terraform {
  backend "remote" {
    organization = "demo-terrafrom"

    workspaces {
      name = "ya_cloud"
    }
  }
}