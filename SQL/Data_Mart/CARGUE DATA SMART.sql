USE jardineria;
GO

-- Cargar dim_tiempo desde staging_pedido (fechas únicas)
INSERT INTO dim_tiempo (fecha, año, mes, dia)
SELECT DISTINCT 
    fecha_pedido,
    YEAR(fecha_pedido) AS año,
    MONTH(fecha_pedido) AS mes,
    DAY(fecha_pedido) AS dia
FROM jardineria_staging.dbo.staging_pedido
WHERE fecha_pedido IS NOT NULL
ORDER BY fecha_pedido;

-- Cargar dim_categoria desde staging_Categoria_producto
INSERT INTO dim_categoria (desc_categoria, descripcion_texto, descripcion_html, imagen)
SELECT 
    Desc_Categoria,
    descripcion_texto,
    descripcion_html,
    imagen
FROM jardineria_staging.dbo.staging_Categoria_producto;

-- Cargar dim_producto desde staging_producto (nota: id_categoria se mapea por IDENTITY, pero asumimos orden coincide; en producción, usar merge)
INSERT INTO dim_producto (codigo_producto, nombre, id_categoria, dimensiones, proveedor, descripcion, cantidad_en_stock, precio_venta, precio_proveedor)
SELECT 
    CodigoProducto,
    nombre,
    Categoria,  -- Asumimos que Categoria en staging es el ID original que coincide con IDENTITY en dim_categoria
    dimensiones,
    proveedor,
    descripcion,
    cantidad_en_stock,
    precio_venta,
    precio_proveedor
FROM jardineria_staging.dbo.staging_producto;

-- Cargar hechos_ventas (join con staging para filtrar entregados)
INSERT INTO hechos_ventas (id_tiempo, id_producto, id_categoria, cantidad_vendida, precio_unidad)
SELECT 
    dt.id_tiempo,
    dp.id_producto,
    dc.id_categoria,
    sd.cantidad,
    sd.precio_unidad
FROM jardineria_staging.dbo.staging_detalle_pedido sd
JOIN jardineria_staging.dbo.staging_pedido sp ON sd.ID_pedido = sp.ID_pedido
JOIN jardineria_staging.dbo.staging_producto sprod ON sd.ID_producto = sprod.ID_producto
JOIN dim_tiempo dt ON sp.fecha_pedido = dt.fecha
JOIN dim_producto dp ON sprod.CodigoProducto = dp.codigo_producto  -- Mapeo por código único en lugar de ID
JOIN dim_categoria dc ON sprod.Categoria = dc.id_categoria  -- Asumimos coincidencia
WHERE sp.estado = 'Entregado';  -- Solo ventas confirmadas
GO


-- Verificar conteos en data mart
SELECT 'dim_tiempo' AS Tabla, COUNT(*) AS Registros FROM dim_tiempo
UNION ALL SELECT 'dim_categoria', COUNT(*) FROM dim_categoria
UNION ALL SELECT 'dim_producto', COUNT(*) FROM dim_producto
UNION ALL SELECT 'hechos_ventas', COUNT(*) FROM hechos_ventas;

-- Muestra
SELECT TOP 5 * FROM hechos_ventas;