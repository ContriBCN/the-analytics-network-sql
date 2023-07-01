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

create table stg.tpintegrador2 as
with cte_philips as 
(
	select 
		orden,
		producto,
		nombre,
		200 / count(1) over() as adjustment
	from stg.order_line_sale ols
	left join stg.product_master pm 
		on pm.codigo_producto = ols.producto
	where lower(pm.nombre) like '%philips%'
),
cte_returns as (
	select 
		orden_venta as orden, 
		item, 
		min(cantidad) as qty_returned
	from stg.return_movements
	group by 
		orden_venta, 
		item
),
cte_ventas as (
	select 
		ols.fecha,
		ols.producto,
		ols.cantidad,
		pm.nombre,
		ols.orden,
		ols.tienda,
		sm.pais,
		sm.nombre as nombre_tienda,
		pm.categoria,
		pm.subcategoria,
		pm.subsubcategoria,
		stg.convert_usd(ols.moneda, ols.venta, ols.fecha) as venta_usd,
		stg.convert_usd(ols.moneda, ols.descuento, ols.fecha) as descuentos_usd, 
		stg.convert_usd(ols.moneda, ols.creditos, ols.fecha) as creditos_usd,
		stg.convert_usd(ols.moneda, ols.impuestos, ols.fecha) as impuestos_usd, 
		extract (day from d1.fecha) as dia,
		d1.fecha as fecha2,
		d1.mes,
		d1.year, 
		d1.fiscal_year,
		d1.fiscal_quarter,
		cte_philips.adjustment as adjustment,
		cte_returns.qty_returned,
		ols.cantidad * costo_promedio_usd as costo_usd
	from stg.order_line_sale ols
	left join stg.product_master pm
		on pm.codigo_producto = ols.producto
	left join stg.store_master sm
		on sm.codigo_tienda = ols.tienda
	left join stg.cost c1
		on c1.codigo_producto = ols.producto
	left join stg.date d1
		on d1.fecha = ols.fecha
	left join cte_philips 
		on cte_philips.producto = ols.producto
		and cte_philips.orden = ols.orden
	left join cte_returns
		on cte_returns.orden = ols.orden
		and cte_returns.item = ols.producto 
	left join stg.suppliers sp
		on sp.codigo_producto = ols.producto 
	where sp.is_primary is true 
)
select 
	cte_ventas.fecha,
	cte_ventas.producto,
	cte_ventas.cantidad,
	cte_ventas.nombre,
	cte_ventas.tienda,
	cte_ventas.pais,
	cte_ventas.nombre as nombre_tienda,
	cte_ventas.categoria,
	cte_ventas.subcategoria,
	cte_ventas.subsubcategoria,
	extract (day from cte_ventas.fecha) as dia,
	cte_ventas.fecha as fecha2,
	cte_ventas.mes,
	cte_ventas.year, 
	cte_ventas.fiscal_year,
	cte_ventas.fiscal_quarter,
	cte_ventas.adjustment as adjustment,
	cte_ventas.qty_returned,
	count(distinct cte_ventas.orden) as countd_orden,
	sum(cantidad) qty,
	sum (venta_usd) as ventas_usd,
	sum (venta_usd)+ sum(descuentos_usd) as ventas_netas_usd,
	sum (impuestos_usd) as impuestos_usd,
	sum (creditos_usd) as creditos_usd,
	sum (descuentos_usd) as descuentos_usd,
	sum (costo_usd) as costo_usd,
	sum (venta_usd) + sum(descuentos_usd) - sum (costo_usd) as gross_margin_usd,
	(i.inicial+i.final)/2 AS inventario_promedio
from cte_ventas 
left join stg.inventory i
	on i.sku = cte_ventas.producto 
	and i.tienda = cte_ventas.tienda 
	and i.fecha = cte_ventas.fecha
group by 
	cte_ventas.fecha,
	cte_ventas.producto,
	cte_ventas.cantidad,
	cte_ventas.nombre,
	cte_ventas.tienda,
	cte_ventas.pais,
	cte_ventas.nombre,
	cte_ventas.categoria,
	cte_ventas.subcategoria,
	cte_ventas.subsubcategoria,
	extract (day from cte_ventas.fecha),
	cte_ventas.fecha,
	cte_ventas.mes,
	cte_ventas.year, 
	cte_ventas.fiscal_year,
	cte_ventas.fiscal_quarter,
	cte_ventas.adjustment,
	cte_ventas.qty_returned,
	inventario_promedio
;
select * from stg.tpintegrador2

-- Cálculo de métricas

-- Ventas brutas, descuentos, impuestos, creditos
select 
	sum(ventas_usd) as ventas, 
	sum(descuentos_usd) as descuentos, 
	sum(impuestos_usd) as impuestos, 
	sum(creditos_usd) as creditos
from stg.tpintegrador2

-- Ventas netas (inluye ventas y descuentos)
select
	sum (ventas_usd) + sum(descuentos_usd) as ventas_netas
from stg.tpintegrador2

-- Valor final pagado (incluye ventas, descuentos, impuestos y creditos)
select
	sum (ventas_usd) - sum(descuentos_usd) + sum(impuestos_usd) - sum(creditos_usd) as valor_final
from stg.tpintegrador2

-- ROI
select 
	sum(ventas_usd)/avg(inventario_promedio*costo_usd) *100 as ROI
from stg.tpintegrador2

-- Costos
select
	sum(costo_promedio)
from stg.tpintegrador2
	
-- Margen bruto (gross margin)
select 
	sum(ventas_usd) + sum(descuentos_usd) + sum(creditos_usd) - sum(costo_usd*cantidad)
		as margen_bruto
from stg.tpintegrador2

-- AGM (adjusted gross margin)
select 
	sum(ventas_usd) + sum(descuentos_usd) + sum(creditos_usd) - sum(costo_usd*cantidad)+ sum (adjustment)
		as AGM
from stg.tpintegrador2
where nombre like '%PHILIPS%'

-- AOV
select
	sum(ventas_usd)/count(countd_orden) as AOV
from stg.tpintegrador2

-- Numero de devoluciones
select
	count (qty_returned) as cant_devoluciones
from stg.tpintegrador2

