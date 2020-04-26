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

if [ -z "$NO_FORWARD_ONLY" ]; then
  _CMD="$_CMD ssh -NT"
else
  _CMD="$_CMD ssh -T"
fi

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

while [ "$1" != "" ]; do
  
  if [ -z "$NO_LOCAL_FORWARD" -a `echo $1 | grep -o ":" | wc -l` -eq "2" ]; then
    _CMD="$_CMD -L"
  fi

  _CMD="$_CMD $1"

  shift
done

## Enable ssh over socks5 proxy if Env SSH_SOCKS_PROXY set
if [ -n "$SSH_SOCKS_PROXY" ]; then
  # -o ProxyCommand='/usr/bin/nc -x socks.example.com:1080 %h %p' has issue in _CMD directly
  # Use option in /etc/ssh_config for workaround (same as Dockerfile did)
  echo "ProxyCommand /usr/bin/nc -x ${SSH_SOCKS_PROXY} %h %p" >> /etc/ssh/ssh_config
  echo "Enable SSH over SOCKS Proxy ${SSH_SOCKS_PROXY}"
fi

echo $_CMD
exec $_CMD
