data "databricks_node_type" "smallest" {
  local_disk = true
}

data "databricks_spark_version" "latest" {
}

resource "databricks_instance_pool" "smallest_nodes" {
  instance_pool_name                    = "${var.project_name}-${var.environment}-pool"
  min_idle_instances                    = 0
  max_capacity                          = 10
  node_type_id                          = data.databricks_node_type.smallest.id
  idle_instance_autotermination_minutes = 20
}

resource "databricks_cluster" "dev" {
  cluster_name            = "${var.project_name}-${var.environment}-cluster"
  spark_version           = data.databricks_spark_version.latest.id
  instance_pool_id        = databricks_instance_pool.smallest_nodes.id
  autotermination_minutes = 20

  aws_attributes {
    instance_profile_arn = var.databricks_instance_profile_arn
    availability         = "SPOT_WITH_FALLBACK"
  }

  spark_conf = {
    "spark.databricks.io.cache.enabled" : "true",
    "spark.databricks.delta.preview.enabled" : "true"
  }
}

resource "databricks_mount" "buckets" {
  for_each = var.s3_buckets
  name     = each.key
  s3 {
    bucket_name = each.value
  }
}

