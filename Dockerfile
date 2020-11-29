FROM node:lts-slim AS build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /src/

RUN set -xe \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		ca-certificates \
		git \
	\
	&& git clone --branch=develop --depth=1 https://github.com/electerious/Ackee.git .

RUN set -xe \
	&& yarn install --frozen-lockfile \
	&& yarn build \
	&& yarn install --production --frozen-lockfile

FROM gcr.io/distroless/nodejs:14
WORKDIR /srv/app/

COPY --chown=nonroot --from=build /src/node_modules /srv/app/node_modules
COPY --chown=nonroot --from=build /src/dist /srv/app/dist
COPY --chown=nonroot --from=build /src/src /srv/app/src

# run as an unprivileged user
USER nonroot

EXPOSE 3000

HEALTHCHECK --interval=5s --timeout=10s --retries=5 CMD [ "/nodejs/bin/node", "/srv/app/src/healthcheck.js" ]
CMD ["/srv/app/src/index.js" ]
