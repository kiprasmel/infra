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
	neovim gdb gdbserver ripgrep htop universal-ctags python3 python3-pip \
	linux-tools-common linux-tools-generic

# perf deps
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y \
	flex bison pkg-config libelf-dev libtraceevent-dev

# perf src, minimal with sparse-checkout
RUN cd /opt \
	&& git clone --depth=1 --no-checkout --filter=blob:none --sparse "https://github.com/torvalds/linux.git" \
	&& cd linux \
	&& git sparse-checkout init --cone \
	&& git checkout master \
	&& git sparse-checkout set tools include scripts arch/arm64

# slow + big AF
#git clone --depth=1 "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"

# filtering not supported at all:
#git clone --depth=1 --no-checkout --filter=blob:none --filter=tree:0 --sparse "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"

# combined filtering not supported:
#git clone --depth=1 --no-checkout --filter=blob:none --filter=tree:0 --sparse "https://github.com/torvalds/linux.git"

# perf build
RUN cd "/opt/linux/tools/perf" \
	&& make -j `nproc` \
	&& cp perf /usr/bin/ \
	&& rm -rf /opt/linux

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

