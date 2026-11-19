-- =====================================================================
-- ITIID Connect · pruebas/03_transacciones.sql
-- Transacciones y validación de conflictos. Corre cada bloque por
-- separado. proximo(1) = el próximo lunes, para no usar fechas fijas.
-- Recuerda: la docente 1 (Laura) tiene clase los lunes de 10:00 a 12:00.
-- =====================================================================
SET search_path TO itiid;

-- ---------------------------------------------------------------------
-- Bloque A · Caso correcto: BEGIN -> validar -> registrar -> COMMIT
-- Esperado: devuelve el número de la cita nueva.
-- ---------------------------------------------------------------------
BEGIN;
SELECT registrar_cita('243810', 1, proximo(1), '12:30', '13:00', 'Dudas de JOIN') AS cita_nueva;
COMMIT;

SELECT * FROM vw_citas WHERE matricula = '243810' ORDER BY id_cita DESC LIMIT 1;

-- ---------------------------------------------------------------------
-- Bloque B · Conflicto con una CLASE (lunes 10:30, la docente está dando clase)
-- Esperado: ERROR  Conflicto: el docente tiene clase en ese horario
-- Como hubo error, la transacción se cancela: hay que cerrar con ROLLBACK.
-- ---------------------------------------------------------------------
BEGIN;
SELECT registrar_cita('243655', 1, proximo(1), '10:30', '11:00', 'Revisión de práctica');
ROLLBACK;

-- ---------------------------------------------------------------------
-- Bloque C · Caso de complejidad: otro estudiante quiere el MISMO horario
-- que el bloque A (12:45 se cruza con 12:30-13:00).
-- Esperado: ERROR  Conflicto: el docente ya tiene una cita en ese horario
-- ---------------------------------------------------------------------
BEGIN;
SELECT registrar_cita('243655', 1, proximo(1), '12:45', '13:15', 'Revisión de práctica');
ROLLBACK;

-- ---------------------------------------------------------------------
-- Bloque D · Atomicidad a mano: dos cambios que van juntos.
-- La docente atiende la cita y levanta un reporte... pero nos
-- arrepentimos y hacemos ROLLBACK. Nada de lo anterior debe quedar.
-- ---------------------------------------------------------------------
BEGIN;
UPDATE citas SET estado = 'atendida', observaciones = 'Se resolvieron dudas'
WHERE id_cita = 1;
INSERT INTO reportes (id_docente_emisor, id_estudiante, tipo, descripcion)
VALUES (1, 1, 'academico', 'Asistió a asesoría.');
SELECT estado FROM citas WHERE id_cita = 1;      -- dentro de la transacción: atendida
ROLLBACK;

SELECT estado FROM citas WHERE id_cita = 1;      -- después del ROLLBACK: confirmada otra vez
SELECT COUNT(*) AS reportes FROM reportes;       -- siguen siendo 4

-- ---------------------------------------------------------------------
-- (Opcional) Limpiar la cita de prueba del bloque A para volver a correrlo
-- ---------------------------------------------------------------------
-- DELETE FROM citas WHERE motivo = 'Dudas de JOIN';
