# TFE customer worker with init script

## Build the image
```
mkaesz@arch ~/w/tfe-custom-ubuntu-worker> docker build -t ubuntu:worker . 2>&1 | tee build.log
Sending build context to Docker daemon  4.096kB
Step 1/3 : FROM ubuntu:xenial
 ---> 96da9143fb18
Step 2/3 : RUN apt-get update && apt-get install -y --no-install-recommends     sudo unzip daemontools git-core awscli ssh wget curl psmisc iproute2 openssh-client redis-tools netcat-openbsd ca-certificates
 ---> Using cache
 ---> dbb30235de11
Step 3/3 : ADD init.sh /usr/local/bin/init_custom_worker.sh
 ---> 750c4f210df8
Successfully built 750c4f210df8
Successfully tagged ubuntu:worker

mkaesz@arch ~/w/tfe-custom-ubuntu-worker> docker images | grep worker
ubuntu                                              worker                              750c4f210df8        9 seconds ago       346MB
```

## Execute the image locally
```
mkaesz@arch ~/w/tfe-custom-ubuntu-worker [127]> docker run -it ubuntu:worker /bin/sh
# /usr/local/bin/init_custom_worker.sh
custom init before terraform init

HOSTNAME=d5514f246dcc
HOME=/root
TERM=xterm
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PWD=/
# 

mkaesz@arch ~/w/tfe-custom-ubuntu-worker> docker run -it ubuntu:worker /bin/sh
# terraform version
/bin/sh: 1: terraform: not found
# 
```

## Push the image to a container registry. In my case Docker Hub. TFE must be able to access it.
```
mkaesz@arch ~/w/tfe-custom-ubuntu-worker> docker tag 750c4f210df8 mskaesz/tfe-ubuntu-worker-with-init:v1.0.0

mkaesz@arch ~/w/tfe-custom-ubuntu-worker> docker images | grep worker
mskaesz/tfe-ubuntu-worker-with-init                 v1.0.0                              750c4f210df8        10 minutes ago      346MB
ubuntu                                              worker                              750c4f210df8        10 minutes ago      346MB

mkaesz@arch ~/w/tfe-custom-ubuntu-worker> docker push mskaesz/tfe-ubuntu-worker-with-init:v1.0.0
The push refers to repository [docker.io/mskaesz/tfe-ubuntu-worker-with-init]
cf7211b3ccd0: Pushed 
fed4d7df5e93: Pushed 
fa1693d66d0b: Mounted from pcfseceng/credhub 
293b479c17a5: Mounted from pcfseceng/credhub 
bd95983a8d99: Mounted from pcfseceng/credhub 
96eda0f553ba: Mounted from pcfseceng/credhub 
v1.0.0: digest: sha256:594034373f6705f6d6e1d6681e7f81f1470bb52017003b2bba3f0b0250d28ab1 size: 1569
```

## Configure TFE to use it
Follow this documentation: https://www.terraform.io/docs/enterprise/install/installer.html#alternative-terraform-worker-image
and restart TFE via replicated UI.

You can add the TFE including the tag: docker.io/mskaesz/tfe-ubuntu-worker-with-init:v1.0.1
or
without: docker.io/mskaesz/tfe-ubuntu-worker-with-init

TFE will then look for the image with the tag "latest".

## Execute a run.
Start a run.

On the TFE host you will see the image got downloaded:

```
[root@tfe terraform]# docker images| grep tfe-ubuntu-worker
docker.io/mskaesz/tfe-ubuntu-worker-with-init         latest                  750c4f210df8        18 minutes ago      346 MB
```

## Check if the script got executed

Log in to the container:
```
docker exec -it cd703c5b8ae3 /bin/bash
```

Check for files in tmp:
```
root@cd703c5b8ae3:/# cat /tmp/init_echo.log 
custom init before terraform init

root@cd703c5b8ae3:/# cat /tmp/init_env.log 
HOSTNAME=cd703c5b8ae3
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PWD=/
SHLVL=1
HOME=/root
_=/usr/bin/env

```

Terraform plan and apply run in their own shell instances. Exporting variables in the init script won't be seen by terraform. Variables set on the workspace will also not be seen by the init script.
