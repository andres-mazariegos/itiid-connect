-- =====================================================================
-- ITIID Connect · 01_esquema.sql
-- Crea el esquema "itiid" y las 10 tablas con sus llaves y restricciones.
--
-- Usamos un esquema propio (y no "public") porque en Supabase todo lo
-- que está en "public" queda expuesto por su API web. Así la base solo
-- se usa con los roles que nosotros definimos.
-- =====================================================================

DROP SCHEMA IF EXISTS itiid CASCADE;
CREATE SCHEMA itiid;
SET search_path TO itiid;

-- ---------------------------------------------------------------------
-- Entidades base
-- ---------------------------------------------------------------------

CREATE TABLE docentes (
    id_docente    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre        VARCHAR(60)  NOT NULL CHECK (btrim(nombre) <> ''),
    apellidos     VARCHAR(80)  NOT NULL CHECK (btrim(apellidos) <> ''),
    correo        VARCHAR(120) NOT NULL UNIQUE CHECK (correo LIKE '%_@_%._%'),
    especialidad  VARCHAR(80),
    estado        VARCHAR(10)  NOT NULL DEFAULT 'activo'
                  CHECK (estado IN ('activo', 'inactivo'))
);

CREATE TABLE estudiantes (
    id_estudiante INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    matricula     CHAR(6)      NOT NULL UNIQUE CHECK (matricula ~ '^[0-9]{6}$'),
    nombre        VARCHAR(60)  NOT NULL CHECK (btrim(nombre) <> ''),
    apellidos     VARCHAR(80)  NOT NULL CHECK (btrim(apellidos) <> ''),
    correo        VARCHAR(120) NOT NULL UNIQUE CHECK (correo LIKE '%_@_%._%'),
    estado        VARCHAR(10)  NOT NULL DEFAULT 'activo'
                  CHECK (estado IN ('activo', 'baja'))
);

CREATE TABLE grupos (
    id_grupo      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_grupo  VARCHAR(10)  NOT NULL,                       -- ej. 7C
    semestre      SMALLINT     NOT NULL CHECK (semestre BETWEEN 1 AND 10),  -- cuatrimestre
    carrera       VARCHAR(10)  NOT NULL DEFAULT 'ITIID',
    estado        VARCHAR(10)  NOT NULL DEFAULT 'activo'
                  CHECK (estado IN ('activo', 'inactivo')),
    UNIQUE (nombre_grupo, carrera)
);

CREATE TABLE materias (
    id_materia    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    clave_materia VARCHAR(12)  NOT NULL UNIQUE,
    nombre        VARCHAR(100) NOT NULL CHECK (btrim(nombre) <> ''),
    creditos      NUMERIC(4,2) NOT NULL CHECK (creditos > 0),
    estado        VARCHAR(10)  NOT NULL DEFAULT 'activa'
                  CHECK (estado IN ('activa', 'inactiva'))
);

CREATE TABLE periodos (
    id_periodo    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre        VARCHAR(40)  NOT NULL UNIQUE,                -- ej. Agosto-Diciembre 2026
    fecha_inicio  DATE         NOT NULL,
    fecha_fin     DATE         NOT NULL,
    estado        VARCHAR(10)  NOT NULL DEFAULT 'planeado'
                  CHECK (estado IN ('planeado', 'activo', 'cerrado')),
    CHECK (fecha_fin > fecha_inicio)
);

-- ---------------------------------------------------------------------
-- Entidades que dependen de llaves foráneas
-- ---------------------------------------------------------------------

-- Un estudiante se inscribe a un grupo en un periodo (resuelve N:M estudiantes-grupos).
CREATE TABLE inscripciones (
    id_inscripcion INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_estudiante  INT NOT NULL REFERENCES estudiantes (id_estudiante),
    id_grupo       INT NOT NULL REFERENCES grupos (id_grupo),
    id_periodo     INT NOT NULL REFERENCES periodos (id_periodo),
    UNIQUE (id_estudiante, id_periodo)          -- un solo grupo por periodo
);

-- Qué docente da qué materia, a qué grupo y en qué periodo.
CREATE TABLE asignaciones (
    id_asignacion INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_docente    INT NOT NULL REFERENCES docentes (id_docente),
    id_materia    INT NOT NULL REFERENCES materias (id_materia),
    id_grupo      INT NOT NULL REFERENCES grupos (id_grupo),
    id_periodo    INT NOT NULL REFERENCES periodos (id_periodo),
    UNIQUE (id_materia, id_grupo, id_periodo)   -- una materia no se repite en el mismo grupo
);

-- Horario de clase de cada asignación. dia: 1 = lunes ... 6 = sábado.
CREATE TABLE horarios (
    id_horario    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_asignacion INT      NOT NULL REFERENCES asignaciones (id_asignacion) ON DELETE CASCADE,
    dia           SMALLINT NOT NULL CHECK (dia BETWEEN 1 AND 6),
    hora_inicio   TIME     NOT NULL,
    hora_fin      TIME     NOT NULL,
    aula          VARCHAR(20) NOT NULL,
    CHECK (hora_fin > hora_inicio)
);

-- Citas de asesoría entre un estudiante y un docente.
CREATE TABLE citas (
    id_cita       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_estudiante INT  NOT NULL REFERENCES estudiantes (id_estudiante),
    id_docente    INT  NOT NULL REFERENCES docentes (id_docente),
    fecha         DATE NOT NULL,
    hora_inicio   TIME NOT NULL,
    hora_fin      TIME NOT NULL,
    motivo        VARCHAR(150) NOT NULL CHECK (btrim(motivo) <> ''),
    estado        VARCHAR(12)  NOT NULL DEFAULT 'pendiente'
                  CHECK (estado IN ('pendiente', 'confirmada', 'cancelada', 'atendida')),
    observaciones TEXT,
    CHECK (hora_fin > hora_inicio),
    CHECK (hora_fin - hora_inicio <= INTERVAL '1 hour')   -- una asesoría dura máximo 1 hora
);

-- Reportes que un docente levanta sobre un estudiante o sobre un grupo completo.
CREATE TABLE reportes (
    id_reporte        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_docente_emisor INT  NOT NULL REFERENCES docentes (id_docente),
    id_estudiante     INT  REFERENCES estudiantes (id_estudiante),
    id_grupo          INT  REFERENCES grupos (id_grupo),
    fecha             DATE NOT NULL DEFAULT CURRENT_DATE,
    tipo              VARCHAR(12) NOT NULL
                      CHECK (tipo IN ('academico', 'asistencia', 'conducta', 'general')),
    descripcion       TEXT NOT NULL CHECK (btrim(descripcion) <> ''),
    estado            VARCHAR(12) NOT NULL DEFAULT 'abierto'
                      CHECK (estado IN ('abierto', 'en_revision', 'cerrado')),
    CHECK (id_estudiante IS NOT NULL OR id_grupo IS NOT NULL)  -- debe ser sobre alguien
);
