terraform {
  backend "remote" {
    organization = "demo-terrafrom"

    workspaces {
      name = "gcp_local"
    }
  }
}