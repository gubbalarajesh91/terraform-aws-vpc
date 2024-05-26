# Custom AWS VPC Module

![alt text](images/vpc.jpg)

This module is developed for joindevops.com. We are creating follwing resources

* VPC
* Internet Gateway
* Internet and VPC attachemnet
* 2 Public Subnets
* 2 Private Subnets
* 2 Databse Subnets
* EIP
* NAT Gateway
* Publive Route table
* Private Route Table
* Database Route Table
* Route Table Associations
* Routes in all tables
* Peering if required
* Routes of Peering in requestor and acceptor
* Database subnet group

## Inputs
* Project_Name ( Required)
* Environment (Optional): Default is dev


## Output
* vpc_id: VPC ID
* public_subnet_ids: A list of 2 public subnet IDS created.
* private_subnet_ids: A list of 2 private subnet IDS Created.
* Database_subnet_ids: A list of 2 Database subnet IDS Created.
* Database_subnet_group: database subnet group ID created.
* igw_id: internet gateway created.