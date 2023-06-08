CREATE  TABLE fct.employees (
						id serial primary key,
						nombre VARCHAR,
						apellido VARCHAR,
						fecha_entrada DATE,
						fecha_salida DATE,
						telefono BIGINT,
						pais VARCHAR,
						provincia VARCHAR,
						codigo_tienda INTEGER,
						CONSTRAINT codigo_tienda FOREIGN KEY (codigo_tienda)
							REFERENCES new.store_master,
						posicion VARCHAR
 );
