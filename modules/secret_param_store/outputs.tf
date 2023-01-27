output "arn" {
  description = "parameter storeのarn。ECSのContainerDefinitionなどから参照する場合はこれを使う"
  value = aws_ssm_parameter.this.arn
}

output "name" {
  description = "parameter storeのname(/db/testみたいなやつ)。data-resourceなどから参照する場合はこれを使う"
  value = aws_ssm_parameter.this.name
}