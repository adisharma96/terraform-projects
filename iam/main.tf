resource "aws_iam_group" "administrators" {
    name = "admins"

}

resource "aws_iam_policy" "admin-policy" {
    name = "admin-policy"
    policy = file("a.json")
}


resource "aws_iam_user" "admin" {
    name = each.value
    for_each = toset(var.name)

}

resource "aws_iam_user_group_membership" "membership" {
    for_each = toset(var.name)
    user =   aws_iam_user.admin[each.value].name
    groups = [ aws_iam_group.administrators.name ]

}

resource "aws_iam_group_policy_attachment" "attach-policy" {
    group = aws_iam_group.administrators.name
    policy_arn = aws_iam_policy.admin-policy.arn

}

