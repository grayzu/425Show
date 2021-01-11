resource "azuredevops_project" "show425" {
  name       = "425 show proj"
  description        = "demo project"
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"

  features = {
      "testplans" = "disabled"
      "artifacts" = "disabled"
      "repositories" = "disabled"
  }
}

resource "azuredevops_serviceendpoint_azurerm" "ame_demos" {
  project_id                = azuredevops_project.show425.id
  service_endpoint_name     = "AME PM"
  description               = "Azure AME PM demo deployment target" 
  credentials {
    serviceprincipalid    = azuread_service_principal.ado_sp.application_id
    serviceprincipalkey   = azuread_service_principal_password.ado_sp.value
  }
  azurerm_spn_tenantid      = data.azurerm_key_vault_secret.tenant_id.value
  azurerm_subscription_id   = data.azurerm_key_vault_secret.subscription_id.value
  azurerm_subscription_name = "Azure MgmtEx PM R&D"
}

resource "azuredevops_serviceendpoint_github" "gh_sources" {
  project_id = azuredevops_project.show425.id
  service_endpoint_name = "GithHub AME PM demo sources"

  auth_personal {
    personal_access_token = data.azurerm_key_vault_secret.gh_pat.value
  }
}

resource "azuredevops_resource_authorization" "auth" {
  project_id  = azuredevops_project.show425.id
  resource_id = azuredevops_serviceendpoint_azurerm.ame_demos.id
  authorized  = true
}

resource "azuredevops_resource_authorization" "github" {
  project_id  = azuredevops_project.show425.id
  resource_id = azuredevops_serviceendpoint_github.gh_sources.id
  authorized  = true
}

resource "azuredevops_build_definition" "app_425_show" {
  project_id = azuredevops_project.show425.id
  name       = "425show Build"

  ci_trigger {
    use_yaml = true
  }

  repository {
    service_connection_id = azuredevops_serviceendpoint_github.gh_sources.id
    repo_type             = "GitHub"
    repo_id               = "grayzu/425show-app-config"
    branch_name           = "main"
    yml_path              = "425show-pipeline.yml"
  }
}
