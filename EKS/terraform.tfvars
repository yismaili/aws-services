cluster_name = "pingpong-k8s-cluster"
region       = "us-west-2"
k8s_version  = "1.28"

frontend_node_size  = "t3.small"   # ~2 vCPU, 2GB RAM
frontend_node_count = 1

backend_node_size   = "t3.small" #t3.medium
backend_node_count  = 1

database_node_size  = "t3.small"   
database_node_count = 1

postgres_volume_size       = 20
postgres_volume_type       = "gp3"
postgres_volume_iops       = 3000
postgres_volume_throughput = 125