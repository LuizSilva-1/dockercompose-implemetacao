# Desafio: Implementação de Estrutura com Docker Compose

Este desafio tem como objetivo aplicar os conhecimentos adquiridos no curso de **Containers e Orquestração**, ministrado pela **Pós-graduação da PUC Minas**. A proposta é implementar o **Guess Game**, uma aplicação simples composta por um backend desenvolvido em Flask, um frontend em React e um banco de dados PostgreSQL. A aplicação será orquestrada utilizando **Docker Compose**, e contará com o **NGINX** configurado como proxy reverso e balanceador de carga.

---

## Sobre a Aplicação

O desafio utiliza como base o jogo demo disponível em [https://github.com/fams/guess_game](https://github.com/fams/guess_game). Todos os créditos pela aplicação original são destinados ao criador do projeto. A implementação foca na criação e configuração da infraestrutura com Docker Compose, abrangendo os seguintes serviços:

1. **PostgreSQL (db):** Banco de dados relacional para armazenar os dados do jogo. Será utilizada a imagem `postgres:14` disponível no Docker Hub.
2. **Backend + NGINX:** 
   - O backend será responsável por gerenciar a lógica do jogo e as tomadas de decisão.
   - O NGINX será configurado para organizar o tráfego entre o frontend e o backend, garantindo eficiência e evitando sobrecargas.
3. **Frontend:** A interface gráfica principal será construída com React, proporcionando uma experiência interativa para os usuários.

---

## Estrutura do Projeto

```plaintext
.
├── Dockerfile            # Dockerfile para o backend Flask e NGINX
├── docker-compose.yml    # Configuração do Docker Compose
├── frontend/             # Código-fonte do frontend React
│   ├── Dockerfile        # Dockerfile para o frontend
│   ├── build/            # Build do React (gerado automaticamente)
├── nginx/
│   ├── nginx.conf        # Configuração do NGINX
├── requirements.txt      # Dependências do backend Flask
├── run.py                # Arquivo principal do backend Flask
└── tests/                # Testes unitários
```
---

## Configurações dos Arquivos

### 1. `docker-compose.yml`

Este arquivo define como os containers serão configurados e gerenciados. Ele especifica os serviços (backend, frontend e banco de dados), suas redes, volumes e dependências. 

**OBS: Foi necessário adicionar um healthcheck para que a aplicação não envie informações para o banco antes de ele estar pronto.**

**Conteúdo:**
```yaml
services:
  db:
    image: postgres:14
    container_name: postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: secretpass
      POSTGRES_DB: guess_game
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d guess_game"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      FLASK_APP: run.py
      FLASK_DB_TYPE: postgres
      FLASK_DB_USER: postgres
      FLASK_DB_PASSWORD: secretpass
      FLASK_DB_NAME: guess_game
      FLASK_DB_HOST: db
      FLASK_DB_PORT: 5432
    networks:
      - app-network
    depends_on:
      db:
        condition: service_healthy

  frontend:
    build:
      context: ./frontend
    networks:
      - app-network
    ports:
      - "80:80"
    depends_on:
      - backend
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf  

networks:
  app-network:

volumes:
  db_data:
```
## Configuração do NGINX

O arquivo **`nginx/nginx.conf`** é responsável por configurar o NGINX como **proxy reverso** e realizar as seguintes funções:

- **Balanceamento de carga**: Distribui o tráfego entre os serviços do backend.
- **Redirecionamento de tráfego**: Encaminha as requisições para as APIs do backend.
- **Servir arquivos estáticos**: Serve os arquivos do frontend React.

Abaixo está o conteúdo do arquivo **`nginx/nginx.conf`**:

```nginx
events {}

http {
    include /etc/nginx/mime.types;
    sendfile on;    
    
    upstream backend {
        server backend:5000;
    }

    server {
        listen 80;

        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri /index.html;
        }

        location /api/ {
            proxy_pass http://backend/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```
## Dockerfile (Backend)

O **`Dockerfile`** é responsável por definir como o container do **backend Flask** será configurado e executado. Ele inclui a instalação das dependências, configuração de variáveis de ambiente e um **health check** para monitoramento.

### Conteúdo do arquivo **Dockerfile**:

```dockerfile
FROM python:3.9-slim

WORKDIR /app

# Copia e instala as dependências
COPY requirements.txt .
RUN pip install --no-cache-dir --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org -r requirements.txt

# Copia o restante do código para o container
COPY . .

# Define variáveis de ambiente para Flask
ENV FLASK_APP=/app/run.py \
    FLASK_RUN_HOST=0.0.0.0 \
    FLASK_RUN_PORT=5000

# Adiciona um health check (opcional)
HEALTHCHECK CMD curl --fail http://localhost:5000/health || exit 1

# Expõe a porta padrão do Flask
EXPOSE 5000

# Comando para iniciar o Flask
CMD ["flask", "run"]
```
## Dockerfile (Frontend)

O **`Dockerfile`** do **frontend** define como o container será configurado para compilar e servir a aplicação React utilizando **Nginx**.

---

### Conteúdo do arquivo **Dockerfile**:

```dockerfile
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
```
## Instruções de Implementação

### Pré-requisitos
Certifique-se de que os seguintes programas estão instalados na sua máquina:
- **Docker**
- **Docker Compose**

---

### Passos

1. **Clone o Repositório**

Para obter o código-fonte do projeto, execute os seguintes comandos:

```bash
git clone git@github.com:LuizSilva-1/dockercompose-implemetacao.git
cd dockercompose-implemetacao
```

2. **Suba os Containers**

Utilize o **Docker Compose** para construir e inicializar todos os serviços necessários:

```bash
docker-compose up --build
```

3. **Acesse a Aplicação**


Após iniciar os containers, acesse a aplicação no navegador através do seguinte endereço:

- **Frontend e Backend:** 

```plaintext 
http://localhost:80
```

## Observações Finais

Este desafio visa demonstrar o domínio sobre:

### Criação e Orquestração de Containers:
- Uso do **Docker Compose** para orquestrar um ambiente com backend, frontend e banco de dados.

### Configuração Completa do Ambiente:
- **Backend**: Desenvolvido em **Flask**.
- **Frontend**: Construído em **React**.
- **Banco de Dados**: Utiliza **PostgreSQL**.

### Utilização do NGINX:
- Configurado como **proxy reverso** para gerenciar o tráfego entre o frontend e o backend.
- Implementação de **balanceamento de carga** para distribuir as requisições de forma eficiente.
