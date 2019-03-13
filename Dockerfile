FROM alpine:3.7

RUN apk --no-cache add \
  bash \
  ca-certificates \
  curl \
  git \
  jq \
  openssh-client

# can't `git pull` unless we set these
RUN git config --global user.email "git@localhost" && \
  git config --global user.name "git"

COPY scripts/install_git_lfs.sh install_git_lfs.sh
RUN ./install_git_lfs.sh

COPY assets /opt/resource
