# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION as base

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle"


# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
RUN \
    --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git pkg-config

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN \
    --mount=type=cache,target=${BUNDLE_PATH}/cache \
    --mount=type=cache,target=${BUNDLE_PATH}/ruby/${RUBY_VERSION}/cache \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# Final stage for app image
FROM base

# Install packages needed for deployment
RUN \
    --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libsqlite3-0

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]


RUN \
    --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && apt-get install --no-install-recommends -y \
    less

RUN { \
    echo 'source /usr/share/bash-completion/completions/git' ; \
    echo 'source /etc/bash_completion.d/git-prompt' ; \
} >> /etc/bash.bashrc
ENV PROMPT_COMMAND='__git_ps1 "\u@\h:\w" "\\\$ "' \
GIT_PS1_SHOWDIRTYSTATE=1 \
GIT_PS1_SHOWCOLORHINTS=1
