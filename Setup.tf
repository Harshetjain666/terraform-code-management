
provider "aws" {
  region    = "ap-south-1"
  profile   = "default"
}



/* -----------------------------------Environment setup------------------------------------*/
variable "vpc-env-name" {}
variable "availability_zone-public" {}
variable "availability_zone-lb" {}
variable "availability_zone-private1" {}
variable "availability_zone-private2" {}
variable "availability_zone-testing" {}
variable "cidr_block-internet_gw" {}
variable "cidr_block-nat_gw" {}



resource "aws_vpc" "main" {
  cidr_block           = "192.168.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "Website-environment-${var.vpc-env-name}"
  }
}

resource "aws_subnet" "public" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = "192.168.99.0/24"
  availability_zone        = "${var.availability_zone-public}"
  map_public_ip_on_launch  = true
  depends_on = [ aws_vpc.main ]
  
  tags = {
    Name   = "main-${var.vpc-env-name}"
    state  = "public"
  }
}

resource "aws_subnet" "lb" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = "192.168.95.0/24"
  availability_zone        = "${var.availability_zone-lb}"
  map_public_ip_on_launch  = true
  depends_on = [ aws_vpc.main ]
  
  tags = {
    Name   = "lb-${var.vpc-env-name}"
    state  = "public"
  }
}


resource "aws_subnet" "private1" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = "192.168.98.0/24"
  availability_zone        = "${var.availability_zone-private1}"
  depends_on = [ aws_vpc.main ]
  
  tags = {
    Name   = "datanet-${var.vpc-env-name}"
    state  = "private"
  }
}

resource "aws_subnet" "private2" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = "192.168.96.0/24"
  availability_zone        = "${var.availability_zone-private2}"
  depends_on = [ aws_vpc.main ]
  
  tags = {
    Name   = "datanet-${var.vpc-env-name}"
    state  = "private"
  }
}

resource "aws_subnet" "testing" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = "192.168.97.0/24"
  availability_zone        = "${var.availability_zone-testing}"
  depends_on = [ aws_vpc.main ]
  
  tags = {
    Name   = "testing-${var.vpc-env-name}"
    state  = "private"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  depends_on = [ aws_vpc.main ]

  tags = {
    Name = "main-${var.vpc-env-name}"
  }
}

resource "aws_eip" "nat" {
  vpc              = true
  public_ipv4_pool = "amazon"
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.testing.id

  tags = {
    Name = "Nat_Gateway-${var.vpc-env-name}"
  }
}


resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "${var.cidr_block-internet_gw}"
    gateway_id = aws_internet_gateway.gw.id
  }
  depends_on = [ aws_vpc.main ]
  tags  = {
      Name = "main-${var.vpc-env-name}"
      state = "public"
  }
  
}

resource "aws_route_table" "local" {
  vpc_id = aws_vpc.main.id

  depends_on = [ aws_vpc.main ]
  tags  = {
      Name = "local-${var.vpc-env-name}"
      state = "private"
  }
  
}

resource "aws_route_table" "testing" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "${var.cidr_block-nat_gw}"
    gateway_id = aws_nat_gateway.gw.id
  }
  depends_on = [ aws_vpc.main ]
  tags  = {
      Name = "main-${var.vpc-env-name}"
      state = "public"
  }
  
}

resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.main.id
  depends_on = [ aws_route_table.main ]
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.main.id
  depends_on = [ aws_route_table.main ,
                 aws_subnet.public
     ]
}

resource "aws_route_table_association" "lb" {
  subnet_id      = aws_subnet.lb.id
  route_table_id = aws_route_table.main.id
  depends_on = [ aws_route_table.main ,
                 aws_subnet.lb
     ]
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.local.id
  depends_on = [ aws_route_table.local ,
                 aws_subnet.private1
     ]
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.local.id
  depends_on = [ aws_route_table.local ,
                 aws_subnet.private2
     ]
}

resource "aws_route_table_association" "testing" {
  subnet_id      = aws_subnet.testing.id
  route_table_id = aws_route_table.testing.id
  depends_on = [ aws_route_table.testing ,
                 aws_subnet.testing
     ]
}

/*-----------------------------------Web-Server setup------------------------------------*/

variable "ami" {}
variable "instance_type-server_instance" {}
variable "instance_type-testing_instance" {}

resource "aws_security_group" "lb" {
  name        = "balancer-${var.vpc-env-name}"
  description = "Allow http inbound traffic only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb-${var.vpc-env-name}"
  }
}

resource "aws_security_group" "http" {
  name        = "Server-${var.vpc-env-name}"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description        = "Traffic"
    from_port          = 80
    to_port            = 80
    protocol           = "tcp"
    security_groups    = [aws_security_group.lb.id]
  }

   ingress {
    description      = "Traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [aws_security_group.testing.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "http_server-${var.vpc-env-name}"
  }

   depends_on = [aws_security_group.testing, aws_security_group.lb]
}

resource "aws_security_group" "testing" {
  name        = "testing-${var.vpc-env-name}"
  description = "Allow only outbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "testing_server-${var.vpc-env-name}"
  }
}

resource "aws_security_group" "data" {
  name        = "data-${var.vpc-env-name}"
  description = "Allow mysql inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "Traffic"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.http.id, aws_security_group.testing.id]
  }

  tags = {
    Name = "data_server"
  }
   depends_on = [aws_security_group.testing, aws_security_group.http ]
}

resource "aws_instance" "Server1" {
  ami                      = "${var.ami}"
  instance_type            = "${var.instance_type-server_instance}"
  vpc_security_group_ids   = [aws_security_group.http.id]
  subnet_id                = aws_subnet.public.id 
   tags = {
    Name = "Server1-${var.vpc-env-name}"
  }
  depends_on = [aws_subnet.public, aws_security_group.http]
}

resource "aws_instance" "Server2" {
  ami                      = "${var.ami}"
  instance_type            = "${var.instance_type-server_instance}"
  vpc_security_group_ids   = [aws_security_group.http.id]
  subnet_id                = aws_subnet.lb.id
   tags = {
    Name = "Server2-${var.vpc-env-name}"
  }
  depends_on = [aws_subnet.lb, aws_security_group.http]
}

resource "aws_instance" "testing" {
  ami                      = "${var.ami}"
  instance_type            = "${var.instance_type-testing_instance}"
  vpc_security_group_ids   = [aws_security_group.testing.id]
  subnet_id                = aws_subnet.testing.id
   tags = {
    Name = "testing-${var.vpc-env-name}"
  }
  depends_on = [aws_subnet.testing, aws_security_group.testing]
}

resource "aws_elb" "balancer" {
  name               = "Server-elb-${var.vpc-env-name}"
  subnets            = [aws_subnet.public.id, aws_subnet.lb.id]
  security_groups    = [aws_security_group.lb.id]
  
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

   health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5 
    target              = "HTTP:80/"
    interval            = 30
  }
 
  instances                   = [aws_instance.Server1.id, aws_instance.Server2.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "load-balancer-${var.vpc-env-name}"
  }
  depends_on = [aws_instance.Server1, aws_instance.Server2]
}

output "Server_ipaddr"{ 
 value = aws_elb.balancer.dns_name
 depends_on = [aws.elb.balancer]
}

/*-----------------------------------Database setup------------------------------------*/

variable "secret_id" {}
variable "identifier" {}
variable "allocated_storage" {}
variable "storage_type" {}
variable "engine" {}
variable "engine_version" {}
variable "instance_class" {}
variable "name" {}
variable "availability_zone-db" {}


resource "aws_db_subnet_group" "Groups" {
  name       = "db groups"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id ]

  tags = {
    Name = "DB subnet group"  
  }
  depends_on = [ aws_subnet.private1, aws_subnet.private2]
}

data "aws_secretsmanager_secret_version" "credentials" {
  secret_id     = "${var.secret_id}"
}
 
locals {
  cred = jsondecode(
    data.aws_secretsmanager_secret_version.credentials.secret_string
  )
}

resource "aws_db_instance" "db" {
  identifier             = "${var.identifier}"
  allocated_storage      = "${var.allocated_storage}"
  storage_type           = "${var.storage_type}"
  engine                 = "${var.engine}"
  engine_version         = "${var.engine_version}"
  instance_class         = "${var.instance_class}"
  name                   = "${var.name}"
  publicly_accessible    = false
  availability_zone      = "${var.availability_zone-db}"
  db_subnet_group_name   = aws_db_subnet_group.Groups.name
  vpc_security_group_ids = [aws_security_group.data.id]
  username               = local.cred.username
  password               = local.cred.password


 depends_on = [ aws_db_subnet_group.Groups, aws_security_group.data ]

}

output "data_ipaddr"{
  value = aws_db_instance.db.endpoint
  depends_on  = [aws_db_instance.db]
}