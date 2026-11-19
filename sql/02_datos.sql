-- =====================================================================
-- ITIID Connect · 02_datos.sql
-- Datos de prueba. Los docentes y la mayoría de los estudiantes son
-- ficticios; solo usamos nuestras matrículas como ejemplo.
-- =====================================================================
SET search_path TO itiid;

INSERT INTO periodos (nombre, fecha_inicio, fecha_fin, estado) VALUES
  ('Mayo-Agosto 2026',      '2026-05-04', '2026-08-21', 'cerrado'),
  ('Agosto-Diciembre 2026', '2026-08-31', '2026-12-18', 'activo');

INSERT INTO grupos (nombre_grupo, semestre) VALUES
  ('7A', 7), ('7C', 7), ('4B', 4);

INSERT INTO materias (clave_materia, nombre, creditos) VALUES
  ('O-BDEN-3', 'Optativa I: Bases de Datos en la Nube',          5.63),
  ('SEGI-07',  'Seguridad Informática',                          6.00),
  ('FIA-07',   'Fundamentos de Inteligencia Artificial',         6.00),
  ('FPT-07',   'Formulación de Proyectos de Tecnología',         5.00),
  ('HAGE-07',  'Habilidades Gerenciales',                        4.50),
  ('PROG-04',  'Programación Orientada a Objetos',               6.00);

INSERT INTO docentes (nombre, apellidos, correo, especialidad) VALUES
  ('Laura',   'Gómez Ruiz',      'lgomez@upchiapas.edu.mx',    'Bases de datos'),
  ('Ricardo', 'Pérez Velasco',   'rperez@upchiapas.edu.mx',    'Redes y seguridad'),
  ('Sofía',   'Hernández Cruz',  'shernandez@upchiapas.edu.mx','Inteligencia artificial'),
  ('Miguel',  'Santos Ochoa',    'msantos@upchiapas.edu.mx',   'Gestión de proyectos'),
  ('Elena',   'Morales Díaz',    'emorales@upchiapas.edu.mx',  'Desarrollo de software');

INSERT INTO estudiantes (matricula, nombre, apellidos, correo) VALUES
  ('243790', 'Carlos Andrés',    'Mazariegos Laguna',  '243790@ids.upchiapas.edu.mx'),
  ('243691', 'Heber Alexander',  'Escobar Nuricumbo',  '243691@ids.upchiapas.edu.mx'),
  ('243702', 'Axel Rodrigo',     'Cuc López',          '243702@ids.upchiapas.edu.mx'),
  ('243810', 'Valeria',          'Ramírez Solís',      '243810@ids.upchiapas.edu.mx'),
  ('243655', 'Diego',            'Aguilar Méndez',     '243655@ids.upchiapas.edu.mx'),
  ('251120', 'Fernanda',         'López Trujillo',     '251120@ids.upchiapas.edu.mx');

-- Inscripciones del periodo activo (id_periodo = 2)
INSERT INTO inscripciones (id_estudiante, id_grupo, id_periodo) VALUES
  (1, 2, 2), (2, 2, 2), (3, 2, 2), (4, 1, 2), (5, 1, 2), (6, 3, 2);

-- Qué docente da qué materia a qué grupo (periodo 2)
INSERT INTO asignaciones (id_docente, id_materia, id_grupo, id_periodo) VALUES
  (1, 1, 2, 2),   -- 1 Laura   · BD en la Nube    · 7C
  (2, 2, 2, 2),   -- 2 Ricardo · Seguridad        · 7C
  (3, 3, 2, 2),   -- 3 Sofía   · IA               · 7C
  (4, 4, 2, 2),   -- 4 Miguel  · Formulación      · 7C
  (1, 1, 1, 2),   -- 5 Laura   · BD en la Nube    · 7A
  (5, 6, 3, 2),   -- 6 Elena   · POO              · 4B
  (4, 5, 1, 2);   -- 7 Miguel  · Hab. Gerenciales · 7A

-- Horarios de clase (1 = lunes ... 5 = viernes)
INSERT INTO horarios (id_asignacion, dia, hora_inicio, hora_fin, aula) VALUES
  (1, 1, '10:00', '12:00', 'LC-3'),
  (1, 3, '10:00', '12:00', 'LC-3'),
  (5, 2, '08:00', '10:00', 'LC-1'),
  (5, 4, '08:00', '10:00', 'LC-1'),
  (2, 2, '12:00', '14:00', 'A-204'),
  (3, 4, '12:00', '14:00', 'A-204'),
  (4, 5, '09:00', '11:00', 'A-201'),
  (7, 1, '12:00', '13:00', 'A-105'),
  (6, 3, '14:00', '16:00', 'LC-2');

-- Citas ya registradas (lunes 23 y martes 24 de noviembre de 2026)
INSERT INTO citas (id_estudiante, id_docente, fecha, hora_inicio, hora_fin, motivo, estado) VALUES
  (1, 1, '2026-11-23', '13:00', '13:30', 'Dudas del modelo relacional del proyecto', 'confirmada'),
  (2, 1, '2026-11-24', '11:00', '11:30', 'Revisión de restricciones CHECK',          'pendiente'),
  (3, 2, '2026-11-23', '15:00', '15:30', 'Asesoría del reporte de laboratorio',      'confirmada'),
  (4, 3, '2026-11-26', '15:00', '16:00', 'Explicación de búsqueda A*',               'pendiente'),
  (5, 1, '2026-11-25', '13:00', '13:30', 'Roles y permisos en PostgreSQL',           'cancelada'),
  (6, 5, '2026-11-20', '10:00', '10:30', 'Herencia en Java',                         'atendida');

INSERT INTO reportes (id_docente_emisor, id_estudiante, id_grupo, fecha, tipo, descripcion, estado) VALUES
  (1, 1,    NULL, '2026-11-10', 'academico',  'Entregó la propuesta completa y a tiempo.',          'cerrado'),
  (2, NULL, 2,    '2026-11-12', 'asistencia', 'El grupo 7C tuvo baja asistencia en el laboratorio.', 'en_revision'),
  (3, 4,    NULL, '2026-11-14', 'academico',  'Pendiente el práctico del primer corte.',            'abierto'),
  (5, 6,    NULL, '2026-11-17', 'conducta',   'Apoya a sus compañeros en las prácticas.',           'cerrado');
