-- ============================================================================
-- MODELO DE DATA WAREHOUSE - PYSPARK
-- Esquema en estrella para el dataset de videojuegos procesado con PySpark
-- Tablas:
--   - dim_genre        (dimensión de género)
--   - dim_platform     (dimensión de plataforma)
--   - dim_year         (dimensión de año)
--   - dim_publisher    (dimensión de distribuidora)
--   - fact_videogames  (tabla de hechos de videojuegos)
-- ============================================================================

-- Activar el soporte de claves foráneas en SQLite
PRAGMA foreign_keys = ON;

-- --------------------------------------------------------------------------
-- Limpieza previa (por si las tablas ya existen)
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS fact_videogames;
DROP TABLE IF EXISTS dim_publisher;
DROP TABLE IF EXISTS dim_year;
DROP TABLE IF EXISTS dim_platform;
DROP TABLE IF EXISTS dim_genre;

-- --------------------------------------------------------------------------
-- DIMENSIÓN: dim_genre  (Dimensión de Género)
-- --------------------------------------------------------------------------
CREATE TABLE dim_genre (
    genre_id   INTEGER PRIMARY KEY,      -- Clave primaria de la dimensión
    genre      TEXT    NOT NULL UNIQUE   -- Nombre del género (Action, RPG, ...)
);

-- --------------------------------------------------------------------------
-- DIMENSIÓN: dim_platform  (Dimensión de Plataforma)
-- --------------------------------------------------------------------------
CREATE TABLE dim_platform (
    platform_id  INTEGER PRIMARY KEY,      -- Clave primaria de la dimensión
    platform     TEXT    NOT NULL UNIQUE   -- Nombre de la plataforma (PC, PS, Xbox, ...)
);

-- --------------------------------------------------------------------------
-- DIMENSIÓN: dim_year  (Dimensión de Año)
-- --------------------------------------------------------------------------
CREATE TABLE dim_year (
    year_id  INTEGER PRIMARY KEY,      -- Clave primaria de la dimensión
    year     INTEGER NOT NULL UNIQUE   -- Año de lanzamiento (ej. 2015, 2018...)
);

-- --------------------------------------------------------------------------
-- DIMENSIÓN: dim_publisher  (Dimensión de Distribuidora / Publisher)
-- --------------------------------------------------------------------------
CREATE TABLE dim_publisher (
    publisher_id  INTEGER PRIMARY KEY,      -- Clave primaria de la dimensión
    publisher     TEXT    NOT NULL UNIQUE   -- Nombre del publisher (Nintendo, EA, ...)
);

-- --------------------------------------------------------------------------
-- TABLA DE HECHOS: fact_videogames
--  - Un registro por videojuego/plataforma en el dataset procesado con PySpark
--  - Contiene métricas agregadas a nivel de plataforma + categorías
-- --------------------------------------------------------------------------
CREATE TABLE fact_videogames (
    fact_id                     INTEGER PRIMARY KEY,  -- Identificador del hecho
    name                        TEXT    NOT NULL,     -- Nombre del juego

    -- Claves foráneas hacia las dimensiones
    genre_id                    INTEGER NOT NULL,
    platform_id                 INTEGER NOT NULL,
    year_id                     INTEGER,              -- Puede ser NULL si falta año
    publisher_id                INTEGER,              -- Puede ser NULL si falta publisher

    -- Métricas y atributos del hecho
    metascore_num               REAL,        -- Metascore numérico normalizado
    copies_sold_millions_num    REAL,        -- Copias vendidas (en millones)
    categoria_ventas            TEXT,        -- Bajo / Medio / Alto
    categoria_calidad           TEXT,        -- Mala / Regular / Buena / Excelente

    -- Métricas agregadas por plataforma (ya calculadas en PySpark)
    num_juegos_plataforma       INTEGER,     -- Nº de juegos en la plataforma
    metascore_medio_plataforma  REAL,        -- Metascore medio en la plataforma
    ventas_totales_plataforma   REAL,        -- Ventas totales (millones) en la plataforma

    -- Información de auditoría
    fecha_carga                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Restricciones de integridad referencial (modelo estrella)
    FOREIGN KEY (genre_id)     REFERENCES dim_genre(genre_id),
    FOREIGN KEY (platform_id)  REFERENCES dim_platform(platform_id),
    FOREIGN KEY (year_id)      REFERENCES dim_year(year_id),
    FOREIGN KEY (publisher_id) REFERENCES dim_publisher(publisher_id)
);
