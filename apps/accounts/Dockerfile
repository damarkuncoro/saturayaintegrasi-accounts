
FROM ruby:3.3-slim AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    postgresql-client \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    ln -s /usr/lib/*/libjemalloc.so.2 /usr/lib/libjemalloc.so.2

ENV BUNDLE_PATH="/usr/local/bundle"

# ─── Development stage ────────────────────────────────────────
FROM base AS development

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    libvips \
    libyaml-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="development" \
    BUNDLE_WITHOUT=""

# Selective copy of required packages
COPY packages/commons /packages/commons
COPY packages/system /packages/system
COPY packages/identity /packages/identity
COPY packages/identity-client /packages/identity-client
COPY packages/identity-ui /packages/identity-ui
COPY packages/ui /packages/ui
COPY packages/navigation /packages/navigation
COPY apps/accounts/Gemfile apps/accounts/Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    mkdir -p /usr/local/bundle && \
    RUBY_VERSION_DIR=$(ls /usr/local/bundle/ruby 2>/dev/null | head -n 1) && \
    RUBY_DIR="ruby/$RUBY_VERSION_DIR" && \
    if [ -d "/usr/local/bundle/$RUBY_DIR/gems" ]; then \
      ln -sf $RUBY_DIR/gems /usr/local/bundle/gems && \
      ln -sf $RUBY_DIR/specifications /usr/local/bundle/specifications && \
      ln -sf $RUBY_DIR/bin /usr/local/bundle/bin || true; \
    fi

COPY apps/accounts .

EXPOSE 3000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]

# ─── Test stage ───────────────────────────────────────────────
FROM development AS test

ENV RAILS_ENV="test"

# Install Node.js, npm, and chromium dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends \
    nodejs \
    libgbm1 \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Pre-install playwright browser driver and Chromium browser
RUN npm install -g playwright && npx playwright install-deps chromium && npx playwright install chromium

# ─── Build stage (production) ─────────────────────────────────
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    libvips \
    libyaml-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_WITHOUT="development"

# Selective copy of required packages
COPY packages/commons /packages/commons
COPY packages/system /packages/system
COPY packages/identity /packages/identity
COPY packages/identity-client /packages/identity-client
COPY packages/identity-ui /packages/identity-ui
COPY packages/ui /packages/ui
COPY packages/navigation /packages/navigation
COPY apps/accounts/Gemfile apps/accounts/Gemfile.lock ./
COPY apps/accounts/vendor/ ./vendor/
RUN bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache

COPY apps/accounts .
RUN bundle exec bootsnap precompile -j 1 --gemfile app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 DISABLE_SIDEKIQ_INITIALIZATION=true ./bin/rails assets:precompile

# ─── Production stage ─────────────────────────────────────────
FROM base AS production

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    LD_PRELOAD="/usr/lib/libjemalloc.so.2"

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /packages/commons /packages/commons
COPY --chown=rails:rails --from=build /packages/system /packages/system
COPY --chown=rails:rails --from=build /packages/identity /packages/identity
COPY --chown=rails:rails --from=build /packages/identity-client /packages/identity-client
COPY --chown=rails:rails --from=build /packages/identity-ui /packages/identity-ui
COPY --chown=rails:rails --from=build /packages/ui /packages/ui
COPY --chown=rails:rails --from=build /packages/navigation /packages/navigation
COPY --chown=rails:rails --from=build /rails /rails

EXPOSE 3000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/thrust", "./bin/rails", "server"]
