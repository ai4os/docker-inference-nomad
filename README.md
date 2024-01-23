<div align="center">
  <img src="https://ai4eosc.eu/wp-content/uploads/sites/10/2022/09/horizontal-transparent.png" alt="logo" width="500"/>
</div>

# Docker inference nomad
Implementation of a load balancing algorithm for Nomad Jobs through [Nginx](https://www.nginx.com/)


The goal of the project is to allow the user to deploy this system with a specific number of machines, and for it to only be live for a certain time.


For this purpose it has been necessary to modify the [original Nginx docker image](https://hub.docker.com/_/nginx) to add this timeout.The image already built with a timeout of 24 hours is available on [dockerhub](https://hub.docker.com/repository/docker/sftobias/autoexit-nginx/general). The dockerfile with which it was generated is included in this [repository](https://github.com/ai4os/docker-inference-nomad/blob/main/Dockerfile).
 <!-- TODO: move to ai4os Dockerhub account -->

The timeout is specified through the sleep command on the next line. Upon completion, a kill call is executed against the process with PID 0, thus ending the execution of the container.

  ```bash
  CMD /bin/bash -c "nginx -g 'daemon off;' & sleep 86400 && kill -9 0"
```

**Dislaimer**: None of the containers closed through timeout return Exit(0). Nginx container will exit with code ... and Deepaas containers will exit with code ...
 <!-- TODO: Complete disclaimer with correct exit codes -->

## Implementation example

Two nomad jobs are included that implement load balancing:

`load-balancer-single-group.hcl` defines all tasks within the same group. This causes all of them to be deployed within the same datacenter node.

`load-balancer-multi-group.hcl` defines two separate groups, one for the nginx task, and another for the deepaas task. 

This implementation allows nomad to allocate tasks to the machines it considers according to its scheduling policy. However, it is necessary to ensure that the machine where the nginx task is executed has connectivity with the machines where the endpoints are executed.

Currently, this is achieved by forcing nomad to execute the job within a specific datacenter.

#### Controlling the nummber of instances


In the case of `load-balancer-multi-group.hcl`, the number of endpoint instances to be generated can be controlled through the count parameter of the group where the task is defined, as follows:

```bash
group "usergroup" {
    count = 4 #Number of endpoints to allocate
```

For `load-balancer-single-group.hcl`, the deepaas task has to be defined explicitly as many times as instances are required.


#### Restart policy

As mentioned above, when the timeout arrives, the containers do not return with exit 0. For this reason, while working to find a better solution, nomad jobs that implement this system will need to change the number of restarts allowed to 0.

```bash
restart {
    attempts = 0
    mode     = "fail"
}
```


