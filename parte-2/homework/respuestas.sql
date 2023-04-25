-- Clase 6
-- 1.Crear una vista con el resultado del ejercicio de la Parte 1 - Clase 2 - Ejercicio 10, donde unimos la 
-- cantidad de gente que ingresa a tienda usando los dos sistemas.

CREATE or REPLACE VIEW stg.count_view AS 
	SELECT	tienda, CAST (CAST(fecha AS text) AS date), conteo FROM stg.market_count 
	UNION ALL
	SELECT	tienda, CAST (CAST (fecha AS text) AS date), conteo FROM stg.super_store_count

-- 2.Recibimos otro archivo con ingresos a tiendas de meses anteriores. Ingestar el archivo y agregarlo a 
-- la vista del ejercicio anterior (Ejercicio 1 Clase 6). Cual hubiese sido la diferencia si hubiesemos 
-- tenido una tabla? (contestar la ultima pregunta con un texto escrito en forma de comentario).

create table stg.super_store_count_september -- Creo una tabla nueva para cargar los datos
	(
		tienda smallint,
		fecha date,
		conteo smallint)
		
copy stg.super_store_count_september 
from 'C:\postgresql\super_store_count_september.csv' 
ENCODING 'win-1251' DELIMITER ',' CSV HEADER -- Cargo los datos en la tabla

CREATE or REPLACE VIEW stg.count_view AS 		-- Creo la vista nuevamente con los datos de septiembre
	SELECT	tienda, CAST (CAST(fecha AS text) AS date), conteo FROM stg.market_count 
	UNION ALL
	SELECT	tienda, CAST (CAST (fecha AS text) AS date), conteo FROM stg.super_store_count
	UNION ALL 
	SELECT tienda, CAST (CAST (fecha AS text) AS date), conteo FROM stg.super_store_count_september

select * from stg.count_view

-- 3.Crear una vista con el resultado del ejercicio de la Parte 1 - Clase 3 - Ejercicio 10, donde calculamos 
-- el margen bruto en dolares. Agregarle la columna de ventas, descuentos, y creditos en dolares para poder 
-- reutilizarla en un futuro.

create or replace view stg.margen_bruto_view as 
	SELECT 
		ols.orden,
		ols.producto,
		ols.tienda,
		ols.fecha,
		ols.cantidad,
		ols.venta,
		ols.descuento,
		ols.impuestos,
		ols.creditos,
		ols.moneda,
		ols.pos,
		ols.is_walkout,
		ols.line_key,
		case when ols.moneda = 'EUR' then ols.venta * fx.cotizacion_usd_eur 
			 when ols.moneda = 'ARS' then ols.venta * fx.cotizacion_usd_peso
			 when ols.moneda = 'URU' then ols.venta * fx.cotizacion_usd_uru end as ventas_usd,
		case when ols.moneda = 'EUR' then coalesce (ols.descuento,0) * fx.cotizacion_usd_eur 
			 when ols.moneda = 'ARS' then coalesce (ols.descuento,0) * fx.cotizacion_usd_peso
			 when ols.moneda = 'URU' then coalesce (ols.descuento,0) * fx.cotizacion_usd_uru end as descuento_usd,
		case when ols.moneda = 'EUR' then coalesce (ols.creditos,0) * fx.cotizacion_usd_eur 
			 when ols.moneda = 'ARS' then coalesce (ols.creditos,0) * fx.cotizacion_usd_peso
			 when ols.moneda = 'URU' then coalesce (ols.creditos,0) * fx.cotizacion_usd_uru end as creditos_usd,
	    round((ols.venta + COALESCE(ols.descuento, 0) + COALESCE(ols.creditos, 0)) /
        CASE
            WHEN ols.moneda = 'EUR' THEN fx.cotizacion_usd_eur
            WHEN ols.moneda = 'ARS' THEN fx.cotizacion_usd_peso
            WHEN ols.moneda = 'URU' THEN fx.cotizacion_usd_uru
            ELSE 0
        END, 1) - c1.costo_promedio_usd AS margen_bruto_usd
   FROM stg.order_line_sale ols
     LEFT JOIN stg.cost c1 ON c1.codigo_producto = ols.producto
     LEFT JOIN stg.monthly_average_fx_rate fx ON EXTRACT(month FROM fx.mes) = EXTRACT(month FROM ols.fecha);
	
-- 4.Generar una query que me sirva para verificar que el nivel de agregacion de la tabla de ventas (y de 
-- la vista) no se haya afectado. Recordas que es el nivel de agregacion/detalle? Lo vimos en la teoria de 
-- la parte 1! Nota: La orden M999000061 parece tener un problema verdad? Lo vamos a solucionar mas adelante.

select 
	line_key, 
	count(1)
from stg.order_line_sale 
group by orden,line_key 
having count(1)>1

-- 5.Calcular el margen bruto a nivel Subcategoria de producto. Usar la vista creada.

select
	subcategoria,
	sum (margen_usd) as margen_bruto	
	from stg.margen_bruto_view mbv
	left join stg.product_master pm
	on mbv.producto = pm.codigo_producto
group by subcategoria

-- 6.Calcular la contribucion de las ventas brutas de cada producto al total de la orden. Por esta vez, si 
-- necesitas usar una subquery, podes utilizarla. (Ventas brutas en dólares)
/* Se realiza la consulta mediante un CTE */

with cte_orden as (
select 
	orden, 
	sum (venta) as venta_orden
from stg.order_line_sale ols
group by orden
)
select  
	ols.orden, 
	ols.producto, 
	ols.venta, 
	o.venta_orden,
	ols.venta / o.venta_orden
from stg.order_line_sale ols 
left join cte_orden o 
	on o.orden = ols.orden

/* Pero también podria realizarse mediante una window function */

select 
	orden, 
	producto,
	venta,
	venta/sum (venta) over (partition by orden) as venta_orden
from stg.order_line_sale 

-- 7.Calcular las ventas por proveedor, para eso cargar la tabla de proveedores por producto. Agregar el 
-- nombre el proveedor en la vista del punto 3.

create table stg.suppliers 
	(
			codigo_producto varchar(255),
			nombre varchar(255),
			is_primary boolean
		);
			
copy stg.suppliers from 'C:\postgresql\suppliers2.csv' 
ENCODING 'win-1251' DELIMITER ',' CSV HEADER;	

select * from stg.suppliers


create or replace  view stg.margen_bruto_view as
	SELECT 
		orden,
		sum (CASE WHEN moneda = 'ARS' THEN coalesce (ols.venta,0) / fx.cotizacion_usd_peso
			 when moneda = 'EUR' THEN coalesce (ols.venta,0) / fx.cotizacion_usd_eur
			 WHEN moneda = 'URU' THEN coalesce (ols.venta,0) / fx.cotizacion_usd_uru
			 end) AS ventas_usd,
		sum (CASE WHEN moneda = 'ARS' THEN coalesce (ols.descuento,0) / fx.cotizacion_usd_peso
			 when moneda = 'EUR' THEN coalesce (ols.descuento,0) / fx.cotizacion_usd_eur
			 WHEN moneda = 'URU' THEN coalesce (ols.descuento,0) / fx.cotizacion_usd_uru
			 end) AS descuento_usd,
		sum (CASE WHEN moneda = 'ARS' THEN coalesce (ols.creditos,0) / fx.cotizacion_usd_peso
			 when moneda = 'EUR' THEN coalesce (ols.creditos,0) / fx.cotizacion_usd_eur
			 WHEN moneda = 'URU' THEN coalesce (ols.creditos,0) / fx.cotizacion_usd_uru
			 end) AS creditos_usd,
		producto,
		((CASE 
			 WHEN moneda = 'ARS' THEN ((OLS.venta - coalesce (OLS.descuento,0)) / FX.cotizacion_usd_peso) - c.costo_promedio_usd
			 WHEN moneda = 'EUR' THEN ((OLS.venta - coalesce (OLS.descuento,0)) / FX.cotizacion_usd_eur) - c.costo_promedio_usd
			 WHEN moneda = 'URU' THEN ((OLS.venta - coalesce (OLS.descuento,0)) / fx.cotizacion_usd_uru) - c.costo_promedio_usd 
		  		END)) AS margen_USD,
		suppliers.nombre,
		suppliers.is_primary
	FROM stg.suppliers as s, stg.order_line_sale AS OLS 
	LEFT JOIN stg.monthly_average_fx_rate AS FX 
		ON SUBSTRING (CAST(OLS.fecha AS text) FROM 1 FOR 7) = SUBSTRING (CAST(FX.mes AS text)FROM 1 FOR 7)
	LEFT JOIN stg.cost AS c
		on c.codigo_producto = ols.producto
	LEFT JOIN stg.suppliers 
		on ols.producto = suppliers.codigo_producto
		and suppliers.is_primary = 'true'
	GROUP BY producto, margen_USD, orden, suppliers.nombre, suppliers.is_primary
	ORDER BY producto DESC 
	
-- 8.Verificar que el nivel de detalle de la vista anterior no se haya modificado, en caso contrario que se deberia ajustar? Que decision tomarias para que no se genereren duplicados?
	--Se pide correr la query de validacion.
	--Crear una nueva query que no genere duplicacion.
	--Explicar brevemente (con palabras escrito tipo comentario) que es lo que sucedia.
	
with cte as (
	select
		orden,
		producto,
		row_number ()over (partition by orden, producto) as rn
	from stg.margen_bruto_view)
		select * from cte
		where rn = 1
