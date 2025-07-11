# Terraform Training

This repository is divided in several modules that guide you in your experience of learning to work with Terraform on Microsoft Azure. You will start with the basics and extend your code by going through the modules. At the end you should have worked with most of Terraform's features and have a solid foundation for working within your environment and if you ever want to get your Terraform Associate certification!

| Module   | Goal                                                                     |
|----------|--------------------------------------------------------------------------|
| [module-1](module-1/) | Terraform basics, and deploy your first resources to Azure  |
| [module-2](module-2/) | More advanced features for writing your infrastructure code |
| [module-3](module-3/) | Learn to work with Terraform modules                        |

Some general tips before you start:

- With Terraform, you basically create a template to deploy infrastructure. This means that a lot of examples are available all over the internet. You can often find a module or template that allows you to only fill out some variables in order to deploy a resource that matches your needs.
- Think of Terraform as an API layer for the Azure API itself. Any option you see in the Azure portal, or remember from your work, has an equivalent property in the corresponding resource. So if you are lost, go to the portal and try creating a resource manually. The properties you see there reflect the properties you can set for that resource in Terraform. Just use the [provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) to find out the name of the property for that resource.
- Always run `terraform plan` before you run `terraform apply`. Terraform will clearly show you the impact your code changes will have on the real world infrastructure. You can experiment all you want if you use `plan`.
- If you run into any issues anywhere, just run `terraform destroy` and `terraform apply` again. The beauty of declarative languages is you get exactly the same infrastructure back the way you wrote it in your code :)

And some useful links:

- [Terraform Associate Certification Study Guide](https://learn.hashicorp.com/tutorials/terraform/associate-study?in=terraform/certification)

