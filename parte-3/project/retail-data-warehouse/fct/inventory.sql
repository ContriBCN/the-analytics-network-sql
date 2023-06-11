CREATE TABLE fct.inventory
                 (
                              tienda  SMALLINT 
                            , sku     VARCHAR(10) PRIMARY KEY
                            , fecha   DATE
                            , inicial SMALLINT
                            , final   SMALLINT
                 );
