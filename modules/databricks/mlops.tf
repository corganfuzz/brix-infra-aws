resource "databricks_mlflow_experiment" "this" {
  name = "/Shared/${var.project_name}-${var.environment}-experiment"
}
