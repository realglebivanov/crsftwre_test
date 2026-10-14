ARG ELIXIR_VERSION=1.20.3
ARG OTP_VERSION=28.5.0.5
ARG DEBIAN_VERSION=trixie-20260824-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV="prod"

# Install dependencies first so they are cached between code changes.
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib

RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code.
COPY config/runtime.exs config/

RUN mix release

FROM ${RUNNER_IMAGE} AS runner

RUN apt-get update \
  && apt-get install -y --no-install-recommends libstdc++6 openssl libncurses6 locales ca-certificates \
  && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app
RUN chown nobody /app

ENV MIX_ENV="prod"
ENV PHX_SERVER="true"

COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/crsftwre_test ./

USER nobody

EXPOSE 4000

CMD ["/app/bin/crsftwre_test", "start"]
