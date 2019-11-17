FROM alpine:3.8

RUN apk add --no-cache ca-certificates git nfs-utils build-base bash
RUN [ ! -e /etc/nsswitch.conf ] \
    && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV DOCKER_CHANNEL=stable
ENV DOCKER_VERSION=19.03.0

LABEL docker_version $DOCKER_VERSION

RUN set -ex; \
	apk add --no-cache --virtual .fetch-deps \
		curl \
		tar \
	; \
	\
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		x86_64) dockerArch='x86_64' ;; \
		s390x) dockerArch='s390x' ;; \
		*) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;;\
	esac; \
	\
	if ! curl -fL -o docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/docker-${DOCKER_VERSION}.tgz"; then \
		echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for '${dockerArch}'"; \
		exit 1; \
	fi; \
	\
	tar --extract \
		--file docker.tgz \
		--strip-components 1 \
		--directory /usr/local/bin/ \
	; \
	rm docker.tgz; \
	\
	apk del .fetch-deps; \
	\
	dockerd -v; \
	docker -v

COPY modprobe.sh /usr/local/bin/modprobe
COPY docker-entrypoint.sh /usr/local/bin/

# Enable experimental feature (gitlab does the right thing and appends its changes)
RUN mkdir -p /root/.docker && echo '{"experimental": "enabled"}' > /root/.docker/config.json

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["sh"]
