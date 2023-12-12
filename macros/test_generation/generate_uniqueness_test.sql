{% macro query_to_list(query) %}
    {% set query_to_process %}
        {{ query }}
    {% endset %}

    {% set results = run_query(query_to_process) %}

    {% if execute %}
    {% set results_list = results.rows %}
    {% else %}
    {% set results_list = [] %}
    {% endif %}

    {{ return(results_list) }}

{% endmacro %}


{% macro print_uniqueness_test_suggestions_from_name(        
        schema_name,
        table_name,
        use_anchors = false,
        is_source = false,
        tags = ["uniqueness"],
        compound_key_length = 1,
        dbt_config = None
    ) 
%}
    {% if execute %}
        {{ print(schema_name) }}

        {% set table_relation = api.Relation.create(
            database = target.database,
            schema = schema_name,
            identifier = table_name
        ) %}

        {{ print(table_relation) }}

        {% do print_uniqueness_test_suggestions(table_relation, use_anchors, is_source, tags, compound_key_length, **kwargs) %} 

    {% endif %}

{% endmacro %}


{% macro print_uniqueness_test_suggestions(        
        table_relation,
        use_anchors = false,
        is_source = false,
        tags = ["uniqueness"],
        compound_key_length = 1,
        dbt_config = None
    ) 
%}
    {% if execute %}
        {% set tests = get_uniqueness_test_suggestions(table_relation, is_source, tags, compound_key_length, **kwargs) %} 

        {% if use_anchors %}
            {% set yaml = toyaml(tests) %}
        {% else %}
            {# Using JSON to get rid fo the YAML anchors that toyaml puts in #}
            {% set yaml = toyaml(fromjson(tojson(tests))) %}
        {% endif %}

        {{ print(yaml) }}
    {% endif %}

{% endmacro %}


{% macro get_uniqueness_test_suggestions(
        table_relation,
        is_source = false,
        tags = ["uniqueness"],
        compound_key_length = 1,
        dbt_config = None
    ) %}
    {# Run macro for the specific target DB #}
    {{ return(adapter.dispatch('get_uniqueness_test_suggestions')(table_relation, is_source, tags, compound_key_length, **kwargs)) }}
{%- endmacro %}


{% macro default__get_uniqueness_test_suggestions(
        table_relation,
        is_source = false,
        tags = ["uniqueness"],
        compound_key_length = 1,
        dbt_config = None
    ) 
%}
    {# kwargs is used for test configurations #}
    {% set test_config = kwargs %}
    {% do test_config.update({"tags": tags}) %}

    {% if is_source == true %}
        {% set models_or_sources = "sources" %}
    {% else %}
        {% set models_or_sources = "models" %}
    {% endif %}

    {% set columns = adapter.get_columns_in_relation(table_relation) %}

    {% set column_names = [] %}
    {% for col in columns %}
        {% do column_names.append(col.column) %}
    {% endfor %}

    {% set column_combinations = [] %}
    {% for i in range(compound_key_length) %}
        {% for col_combo in modules.itertools.combinations(column_names, i + 1)%}
            {% do column_combinations.append(col_combo) %}
        {% endfor %}
    {% endfor %}

    {% set count_distinct_exprs = [] %}
    {% set i = 0 %}
    {% for column_combo in column_combinations %}
        {% do count_distinct_exprs.append(
            "SELECT " ~ loop.index ~ " AS ordering, count(1) AS cardinality from (SELECT 1 FROM " ~ table_relation ~ " GROUP BY " ~ column_combo|join(", ") ~ ") t"
        ) %}
    {% endfor %}

    {% set count_distinct_sql %}
    {{ count_distinct_exprs | join("\nUNION ALL\n") }}
    ORDER BY ordering ASC
    {% endset %}

    {% set count_sql %}
        {{ "SELECT count(1) AS table_count FROM " ~ table_relation }} 
    {% endset%}

    {{ print(count_distinct_sql) }}

    {% set table_count = query_to_list(count_sql)[0].table_count %}

    {% set cardinality_results = zip(column_combinations, query_to_list(count_distinct_sql)) %}

    {% set unique_keys = [] %}
    {% for cardinality_result in cardinality_results %}
        {% if cardinality_result[1].cardinality == table_count %}
            {% do unique_keys.append(cardinality_result[0]) %}
        {% endif %}
    {% endfor %}

    {{ print(unique_keys) }}

    {% set columns_list = [] %}
    {% for unique_key in unique_keys %}
        {% if unique_key|length == 1 %}
            {% do columns_list.append({
                "name": unique_key[0],
                "description": "Uniqueness test generated by dbt-testgen",
                "tests": [
                    {"unique": test_config},
                    {"not_null": test_config}
                ]
            }) %}
        {% else %}
            {% do columns_list.append({
                "name": unique_key|join("_"),
                "description": "Uniqueness test generated by dbt-testgen",
                "tests": [
                    {"unique": test_config},
                    {"not_null": test_config}
                ]
            }) %}
        {% endif %}
    {% endfor %}

    {% if dbt_config == None %}
        {% set dbt_config = {models_or_sources: []} %}
    {% endif %}

    {% do dbt_config[models_or_sources].append({"name": table_relation.identifier, "columns": columns_list}) %}

    {% do return(dbt_config) %}

{% endmacro %}


