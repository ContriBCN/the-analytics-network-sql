DROP TABLE IF EXISTS stg.super_store_count;
    
CREATE TABLE stg.super_store_count
                 (
                              tienda SMALLINT
                            , fecha  VARCHAR(10)
                            , conteo SMALLINT
                 );
