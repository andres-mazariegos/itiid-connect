-- =====================================================================
-- ITIID Connect · 05_roles.sql
-- Roles y permisos (principio de mínimo privilegio).
--
-- Roles de grupo (no inician sesión, solo agrupan permisos):
--   rol_admin, rol_docente, rol_estudiante, rol_consulta
-- Usuarios de ejemplo (sí inician sesión):
--   admin_itiid, doc_lgomez, est_243790, est_243691, consulta_itiid
--
-- IMPORTANTE: antes de ejecutar, cambia 'CAMBIAR_ESTA_CLAVE' por una
-- contraseña tuya. No subas contraseñas reales a GitHub.
-- =====================================================================
SET search_path TO itiid;

-- ---------- Crear roles (si ya existen, no truena) ----------
DO $$
DECLARE r TEXT;
BEGIN
    FOREACH r IN ARRAY ARRAY['rol_admin','rol_docente','rol_estudiante','rol_consulta'] LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('CREATE ROLE %I NOLOGIN', r);
        END IF;
    END LOOP;

    FOREACH r IN ARRAY ARRAY['admin_itiid','doc_lgomez','est_243790','est_243691','consulta_itiid'] LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', r, 'CAMBIAR_ESTA_CLAVE');
        END IF;
    END LOOP;
END $$;

GRANT rol_admin      TO admin_itiid;
GRANT rol_docente    TO doc_lgomez;      -- Laura Gómez Ruiz (lgomez@...)
GRANT rol_estudiante TO est_243790, est_243691;
GRANT rol_consulta   TO consulta_itiid;

-- Todos pueden "entrar" al esquema, pero nadie más que nosotros puede crear cosas ahí
REVOKE ALL ON SCHEMA itiid FROM PUBLIC;
GRANT USAGE ON SCHEMA itiid TO rol_admin, rol_docente, rol_estudiante, rol_consulta;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA itiid FROM PUBLIC;

-- ---------- Administrador: todo sobre los datos ----------
GRANT ALL ON ALL TABLES    IN SCHEMA itiid TO rol_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA itiid TO rol_admin;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA itiid TO rol_admin;

-- ---------- Consulta: solo lectura ----------
GRANT SELECT ON ALL TABLES IN SCHEMA itiid TO rol_consulta;   -- incluye las vistas

-- ---------- Docente: consulta, atiende sus citas y levanta reportes ----------
GRANT SELECT ON ALL TABLES IN SCHEMA itiid TO rol_docente;
GRANT UPDATE (estado, observaciones) ON citas TO rol_docente;
GRANT INSERT (id_docente_emisor, id_estudiante, id_grupo, fecha, tipo, descripcion) ON reportes TO rol_docente;
GRANT UPDATE (estado) ON reportes TO rol_docente;
GRANT EXECUTE ON FUNCTION proximo(INT) TO rol_docente;

-- ---------- Estudiante: ve el catálogo y agenda citas solo con la función ----------
GRANT SELECT ON docentes, materias, grupos, periodos, asignaciones, horarios TO rol_estudiante;
GRANT SELECT ON vw_carga_docente TO rol_estudiante;
GRANT SELECT ON citas TO rol_estudiante;                        -- filtrado abajo con RLS
GRANT EXECUTE ON FUNCTION registrar_cita(CHAR, INT, DATE, TIME, TIME, VARCHAR) TO rol_estudiante;
GRANT EXECUTE ON FUNCTION proximo(INT) TO rol_estudiante;
-- (el estudiante NO puede ver la tabla estudiantes ni reportes)

-- =====================================================================
-- Seguridad a nivel de fila (RLS) en citas:
-- cada docente ve solo sus citas y cada estudiante solo las suyas.
-- El usuario se relaciona con su registro por su nombre:
--   est_<matrícula>  y  doc_<parte del correo antes de la @>
-- =====================================================================
-- Reciben el nombre del usuario (current_user) desde la política.
CREATE OR REPLACE FUNCTION id_estudiante_de(p_usuario NAME) RETURNS INT
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = itiid, pg_temp AS $$
    SELECT id_estudiante FROM estudiantes WHERE 'est_' || matricula = p_usuario;
$$;

CREATE OR REPLACE FUNCTION id_docente_de(p_usuario NAME) RETURNS INT
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = itiid, pg_temp AS $$
    SELECT id_docente FROM docentes WHERE 'doc_' || split_part(correo, '@', 1) = p_usuario;
$$;

REVOKE EXECUTE ON FUNCTION id_estudiante_de(NAME), id_docente_de(NAME) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION id_estudiante_de(NAME) TO rol_estudiante;
GRANT EXECUTE ON FUNCTION id_docente_de(NAME)    TO rol_docente;

ALTER TABLE citas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS citas_admin_consulta ON citas;
DROP POLICY IF EXISTS citas_docente_ver ON citas;
DROP POLICY IF EXISTS citas_docente_actualizar ON citas;
DROP POLICY IF EXISTS citas_estudiante_ver ON citas;

CREATE POLICY citas_admin_consulta ON citas
    FOR ALL TO rol_admin, rol_consulta USING (true) WITH CHECK (true);

CREATE POLICY citas_docente_ver ON citas
    FOR SELECT TO rol_docente USING (id_docente = id_docente_de(current_user));

CREATE POLICY citas_docente_actualizar ON citas
    FOR UPDATE TO rol_docente
    USING (id_docente = id_docente_de(current_user))
    WITH CHECK (id_docente = id_docente_de(current_user));

CREATE POLICY citas_estudiante_ver ON citas
    FOR SELECT TO rol_estudiante USING (id_estudiante = id_estudiante_de(current_user));
