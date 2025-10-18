# syntax=docker/dockerfile:1

# Base image with Ruby
FROM ruby:3.2.2-alpine AS base

# Install base dependencies
RUN apk add --no-cache \
    build-base \
    tzdata \
    bash \
    libaio \
    libnsl

WORKDIR /app

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apk add --no-cache git

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    find "$BUNDLE_PATH" -name "*.c" -delete && \
    find "$BUNDLE_PATH" -name "*.o" -delete

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Final stage for app image
FROM base

# Copy built artifacts: gems and application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

# Create a non-root user for running the application
RUN addgroup -g 1000 rails && \
    adduser -D -u 1000 -G rails rails && \
    chown -R rails:rails /app /usr/local/bundle

USER rails:rails

# Expose port 3001
EXPOSE 3001

# Start the server by default
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
