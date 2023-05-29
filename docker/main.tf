provider "docker" {
  registry_auth {
    address  = "docker-registry.io"
    username = "$DOCKER_REGISTRY_USER"
    password = "$DOCKER_REGISTRY_PASS"
  }
}
resource "docker_image" "nginx" {
    name = "adisharma96/weather-app:jenkins"

}

resource "docker_container" "web_server" {
    image = docker_image.nginx.image_id
    name = "webserver"
    ports {
      internal = "3000"
      external = "80"
    }

    ports {
       internal = "8080"
       external = "5000"
    }
}
