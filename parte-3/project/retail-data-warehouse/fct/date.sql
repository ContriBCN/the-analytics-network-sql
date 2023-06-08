CREATE TABLE IF NOT EXISTS stg.date
(
    fecha date,
    mes double precision,
    year double precision,
    dia_semana text COLLATE pg_catalog."default",
    is_weekend boolean,
    nombre_mes text COLLATE pg_catalog."default",
    fiscal_year double precision,
    fiscal_year2 text COLLATE pg_catalog."default",
    fiscal_quarter text COLLATE pg_catalog."default",
    "año_anterior" date,
    PRIMARY KEY (fecha)
)
