data "azurerm_subscription" "ame_pm" {
}

data "azurerm_key_vault" "secret_store" {
  name                = "ame-kv01"
  resource_group_name = "mcg-core-svc"
}

data "azurerm_key_vault_secret" "tenant_id" {
  name          = "tenant-id"
  key_vault_id  = data.azurerm_key_vault.secret_store.id
}

data "azurerm_key_vault_secret" "subscription_id" {
  name          = "subscription-id"
  key_vault_id  = data.azurerm_key_vault.secret_store.id
}

data "azurerm_key_vault_secret" "gh_pat" {
  name          = "mcg-gh-pat"
  key_vault_id = data.azurerm_key_vault.secret_store.id
}

data "azurerm_key_vault_secret" "ado_sp_pwd" {
  name          = "ado-sp-pwd"
  key_vault_id = data.azurerm_key_vault.secret_store.id
}

resource "azuread_application" "ado_app" {
  name                       = "ado_sp_ame"
}

resource "azuread_service_principal" "ado_sp" {
  application_id               = azuread_application.ado_app.application_id
}

resource "azuread_service_principal_password" "ado_sp" {
  service_principal_id = azuread_service_principal.ado_sp.id
  description          = "My managed password"
  value                = data.azurerm_key_vault_secret.ado_sp_pwd.value
  end_date             = "2021-02-15T00:00:00Z"
}

resource "azurerm_role_assignment" "ado_sp_mgmtex_pm" {
  scope                = data.azurerm_subscription.ame_pm.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.ado_sp.object_id
}

resource "azurerm_key_vault_access_policy" "example" {
  key_vault_id = data.azurerm_key_vault.secret_store.id
  tenant_id    = data.azurerm_key_vault_secret.tenant_id.value
  object_id    = azuread_service_principal.ado_sp.object_id

  secret_permissions = [
    "get", "list"
  ]
}

# ** For Key Vaults with Role Based Authentication **
# resource "azurerm_role_assignment" "ado_sp_key_vault_secrets" {
#   scope                = data.azurerm_key_vault.secret_store.id
#   role_definition_name = "Key Vault Secrets User (preview)"
#   principal_id         = azuread_service_principal.ado_sp.object_id
# }