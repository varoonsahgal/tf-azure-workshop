# Module 2: More advanced operations

# The Challenge

In the previous module you have used Terraform to deploy a Linux virtual machine in an existing Azure VNet.

In this module, we will continue working on our previous example. We will add some more Azure resources to our example to harden our virtual machine, and add some flexibility for re-using this template by using more variables.
If you have not completed the previous module, you can use the full code example in the [full_solution folder in module-1](../module-1/full_solution).

The ultimate goal is to create a Terraform template that can be re-used by other people, or can be turned into a Terraform module!

To repeat:
> Assignments are marked like this.

<details>
<summary>Solutions are shown like this.</summary>
    Hi! Only open these when you are completely clueless.
</details>
<p></p>

And you can also earn **Bonus points**! These are not included in the full solution, so it's fully up to you on how you solve these challenges!

See how far you can get during the workshop:

- **Level 0: Recreate your destroyed resources from the previous module**
- **Level 1: Add an Azure Key Vault resource for storing your credentials and keys**
- **Level 2: Work with Azure identities to provide credential-free access to your Azure resources**
- **Level 3: Work with provisioners and extensions to configure virtual machines after creation**
- **Level 4: Secure network access to and between your virtual machine and key vault**
- **Level 5: Add more variables and experiment with ways to pass and validate variable values**
- **Level 6: Work with some popular Terraform CLI options**

Some general tips before you start:

- With Terraform, you basically create a template to deploy infrastructure. This means that a lot of examples are available all over the internet. You can often find a module or template that allows you to only fill out some variables in order to deploy a resource that matches your needs.
- Think of Terraform as an API layer for the Azure API itself. Any option you see in the Azure portal, or remember from your work, has an equivalent property in the corresponding resource. So if you are lost, go to the portal and try creating a resource manually. The properties you see there reflect the properties you can set for that resource in Terraform. Just use the [provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) to find out the name of the property for that resource.
- Always run `terraform plan` before you run `terraform apply`. Terraform will clearly show you the impact your code changes will have on the real world infrastructure. You can experiment all you want if you use `plan`.
- Check out [this](https://www.tfwriter.com/azurerm/azurerm.html) awesome website to grab some autogenerated Terraform code. If you are ever in need of some prefabricated code for creating a resource, variable or output you can get it here. This one is for the advanced users, but once you find out how useful it is you keep coming back!
- If you run into any issues anywhere, just run `terraform destroy` and `terraform apply` again. The beauty of declarative languages is you get exactly the same infrastructure back the way you wrote it in your code :)
  
## Level 0: Recreate your destroyed resources from the previous module

If you came here from the last workshop, you can use the code you wrote in the previous module. If you have not completed the previous module, you can use the full code example in the [full_solution folder in module-1](../module-1/full_solution).

> Go to the folder containing your `.tf` files and run `terraform apply -auto-approve` to (re-)deploy your resources.

## Level 1: Add an Azure Key Vault resource for storing your credentials and keys

We are currently only storing our credentials and SSH key within Terraform. Within any cloud environment, it is best practice to store your secrets in some kind of vault. Hashicorp has their own solution for this, Hashicorp Vault, as does AWS with their Key Management Service. Within Azure, this is called the Key Vault resource. When you store your keys and credentials in a Key Vault, you have a safe mechanism for sharing them with other people by providing them access to the Key Vault.

An Azure Key vault is fully locked by default. You have to explicitly give access to a vault using access policies. These access policies require you to specify an Object ID, which is a unique identifier for an identity in Azure. These identities are either a user, service principal or security group in the Azure Active Directory tenant. If you are using a service principal or security group, both an Application and an Object ID is provided. In the case that you are logged in with your personal Microsoft account, only an Object ID is provided.
Note: you can also use Azure RBAC for authorization, but that it out of scope for this workshop. You can read more about Key Vault access policies vs. Azure RBAC tradeoff [here](https://docs.microsoft.com/en-us/azure/key-vault/general/rbac-migration)

> Create an Azure Key Vault resource with the `standard` SKU. Configure that deleted secrets are retained for 10 days and ensure that RBAC authorization is disabled in favor of access policies. Make sure that your own user (or your configured service principal) has `Set & Get` secret permissions. Use the same naming convention, tags and the resource references you learned in the previous module.

<details>
<summary>Solution</summary>

```hcl
resource "azurerm_key_vault" "watech-kv" {
  name                = "${local.trimmed_rootname}-kv"
  location            = var.location
  resource_group_name = azurerm_resource_group.watech-rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = local.tags

  enable_rbac_authorization  = false
  soft_delete_retention_days = 10

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "Set",
    ]
  }
}

```

</details>

TIP: Use the [`azurerm_client_config` data source](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) to grab the tenant ID and object ID for the currently logged in identity dynamically.

**Bonus points**: You currently cannot verify that your user has access to the secret in Key Vault in the Azure Portal. What additional permission do you need for this?

We want to ensure that our Linux virtual machine's admin user is locked down using a key that is not available anywhere but in the Key Vault. The limitation of the `tls_private_key` we used in the previous module is that it is still written in plain-text to the state file, and can thus be accessed by anyone that has access to the state file.
> Verify this using the `terraform output` command. Add the name of the output in `outputs.tf` and the end of this command. Add the `-raw` flag to be sure you do not get weird additional characters.

<details>
<summary>Output</summary>

    terraform output -raw private_ssh_key

    -----BEGIN RSA PRIVATE KEY-----
    ...key contents...
    -----END RSA PRIVATE KEY-----

</details>

As you can see in the Security Notice of the [tls_private_key resource](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key), Hashicorp does not recommend storing the key in the state file and advises you to generate the key outside of Terraform and provide it another way. We can do this using the `openssh` utility on our own laptop or through any other method for generating keys, but this is outside of the scope of this workshop.

> Write both the private and public key generated by the `tls_private_key` resource to separate Key Vault secrets in the openssh format.

<details>
<summary>Solution</summary>

```hcl
resource "azurerm_key_vault_secret" "watech-private-key" {
    name            = "private-key-openssh"
    value           = tls_private_key.watech-ssh-key.private_key_openssh
    key_vault_id    = azurerm_key_vault.watech-kv.id
    expiration_date = "2025-12-31T00:00:00Z"
    content_type    = "openssh private key"
}

resource "azurerm_key_vault_secret" "watech-public-key" {
    name            = "public-key-openssh"
    value           = tls_private_key.watech-ssh-key.public_key_openssh
    key_vault_id    = azurerm_key_vault.watech-kv.id
    expiration_date = "2025-12-31T00:00:00Z"
    content_type    = "openssh public key"
}
```

</details>

**Bonus points**: Use the `random` provider to create a VM password with a length of 8 characters, containing 1 numeric, 2 special and a minimum of 3 upper characters and add this to your previously created Key Vault.

**More bonus points**: Use Terraform functions to generate an expiration_date on your secrets that is 6 months from the current timestamp.

Now that we have created the secrets in the Azure Key Vault, you can check them out in the Azure Portal.
> Navigate to your Key Vault and click Secrets in the left hand pane. Why can you not list the secrets? Fix this in your `main.tf` file. Next, ensure that the private key is no longer outputted when running `terraform` apply, and that the VM you create now references the secret in the Azure Key Vault.

<details>
<summary>Solution</summary>

```hcl
# Add List permissions to your current user context
...
    secret_permissions = [
      "Get",
      "Set",
      "List",
    ]
...

# Change the SSH key reference of your virtual machine to reference the key vault secret
...
  admin_ssh_key {
    username   = var.yourname
    public_key = azurerm_key_vault_secret.watech-public-key.value
  }
...
```

</details>

## Level 2: Work with Azure identities to provide credential-free access to your Azure resources

Ideally you want to be able to access Azure resources from within your virtual machines without having to supply credentials. Say you want to grab a key or secret from an Azure Key Vault within a script running on your virtual machine or give your application access to a database, both running within Azure. To achieve this, you would need some kind of login mechanism using a user account or service principal that needs to be supplied to the machine.

Let's experiment with this and SSH into our machine. If you do not have your private key anymore, you can grab it from the Azure Key vault using the following command:

`az keyvault secret download --file watech-private-key.pem --vault-name <name-of-your-key-vault> --name private-key-openssh`

Then login to your machine the same way you did in module 1:

`ssh -i watech-private-key.pem <your_name>@<ip_address>`

Install the Azure CLI using the following command:

`curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`

Now, try running the same command to download the Key Vault secret. This will not work:
<details>
<summary>Output</summary>
    Please run 'az login' to setup account.
</details>
<p></p>

Ofcourse, this is expected behavior, as you did not perform any login on this machine. You can run `az login` on this machine, but imagine a scenario where you want to have complete hands-off deployment, and want to run a script to configure this machine. Also, you do not want any single user account linked to this machine. This leaves you with two options: service principals and managed identities.

A service principal would still require you to specify or store credentials within the service principal, so managed identities remain. Read more about them [here](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview). In this workshop we will limit ourselves to the use of **System-Assigned Managed Identities**.

What we would like to do now is give the identity of our virtual machine access to the key vault. By default, Terraform does not create a System-Assigned Managed Identity with every resource that supports it, such as the `azurerm_linux_virtual_machine` resource we are using.

> Extend your `azurerm_linux_virtual_machine` resource to also generate a `SystemAssigned` identity

<details>
<summary>Solution</summary>

```hcl
  identity {
    type = "SystemAssigned"
  }
```

</details>
<p></p>

**Be sure to run `terraform apply` to make sure the identity is created before continuing to the next steps.**

> Extend your key vault's access policy to give the virtual machine's identity secrets `Get` permissions. Tip: look for the exported properties of the `azurerm_linux_virtual_machine` resource.

<details>
<summary>Solution</summary>

```hcl
...
access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_virtual_machine.watech-vm.identity.principal_id

    secret_permissions = ["Get",]
  }
...
```

</details>
<p></p>
Now when you try to run it, it will show the following message:

<details>
<summary>Output</summary>
    Error: Cycle: azurerm_key_vault_secret.watech-public-key, azurerm_linux_virtual_machine.watech-vm, azurerm_key_vault.watech-kv
</details>
<p></p>

This is a great example of what Terraform calls *implicit dependencies* ([more here](https://learn.hashicorp.com/tutorials/terraform/dependencies)). What is basically happening, is that Terraform automatically creates resources in a specific order based on their dependencies, which are defined using resource references. The problem here is that we are defining an access policy for `azurerm_linux_virtual_machine.watech-vm` on key vault `azurerm_key_vault.watech-kv` which means Terraform will first create the virtual machine and then reference it in the access policy. But the virtual machine is also reliant on the `azurerm_key_vault_secret.watech-public-key` which is only created after the Key Vault is created. This causes a cycle that Terraform cannot understand by itself.

> To solve this, change back the reference to `tls_private_key.watech-ssh-key.private_key_openssh` on your `azurerm_linux_virtual_machine` resource.

Our virtual machine now has access to the Key Vault using it's own identity. We can now log back in to the virtual machine and authenticate to Azure without specifying any credentials:

`az login --identity --allow-no-subscriptions`

Now try running the `az keyvault secret download` command again to verify that you can download the key without running into any authentication errors.

## Level 3: Work with provisioners and extensions to configure virtual machines after creation

Provisioners are a way for Terraform to hack/customize your Terraform code. HashiCorp states that provisioners are to be used as a last resort ([more here](https://www.terraform.io/language/resources/provisioners/syntax)), since their is no way for Terraform to check their result using the declarative approach. Especially with providers that aren't supported by the original creators, you might sometimes need to resort to the official CLI or custom code. For example, back when the `azurerm` provider wasn't officially maintened by Microsoft, you often needed to use the `local-exec` provisioner to run Azure CLI commands for features that were not yet supported by Terraform.

The assignments we are going to do below are not really a good practice, but should help you when you get stuck with using Terraform. Things like configuring a VM after creation should normally be done with configuration management tools such as Ansible.

The main 'ugly' provisioners you will use are `local-exec` and `remote-exec`. The simple difference is that you use `local-exec` for running a command on the machine Terraform is running on (like your local device), and `remote-exec` is for running something on the resource you declare it in (like on the virtual machine you are creating). An alternative to this is running it as part of a `null_resource`.




---

### Working with `local-exec`

We will use the `local-exec` provisioner to run a command **on the same machine running Terraform** (like your local laptop or your pipeline agent). This can be helpful when you want to record information after deployment or trigger external scripts.

> Write the public IP address of your virtual machine to a file on your local machine named `vm_ip.txt`. This can be useful if you want to share the IP with another script, automation step, or simply log it.

<details>
<summary>Solution</summary>

```hcl
resource "null_resource" "write_vm_ip" {
  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.watech-public-ip.ip_address} > vm_ip.txt"
  }

  depends_on = [azurerm_linux_virtual_machine.watech-vm]
}
```

</details>

**Bonus points**: Make the path of the file configurable by introducing a variable (e.g. `output_file_path`).

---

### Working with `remote-exec`

The `remote-exec` provisioner runs commands **on the virtual machine** itself after it has been created. This is often used to perform lightweight configuration without using a full configuration management tool.

> Use `remote-exec` to install NGINX on your Linux virtual machine. You’ll SSH into the VM and run the required commands.

<details>
<summary>Solution</summary>

```hcl
resource "null_resource" "remote_nginx_install" {
  depends_on = [azurerm_linux_virtual_machine.watech-vm]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx"
    ]
  }

  connection {
    type        = "ssh"
    user        = var.yourname
    private_key = tls_private_key.watech-ssh-key.private_key_openssh
    host        = azurerm_public_ip.watech-public-ip.ip_address
  }
}
```

</details>

**Bonus points**:

* Add an `output` to display the NGINX homepage URL:

<details>
<summary>Bonus Output</summary>

```hcl
output "nginx_homepage" {
  value = "http://${azurerm_public_ip.watech-public-ip.ip_address}"
}
```

</details>

* Add a provisioner command that touches a file like `/tmp/nginx-installed.txt` to prove installation.

---


## Level 4: Secure network access to and between your virtual machine and key vault

By default, your Azure resources will be open to the internet. This means that SSH access over internet is possible without any firewall or IP whitelist in place. The same goes for your Key Vault, which is accessible using the Azure API. Of course, these resources are protected by Azure RBAC, but in cloud it is best practice to disable internet access by default.

Azure has the concept of **network security groups (NSGs)** to add a layer of security to your network. You can attach these NSGs to your subnets to centralize network rules. A single NSG can contain multiple security rules and can be attached to multiple subnets. A security rule is basically a way to deny or allow specific inbound or onbound traffic to a network port from a specific IP address or CIDR range.

> Let's start with creating a network security group and associating it to our subnet. Do not create any rules yet. Run `terraform apply`.

<details>
<summary>Solution</summary>

```hcl
resource "azurerm_network_security_group" "watech-nsg" {
  name                = "${local.rootname}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.watech-rg.name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "watech-nsg_to_subnet" {
  subnet_id                 = azurerm_subnet.watech-subnet.id
  network_security_group_id = azurerm_network_security_group.watech-nsg.id
}
```

</details>
<p></p>

Check out your NSG in the Azure Portal. Will connecting through SSH still work, and why (not)?

The next step is to start adding rules to your NSG. Just like with the Key Vault resource, you can do this inside the resource block of the security group itself, but you can also use a standalone resource. Check out the note on the `azurerm_network_security_group` resource in the Terraform documentation. Whether to do it inline or in the standalone resource is all up to you. Separating them gives you more flexibility but introduces some more code.

> Add an inbound rule to allow traffic to TCP port 22 on your personal IP address. (Tip: go to showmyip.com to find out your IP). Be aware of the priority.

<details>
<summary>Solution</summary>

```hcl
resource "azurerm_network_security_rule" "ssh-access" {
  name                        = "Allow-SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "<your ip address>" # Your own IP address
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.watech-workspace-rg.name
  network_security_group_name = azurerm_network_security_group.watech-nsg.name
}
```

</details>
<p></p>

Now that your virtual machine is (somewhat) locked away from the internet, there is still the Key Vault that is accessible from the internet. Another way that Azure uses to secure services is to only allow access from certain networks. This allows you to, for example, only allow access to certain Azure services from specific virtual networks or subnets.

Note: before continuing here, add `service_endpoints` to your subnet for Microsoft.KeyVault.

> Configure your Key Vault in such a way that it is only accessible from resources within your own subnet. Also make sure you can access it from your local device, otherwise you will not be able to communicate with it using Terraform.

<details>
<summary>Solution</summary>

```hcl
# azurerm_subnet.watech-subnet
...
service_endpoints = ["Microsoft.KeyVault"]

# azurerm_key_vault.watech-kv
...
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.watech-subnet.id]
    ip_rules                   = ["<your ip address>"] # Your own IP address
  }
...
```

</details>
<p></p>

## Level 5: Add more variables and experiment with ways to pass and validate variable values

The power of Terraform is mainly in the fact that you can define your infrastructure as a template or blueprint. To achieve this, you ideally want to use variables as much as possible. As you can read [here](https://www.terraform.io/language/values/variables) on the Terraform documentation, there are multiple ways to declare, pass and validate variables.

As we've seen in the previous module, you can supply variables to Terraform in different ways. In real-world scenarios, you will often use environment variables and variable files that are generated on the fly in a CI/CD pipeline. Terraform uses an order of precedence for loading variables, so you will often find yourself combining different ways to supply your variables to a Terraform template or module:

- Environment variables
- The terraform.tfvars file, if present.
- The terraform.tfvars.json file, if present.
- Any *.auto.tfvars or *.auto.tfvars.json files, processed in lexical order of their filenames.
- Any -var and -var-file options on the command line, in the order they are provided.

> Add some more variables to your `variables.tf` file. For example, you can make the VM size, OS disk type/size, subnet prefix or your IP address a variable. Whatever you like!

**Bonus points**: Also experiment with different default values, the `nullable` argument and type constraints/type constructors such as `number`, `bool` and `list`.

<details>
<summary>Solution</summary>

```hcl
# Just some examples, you can create whatever variables you like
# variables.tf

variable "vm_size" {
  description = "The size of the VM used for the VRE. To get a list of available VM sizes use az vm list-sizes --location \"westeurope\" -otable. Example values: Standard_NC6_promo, Standard_B4ms"

  type     = string
  default  = "Standard_B4ms"
  nullable = false
}

variable "os_disk_sku" {
  description = "The SKU used for the OS Disk. Possible values: Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS"

  type    = string
  default = "Standard_LRS"
}

variable "os_disk_size" {
  description = "The size in GB of the OS Disk."

  type    = number
  default = 128
}

variable "subnet_prefix" {
  type    = list(string)
  default = ["10.0.90.0/24"]
}

variable "store_public_key_in_key_vault" {
  type    = bool
  default = true
}
```

</details>
<p></p>

> Now go ahead and experiment with different ways to pass variables to Terraform, using the methods in the bullets above. Note: to pass values as an environment variable, prefix them with `TF_VAR_`, for example `TF_VAR_yourname`

Another powerful mechanism that Terraform added some time ago, is the possibility to validate variable values. This allows you to use some of Terraforms functions to verify that the input that is passed to Terraform is correct. For things like VM sizes, there is no way for Terraform to check whether you have provided a proper value, until the actual `apply` command is ran. You can basically insert any value into your Terraform template, and Terraform will accept it. But your upstream API or cloud provider will not. In comes variable validation: you can specify a list of values or a regular expression (regex) to which the inserted value must comply.

> Add the following validation rules to your `variables.tf`. Add the variables themselves if you have not done this yet. <p></p>
> - Validate that the VM size variable that is passed must start with 'Standard_'
> - Validate that the OS disk SKU is one of: Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS
> - Validate that the OS disk size is a whole number and at least 100GB (triple digits)

<details>
<summary>Solution</summary>

```hcl
# Just some examples, you can create whatever variables you like
# variables.tf

variable "vm_size" {
  description = "The size of the VM used for the VRE. To get a list of available VM sizes use az vm list-sizes --location \"westeurope\" -otable. Example values: Standard_NC6_promo, Standard_B4ms"

  type    = string
  default = "Standard_B2ms"

  validation {
    condition     = can(regex("^(Standard_)", var.vm_size))
    error_message = "The VM SKU must start with 'Standard_'. To get a list of available VM sizes use az vm list-sizes --location \"westeurope\" -otable."
  }
}

variable "os_disk_sku" {
  description = "The SKU used for the OS Disk. Possible values: Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS"

  type    = string
  default = "Standard_LRS"

  validation {
    condition     = can(regex("^(Standard_LRS|Premium_LRS|StandardSSD_LRS|UltraSSD_LRS)$", var.os_disk_sku))
    error_message = "The disk SKU must be one of: Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS."
  }
}

variable "os_disk_size" {
  description = "The size in GB of the OS Disk."

  type    = number
  default = 128

  validation {
    condition     = var.os_disk_size >= 100 && can(regex("[0-9]+", var.os_disk_size))
    error_message = "Must be a whole number and larger than 100."
  }
}
```

</details>
<p></p>

**Mega bonus points**: Create a variable and validation rule for your IP address to follow the format `<number>`.`<number>`.`<number>`.`<number>` and be longer than 7 characters.

Now, experiment again with passing wrong values to your Terraform script and see what happens!

## Level 6: Work with some popular Terraform CLI options

Next to the obvious `init`, `plan`, `apply` and `destroy` options, there are some more useful CLI options that you can use with the Terraform CLI. You can find the full list [here](https://www.terraform.io/cli/commands) or by running `terraform -help`. The ones you will probably use often are:

- `validate`: You can use this to validate that your syntax is correct and consistent, but does not verify anything against remote services or state. Think of it as a linter. You will often run this in a CI/CD pipeline or as a pre-commit hook.
- `fmt`: You can use this to format your code neatly to follow Terraform coding guidelines. It makes sure your outlines are set neatly and generally makes your code a bit nicer. You will often use this as a pre-commit hook.
    > Go ahead and try running it now!
- `console`: This will open an interactive console that you can use to type interpolations into and inspect their values. This command loads the current state. This lets you explore and test interpolations before using them in future configurations. It's a nice way to experiment with regular expressions, for example.
- `state`: You can use this to do state operations, such as listing what is currently in your state or removing stale items. Be careful with this and only use it as a last resort.
- `taint`: This neat command allows you to mark a resource as 'damaged' and tell it to be replaced the next time you run Terraform apply. It can be very helpful in some scenarios. Read more about it [here](https://www.terraform.io/cli/commands/taint)
