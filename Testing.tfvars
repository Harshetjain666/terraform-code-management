  /*---------------------------------Environment setup----------------------------------*/

    vpc-testing-name             = "testing"
    availability_zone-public     = "ap-south-1b"
    availability_zone-lb         = "ap-south-1a"
    availability_zone-private1   = "ap-south-1a"
    availability_zone-private2   = "ap-south-1b"
    availability_zone-testing    = "ap-south-1a"
    cidr_block-internet_gw       = "0.0.0.0/0"
    cidr_block-nat_gw            = "0.0.0.0/0"  
 
 /*---------------------------------Web Server setup----------------------------------*/ 
    ami                             = "ami-07e3dcfdcf2d55996"
    instance_type-server_instance   = "t2.micro"
    instance_type-testing_instance  = "t2.micro"
    
 /*---------------------------------Database setup----------------------------------*/   
    
    secret_id              = "database"
    identifier             = "database"
    allocated_storage      = 20
    storage_type           = "gp2"
    engine                 = "mysql"
    engine_version         = 5.7
    instance_class         = "db.t2.micro"
    name                   = "db"
    availability_zone-db   = "ap-south-1a"





