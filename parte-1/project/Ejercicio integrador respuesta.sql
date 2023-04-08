-- Ejercicio Integrador
-- Luego de un tiempo de haber respondido todas las preguntas puntuales por los gerentes, la empresa decide 
-- ampliar el contrato para mejorar las bases de reporte de datos. Para esto quiere definir una serie de 
-- KPIs (Key Performance Indicator) que midan la salud de la empresa en diversas areas y ademas mostrar el 
-- valor actual y la evolucion en el tiempo.
-- Por cada KPI listado vamos a tener que generar al menos una query (pueden ser mas de una) que nos 
-- devuelva el valor del KPI en cada mes, mostrando el resultado para todos los meses disponibles.

-- Todos los valores monetarios deben ser calculados en dolares usando el tipo de cambio promedio mensual.

-- El objetivo no es solo encontrar la query que responda la metrica sino entender que datos necesitamos, 
-- que es lo que significa y como armar el KPI General

-- Ventas brutas

SELECT
	EXTRACT (month FROM fecha) AS mes_venta,
	ROUND (SUM (CASE WHEN moneda = 'ARS' THEN OLS.venta / FX.cotizacion_usd_peso
	WHEN moneda = 'EUR' THEN OLS.venta / FX.cotizacion_usd_eur
	ELSE OLS.venta / fx.cotizacion_usd_uru END),2) AS ventas_brutas_USD
FROM stg.order_line_sale AS OLS
LEFT JOIN stg.monthly_average_fx_rate AS FX 
	ON SUBSTRING (CAST(OLS.fecha AS text) FROM 1 FOR 7) = SUBSTRING (CAST(FX.mes AS text)FROM 1 FOR 7)
GROUP BY mes_venta

-- Ventas netas

SELECT 
	EXTRACT (month FROM fecha) AS mes_venta,
	ROUND (SUM (CASE WHEN moneda = 'ARS' THEN ((ols.venta-OLS.impuestos)/FX.cotizacion_usd_peso)
	WHEN moneda = 'EUR' THEN ((OLS.venta-OLS.impuestos)/FX.cotizacion_usd_eur)
	ELSE (OLS.venta-OLS.impuestos)/FX.cotizacion_usd_uru END),2)  AS ventas_netas_USD
FROM stg.order_line_sale AS OLS
LEFT JOIN stg.monthly_average_fx_rate AS FX
	ON SUBSTRING (CAST(OLS.fecha AS text) FROM 1 FOR 7) = SUBSTRING (CAST(FX.mes AS text)FROM 1 FOR 7)
GROUP BY mes_venta

-- Margen ventas

SELECT 
	EXTRACT (month FROM fecha) AS mes_venta,
	ROUND (SUM (CASE WHEN moneda = 'ARS' THEN (((ols.venta-OLS.descuento)-OLS.impuestos)/FX.cotizacion_usd_peso)
	WHEN moneda = 'EUR' THEN (((OLS.venta-OLS.descuento)-OLS.impuestos)/FX.cotizacion_usd_eur)
	ELSE ((OLS.venta-OLS.descuento)-OLS.impuestos)/FX.cotizacion_usd_uru END),2)  AS margen_ventas_USD
FROM stg.order_line_sale AS OLS
LEFT JOIN stg.monthly_average_fx_rate AS FX
	ON SUBSTRING (CAST(OLS.fecha AS text) FROM 1 FOR 7) = SUBSTRING (CAST(FX.mes AS text)FROM 1 FOR 7)
GROUP BY mes_venta

-- Margen por categoria de producto

SELECT 
	EXTRACT (month FROM fecha) AS mes_venta,
	subcategoria,
	ROUND (SUM (CASE WHEN moneda = 'ARS' THEN (((ols.venta-OLS.descuento)-OLS.impuestos)/FX.cotizacion_usd_peso)
	WHEN moneda = 'EUR' THEN (((OLS.venta-OLS.descuento)-OLS.impuestos)/FX.cotizacion_usd_eur)
	ELSE ((OLS.venta-OLS.descuento)-OLS.impuestos)/FX.cotizacion_usd_uru END),2)  AS margen_ventas_USD
FROM stg.order_line_sale AS OLS
LEFT JOIN stg.monthly_average_fx_rate AS FX
	ON SUBSTRING (CAST(OLS.fecha AS text) FROM 1 FOR 7) = SUBSTRING (CAST(FX.mes AS text)FROM 1 FOR 7)
LEFT JOIN stg.product_master AS PM
	ON OLS.producto = PM.codigo_producto
GROUP BY mes_venta, subcategoria
ORDER BY mes_venta

-- ROI por categoria de producto. ROI = Valor promedio de inventario / ventas netas 

WITH CTE_inventario AS (
	SELECT
		tienda,
		ROUND (AVG((inicial+final)/2),2) AS inventario_promedio,
		INV.sku
	FROM stg.inventory AS INV
	GROUP BY sku, tienda
	ORDER BY sku
),
CTE_ventas AS (
	SELECT 
		tienda,
		EXTRACT (month FROM fecha) AS mes_venta,
		ROUND (SUM (CASE WHEN moneda = 'ARS' THEN ((ols.venta-OLS.impuestos)/FX.cotizacion_usd_peso)
		WHEN moneda = 'EUR' THEN ((OLS.venta-OLS.impuestos)/FX.cotizacion_usd_eur)
		ELSE (OLS.venta-OLS.impuestos)/FX.cotizacion_usd_uru END),2)  AS ventas_netas_USD
	FROM stg.order_line_sale AS OLS
	LEFT JOIN stg.monthly_average_fx_rate AS FX
		ON SUBSTRING (CAST(OLS.fecha AS text) FROM 1 FOR 7) = SUBSTRING (CAST(FX.mes AS text)FROM 1 FOR 7)
	GROUP BY mes_venta, tienda
)
SELECT 
	categoria,
	ROUND ((SUM(inventario_promedio)/SUM(ventas_netas_USD)*100),2) AS ROI
FROM CTE_inventario AS INV
LEFT JOIN CTE_ventas AS OLS
	ON INV.tienda = OLS.tienda
LEFT JOIN stg.product_master AS PM
	ON INV.sku = PM.codigo_producto
GROUP BY categoria

-- AOV (Average order value), valor promedio de la orden.

SELECT 
	EXTRACT (month FROM fecha) AS mes_venta,
	ROUND (AVG (CASE WHEN moneda = 'ARS' THEN (ols.venta/FX.cotizacion_usd_peso)
	WHEN moneda = 'EUR' THEN (OLS.venta/FX.cotizacion_usd_eur)
	ELSE OLS.venta/FX.cotizacion_usd_uru END),2)  AS AOV_USD
FROM stg.order_line_sale AS OLS
LEFT JOIN stg.monthly_average_fx_rate AS FX
	ON SUBSTRING (CAST(OLS.fecha AS text) FROM 1 FOR 7) = SUBSTRING (CAST(FX.mes AS text)FROM 1 FOR 7)
GROUP BY mes_venta

-- CONTABILIDAD
-- Impuestos pagados

SELECT
	ROUND (SUM (CASE WHEN moneda = 'ARS' THEN (impuestos/FX.cotizacion_usd_peso)
		 WHEN moneda = 'EUR' THEN (impuestos/FX.cotizacion_usd_eur)
		 ELSE impuestos/FX.cotizacion_usd_uru END),2)
FROM stg.order_line_sale AS OLS
LEFT JOIN stg.monthly_average_fx_rate AS FX
	ON SUBSTRING (CAST (OLS.fecha AS text) FROM 1 FOR 7) = SUBSTRING (CAST (FX.mes AS text) FROM 1 FOR 7)
GROUP BY FX.mes

-- Tasa de impuesto. Impuestos / Ventas netas (SIN RESOLVER)

WITH CTE_ventas_netas AS (
	SELECT 
		EXTRACT (month FROM fecha) AS mes_venta,
		ROUND (SUM (CASE WHEN moneda = 'ARS' THEN ((ols.venta-OLS.impuestos)/FX.cotizacion_usd_peso)
		WHEN moneda = 'EUR' THEN ((OLS.venta-OLS.impuestos)/FX.cotizacion_usd_eur)
		ELSE (OLS.venta-OLS.impuestos)/FX.cotizacion_usd_uru END),2)  AS ventas_netas_USD
	FROM stg.order_line_sale AS OLS
	LEFT JOIN stg.monthly_average_fx_rate AS FX
		ON SUBSTRING (CAST(OLS.fecha AS text) FROM 1 FOR 7) = SUBSTRING (CAST(FX.mes AS text)FROM 1 FOR 7)
	GROUP BY mes_venta
)
	SELECT
		ROUND (SUM (CASE WHEN moneda = 'ARS' THEN ((impuestos/CTE_ventas_netas)/FX.cotizacion_usd_peso)
			WHEN moneda = 'EUR' THEN ((impuestos/CTE_ventas_netas)/FX.cotizacion_usd_eur)
		 	ELSE (impuestos/CTE_ventas_netas)/FX.cotizacion_usd_uru END),2)
	FROM stg.order_line_sale AS OLS
	LEFT JOIN stg.monthly_average_fx_rate AS FX
	LEFT JOIN CTE_ventas_netas ON FX.mes = CTE_ventas_netas.mes_venta
		ON SUBSTRING (CAST (OLS.fecha AS text) FROM 1 FOR 7) = SUBSTRING (CAST (FX.mes AS text) FROM 1 FOR 7)
	GROUP BY CTE_ventas_netas.mes_venta

-- Cantidad de creditos otorgados

SELECT
	EXTRACT (month FROM fecha) AS mes,
	COUNT (creditos)
FROM stg.order_line_sale
GROUP BY mes

-- Valor pagado final por order de linea. Valor pagado: Venta - descuento + impuesto - credito
-- (SIN RESOLVER) -- LOS RESULTADOS SON TODOS NULL
	
SELECT
	orden,
	COALESCE (SUM (CASE WHEN moneda = 'ARS' THEN ((((venta-descuento)+impuestos)-creditos)/FX.cotizacion_usd_peso)
		 WHEN moneda = 'EUR' THEN ((((venta-descuento)+impuestos)-creditos)/FX.cotizacion_usd_eur)
		 ELSE ((((venta-descuento)+impuestos)-creditos)/FX.cotizacion_usd_uru) END),0)
FROM stg.order_line_sale AS OLS
LEFT JOIN stg.monthly_average_fx_rate AS FX
	ON OLS.fecha = FX.mes
GROUP BY OLS.orden
ORDER BY OLS.orden
		
-- SUPPLY CHAIN
-- Costo de inventario promedio por tienda

SELECT
	tienda,
	(SUM(inicial)+SUM(final))/2 AS inventario_promedio,
	((SUM(inicial)+SUM(final))/2) * MAX(C.costo_promedio_usd) AS costo_promedio
FROM stg.inventory AS INV
LEFT JOIN stg.cost AS C
	ON INV.sku = C.codigo_producto
GROUP BY tienda
ORDER BY tienda

-- Costo del stock de productos que no se vendieron por tienda



-- Cantidad y costo de devoluciones



-- Tiendas
-- Ratio de conversion. Cantidad de ordenes generadas / Cantidad de gente que entra
						
WITH CTE_total_ordenes AS (					-- total ordenes --
	SELECT
		tienda,
		COUNT (DISTINCT orden) total_orden
	FROM stg.order_line_sale
	GROUP BY tienda
	),
CTE_total_conteo AS (
	SELECT									-- union conteo tiendas Eur y America --
		tienda, 
		CAST (CAST(fecha AS text) AS date), 
		conteo AS conteo_1 
	FROM stg.market_count 
	UNION ALL
	SELECT	
		tienda, 
		CAST (CAST (fecha AS text) AS date), 
		conteo AS conteo_1
	FROM stg.super_store_count
	)
SELECT 
	CTE_total_ordenes.tienda,
	ROUND ((SUM (CTE_total_ordenes.total_orden)/SUM (CTE_total_conteo.conteo_1)*100),2) AS ratio	
FROM CTE_total_ordenes
LEFT JOIN CTE_total_conteo
	ON CTE_total_ordenes.tienda = CTE_total_conteo.tienda
	GROUP BY CTE_total_ordenes.tienda

-- Por otro lado tambien necesitamos crear y subir a nuestra DB la tabla "return_movements" para poder 
-- utilizarla en la segunda parte.

-- PREGUNTAS DE ENTREVISTAS
-- Como encuentro duplicados en una tabla. Dar un ejemplo mostrando duplicados de la columna orden en la 
-- tabla de ventas.
--> Utilizando la función ROW_NUMBER, me añade una columna secuencial con el numero de duplicados.

SELECT 
	producto, 
	ROW_NUMBER () OVER (PARTITION BY producto)
FROM stg.order_line_sale

-- Como elimino duplicados?
--> Con la cláusula COUNT DISTINCT me va a indicar el número total de valores distintos del campo que 
--> seleccione.

-- Cual es la diferencia entre UNION y UNION ALL.
--> UNION combina los resultados de dos tablas, eliminando los duplicados. UNION ALL combina las tablas y 
--> mantiene los registros duplicados.

-- Como encuentro registros en una tabla que no estan en otra tabla.
--> Mediante un LEFT JOIN, para traer todos aquellos registros que no están en la otra tabla.
--> Con un FULL JOIN traerías todos los registros de cada una de las tablas.

-- Para probar podes crear dos tablas con una unica columna id que tengan valores: Tabla 1: 1,2,3,4 Tabla 2: 3,4,5,6
-- Cual es la diferencia entre INNER JOIN y LEFT JOIN. (podes usar la tabla anterior)
CREATE TABLE stg.tabla_1 (
			id int);
INSERT INTO stg.tabla_1 VALUES (1),(2),(3),(4) 

CREATE TABLE stg.tabla_2 (
			id int);
INSERT INTO stg.tabla_2 VALUES (3),(4),(5),(6)

-- Inner Join selecciona aquellos registros que están en ambas tablas
SELECT * FROM stg.tabla_1 AS T1 INNER JOIN stg.tabla_2 AS T2 ON T1.id = T2.id 

-- Left Join selecciona todos los registros de la tabla de la izquierda (tabla_1), y los registros que 
-- coinciden con la tabla de la derecha (tabla_2)
SELECT * FROM stg.tabla_1 AS T1 LEFT JOIN stg.tabla_2 AS T2 ON T1.id = T2.id 

