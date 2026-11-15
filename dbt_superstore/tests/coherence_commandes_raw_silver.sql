-- Test singulier : la curation ne doit perdre aucune commande. Le nombre de
-- commandes distinctes doit être identique entre RAW et SILVER (seules des
-- lignes en double sont supprimées, jamais une commande entière).

with raw_orders as (
    select count(distinct trim("Order ID")) as nb from {{ source('raw', 'sales') }}
),

silver_orders as (
    select count(distinct order_id) as nb from {{ ref('curation_sales') }}
)

select raw_orders.nb as nb_raw, silver_orders.nb as nb_silver
from raw_orders
cross join silver_orders
where raw_orders.nb <> silver_orders.nb
