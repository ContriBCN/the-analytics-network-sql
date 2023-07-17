-- Parte 2 punto 1
-- Crear una base de datos que se llame "dev". Correr todos los scripts de ddl.sql para tener la estructura 
-- en un ambiente que vamos a usar para el desarrollo y testeo de nuevas queries. No es es necesario 
-- llenarlo de datos ni de crear nuevos scripts para la base de desarrollo. Los scripts son unicos y deben 
-- permanecer en el repositorio.

-- Database: DEV

DROP DATABASE IF EXISTS "DEV";

create database dev

-- Parte 3 punto 2
-- Crear un script de ddl para cada tabla dentro de fct y dim, con sus respectivas PK and FK en la creacion
-- de tabla.
-- Decidir en cada caso si es necesario crear una clave surrogada o no.
-- (DIMENSION TABLES)

DROP TABLE IF EXISTS dim.cost;
    
CREATE TABLE dim.cost
                 (
                              codigo_producto    VARCHAR(10)
                            , costo_promedio_usd DECIMAL
                            , PRIMARY KEY (codigo_producto)
                 );
				 
DROP TABLE IF EXISTS dim.date;

CREATE TABLE IF NOT EXISTS dim.date
				(
					fecha date,
					mes double precision,
					year double precision,
					dia_semana text COLLATE pg_catalog."default",
					is_weekend boolean,
					nombre_mes text COLLATE pg_catalog."default",
					fiscal_year double precision,
					fiscal_year2 text COLLATE pg_catalog."default",
					fiscal_quarter text COLLATE pg_catalog."default",
					"año_anterior" date,
					id_number serial,
					primary key (fecha, id_number)
				);

DROP TABLE IF EXISTS dim.employees;

CREATE  TABLE dim.employees;
				(
						id serial primary key,
						nombre VARCHAR,
						apellido VARCHAR,
						fecha_entrada DATE,
						fecha_salida DATE,
						telefono BIGINT,
						pais VARCHAR,
						provincia VARCHAR,
						codigo_tienda INTEGER,
						posicion VARCHAR
				 );

DROP TABLE IF EXISTS dim.monthly_average_fx_rate;

CREATE TABLE dim.monthly_average_fx_rate
                 (
                              mes                 DATE
                            , cotizacion_usd_peso DECIMAL
                            , cotizacion_usd_eur  DECIMAL
                            , cotizacion_usd_uru  DECIMAL
                 );

DROP TABLE IF EXISTS dim.product_master;

CREATE TABLE dim.product_master
                 (
                              codigo_producto VARCHAR(255) PRIMARY KEY
                            , nombre          VARCHAR(255)
                            , categoria       VARCHAR(255)
                            , subcategoria    VARCHAR(255)
                            , subsubcategoria VARCHAR(255)
                            , material        VARCHAR(255)
                            , color           VARCHAR(255)
                            , origen          VARCHAR(255)
                            , ean             bigint
                            , is_active       boolean
                            , has_bluetooth   boolean
                            , talle           VARCHAR(255)
                 );

DROP TABLE IF EXISTS dim.store_master;

CREATE TABLE dim.store_master
                 (
                              codigo_tienda  SMALLINT PRIMARY KEY
                            , pais           VARCHAR(100)
                            , provincia      VARCHAR(100)
                            , ciudad         VARCHAR(100)
                            , direccion      VARCHAR(255)
                            , nombre         VARCHAR(255)
                            , tipo           VARCHAR(100)
                            , fecha_apertura DATE
                            , latitud        DECIMAL(10, 8)
                            , longitud       DECIMAL(11, 8)
                 );

DROP TABLE IF EXISTS dim.suppliers;

create table dim.suppliers 
				 (
					codigo_producto varchar(255),
					nombre varchar(255) PRIMARY KEY,
					is_primary boolean
				 );

-- (FACT TABLES)

DROP TABLE IF EXISTS fct.inventory;

CREATE TABLE fct.inventory
                 (
                              tienda  SMALLINT 
                            , sku     VARCHAR(10) 
                            , fecha   DATE
                            , inicial SMALLINT
                            , final   SMALLINT
                 );

DROP TABLE IF EXISTS fct.market_count;

CREATE TABLE fct.market_count
                 (
                              tienda SMALLINT
                            , fecha  INTEGER 
                            , conteo SMALLINT
                 );

DROP TABLE IF EXISTS fct.order_line_sale;

CREATE TABLE fct.order_line_sale
                 (
                              orden      VARCHAR(10) 
                            , producto   VARCHAR(10)
                            , tienda     SMALLINT
                            , fecha      date
                            , cantidad   int
                            , venta      decimal(18,5)
                            , descuento  decimal(18,5)
                            , impuestos  decimal(18,5)
                            , creditos   decimal(18,5)
                            , moneda     varchar(3)
                            , pos        SMALLINT
                            , is_walkout BOOLEAN
                 );

DROP TABLE IF EXISTS fct.return_movements;

CREATE  TABLE fct.return_movements 
     			 (
						orden_venta VARCHAR,
						envio VARCHAR,
						item VARCHAR,
						cantidad INT,
						id_movimiento BIGINT PRIMARY KEY,
						desde VARCHAR,
						hasta VARCHAR,
						recibido_por VARCHAR,
						fecha DATE
      			 );

-- Creando las correspondientes FK 

alter table fct.order_line_sale
add constraint fk_codigo_producto
foreign key (producto)
references dim.product_master (codigo_producto);

alter table fct.order_line_sale
add constraint fk_tienda
foreign key (tienda)
references dim.store_master (codigo_tienda);

alter table fct.inventory
add constraint fk_codigo_producto
foreign key (sku)
references dim.product_master (codigo_producto);

alter table fct.inventory
add constraint fk_tienda
foreign key (tienda)
references dim.store_master (codigo_tienda);

alter table fct.market_count
add constraint fk_tienda
foreign key (tienda)
references dim.store_master (codigo_tienda);

alter table fct.return_movements
add constraint fk_codigo_producto
foreign key (item)
references dim.product_master (codigo_producto);

-- Parte 3 punto 2
-- Editar el script de la tabla "employee" para que soporte un esquema de SDC (Slow changing dimension) 
-- cuyo objetivo debe ser capturar cuales son los empleados activos y el periodo de duracion de cada empleado.

alter table dim.employees add column start_date date;
alter table dim.employees add column end_date date;
alter table dim.employees add column is_active boolean

select * from dim.employees

  
-- 3. Generar un ERD para el modelo dimensional creado con las tablas de hechos y 
-- de dimensiones, descargarlo en PDF y sumarlo al repositorio del proyecto.

/* Hecho en Git */


-- Parte 4 - Creación de los proceso de transformación
-- Para nuestro poryecto vamos a realizar las transformaciones de datos dentro de  stored procedures del 
-- esquema etl. Esta parte es la encargada de limpiar las datos  crudos y realizar las transformaciones 
-- de negocio hasta la capa de analytics.

-- stg -> Modelo dimensional (fct/dim)

-- 1. Crear un backup de las ultimas versiones de todas las tablas stg en el nuevo 
-- schema bkp. La idea es que los datos puedan ser recuperados rapidamente en caso 
-- de errores/fallas en los scripts de transformacion.

CREATE OR REPLACE PROCEDURE etl.sp_backup() 
LANGUAGE SQL as $$ 
	DROP TABLE IF EXISTS bkp.cost; 
	CREATE TABLE bkp.cost as
		select *
		from
    		stg.cost;
			
	DROP TABLE IF EXISTS bkp.product_master; 
	CREATE TABLE bkp.product_master as
		select *
		from
			stg.product_master;

	DROP TABLE IF EXISTS bkp.order_line_sale; 
	CREATE TABLE bkp.order_line_sale as
		select
		from
			stg.order_line_sale;

	DROP TABLE IF EXISTS bkp.inventory;
	CREATE TABLE bkp.inventory as
		select *
		from
			stg.inventory;

	DROP TABLE IF EXISTS bkp.store_master; 
	CREATE TABLE bkp.store_master as
		select *
		from
			stg.store_master;

	DROP TABLE IF EXISTS bkp.super_store_count; 
	CREATE TABLE bkp.super_store_count as
		select *
		from
			stg.super_store_count;

	DROP TABLE IF EXISTS bkp.monthly_average_fx_rate; 
	CREATE TABLE bkp.monthly_average_fx_rate as
		select *
		from
			stg.monthly_average_fx_rate;

	DROP TABLE IF EXISTS bkp.return_movements;
	CREATE TABLE bkp.return_movements as
		select *
		from
			stg.return_movements;

	DROP TABLE IF EXISTS bkp.suppliers; 
	CREATE TABLE bkp.suppliers as
		select *
		from
			stg.suppliers;

	DROP TABLE IF EXISTS bkp.employees;
	CREATE TABLE bkp.employees as
		select *
		from
			stg.employees;

$$;
-- call etl.sp_backup();

-- 2. Por default todas las tablas van a seguir el paradigma de truncate and insert, a menos que se 
-- indique lo contrario.
-- 3. El objetivo de este paso es que las tablas fact/dim queden "limpias" y validadas 
-- y listas para ser usadas para analisis. Por lo tanto, van a requerir que hagas 
-- los cambios necesarios que ya vimos en la parte 1 y 2 para que queden lo mas 
-- completa posibles. Te menciono algunos como ejemplo pero la lista puede no estar 
-- completa:
-- * Agregar columnas: ejemplo marca/"brand" en la tabla de producto.
-- * Las tablas store_count de ambos sistemas deben centrarlizarse en una tabla.
-- * Limpiar la tabla de supplier dejando uno por producto.
-- * Nombre de columnas: cambiar si considerar que no esta claro. Las PK suelen 
--   llamarse "id" y las FK "tabla_id" ejemplo: "customer_id" OK
-- * Tipo de dato: Cambiar el tipo de dato en caso que no sea correcto.

/* create table total_count (
		tienda smallint, 
		fecha integer, 
		conteo smallint)
insert into total_count ( tienda, fecha, conteo)
select 
			tienda,
			fecha,
			conteo
		from stg.market_count
		union all
		select 
			tienda,
			cast(fecha as numeric) as fecha,
			conteo 
		from stg.super_store_count
*/
