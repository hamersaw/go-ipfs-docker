FROM debian:bullseye
LABEL maintainer="Daniel Rammer <daniel.rammer@protonmail.com>"

# Install deps
RUN apt-get update && apt-get install -y \
  gcc \
  git \
  iproute2 \
  libssl-dev \
  make \
  ca-certificates \
  fuse \
  tini \
  wget

# Get su-exec, a very minimal tool for dropping privileges,
ENV SUEXEC_VERSION v0.2
RUN set -eux; \
  cd /tmp \
  && git clone https://github.com/ncopa/su-exec.git \
  && cd su-exec \
  && git checkout -q $SUEXEC_VERSION \
  && make su-exec-static \
  && mv /tmp/su-exec/su-exec-static /sbin/su-exec \
  && cd /tmp \
  && wget https://dist.ipfs.io/go-ipfs/v0.8.0/go-ipfs_v0.8.0_linux-amd64.tar.gz \
  && tar -xvzf go-ipfs_v0.8.0_linux-amd64.tar.gz \
  && cd go-ipfs/ \
  && bash install.sh

# Copy entrypoint script
COPY start_ipfs /usr/local/bin/start_ipfs

# Fix permissions on start_ipfs (ignore the build machine's permissions)
RUN chmod 0755 /usr/local/bin/start_ipfs

# Swarm TCP; should be exposed to the public
EXPOSE 4001
# Swarm UDP; should be exposed to the public
EXPOSE 4001/udp
# Daemon API; must not be exposed publicly but to client services under you control
EXPOSE 5001
# Web Gateway; can be exposed publicly with a proxy, e.g. as https://ipfs.example.org
EXPOSE 8080
# Swarm Websockets; must be exposed publicly when the node is listening using the websocket transport (/ipX/.../tcp/8081/ws).
EXPOSE 8081

# Create the fs-repo directory and switch to a non-privileged user.
ENV IPFS_PATH /data/ipfs
RUN mkdir -p $IPFS_PATH \
  && adduser --home $IPFS_PATH --uid 1000 --ingroup users ipfs \
  && chown ipfs:users $IPFS_PATH

# Create mount points for `ipfs mount` command
RUN mkdir /ipfs /ipns \
  && chown ipfs:users /ipfs /ipns

# Expose the fs-repo as a volume.
# start_ipfs initializes an fs-repo if none is mounted.
# Important this happens after the USER directive so permissions are correct.
VOLUME $IPFS_PATH

# The default logging level
ENV IPFS_LOGGING ""

# This just makes sure that:
# 1. There's an fs-repo, and initializes one if there isn't.
# 2. The API and Gateway are accessible from outside the container.
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/start_ipfs"]

# Execute the daemon subcommand by default
CMD ["daemon", "--migrate=true"]
