# Imagen endurecida de Juice Shop: versiones fijas, base mínima sin shell y sin usuario root.
FROM node:26.13.1-bookworm AS construccion
WORKDIR /juice-shop
COPY . .
RUN npm install -g typescript@6.0.3 \
    && npm install --omit=dev \
    && npm dedupe --omit=dev \
    && rm -rf frontend/node_modules frontend/.angular frontend/src/assets \
    && mkdir logs \
    && chown -R 65532 logs \
    && chgrp -R 0 ftp/ frontend/dist/ logs/ data/ i18n/ \
    && chmod -R g=u ftp/ frontend/dist/ logs/ data/ i18n/ \
    && rm -f ftp/legal.md i18n/*.json

FROM gcr.io/distroless/nodejs24-debian13:nonroot
WORKDIR /juice-shop
COPY --from=construccion --chown=65532:0 /juice-shop .
USER 65532
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD ["/nodejs/bin/node", "-e", "require('http').get('http://127.0.0.1:3000/rest/admin/application-version', (r) => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"]
CMD ["/juice-shop/build/app.js"]
