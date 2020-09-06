# This Dockerfile builds the image used for the worker containers.
FROM ubuntu:xenial

# Install software used by Terraform Enterprise.
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo unzip vim daemontools git-core awscli ssh wget curl psmisc iproute2 openssh-client redis-tools netcat-openbsd ca-certificates

# Include all necessary CA certificates.
ADD tfe.msk.pub.crt /usr/local/share/ca-certificates/

# Update the CA certificates bundle to include newly added CA certificates.
RUN update-ca-certificates

# Add a custom bash script. Location cannot be changed. Script must be executable.
ADD init.sh /usr/local/bin/init_custom_worker.sh

