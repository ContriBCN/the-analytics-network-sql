-- Clase 6
-- 1.Crear una vista con el resultado del ejercicio de la Parte 1 - Clase 2 - Ejercicio 10, donde unimos la 
-- cantidad de gente que ingresa a tienda usando los dos sistemas.

CREATE or REPLACE VIEW stg.count AS 
	SELECT	tienda, CAST (CAST(fecha AS text) AS date), conteo FROM stg.market_count 
	UNION ALL
	SELECT	tienda, CAST (CAST (fecha AS text) AS date), conteo FROM stg.super_store_count

-- 2.Recibimos otro archivo con ingresos a tiendas de meses anteriores. Ingestar el archivo y agregarlo a 
-- la vista del ejercicio anterior (Ejercicio 1 Clase 6). Cual hubiese sido la diferencia si hubiesemos 
-- tenido una tabla? (contestar la ultima pregunta con un texto escrito en forma de comentario).



-- 3.Crear una vista con el resultado del ejercicio de la Parte 1 - Clase 3 - Ejercicio 10, donde calculamos 
-- el margen bruto en dolares. Agregarle la columna de ventas, descuentos, y creditos en dolares para poder 
-- reutilizarla en un futuro.

-- 4.Generar una query que me sirva para verificar que el nivel de agregacion de la tabla de ventas (y de 
-- la vista) no se haya afectado. Recordas que es el nivel de agregacion/detalle? Lo vimos en la teoria de 
-- la parte 1! Nota: La orden M999000061 parece tener un problema verdad? Lo vamos a solucionar mas adelante.

-- 5.Calcular el margen bruto a nivel Subcategoria de producto. Usar la vista creada.

-- 6.Calcular la contribucion de las ventas brutas de cada producto al total de la orden. Por esta vez, si 
-- necesitas usar una subquery, podes utilizarla.

-- 7.Calcular las ventas por proveedor, para eso cargar la tabla de proveedores por producto. Agregar el 
-- nombre el proveedor en la vista del punto 3.

-- 8.Verificar que el nivel de detalle de la vista anterior no se haya modificado, en caso contrario que se deberia ajustar? Que decision tomarias para que no se genereren duplicados?
	--Se pide correr la query de validacion.
	--Crear una nueva query que no genere duplicacion.
	--Explicar brevemente (con palabras escrito tipo comentario) que es lo que sucedia. 
