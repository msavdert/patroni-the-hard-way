FROM rockylinux:9

LABEL maintainer="Melih Savdert"

ENV container docker
# see https://hub.docker.com/_/rockylinux
# RockyLinux:9 missing /usr/sbin/init -> ../lib/systemd/systemd
#  see https://github.com/rocky-linux/sig-cloud-instance-images/issues/39

RUN dnf -y update
RUN [ ! -f /usr/sbin/init ] && dnf -y install systemd sudo openssh-clients openssh-server;
RUN ([ -d /lib/systemd/system/sysinit.target.wants ] && cd /lib/systemd/system/sysinit.target.wants/ && for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

# Configure SSH
RUN ssh-keygen -A && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    # Set a default root password (change this in production!)
    echo 'root:password' | chpasswd && \
    # Enable sshd service
    systemctl enable sshd

# Completely disable pam_nologin in the SSH PAM configuration
RUN sed -i '/pam_nologin.so/d' /etc/pam.d/sshd && \
    sed -i '/pam_nologin.so/d' /etc/pam.d/login && \
    sed -i '/pam_nologin.so/d' /etc/pam.d/system-auth

# Create tmpfiles configuration to ensure /run/nologin is removed
RUN echo "r /run/nologin - - - - -" > /etc/tmpfiles.d/remove-nologin.conf

VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]