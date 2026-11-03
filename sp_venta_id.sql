/* 2026-10-26 10:48:21 [8 ms] */ 
CREATE PROCEDURE sp_venta_id(
    IN p_id_venta INT
)
BEGIN
    SELECT 
        v.fecha_venta,
        c.nombre_completo AS nombre_cliente,
        c.direccion_despacho AS ciudad_cliente, -- O la columna donde almacenes la ciudad/ubicación del cliente
        p.nombre_producto AS producto,
        v.cantidad,
        (v.cantidad * p.precio_unitario) AS monto_venta
    FROM ventas v
    INNER JOIN clientes c ON v.id_cliente = c.id_cliente
    INNER JOIN productos p ON v.id_producto = p.id_producto
    WHERE v.id_venta = p_id_venta;
END;
/* 2026-10-26 10:50:13 [9 ms] */ 
CREATE PROCEDURE db_ventas_tech(
    IN p_sucursal INT,
    IN p_anio INT
)
BEGIN
    -- Validar que si el año es distinto de 0, sea estrictamente mayor a 2000.
    -- Si es <= 2000 y diferente de 0, devuelve un conjunto de datos vacío.
    IF p_anio != 0 AND p_anio <= 2000 THEN
        SELECT 
            v.id_venta,
            DATE_FORMAT(v.fecha_venta, '%d-%m-%Y') AS fecha_venta,
            c.id_cliente,
            c.nombre_completo AS nombre_cliente,
            c.estado_membresia AS estado_membresia_cliente,
            c.tipo_cliente,
            cat.nombre_categoria AS nombre_categoria_producto,
            p.nombre_producto,
            v.cantidad,
            (v.cantidad * p.precio_unitario) AS monto_total_venta
        FROM ventas v
        JOIN clientes c ON v.id_cliente = c.id_cliente
        JOIN productos p ON v.id_producto = p.id_producto
        JOIN categorias cat ON p.id_categoria = cat.id_categoria
        WHERE 1 = 0; -- Retorna conjunto vacío
    ELSE
        SELECT 
            v.id_venta,
            DATE_FORMAT(v.fecha_venta, '%d-%m-%Y') AS fecha_venta,
            c.id_cliente,
            c.nombre_completo AS nombre_cliente,
            c.estado_membresia AS estado_membresia_cliente,
            c.tipo_cliente,
            cat.nombre_categoria AS nombre_categoria_producto,
            p.nombre_producto,
            v.cantidad,
            (v.cantidad * p.precio_unitario) AS monto_total_venta
        FROM ventas v
        JOIN clientes c ON v.id_cliente = c.id_cliente
        JOIN productos p ON v.id_producto = p.id_producto
        JOIN categorias cat ON p.id_categoria = cat.id_categoria
        WHERE (p_sucursal = 0 OR v.id_sucursal = p_sucursal)
          AND (p_anio = 0 OR YEAR(v.fecha_venta) = p_anio);
    END IF;
END;
/* 2026-10-26 10:50:53 [10 ms] */ 
CREATE PROCEDURE db_guardar_producto(
    IN p_idProducto INT,
    IN p_idCategoria INT,
    IN p_nombreProducto VARCHAR(100),
    IN p_precioUnitario INT,
    IN p_costoProveedor INT,
    IN p_ubicacionPasillo VARCHAR(10),
    IN p_cantidad DECIMAL(10,2)
)
BEGIN
    INSERT INTO productos (
        id_producto,
        id_categoria,
        nombre_producto,
        precio_unitario,
        costo_proveedor,
        ubicacion_pasillo,
        cantidad
    ) 
    VALUES (
        p_idProducto,
        p_idCategoria,
        p_nombreProducto,
        p_precioUnitario,
        p_costoProveedor,
        p_ubicacionPasillo,
        p_cantidad
    )
    ON DUPLICATE KEY UPDATE
        -- Si p_idProducto coincide con una clave primaria existente, actualiza el stock y los precios:
        cantidad = cantidad + VALUES(cantidad),
        precio_unitario = VALUES(precio_unitario),
        costo_proveedor = VALUES(costo_proveedor),
        ubicacion_pasillo = COALESCE(VALUES(ubicacion_pasillo), ubicacion_pasillo),
        id_categoria = VALUES(id_categoria);
END;
/* 2026-10-26 10:55:57 [8 ms] */ 
CREATE PROCEDURE sp_reporte_ventas_año(
    IN p_año_venta SMALLINT,
    in p_monto INT
)
BEGIN
    SELECT 
        clientes.nombre_completo AS 'Cliente',
        clientes.tipo_cliente AS 'Tipo Cliente',
        categorias.nombre_categoria AS 'Categoría',
        COUNT(ventas.id_venta) AS 'Total Transacciones',
        SUM(ventas.cantidad) AS 'Total Productos Vendidos',
        SUM(fn_calcular_total(ventas.cantidad, productos.precio_unitario, clientes.tipo_cliente)) AS 'Monto Total Vendido'
    FROM ventas 
    JOIN clientes ON clientes.id_cliente = ventas.id_cliente
    JOIN productos ON productos.id_producto = ventas.id_producto
    JOIN categorias ON categorias.id_categoria = productos.id_categoria
    WHERE clientes.estado_membresia = 'Activo'
      AND YEAR(ventas.fecha_venta) = p_año_venta
    GROUP BY clientes.nombre_completo, clientes.tipo_cliente, categorias.nombre_categoria
    HAVING SUM(fn_calcular_total(ventas.cantidad, productos.precio_unitario, clientes.tipo_cliente)) > p_monto 
    ORDER BY 'Monto Total Vendido' DESC;
END;
/* 2026-10-26 10:57:10 [7 ms] */ 
DROP PROCEDURE IF EXISTS db_consultar_productos;
/* 2026-10-26 10:57:12 [10 ms] */ 
CREATE PROCEDURE db_consultar_productos(
    IN p_nombreProducto VARCHAR(255)
)
BEGIN
    SELECT 
        p.id_producto AS ID_Producto,
        cat.nombre AS Nombre_Categoria_Producto,
        p.nombre AS Nombre_Producto,
        p.cantidad AS Cantidad
    FROM productos p
    INNER JOIN categorias cat 
        ON p.id_categoria = cat.id_categoria
    WHERE p_nombreProducto = ''
       OR p_nombreProducto IS NULL
       OR p.nombre LIKE CONCAT('%', p_nombreProducto, '%');
END;


