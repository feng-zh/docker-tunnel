#!/bin/sh

if [ "$1" == "" ]; then
  exec sh
  exit
fi

_CMD=

if [ -n "$SSH_PASSWORD" ]; then
  export SSHPASS=$SSH_PASSWORD
  _CMD="sshpass -e"
fi

if [ -n "$SSH_PASSWORD_FILE" ]; then
  if [ -e "$SSH_PASSWORD_FILE" ]; then
    _CMD="sshpass -f $SSH_PASSWORD_FILE"
  else
    echo "No ssh password file '$SSH_PASSWORD_FILE' found" 1>&2
    exit 1
  fi
fi

_CMD="$_CMD ssh -T"

if [ -n "$SSH_KEY_FILE" ]; then
  if [ -e "$SSH_KEY_FILE" ]; then
    # Fix permission
    cp $SSH_KEY_FILE /tmp/.ssh_key
    chmod 400 /tmp/.ssh_key
    _CMD="$_CMD -i /tmp/.ssh_key"
    if [ -z "$NO_AGENT" ]; then
      _CMD="ssh-agent $_CMD"
    fi
  else
    echo "No ssh key file '$SSH_KEY_FILE' found" 1>&2
    exit 1
  fi
fi

if [ -n "$SSH_USER" ]; then
  _CMD="$_CMD -l $SSH_USER"
fi

if [ -n "$SOCKS_PORT" ]; then
  _CMD="$_CMD -D $SOCKS_PORT"
fi

_UDP_FORWARD_LOCAL=
_LAST_ARG=
_CMD_ARGS=

echo "Include /etc/ssh/ssh_config" > /tmp/ssh_config

while [ "$1" != "" ]; do
  _ARG=$1
  
  if [ -z "$NO_LOCAL_FORWARD" -a `echo $_ARG | grep -o ":" | wc -l` -eq "2" ]; then
    if [ -n "`echo $_ARG | grep -o -i "/udp$"`" ]; then
      if [ -n "$_UDP_FORWARD_LOCAL" ]; then
        echo "Only one UDP forward supported" 1>&2
        exit 1
      fi
      _UDP_FORWARD_LOCAL=`echo $_ARG | grep -o "^[0-9]*:" | tr -d :`
      _UDP_FORWARD_REMOTE=`echo $_ARG | sed 's/^[0-9]*://' | sed 's#/udp$##i'`
      _TUNNEL_SOCK_LOCAL=`mktemp -u -p ${XDG_RUNTIME_DIR:-/tmp} .tunnel-XXXXXXXXXX`.sock
      _TUNNEL_SOCK_REMOTE=`mktemp -u -p /tmp .tunnel-XXXXXXXXXX`.sock
      # Use option in /etc/ssh_config for workaround (same as Dockerfile did)
      echo "LocalCommand socat UDP-LISTEN:$_UDP_FORWARD_LOCAL,reuseaddr,fork UNIX-CONNECT:$_TUNNEL_SOCK_LOCAL &" >> /tmp/ssh_config
      echo "PermitLocalCommand yes" >> /tmp/ssh_config
      _ARG=$_TUNNEL_SOCK_LOCAL:$_TUNNEL_SOCK_REMOTE
      _LAST_ARG="socat UNIX-LISTEN:$_TUNNEL_SOCK_REMOTE,fork udp:$_UDP_FORWARD_REMOTE,reuseaddr & cat; kill -TERM \$!"
      NO_FORWARD_ONLY=true
    fi
    _CMD="$_CMD -L $_ARG"
    _ARG=
  fi

  _CMD_ARGS="$_CMD_ARGS $_ARG"

  shift
done

if [ -z "$NO_FORWARD_ONLY" ]; then
  _CMD="$_CMD -N"
fi

if [ -n "$_LAST_ARG" ]; then
  _CMD_ARGS="$_CMD_ARGS $_LAST_ARG"
fi

## Enable ssh over socks5 proxy if Env SSH_SOCKS_PROXY set
if [ -n "$SSH_SOCKS_PROXY" ]; then
  # -o ProxyCommand='socat - SOCKS:socks.example.com:%h:%p,socksport=1080' has issue in _CMD directly
  # Use option in /etc/ssh_config for workaround (same as Dockerfile did)
  _SOCKS_HOST=`echo ${SSH_SOCKS_PROXY} | grep -o "^[^:]*"`
  _SOCKS_PORT=`echo ${SSH_SOCKS_PROXY} | grep -o "[^:]*$"`
  echo "ProxyCommand socat - SOCKS:$_SOCKS_HOST:%h:%p,socksport=$_SOCKS_PORT" >> /tmp/ssh_config
  echo "Enable SSH over SOCKS Proxy ${SSH_SOCKS_PROXY}"
fi

_CMD="$_CMD -F /tmp/ssh_config $_CMD_ARGS"

echo $_CMD
exec $_CMD
