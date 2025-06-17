FROM docker.io/elixir:1.18.4-slim

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ARG UID=1000
ARG PWD=/home/dev

RUN useradd --uid $UID --create-home dev

WORKDIR /tmp

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      locales && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      inotify-tools \
      libncurses5 \
      libstdc++6 \
      locales \
      openssl \
      unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /usr/local/elixir-ls && \
    curl -sSLo elixir-ls.zip \
      https://github.com/elixir-lsp/elixir-ls/releases/download/v0.28.0/elixir-ls-v0.28.0.zip && \
    unzip elixir-ls.zip -d /usr/local/elixir-ls && \
    ln -s /usr/local/elixir-ls/language_server.sh /usr/local/bin/elixir-ls && \
    rm elixir-ls.zip

USER dev
WORKDIR $PWD

COPY --chown=dev:dev mix.exs mix.lock ./

ENV MIX_ENV=dev

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix compile
