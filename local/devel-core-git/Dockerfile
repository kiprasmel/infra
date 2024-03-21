FROM ubuntu:latest

ENV USER="root"
USER "$USER"

ENV DEBIAN_FRONTEND="noninteractive"

# core deps
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y software-properties-common \
	&& apt-add-repository -y ppa:git-core/ppa \
	&& apt-get install -y \
	build-essential \
	libssl-dev \
	libcurl4-gnutls-dev \
	libexpat1-dev \
	gettext \
	unzip \
	zsh \
	git \
	openssh-server

# from git/ci/install-docker-dependencies.sh
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y \
	make language-pack-is libsvn-perl apache2 libssl-dev libcurl4-openssl-dev \
	libexpat-dev tcl tk gettext zlib1g-dev perl-modules liberror-perl \
	libauthen-sasl-perl libemail-valid-perl libdbd-sqlite3-perl \
	libio-socket-ssl-perl libnet-smtp-ssl-perl ${CC_PACKAGE:-${CC:-gcc}} \
	apache2 cvs cvsps gnupg libcgi-pm-perl subversion

# extra deps
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y \
	neovim tmux gdb gdbserver ripgrep htop python3 python3-pip neofetch \
	valgrind kcachegrind linux-tools-common linux-tools-generic universal-ctags

# cleanup
RUN apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# dotfiles
COPY ./install-dotfiles.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-dotfiles.sh \
          && /usr/local/bin/install-dotfiles.sh

# locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo 'LANG="en_US.UTF-8"' >> /etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG   en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# default workdir
WORKDIR /git

RUN mkdir /var/run/sshd
EXPOSE 22

# run ssh server by default.
#
# to access regular shell, use
# docker exec -it git /bin/zsh -l
#
CMD ["/usr/sbin/sshd", "-D"]

