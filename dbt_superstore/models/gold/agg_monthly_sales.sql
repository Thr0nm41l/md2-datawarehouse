-- GOLD.AGG_MONTHLY_SALES : indicateurs commerciaux par mois de commande.
-- Le mois est représenté par la date de son premier jour (type date), ce qui
-- permet de le trier et de l'utiliser directement comme axe temporel.

select
    date_trunc('month', order_date)::date as order_month,
    round(sum(sales), 2)                  as total_sales,
    round(sum(profit), 2)                 as total_profit,
    count(distinct order_id)              as nb_orders
from {{ ref('curation_sales') }}
group by 1
