# Lab Learn Terraform Modules

## Introduction
Terraform modules are a good way to abstract out repeated chunks of code, making it reusable across other Terraform projects and configurations. In this hands-on lab, we'll be writing a basic Terraform module from scratch and then testing it out.

## Project directories

Create project directory: `mkdir terraform_project`

Create directory for modules and within that directory create a folder for vpc: `mkdir -p modules/vpc`

## Create Terraform VPC module definitions

Create main.tf and add the following.  This is the main file responsible for creating a VPC and Subnet.  It also 
reads the data value for the latest AWS Linux AMI to be used when creating EC2 instances.

```terraform
provider "aws" {
  region = var.region
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "this" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.1.0/24"
}

data "aws_ssm_parameter" "this" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}
```

The main.tf file for defining VPC resources contains a variable that must be supplied. Create variables.tf file and 
define the region variable.

```terraform
variable "region" {
  type    = string
  default = "us-east-1"
}
```

Create an outputs.tf file to define what values are provided as output from the vpc creation module.  These are 
referenced by terraform resources that import the VPC module.

```terraform
output "ami_id" {
  value = data.aws_ssm_parameter.this.value
}

output "subnet_id" {
  value = aws_subnet.this.id
}

```
Note: The code in outputs.tf is critical to exporting values to your main Terraform code, where you'll be referencing this module. Specifically, it returns the subnet and AMI IDs for your EC2 instance.

Create a terrform definition file to create the main project resources.  Create main.tf file in the root project 
directory.

```terraform
variable "main_region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region = var.main_region
}

module "vpc" {
  source = "./modules/vpc"
  region = var.main_region
}

resource "aws_instance" "my-instance" {
  ami           = module.vpc.ami_id
  subnet_id     = module.vpc.subnet_id
  instance_type = "t2.micro"
}
```
Note: The code in main.tf invokes the VPC module that you created earlier. Notice how you're referencing the code using the source option within the module block to let Terraform know where the module code resides.

Create an outputs file for these created resources.

```terraform
output "PrivateIP" {
  description = "Private IP of EC2 instance"
  value       = aws_instance.my-instance.private_ip
}
```

## Deployment

Deploy Your Code and Test Out Your Module.  

First confirm code is formatted by running terraform fmt.

`terraform fmt -recursive`

Initialize the Terraform configuration to fetch any required providers and get the code being referenced in the module block:

`terraform init`

Validate the code to look for any errors in syntax, parameters, or attributes within Terraform resources that may prevent it from deploying correctly:

`terraform validate`

You should receive a notification that the configuration is valid.

Review the actions that will be performed when you deploy the Terraform code:

`terraform plan`

In this case, it will create 3 resources, which includes the EC2 instance configured in the root code and any resources configured in the module. If you scroll up and view the resources that will be created, any resource with module.vpc in the name will be created via the module code, such as module.vpc.aws_vpc.this.

To deploy the resources run the Terraform apply comand.

`terraform apply --auto-approve`

Note: The --auto-approve flag will prevent Terraform from prompting you to enter yes explicitly before it deploys the code.

Once the code has executed successfully, note in the output that 3 resources have been created and the private IP address of the EC2 instance is returned as was configured in the outputs.tf file in your main project code.

View all the resources that Terraform has created and is now tracking in the state file:

`terraform state list`

The list of resources should include your EC2 instance, which was configured and created by the main Terraform code, and 3 resources with module.vpc in the name, which were configured and created via the module code.

## Destroy/Cleanup

Run command to destroy resources.

`terraform destroy`
