Introduction
-----
This is the docker project to setup tunnel via ssh to jump-station server. This can support multiple forward tunnel and socks proxy.

The Local UDP forward is supported if remote server has `socat` package installed.

Usage
-----
Use different option to connect remote ssh server:
- Input password in running
- Use password in environment
- Use password file
- Use ssh private key file

### Input Password
Input password in docker run
```shell
$ docker run -it -p 443:443 fengzhou/ssh-tunnel user@remoteserver 443:example.com:443
password: <input here>
```

### Use password in environment
For no-interaction situration, use password in environment variable:
```shell
$ docker run -it -p 443:443 -e SSH_PASSWORD=remotepassword \
> fengzhou/ssh-tunnel user@remoteserver 443:example.com:443
```

### Use password file
For no-interaction situration and security considataion, use password file:
```shell
$ docker run -it -p 443:443 -e SSH_PASSWORD_FILE=/password.txt -v $PWD/password.txt:/password.txt \
> fengzhou/ssh-tunnel user@remoteserver 443:example.com:443
```

### Use ssh private key file
For non-password situration,
```shell
$ docker run -it -p 443:443 -e SSH_KEY_FILE=/id_rsa -v ~/.ssh/id_rsa:/id_rsa \
> fengzhou/ssh-tunnel user@remoteserver 443:example.com:443
```

### Multiple forward tunnel
The multiple forward tunnel are suppored as following:
```shell
$ docker run -it -p 443:443 -p 80:80 -e SSH_PASSWORD=remotepassword \
> fengzhou/ssh-tunnel user@remoteserver 443:example.com:443 80:example.com:80
```

### UDP local forward tunnel
The UDP local forward tunnel is supported as following:
```shell
$ docker run -it -p 5353:53/udp -e SSH_PASSWORD=remotepassword \
> fengzhou/ssh-tunnel user@remoteserver 5353:example.com:53/udp
```
The remote server should have `socat` pre-installed to support UDP forward converting.

Only one UDP port forward supported. It can also include multiple TCP ports forward tunnel.

Make sure `-i` option (enable input) is enabled in docker run command (or `stdin_open: true` in docker-compose.yml)

### SSH provides SOCKS proxy Server
The socks proxy can supported as well
```shell
$ docker run -it -p 443:443 -p 1080:1080 -e SSH_PASSWORD=remotepassword -e SOCKS_PORT=1080 \
> fengzhou/ssh-tunnel user@remoteserver 443:example.com:443
```

### SSH Over SOCKS Proxy
Tunnel can over socks proxy server
```
$ docker run -it -p 1080:1080 -e SSH_PASSWORD=remotepassword -e SOCKS_PORT=1080 -e SSH_SOCKS_PROXY=socks.example.com:1080\
> fengzhou/ssh-tunnel user@remoteserver
```

