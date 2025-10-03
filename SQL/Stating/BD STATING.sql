DROP DATABASE IF EXISTS jardineria_staging;

CREATE DATABASE jardineria_staging;
GO

USE jardineria_staging;
GO

-- 2. Crear tablas en staging basadas en el modelo relacional de jardineria
CREATE TABLE staging_oficina (
    ID_oficina INT IDENTITY(1,1) PRIMARY KEY,
    Descripcion VARCHAR(10) NOT NULL,
    ciudad VARCHAR(30) NOT NULL,
    pais VARCHAR(50) NOT NULL,
    region VARCHAR(50) DEFAULT NULL,
    codigo_postal VARCHAR(10) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    linea_direccion1 VARCHAR(50) NOT NULL,
    linea_direccion2 VARCHAR(50) DEFAULT NULL
);

CREATE TABLE staging_empleado (
    ID_empleado INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido1 VARCHAR(50) NOT NULL,
    apellido2 VARCHAR(50) DEFAULT NULL,
    extension VARCHAR(10) NOT NULL,
    email VARCHAR(100) NOT NULL,
    ID_oficina INT NOT NULL,
    ID_jefe INT DEFAULT NULL,
    puesto VARCHAR(50) DEFAULT NULL
);

CREATE TABLE staging_Categoria_producto (
    Id_Categoria INT IDENTITY(1,1) PRIMARY KEY,
    Desc_Categoria VARCHAR(50) NOT NULL,
    descripcion_texto TEXT,
    descripcion_html TEXT,
    imagen VARCHAR(256)
);

CREATE TABLE staging_cliente (
    ID_cliente INT IDENTITY(1,1) PRIMARY KEY,
    nombre_cliente VARCHAR(50) NOT NULL,
    nombre_contacto VARCHAR(30) DEFAULT NULL,
    apellido_contacto VARCHAR(30) DEFAULT NULL,
    telefono VARCHAR(15) NOT NULL,
    fax VARCHAR(15) NOT NULL,
    linea_direccion1 VARCHAR(50) NOT NULL,
    linea_direccion2 VARCHAR(50) DEFAULT NULL,
    ciudad VARCHAR(50) NOT NULL,
    region VARCHAR(50) DEFAULT NULL,
    pais VARCHAR(50) DEFAULT NULL,
    codigo_postal VARCHAR(10) DEFAULT NULL,
    ID_empleado_rep_ventas INT DEFAULT NULL,
    limite_credito DECIMAL(15,2) DEFAULT NULL
);

CREATE TABLE staging_pedido (
    ID_pedido INT IDENTITY(1,1) PRIMARY KEY,
    fecha_pedido DATE NOT NULL,
    fecha_esperada DATE NOT NULL,
    fecha_entrega DATE DEFAULT NULL,
    estado VARCHAR(15) NOT NULL,
    comentarios TEXT,
    ID_cliente INT NOT NULL
);

CREATE TABLE staging_producto (
    ID_producto INT IDENTITY(1,1) PRIMARY KEY,
    CodigoProducto VARCHAR(15) NOT NULL,
    nombre VARCHAR(70) NOT NULL,
    Categoria INT NOT NULL,
    dimensiones VARCHAR(25),
    proveedor VARCHAR(50) DEFAULT NULL,
    descripcion TEXT,
    cantidad_en_stock SMALLINT NOT NULL,
    precio_venta DECIMAL(15,2) NOT NULL,
    precio_proveedor DECIMAL(15,2) DEFAULT NULL
);

CREATE TABLE staging_detalle_pedido (
    ID_detalle_pedido INT IDENTITY(1,1) PRIMARY KEY,
    ID_pedido INT NOT NULL,
    ID_producto INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unidad DECIMAL(15,2) NOT NULL,
    numero_linea SMALLINT NOT NULL
);

CREATE TABLE staging_pago (
    ID_pago INT IDENTITY(1,1) PRIMARY KEY,
    ID_cliente INT NOT NULL,
    forma_pago VARCHAR(40) NOT NULL,
    id_transaccion VARCHAR(50) NOT NULL,
    fecha_pago DATE NOT NULL,
    total DECIMAL(15,2) NOT NULL
);
GO

-- 3. Transferir registros de jardineria a staging con transformación mínima

INSERT INTO staging_oficina (Descripcion, ciudad, pais, region, codigo_postal, telefono, linea_direccion1, linea_direccion2)
SELECT 
    Descripcion, 
    ciudad, 
    REPLACE(pais, 'EspaÃ±a', 'España') AS pais, 
    region, 
    codigo_postal, 
    telefono, 
    linea_direccion1, 
    linea_direccion2
FROM jardineria.dbo.oficina;

INSERT INTO staging_empleado (nombre, apellido1, apellido2, extension, email, ID_oficina, ID_jefe, puesto)
SELECT 
nombre, 
apellido1, 
apellido2, 
extension, 
email, 
ID_oficina, 
ID_jefe, 
puesto
FROM jardineria.dbo.empleado;

INSERT INTO staging_Categoria_producto (Desc_Categoria, descripcion_texto, descripcion_html, imagen)
SELECT 
Desc_Categoria, 
descripcion_texto, 
descripcion_html, 
imagen
FROM jardineria.dbo.Categoria_producto;

INSERT INTO staging_cliente (nombre_cliente, nombre_contacto, apellido_contacto, telefono, fax, linea_direccion1, linea_direccion2, ciudad, region, pais, codigo_postal, ID_empleado_rep_ventas, limite_credito)
SELECT 
nombre_cliente, 
nombre_contacto, 
apellido_contacto,
telefono, 
fax, 
linea_direccion1, 
linea_direccion2,
ciudad, 
region, 
pais, 
codigo_postal, 
ID_empleado_rep_ventas, 
limite_credito
FROM jardineria.dbo.cliente;

INSERT INTO staging_pedido (fecha_pedido, fecha_esperada, fecha_entrega, estado, comentarios, ID_cliente)
SELECT 
fecha_pedido, 
fecha_esperada, 
fecha_entrega, 
estado, 
comentarios, 
ID_cliente
FROM jardineria.dbo.pedido;

INSERT INTO staging_producto (CodigoProducto, nombre, Categoria, dimensiones, proveedor, descripcion, cantidad_en_stock, precio_venta, precio_proveedor)
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
FROM jardineria.dbo.producto;

INSERT INTO staging_detalle_pedido (ID_pedido, ID_producto, cantidad, precio_unidad, numero_linea)
SELECT 
ID_pedido, 
ID_producto, 
cantidad, 
precio_unidad,
numero_linea
FROM jardineria.dbo.detalle_pedido;

INSERT INTO staging_pago (ID_cliente, forma_pago, id_transaccion, fecha_pago, total)
SELECT 
ID_cliente, 
forma_pago, 
id_transaccion, 
fecha_pago, 
total
FROM jardineria.dbo.pago;
GO

-- Verificar muestras de datos
SELECT TOP 5 * FROM staging_oficina;  -- Mostrar datos limpios

-- 4. Validar que los datos se almacenaron correctamente

SELECT 'Fuente' AS Origen, COUNT(*) AS Registros FROM jardineria.dbo.oficina
UNION ALL SELECT 'Staging', COUNT(*) FROM staging_oficina
UNION ALL
SELECT 'Fuente' AS Origen, COUNT(*) AS Registros FROM jardineria.dbo.empleado
UNION ALL SELECT 'Staging', COUNT(*) FROM staging_empleado
UNION ALL
SELECT 'Fuente' AS Origen, COUNT(*) AS Registros FROM jardineria.dbo.Categoria_producto
UNION ALL SELECT 'Staging', COUNT(*) FROM staging_Categoria_producto
UNION ALL
SELECT 'Fuente' AS Origen, COUNT(*) AS Registros FROM jardineria.dbo.cliente
UNION ALL SELECT 'Staging', COUNT(*) FROM staging_cliente
UNION ALL
SELECT 'Fuente' AS Origen, COUNT(*) AS Registros FROM jardineria.dbo.pedido
UNION ALL SELECT 'Staging', COUNT(*) FROM staging_pedido
UNION ALL
SELECT 'Fuente' AS Origen, COUNT(*) AS Registros FROM jardineria.dbo.producto
UNION ALL SELECT 'Staging', COUNT(*) FROM staging_producto
UNION ALL
SELECT 'Fuente' AS Origen, COUNT(*) AS Registros FROM jardineria.dbo.detalle_pedido
UNION ALL SELECT 'Staging', COUNT(*) FROM staging_detalle_pedido
UNION ALL
SELECT 'Fuente' AS Origen, COUNT(*) AS Registros FROM jardineria.dbo.pago
UNION ALL SELECT 'Staging', COUNT(*) FROM staging_pago;
GO

-- 5. Crear backups de ambas bases de datos
BACKUP DATABASE jardineria TO DISK = 'M:\ENTORNO DESARROLLO\SQLSERVER\Backups\jardineria_backup_20250915.bak' WITH FORMAT, INIT, NAME = 'Backup de Jardineria - 2025-09-15';
GO

BACKUP DATABASE jardineria_staging TO DISK = 'M:\ENTORNO DESARROLLO\SQLSERVER\Backups\jardineria_staging_backup_20250915.bak' WITH FORMAT, INIT, NAME = 'Backup de Jardineria Staging - 2025-09-15';
GO