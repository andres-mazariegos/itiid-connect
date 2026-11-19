-- =====================================================================
-- ITIID Connect · pruebas/02_restricciones.sql
-- Pruebas NEGATIVAS: cada INSERT está mal a propósito y PostgreSQL
-- debe rechazarlo. Ejecútalas UNA POR UNA (en Supabase: selecciona
-- la línea y dale Run). El error ES el resultado esperado.
-- =====================================================================
SET search_path TO itiid;

-- 1) UNIQUE: matrícula repetida
--    Esperado: ERROR duplicate key value violates unique constraint "estudiantes_matricula_key"
INSERT INTO estudiantes (matricula, nombre, apellidos, correo)
VALUES ('243790', 'Otro', 'Alumno', 'otro@ids.upchiapas.edu.mx');

-- 2) CHECK: matrícula con letras
--    Esperado: ERROR new row ... violates check constraint "estudiantes_matricula_check"
INSERT INTO estudiantes (matricula, nombre, apellidos, correo)
VALUES ('24A790', 'Ana', 'Pérez', 'ana@ids.upchiapas.edu.mx');

-- 3) NOT NULL: docente sin correo
--    Esperado: ERROR null value in column "correo" ... violates not-null constraint
INSERT INTO docentes (nombre, apellidos) VALUES ('Juan', 'Sin Correo');

-- 4) FOREIGN KEY: cita con un docente que no existe
--    Esperado: ERROR ... violates foreign key constraint "citas_id_docente_fkey"
INSERT INTO citas (id_estudiante, id_docente, fecha, hora_inicio, hora_fin, motivo)
VALUES (1, 999, '2026-12-01', '10:00', '10:30', 'Prueba');

-- 5) CHECK: la cita termina antes de empezar
--    Esperado: ERROR ... violates check constraint "citas_check"
INSERT INTO citas (id_estudiante, id_docente, fecha, hora_inicio, hora_fin, motivo)
VALUES (1, 1, '2026-12-01', '11:00', '10:00', 'Prueba');

-- 6) CHECK: estado que no existe
--    Esperado: ERROR ... violates check constraint "citas_estado_check"
INSERT INTO citas (id_estudiante, id_docente, fecha, hora_inicio, hora_fin, motivo, estado)
VALUES (1, 1, '2026-12-01', '10:00', '10:30', 'Prueba', 'olvidada');

-- 7) CHECK: periodo que termina antes de iniciar
--    Esperado: ERROR ... violates check constraint "periodos_check"
INSERT INTO periodos (nombre, fecha_inicio, fecha_fin)
VALUES ('Periodo raro', '2027-05-01', '2027-01-01');

-- 8) UNIQUE compuesto: inscribir al mismo estudiante dos veces en el mismo periodo
--    Esperado: ERROR duplicate key ... "inscripciones_id_estudiante_id_periodo_key"
INSERT INTO inscripciones (id_estudiante, id_grupo, id_periodo) VALUES (1, 1, 2);

-- 9) FOREIGN KEY al borrar: no se puede borrar un docente que tiene asignaciones
--    Esperado: ERROR update or delete on table "docentes" violates foreign key constraint
DELETE FROM docentes WHERE id_docente = 1;

-- Comprobación final: los datos originales siguen igual
SELECT (SELECT COUNT(*) FROM estudiantes) AS estudiantes,  -- 6
       (SELECT COUNT(*) FROM docentes)    AS docentes,     -- 5
       (SELECT COUNT(*) FROM citas)       AS citas;        -- 6
