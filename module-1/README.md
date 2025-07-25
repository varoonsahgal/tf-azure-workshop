# Module 1: Introduction to Terraform

# The Challenge

You will use Terraform to create some basic infrastructure in our Azure Subscription.

In this module, we will work with most of the basic uses of Terraform. We will work with variables, outputs, locals, expressions, data sources, providers and the Core Terraform Workflow. Things like modules, functions, (remote) state, workspaces are purposely left out of scope. The ultimate goal is to deploy a Linux virtual machine in an existing Azure VNet.

> Assignments are marked like this.

<details>
<summary>Solutions are shown like this.</summary>

    Hi! Only open these when you need help!    

</details>
<p></p>

And you can also earn **Bonus points**! These are not included in the full solution, so it's fully up to you on how you solve these challenges!

See how far you can get during the workshop:

- [**Level 0: Install Terraform and connect to Azure**](#level-0-install-terraform-and-connect-to-azure)
- [**Level 1: Deploy your first resource - a resource group**](#level-1-create-your-first-resource---a-resource-group)
- [**Level 2: Reference this RG in your second resource - a storage account**](#level-2-reference-this-rg-in-your-second-resource---a-storage-account)
- [**Level 3: Create a variable and output file**](#level-3-create-a-variable-and-output-file)
- [**Level 4: Enforce a naming convention and tags using locals**](#level-4-enforce-a-naming-convention-and-tags-using-locals)
- [**Level 5: Creating a subnet in an existing virtual network**](#level-5-creating-a-subnet-in-an-existing-virtual-network)
- [**Level 6: Create and output a network card with a dynamic public IP address for the virtual machine**](#level-6-create-and-output-a-network-card-with-a-dynamic-public-ip-address-for-the-virtual-machine)
- [**Level 7: Generate and output a SSH key pair for the machine**](#level-7-generate-and-output-a-ssh-key-pair-for-the-machine)
- [**Level 8: Create the virtual machine and connect to it**](#level-8-create-the-virtual-machine-and-connect-to-it)
- [**Level 9: Destroy all of your resources**](#level-9-destroy-all-of-your-resources)

Some general tips before you start:

- With Terraform, you basically create a template to deploy infrastructure. This means that a lot of examples are available all over the internet. You can often find a module or template that allows you to only fill out some variables in order to deploy a resource that matches your needs.
- Think of Terraform as an API layer for the Azure API itself. Any option you see in the Azure portal, or remember from your work, has an equivalent property in the corresponding resource. So if you are lost, go to the portal and try creating a resource manually. The properties you see there reflect the properties you can set for that resource in Terraform. Just use the [provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) to find out the name of the property for that resource.
- Always run `terraform plan` before you run `terraform apply`. Terraform will clearly show you the impact your code changes will have on the real world infrastructure. You can experiment all you want if you use `plan`.
- If you run into any issues anywhere, just run `terraform destroy` and `terraform apply` again. The beauty of declarative languages is you get exactly the same infrastructure back the way you wrote it in your code :)
  
## Level 0: Install Terraform and connect to Azure

### Authenticate To Azure

**Option 1**

Login via the Azure CLI (should be installed already):

```sh
az login #should open a webpage

az account show # to validate that you're logged in

# Be sure to use the right subscription for this workshop - DataCouch is what we use
az account set -s "DataCouch"
```

You will also need to run this to set the subscription, the instructor will provide the full ID as well:

```
export ARM_SUBSCRIPTION_ID="<instructor-will-provide>"
```

Remember, all resources in Azure (like VMs, storage, etc.) must be created in a subscription to keep track of cost/billing - read here: https://github.com/varoonsahgal/tf-az-wt/wiki/Azure-subscriptions-and-resources

In addition all resources in Azure must be part of a resource group (to group logically related resources)


**Option 2**

Note: this option is not really necessary so you can safely skip, but just kept here as an FYI.

If you do not have the Azure CLI installed, you can use a service principal. If this is needed, the details will be shared during the workshop.
<p> Set the following environment variables:

```sh
$ export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
$ export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
$ export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
$ export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
```

You can also connect to Azure using certificates or managed identities, but that is out of scope for this workshop. More information can be found [here](https://www.terraform.io/docs/providers/azurerm/auth/azure_cli.html).

### Connect Terraform to Azure

Getting started with Terraform is easy. We have alread installed it for you, but you can easily do so in the future using Homebrew or Chocolatey. More information can be found [here](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/azure-get-started).

> Create a file named `main.tf` ( just put it in a folder called `tf-workshop` and then create a sub-folder called `module1` ) and simply add the following.  Open the file in the VSCode editor to make your life easier.  Turn on Auto-Save (ask instructor if that info is not shared)

```hcl
provider "azurerm" {
  features {}
}
```

azurerm stands for Azure Resource Manager, which is the modern deployment and management service for Azure.

### What's a provider plugin?

In Terraform, a provider is a plugin that lets Terraform interact with external platforms or services—like cloud providers, SaaS APIs, or on-prem systems.

In Simple Terms:
A provider is how Terraform knows how to talk to something like:

Azure → via the azurerm provider

AWS → via the aws provider

Google Cloud → via the google provider

GitHub, Datadog, Kubernetes, etc.

Terraform supports a huge amount of providers. A full list of these providers, including documentation, can be found in the [Terraform Registry](https://registry.terraform.io/browse/providers).


The code block above will tell Terraform to install the official `azurerm` provider. This is the bare minimum required to install the required files when you initialize Terraform. You can also specify provider settings or version constraints.<p>

> Now, navigate to this folder where you have the main.tf file and using your commandline run `terraform init` to initialize Terraform.

<details>
<summary>If Terraform initialized successfully, you will see the following output:</summary>

    Initializing the backend...

    Initializing provider plugins...
    - Finding latest version of hashicorp/azurerm...
    - Installing hashicorp/azurerm v2.64.0...
    - Installed hashicorp/azurerm v2.64.0 (self-signed, key ID 34365D9472D7468F)

    Partner and community providers are signed by their developers.
    If you'd like to know more about provider signing, you can read about it here:
    https://www.terraform.io/docs/cli/plugins/signing.html

    Terraform has created a lock file .terraform.lock.hcl to record the provider
    selections it made above. Include this file in your version control repository
    so that Terraform can guarantee to make the same selections by default when
    you run "terraform init" in the future.

    Terraform has been successfully initialized!

    You may now begin working with Terraform. Try running "terraform plan" to see
    any changes that are required for your infrastructure. All Terraform commands
    should now work.

    If you ever set or change modules or backend configuration for Terraform,
    rerun this command to reinitialize your working directory. If you forget, other
    commands will detect it and remind you to do so if necessary.

</details>

### Why the features block in the code above?

Starting with version 2.0 of the azurerm provider, Terraform requires the features block to be explicitly defined.

It acts as a placeholder for provider-specific configuration flags.

You can customize behaviors for certain resource types inside it.

### Moving on...
Now we can go ahead and start creating Azure resources using Terraform!

## Level 1: Create your first resource - a resource group

First, we will create a resource group that will contain your resources for this workshop. We will use the `azurerm_resource_group` resource for this. Be sure to change your name in the example below.
You can find additional documentation on this resource (and all other possible resources for the `azurerm` provider) [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group).

> Since we will all be working in the same Azure subscription, we will need unique names for our resources. So be sure to edit the snippet below, replacing <your_name> with your name (eg. 'vsahgal' - lose the <>), and add this to your `main.tf` file:

```hcl
provider "azurerm" {
  features {}

  subscription_id = "<GET-VALUE-FROM-INSTRUCTOR>"

}

resource "azurerm_resource_group" "watech-rg" {
  name     = "watech-<your_name>-rg"
  location = "westus2"
}
```

Add your subscription to the the provider block.  IF you set the enviornment variable earlier, the problem would be that if you create a new shell session it will not pull that variable.

Note, that from a security standpoint this is not great since our subscription id would be exposed in a github repo - NEVER a good idea in real world, but for now it's fine.  We will look at alternatives later.

### location is region

Above, location refers to the region the resource group will live in. So, why not just use the word region?  Because: 

- Azure's underlying Resource Manager (ARM) APIs use the property name location to specify where to deploy the resource.

- Terraform's azurerm provider is just a wrapper for those APIs — so it uses the same field name: location.


NOTE: this just creates a resource group, which is just meant to be a wrapper around resources.  No actual resources being created just yet...

**If you were instructed to use a different region like westus3 instead of 2, just replace it in your code please!**

Creating this resource in Azure is done by following [The Core Terraform Workflow](https://www.terraform.io/guides/core-workflow.html) - Write, Plan, Apply. We just did the 'Write' part, so run:

`terraform plan` to preview your changes:

<details>
<summary>Output</summary>

    An execution plan has been generated and is shown below.
    Resource actions are indicated with the following symbols:
    + create

    Terraform will perform the following actions:

    # azurerm_resource_group.rg will be created
    + resource "azurerm_resource_group" "watech-rg" {
        + id       = (known after apply)
        + location = "westus2"
        + name     = "watech-vsahgal-rg"
        }

    Plan: 1 to add, 0 to change, 0 to destroy.

    ------------------------------------------------------------------------

    Note: You didn't specify an "-out" parameter to save this plan, so Terraform
    can't guarantee that exactly these actions will be performed if
    "terraform apply" is subsequently run.

</details>
<p></p>

Mind the part at the bottom. We see that Terraform plans to add 1 resource, change 0 and destroy 0. This is what we want.

Now we can run `terraform apply` to finalize these changes and to actually create the Azure resource group. Terraform will show you the plan again, but also ask you to confirm the changes. Type 'yes' to apply the changes. *Pro tip:* Add the `-auto-approve` flag to skip this prompt.

<details>
<summary>Output</summary>

    An execution plan has been generated and is shown below.
    Resource actions are indicated with the following symbols:
    + create

    Terraform will perform the following actions:

    # azurerm_resource_group.rg will be created
    + resource "azurerm_resource_group" "rg" {
        + id       = (known after apply)
        + location = "westus2"
        + name     = "watech-vsahgal-rg"
        }

    Plan: 1 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes

    azurerm_resource_group.watech-rg: Creating...
    azurerm_resource_group.watech-rg: Creation complete after 3s [id=/subscriptions/SUBSCRIPTION_ID/resourceGroups/watech-vsahgal-rg]

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

</details>
<p></p>

Great success!! You've created your first Azure resource using Terraform.

One thing to note: A resource in TERRAFORM is a broader concept than a  resource group in Azure.  In Terraform, a resource is a block of code that defines and manages a single infrastructure object - which can be anything like a VM, a storage account, a VNet, etc..  Terraform resource blocks are used with all cloud providers, including AWS, Azure, GCP, and many others.

In Azure, a resource group (note: it's not just called a "resource") is a container/wrapper for Azure resources meant to deploy, manage, and monitor multiple resources as a single unit.

Now that you created a resource group in Azure, go to the Azure Portal to validate that it does indeed exist!


## Level 2: Reference this RG in your second resource - a storage account

We also need a storage account to store some boot diagnostics data. One of the strengths of Terraform's language (HCL) are its [expressions](https://www.terraform.io/docs/language/expressions/references.html).
You can use this to create clean, dynamic code that uses references instead of hardcoded values. One of the most basic uses is the reference to a resource attribute, like the name or ID of the resource. You can reference variables, local values, resources, data sources, outputs or any Terraform component you'd like.

For context for those of you more familiar with AWS: in AWS, the closest equivalent to an Azure Storage Account is Amazon S3, but it's not a 1:1 match because Azure Storage Account includes multiple types of storage under one service.

> Let's start with using this expression syntax to reference the resource group name in the storage account resource. I'll leave it to you to fix the snippet below. Change the name of the storage account like you did with the resource group, and use the expression syntax to reference the name of the resource group. Add this to your `main.tf` when you've figured it out.

```hcl
resource "azurerm_storage_account" "watech-sa" {
  name                     = "watech<yourname>sa"
  resource_group_name      = "watech-<your_name>-rg"
  location                 = "westus2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

<details>
<summary>Solution</summary>

    resource "azurerm_storage_account" "watech-sa" {
        name                     = "watechvsahgalsa"
        resource_group_name      = azurerm_resource_group.watech-rg.name
        location                 = "westus2"
        account_tier             = "Standard"
        account_replication_type = "LRS"
    }

</details>
<p></p>

If you want you can run the Terraform workflow again to see if your code is working as expected - so do a `terraform plan` first.

Then, run `terraform apply` and if it works it should show `1 to add, 0 to change, 0 to destroy`.

NOTE: You might see an error regarding the storage account name - unlike most Azure resources, the storage account name is not allowed to contain any special characters. We will get to this later. For now, give it a name similar to the snippet above.

## Level 3: Create a variable and output file

### Variable file
To create clean code, you should use variables wherever you can. Especially if you are going to re-use your code, for example as a Terraform module, you can't get around using variables. You can find more information on how Terraform deals with variables [here](https://www.terraform.io/docs/language/values/variables.html).

Let's say we want to make the `<your_name>` snippet dynamic so that we can all use the same `main.tf` file, and that you only need to change the variable to make the file custom to your situation.
> Create a file named `variables.tf` in the same directory as your `main.tf` file, and create a variable for your name.

```hcl
variable "yourname" {
  type = string
}
```

Note: Any file that has the name `terraform.tfvars` or ends with `*.auto.tfvars` will be automatically loaded by Terraform. Otherwise you have to specify the file location with the `-var` flag on the CLI.

We also want a variable for the Azure region to deploy in, so we don't need to repeat this every time. You can also use the expression syntax for this, but the variable way is the nicer option.
> Add this `location` variable to your `variables.tf` file so it contains two variables. Save and close the file.

**Bonus points**: use variable validation to ensure the variable containing your name is no longer than 10 characters. Even more bonus points if you enforce the variable to only allow the values `westus2` or `westus3`.

> Now, edit your `main.tf` file to reflect your variables. Remove the `<yourname>/<your_name>` snippets and replace `westus2` as the `location` value. The additional information provided on expressions should help you with this.
> Also read here on variable interpolation: https://developer.hashicorp.com/terraform/language/expressions/strings#interpolation

<details>
<summary>Solution</summary>

    resource "azurerm_resource_group" "watech-rg" {
        name     = "watech-${var.yourname}-rg"
        location = var.location 
        ...
    }

    resource "azurerm_storage_account" "watech-sa" {
        name     = "watech${var.yourname}sa"
        location = var.location 
        ...
    }
</details>

There are several ways to supply your variable values to Terraform. Pick any of the methods mentioned [here](https://www.terraform.io/docs/language/values/variables.html#assigning-values-to-root-module-variables). For this workshop we will use a `.tfvars` file.

> Create a file called `terraform.tfvars` containing the following:

```
location = "westus2"
yourname = "vsahgal"
```

Now, when you run `terraform apply`, nothing should change, which is exactly what we want. You can go ahead and experiment a bit and see what would happen if you used different values.

### Output file
Output values make information about your infrastructure available on the command line, and can expose information for other Terraform configurations to use. Output values are similar to return values in programming languages. Outputs are useful for a wide range of use cases, like outputting a full resource ID for use in a script or outputting a SSH key generated by Terraform. Terraform can output any attribute of any resource. You can find more information [here](https://www.terraform.io/docs/language/values/outputs.html).

In this workshop we will experiment with outputs by outputting the resource ID of our resource group.
> Create a file named `outputs.tf` in your working directory and tell Terraform to output our resource group's ID. 

<details>
<summary>Solution</summary>

    output "watech_rg_id" {
        description = "Returns the ID of the created resource group"
        value       = azurerm_resource_group.watech-rg.id
    }

</details>
<p></p>

Terraform will now output the full resource IP attribute at the end of `terraform apply`:

<details>
<summary>Output</summary>

    azurerm_resource_group.watech-rg: Refreshing state... [id=/subscriptions/582089b7-6ffa-47b0-8b9b-65f7c583852b/resourceGroups/watech-vsahgal-rg]
    azurerm_storage_account.watech-sa: Refreshing state... [id=/subscriptions/582089b7-6ffa-47b0-8b9b-65f7c583852b/resourceGroups/watech-vsahgal-rg/providers/Microsoft.Storage/storageAccounts/watechvsahgalsa]

    An execution plan has been generated and is shown below.
    Resource actions are indicated with the following symbols:

    Terraform will perform the following actions:

    Plan: 0 to add, 0 to change, 0 to destroy.

    Changes to Outputs:
    + watech_rg_id = "/subscriptions/582089b7-6ffa-47b0-8b9b-65f7c583852b/resourceGroups/watech-vsahgal-rg"

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes


    Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

    Outputs:

    watech_rg_id = "/subscriptions/582089b7-6ffa-47b0-8b9b-65f7c583852b/resourceGroups/watech-vsahgal-rg"

</details>
<p></p>

**Bonus points**: concatenate the output to an Azure portal URL, eg: https://portal.azure.com/#@BrightCubes.nl/resource/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP_NAME>/overview

TIP: Use the [`azurerm_client_config` data source](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) to grab the subscription ID dynamically.

## Level 4: Enforce a naming convention and tags using locals

Local values are a very powerful mechanism in Terraform. You can use it to make recurring expressions. More information can be found [here](https://www.terraform.io/docs/language/values/locals.html).
They are especially useful for declaring reusable blocks of code in which you can reference variables. You can use *variables* to configure a Terraform template, and use *locals* to use these variables in an expression. 

### Naming convention
A popular use for locals is for making sure all resources follow the same naming convention. Let's say we want to name all our resources `watech-<your_name>-<location>-` followed by the resource type. Of course, you can use the following method:

```hcl
resource "azurerm_resource_group" "watech-rg" {
  name = "watech-${var.yourname}-${var.location}-rg"
  ...
}

resource "azurerm_storage_account" "watech-sa" {
  name = "watech${var.yourname}${var.location}sa"
  ...
}
```

But let's say we keep adding resources and later on don't like the `watech` part. Then we need to go over all resources and change this part everywhere. You can make it a variable, but that would mean it can be changed by anyone supplying a variable set. Ideally, you want to make this as some kind of variable tied to this template. Instead, you can create a local value `rootname` where you define this naming convention based on the variables provided.

> To create a locals block, append the following at the top of your `main.tf` file, under the `provider` blocks:
> 
```hcl
locals {
    rootname = "watech-${var.yourname}-${var.location}"
}
```

> Since the storage account doesn't support special characters, create another local value called `trimmed_rootname` without the hyphens. It's worth noting that we can also just do the string replacement in the storage account name. But since we want to reuse this for the computer name later, we should make it a local value. <p>

```hcl
trimmed_rootname = "watech${var.yourname}${var.location}"
# ...or?
trimmed_rootname = replace(local.rootname, "-", "")
```

> Next, replace all `name` properties of our resources in the `main.tf` to reference the local value using the expressions syntax.

**Bonus points**: add a random ID to your naming convention. TIP: Use [Terraforms `random` provider](https://registry.terraform.io/providers/hashicorp/random/latest/docs) and the expressions syntax.

### Tags
Another popular use for locals is creating a repeatable tags block. Often you need to supply the same set of tags to every resource you create in Azure, like a cost center or resource owner. You can create a block of tags the same way you'd use it on any resource. This allows you to reference variable values without repeating this everywhere. You can then reference this in your resources using the expressions syntax. 

> Go ahead and create a `tags` block inside your `locals` block containing `costCenter`, `owner` and `region` tags.
Also add a tags property to your resources, referencing the `tags` block.

**Bonus points**: add an extra tag to a single resource of your choice, next to the default tags, using Terraforms `merge` function.

<details>
<summary>Solution</summary>

    locals {
        rootname         = "watech-${var.yourname}-${var.location}"
        trimmed_rootname = "watech${var.yourname}${var.location}"
        tags = {
           "costCenter" = "WatechInternal"
           "owner"      = var.yourname
           "region"     = var.location
        }
    }

    resource "azurerm_resource_group" "watech-rg" {
        name     = "${local.rootname}-rg"
        location = var.location
        tags     = local.tags
    }

    resource "azurerm_storage_account" "watech-sa" {
        name                = "${local.trimmed_rootname}sa"
        resource_group_name = azurerm_resource_group.watech-rg.name
        location            = var.location
        tags                = local.tags

        account_tier             = "Standard"
        account_replication_type = "LRS"
    }

</details>

Now, when you run `terraform apply`, both resources need to be recreated since we've added the `location` variable to the naming convention. Review the output of `terraform apply` and verify the changes, forcing the recreation of your resources to adhere to the new naming convention.

## Level 5: Creating a subnet in an existing virtual network

Terraform can also deal with existing resources. You can use `terraform import` to import existing resources into the state file, but there's a reason this feature has seen little development progress. You should use Terraform for resources that are created by Terraform itself, and not let it manage any resources it has not created itself.<p>
Instead, use *data sources* to reference existing resources in your Terraform code. 

> In this exercise, start with referencing the existing `watech-workshop-vnet` in the `watech-workshop-rg` resource group. Add this to your `main.tf` file.

TIP: Start looking around in the [provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) to find the documentation on the `azurerm_virtual_network` resource.

<details>
<summary>Solution</summary>

    data "azurerm_virtual_network" "watech-vnet" {
        name                = "watech-workshop-vnet"
        resource_group_name = "watech-workshop-rg"
    }

</details>

We don't have to run `terraform apply`, since simply adding the data source doesn't do anything. We can now reference this existing virtual network in the creation of our own subnet within this network. When we create the subnet using Terraform, the lifecycle of the subnet will be tied to your Terraform code, but the virtual network is not. This means that when we `destroy` our Terraform infrastructure, the subnet will be destroyed but the existing virtual network will be left untouched. If we would have *imported* the vitual network, it would be destroyed as well.

> Next, create a subnet in this virtual network data source. Use the expression syntax again to reference the virtual network and resource group. Also remember to use our naming convention. For the address prefix, you can pick any number in the *[10.0.<1-255>.0/24]* range. Let's hope none of you collide ;)

<details>
<summary>Solution</summary>

    data "azurerm_virtual_network" "watech-vnet" {
        name                = "watech-workshop-vnet"
        resource_group_name = "watech-workshop-rg"
    }

    resource "azurerm_subnet" "watech-subnet" {
        name                 = "${local.rootname}-subnet"
        resource_group_name  = data.azurerm_virtual_network.watech-vnet.resource_group_name
        virtual_network_name = data.azurerm_virtual_network.watech-vnet.name
        address_prefixes     = ["10.0.80.0/24"]
    }

</details>

Running `terraform apply` now will create the subnet for us.

## Level 6: Create and output a network card with a dynamic public IP address for the virtual machine

### Create the public IP address

In order to connect to the virtual machine at the end of this workshop, we need to create and assign a public IP address to this virtual machine. This one should be pretty easy if you remember everything you've learned until now, so I won't give away a lot of information. 

> Create a *dynamic* public IP address that we can assign to the virtual machine we are about to create, and tell Terraform to output this IP address. Be sure to use the expression syntax and add tags!
> Note that you would need  to set the sku to basic in your terraform!

<details>
<summary>Solution</summary>

    # Add this to your main.tf
    resource "azurerm_public_ip" "watech-pip" {
        name                = "${local.rootname}-pip"
        location            = var.location
        resource_group_name = azurerm_resource_group.watech-rg.name
        allocation_method   = "Dynamic"
        tags                = local.tags
    }

    # Add this to your outputs.tf
    output "public_ip_address" {
        description = "The public IP address for the virtual machine"
        value       = azurerm_public_ip.watech-pip.ip_address
    }

</details>
<p></p>

**Bonus points:** Create a variable for a custom domain name label and add this property to the public IP address resource. Also output the FQDN.

### Create the NIC

Next, assign this public IP to a network interface card (NIC). In this resource, you need to reference the subnet and public IP address created before.

> Go ahead and create a NIC. Use *dynamic* private IP address allocation and be sure to use the expression syntax and add tags!

<details>
<summary>Solution</summary>

    resource "azurerm_network_interface" "watech-nic" {
        name                = "${local.rootname}-nic"
        location            = var.location
        resource_group_name = azurerm_resource_group.watech-rg.name
        tags                = local.tags

        ip_configuration {
            name                          = "${local.rootname}-nic-cfg"
            subnet_id                     = azurerm_subnet.watech-subnet.id
            private_ip_address_allocation = "Dynamic"
            public_ip_address_id          = azurerm_public_ip.watech-pip.id
        }
    }

</details>
<p></p>

## Level 7: Generate and output a SSH key pair for the machine

We can supply our own key pair to the virtual machine by referencing a local path during the creation of the virtual machine. But there are cases where you want to link the lifecycle of the key to the lifecycle of the virtual machine. In those cases, it can be preferable to let Terraform generate the SSH key pair. This is not really production worthy, but fine for development environments or workshops like this. The main limitation is that it stores both the public and private key in plain text in the state file. There is an interesting note on this in the Terraform documentation [here](https://www.terraform.io/docs/language/state/sensitive-data.html).

For this you can utilize [Terraforms `tls` provider](https://registry.terraform.io/providers/hashicorp/tls/latest/docs). If you went for the bonus points you should have some experience with adding more providers :)

To install this provider, just add another `provider` block below the section where you initialize the `azurerm` provider in your `main.tf` file. After doing this, you need to run `terraform init` again to download this provider to your local drive.

```hcl
provider "tls" {}
```

> Add a TLS private key resource to your `main.tf` file.
 
<details>
<summary>Solution</summary>

    resource "tls_private_key" "watech-ssh-key" {
        algorithm = "RSA"
        rsa_bits  = 4096
    }

</details>

Of course, we need some way to extract this key after it has been created and added to the state file. To prevent the need to scroll through the state file, you can tell Terraform to output the key. As you may already know, we can do this by creating an `output` that will show the private key we can use to connect to the VM after running `terraform apply`.

<details>
<summary>Solution</summary>

    output "private_ssh_key" {
        description = "The private SSH key to access the VRE"
        value       = tls_private_key.watech-ssh-key.private_key_pem
    }

</details>

If you now run `terraform apply`, it should output the key in plain text. Oh no!
<p></p> 

> To prevent this, a recent version of Terraform introduced the `sensitive` property for outputs. It should be easy to add this property using the documentation mentioned [here](https://www.terraform.io/docs/language/values/outputs.html#sensitive-suppressing-values-in-cli-output).
<p></p>

<details>
<summary>Solution</summary>

    output "private_ssh_key" {
        description = "The private SSH key to access the VRE"
        value       = tls_private_key.watech-ssh-key.private_key_pem
        sensitive   = true
    }

</details>

Run `terraform apply` again to see the key is now redacted from the output, which can be particularly useful in deployment pipelines. The best practice would be to write the key to a secure vault and read it from there, but for debugging purposes it can be useful to add the key to the `outputs.tf` file. But when it is sensitive, there is still no way to access it without needing to grab and scroll through the state file. For that, you can use the `terraform output` command to extract the value of an output variable from the state file. More information is available [here](https://www.terraform.io/docs/cli/commands/output.html).

> Use the `terraform output` command to extract the private key and write this to a file called `watech-private-key.pem`. Use the `-raw` flag to be able to access a sensitive output.

<details>
<summary>Solution</summary>

    terraform output -raw private_ssh_key > watech-private-key.pem && chmod 600 watech-private-key.pem

</details>

## Level 8: Create the virtual machine and connect to it

We can now go ahead and create our virtual machine. We've already done a lot of the work up until this point, so we can use the expression syntax to tie everything together. For resources like virtual machines or even Kubernetes clusters, a lot of examples are available on the internet that suit your needs. For this level, I will leave it up to you to find a suitable template and edit it it to create a Linux VM with the resources we have created before.

> Find a suitable template for the `azurerm_linux_virtual_machine` resource. Create a VM of size `Standard_B2ms` in the existing subnet, using a Linux distro of your choice. Link the network card and public IP address we created, and use the expression syntax to reference the `public_key_openssh` property for the admin user's public key. Reuse the `trimmed_rootname` as the computer name. For the username, use the `yourname` variable. Also use the storage account's `primary_blob_endpoint` property to enable boot diagnostics on the VM and apply our tags block.

<details>
<summary>Solution</summary>

    resource "azurerm_linux_virtual_machine" "watech-vm" {
        name                  = "${local.rootname}-vm"
        location              = var.location
        resource_group_name   = azurerm_resource_group.watech-rg.name
        size                  = "Standard_B2ms"
        network_interface_ids = [azurerm_network_interface.watech-nic.id]
        admin_username        = var.yourname
        computer_name         = local.trimmed_rootname
        tags                  = local.tags

        # SSH key authentication
        admin_ssh_key {
            username   = var.yourname
            public_key = tls_private_key.watech-ssh-key.public_key_openssh
        }
        disable_password_authentication = true

        # Password authentication
        #admin_password = "ThisWasSuchACoolWorkshop!1!"
        #disable_password_authentication = false

        source_image_reference {
            publisher = "Canonical"
            offer     = "UbuntuServer"
            sku       = "18.04-LTS"
            version   = "latest"
        }

        os_disk {
            caching              = "ReadWrite"
            storage_account_type = "Standard_LRS"
        }

        boot_diagnostics {
            storage_account_uri = azurerm_storage_account.watech-sa.primary_blob_endpoint
        }
    }

</details>
<p></p>

NOTE: It may occur that you do not immediately see a public IP address appear. This is caused by the Azure API not reporting this yet. Just run `terraform apply` again: nothing will change, but it should output the public IP address.

Head over to the [Azure portal](https://portal.azure.com/#blade/HubsExtension/BrowseResourceGroups) to check out the resources you've created!

You should now be able to connect to the VRE using the following command:
```
ssh -i watech-private-key.pem <your_name>@<ip_address>
```

If this does not work, try using the ssh-agent combined with the `terraform output` command.
```
eval $(ssh-agent -s) && terraform output -raw private_ssh_key | tr -d '\r' | ssh-add -
```
Now you can connect without the `-i` flag referencing your key, so connecting is `ssh -i <your_name>@<ip_address>`

NOTE: If you're having difficulties with connecting using a private key, try using password authentication instead. See the solution block above for both methods. The VM will need to be recreated if you change this, but that is not an issue.

## Level 9: Destroy all of your resources

Now that we're done and have proven the power of Terraform, it's time to cleanup our resources. In order to do so, run `terraform destroy`. Terraform will ask you one last time to verify your actions and when you enter `yes`, you're finished with the first part of the workshop! If you've made it all the way here: You're awesome!
