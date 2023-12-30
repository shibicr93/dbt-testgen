

{% set actual_yaml = testgen.print_uniqueness_test_suggestions(
        ref('users'),
        compound_key_length = 1
    )
%}

{% set expected_yaml %}
models:
- name: users
  tests: []
  columns:
  - name: user_id
    description: Uniqueness test generated by dbt-testgen
    tests:
    - unique:
        tags:
        - uniqueness
    - not_null:
        tags:
        - uniqueness
  - name: username
    description: Uniqueness test generated by dbt-testgen
    tests:
    - unique:
        tags:
        - uniqueness
    - not_null:
        tags:
        - uniqueness
  - name: email
    description: Uniqueness test generated by dbt-testgen
    tests:
    - unique:
        tags:
        - uniqueness
    - not_null:
        tags:
        - uniqueness
{% endset %}

{{ assert_equal (actual_yaml | trim, expected_yaml | trim) }}