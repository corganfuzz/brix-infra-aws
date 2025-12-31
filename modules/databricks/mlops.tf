resource "databricks_mlflow_experiment" "this" {
  name        = "/Shared/${var.project_name}-${var.environment}-experiment"
  description = "MLflow Experiment for ${var.project_name} in ${var.environment}"
}

# resource "databricks_model_serving" "this" {
#   name = "${var.project_name}-${var.environment}-serving-endpoint"

#   config {
#     served_models {
#       name          = "model-A"
#       model_name    = "databricks-dbrx-instruct" # Using a foundation model as placeholder/default
#       model_type    = "FOUNDATION_MODEL"
#       workload_type = "CPU"
#       workload_size = "Small"
# 
#       scale_to_zero_enabled = true
#     }
# 
#     traffic_config {
#       routes {
#         served_model_name  = "model-A"
#         traffic_percentage = 100
#       }
#     }
#   }
# }
