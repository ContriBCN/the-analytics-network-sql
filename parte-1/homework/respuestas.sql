-- CLASE 1 DE 0 A MESSI--
-- 1.Mostrar todos los productos dentro de la categoria electro junto con todos los detalles.

SELECT * FROM stg.product_master
	WHERE categoria = 'Electro'

-- 2.Cuales son los producto producidos en China?

SELECT	nombre, 
		origen 
FROM stg.product_master 
	WHERE origen = 'China'
	
-- 3.Mostrar todos los productos de Electro ordenados por nombre.

SELECT * FROM stg.product_master
	ORDER BY nombre ASC

-- 4.Cuales son las TV que se encuentran activas para la venta?

SELECT	nombre,
		subcategoria,
		is_active
FROM stg.product_master
	WHERE is_active = true
	AND subcategoria = 'TV'
	
-- 5.Mostrar todas las tiendas de Argentina ordenadas por fecha de apertura de las mas antigua a la mas nueva.

SELECT	* FROM	stg.store_master 
	WHERE pais = 'Argentina'
ORDER BY fecha_apertura ASC

-- 6.Cuales fueron las ultimas 5 ordenes de ventas?

SELECT	* FROM stg.order_line_sale
ORDER BY fecha DESC
LIMIT 5

-- 7.Mostrar los primeros 10 registros de el conteo de trafico por Super store ordenados por fecha.

SELECT	* FROM stg.super_store_count
ORDER BY	conteo DESC, 
			fecha DESC
LIMIT 10

-- 8.Cuales son los producto de electro que no son Soporte de TV ni control remoto.

SELECT * FROM stg.product_master
	WHERE subsubcategoria <> 'Soporte' AND subsubcategoria <> 'Control remoto'

-- 9.Mostrar todas las lineas de venta donde el monto sea mayor a $100.000 solo para transacciones en pesos.

SELECT	* FROM stg.order_line_sale
	WHERE	venta > 100.000
	AND moneda <> 'EUR'

-- 10.Mostrar todas las lineas de ventas de Octubre 2022.

SELECT	* FROM stg.order_line_sale
	WHERE fecha BETWEEN '2022-10-01' AND '2022-10-30'

-- 11.Mostrar todos los productos que tengan EAN.

SELECT	* FROM stg.product_master
	WHERE	ean IS NOT NULL

-- 12.Mostrar todas las lineas de venta que que hayan sido vendidas entre 1 de Octubre de 2022 y 10 de Noviembre de 2022.

SELECT	* FROM stg.order_line_sale
	WHERE fecha BETWEEN '2022-10-01' AND '2022-11-10'
	
	
-- CLASE 2 DE 0 A MESSI
-- 1.Cuales son los paises donde la empresa tiene tiendas?

SELECT DISTINCT pais FROM stg.store_master

-- 2.Cuantos productos por subcategoria tiene disponible para la venta?

SELECT	subcategoria, 
		COUNT (DISTINCT NOMBRE)  
FROM	stg.product_master
GROUP BY SUBCATEGORIA

-- 3.Cuales son las ordenes de venta de Argentina de mayor a $100.000?

SELECT * FROM stg.order_line_sale
WHERE venta >= 100000 

-- 4.Obtener los descuentos otorgados durante Noviembre de 2022 en cada una de las monedas?

SELECT	moneda,
		SUM (descuento) AS total_descuento
FROM stg.order_line_sale 
WHERE fecha BETWEEN '2022-01-01' and '2022-10-30'
GROUP BY moneda

-- 5.Obtener los impuestos pagados en Europa durante el 2022.

SELECT SUM (impuestos) AS impuestos_europa FROM stg.order_line_sale
WHERE moneda = 'EUR'

-- 6.En cuantas ordenes se utilizaron creditos?

SELECT	COUNT (*) AS credit_orders 
FROM 	stg.order_line_sale
WHERE	creditos IS NOT NULL

-- 7.Cual es el % de descuentos otorgados (sobre las ventas) por tienda?

SELECT	tienda, ROUND ((SUM(descuento)/sum(venta))*100,2) AS descuento 
FROM	stg.order_line_sale
GROUP BY tienda
ORDER BY descuento

-- 8.Cual es el inventario promedio por dia que tiene cada tienda?

SELECT	tienda, 
		AVG((inicial+final)/2) as promedio 
FROM stg.inventory 
GROUP BY tienda
ORDER BY tienda

-- 9.Obtener las ventas netas y el porcentaje de descuento otorgado por producto en Argentina.

SELECT	producto, 
		SUM (venta-impuestos), 
		ROUND (AVG (descuento/venta)*100,2) AS descuento_porcentaje
FROM stg.order_line_sale
WHERE moneda = 'ARS'
GROUP BY producto 
ORDER BY producto

-- 10.Las tablas "market_count" y "super_store_count" representan dos sistemas distintos que usa la empresa 
-- para contar la cantidad de gente que ingresa a tienda, uno para las tiendas de Latinoamerica y otro 
-- para Europa. Obtener en una unica tabla, las entradas a tienda de ambos sistemas.

SELECT	tienda, CAST (CAST(fecha AS text) AS date), conteo FROM stg.market_count 
UNION ALL
SELECT	tienda, CAST (CAST (fecha AS text) AS date), conteo FROM stg.super_store_count

-- 11.Cuales son los productos disponibles para la venta (activos) de la marca Phillips?

SELECT	* FROM stg.product_master 
WHERE nombre LIKE '%PHILIPS%'

-- 12.Obtener el monto vendido por tienda y moneda y ordenarlo de mayor a menor por valor nominal.

SELECT	SUM (venta), 
		tienda, 
		moneda
FROM stg.order_line_sale 
GROUP BY tienda, moneda

-- 13.ual es el precio promedio de venta de cada producto en las distintas monedas? Recorda que los valores
-- de venta, impuesto, descuentos y creditos es por el total de la linea.

SELECT	producto, 
		ROUND ((venta/cantidad),2) AS ventas,
		moneda 
FROM stg.order_line_sale 
GROUP BY producto, moneda, ventas 
ORDER BY producto

-- 14.Cual es la tasa de impuestos que se pago por cada orden de venta?

SELECT	*, 
		ROUND ((impuestos/venta),2) AS tasas 
FROM stg.order_line_sale


-- Clase 3 DE 0 A MESSI

-- 1.Mostrar nombre y codigo de producto, categoria y color para todos los productos de la marca Philips y 
-- Samsung, mostrando la leyenda "Unknown" cuando no hay un color disponible

SELECT 
	nombre, 
	codigo_producto, 
	CASE WHEN color IS NULL THEN 'Unknown' ELSE color END
FROM stg.product_master 
	WHERE nombre LIKE '%PHILIPS%' OR nombre LIKE '%Samsung%'

-- 2.Calcular las ventas brutas y los impuestos pagados por pais y provincia en la moneda correspondiente.

SELECT
	SM.pais,
	SUM (OLS.venta) AS VENTAS,
	SUM (OLS.impuestos) AS IMPUESTOS,
	OLS.moneda,
	SM.provincia
FROM stg.order_line_sale  AS OLS
LEFT JOIN stg.store_master AS SM
	ON OLS.tienda = SM.codigo_tienda 
GROUP BY pais, provincia, moneda
ORDER BY pais, provincia

-- 3.Calcular las ventas totales por subcategoria de producto para cada moneda ordenados por subcategoria y 
-- moneda.

SELECT
	SUM (OLS.venta) AS ventas_subcategoria, 
	OLS.moneda,
	PM.subcategoria 
FROM stg.order_line_sale AS OLS 
LEFT JOIN stg.product_master AS PM
	ON OLS.producto = PM.codigo_producto
GROUP BY PM.subcategoria, OLS.moneda
ORDER BY PM.subcategoria, OLS.moneda

-- 4.Calcular las unidades vendidas por subcategoria de producto y la concatenacion de pais, provincia; 
-- usar guion como separador y usarla para ordernar el resultado.

SELECT
	SUM (cantidad),
	subcategoria,
	CONCAT (pais,'-',provincia) AS concatpais
FROM stg.order_line_sale OLS
LEFT JOIN stg.product_master PM
	ON OLS.producto = PM.codigo_producto
LEFT JOIN stg.store_master SM
	ON OLS.tienda = SM.codigo_tienda
GROUP BY subcategoria, concatpais
		
-- 5.Mostrar una vista donde sea vea el nombre de tienda y la cantidad de entradas de personas que hubo 
-- desde la fecha de apertura para el sistema "super_store".

SELECT 
	nombre,
	SUM (conteo)	
FROM stg.store_master AS SM
LEFT JOIN stg.super_store_count AS SSC
	ON SM.codigo_tienda = SSC.tienda
GROUP BY nombre

-- 6.Cual es el nivel de inventario promedio en cada mes a nivel de codigo de producto y tienda; mostrar el 
-- resultado con el nombre de la tienda.

SELECT	
	SM.nombre,
	INV.tienda, 
	ROUND (AVG((inicial+final)/2),2) as inventario_promedio,
	INV.sku
FROM stg.inventory AS INV
LEFT JOIN stg.store_master AS SM
	ON INV.tienda = SM.codigo_tienda
GROUP BY nombre, tienda, sku
ORDER BY tienda, sku

-- 7.Calcular la cantidad de unidades vendidas por material. Para los productos que no tengan material usar 
-- 'Unknown', homogeneizar los textos si es necesario.

WITH CTE_material AS (
SELECT 
	*, 
	CASE WHEN material IS NULL THEN 'Unknown'
	when material = 'PLASTICO' THEN 'Plastico'
	when material = 'plastico' THEN 'Plastico'
	ELSE material END AS material_consolidado
FROM stg.order_line_sale AS OLS
LEFT JOIN stg.product_master AS PM
	ON OLS.producto = PM.codigo_producto
)
SELECT 
	material_consolidado,
	SUM (cantidad)
FROM CTE_material
GROUP BY material_consolidado

-- 8.Mostrar la tabla order_line_sales agregando una columna que represente el valor de venta bruta en cada 
-- linea convertido a dolares usando la tabla de tipo de cambio.

SELECT *,
	ROUND ((CASE WHEN moneda = 'ARS' THEN OLS.venta / FX.cotizacion_usd_peso
	WHEN moneda = 'EUR' THEN OLS.venta / FX.cotizacion_usd_eur
	ELSE OLS.venta / fx.cotizacion_usd_uru END),2) AS nueva_tarifa
FROM stg.order_line_sale AS OLS
LEFT JOIN stg.monthly_average_fx_rate AS FX 
	ON SUBSTRING (CAST(OLS.fecha AS text) FROM 1 FOR 7) = SUBSTRING (CAST(FX.mes AS text)FROM 1 FOR 7)

-- 9.Calcular cantidad de ventas totales de la empresa en dolares.

SELECT
	ROUND (SUM (CASE WHEN moneda = 'ARS' THEN OLS.venta / FX.cotizacion_usd_peso
	WHEN moneda = 'EUR' THEN OLS.venta / FX.cotizacion_usd_eur
	ELSE OLS.venta / fx.cotizacion_usd_uru END),2) AS total_ventas_USD
FROM stg.order_line_sale AS OLS
LEFT JOIN stg.monthly_average_fx_rate AS FX 
	ON SUBSTRING (CAST(OLS.fecha AS text) FROM 1 FOR 7) = SUBSTRING (CAST(FX.mes AS text)FROM 1 FOR 7)

-- 10.Mostrar en la tabla de ventas el margen de venta por cada linea. Siendo margen = 
-- (venta - promociones) - costo expresado en dolares.

SELECT 
	producto,
	venta-descuento AS margen_USD
FROM stg.order_line_sale AS OLS
LEFT JOIN stg.monthly_average_fx_rate AS FX 
	ON SUBSTRING (CAST(OLS.fecha AS text) FROM 1 FOR 7) = SUBSTRING (CAST(FX.mes AS text)FROM 1 FOR 7)
ORDER BY producto DESC

-- 11.Calcular la cantidad de items distintos de cada subsubcategoria que se llevan por numero de orden.

SELECT 
	orden, 
	COUNT (DISTINCT subcategoria) 
FROM stg.order_line_sale OLS
LEFT JOIN stg.product_master PM
	ON OLS.producto = PM.codigo_producto
GROUP BY orden
