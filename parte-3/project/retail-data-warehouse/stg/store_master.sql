DROP TABLE IF EXISTS stg.store_master;
      
CREATE TABLE stg.store_master
                 (
                              codigo_tienda  SMALLINT
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
