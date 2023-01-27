# SSM パラメーターストアで秘匿情報を管理する module

初期作成時、パラメーターの`dummy_value`には適当な値を dummy として入れ、
リソース作成後、手動で overwrite する
Terraform から設定してしまうと、tfstate に store した値が記入されてしまうため。
