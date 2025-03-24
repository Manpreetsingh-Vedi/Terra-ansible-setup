resource "aws_key_pair" "tg_intial_key" {
  key_name = "terra-ansible-server-setup"
  public_key = file(var.keypath) #defined in vars file
}

resource "aws_default_vpc" "ta_aws_default_vpc" {
  
}



resource "aws_security_group" "ta_aws_security_group" {
  name        = "ta-sg"
  description = "this will add a TF generated Security group"
  vpc_id      = aws_default_vpc.default.id # interpolation

  # inbound rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH open"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP open"
  }

  # outbound rules

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "all access open outbound"
  }

  tags = {
    Name = "ta-sg"
  }
}




# Create the master instance
resource "aws_instance" "master" {
  ami           = var.env[proc.value]  # Amazon Linux 2 AMI (adjust as needed)
  instance_type = "t2.micro"
  key_name      = aws_key_pair.tg_intial_key.key_name

  tags = {
    Name = "Master"
  }
  # Generate new SSH key on the master
  provisioner "remote-exec" {
    inline = [
      "ssh-keygen -t rsa -b 2048 -f ~/.ssh/master_key -N ''",
      "echo 'Master public key:' $(cat ~/.ssh/master_key.pub)"
    ]
  }
}



#instance configuration 
resource "aws_instance" "tg_servers" {
    for_each = var.env
    ami= var.ami_map[each.key]
    instance_type = t2.micro
    key_name = aws_security_group.ta_aws_security_group.key_name
    security_groups = [aws_security_group.ta_aws_security_group]

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }
  tags = {
    name = "${each.key}-server"
  }
}





# Now, let's update the null_resource to handle different OS types:
resource "null_resource" "update_auth_keys" {
  count = 3

  depends_on = [aws_instance.master, aws_instance.tg_servers]

  provisioner "local-exec" {
    command = <<-EOT
      MASTER_KEY=$(ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.master.public_ip} 'cat ~/.ssh/master_key.pub')
      
      SERVER_IP="${aws_instance.tg_servers[count.index].public_ip}"
      SERVER_OS="${element(["ubuntu", "redhat", "amazon"], count.index)}"
      
      case $SERVER_OS in
        ubuntu)
          USER="ubuntu"
          ;;
        redhat)
          USER="ec2-user"
          ;;
        amazon)
          USER="ec2-user"
          ;;
        *)
          echo "Unknown OS type"
          exit 1
          ;;
      esac
      
      ssh -i ~/.ssh/id_rsa $USER@$SERVER_IP "echo '$MASTER_KEY' >> ~/.ssh/authorized_keys"
    EOT
  }
}




