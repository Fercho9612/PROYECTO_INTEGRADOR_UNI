-- Usar la base de datos existente 'jardineria'
USE jardineria;

-- Crear dimensión de tiempo (basada en fecha_pedido)
CREATE TABLE dim_tiempo (
    id_tiempo INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATE,
    año INT,
    mes INT,
    dia INT,
    trimestre AS (DATEPART(QUARTER, fecha)) PERSISTED -- Calcula trimestre automáticamente
);

-- Poblar dim_tiempo con fechas únicas de pedidos
INSERT INTO dim_tiempo (fecha, año, mes, dia)
SELECT DISTINCT 
    fecha_pedido,
    YEAR(fecha_pedido) AS año,
    MONTH(fecha_pedido) AS mes,
    DAY(fecha_pedido) AS dia
FROM pedido
WHERE fecha_pedido IS NOT NULL
ORDER BY fecha_pedido;

-- Crear dimensión de categoría
CREATE TABLE dim_categoria (
    id_categoria INT IDENTITY(1,1) PRIMARY KEY,
    desc_categoria VARCHAR(50) NOT NULL,
    descripcion_texto TEXT,
    descripcion_html TEXT,
    imagen VARCHAR(256)
);

-- Poblar dim_categoria desde Categoria_producto
INSERT INTO dim_categoria (desc_categoria, descripcion_texto, descripcion_html, imagen)
SELECT 
    Desc_Categoria,
    descripcion_texto,
    descripcion_html,
    imagen
FROM Categoria_producto;

-- Crear dimensión de producto
CREATE TABLE dim_producto (
    id_producto INT IDENTITY(1,1) PRIMARY KEY,
    codigo_producto VARCHAR(15) NOT NULL,
    nombre VARCHAR(70) NOT NULL,
    id_categoria INT,
    dimensiones VARCHAR(25),
    proveedor VARCHAR(50),
    descripcion TEXT,
    cantidad_en_stock SMALLINT,
    precio_venta DECIMAL(15,2) NOT NULL,
    precio_proveedor DECIMAL(15,2),
    FOREIGN KEY (id_categoria) REFERENCES dim_categoria(id_categoria)
);

-- Poblar dim_producto desde producto
INSERT INTO dim_producto (codigo_producto, nombre, id_categoria, dimensiones, proveedor, descripcion, cantidad_en_stock, precio_venta, precio_proveedor)
SELECT 
    CodigoProducto,
    nombre,
    Categoria,
    dimensiones,
    proveedor,
    descripcion,
    cantidad_en_stock,
    precio_venta,
    precio_proveedor
FROM producto;

-- Crear tabla de hechos para ventas
CREATE TABLE hechos_ventas (
    id_venta INT IDENTITY(1,1) PRIMARY KEY,
    id_tiempo INT,
    id_producto INT,
    id_categoria INT,
    cantidad_vendida INT NOT NULL,
    precio_unidad DECIMAL(15,2) NOT NULL,
    monto_total AS (cantidad_vendida * precio_unidad) PERSISTED, -- Calculado automáticamente
    FOREIGN KEY (id_tiempo) REFERENCES dim_tiempo(id_tiempo),
    FOREIGN KEY (id_producto) REFERENCES dim_producto(id_producto),
    FOREIGN KEY (id_categoria) REFERENCES dim_categoria(id_categoria)
);

-- Poblar hechos_ventas desde detalle_pedido, pedido, producto y dimensiones
INSERT INTO hechos_ventas (id_tiempo, id_producto, id_categoria, cantidad_vendida, precio_unidad)
SELECT 
    dt.id_tiempo,
    dp.id_producto, -- Usamos el ID de dim_producto en lugar de ID_producto directo
    dc.id_categoria,
    dpd.cantidad,
    dpd.precio_unidad
FROM detalle_pedido dpd
JOIN pedido p ON dpd.ID_pedido = p.ID_pedido
JOIN producto prod ON dpd.ID_producto = prod.ID_producto
JOIN dim_tiempo dt ON p.fecha_pedido = dt.fecha
JOIN dim_producto dp ON prod.ID_producto = dp.id_producto
JOIN dim_categoria dc ON prod.Categoria = dc.id_categoria
WHERE p.estado = 'Entregado'; -- Solo considerar pedidos entregados

---------------------------------------------------------------------
-- Verificar conteos en data mart
SELECT 'dim_tiempo' AS Tabla, COUNT(*) AS Registros FROM dim_tiempo
UNION ALL SELECT 'dim_categoria', COUNT(*) FROM dim_categoria
UNION ALL SELECT 'dim_producto', COUNT(*) FROM dim_producto
UNION ALL SELECT 'hechos_ventas', COUNT(*) FROM hechos_ventas;

-- Muestra
SELECT TOP 5 * FROM hechos_ventas;