FROM alpine:latest

LABEL maintainer "Feng Zhou <feng.zh@gmail.com>"

# Refer to https://github.com/iadknet/docker-ssh-client-light

RUN apk update && apk add --no-cach openssh-client sshpass netcat-openbsd && \
    echo -e 'Host *\nUseRoaming no\nServerAliveInterval 60\nServerAliveCountMax 2\nStrictHostKeyChecking no\nUserKnownHostsFile /dev/null\nExitOnForwardFailure yes\nGatewayPorts true\nForwardAgent yes\nAddKeysToAgent yes' >> /etc/ssh/ssh_config

ADD entrypoint.sh /

# Use Environment SSH_PASSWORD SSH_PASSWORD_FILE SSH_KEY_FILE SOCKS_PORT SSH_SOCKS_PROXY SSH_USER NO_LOCAL_FORWARD NO_AGENT

ENTRYPOINT ["/entrypoint.sh"]
