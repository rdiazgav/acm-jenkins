FROM registry.access.redhat.com/ubi9/nodejs-18-minimal

# Cambiamos temporalmente a root para ajustar permisos
USER 0

WORKDIR /opt/app

# Copiamos archivos y ajustamos permisos para UID arbitrario
COPY package.json .
COPY server.js .
RUN chmod -R g+w /opt/app && chgrp -R 0 /opt/app && chmod -R g=u /opt/app

# Volvemos al usuario por defecto (no root)
USER 1001

# Instala dependencias
RUN npm install --omit=dev

EXPOSE 8080
CMD ["node", "server.js"]
