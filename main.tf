terraform {
  required_version = ">= 0.10.3"
}


provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  region = "us-east-2"
  alias = "us-east-2"
}

###############
## us-east-1 ##
###############

# vpc 생성
resource "aws_vpc" "create_vpc" {
    cidr_block = "10.10.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    instance_tenancy = "default"

    tags {
        Name = "jaejin test"
    }
}

# 라우팅 테이블 생성
resource "aws_default_route_table" "create_vpc" {
    default_route_table_id = "${aws_vpc.create_vpc.default_route_table_id}"

    tags {
        Name = "default"
    }
}

# 서브넷 생성
resource "aws_subnet" "subnet_1" {
    vpc_id = "${aws_vpc.create_vpc.id}"
    cidr_block = "10.10.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    tags = {
        Name = "public-az-1"
    }
}

# availability zone
data "aws_availability_zones" "available" {}

# internet gateway 생성
resource "aws_internet_gateway" "igw_1" {
  vpc_id = "${aws_vpc.create_vpc.id}"
  tags {
    Name = "internet-gateway"
  }
}

# vpc끼리 통신하기 위해서 라우팅 테이블 수정
resource "aws_route" "internet_access_vpc" {
    route_table_id = "${aws_vpc.create_vpc.main_route_table_id}"
    destination_cidr_block = "${aws_vpc.create_vpc_2.cidr_block}"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.default.id}"
}

## 외부에서 ssh 접속하기 위해서 internet gateway 연결
resource "aws_route" "internet_access" {
    route_table_id = "${aws_vpc.create_vpc.main_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw_1.id}"
}

###############
## us-east-2 ##
###############

# vpc 생성
resource "aws_vpc" "create_vpc_2" {
    provider = "aws.us-east-2"
    cidr_block = "172.10.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    instance_tenancy = "default"

    tags {
        Name = "jaejin test222"
    }
}

# 라우팅 테이블 생성
resource "aws_default_route_table" "create_vpc_2" {
    provider = "aws.us-east-2"

    default_route_table_id = "${aws_vpc.create_vpc_2.default_route_table_id}"

    tags {
        Name = "default"
    }
}

# 서브넷 생성
resource "aws_subnet" "subnet_2" {
    provider = "aws.us-east-2"

    vpc_id = "${aws_vpc.create_vpc_2.id}"
    cidr_block = "172.10.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "${data.aws_availability_zones.available_2.names[0]}"
    tags = {
        Name = "public-az-2"
    }
}

# availability zone
data "aws_availability_zones" "available_2" {
    provider = "aws.us-east-2"
}



# internet gateway 생성
resource "aws_internet_gateway" "igw_2" {
  provider = "aws.us-east-2"
  vpc_id = "${aws_vpc.create_vpc_2.id}"
  tags {
    Name = "internet-gateway"
  }
}

# vpc끼리 통신하기 위해서 라우팅 테이블 수정
resource "aws_route" "internet_access_vpc_2" {
    provider = "aws.us-east-2"
    route_table_id = "${aws_vpc.create_vpc_2.main_route_table_id}"
    destination_cidr_block = "${aws_vpc.vpc_test.cidr_block}"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.default.id}"
}

## 외부에서 ssh 접속하기 위해서 internet gateway 연결
resource "aws_route" "internet_access_2" {
    provider = "aws.us-east-2"
    route_table_id = "${aws_vpc.create_vpc_2.main_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw_2.id}"
}


#################
## VPC Peering ##
#################
resource "aws_vpc_peering_connection" "default" {
  peer_owner_id = "871229912567"
  peer_vpc_id   = "${aws_vpc.create_vpc_2.id}"
  vpc_id        = "${aws_vpc.vpc_test.id}"
  peer_region   = "us-east-2"
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}
resource "aws_vpc_peering_connection_accepter" "default" {
  provider                  = "aws.us-east-2"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.default.id}"
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}
