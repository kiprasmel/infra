- ssh key @ remote (DO allows by default when creating)
- ssh key @ local
- compare prod's man3 and ams1 man - see which pkgs missing
SRV=

. ./vars
USER=

- ssh root@$SRV
- useradd -m $USER; passwd $USER
- sudo usermod -aG sudo $USER
- cp -r ~/.ssh /home/$USER
- su $USER
- cd ~
- sudo chown -R $USER:$USER ~/.ssh
- sudo add-apt-repository -y ppa:git-core/ppa
- sudo apt update -y && sudo apt upgrade -y # handle kernel reboot?
- sudo apt install -y git
- git clone https://github.com/$GITHUB_USERNAME/infra
- bash infra/server/ubuntu/setup-p1.sh
- bash infra/server/ubuntu/setup-p2.sh
-
- sudo vim /etc/ssh/sshd_config
	- Port 2222
		- adjust local ssh conf
	- PermitRootLogin no
	- UsePAM no

passwd # more secure

