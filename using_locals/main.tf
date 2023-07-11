locals {
    name-prefix = "${var.name}-${var.id}"
}

resource "aws_s3_bucket" "buck-locals" {
    bucket = "${local.name-prefix}"
    tags = {
       Name = "${local.name-prefix}-bucket" 
    }

}

resource "aws_s3_object" "s3-object" {
    bucket = aws_s3_bucket.buck-locals.id
    key = "/test/${local.name-prefix}"
    content = "a.txt"

}
