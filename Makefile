.DEFAULT_GOAL		:= help

IMAGE_NAME			:= centos:7
SHELL				:= /bin/bash
HOSTDIR				:= /host
BUILDDIR			:= /home/user

SCMD := $(shell \
	if ! id -n -G | grep -q docker; then \
		echo sudo; \
	fi \
)

NCPU := $(shell \
	getconf _NPROCESSORS_ONLN 2>/dev/null || \
	getconf NPROCESSORS_ONLN 2>/dev/null || echo 1 \
)
MEM := $(shell \
	echo $$(free -m | awk '/^Mem/ {print int($$7 * 0.8)}')M \
)

DEFAULT_CMD := \
	useradd -u "$(shell id -u)" -g "$(shell id -g)" user;						\
	yum makecache;																\
	yum install -y make gcc rpm-build rpmdevtools sudo;							\
	echo 'root ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers;						\
	echo 'user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers;						\
	chown -R user: "$(BUILDDIR)";												\
	sudo -u user rpmdev-setuptree;												\
	sudo -u user cp -- "$(HOSTDIR)/SPECS/*.spec" "$(BUILDDIR)/rpmbuild/SPECS/";	\
	yum-builddep -y "$(BUILDDIR)/rpmbuild/SPECS/*.spec";						\
	sudo -u user spectool -R -g "$(BUILDDIR)/rpmbuild/SPECS/*.spec";			\
	sudo -u user rpmbuild -ba "$(BUILDDIR)/rpmbuild/SPECS/*.spec";				\
	sudo -u user cp -- "$(BUILDDIR)/rpmbuild/RPMS/*/*.rpm" "$(HOSTDIR)";		\
	sudo -u user cp -- "$(BUILDDIR)/rpmbuild/SRPMS/*.rpm" "$(HOSTDIR)";			\

export NCPU
export MEM

DOCKER_ENV := -e "NCPU=$(NCPU)"						\
	-e "TERM=$(TERM)"								\
	-v "$(PWD)":"$(HOSTDIR)"						\
	-w $(BUILDDIR)									\
	--rm

all:

help:  ## display this help
	@cat $(MAKEFILE_LIST) | grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' | \
		sort -k1,1 | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build:  ## build arch linux package
	$(SCMD) docker run $(DOCKER_ENV) \
		-it $(IMAGE_NAME) /bin/sh -c "$(DEFAULT_CMD)"

shell:  ## open a shell inside docker
	$(SCMD) docker run $(DOCKER_ENV) \
		-it $(IMAGE_NAME) $(SHELL)

clean: cleanup  ## remove actual docker image

cleanup:  ## generic docker cleanup
	$(SCMD) docker ps -q -f status=exited | xargs -r $(SCMD) docker rm -v
	$(SCMD) docker images -q -f dangling=true | xargs -r $(SCMD) docker rmi
	$(SCMD) docker volume ls -q -f dangling=true | xargs -r $(SCMD) docker volume rm


.PHONY: all help build clean cleanup

# vim: set noexpandtab ts=4 sw=4 ft=make :
