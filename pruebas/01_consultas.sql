-- =====================================================================
-- ITIID Connect · pruebas/01_consultas.sql
-- Consultas que relacionan varias tablas (SELECT, JOIN, WHERE,
-- GROUP BY, HAVING, ORDER BY). Se pueden correr todas de una vez.
-- =====================================================================
SET search_path TO itiid;

-- 1) ¿Qué materia da cada docente, a qué grupo, qué día y en qué aula?
SELECT docente, materia, grupo, dia, horario, aula
FROM vw_carga_docente
ORDER BY docente, num_dia, hora_inicio;

-- 2) Historial de citas de la docente Laura Gómez (id 1)
SELECT fecha, horario, estudiante, motivo, estado
FROM vw_citas
WHERE docente = 'Laura Gómez Ruiz'
ORDER BY fecha, horario;

-- 3) Citas registradas por un estudiante (matrícula 243790)
SELECT c.fecha, c.hora_inicio, d.nombre || ' ' || d.apellidos AS docente, c.motivo, c.estado
FROM citas c
JOIN estudiantes e ON e.id_estudiante = c.id_estudiante
JOIN docentes d    ON d.id_docente    = c.id_docente
WHERE e.matricula = '243790'
ORDER BY c.fecha;

-- 4) ¿Cuántas citas tiene cada docente por estado?
SELECT d.nombre || ' ' || d.apellidos AS docente, c.estado, COUNT(*) AS total
FROM citas c
JOIN docentes d ON d.id_docente = c.id_docente
GROUP BY docente, c.estado
ORDER BY docente, c.estado;

-- 5) Docentes con más de una cita activa (pendiente o confirmada)  -> HAVING
SELECT d.nombre || ' ' || d.apellidos AS docente, COUNT(*) AS citas_activas
FROM citas c
JOIN docentes d ON d.id_docente = c.id_docente
WHERE c.estado IN ('pendiente', 'confirmada')
GROUP BY docente
HAVING COUNT(*) > 1;

-- 6) Estudiantes inscritos por grupo en el periodo activo
SELECT g.nombre_grupo AS grupo, COUNT(i.id_estudiante) AS estudiantes
FROM grupos g
LEFT JOIN inscripciones i ON i.id_grupo = g.id_grupo
                         AND i.id_periodo = (SELECT id_periodo FROM periodos WHERE estado = 'activo')
GROUP BY g.nombre_grupo
ORDER BY g.nombre_grupo;

-- 7) Reportes que siguen abiertos o en revisión, con quién los levantó
SELECT r.fecha, r.tipo, d.apellidos AS docente,
       COALESCE(e.nombre || ' ' || e.apellidos, 'Grupo ' || g.nombre_grupo) AS sobre,
       r.descripcion, r.estado
FROM reportes r
JOIN docentes d         ON d.id_docente    = r.id_docente_emisor
LEFT JOIN estudiantes e ON e.id_estudiante = r.id_estudiante
LEFT JOIN grupos g      ON g.id_grupo      = r.id_grupo
WHERE r.estado <> 'cerrado'
ORDER BY r.fecha;

-- 8) Agenda de un docente en un día: sus clases + sus citas, juntas (UNION ALL)
SELECT 'Clase' AS tipo, horario, materia || ' (' || grupo || ')' AS detalle
FROM vw_carga_docente
WHERE id_docente = 1 AND num_dia = 1                      -- lunes
UNION ALL
SELECT 'Cita', horario, estudiante || ': ' || motivo
FROM vw_citas
WHERE docente = 'Laura Gómez Ruiz' AND fecha = '2026-11-23' AND estado IN ('pendiente','confirmada')
ORDER BY horario;

-- 9) ¿Se usa el índice? Con tan pocos datos PostgreSQL prefiere leer toda la tabla
--    (Seq Scan), así que lo apagamos un momento solo para comprobar el índice.
SET enable_seqscan = off;
EXPLAIN SELECT * FROM citas WHERE id_docente = 1 AND fecha = '2026-11-23';
RESET enable_seqscan;
