terraform {
  backend "remote" {
    organization = "demo-terrafrom"

    workspaces {
      name = "gcp_k8s"
    }
  }
}