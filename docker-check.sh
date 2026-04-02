#!/bin/bash

if rpm -q docker; then
	echo "Package docker: installed"
else
	echo "ERROR: install docker"
	exit 1
fi
if [ $(systemctl is-active docker.service) == 'active' ]; then
	echo "Docker service: active"
else
	echo "ERROR: systemctl start docker.service"
	exit 1
fi
if [ $(systemctl is-enabled docker.service) == 'enabled' ]; then
	echo "Docker service: enabled"
else
	echo "WARNING: systemctl enable docker.service"
fi

echo "Users in group docker:" $(getent group docker)

if [ -e '/var/lib/docker' ]; then
	tmp=$(readlink -f /var/lib/docker)
	fs=$(stat --format="%T" -f "$tmp")
	echo "Container path: exists ($tmp on $fs)"
	echo "Space report on $tmp:"
	df -HT /var/lib/docker
else
	echo "ERROR: container path /var/lib/docker does not exist?"
	exit 1
fi
