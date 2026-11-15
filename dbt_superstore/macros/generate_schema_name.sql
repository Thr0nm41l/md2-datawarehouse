-- Par défaut, dbt préfixe le schéma personnalisé par celui du profil
-- (dbt_dev_silver). On veut exactement les schémas SILVER et GOLD de
-- l'architecture attendue : le schéma personnalisé est donc utilisé tel quel.
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
