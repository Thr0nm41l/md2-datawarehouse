-- GOLD.AGG_SALES_BY_REGION : indicateurs commerciaux par région.
-- Une commande est rattachée à une seule région (adresse de livraison), le
-- nombre de commandes est donc un COUNT(DISTINCT order_id).

select
    region,
    round(sum(sales), 2)     as total_sales,
    round(sum(profit), 2)    as total_profit,
    count(distinct order_id) as nb_orders
from {{ ref('curation_sales') }}
group by region
