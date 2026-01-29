# IT group
resource "aws_iam_group" "it" {
  name = "it-group"
  path = "/groups/"
}

# Admin group (HR + Admin)
resource "aws_iam_group" "admin" {
  name = "admin-group"
  path = "/groups/"
}

# Finance & Data group
resource "aws_iam_group" "finance_data" {
  name = "finance-data-group"
  path = "/groups/"
}

# Marketing & Sales group
resource "aws_iam_group" "marketing_sales" {
  name = "marketing-sales-group"
  path = "/groups/"
}

# Operations & Customer Support group
resource "aws_iam_group" "ops_support" {
  name = "ops-support-group"
  path = "/groups/"
}

# iam group memberships
# IT group
resource "aws_iam_group_membership" "it_members" {
  name  = "it-membership"
  group = aws_iam_group.it.name
  users = [
    for _, user in aws_iam_user.users : user.name
    if user.tags["Department"] == "IT"
  ]
}

# Admin group (HR + Administration)
resource "aws_iam_group_membership" "admin_members" {
  name  = "admin-membership"
  group = aws_iam_group.admin.name
  users = [
    for _, user in aws_iam_user.users : user.name
    if user.tags["Department"] == "HR" || user.tags["Department"] == "Administration"
  ]
}

# Finance & Data group
resource "aws_iam_group_membership" "finance_data_members" {
  name  = "finance-data-membership"
  group = aws_iam_group.finance_data.name
  users = [
    for _, user in aws_iam_user.users : user.name
    if user.tags["Department"] == "Finance" || user.tags["Department"] == "Data"
  ]
}

# Marketing & Sales group
resource "aws_iam_group_membership" "marketing_sales_members" {
  name  = "marketing-sales-membership"
  group = aws_iam_group.marketing_sales.name
  users = [
    for _, user in aws_iam_user.users : user.name
    if user.tags["Department"] == "Marketing" || user.tags["Department"] == "Sales"
  ]
}

# Operations & Customer Support group
resource "aws_iam_group_membership" "ops_support_members" {
  name  = "ops-support-membership"
  group = aws_iam_group.ops_support.name
  users = [
    for _, user in aws_iam_user.users : user.name
    if user.tags["Department"] == "Operations" || user.tags["Department"] == "Customer Support"
  ]
}
