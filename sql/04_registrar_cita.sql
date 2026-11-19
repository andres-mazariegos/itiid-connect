-- =====================================================================
-- ITIID Connect · 04_registrar_cita.sql
-- La parte más importante del proyecto: registrar una cita SOLO si el
-- docente está libre. Todo pasa dentro de una transacción: si algo
-- falla, PostgreSQL deshace todo (ROLLBACK) y no queda nada a medias.
-- =====================================================================
SET search_path TO itiid;

-- Próxima fecha (a partir de mañana) que cae en el día indicado.
-- 1 = lunes ... 6 = sábado. Sirve para hacer pruebas sin fechas fijas.
CREATE OR REPLACE FUNCTION proximo(p_dia INT)
RETURNS DATE
LANGUAGE sql STABLE
AS $$
    SELECT CURRENT_DATE + 1 + ((p_dia - EXTRACT(ISODOW FROM CURRENT_DATE + 1)::INT + 7) % 7);
$$;

-- registrar_cita(matrícula, id del docente, fecha, hora inicio, hora fin, motivo)
-- Devuelve el id de la cita nueva o lanza un error explicando por qué no se pudo.
CREATE OR REPLACE FUNCTION registrar_cita(
    p_matricula  CHAR(6),
    p_id_docente INT,
    p_fecha      DATE,
    p_inicio     TIME,
    p_fin        TIME,
    p_motivo     VARCHAR
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER                 -- corre con permisos del dueño, así el estudiante
SET search_path = itiid, pg_temp -- no necesita acceso directo a todas las tablas
AS $$
DECLARE
    v_id_estudiante INT;
    v_id_cita       INT;
    v_usuario       TEXT;
BEGIN
    -- 1) El estudiante existe y está activo
    SELECT id_estudiante INTO v_id_estudiante
    FROM estudiantes
    WHERE matricula = p_matricula AND estado = 'activo';

    IF v_id_estudiante IS NULL THEN
        RAISE EXCEPTION 'No hay un estudiante activo con la matrícula %', p_matricula;
    END IF;

    -- Un estudiante con su propio usuario (est_######) solo agenda a su nombre.
    -- (Dentro de SECURITY DEFINER, current_user es el dueño de la función;
    --  por eso revisamos el rol activo o el usuario que inició sesión.)
    v_usuario := CASE WHEN current_setting('role') <> 'none'
                      THEN current_setting('role') ELSE session_user END;
    IF v_usuario LIKE 'est\_%' AND v_usuario <> 'est_' || p_matricula THEN
        RAISE EXCEPTION 'Solo puedes agendar citas con tu propia matrícula';
    END IF;

    -- 2) El docente existe y está activo.
    --    FOR UPDATE "aparta" al docente: si dos estudiantes intentan agendar con él
    --    al mismo tiempo, el segundo espera a que el primero termine (aislamiento).
    PERFORM 1 FROM docentes
    WHERE id_docente = p_id_docente AND estado = 'activo'
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El docente % no existe o está inactivo', p_id_docente;
    END IF;

    -- 3) Validaciones de fecha
    IF p_fecha <= CURRENT_DATE THEN
        RAISE EXCEPTION 'La cita debe ser a partir de mañana';
    END IF;

    IF EXTRACT(ISODOW FROM p_fecha) = 7 THEN
        RAISE EXCEPTION 'No hay citas en domingo';
    END IF;

    -- 4) ¿El docente tiene clase a esa hora?
    IF EXISTS (
        SELECT 1
        FROM horarios h
        JOIN asignaciones a ON a.id_asignacion = h.id_asignacion
        JOIN periodos pe    ON pe.id_periodo   = a.id_periodo
        WHERE a.id_docente = p_id_docente
          AND p_fecha BETWEEN pe.fecha_inicio AND pe.fecha_fin
          AND h.dia = EXTRACT(ISODOW FROM p_fecha)
          AND p_inicio < h.hora_fin
          AND p_fin    > h.hora_inicio
    ) THEN
        RAISE EXCEPTION 'Conflicto: el docente tiene clase en ese horario';
    END IF;

    -- 5) ¿El docente ya tiene otra cita a esa hora?
    IF EXISTS (
        SELECT 1 FROM citas c
        WHERE c.id_docente = p_id_docente
          AND c.fecha = p_fecha
          AND c.estado IN ('pendiente', 'confirmada')
          AND p_inicio < c.hora_fin
          AND p_fin    > c.hora_inicio
    ) THEN
        RAISE EXCEPTION 'Conflicto: el docente ya tiene una cita en ese horario';
    END IF;

    -- 6) ¿El estudiante ya tiene otra cita a esa hora?
    IF EXISTS (
        SELECT 1 FROM citas c
        WHERE c.id_estudiante = v_id_estudiante
          AND c.fecha = p_fecha
          AND c.estado IN ('pendiente', 'confirmada')
          AND p_inicio < c.hora_fin
          AND p_fin    > c.hora_inicio
    ) THEN
        RAISE EXCEPTION 'Conflicto: ya tienes otra cita en ese horario';
    END IF;

    -- 7) Todo bien: se registra
    INSERT INTO citas (id_estudiante, id_docente, fecha, hora_inicio, hora_fin, motivo)
    VALUES (v_id_estudiante, p_id_docente, p_fecha, p_inicio, p_fin, p_motivo)
    RETURNING id_cita INTO v_id_cita;

    RETURN v_id_cita;
END;
$$;

-- Vista para leer las citas con nombres en lugar de puros números.
-- security_invoker = true: la vista respeta los permisos de quien la consulta.
CREATE OR REPLACE VIEW vw_citas WITH (security_invoker = true) AS
SELECT c.id_cita,
       c.fecha,
       to_char(c.hora_inicio, 'HH24:MI') || '-' || to_char(c.hora_fin, 'HH24:MI') AS horario,
       d.nombre || ' ' || d.apellidos  AS docente,
       e.matricula,
       e.nombre || ' ' || e.apellidos  AS estudiante,
       c.motivo,
       c.estado,
       c.observaciones
FROM citas c
JOIN docentes d    ON d.id_docente    = c.id_docente
JOIN estudiantes e ON e.id_estudiante = c.id_estudiante;

-- Vista con la carga de cada docente: qué da, a quién, cuándo y dónde.
CREATE OR REPLACE VIEW vw_carga_docente AS
SELECT d.id_docente,
       d.nombre || ' ' || d.apellidos AS docente,
       m.nombre                       AS materia,
       g.nombre_grupo                 AS grupo,
       (ARRAY['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado'])[h.dia] AS dia,
       to_char(h.hora_inicio, 'HH24:MI') || '-' || to_char(h.hora_fin, 'HH24:MI') AS horario,
       h.aula,
       h.dia AS num_dia,
       h.hora_inicio
FROM asignaciones a
JOIN docentes d ON d.id_docente = a.id_docente
JOIN materias m ON m.id_materia = a.id_materia
JOIN grupos   g ON g.id_grupo   = a.id_grupo
JOIN periodos p ON p.id_periodo = a.id_periodo AND p.estado = 'activo'
JOIN horarios h ON h.id_asignacion = a.id_asignacion;
