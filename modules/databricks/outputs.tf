output "cluster_id" {
  value = databricks_cluster.dev.id
}

output "mount_names" {
  value = [for m in databricks_mount.buckets : m.name]
}
