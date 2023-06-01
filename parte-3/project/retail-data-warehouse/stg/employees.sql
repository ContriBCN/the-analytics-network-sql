DROP TABLE bkp.employees IF EXISTS;
CREATE  TABLE stg.employees (
						id serial primary key,
						nombre VARCHAR,
						apellido VARCHAR,
						fecha_entrada DATE,
						fecha_salida DATE,
						telefono BIGINT,
						pais VARCHAR,
						provincia VARCHAR,
						codigo_tienda INTEGER,
						posicion VARCHAR)
