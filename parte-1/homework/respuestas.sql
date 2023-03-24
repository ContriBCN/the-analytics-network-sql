-- CLASE 1 DE 0 A MESSI--
-- Mostrar todos los productos dentro de la categoria electro junto con todos los detalles.

SELECT * FROM stg.product_master
	WHERE categoria = 'Electro'

-- Cuales son los producto producidos en China?

SELECT	nombre, 
		origen 
FROM stg.product_master 
	WHERE origen = 'China'
	
-- Mostrar todos los productos de Electro ordenados por nombre.

SELECT * FROM stg.product_master
	ORDER BY nombre ASC

-- Cuales son las TV que se encuentran activas para la venta?

SELECT	nombre,
		subcategoria,
		is_active
FROM stg.product_master
	WHERE is_active = true
	AND subcategoria = 'TV'
	
-- Mostrar todas las tiendas de Argentina ordenadas por fecha de apertura de las mas antigua a la mas nueva.

SELECT	* FROM	stg.store_master 
	WHERE pais = 'Argentina'
ORDER BY fecha_apertura ASC

-- Cuales fueron las ultimas 5 ordenes de ventas?

SELECT	* FROM stg.order_line_sale
ORDER BY fecha DESC
LIMIT 5

-- Mostrar los primeros 10 registros de el conteo de trafico por Super store ordenados por fecha.

SELECT	* FROM stg.super_store_count
ORDER BY	conteo DESC, 
			fecha DESC
LIMIT 10

-- Cuales son los producto de electro que no son Soporte de TV ni control remoto.

SELECT * FROM stg.product_master
	WHERE subsubcategoria <> 'Soporte' AND subsubcategoria <> 'Control remoto'

-- Mostrar todas las lineas de venta donde el monto sea mayor a $100.000 solo para transacciones en pesos.

SELECT	* FROM stg.order_line_sale
	WHERE	venta > 100.000
	AND moneda <> 'EUR'

-- Mostrar todas las lineas de ventas de Octubre 2022.

SELECT	* FROM stg.order_line_sale
	WHERE fecha BETWEEN '2022-10-01' AND '2022-10-30'

-- Mostrar todos los productos que tengan EAN.

SELECT	* FROM stg.product_master
	WHERE	ean IS NOT NULL

-- Mostrar todas las lineas de venta que que hayan sido vendidas entre 1 de Octubre de 2022 y 10 de Noviembre de 2022.

SELECT	* FROM stg.order_line_sale
	WHERE fecha BETWEEN '2022-10-01' AND '2022-11-10'
