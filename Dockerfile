FROM registry.access.redhat.com/ubi9/nodejs-18-minimal

WORKDIR /opt/app

# Copiamos solo lo necesario
COPY package.json .
COPY server.js .

# Instala deps (mantienes versiones viejas a propósito para que ACS detecte CVEs)
RUN npm install --omit=dev

# Permisos para UID arbitrario (SCC restricted)
RUN chgrp -R 0 /opt/app && chmod -R g=u /opt/app

EXPOSE 8080
CMD ["node", "server.js"]
