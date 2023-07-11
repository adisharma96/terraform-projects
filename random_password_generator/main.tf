resource "random_password" "password-generator" {
    length = var.length < 8 ? 8 : var.length
}

output password {
    value = nonsensitive(random_password.password-generator.result)
}

 
