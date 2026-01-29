# create iam users
resource "aws_iam_user" "users" {
  for_each = { for user in local.users : "${user.first_name}.${user.last_name}" => user }
  name = lower("${each.value.first_name}.${each.value.last_name}")
  path = "/users/"
  tags = {
    "DisplayName":"${each.value.first_name}${each.value.last_name}"
    "Department": each.value.department
    "JobTitle": each.value.job_title
  }
}

# Iam user login profile
resource "aws_iam_user_login_profile" "user_login" {
  for_each = aws_iam_user.users # using the created iam users from the resource above

  user    = each.value.name
  password_reset_required = true
  depends_on = [aws_iam_user.users]
  lifecycle {
    ignore_changes = [ password_length,password_reset_required ]
  }
}

