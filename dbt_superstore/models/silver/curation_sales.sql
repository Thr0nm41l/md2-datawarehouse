-- =============================================================================
-- SILVER.CURATION_SALES : ventes nettoyées et typées, une ligne par ligne de
-- commande. Source : RAW.SALES (toutes les colonnes y sont en texte).
-- =============================================================================

with source as (

    select * from {{ source('raw', 'sales') }}

),

-- 1. Renommage en snake_case et normalisation des chaînes vides en NULL
-- (le CSV ne distingue pas "vide" et "absent").
-- Le fichier source contient des espaces insécables (U+00A0) dans
-- certains noms de produits : on les remplace par des espaces simples.
renommage as (

    select
        nullif(trim("Row ID"), '')        as row_id,
        nullif(trim("Order ID"), '')      as order_id,
        nullif(trim("Order Date"), '')    as order_date,
        nullif(trim("Ship Date"), '')     as ship_date,
        nullif(trim("Ship Mode"), '')     as ship_mode,
        nullif(trim("Customer ID"), '')   as customer_id,
        nullif(trim("Customer Name"), '') as customer_name,
        nullif(trim("Segment"), '')       as segment,
        nullif(trim("Country"), '')       as country,
        nullif(trim("City"), '')          as city,
        nullif(trim("State"), '')         as state,
        nullif(trim("Postal Code"), '')   as postal_code,
        nullif(trim("Region"), '')        as region,
        nullif(trim("Product ID"), '')    as product_id,
        nullif(trim("Category"), '')      as category,
        nullif(trim("Sub-Category"), '')  as sub_category,
        nullif(trim(replace("Product Name", chr(160), ' ')), '') as product_name,
        nullif(trim("Sales"), '')         as sales,
        nullif(trim("Quantity"), '')      as quantity,
        nullif(trim("Discount"), '')      as discount,
        nullif(trim("Profit"), '')        as profit,
        _loaded_at
    from source

),

-- 2. Conversion dans les types appropriés.
-- Dates au format américain M/D/YYYY dans le fichier source.
-- Les codes postaux à 4 chiffres ont perdu leur zéro initial
-- (ex. 2138 au lieu de 02138) : on les complète sur 5 caractères.
-- Montants : 4 décimales au maximum dans la source.
typage as (

    select
        row_id::integer                       as row_id,
        order_id,
        
        to_date(order_date, 'MM/DD/YYYY')     as order_date,
        to_date(ship_date, 'MM/DD/YYYY')      as ship_date,
        ship_mode,
        customer_id,
        customer_name,
        segment,
        country,
        city,
        state,
        lpad(postal_code, 5, '0')             as postal_code,
        region,
        product_id,
        category,
        sub_category,
        product_name,
        sales::numeric(14, 4)                 as sales,
        quantity::integer                     as quantity,
        discount::numeric(5, 4)               as discount,
        profit::numeric(14, 4)                as profit,
        _loaded_at
    from renommage

),

-- 3. Gestion des valeurs nulles.
-- Les lignes sans identifiant de ligne ou de commande sont inexploitables et sont écartées.
-- Les attributs descriptifs absents sont remplacés par 'Non renseigné' 
-- pour ne pas disparaître des agrégats GOLD (GROUP BY).
-- Une remise absente signifie qu'aucune remise n'a été appliquée.
-- Les montants (sales, profit, quantity) ne sont pas inventés : un NULL
-- reste NULL et est ignoré par SUM().
valeurs_nulles as (

    select
        row_id,
        order_id,
        order_date,
        ship_date,
        coalesce(ship_mode, 'Non renseigné')     as ship_mode,
        customer_id,
        coalesce(customer_name, 'Non renseigné') as customer_name,
        coalesce(segment, 'Non renseigné')       as segment,
        coalesce(country, 'Non renseigné')       as country,
        coalesce(city, 'Non renseigné')          as city,
        coalesce(state, 'Non renseigné')         as state,
        postal_code,
        coalesce(region, 'Non renseigné')        as region,
        product_id,
        coalesce(category, 'Non renseigné')      as category,
        coalesce(sub_category, 'Non renseigné')  as sub_category,
        coalesce(product_name, 'Non renseigné')  as product_name,
        sales,
        quantity,
        coalesce(discount, 0)                    as discount,
        profit,
        _loaded_at
    from typage
    where row_id is not null
      and order_id is not null

),

-- 4. Vérification et suppression des doublons.
-- Si le même row_id chargé plusieurs fois alors on garde le chargement le plus récent.
-- Si la même ligne de commande (toutes les colonnes identiques sauf row_id) alors,
-- soit il s'agit d'une saisie en double, on garde le plus petit row_id,
-- soit le fichier source en contient une (row_id 3406 et 3407).
doublons as (

    select
        *,
        row_number() over (
            partition by row_id
            order by _loaded_at desc
        ) as rang_row_id,
        row_number() over (
            partition by order_id, order_date, ship_date, ship_mode,
                         customer_id, customer_name, segment, country, city,
                         state, postal_code, region, product_id, category,
                         sub_category, product_name, sales, quantity,
                         discount, profit
            order by row_id
        ) as rang_ligne
    from valeurs_nulles

)

-- 5. Résultat final avec le délai de livraison.
select
    row_id,
    order_id,
    order_date,
    ship_date,
    ship_date - order_date as shipping_delay_days,
    ship_mode,
    customer_id,
    customer_name,
    segment,
    country,
    city,
    state,
    postal_code,
    region,
    product_id,
    category,
    sub_category,
    product_name,
    sales,
    quantity,
    discount,
    profit,
    _loaded_at
from doublons
where rang_row_id = 1
  and rang_ligne = 1
