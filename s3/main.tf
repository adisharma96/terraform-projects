resource "aws_s3_bucket" "finance" {
  bucket = "finance-232323243332"
  tags = {
    Description = "s3 bucket"

  }


}


resource "aws_s3_object" "finance-2020" {
  content = "a.txt"
  key     = "a.txt"
  bucket  = aws_s3_bucket.finance.id

}


data "aws_iam_group" "users" {
  group_name = "read-users"

}

resource "aws_s3_bucket_policy" "finance-policy" {
  bucket = aws_s3_bucket.finance.id
  policy = file("a.json")


}

output "test" {
  value = data.aws_iam_group.users.arn

}
