FROM node:18.17.0 AS build

# Configura URL do backend
ARG REACT_APP_BACKEND_URL
ENV REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL:-http://localhost/api}

WORKDIR /app

# Copia arquivos essenciais e instala dependências
COPY package.json package-lock.json ./
RUN yarn config set strict-ssl false && CYPRESS_INSTALL_BINARY=0 yarn install

# Copia todo o projeto e cria o build
COPY . .
RUN yarn build

# Usa Nginx para servir a aplicação
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
