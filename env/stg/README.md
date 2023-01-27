# Terraform for xxx Staging

## 構築手順

### 新規でインフラ環境を構築する場合

**※作業ディレクトリは`/terraform/env/stg`と仮定**  
**※`aws configure list`で正しい認証情報が設定されているか要確認**

1. `.tfstate`ファイルを管理する backend として S3 を、Terraform 以外の方法で作成する
2. `/terraform/env/stg/backend.tf`にて、`terraform`ブロックの`backend`ブロックを以下のように変更する

```hcl
  backend "s3" {
    bucket         = "<CREATED_BUCKET_NAME>"
    region         = "ap-northeast-1"
    key            = "terraform.tfstate"
    encrypt        = true
    # dynamodb_table = "xxx_tf_state_lock_stg" //コメントアウトする
  }
```

3. backend.tf の定義をもとに terraform を init する
   `terraform init`
4. 秘匿情報を`ssm parameter store`に保存するため、**ダミーの値**で initialize する  
   `make plan-initial-set-up-stg`  
   plan 結果が問題なければ、  
   `make apply-initial-set-up-stg`
5. CLI や GUI から、`terraform/env/stg/initialize_secret_params.tf`で作成している  
   `ssm parameter store`の値を**本来の値**で overwrite する
6. 他のリソースを作成する。  
   `make plan-stg`  
   `make apply-stg`  
   (RDS のマスターパスワードは`ssm parameter store`の値で自動的に modify される)
7. `/terraform/env/stg/backend.tf`にて、`terraform`ブロックの`backend`ブロックを以下のように再度変更する

```hcl
  backend "s3" {
    bucket         = "<CREATED_BUCKET_NAME>"
    region         = "ap-northeast-1"
    key            = "terraform.tfstate"
    encrypt        = true
    dynamodb_table = "xxx_tf_tfstate_lock_stg" # 6で作成されたのでコメントアウトを解除
  }
```

8. backend を更新する
   `terraform init -reconfigure`

### インフラ作成が完了した後の運用

1. 追加の秘匿情報は、`terraform/env/stg/initialize_secret_params.tf`に追加する。  
   `terraform/stg/Makefile`にある  
   `plan-initial-set-up-stg`, `apply-initial-set-up-stg`  
   の末尾に`-target=module.<追加したmoduleの名前>`を追記する。  
   `make plan-initial-set-up-stg`  
   `make apply-initial-set-up-stg`  
   実行することでダミーの値で store を作成してから、CLI や GUI から正しい値に変更する

## Terraform 管理外のリソース

・各環境の tfstate を保持する S3 バケット  
・ECR  
・Event Batch(Shopify から作成)
