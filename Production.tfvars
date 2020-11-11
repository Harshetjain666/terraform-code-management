/*---------------------------------Environment setup----------------------------------*/

    vpc-env-name                 = "Production"
    availability_zone-public     = "ap-south-1b"
    availability_zone-lb         = "ap-south-1a"
    availability_zone-private1   = "ap-south-1a"
    availability_zone-private2   = "ap-south-1b"
    availability_zone-testing    = "ap-south-1a"
    cidr_block-internet_gw       = "0.0.0.0/0"
    cidr_block-nat_gw            = "0.0.0.0/0"  
 
 /*---------------------------------Web Server setup----------------------------------*/ 
    ami                             = "ami-07e3dcfdcf2d55996"
    instance_type-server_instance   = "t3.xlarge"
    instance_type-testing_instance  = "t2.xlarge"
    
 /*---------------------------------Database setup----------------------------------*/   
    
    secret_id              = "database"
    identifier             = "database"
    allocated_storage      = 100
    storage_type           = "io1"
    engine                 = "mysql"
    engine_version         = 5.7
    instance_class         = "db.m5.xlarge"
    name                   = "data"
    availability_zone-db   = "ap-south-1a"
