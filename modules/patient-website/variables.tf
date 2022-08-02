variable patient_web_domain_name {
    type = string
}
variable environment {
    type = string
}
variable certificate_arn {
    type = string
    default = "arn:aws:acm:us-east-1:182560659941:certificate/20090156-9f7e-4d5f-886a-83a66564836b"
}
variable patient_web_alias {
    type = string
}
