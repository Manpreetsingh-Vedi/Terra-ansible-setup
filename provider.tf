#We are configuring the Master server and node server for the ansible practice lab.

# Configure the AWS Provider
provider "aws" {
  region = var.region
}
