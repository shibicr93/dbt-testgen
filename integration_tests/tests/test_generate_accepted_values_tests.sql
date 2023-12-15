

{% set actual_model_yaml = toyaml(fromjson(tojson(
        testgen.get_accepted_values_test_suggestions(
            ref('users')
        )
    )))
%}

{% set expected_model_yaml %}
models:
- name: users
  columns:
  - name: user_status
    description: Accepted values test generated by dbt-testgen
    tests:
    - accepted_values:
        values:
        - active
        - inactive
{% endset %}

{{ assert_equal (actual_model_yaml | trim, expected_model_yaml | trim) }}