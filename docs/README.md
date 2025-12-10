# 📊 RA1 - Análisis de Videojuegos con Pandas y PySpark

## 📋 Índice
1. [Introducción](#introducción)
2. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
3. [Fase 1: Exploración y Limpieza con Pandas](#fase-1-exploración-y-limpieza-con-pandas)
4. [Fase 2: Procesamiento con PySpark](#fase-2-procesamiento-con-pyspark)
5. [Fase 3: ETL con Pandas](#fase-3-etl-con-pandas)
6. [Fase 4: ETL con PySpark y Modelo Dimensional](#fase-4-etl-con-pyspark-y-modelo-dimensional)
7. [Decisiones Técnicas y Justificación](#decisiones-técnicas-y-justificación)
8. [Ejecución del Proyecto](#ejecución-del-proyecto)

---

## 📖 Introducción

Este proyecto implementa un proceso completo de **análisis de datos de videojuegos** utilizando dos enfoques complementarios:
- **Pandas**: Para procesamiento en memoria y análisis exploratorio
- **PySpark**: Para procesamiento distribuido y escalabilidad

El objetivo principal es realizar la **exploración, limpieza, transformación y carga (ETL)** de un dataset de videojuegos, culminando en la creación de un **data warehouse dimensional** almacenado en bases de datos SQLite.


## 🧹 Fase 1: Exploración y Limpieza con Pandas

### Objetivos
1. Cargar el dataset desde múltiples rutas posibles (local/contenedor)
2. Analizar tipos de datos y detectar valores faltantes
3. Realizar limpieza exhaustiva de datos
4. Normalizar y transformar columnas

### Proceso de Limpieza

#### 1. **Detección de Valores Especiales**
Se identificaron y reemplazaron valores que representaban datos faltantes pero no eran reconocidos como `NaN`:
```python
specials = ['?', 'N/A', 'Unknown', 'unknown', '', ' ', 'nan', 'NaN']
df_clean = df_clean.replace(specials, np.nan)
```

**Justificación**: Los datasets del mundo real contienen múltiples representaciones de valores faltantes que deben estandarizarse para un tratamiento consistente.

#### 2. **Eliminación de Duplicados**
```python
df_clean = df_clean.drop_duplicates()
```

**Justificación**: Los duplicados pueden sesgar estadísticas y análisis. Se eliminan para garantizar la integridad de los datos.

#### 3. **Tratamiento de Valores Faltantes**

##### Estrategia adoptada:
- **Columnas con >60% de nulos**: Se eliminan completamente
  - **Justificación**: Columnas con tantos valores faltantes no aportan información útil y pueden generar bias
  
- **Filas con >60% de nulos**: Se eliminan
  - **Justificación**: Registros incompletos que no permiten análisis confiable

- **Imputación de valores numéricos**: Se usa la **mediana**
  ```python
  for col in num_cols:
      med = df_clean[col].median()
      df_clean[col] = df_clean[col].fillna(med)
  ```
  - **Justificación**: La mediana es robusta ante outliers, a diferencia de la media

- **Imputación de valores categóricos**: Se usa la **moda** (valor más frecuente)
  ```python
  for col in cat_cols:
      moda = df_clean[col].mode()
      if not moda.empty:
          df_clean[col] = df_clean[col].fillna(moda.iloc[0])
  ```
  - **Justificación**: La moda mantiene la distribución original de las categorías

#### 4. **Normalización de Texto**
```python
# Limpieza de espacios en blanco
df_clean[col] = df_clean[col].astype(str).str.strip()

# Unificación de plataformas
platform_map = {
    'ps': 'PS', 'playstation': 'PS', 'ps4': 'PS', 'ps5': 'PS',
    'xbox': 'Xbox', 'xbox one': 'Xbox', ...
}
```

**Justificación**: 
- Elimina inconsistencias en la entrada de datos
- Reduce la cardinalidad de variables categóricas
- Facilita agrupaciones y análisis posteriores

#### 5. **Transformación de Columnas Numéricas**

Se crearon funciones especializadas para parsear diferentes formatos:

##### `parse_cost()`: Precios de videojuegos
- Convierte: `'$59.99'`, `'€49,99'`, `'free'` → valores numéricos
- Maneja múltiples divisas y formatos de separadores
- **Justificación**: Los precios vienen en formatos diversos que necesitan estandarización

##### `parse_score()`: Puntuaciones
- Normaliza escalas: `'8.5/10'` → `85.0`, `'47.7'` → `47.7`
- **Justificación**: Las puntuaciones pueden estar en escala 0-10 o 0-100; se unifican a 0-100

##### `parse_millions()`: Ventas e ingresos
- Convierte: `'10M'` → `10.0`, `'1.5B'` → `1500.0` (millones)
- **Justificación**: Estandariza unidades para cálculos matemáticos correctos

#### 6. **Escalado de Variables Numéricas**
```python
df_clean[col + '_scaled'] = (df_clean[col] - col_min) / (col_max - col_min)
```

**Justificación**: 
- Normaliza valores a rango [0, 1]
- Facilita comparaciones entre variables de diferentes escalas
- Prepara datos para posibles modelos de machine learning

### Resultado Final
- **0 valores NaN** en el dataset limpio
- Datos completamente normalizados y listos para análisis
- Nuevas columnas calculadas con información derivada

---

## ⚡ Fase 2: Procesamiento con PySpark

### Objetivos
1. Crear SparkSession para procesamiento distribuido
2. Aplicar transformaciones sobre grandes volúmenes de datos
3. Demostrar capacidades de agregación y joins

### Transformaciones Aplicadas

#### 1. **Selección y Filtrado**
```python
df_filtered = (
    df_numeric
    .filter(col("metascore_num").isNotNull())
    .filter(col("copies_sold_millions_num").isNotNull())
)
```

**Justificación**: Se filtran registros con valores nulos en métricas clave para garantizar análisis válidos.

#### 2. **Agregación por Género**
```python
df_by_genre = (
    df_filtered
    .groupBy("genre")
    .agg(
        count("*").alias("num_juegos"),
        avg("metascore_num").alias("metascore_medio"),
        sum("copies_sold_millions_num").alias("ventas_totales")
    )
)
```

**Justificación**: 
- Identifica géneros más populares y rentables
- Permite análisis de tendencias por categoría
- Útil para decisiones de negocio

#### 3. **Creación de Columnas Calculadas**
```python
df_with_new_cols = df_filtered.withColumn(
    "categoria_ventas",
    when(col("copies_sold_millions_num") >= 5, "Alto")
    .when(col("copies_sold_millions_num") >= 1, "Medio")
    .otherwise("Bajo")
)
```

**Justificación**: 
- Categoriza juegos por rendimiento comercial
- Facilita segmentación y análisis comparativo
- Proporciona insights de negocio claros

#### 4. **Join y Análisis Cruzado**
```python
df_joined = (
    df_with_new_cols
    .join(df_platform_stats, on="platform", how="left")
)
```

**Justificación**: 
- Enriquece cada registro con estadísticas agregadas de su plataforma
- Permite comparar rendimiento individual vs. promedio de plataforma
- Demuestra capacidad de PySpark para operaciones complejas

---

## 🔄 Fase 3: ETL con Pandas

### Proceso ETL

#### **Extracción (E)**
- Se reutiliza el DataFrame limpio de la Fase 1
- Datos ya validados y normalizados

#### **Transformación (T)**

##### Nuevas Columnas Calculadas:
1. **`score_promedio`**: Promedio entre metascore y user_score
   - **Justificación**: Combina opinión de críticos y usuarios

2. **`categoria_ventas`**: Clasificación de rendimiento comercial
   - Bajo: < 1M copias
   - Moderado: 1-5M copias
   - Exitoso: 5-10M copias
   - Blockbuster: > 10M copias
   - **Justificación**: Segmentación clara para análisis de negocio

3. **`ingreso_por_copia`**: Revenue / Copias vendidas
   - **Justificación**: Métrica de monetización efectiva

##### Agregaciones Creadas:
- **`by_genre`**: Estadísticas por género
- **`by_platform`**: Estadísticas por plataforma

#### **Carga (L)**
```python
df_etl.to_sql('videogames', conn, if_exists='replace', index=False)
df_by_genre.to_sql('by_genre', conn, if_exists='replace', index=False)
df_by_platform.to_sql('by_platform', conn, if_exists='replace', index=False)
```

**Resultado**: Base de datos `warehouse_pandas.db` con 3 tablas

---

## 🌟 Fase 4: ETL con PySpark y Modelo Dimensional

### Modelo Dimensional (Esquema Estrella)

#### 🎯 **Diseño del Modelo**

```
            ┌─────────────────┐
            │   dim_genre     │
            ├─────────────────┤
            │ genre_id (PK)   │◄─────┐
            │ genre           │      │
            └─────────────────┘      │
                                     │
                                     │
            ┌─────────────────────────────────────┐
            │      fact_videogames                │
            ├─────────────────────────────────────┤
            │ fact_id (PK)                        │
            │ genre_id (FK)                       │──┘
            │ platform_id (FK)                    │──┐
            │ name                                │  │
            │ metascore_num                       │  │
            │ copies_sold_millions_num            │  │
            │ categoria_ventas                    │  │
            │ categoria_calidad                   │  │
            │ num_juegos_plataforma               │  │
            │ metascore_medio_plataforma          │  │
            │ ventas_totales_plataforma           │  │
            └─────────────────────────────────────┘  │
                                     │               │
                                     │               │
            ┌─────────────────┐     │               │
            │  dim_platform   │     │               │
            ├─────────────────┤     │               │
            │ platform_id (PK)│◄────┘               │
            │ platform        │                     │
            └─────────────────┘                     │
```

### 📊 Justificación del Modelo Dimensional

#### **¿Por qué un Esquema Estrella?**

1. **Simplicidad de Consultas**
   - Las queries son más intuitivas y rápidas
   - Menos JOINs necesarios para análisis
   - Ideal para herramientas de BI

2. **Rendimiento Optimizado**
   - Desnormalización controlada reduce JOINs
   - Índices eficientes en claves foráneas
   - Consultas analíticas más rápidas

3. **Escalabilidad**
   - Fácil agregar nuevas dimensiones
   - Tablas independientes facilitan mantenimiento
   - Crecimiento lineal de datos

### 📐 Decisiones sobre Dimensiones

#### **Dimensión 1: `dim_genre` (Género)**

**Campos:**
- `genre_id`: Clave primaria auto-generada
- `genre`: Nombre del género

**Justificación:**
- **Alto poder analítico**: Los géneros son fundamentales en la industria del videojuego
- **Baja cardinalidad**: ~10-20 géneros únicos (Action, RPG, Sports, etc.)
- **Estabilidad**: Los géneros no cambian frecuentemente
- **Casos de uso**:
  - Análisis de tendencias por género
  - Comparación de rendimiento entre categorías
  - Identificación de géneros más rentables

#### **Dimensión 2: `dim_platform` (Plataforma)**

**Campos:**
- `platform_id`: Clave primaria auto-generada
- `platform`: Nombre de la plataforma

**Justificación:**
- **Relevancia comercial**: Las plataformas definen mercados y estrategias
- **Cardinalidad media**: ~15-30 plataformas (PS, Xbox, PC, Switch, etc.)
- **Impacto en ventas**: Diferentes plataformas tienen diferentes bases de usuarios
- **Casos de uso**:
  - Análisis de market share por plataforma
  - Comparación de rendimiento multiplataforma
  - Estrategias de lanzamiento exclusivo vs. multiplataforma

#### **¿Por qué NO se incluyeron otras dimensiones?**

##### `dim_publisher` (Editorial) - NO incluida
- **Alta cardinalidad**: Cientos de publishers únicos
- **Menor impacto analítico** en este contexto
- **Complejidad innecesaria** para el alcance del proyecto

##### `dim_tiempo` (Fecha de lanzamiento) - NO incluida
- **Datos incompletos**: Muchos registros sin fecha precisa
- **Análisis temporal**: Requeriría granularidad (año, mes, trimestre) que no es prioritaria
- **Posible extensión futura**

### 🎲 Tabla de Hechos: `fact_videogames`

**Métricas (Measures):**
- `metascore_num`: Puntuación crítica
- `copies_sold_millions_num`: Volumen de ventas
- `num_juegos_plataforma`: Contexto de la plataforma
- `metascore_medio_plataforma`: Benchmark de plataforma
- `ventas_totales_plataforma`: Potencial de mercado

**Dimensiones (Foreign Keys):**
- `genre_id`: Enlace a dim_genre
- `platform_id`: Enlace a dim_platform

**Atributos Descriptivos:**
- `name`: Nombre del juego
- `categoria_ventas`: Segmentación comercial
- `categoria_calidad`: Segmentación por calidad

**Justificación del Diseño:**
- **Granularidad**: Un registro por juego (nivel más atómico)
- **Desnormalización controlada**: Se incluyen estadísticas agregadas de plataforma para evitar re-cálculos frecuentes
- **Balance**: Combina datos transaccionales (ventas) con métricas derivadas (categorías)

### 🔍 Ventajas del Modelo Implementado

1. **Consultas Eficientes**
   ```sql
   -- Ejemplo: Ventas totales por género y plataforma
   SELECT 
       g.genre,
       p.platform,
       SUM(f.copies_sold_millions_num) as ventas_totales
   FROM fact_videogames f
   JOIN dim_genre g ON f.genre_id = g.genre_id
   JOIN dim_platform p ON f.platform_id = p.platform_id
   GROUP BY g.genre, p.platform;
   ```

2. **Mantenimiento Simplificado**
   - Actualizar un género afecta solo a `dim_genre`
   - Agregar nueva plataforma no altera estructura existente

3. **Escalabilidad**
   - Millones de registros en `fact_videogames` con performance óptima
   - Dimensiones pequeñas caben en memoria/caché

4. **Extensibilidad**
   - Fácil agregar `dim_tiempo` en el futuro
   - Posible incluir `dim_publisher` si la cardinalidad se controla

---

## 🛠️ Decisiones Técnicas y Justificación

### Tecnologías Elegidas

#### **Pandas**
✅ **Ventajas:**
- Sintaxis intuitiva y Pythonic
- Excelente para datasets de tamaño medio (<10GB)
- Amplio ecosistema de visualización (Matplotlib, Seaborn)
- Integración nativa con SQLite

❌ **Limitaciones:**
- Procesamiento en memoria (limitado por RAM)
- No apto para datasets >100GB

**Uso en el proyecto**: Exploración inicial, limpieza exhaustiva, análisis exploratorio

#### **PySpark**
✅ **Ventajas:**
- Procesamiento distribuido (escala a terabytes)
- Lazy evaluation (optimización automática)
- API similar a SQL y Pandas
- Tolerancia a fallos

❌ **Limitaciones:**
- Mayor overhead para datasets pequeños
- Curva de aprendizaje más pronunciada

**Uso en el proyecto**: Transformaciones complejas, agregaciones masivas, preparación para producción

### Estrategias de Limpieza

| Problema | Solución Adoptada | Alternativa Descartada | Justificación |
|----------|-------------------|------------------------|---------------|
| Valores faltantes en columnas clave | Imputación con mediana/moda | Eliminación de filas | Preserva el 80-90% de los datos |
| Columnas con >60% nulos | Eliminación completa | Imputación avanzada (ML) | Coste-beneficio: demasiado esfuerzo para información limitada |
| Duplicados exactos | Eliminación | Deduplicación parcial | Los duplicados exactos son claramente errores de carga |
| Formatos inconsistentes | Parsing especializado | Regex genérico | Mayor precisión y control sobre casos edge |
| Escalas diferentes | Min-Max normalization | Standardization (Z-score) | Rango [0,1] es más interpretable |

### Arquitectura de Datos

```
RAW DATA (CSV)
     ↓
[LIMPIEZA Y NORMALIZACIÓN]
     ↓
CLEAN DATA (DataFrame)
     ↓
[TRANSFORMACIONES ETL]
     ↓
MODELO DIMENSIONAL
     ↓
WAREHOUSE (SQLite)
     ↓
[CONSULTAS ANALÍTICAS]
```

---

## 🚀 Ejecución del Proyecto

### Prerequisitos
- Docker y Docker Compose instalados
- Python 3.9+
- Jupyter Notebook

### Opción 1: Ejecución con Docker

```bash
# Levantar servicios
docker-compose up -d

# Acceder a Jupyter
# Abrir navegador en: http://localhost:8888
```

### Opción 2: Ejecución Local

```bash
# Instalar dependencias
pip install pandas numpy pyspark scikit-learn jupyter

# Ejecutar notebooks
jupyter notebook notebooks/01_pandas.ipynb
jupyter notebook notebooks/02_pyspark.ipynb
```

### Verificación de Resultados

```python
import sqlite3
import pandas as pd

# Verificar warehouse Pandas
conn = sqlite3.connect('warehouse/warehouse_pandas.db')
print(pd.read_sql("SELECT name FROM sqlite_master WHERE type='table'", conn))

# Verificar warehouse PySpark
conn_spark = sqlite3.connect('warehouse/warehouse_pyspark.db')
print(pd.read_sql("SELECT name FROM sqlite_master WHERE type='table'", conn_spark))
```

---

## 📊 Resultados Obtenidos

### Métricas de Calidad de Datos

| Métrica | Antes de Limpieza | Después de Limpieza |
|---------|-------------------|---------------------|
| Valores nulos | ~15-30% | 0% |
| Duplicados | ~2-5% | 0% |
| Formatos inconsistentes | Múltiples | Estandarizados |
| Columnas eliminadas | 0 | Columnas con >60% nulos |

### Estructura Final de Bases de Datos

#### `warehouse_pandas.db`
- `videogames`: Tabla principal con todos los datos transformados
- `by_genre`: Agregaciones por género
- `by_platform`: Agregaciones por plataforma

#### `warehouse_pyspark.db`
- `dim_genre`: Dimensión de géneros (10-20 registros)
- `dim_platform`: Dimensión de plataformas (15-30 registros)
- `fact_videogames`: Tabla de hechos (miles de registros)

---

## 🎯 Conclusiones

### Logros del Proyecto

1. ✅ **Limpieza exhaustiva**: 100% de datos válidos y normalizados
2. ✅ **Dos enfoques complementarios**: Pandas (análisis) + PySpark (escalabilidad)
3. ✅ **Modelo dimensional optimizado**: Esquema estrella con 2 dimensiones y 1 tabla de hechos
4. ✅ **ETL completo**: Extracción, transformación y carga en data warehouse
5. ✅ **Documentación detallada**: Justificación de cada decisión técnica

### Lecciones Aprendidas

1. **Limpieza de datos es el 80% del trabajo**: La mayor parte del esfuerzo se invirtió en entender y limpiar los datos
2. **La imputación inteligente preserva información**: Usar mediana/moda es mejor que eliminar registros
3. **El modelo dimensional simplifica análisis**: Aunque requiere más diseño inicial, las consultas son mucho más simples
4. **PySpark brilla en agregaciones complejas**: Para transformaciones masivas, PySpark supera ampliamente a Pandas

### Posibles Extensiones Futuras

1. **Añadir `dim_tiempo`**: Para análisis de tendencias temporales
2. **Implementar `dim_publisher`**: Si se controla la cardinalidad con agrupaciones
3. **Visualizaciones interactivas**: Dashboard con Plotly/Dash
4. **Machine Learning**: Modelos predictivos de éxito comercial
5. **Pipeline automatizado**: Airflow/Prefect para ETL recurrente

---

## 👤 Autor

**Joan Linares**  
Proyecto: RA1 - Análisis de Videojuegos  
Fecha: Diciembre 2025

---

## 📚 Referencias

- [Pandas Documentation](https://pandas.pydata.org/docs/)
- [PySpark Documentation](https://spark.apache.org/docs/latest/api/python/)
- [Kimball's Data Warehouse Toolkit](https://www.kimballgroup.com/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
