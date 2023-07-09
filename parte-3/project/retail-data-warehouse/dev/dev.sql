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
