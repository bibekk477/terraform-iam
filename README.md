# IAM User and Group Management with Terraform and LocalStack

This project demonstrates how to manage AWS IAM users and groups using Terraform with LocalStack for local development and testing.

## Overview

This Terraform configuration creates IAM users from a userdata csv and organizes them into department-based groups. It's designed to work with LocalStack, allowing you to test IAM infrastructure locally without incurring AWS costs.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0+)
- [LocalStack](https://docs.localstack.cloud/getting-started/installation/) (Community or Pro)
- [AWS CLI](https://aws.amazon.com/cli/) (optional, for testing)
- Docker (for running LocalStack)

## Project Structure

```
.
├── provider.tf          # AWS provider configuration for LocalStack
├── variables.tf         # Variable definitions
├── locals.tf            # Local values - loads users from CSV
├── users.csv            # CSV file containing user data
├── users.tf             # IAM user creation and login profiles
├── groups.tf            # IAM group creation and memberships
├── outputs.tf           # Output definitions for users and passwords
└── README.md            # This file
```

## What This Configuration Does

### 1. **IAM Users** (`users.tf`)

- Creates IAM users from a `local.users` variable (defined elsewhere, e.g., in `locals.tf` or `terraform.tfvars`)
- Naming convention: `firstname.lastname` (lowercase)
- User path: `/users/`
- Tags each user with:
  - DisplayName
  - Department
  - JobTitle
- Creates login profiles with password reset required on first login

### 2. **IAM Groups** (`groups.tf`)

Creates five department-based groups:

- **IT Group** - IT department members
- **Admin Group** - HR and Administration members
- **Finance & Data Group** - Finance and Data department members
- **Marketing & Sales Group** - Marketing and Sales members
- **Operations & Support Group** - Operations and Customer Support members

### 3. **Group Memberships**

Automatically assigns users to groups based on their department tags using dynamic filtering.

### 4. **Outputs** (`outputs.tf`)

- Lists all created usernames
- Shows password status (sensitive output)

## Configuration Files Explained

### Provider Configuration (`provider.tf`)

```terraform
provider "aws" {
  region     = var.aws_region
  access_key = "test"
  secret_key = "test"

  # LocalStack-specific settings
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  endpoints {
    iam = var.localstack_endpoint  # Points to LocalStack
  }
}
```

**Key Points:**

- Uses dummy credentials (`test`/`test`) - LocalStack doesn't validate real AWS credentials
- Overrides AWS endpoints to point to LocalStack
- Skips AWS-specific validations that would fail with LocalStack

### Variables (`variables.tf`)

- `environment`: Environment type (default: "prod")
- `localstack_endpoint`: LocalStack URL (default: "http://localhost:4566")
- `aws_region`: AWS region (default: "us-east-1")

### Locals Configuration (`locals.tf`)

```terraform
locals {
  users = csvdecode(file("users.csv"))
}
```

**How it works:**

- `file("users.csv")` - Reads the CSV file content as a string
- `csvdecode()` - Parses the CSV string into a list of maps
- Each row becomes a map with keys matching the CSV headers
- This makes it easy to manage users without modifying Terraform code

**Advantages of CSV approach:**

- Non-technical staff can manage user lists
- Easy to bulk-import users from HR systems
- Can use Excel or Google Sheets to edit
- Simple to version control changes
- Clear separation of data from infrastructure code

## Setup Instructions

### 1. Start LocalStack

```bash
# Using Docker
docker run -d \
  --name localstack \
  -p 4566:4566 \
  -e SERVICES=iam,sts \
  localstack/localstack

# Or using LocalStack CLI
localstack start
```

### 2. Create User Data

The project uses a CSV file to define users. Create a `users.csv` file in your project root:

```csv
first_name,last_name,department,job_title
Aarav,Sharma,IT,Software Engineer
Sita,Karki,HR,HR Officer
Rohan,Gupta,Finance,Accountant
Nisha,Thapa,Marketing,Marketing Executive
Prakash,Adhikari,Operations,Operations Manager
Anita,Rai,Sales,Sales Representative
Sanjay,Joshi,IT,DevOps Engineer
Maya,Gurung,Customer Support,Support Specialist
Kiran,Bhandari,Data,Data Analyst
Pooja,Shrestha,Administration,Admin Assistant
Ramesh,Shrestha,IT,System Administrator
```

**CSV File Format:**

- **first_name**: User's first name
- **last_name**: User's last name
- **department**: Department (IT, HR, Finance, Data, Marketing, Sales, Operations, Customer Support, Administration)
- **job_title**: User's job title

The `locals.tf` file reads this CSV:

```terraform
locals {
  users = csvdecode(file("users.csv"))
}
```

This automatically creates a list of maps that Terraform can iterate over.

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan and Apply

```bash
# Preview changes
terraform plan

# Apply configuration
terraform apply
```

### 5. View Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output user_names

# View sensitive output (passwords)
terraform output -json user_passwords
```

## Testing with AWS CLI

You can verify the created resources using the AWS CLI pointed at LocalStack:

```bash
# List IAM users
aws --endpoint-url=http://localhost:4566 iam list-users

# List IAM groups
aws --endpoint-url=http://localhost:4566 iam list-groups

# Get group membership
aws --endpoint-url=http://localhost:4566 iam get-group --group-name it-group

# Get user details
aws --endpoint-url=http://localhost:4566 iam get-user --user-name kiran.bhandari
```

## Important Notes

### LocalStack Limitations

1. **IAM Policy Enforcement**: The free version of LocalStack doesn't enforce IAM policies. Users and groups are created, but permission checks aren't performed.

2. **Password Management**: Login profiles are created, but LocalStack doesn't provide a console login interface. This is primarily for testing infrastructure-as-code.

3. **Account ID**: LocalStack uses a default account ID (`000000000000`) unless configured otherwise.

### Lifecycle Management

The login profile resource includes a lifecycle block:

```terraform
lifecycle {
  ignore_changes = [password_length, password_reset_required]
}
```

This prevents Terraform from trying to reset passwords on every apply after the initial creation.

## Customization

### Managing Users via CSV

To add, modify, or remove users, simply edit the `users.csv` file:

**Adding a user:**

```csv
first_name,last_name,department,job_title
# ... existing users ...
Pallavi,Adhikari,Administration,Office Manager
```

**Modifying a user:**
Change any field in the CSV (department, job title, etc.)

**Removing a user:**
Delete the row from the CSV

After changes, run:

```bash
terraform plan   # Review changes
terraform apply  # Apply changes
```

**⚠️ Important:** Changing `first_name` or `last_name` will destroy and recreate the user, as these form the resource key.

### CSV Validation

Ensure your CSV file:

- Has headers: `first_name,last_name,department,job_title`
- Contains no empty rows
- Uses consistent department names (exact matches)
- Has no special characters in names that would make invalid IAM usernames

### Adding More Departments

To add a new department group:

1. Create a new group resource in `groups.tf`
2. Create a new membership resource with appropriate filtering

Example:

```terraform
resource "aws_iam_group" "engineering" {
  name = "engineering-group"
  path = "/groups/"
}

resource "aws_iam_group_membership" "engineering_members" {
  name  = "engineering-membership"
  group = aws_iam_group.engineering.name
  users = [
    for _, user in aws_iam_user.users : user.name
    if user.tags["Department"] == "Engineering"
  ]
}
```

### Changing Naming Conventions

Modify the user resource name attribute:

```terraform
name = lower("${each.value.first_name}.${each.value.last_name}")
# Change to:
name = lower("${each.value.first_name}_${each.value.last_name}")
```

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

## Troubleshooting

### Connection Issues

If Terraform can't connect to LocalStack:

- Verify LocalStack is running: `docker ps | grep localstack`
- Check the endpoint URL in your variables
- Ensure port 4566 is accessible

### Resource Creation Failures

If resources fail to create:

- Check LocalStack logs: `docker logs localstack`
- Verify the IAM service is enabled in LocalStack
- Ensure your user data structure matches the expected format

### CSV File Issues

If you encounter errors related to the CSV file:

**Error: "Invalid function argument"**

- Check that `users.csv` exists in the project root
- Verify the file is readable

**Error: "Missing required argument"**

- Ensure CSV has all required headers: `first_name`, `last_name`, `department`, `job_title`
- Check for typos in header names

**Error: "Invalid character in username"**

- IAM usernames can only contain alphanumeric characters, `+`, `=`, `,`, `.`, `@`, `_`, `-`
- Check for special characters in first/last names

**Duplicate users being created**

- Check for duplicate rows in CSV
- Verify no duplicate `first_name.last_name` combinations (case-insensitive)

To debug CSV parsing:

```bash
terraform console
> local.users
```

### State Issues

If you encounter state locking issues:

```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>

# Or remove and reinitialize
rm -rf .terraform terraform.tfstate*
terraform init
```
