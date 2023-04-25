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

-- Clase 7
-- 1. Calcular el porcentaje de valores null de la tabla stg.order_line_sale para la columna creditos y 
-- descuentos. (porcentaje de nulls en cada columna)

select 
	sum (case when creditos is null then 1 else 0 end) total_null_creditos,
	sum (case when descuento is null then 1 else 0 end) total_null_descuento,
	count(1),
	sum (case when creditos is null then 1 else 0 end)*1.0 / count(1)*1.0 as ratio_null_creditos,
	sum (case when descuento is null then 1 else 0 end)*1.0 / count(1)*1.0 as ratio_null_descuento
from stg.order_line_sale

-- 2.La columna "is_walkout" se refiere a los clientes que llegaron a la tienda y se fueron con el producto 
-- en la mano (es decia habia stock disponible). Responder en una misma query:
	-- Cuantas ordenes fueron "walkout" por tienda?
	-- Cuantas ventas brutas en USD fueron "walkout" por tienda?
	-- Cual es el porcentaje de las ventas brutas "walkout" sobre el total de ventas brutas por tienda?
	
with cte_ventas_brutas as (
	select 
		tienda,
		sum(case when moneda = 'ARS' then venta/fx.cotizacion_usd_peso
	   		 when moneda = 'EUR' then venta/fx.cotizacion_usd_eur
			 when moneda = 'URU' then venta/fx.cotizacion_usd_uru end) as ventas_brutas
	from stg.order_line_sale ols
	left join stg.monthly_average_fx_rate fx
	on extract (month from fx.mes) = extract (month from ols.fecha)
	group by tienda
),
cte_ventas_walkout as (
	select 
		tienda, 
		count (case when is_walkout = 'true' then 1 else 0 end) as count_walkout,
		sum(case when moneda = 'ARS' then venta/fx.cotizacion_usd_peso
	   		 when moneda = 'EUR' then venta/fx.cotizacion_usd_eur
			 when moneda = 'URU' then venta/fx.cotizacion_usd_uru end) as ventas_walkout
	from stg.order_line_sale ols
	left join stg.monthly_average_fx_rate fx
	on extract (month from fx.mes) = extract (month from ols.fecha)
	where is_walkout = 'True'
	group by tienda
)
select 
	cte_ventas_brutas.tienda,
	sum(count_walkout) as count_walkout,
	sum(ventas_walkout) as ventas_walkout,
	sum(ventas_brutas) as ventas_brutas,
	sum(ventas_walkout) / sum(ventas_brutas) as ratio_ventas_walkout
from cte_ventas_brutas
left join cte_ventas_walkout
on cte_ventas_brutas.tienda = cte_ventas_walkout.tienda
group by cte_ventas_brutas.tienda

-- 3.Siguiendo el nivel de detalle de la tabla ventas, hay una orden que no parece cumplirlo. Como 
-- identificarias duplicados utilizando una windows function? Nota: Esto hace referencia a la orden 
-- M999000061. Tenes que generar una forma de excluir los casos duplicados, para este caso particular y a 
-- nivel general, si llegan mas ordenes con duplicaciones.

with cte_duplicados as 
(
	select 
		orden, 
		producto, 
		row_number() over(partition by orden, producto) as rn 
	from stg.order_line_sale
)
select * from cte_duplicados
where rn = 1

-- 4.Obtener las ventas totales en USD de productos que NO sean de la categoria "TV" NI esten en tiendas de 
-- Argentina.

select 
	ols.tienda,
	sm.pais,
	sum (case when moneda = 'EUR' then venta/fx.cotizacion_usd_eur
		 	  when moneda = 'URU' then venta/fx.cotizacion_usd_uru end) as ventas_brutas 
from stg.order_line_sale ols
left join stg.store_master sm
on ols.tienda = sm.codigo_tienda 
left join stg.product_master pm
on ols.producto = pm.codigo_producto
left join stg.monthly_average_fx_rate fx
on extract (month from fx.mes) = extract (month from ols.fecha)
where sm.pais <> 'Argentina' and subcategoria <> 'TV'
group by ols.tienda, sm.pais

-- 5.El gerente de ventas quiere ver el total de unidades vendidas por dia junto con otra columna con la 
-- cantidad de unidades vendidas una semana atras y la diferencia entre ambos. Nota: resolver en dos querys 
-- usando en una CTEs y en la otra windows functions.

with cte_ventas as (
	select 
		fecha,
		count (venta) as cantidad_vendida,
		sum (venta) as importe_vendido
	from stg.order_line_sale ols
	group by fecha
)
select 
	fecha,
	cantidad_vendida,
	lag(cantidad_vendida,7) over (order by fecha) as qty_lw,
	importe_vendido,
	lag(importe_vendido,7) over (order by fecha) as amount_lw
from cte_ventas

