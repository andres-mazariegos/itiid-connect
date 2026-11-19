-- =====================================================================
-- ITIID Connect · 03_indices.sql
-- Índices en las columnas que más se consultan.
-- (correo, matrícula y clave de materia ya tienen índice por ser UNIQUE)
-- =====================================================================
SET search_path TO itiid;

-- La validación de conflictos busca siempre "citas de este docente en esta fecha".
CREATE INDEX idx_citas_docente_fecha ON citas (id_docente, fecha);

-- Para ver rápido el historial de citas de un estudiante.
CREATE INDEX idx_citas_estudiante    ON citas (id_estudiante);

-- Para sacar el horario de clases de un docente.
CREATE INDEX idx_asignaciones_docente ON asignaciones (id_docente);
CREATE INDEX idx_horarios_asignacion  ON horarios (id_asignacion);

-- Para contar estudiantes por grupo.
CREATE INDEX idx_inscripciones_grupo  ON inscripciones (id_grupo);
