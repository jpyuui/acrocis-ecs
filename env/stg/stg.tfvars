region       = "ap-northeast-1"
service_name = "xxx"

default_tags = {
  Name        = "xxx-stg"
  ManagedBy   = "terraform"
  Environment = "staging"
}

codestar_connection_arn = "arn:aws:codestar-connections:ap-northeast-1:475423565790:connection/1d9b8484-dace-4405-8105-a6d0b5ea052c"

web_app_repository_url        = "https://github.com/framgia/xxx-dxpj-web.git"
subscriber_app_repository_url = "https://github.com/framgia/xxx-dxpj-subscriber.git"

developper_emails = [
  "ohtukayoshi.yoshi@gmail.com",
  "takeshi.morita@sun-asterisk.com",
  "miyuki.nagayama@sun-asterisk.com",
  "tran.vu.duc@sun-asterisk.com",
  "wei.you@sun-asterisk.com",
]