-- transformación en staging
USE jardineria_staging;
GO

-- Ejemplo para staging_producto
UPDATE staging_producto
SET nombre = LTRIM(RTRIM(nombre)),  -- Elimina espacios extra al inicio/fin
    proveedor = LTRIM(RTRIM(proveedor)),
    dimensiones = LTRIM(RTRIM(dimensiones));

-- Normalización

UPDATE staging_Categoria_producto
SET Desc_Categoria = UPPER(LEFT(Desc_Categoria, 1)) + LOWER(SUBSTRING(Desc_Categoria, 2, LEN(Desc_Categoria)));

-- Manejo de NULLs
UPDATE staging_producto
SET proveedor = 'Desconocido'
WHERE proveedor IS NULL;

-- Enriquecimiento
--ALTER TABLE staging_pedido ADD año INT NULL;
UPDATE staging_pedido
SET año = YEAR(fecha_pedido);

-- Verificar duplicados en staging_detalle_pedido (por si hay errores en datos)

SELECT ID_pedido, ID_producto, COUNT(*) AS duplicados
FROM staging_detalle_pedido
GROUP BY ID_pedido, ID_producto
HAVING COUNT(*) > 1;  

-- Verificación post-transformación
SELECT TOP 5 nombre, proveedor FROM staging_producto;  -- Debe mostrar datos limpios
GO