# Cała infrastruktura w jednym pliku
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# Network dla edge AI platform
resource "docker_network" "wronai_edge_network" {
  name = "wronai_edge-net"
  ipam_config {
    subnet = "172.20.0.0/16"
  }
}

# Shared volumes
resource "docker_volume" "k3s_data" {
  name = "k3s-data"
}

resource "docker_volume" "kubeconfig_data" {
  name = "kubeconfig-data"
}

# K3s cluster jako Docker container (symulacja edge)
resource "docker_container" "k3s_server" {
  name  = "k3s-server"
  image = "rancher/k3s:v1.28.4-k3s2"

  privileged = true
  restart    = "unless-stopped"

  ports {
    internal = 6443
    external = 6443
  }

  ports {
    internal = 80
    external = 8088
  }

  ports {
    internal = 443
    external = 8443
  }

  env = [
    "K3S_KUBECONFIG_OUTPUT=/output/kubeconfig.yaml",
    "K3S_KUBECONFIG_MODE=666",
    "K3S_TOKEN=wronai_edge-token-2024"
  ]

  command = [
    "server",
    "--disable=traefik",
    "--disable=servicelb",
    "--disable=metrics-server",
    "--write-kubeconfig-mode=666",
    "--node-name=edge-master",
    "--cluster-cidr=10.42.0.0/16",
    "--service-cidr=10.43.0.0/16"
  ]

  volumes {
    container_path = "/output"
    host_path      = "${path.cwd}/kubeconfig"
  }

  volumes {
    container_path = "/var/lib/rancher/k3s"
    volume_name    = docker_volume.k3s_data.name
  }

  networks_advanced {
    name = docker_network.wronai_edge_network.name
    ipv4_address = "172.20.0.10"
  }

  # Health check
  healthcheck {
    test     = ["CMD", "k3s", "kubectl", "get", "nodes"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
  }
}

# Registry lokalny dla obrazów (opcjonalny)
resource "docker_container" "local_registry" {
  name  = "local-registry"
  image = "registry:2"

  ports {
    internal = 5000
    external = 5000
  }

  env = [
    "REGISTRY_STORAGE_DELETE_ENABLED=true"
  ]

  volumes {
    container_path = "/var/lib/registry"
    host_path      = "${path.cwd}/registry-data"
  }

  networks_advanced {
    name = docker_network.wronai_edge_network.name
    ipv4_address = "172.20.0.20"
  }

  restart = "unless-stopped"
}

# Create directories
resource "null_resource" "create_directories" {
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.cwd}/kubeconfig
      mkdir -p ${path.cwd}/k3s-data
      mkdir -p ${path.cwd}/registry-data
      chmod 755 ${path.cwd}/kubeconfig
    EOT
  }

  depends_on = [docker_network.wronai_edge_network]
}

# Wait for K3s to be ready
resource "time_sleep" "wait_for_k3s" {
  depends_on = [docker_container.k3s_server]
  create_duration = "45s"
}

# Verify kubeconfig exists
resource "null_resource" "verify_kubeconfig" {
  depends_on = [time_sleep.wait_for_k3s]

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for kubeconfig file
      timeout=60
      while [ $timeout -gt 0 ]; do
        if [ -f "${path.cwd}/kubeconfig/kubeconfig.yaml" ]; then
          echo "Kubeconfig found!"
          break
        fi
        echo "Waiting for kubeconfig... ($timeout seconds left)"
        sleep 2
        timeout=$((timeout-2))
      done

      if [ ! -f "${path.cwd}/kubeconfig/kubeconfig.yaml" ]; then
        echo "ERROR: Kubeconfig not found after waiting"
        exit 1
      fi

      # Fix kubeconfig server URL
      sed -i 's|server: https://.*:6443|server: https://localhost:6443|g' "${path.cwd}/kubeconfig/kubeconfig.yaml"
      echo "Kubeconfig configured for localhost access"
    EOT
  }
}

# Outputs
output "kubeconfig_path" {
  value = "${path.cwd}/kubeconfig/kubeconfig.yaml"
  description = "Path to the kubeconfig file"
}

output "k3s_endpoint" {
  value = "https://localhost:6443"
  description = "K3s cluster endpoint"
}

output "registry_url" {
  value = "localhost:5000"
  description = "Local Docker registry URL"
}

output "ai_gateway_url" {
  value = "http://localhost:30080"
  description = "AI Gateway access URL (after K8s deployment)"
}

output "grafana_url" {
  value = "http://localhost:30030"
  description = "Grafana dashboard URL (after K8s deployment)"
}

output "prometheus_url" {
  value = "http://localhost:30090"
  description = "Prometheus URL (after K8s deployment)"
}

output "network_info" {
  value = {
    network_name = docker_network.wronai_edge_network.name
    subnet       = "172.20.0.0/16"
    k3s_ip      = "172.20.0.10"
    registry_ip = "172.20.0.20"
  }
  description = "Network configuration details"
}