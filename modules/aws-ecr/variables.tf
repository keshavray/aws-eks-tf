variable "repo_name" {

    type = string
}

variable "tag_mutability" {
    type = string

}

variable "image_scanning_config" {

     type = bool 
     default = true 

}