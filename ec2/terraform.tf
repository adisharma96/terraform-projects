terraform {  
     backend "s3" {
         bucket = "test-7863121991"
         region = "us-east-2"
         key = "ec-state"
     }

}
