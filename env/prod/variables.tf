variable "databricks_host" {
  description = "Databricks Workspace URL"
  type        = string
}

variable "databricks_token" {
  description = "Databricks Personal Access Token"
  type        = string
  sensitive   = true
}

variable "fred_api_key" {
  description = "FRED API Key for mortgage rates"
  type        = string
  sensitive   = true
}
