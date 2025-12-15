-- Activar el soporte de claves foráneas en SQLite
PRAGMA foreign_keys = ON;

-- --------------------------------------------------------------------------
-- Limpieza previa (por si las tablas ya existen)
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS fact_videogame;
DROP TABLE IF EXISTS dim_publisher;
DROP TABLE IF EXISTS dim_year;
DROP TABLE IF EXISTS dim_platform;
DROP TABLE IF EXISTS dim_genre;

-- --------------------------------------------------------------------------
-- DIMENSIÓN: dim_genre  (Dimensión de Género)
-- --------------------------------------------------------------------------
CREATE TABLE dim_genre (
    genre_id     INTEGER PRIMARY KEY,
    genre_name   TEXT    NOT NULL UNIQUE
);

-- --------------------------------------------------------------------------
-- DIMENSIÓN: dim_platform  (Dimensión de Plataforma)
-- --------------------------------------------------------------------------
CREATE TABLE dim_platform (
    platform_id    INTEGER PRIMARY KEY,
    platform_name  TEXT    NOT NULL UNIQUE
);

-- --------------------------------------------------------------------------
-- DIMENSIÓN: dim_year  (Dimensión de Año)
-- --------------------------------------------------------------------------
CREATE TABLE dim_year (
    year_id     INTEGER PRIMARY KEY,
    year_value  INTEGER NOT NULL UNIQUE
);

-- --------------------------------------------------------------------------
-- DIMENSIÓN: dim_publisher  (Dimensión de Distribuidora / Publisher)
-- --------------------------------------------------------------------------
CREATE TABLE dim_publisher (
    publisher_id    INTEGER PRIMARY KEY,
    publisher_name  TEXT    NOT NULL UNIQUE
);

-- --------------------------------------------------------------------------
-- TABLA DE HECHOS: fact_videogame
--  - Un registro por videojuego
--  - Métricas numéricas + claves foráneas a las dimensiones
-- --------------------------------------------------------------------------
CREATE TABLE fact_videogame (
    game_id                     INTEGER PRIMARY KEY,
    name                        TEXT    NOT NULL,

    -- Claves foráneas hacia las dimensiones
    genre_id                    INTEGER NOT NULL,
    platform_id                 INTEGER NOT NULL,
    year_id                     INTEGER,
    publisher_id                INTEGER,

    -- Métricas y atributos
    metascore_num               REAL,
    user_score_num              REAL,
    score_promedio              REAL,
    copies_sold_millions_num    REAL,
    revenue_millions_usd_num    REAL,
    ingreso_por_copia           REAL,
    categoria_ventas            TEXT,

    -- Información de auditoría
    fecha_carga                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Restricciones de integridad referencial (modelo estrella)
    FOREIGN KEY (genre_id)     REFERENCES dim_genre(genre_id),
    FOREIGN KEY (platform_id)  REFERENCES dim_platform(platform_id),
    FOREIGN KEY (year_id)      REFERENCES dim_year(year_id),
    FOREIGN KEY (publisher_id) REFERENCES dim_publisher(publisher_id)
);
