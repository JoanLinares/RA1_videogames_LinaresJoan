-- ============================================================================
-- MODELO DE DATA WAREHOUSE - PANDAS
-- Esquema en estrella para el dataset de videojuegos
-- Tablas:
--   - dim_genre        (dimensión de género)
--   - dim_platform     (dimensión de plataforma)
--   - dim_year         (dimensión de año de lanzamiento)
--   - dim_publisher    (dimensión de distribuidora)
--   - fact_videogame   (tabla de hechos de videojuegos)
-- ============================================================================

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
    genre_id     INTEGER PRIMARY KEY,      -- Clave primaria de la dimensión
    genre_name   TEXT    NOT NULL UNIQUE   -- Nombre del género (Action, RPG, ...)
);

-- --------------------------------------------------------------------------
-- DIMENSIÓN: dim_platform  (Dimensión de Plataforma)
-- --------------------------------------------------------------------------
CREATE TABLE dim_platform (
    platform_id    INTEGER PRIMARY KEY,       -- Clave primaria de la dimensión
    platform_name  TEXT    NOT NULL UNIQUE    -- Nombre de la plataforma (PC, PS, Xbox, ...)
);

-- --------------------------------------------------------------------------
-- DIMENSIÓN: dim_year  (Dimensión de Año)
-- --------------------------------------------------------------------------
CREATE TABLE dim_year (
    year_id     INTEGER PRIMARY KEY,      -- Clave primaria de la dimensión
    year_value  INTEGER NOT NULL UNIQUE   -- Año de lanzamiento (ej. 2015, 2018...)
);

-- --------------------------------------------------------------------------
-- DIMENSIÓN: dim_publisher  (Dimensión de Distribuidora / Publisher)
-- --------------------------------------------------------------------------
CREATE TABLE dim_publisher (
    publisher_id    INTEGER PRIMARY KEY,       -- Clave primaria de la dimensión
    publisher_name  TEXT    NOT NULL UNIQUE    -- Nombre del publisher (Nintendo, EA, ...)
);

-- --------------------------------------------------------------------------
-- TABLA DE HECHOS: fact_videogame
--  - Un registro por videojuego
--  - Métricas numéricas + claves foráneas a las dimensiones
-- --------------------------------------------------------------------------
CREATE TABLE fact_videogame (
    game_id                     INTEGER PRIMARY KEY,  -- Identificador del videojuego (hecho)
    name                        TEXT    NOT NULL,     -- Nombre del juego

    -- Claves foráneas hacia las dimensiones
    genre_id                    INTEGER NOT NULL,
    platform_id                 INTEGER NOT NULL,
    year_id                     INTEGER,              -- Año puede ser opcional si falta
    publisher_id                INTEGER,              -- Publisher puede ser opcional si falta

    -- Métricas y atributos
    metascore_num               REAL,                -- Metascore numérico normalizado
    user_score_num              REAL,                -- User score numérico normalizado
    score_promedio              REAL,                -- Media entre metascore y user_score
    copies_sold_millions_num    REAL,                -- Copias vendidas (en millones)
    revenue_millions_usd_num    REAL,                -- Ingresos (en millones de USD)
    ingreso_por_copia           REAL,                -- Ingreso medio por copia
    categoria_ventas            TEXT,                -- Clasificación: Bajo/Moderado/Exitoso/Blockbuster

    -- Información de auditoría
    fecha_carga                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Restricciones de integridad referencial (modelo estrella)
    FOREIGN KEY (genre_id)     REFERENCES dim_genre(genre_id),
    FOREIGN KEY (platform_id)  REFERENCES dim_platform(platform_id),
    FOREIGN KEY (year_id)      REFERENCES dim_year(year_id),
    FOREIGN KEY (publisher_id) REFERENCES dim_publisher(publisher_id)
);
