variable "instance_type" {
  description = "instance_type"
  type = string
  default = "t2.micro"  
}
variable "http_port" {
  description = "server_port"
  type = number
  default = 80
}
variable "https_port" {
  description = "server_port"
  type = number
  default = 8080
}
variable "mysql_port" {
  description = "server_port"
  type = number
  default = 8080
}
variable "ssh_port" {
  description = "ssh_port"
  type = number
  default = 22
}
