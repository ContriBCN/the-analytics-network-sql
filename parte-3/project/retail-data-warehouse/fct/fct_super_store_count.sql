CREATE TABLE fct.super_store_count
                 (
                              tienda SMALLINT
                            , fecha  VARCHAR(10)
                            , conteo SMALLINT
				                    , primary key (fecha, tienda)
                 );
