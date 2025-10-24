FROM registry.access.redhat.com/ubi9/nodejs-18-minimal

WORKDIR /opt/app

# Copiamos los archivos antes de cambiar permisos
COPY package.json .
COPY server.js .

# Fijamos permisos para que cualquier UID pueda escribir
RUN chmod -R g+w /opt/app && chgrp -R 0 /opt/app && chmod -R g=u /opt/app

# Instalamos dependencias
RUN npm install --omit=dev

# Exponemos puerto
EXPOSE 8080

# Configuración OpenShift-friendly (no asumimos root)
USER 1001

CMD ["node", "server.js"]

