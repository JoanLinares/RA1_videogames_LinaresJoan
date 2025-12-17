
PRAGMA foreign_keys = ON;


DROP TABLE IF EXISTS fact_videogames;
DROP TABLE IF EXISTS dim_publisher;
DROP TABLE IF EXISTS dim_year;
DROP TABLE IF EXISTS dim_platform;
DROP TABLE IF EXISTS dim_genre;


CREATE TABLE dim_genre (
    genre_id   INTEGER PRIMARY KEY,
    genre      TEXT    NOT NULL UNIQUE
);


CREATE TABLE dim_platform (
    platform_id  INTEGER PRIMARY KEY,
    platform     TEXT    NOT NULL UNIQUE
);


CREATE TABLE dim_year (
    year_id  INTEGER PRIMARY KEY,
    year     INTEGER NOT NULL UNIQUE
);


CREATE TABLE dim_publisher (
    publisher_id  INTEGER PRIMARY KEY,
    publisher     TEXT    NOT NULL UNIQUE
);

-- --------------------------------------------------------------------------
-- TABLA DE HECHOS: fact_videogames
--  - Un registro por videojuego/plataforma en el dataset procesado con PySpark
--  - Contiene métricas agregadas a nivel de plataforma + categorías
-- --------------------------------------------------------------------------
CREATE TABLE fact_videogames (
    fact_id                     INTEGER PRIMARY KEY,
    name                        TEXT    NOT NULL,

    -- Claves foráneas hacia las dimensiones
    genre_id                    INTEGER NOT NULL,
    platform_id                 INTEGER NOT NULL,
    year_id                     INTEGER,
    publisher_id                INTEGER,

    -- Métricas y atributos del hecho
    metascore_num               REAL,
    copies_sold_millions_num    REAL,
    categoria_ventas            TEXT,
    categoria_calidad           TEXT,

    -- Métricas agregadas por plataforma (ya calculadas en PySpark)
    num_juegos_plataforma       INTEGER,
    metascore_medio_plataforma  REAL,
    ventas_totales_plataforma   REAL,

    -- Información de auditoría
    fecha_carga                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Restricciones de integridad referencial (modelo estrella)
    FOREIGN KEY (genre_id)     REFERENCES dim_genre(genre_id),
    FOREIGN KEY (platform_id)  REFERENCES dim_platform(platform_id),
    FOREIGN KEY (year_id)      REFERENCES dim_year(year_id),
    FOREIGN KEY (publisher_id) REFERENCES dim_publisher(publisher_id)
);
