-- GOLD.AGG_SALES_BY_CATEGORY : indicateurs commerciaux par catégorie de produit.

select
    category,
    round(sum(sales), 2)  as total_sales,
    round(sum(profit), 2) as total_profit,
    sum(quantity)         as total_quantity
from {{ ref('curation_sales') }}
group by category
