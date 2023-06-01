DROP TABLE IF EXISTS stg.suppliers;

create table stg.suppliers 
  	(
        codigo_producto varchar(255),
        nombre varchar(255),
        is_primary boolean
		);
