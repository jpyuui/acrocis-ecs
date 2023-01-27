variable "name" {
  description = "ECRで作成するリポジトリの名前"
  type        = string
}

variable "image_tag_mutability" {
  description = "tagのmutabilityを指定する。IMMUTABLEの場合は、tagが常に一意になるよう運用する"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.image_tag_mutability)
    error_message = "Allowed values for \"ecr_image_tag_mutability\" are \"IMMUTABLE\" or \"MUTABLE\"."
  }
}
