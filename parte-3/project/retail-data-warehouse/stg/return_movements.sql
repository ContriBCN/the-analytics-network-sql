CREATE  TABLE stg.return_movements 
      (
						orden_venta VARCHAR,
						envio VARCHAR,
						item VARCHAR,
						cantidad INT,
						id_movimiento BIGINT,
						desde VARCHAR,
						hasta VARCHAR,
						recibido_por VARCHAR,
						fecha DATE
       );
