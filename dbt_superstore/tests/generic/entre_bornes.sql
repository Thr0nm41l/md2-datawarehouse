-- Test générique : échoue pour chaque ligne où la colonne sort de l'intervalle
-- [min_value, max_value] (bornes incluses). Les NULL sont ignorés.
{% test entre_bornes(model, column_name, min_value, max_value) %}

select {{ column_name }}
from {{ model }}
where {{ column_name }} < {{ min_value }}
   or {{ column_name }} > {{ max_value }}

{% endtest %}
