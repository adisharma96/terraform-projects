resource "aws_vpc" "my-vpc" {
    cidr_block = "15.6.0.0/16"
    enable_dns_support =  true
    enable_dns_hostnames = true

}

resource "aws_internet_gateway" "my-igw" {
    vpc_id = aws_vpc.my-vpc.id
    tags = {
       Description = "My internet Gateway"
    }

}

resource "aws_subnet" "public-subnet" {
    vpc_id = aws_vpc.my-vpc.id 
    cidr_block = "15.6.5.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-west-2a"

}

resource "aws_subnet" "private-subnet" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "15.6.4.0/24"
    availability_zone = "us-west-2b"

}

resource "aws_default_route_table" "vpc-route" {
    default_route_table_id = aws_vpc.my-vpc.default_route_table_id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.my-igw.id
    }

}

resource "aws_eip" "my-eip" {
    instance = aws_instance.web-server.id
    vpc = true

}

resource "aws_default_network_acl" "my-acl" {
     default_network_acl_id = aws_vpc.my-vpc.default_network_acl_id
     ingress {
         protocol = "all"
         rule_no = 100
         action = "allow"
         cidr_block = "0.0.0.0/0"
         from_port = 0
         to_port = 0
     }

     egress {
         protocol = "all"
         rule_no = 100
         action = "allow"
         cidr_block = "0.0.0.0/0"
         from_port = 0
         to_port = 0
     }
     tags = {
        Name = "my-acl"
     }
}

resource "aws_security_group" "my-group1" {
      name = "all-access"
      vpc_id = aws_vpc.my-vpc.id
      tags = {
         Description = "Allow all traffic"
      }
      ingress {
         from_port = 0
         to_port = 0
         protocol = "all"
         cidr_blocks = ["0.0.0.0/0"]
      }

      egress {
          from_port = 0
          to_port = 0
          protocol = "all"
          cidr_blocks = ["0.0.0.0/0"]
      }
}

resource "aws_security_group_rule" "ping2" {
        type = "ingress"
        from_port = 8
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "icmp"
        security_group_id = aws_security_group.my-group1.id
}

resource "aws_key_pair" "web" {
       public_key = file("a.pub")

}

resource "aws_instance" "web-server" {
        ami = "ami-06932c41880e03d3b"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        subnet_id = aws_subnet.public-subnet.id
        tags = {
           Name = "Nginx"
        }
        key_name = aws_key_pair.web.id
        vpc_security_group_ids = [ aws_security_group.my-group1.id ]
        depends_on = [ 
                aws_security_group.my-group1 
        ]
 
        provisioner "remote-exec" {
               inline = [ "sudo apt-get update",
                          "sudo apt-get install nginx -y",
                          "sudo service nginx start"
               ]
        }     
        connection {
             type = "ssh"
             host = self.public_ip
             user = "ubuntu"
             private_key = file("id_rsa")
         }
}

resource "aws_iam_role" "ec2_s3_access_role" {
  name               = "ec2-s3"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "policy" {
  name        = "ec2_S3policy"
  description = "Access to s3 policy from ec2"
  policy      = <<EOF
{
 "Version": "2012-10-17",
   "Statement": [
       {
           "Effect": "Allow",
           "Action": "s3:*",
           "Resource": "*"
       }
    ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "ec2-attach" {
  role     = aws_iam_role.ec2_s3_access_role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.my-vpc.id
  service_name      = "com.amazonaws.us-west-2.s3"
}

resource "aws_vpc_endpoint_route_table_association" "Private_route_table_association" {
  route_table_id  = aws_default_route_table.vpc-route.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

