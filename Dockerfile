FROM rockylinux:9

LABEL maintainer="Melih Savdert"

ENV container docker
# see https://hub.docker.com/_/rockylinux
# RockyLinux:9 missing /usr/sbin/init -> ../lib/systemd/systemd
#  see https://github.com/rocky-linux/sig-cloud-instance-images/issues/39

# Install systemd and essential packages including openssh-server
RUN dnf -y update && \
    dnf -y install systemd openssh-server openssh-clients sudo passwd && \
    dnf clean all
# RUN [ ! -f /usr/sbin/init ] && dnf -y install systemd; # Already installed above

# Configure SSH
RUN ssh-keygen -A && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    # Set a default root password (change this in production!)
    echo 'root:password' | chpasswd && \
    # Enable sshd service
    systemctl enable sshd

# systemd cleanup from original file
RUN ([ -d /lib/systemd/system/sysinit.target.wants ] && cd /lib/systemd/system/sysinit.target.wants/ && for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

VOLUME [ "/sys/fs/cgroup" ]
# Expose SSH port
EXPOSE 22
CMD ["/usr/sbin/init"]