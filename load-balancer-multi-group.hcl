job "demo-saul-load-balancer" {
  namespace     = "default"
  type          = "batch"
  region        = "global"
  id            = "demo-saul-load-balancer"
  priority      = "50"
  datacenters   =  ["ifca-ai4eosc"] #One and just one datacenter has to be specified
  
  group "usergroup" {

    count = 4 #Number of endpoints to allocate

    reschedule {
      attempts  = 0
      unlimited = false
    }

    network {

      port "api" {
        to = 5000  # -1 will assign random port
      }
    }

    service {
      name = "demo-back"
      port = "api"
    }

    ephemeral_disk {
      size = 500
    }

    task "usertask" {

      driver = "docker"

      config {
        image    = "deephdc/deep-oc-image-classification-tf:latest"
        command  = "timeout"
        args    = ["--preserve-status", "24h", "deep-start", "--deepaas"]
        ports    = ["api"]
        shm_size = 1000000000
      }

      resources {
        cores  = 4
        memory = 4000
      }

      restart {
        attempts = 0
        mode     = "fail"
      }

    }

  }

  group "nginx" {
    count = 1

    reschedule {
      attempts  = 0
      unlimited = false
    }

    network {
      port "http" {
        static = 8080
      }
    }

    service {
      name = "demo-saul-load-balancer"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.demo-saul-load-balancer.tls=true",
        "traefik.http.routers.demo-saul-load-balancer.rule=Host(`api-demo-saul-load-balancer.${meta.domain}-deployments.cloud.ai4eosc.eu`, `www.api-demo-saul-load-balancer.${meta.domain}-deployments.cloud.ai4eosc.eu`)",
      ]
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "sftobias/autoexit-nginx:latest"
        ports = ["http"]
        volumes = [
          "local:/etc/nginx/conf.d",
        ]
      }

      template {
        data = <<EOF
          upstream backend {
          {{ range service "demo-back" }}
            server {{ .Address }}:{{ .Port }};
          {{ else }}server 127.0.0.1:65535; # force a 502
          {{ end }}
          }

          server {
            listen 8080;
            location / {
                proxy_pass http://backend;
            }
          }
          EOF

        destination   = "local/load-balancer.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      resources { //TODO adjust resources
        cores  = 4
        memory = 4000
      }

      restart {
        attempts = 1
        mode     = "fail"
      }

    }
  }
}