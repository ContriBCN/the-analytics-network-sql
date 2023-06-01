DROP TABLE IF EXISTS stg.market_count;
    
CREATE TABLE stg.market_count
                 (
                              tienda SMALLINT
                            , fecha  INTEGER
                            , conteo SMALLINT
                 );
