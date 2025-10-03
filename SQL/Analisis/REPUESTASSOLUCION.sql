USE jardineria;
--Producto más vendido (por cantidad)
SELECT TOP 1
    dp.nombre AS producto,
    SUM(hv.cantidad_vendida) AS total_vendido
FROM hechos_ventas hv
JOIN dim_producto dp ON hv.id_producto = dp.id_producto
GROUP BY dp.nombre
ORDER BY total_vendido DESC;

--Categoría con más productos
SELECT TOP 1
    dc.desc_categoria AS categoria,
    COUNT(dp.id_producto) AS num_productos
FROM dim_producto dp
JOIN dim_categoria dc ON dp.id_categoria = dc.id_categoria
GROUP BY dc.desc_categoria
ORDER BY num_productos DESC;

--Año con más ventas (por monto total)
SELECT TOP 1
    dt.año,
    SUM(hv.monto_total) AS total_ventas
FROM hechos_ventas hv
JOIN dim_tiempo dt ON hv.id_tiempo = dt.id_tiempo
GROUP BY dt.año
ORDER BY total_ventas DESC;

-------------------

