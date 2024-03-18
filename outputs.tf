/***** Aurora PgSql Output Parameters *****/

output "Aurora_Pgsql_cluster_endpoint" {
  value       = module.aurora-pgsql.cluster_endpoint
  description = "The DNS address of the RDS instance"
}

output "Aurora_Pgsql_cluster_id" {
  value       = module.aurora-pgsql.id
  description = "The Aurora Postgresql Cluster ID"
}

output "Aurora_Pgsql_cluster_members" {
  value       = module.aurora-pgsql.cluster_members
  description = "List of Aurora Postgresql Instances that are a part of this cluster"
}

output "Aurora_Pgsql_database_name" {
  value       = module.aurora-pgsql.database_name
  description = "The database name"
}

output "Aurora_Pgsql_instance_endpoint" {
  value       = module.aurora-pgsql.instance_endpoint
  description = "The DNS address for this instance. May not be writable"
}

output "Aurora_Pgsql_instance_id" {
  value       = module.aurora-pgsql.instance_id
  description = "The Aurora Postgresql instance ID"
}

output "Aurora_Pgsql_reader_endpoint" {
  value       = module.aurora-pgsql.reader_endpoint
  description = "A read-only endpoint for the Aurora Postgresql cluster, automatically load-balanced across replicas"
}



