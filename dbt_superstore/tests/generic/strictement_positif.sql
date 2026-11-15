-- Test générique : échoue pour chaque ligne où la colonne est <= 0.
-- Les valeurs NULL sont ignorées (elles relèvent du test not_null).
{% test strictement_positif(model, column_name) %}

select {{ column_name }}
from {{ model }}
where {{ column_name }} <= 0

{% endtest %}
