FROM ligero/otrs:rel-6_0

RUN sudo apt-get update \
    && sudo apt-get install -y \
       ssh \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/sshd \
    && rm -f /etc/ssh/ssh_host_*key*

COPY files/sshd_config /etc/ssh/sshd_config
COPY files/create-sftp-user /usr/local/bin/
COPY files/entrypoint /

EXPOSE 22

ENTRYPOINT ["/entrypoint"]
