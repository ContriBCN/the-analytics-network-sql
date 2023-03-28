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
	
	
-- CLASE 2 DE 0 A MESSI
-- Cuales son los paises donde la empresa tiene tiendas?

SELECT DISTINCT pais FROM stg.store_master

-- Cuantos productos por subcategoria tiene disponible para la venta?

SELECT	subcategoria, 
		COUNT (DISTINCT NOMBRE)  
FROM	stg.product_master
GROUP BY SUBCATEGORIA

-- Cuales son las ordenes de venta de Argentina de mayor a $100.000?

SELECT * FROM stg.order_line_sale
WHERE venta >= 100000 

-- Obtener los descuentos otorgados durante Noviembre de 2022 en cada una de las monedas?

SELECT	moneda,
		SUM (descuento) AS total_descuento
FROM stg.order_line_sale 
WHERE fecha BETWEEN '2022-01-01' and '2022-10-30'
GROUP BY moneda

-- Obtener los impuestos pagados en Europa durante el 2022.

SELECT SUM (impuestos) AS impuestos_europa FROM stg.order_line_sale
WHERE moneda = 'EUR'

-- En cuantas ordenes se utilizaron creditos?

SELECT	COUNT (*) AS credit_orders 
FROM 	stg.order_line_sale
WHERE	creditos IS NOT NULL

-- Cual es el % de descuentos otorgados (sobre las ventas) por tienda?

SELECT	tienda, ROUND ((SUM(descuento)/sum(venta))*100,2) AS descuento 
FROM	stg.order_line_sale
GROUP BY tienda
ORDER BY descuento

-- Cual es el inventario promedio por dia que tiene cada tienda?

SELECT	tienda, 
		AVG((inicial+final)/2) as promedio 
FROM stg.inventory 
GROUP BY tienda
ORDER BY tienda

-- Obtener las ventas netas y el porcentaje de descuento otorgado por producto en Argentina.

SELECT	producto, 
		SUM (venta-impuestos), 
		ROUND (AVG (descuento/venta)*100,2) AS descuento_porcentaje
FROM stg.order_line_sale
WHERE moneda = 'ARS'
GROUP BY producto 
ORDER BY producto

-- Las tablas "market_count" y "super_store_count" representan dos sistemas distintos que usa la empresa 
-- para contar la cantidad de gente que ingresa a tienda, uno para las tiendas de Latinoamerica y otro 
-- para Europa. Obtener en una unica tabla, las entradas a tienda de ambos sistemas.

SELECT	tienda, CAST (CAST(fecha AS text) AS date), conteo FROM stg.market_count 
UNION ALL
SELECT	tienda, CAST (CAST (fecha AS text) AS date), conteo FROM stg.super_store_count

-- Cuales son los productos disponibles para la venta (activos) de la marca Phillips?

SELECT	* FROM stg.product_master 
WHERE nombre LIKE '%PHILIPS%'

-- Obtener el monto vendido por tienda y moneda y ordenarlo de mayor a menor por valor nominal.

SELECT	SUM (venta), 
		tienda, 
		moneda
FROM stg.order_line_sale 
GROUP BY tienda, moneda

-- Cual es el precio promedio de venta de cada producto en las distintas monedas? Recorda que los valores
-- de venta, impuesto, descuentos y creditos es por el total de la linea.

SELECT	producto, 
		ROUND ((venta/cantidad),2) AS ventas,
		moneda 
FROM stg.order_line_sale 
GROUP BY producto, moneda, ventas 
ORDER BY producto

-- Cual es la tasa de impuestos que se pago por cada orden de venta?

SELECT	*, 
		ROUND ((impuestos/venta),2) AS tasas 
FROM stg.order_line_sale
