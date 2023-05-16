-- Ejercicio Integrador Parte 2
-- Uno de los proyectos que viene trabajando nuestra empresa es de mejorar la visibilidad que le damos a 
-- nuestros principales KPIs que calculamos durante la Parte 1. Para eso, uno de los requisitos futuros va 
-- a ser crear una serie de dashboards en el cual podramos investigar cada metrica, su progresion en el 
-- tiempo y para diferentes cortes de los datos (Ejemplo: categoria, tienda, mes, producto, etc.). Para 
-- lograr esto, el primer objetivo es crear una tabla donde se pueda obtener todo esto en un mismo lugar.

-- Nivel de detalle de la tabla:

-- Fecha
-- SKU
-- Tienda
-- Con los siguientes atributos

-- Tienda: Pais, provincia, Nombre de tienda
-- SKU: Categoria, Subcategoria, Subsubcategoria, proveedor
-- Fecha: dia, mes, año, año fiscal, quarter fiscal

-- Notas:

-- No es necesario que este todo precalculado, sino que tenemos que generar una tabla lo suficientemente 
-- flexible para poder calcular todas las metricas listadas al nivel de de agregacion que querramos.
-- Tiene que ser una tabla en lugar de una vista para que pueda ser consumido rapidamente por el usuario 
-- final.
-- La idea que este todo en un solo lugar facilita la creacion de una sola fuente de la verdad ("single 
-- source of truth").
-- AGM es el gross margen ajustado, es decir no solo tomar los costos de los productos sino tomar otros 
-- gastos o descuentos que hacen los proveedores al momento de vender el producto. Al ser fijos, estos 
-- tienen que distribuirse en los productos vendidos de manera proporcional.
-- Entonces el AGM seria algo asi -> AGM: Ventas netas - Costos - Otros Gastos + Otros Ingresos
-- En este caso se nos pide que distribuyamos el ingreso extra de una TV dentro de los productos que se 
-- vendieron de Phillips. Es decir los unicos productos donde el Margen bruto va a ser distintos al AGM es
-- en los productos Phillips.
-- El periodo fiscal de la empresa empieza el primero de febrero.
-- Las metricas tienen que estar calculadas en dolares.

create table stg.source_truth2 as 
with cte_philips as (
	select sum(cantidad) as cantidad_total, 
	nombre
	from stg.product_master pm 
	left join stg.order_line_sale ols 
		on pm.codigo_producto = ols.producto
	where nombre like '%PHILIPS%' 
	group by nombre
),
ingreso_philips as (
	select 200 / cantidad_total as ingreso_extra,
	nombre
	from cte_philips
),
cte_conteo as (
	select sum (conteo) as conteo, tienda, fecha
	from stg.super_store_count
	group by tienda, fecha
	order by fecha
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
	select 
		ols.producto,
		ingreso_extra,
		ols.fecha ,
		ols.tienda,
		ols.orden,
		ols.cantidad,
		venta / (case
			when moneda = 'EUR' then fx.cotizacion_usd_eur
			when moneda = 'ARS' then fx.cotizacion_usd_peso
			when moneda = 'URU' then fx.cotizacion_usd_uru
			end) ventas_usd,
		descuento / (case
			when moneda = 'EUR' then fx.cotizacion_usd_eur
			when moneda = 'ARS' then fx.cotizacion_usd_peso
			when moneda = 'URU' then fx.cotizacion_usd_uru
			end) descuento_usd,
		impuestos / (case
			when moneda = 'EUR' then fx.cotizacion_usd_eur
			when moneda = 'ARS' then fx.cotizacion_usd_peso
			when moneda = 'URU' then fx.cotizacion_usd_uru
			end) impuestos_usd,
		creditos / (case
			when moneda = 'EUR' then fx.cotizacion_usd_eur
			when moneda = 'ARS' then fx.cotizacion_usd_peso
			when moneda = 'URU' then fx.cotizacion_usd_uru
			end) creditos_usd,
		sm.pais,
		sm.provincia,
		sm.nombre,
		pm.categoria,
		pm.subcategoria,
		pm.subsubcategoria,
		pm.nombre as nombre_producto,
		s.nombre as proveedor,
		(inicial+final)/2 AS inventario_promedio,
		extract (day from d.fecha) as dia,
		d.fecha as fecha2,
		d.mes,
		d.year,
		d.fiscal_year,
		d.fiscal_quarter,
		(ols.cantidad * costo_promedio_usd) as costo_promedio,
		rm.cantidad as devoluciones,
		cte_conteo.conteo,
		cte_DOH.ventas_promedio_7dias
	from stg.order_line_sale ols
	left join stg.inventory inv
		on ols.producto = inv.sku
		and ols.tienda = inv.tienda 
		and ols.fecha = inv.fecha 
	left join stg.monthly_average_fx_rate fx
		on fx.mes = date(date_trunc ('month',ols.fecha))
	left join stg.store_master sm
		on inv.tienda = sm.codigo_tienda
	left join stg.product_master pm
		on inv.sku = pm.codigo_producto
	left join stg.suppliers s
		on inv.sku = s.codigo_producto
		and s.is_primary = 'True'
	left join stg.date d
		on inv.fecha = d.fecha
	left join stg.cost c
		on inv.sku = c.codigo_producto
	left join stg.view_return_movements rm
		on inv.sku = rm.item
		and ols.orden = rm.orden_venta
	left join ingreso_philips
		on pm.nombre = ingreso_philips.nombre
	left join cte_conteo
		on ols.tienda = cte_conteo.tienda
		and ols.fecha = cte_conteo.fecha::date
	left join cte_DOH
		on ols.tienda = cte_DOH.tienda
		and ols.producto = cte_DOH.producto
		and ols.fecha = cte_DOH.fecha
;
select * from stg.source_truth2

-- Cálculo de métricas

-- Ventas brutas, descuentos, impuestos, creditos
select 
	sum(ventas_usd) as ventas, 
	sum(descuento_usd) as descuentos, 
	sum(impuestos_usd) as impuestos, 
	sum(creditos_usd) as creditos
from stg.source_truth2

-- Ventas netas (inluye ventas y descuentos)
select
	sum (ventas_usd) + sum(descuento_usd) as ventas_netas
from stg.source_truth2

-- Valor final pagado (incluye ventas, descuentos, impuestos y creditos)
select
	sum (ventas_usd) - sum(descuento_usd) + sum(impuestos_usd) - sum(creditos_usd) as valor_final
from stg.source_truth2

-- ROI
select 
	sum(ventas_usd)/avg(inventario_promedio*costo_promedio) *100 as ROI
from stg.source_truth2

-- Days on hand
select
	producto,
	inventario_promedio / ventas_promedio_7dias as DOH
from stg.source_truth2

-- Costos
select
	sum(costo_promedio)
from stg.source_truth2
	

-- Margen bruto (gross margin)
select 
	sum(ventas_usd) + sum(descuento_usd) + sum(creditos_usd) - sum(costo_promedio*cantidad)
		as margen_bruto
from stg.source_truth2

-- AGM (adjusted gross margin)
select 
	sum(ventas_usd) + sum(descuento_usd) + sum(creditos_usd) - sum(costo_promedio*cantidad)+ sum (ingreso_extra)
		as AGM
from stg.source_truth2
where nombre like '%PHILIPS%'

-- AOV
select
	sum(ventas_usd)/count(orden) as AOV
from stg.source_truth2

-- Numero de devoluciones
select
	count (devoluciones) as cant_devoluciones
from stg.source_truth2

-- Ratio de conversion
select
	round(count (orden)*100.0/sum(conteo),2) as ratio_conversion
from stg.source_truth2
