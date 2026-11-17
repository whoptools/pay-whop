FROM ruby:4.0.9-slim AS build
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential libpq-dev libyaml-dev pkg-config && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV BUNDLE_FROZEN=true
COPY . .
RUN bundle install --jobs 2

FROM ruby:4.0.9-slim
RUN apt-get update -qq && apt-get install --no-install-recommends -y libpq5 libyaml-0-2 ca-certificates && rm -rf /var/lib/apt/lists/* && useradd --create-home --uid 1000 rails
WORKDIR /app
ENV RAILS_ENV=production PORT=3001 BUNDLE_FROZEN=true
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /app /app
USER rails
EXPOSE 3001
CMD ["examples/rails/bin/start"]
