-- Test singulier : chaque table GOLD doit restituer le même chiffre d'affaires
-- et le même bénéfice totaux que la couche SILVER. Une ligne retournée = une
-- table GOLD incohérente. La tolérance absorbe les arrondis à 2 décimales.

with silver as (
    select sum(sales) as total_sales, sum(profit) as total_profit
    from {{ ref('curation_sales') }}
),

gold as (
    select 'agg_sales_by_region' as table_gold,
           sum(total_sales) as total_sales, sum(total_profit) as total_profit
    from {{ ref('agg_sales_by_region') }}
    union all
    select 'agg_sales_by_category',
           sum(total_sales), sum(total_profit)
    from {{ ref('agg_sales_by_category') }}
    union all
    select 'agg_monthly_sales',
           sum(total_sales), sum(total_profit)
    from {{ ref('agg_monthly_sales') }}
)

select
    gold.table_gold,
    gold.total_sales  as gold_sales,
    silver.total_sales as silver_sales,
    gold.total_profit  as gold_profit,
    silver.total_profit as silver_profit
from gold
cross join silver
where abs(gold.total_sales - silver.total_sales) > 1
   or abs(gold.total_profit - silver.total_profit) > 1
