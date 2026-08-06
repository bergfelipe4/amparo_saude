# The `audited` gem YAML-serializes `audited_changes`, which can contain
# ActiveSupport::TimeWithZone (datetime columns) and BigDecimal (decimal columns).
# Rails 7.1+'s safe YAML coder only permits Symbol by default — extend it so
# audited creates/updates on models with datetime/decimal columns don't raise
# Psych::DisallowedClass. Runs in after_initialize so it applies after any
# framework-default value has already been set.
Rails.application.config.after_initialize do
  ActiveRecord.yaml_column_permitted_classes |= [ActiveSupport::TimeWithZone, ActiveSupport::TimeZone, BigDecimal, Time, Date]
end
