-- =====================================================================
-- ITIID Connect · pruebas/04_permisos.sql
-- Comprobamos que cada rol solo puede hacer lo que le toca.
-- SET ROLE = "hacerse pasar" por ese usuario sin cambiar de conexión.
-- Ejecuta cada bloque por separado. Los ERROR son lo esperado.
-- =====================================================================
SET search_path TO itiid;

-- Necesario solo la primera vez (en Supabase el usuario postgres debe
-- ser miembro de estos roles para poder usar SET ROLE).
GRANT est_243790, doc_lgomez, consulta_itiid TO CURRENT_USER;

-- ---------- Estudiante 243790 ----------
SET ROLE est_243790;
SELECT id_cita, fecha, motivo, estado FROM citas;   -- solo ve SUS citas (RLS)
SELECT * FROM reportes;                             -- ERROR: permission denied for table reportes
RESET ROLE;

SET ROLE est_243790;
-- Intenta agendar a nombre de otro compañero
SELECT registrar_cita('243691', 2, proximo(3), '16:00', '16:30', 'Prueba');  -- ERROR: Solo puedes agendar citas con tu propia matrícula
RESET ROLE;

SET ROLE est_243790;
DELETE FROM citas;                                  -- ERROR: permission denied for table citas
RESET ROLE;

-- ---------- Docente Laura Gómez ----------
SET ROLE doc_lgomez;
SELECT id_cita, fecha, motivo, estado FROM citas;   -- solo ve las citas de ella
UPDATE citas SET estado = 'confirmada' WHERE id_cita = 2;  -- permitido: es su cita
UPDATE citas SET estado = 'cancelada'  WHERE id_cita = 3;  -- UPDATE 0: la cita 3 no es suya
RESET ROLE;

SET ROLE doc_lgomez;
UPDATE citas SET fecha = '2026-12-24' WHERE id_cita = 2;  -- ERROR: permission denied (solo puede cambiar estado y observaciones)
RESET ROLE;

-- ---------- Consulta (solo lectura) ----------
SET ROLE consulta_itiid;
SELECT COUNT(*) AS total_citas FROM citas;          -- ve todo
UPDATE materias SET creditos = 10 WHERE id_materia = 1;  -- ERROR: permission denied for table materias
RESET ROLE;
