variable "region" {
    default = "eu-west-1"
    type = string
}

# Define a variable with three different values
variable "env" {
  type = set(string)
  default = ["dev", "proc","db"]
}

# Define a map of AMIs for different environments
variable "ami_map" {
  type = map(string)
  default = {
    dev     = "ami-08f9a9c699d2ab3f9"  #amazon
    proc    = "ami-0df368112825f8d8f"     #Ubuntu
    dbserver    = "ami-09de149defa704528"     #Redhat
  }
}


#provide the key path
variable "keypath" {
  default = "C:/Users/manpreetsingh.vedi/OneDrive - JLL/Documents/Terra-ansible-setup/Personal-Instance.pem"  #path
  type = string
}