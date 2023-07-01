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
;


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
		sum (cantidad) as qty
	from stg.order_line_sale ols
	group by fecha
)
select 
	cte_ventas.fecha,
	cte_ventas.qty,
	cte_ventas2.qty,
	cte_ventas.qty - cte_ventas2.qty as qty_diff
from cte_ventas
inner join cte_ventas as cte_ventas2
	on cte_ventas.fecha = cte_ventas2.fecha - interval '7 days'

-- 6.Crear una vista de inventario con la cantidad de inventario por dia, tienda y producto, que ademas va 
-- a contar con los siguientes datos:
	-- Nombre y categorias de producto 		
	-- Pais y nombre de tienda 				
	-- Costo del inventario por linea (recordar que si la linea dice 4 unidades debe reflejar el costo total 
	-- de esas 4 unidades)					
	-- Una columna llamada "is_last_snapshot" para el ultimo dia disponible de inventario. 
	-- Ademas vamos a querer calcular una metrica llamada "Average days on hand (DOH)" que mide cuantos dias de 
	-- venta nos alcanza el inventario. Para eso DOH = Unidades en Inventario Promedio / Promedio diario 
	-- Unidades vendidas ultimos 7 dias.
-- Notas:
	-- Antes de crear la columna DOH, conviene crear una columna que refleje el Promedio diario Unidades 
	-- vendidas ultimos 7 dias.
	-- El nivel de agregacion es dia/tienda/sku.
	-- El Promedio diario Unidades vendidas ultimos 7 dias tiene que calcularse para cada dia.

create view stg.inv_dia_tienda_prod as 
	with cte_inventario as (
	select
		fecha,
		tienda,
		sku,
		(inicial+final/2) as promedio_inv
	from stg.inventory inv
),
cte_ventas as (
	select 
		fecha,
		tienda,
		producto,
		sum (cantidad) as qty
	from stg.order_line_sale ols
	group by 
		fecha,
		tienda,
		producto
),
cte_DOH as (
	select 
		v1.tienda,
		v1.producto,
		v1.fecha,
		sum (case when v1.fecha - v2.fecha <= 6 then v2.qty else 0 end) as ventas_promedio_7dias
	from cte_ventas v1
	left join cte_ventas v2
		on v1.tienda = v2.tienda
		and v1.producto = v2.producto
		and v2.fecha <= v1.fecha
	group by 
		v1.tienda,
		v1.producto,
		v1.fecha
)
select 	inv.*,
		pm.nombre,
		pm.categoria,
		sm.pais,
		sm.nombre,
		costo_promedio_usd * promedio_inv as costo_promedio,
		 ventas_promedio_7dias,
		inv.promedio_inv / cte_DOH.ventas_promedio_7dias as DOH,
		case when inv.fecha = (select max (fecha) as is_last_snapshot from stg.inventory)
			then True else False end as i_last_snapshot
from cte_inventario inv 
left join stg.product_master pm
	on inv.sku = pm.codigo_producto
left join stg.store_master sm
	on inv.tienda = sm.codigo_tienda
left join stg.cost c
	on inv.sku = c.codigo_producto
left join cte_DOH
	on inv.fecha = cte_DOH.fecha
	and inv.sku = cte_DOH.producto
	and inv.tienda = cte_DOH.tienda
;

-- Clase 8
-- 1.Realizar el Ejercicio 6 de la clase 6 donde calculabamos la contribucion de las ventas brutas de cada 
-- producto utilizando una window function.

select
	orden,
	producto,
	sum (venta) as venta_producto_orden,
	sum (venta) over (partition by orden) as total_venta_producto,
	sum (venta) / sum (venta) over (partition by orden) as contribucion
from stg.order_line_sale ols
group by 
	orden,
	producto,
	venta

-- 2.La regla de pareto nos dice que aproximadamente un 20% de los productos generan un 80% de las ventas. 
-- Armar una vista a nivel sku donde se pueda identificar por orden de contribucion, ese 20% aproximado de 
-- SKU mas importantes. (Nota: En este ejercicios estamos construyendo una tabla que muestra la regla de 
-- Pareto)

with cte_ventas_mes as (		
	select
		producto,
		sum (round (ols.venta / (case
		when moneda = 'EUR' then fx.cotizacion_usd_eur
		when moneda = 'ARS' then fx.cotizacion_usd_peso
		when moneda = 'URU' then fx.cotizacion_usd_uru
		else 0 end),2)) as venta_bruta_usd
	from stg. order_line_sale ols
	left join stg.monthly_average_fx_rate fx
		on fx.mes = date(date_trunc ('month',ols.fecha))
	left join stg.cost c
		on ols.producto = c.codigo_producto
	group by 1
),
cte_venta_acumulada as (
	select
		producto, 
		venta_bruta_usd, 
		sum (venta_bruta_usd) over (order by venta_bruta_usd asc) as venta_acumulada
	from cte_ventas_mes
),
cte_porcentaje as (
select
	vm.producto, 
	vm.venta_bruta_usd, 
	va.venta_acumulada,
	vm.venta_bruta_usd / last_value(va.venta_acumulada) 
		over () as percentage
from cte_ventas_mes vm
left join cte_venta_acumulada va on vm.producto = va.producto
)
select
	producto, 
	venta_bruta_usd, 
	percentage,
	round (sum (percentage) over (order by venta_bruta_usd desc),2) as contribution
from cte_porcentaje
order by venta_bruta_usd desc

-- 3.Calcular el crecimiento de ventas por tienda mes a mes, con el valor nominal y el valor % de 
-- crecimiento.

with cte_ventas as (
select
	tienda,
	sum (venta) as venta_mensual,
	extract (month from fecha) as mes
from stg.order_line_sale ols
group by tienda, mes
),
cte_venta_acumulada as (
select 
	tienda,
	mes,
	venta_mensual,
	sum (venta_mensual) over (partition by tienda order by venta_mensual asc) as venta_acumulada
from cte_ventas
)
select 
	tienda,
	mes,
	venta_mensual,
	venta_acumulada,
	((venta_acumulada - lag(venta_acumulada,1)over()) / 
	 			lag (venta_mensual,1) over (partition by tienda)) as perct_incremento
from cte_venta_acumulada
	
-- 4.Crear una vista a partir de la tabla "return_movements" que este a nivel Orden de venta, item y que 
-- contenga las siguientes columnas:
	-- Orden
	-- Sku
	-- Cantidad unidated retornadas
	-- Valor USD retornado (resulta de la cantidad retornada * valor USD del precio unitario bruto con que 
	-- se hizo la venta)
	-- Nombre producto
	-- Primera_locacion (primer lugar registrado, de la columna "desde", para la orden/producto)
	-- Ultima_locacion (el ultimo lugar donde se registro, de la columna "hasta", el producto/orden)
		
create view stg.view_return_movements as (
	select distinct
		orden_venta,
		item,
		cantidad,
		cantidad*c.costo_promedio_usd as valor_usd_retornado,
		pm.nombre,
		first_value(desde) over(partition by orden_venta, item order by id_movimiento asc) 
			as primera_locacion, 
		last_value(hasta) over(partition by orden_venta, item )as ultima_locacion
	from stg.return_movements rm
	left join stg.cost c 
		on rm.item = c.codigo_producto
	left join stg.product_master pm 
		on rm.item = pm.codigo_producto
);

-- 5.Crear una tabla calendario llamada "date" con las fechas del 2022 incluyendo el año fiscal y trimestre 
-- fiscal (en ingles Quarter). El año fiscal de la empresa comienza el primero Febrero de cada año y dura 
-- 12 meses. Realizar la tabla para 2022 y 2023. La tabla debe contener:
	-- Fecha (date)
	-- Mes (date)
	-- Año (date)
	-- Dia de la semana (text, ejemplo: "Monday")
	-- "is_weekend" (boolean, indicando si es Sabado o Domingo)
	-- Mes (text, ejemplo: June)
	-- Año fiscal (date)
	-- Año fiscal (text, ejemplo: "FY2022")
	-- Trimestre fiscal (text, ejemplo: Q1)
	-- Fecha del año anterior (date, ejemplo: 2021-01-01 para la fecha 2022-01-01)
	-- Nota: En general una tabla date es creada para muchos años mas (minimo 10), por el momento nos 
	-- ahorramos ese paso y de la creacion de feriados.

CREATE TABLE IF NOT EXISTS stg.date
(
    fecha date,
    mes double precision,
    year double precision,
    dia_semana text,
    is_weekend boolean,
    nombre_mes text,
    fiscal_year double precision,
    fiscal_year2 text,
    fiscal_quarter text,
    "año_anterior" date
)
	
with recursive cte_date as (
	select ('2022-01-01'::date) as fecha
	union
	select fecha+1 as recursive_fecha
	from cte_date
	where fecha+1 <= date ('2024-01-31')
)
select 
	fecha,
	extract (month from fecha) as mes,
	extract (year from fecha) as year,
	to_char (fecha, 'Day') as dia_semana,
	case when extract (dow from fecha) in (0,6) then True else false end as is_weekend,
	to_char (fecha, 'Month') as nombre_mes,
	extract (year from fecha - interval '1 month') as fiscal_year,
	concat ('FY',extract (year from fecha - interval '1 month')) as fiscal_year2,
	concat ('Q', extract (quarter from fecha - interval '1 month')) as fiscal_quarter,
	cast (fecha - interval ' 1 year' as date) as año_anterior
into stg.date
from cte_date
;

-- CLASE 9
-- 1.Calcular el crecimiento de ventas por tienda mes a mes, con el valor nominal y el valor % de crecimiento.
-- Utilizar self join.

with ventas_mes as (
	select 
		tienda,
		extract (month from fecha) as mes,
		sum (cantidad) as cantidad
	from stg.order_line_sale ols
	group by 
		tienda,
		mes
)
select *,
	(vm.cantidad - vm2.cantidad) * 1.0 / (vm2.cantidad) * 1.0 as variacion
from ventas_mes vm
inner join ventas_mes vm2
	on vm.tienda = vm2.tienda
	and vm.mes > vm2.mes
order by vm.tienda

-- 2.Hacer un update a la tabla de product_master agregando una columna llamada "marca", con la marca de cada
-- producto con la primer letra en mayuscula. Sabemos que las marcas que tenemos son: Levi's, Tommy Hilfiger, 
-- Samsung, Phillips, Acer, JBL y Motorola. En caso de no encontrarse en la lista usar 'Unknown'.

alter table stg.product_master add column marca varchar

select *, 
	case 
		when lower(nombre) like '%samsung%' then 'Samsung'
		when lower(nombre) like '%philips%' then 'Phillips'
		when lower(nombre) like '%levi''s%' then 'Levi''s'
		when lower(nombre) like '%tommy hilfiger%' then 'Tommy Hilfiger'
		when lower(nombre) like '%acer%' then 'Acer'
		when lower(nombre) like '%jbl%' then 'JBL'
		when lower(nombre) like '%motorola%' then 'Motorola'
		else 'Unknown'
		end as marca
from stg.product_master

-- 3.Un jefe de area tiene una tabla que contiene datos sobre las principales empresas de distintas industrias
-- en rubros que pueden ser competencia:
/*
	empresa			rubro			facturacion
	El Corte Ingles	Departamental	$110.99B
	Mercado Libre	ECOMMERCE		$115.86B
	Fallabela		departamental	$20.46M
	Tienda Inglesa	Departamental	$10,78M
	Zara			INDUMENTARIA	$999.98M
*/
-- Armar una query que refleje lo siguiente:
-- Rubro
-- FacturacionTotal (total de facturación por rubro).
-- Ordenadas por la columna rubro en orden ascendente.
-- La columna FacturacionTotal debe estar expresada en millones/billones según corresponda y con 2 decimales 
-- después de la coma. Los elementos de la columna rubro debe estar expresados en letra minúscula.
-- Output esperado:
/*
	rubro			facturacion_total
	departamental	111.01B
	ecommerce		115.86B
	indumentaria	999.98M
*/

-- Primero creamos la tabla
create table stg.datos_empresa (
			empresa 		varchar,
			rubro			varchar,
			facturacion		decimal (18,2)
	)

-- Insertamos los datos 
insert into stg.datos_empresa values ('El Corte Ingles','departamental','110990000000000')
insert into stg.datos_empresa values ('Mercado Libre','ecommerce','115860000000000')
insert into stg.datos_empresa values ('Fallabela','departamental','20460000')
insert into stg.datos_empresa values ('Tienda Inglesa','departamental','10780000')
insert into stg.datos_empresa values ('Zara','indumentaria','998980000')

-- Realizamos la query

with cte as (
	select 
		rubro, 
		sum (facturacion) as total_fra 
	from stg.datos_empresa 
	group by rubro
	order by rubro asc
)
select 
	rubro,
	case when length((total_fra::text))>12 then concat(round ((total_fra/1000000000000),2),'B')
	else concat(round ((total_fra/1000000),2),'M') end as fact_total
from cte
;
