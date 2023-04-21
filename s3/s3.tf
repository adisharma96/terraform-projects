resource "aws_s3_bucket" "my-bucket" {
       bucket = "my-bucket-7863121991"
       acl = "public-read-write"
       tags = {
          Description = "s3 bucket"
       }

}

resource "aws_s3_object" "my-object" {
       content = "a.txt"
       key = "a.txt"
       acl = "public-read"
       bucket = aws_s3_bucket.my-bucket.id

}

resource "aws_s3_bucket_policy" "my-policy" {
       bucket = aws_s3_bucket.my-bucket.id
       policy = file("a.json")

}
