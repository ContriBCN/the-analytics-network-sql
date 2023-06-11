DROP TABLE IF EXISTS dim.cost;
    
CREATE TABLE new.cost
                 (
                              codigo_producto    VARCHAR(10)
                            , costo_promedio_usd DECIMAL
                            , PRIMARY KEY (codigo_producto)
                 );
