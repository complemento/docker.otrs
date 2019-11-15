FROM ligero/otrs:rel-6_0

RUN sudo apt-get update \
    && sudo apt-get install -y \
       ssh \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* 

CMD [ "/usr/sbin/sshd -D" ]
