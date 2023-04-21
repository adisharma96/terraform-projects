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
    availability_zone = "us-east-2a"

}

resource "aws_subnet" "private-subnet" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "15.6.4.0/24"
    availability_zone = "us-east-2b"

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
        ami = "ami-037b6a23bae46f652"
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
                          "sudo service nginx start",
               ]
        }     
        connection {
             type = "ssh"
             host = self.public_ip
             user = "ubuntu"
             private_key = file("id_rsa")
         }
}
