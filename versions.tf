# Configure Terraform version and the Pilvio provider.
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    pilvio = {
      source  = "pilvio-com/pilvio"
      version = ">= 1.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }

  # backend "s3" {
    # Configure your remote state backend below. Fill in the details!
    # bucket         = "YOUR-TF-STATE-BUCKET"   # <-- Set to an existing bucket name
    # key            = "nextcloud/terraform.tfstate"
    # region         = "eu-west-1"
    # endpoint     = "s3.eu-central-1.amazonaws.com"
    # access_key  = ""
    # secret_key  = ""
    # skip_credentials_validation = true
    # skip_metadata_api_check    = true
    # skip_requesting_account_id = true
    # force_path_style           = true
  # }
}

provider "pilvio" {
  apikey   = var.apikey
  host     = var.host        # e.g. "api.pilvio.com"
  location = var.location    # Allowed: "tll01", "jhvi", "jhv02"
}
