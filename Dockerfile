# Use Red Hat UBI 9 minimal as base
ROM registry.access.redhat.com/ubi9/nodejs-18-minimal

# Install Node.js (LTS but from RHEL repos, it may include known CVEs)
RUN microdnf install -y nodejs npm curl && microdnf clean all

# Create app directory and add non-root user
WORKDIR /opt/app
RUN useradd --uid 1001 --create-home appuser
USER appuser

# Copy app files
COPY --chown=1001:1001 package.json .
COPY --chown=1001:1001 server.js .

# Install dependencies (includes intentionally outdated packages)
RUN npm install --omit=dev

EXPOSE 8080

CMD ["node", "server.js"]
