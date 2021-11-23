FROM ubuntu:20.04

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y openssh-client openssh-server && \
    sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication\ no/' /etc/ssh/sshd_config && \
    mkdir -p /run/sshd

COPY setup_privkey.sh /usr/local/bin/
COPY teardown_privkey.sh /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# -D in CMD below prevents sshd from becoming a daemon. -e is to log everything to stderr.
CMD ["/usr/sbin/sshd", "-D", "-d", "-e"]
