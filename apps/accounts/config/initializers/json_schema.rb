# frozen_string_literal: true

# Disable MultiJSON support in json-schema to resolve deprecation warnings
JSON::Validator.use_multi_json = false
