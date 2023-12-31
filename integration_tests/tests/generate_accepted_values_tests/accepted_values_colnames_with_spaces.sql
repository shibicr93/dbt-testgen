

{% set actual_yaml = toyaml(fromjson(tojson(
        testgen.get_accepted_values_test_suggestions(
            ref('colnames_with_spaces')
        )
    )))
%}

{% set expected_yaml %}
models:
- name: colnames_with_spaces
  columns:
  - name: First Name
    description: Accepted values test generated by dbt-testgen
    tests:
    - accepted_values:
        values:
        - Alice
        - Bob
        - John
  - name: Age (Years)
    description: Accepted values test generated by dbt-testgen
    tests:
    - accepted_values:
        values:
        - '22'
        - '25'
        - '30'
  - name: Current City
    description: Accepted values test generated by dbt-testgen
    tests:
    - accepted_values:
        values:
        - Chicago
        - New York
        - San Francisco
{% endset %}

{{ assert_equal (actual_yaml | trim, expected_yaml | trim) }}