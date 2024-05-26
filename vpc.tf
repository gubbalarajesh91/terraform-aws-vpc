resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = var.enable_dns_hostnames


  tags = merge(
    var.common_tags,
    var.vpc_tags,
    {
      Name = local.resource_name
    }
    )
  }


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    var.igw_tags,
    {
      Name = local.resource_name
    }
    )
  
 }

#### Public Subnet ######
 resource "aws_subnet" "main" { #first name is public[0], second name is public[1]
  count = length(var.public_subnet_cidrs)
  availability_zone = local.az_names[count.index]
  map_public_ip_on_launch = true
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]

  tags = merge(
    var.common_tags,
    var.public_subnet_cidr_tags,
    {
      Name = "${local.resource_name}-public-${local.az_names[count.index]}"
    }
    )
}


#### Private Subnet ######
 resource "aws_subnet" "private" { #first name is public[0], second name is public[1]
  count = length(var.private_subnet_cidrs)
  availability_zone = local.az_names[count.index]
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]

  tags = merge(
    var.common_tags,
    var.private_subnet_cidr_tags,
    {
      Name = "${local.resource_name}-private-${local.az_names[count.index]}"
    }
    )
}

#### Database Subnet ######
 resource "aws_subnet" "Database" { #first name is public[0], second name is public[1]
  count = length(var.Database_subnet_cidrs)
  availability_zone = local.az_names[count.index]
  vpc_id     = aws_vpc.main.id
  cidr_block = var.Database_subnet_cidrs[count.index]

  tags = merge(
    var.common_tags,
    var.Database_subnet_cidr_tags,
    {
      Name = "${local.resource_name}-Database-${local.az_names[count.index]}"
    }
    )
}

resource "aws_db_subnet_group" "default" {
  name = "${local.resource_name}"
  subnet_ids = aws_subnet.Database[*].id

  tags = merge(
    var.common_tags,
    var.Database_subnet_group_tags,
    {
      Name = "${local.resource_name}"
    }
    )
}

####### Elastic IP ######
resource "aws_eip" "nat" {
  domain = "vpc"
  
}


resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.main[0].id

tags = merge(
    var.common_tags,
    var.nat_gateway_tags,
    {
      Name = "${local.resource_name}" #Expense-Dev
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw] #this is explicit dependency
}


#### Public Route table #############

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # route {
  #   cidr_block = var.vpc_cidr
  #   gateway_id = aws_internet_gateway.gw.id
  # }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  # }

  tags = merge(
    var.common_tags,
    var.public_route_table_tags,
    {
      Name = "${local.resource_name}-public" #Expense-Dev-public
    }
  )
}


#### Private Route table #############

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # route {
  #   cidr_block = var.vpc_cidr
  #   gateway_id = aws_internet_gateway.gw.id
  # }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  # }

  tags = merge(
    var.common_tags,
    var.private_route_table_tags,
    {
      Name = "${local.resource_name}-private" #Expense-Dev-private
    }
  )
}


#### Private Route table #############

resource "aws_route_table" "Database" {
  vpc_id = aws_vpc.main.id

  # route {
  #   cidr_block = var.vpc_cidr
  #   gateway_id = aws_internet_gateway.gw.id
  # }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  # }

  tags = merge(
    var.common_tags,
    var.Database_route_table_tags,
    {
      Name = "${local.resource_name}-Database" #Expense-Dev-Database
    }
  )
}

### Create Route ####
resource "aws_route" "public_route" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

resource "aws_route" "private_route_nat" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route" "Database_route_nat" {
  route_table_id            = aws_route_table.Database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

##### Route table Assosiate with Subnets ####
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.main[*].id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "Database" {
  count = length(var.Database_subnet_cidrs)
  subnet_id      = element(aws_subnet.Database[*].id, count.index)
  route_table_id = aws_route_table.Database.id
}

######### Create Peering connections ###########