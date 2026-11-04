locals {
  name     = "dynamic-demo"
  region   = "eu-west-1"
  vpc_cidr = "10.0.0.0/16"
  azs      = ["eu-west-1a", "eu-west-1b"]

  # One object per ingress rule. Add or remove entries and the dynamic block follows.
  ingress_rules = [
    { description = "HTTP", port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { description = "HTTPS", port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    # 203.0.113.0/24 is a documentation range: swap in your own office or home CIDR.
    { description = "SSH from the office", port = 22, protocol = "tcp", cidr_blocks = ["203.0.113.0/24"] },
  ]

  tags = {
    Project   = local.name
    ManagedBy = "terraform"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${local.name}-vpc" }
}

# The way out to the internet: the gateway plus the default route below.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${local.name}-igw" }
}

# One public subnet per AZ. cidrsubnet(/16, 8, n) carves out /24 number n.
resource "aws_subnet" "public" {
  # local.azs is a tuple (a list literal): ["eu-west-1a", "eu-west-1b"].
  # `az => i` assigns each AZ a value i, its position in that tuple (0, 1, ...), and the { } makes an object:
  #   { "eu-west-1a" = 0, "eu-west-1b" = 1 }  ->  each.key is the AZ, each.value is i
  for_each = { for i, az in local.azs : az => i }

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(local.vpc_cidr, 8, each.value)
  map_public_ip_on_launch = true

  tags = { Name = "${local.name}-public-${each.key}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Anything not destined for the VPC goes to the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${local.name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name        = "${local.name}-web"
  description = "Web access, rules generated from local.ingress_rules"
  vpc_id      = aws_vpc.main.id

  # One ingress block per entry in local.ingress_rules.
  # The iterator is named after the block, so read the fields as ingress.value.<field>.
  dynamic "ingress" {
    for_each = local.ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  # All outbound traffic allowed, so instances can reach the internet
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-web-sg" }
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = { for az, s in aws_subnet.public : az => s.id }
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}

output "internet_route" {
  value       = "0.0.0.0/0 -> ${aws_internet_gateway.main.id}"
  description = "The default route that sends outbound traffic to the internet"
}

output "security_group_id" {
  value = aws_security_group.web.id
}

output "open_ports" {
  value       = [for r in local.ingress_rules : "${r.port}/${r.protocol} from ${join(", ", r.cidr_blocks)} (${r.description})"]
  description = "Human-readable view of the ingress rules the dynamic block creates"
}
