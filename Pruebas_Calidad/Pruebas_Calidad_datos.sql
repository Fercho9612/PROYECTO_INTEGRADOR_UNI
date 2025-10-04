
-- PARTE 1: CALIDAD EN STAGING (jardineria_staging)
-- =====================================================
USE jardineria_staging;
GO

-- 1.1 Completitud: % de registros completos en tablas clave (vs. origen)
WITH Conteos AS (
    SELECT 'staging_producto' AS Tabla, COUNT(*) AS Total, COUNT(ID_producto) AS NoNull_ID, AVG(CASE WHEN nombre IS NOT NULL THEN 1 ELSE 0 END) * 100 AS Pct_NoNull_Nombre
    FROM staging_producto
    UNION ALL
    SELECT 'staging_pedido', COUNT(*), COUNT(ID_pedido), AVG(CASE WHEN fecha_pedido IS NOT NULL THEN 1 ELSE 0 END) * 100
    FROM staging_pedido
    UNION ALL
    SELECT 'staging_detalle_pedido', COUNT(*), COUNT(ID_detalle_pedido), AVG(CASE WHEN cantidad > 0 THEN 1 ELSE 0 END) * 100
    FROM staging_detalle_pedido
)
SELECT * FROM Conteos;
-- Esperado: >95% completitud; si <90%, revisar extracción.

-- 1.2 Consistencia: Duplicados en claves únicas
SELECT 'staging_producto' AS Tabla, COUNT(*) AS Duplicados
FROM (SELECT CodigoProducto FROM staging_producto GROUP BY CodigoProducto HAVING COUNT(*) > 1) AS Dups
UNION ALL
SELECT 'staging_pedido', COUNT(*)
FROM (SELECT ID_pedido FROM staging_pedido GROUP BY ID_pedido HAVING COUNT(*) > 1) AS Dups;
-- Esperado: 0 duplicados.

-- 1.3 Exactitud: Muestra 5 registros vs. origen (manual check)
SELECT TOP 5 'staging_producto' AS Tabla, CodigoProducto, nombre FROM staging_producto
UNION ALL
SELECT TOP 5 'origen_producto', CodigoProducto, nombre FROM jardineria.dbo.producto;
-- Compara manualmente: Deben coincidir post-transformación.

-- 1.4 Validez: Rangos lógicos
SELECT 
    SUM(CASE WHEN precio_venta > 0 THEN 1 ELSE 0 END) AS Precios_Validos,
    SUM(CASE WHEN precio_venta <= 0 THEN 1 ELSE 0 END) AS Precios_Invalidos,
    AVG(precio_venta) AS Promedio_Precio
FROM staging_producto;
-- Esperado: 100% precios >0; promedio ~50-100 basado en datos.

-- =====================================================
-- PARTE 2: CALIDAD EN DATA MART (jardineria)
-- =====================================================
USE jardineria;
GO

-- 2.1 Completitud en dimensiones y hechos
WITH Conteos_DM AS (
    SELECT 'dim_producto' AS Tabla, COUNT(*) AS Total, COUNT(id_producto) AS NoNull_ID
    FROM dim_producto
    UNION ALL
    SELECT 'hechos_ventas', COUNT(*), COUNT(id_venta)
    FROM hechos_ventas
)
SELECT * FROM Conteos_DM;
-- Esperado: Total > registros en staging (debido a IDENTITY).

-- 2.2 Consistencia: FK válidas (no orphans)
SELECT 'hechos_ventas -> dim_tiempo' AS Relacion, COUNT(*) AS Orfanos
FROM hechos_ventas hv LEFT JOIN dim_tiempo dt ON hv.id_tiempo = dt.id_tiempo
WHERE dt.id_tiempo IS NULL
UNION ALL
SELECT 'hechos_ventas -> dim_producto', COUNT(*)
FROM hechos_ventas hv LEFT JOIN dim_producto dp ON hv.id_producto = dp.id_producto
WHERE dp.id_producto IS NULL;
-- Esperado: 0 orfanos.

-- 2.3 Exactitud: Verificar monto_total calculado
SELECT TOP 5 
    cantidad_vendida, precio_unidad, monto_total,
    (cantidad_vendida * precio_unidad) AS Calculado_Manual
FROM hechos_ventas
WHERE ABS(monto_total - (cantidad_vendida * precio_unidad)) > 0.01;  -- Tolerancia por redondeo
-- Esperado: 0 rows (coincidencia perfecta).

-- 2.4 Validez: Fechas y cantidades lógicas
SELECT 
    MIN(fecha) AS Fecha_Min, MAX(fecha) AS Fecha_Max,
    SUM(CASE WHEN cantidad_vendida > 0 THEN 1 ELSE 0 END) AS Cantidades_Validas
FROM dim_tiempo dt JOIN hechos_ventas hv ON dt.id_tiempo = hv.id_tiempo;
-- Esperado: Fechas 2006-2009; 100% cantidades >0.

-- =====================================================
-- PARTE 3: RESUMEN GENERAL (Ejecutar al final)
-- =====================================================
-- CTE calcula % por campo directamente; outer query promedia y clasifica.

USE jardineria_staging;
GO

WITH Porcentajes_Campos AS (
    -- % no-NULL para 'nombre' (AL 100% post-extracción)
    SELECT 
        'nombre' AS Campo,
        ROUND((COUNT(nombre) * 100.0 / COUNT(*)), 2) AS Pct_NoNull
    FROM staging_producto
    UNION ALL
    -- % no-NULL para 'proveedor' (100% post-UPDATE en CREATE VIEW AND UPDATE.sql)
    SELECT 
        'proveedor' AS Campo,
        ROUND((COUNT(proveedor) * 100.0 / COUNT(*)), 2) AS Pct_NoNull
    FROM staging_producto
   
)
SELECT 
    'Calidad_General' AS Metrica,
    AVG(Pct_NoNull) AS Promedio_Porcentaje_NoNull,
    CASE 
        WHEN AVG(Pct_NoNull) >= 95 THEN 'Alta'
        WHEN AVG(Pct_NoNull) >= 80 THEN 'Media'
        ELSE 'Baja'
    END AS Nivel_Calidad,
    COUNT(*) AS Campos_Evaluados  -- Cuántos campos se chequean
FROM Porcentajes_Campos;
GO
