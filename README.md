# Guess Game - Docker Compose Implementation

## Introdução

Este projeto é parte do desafio da pós-graduação da **PUC Minas**, no curso de **Containers e Orquestração**. O objetivo é implementar uma aplicação chamada **Guess Game**, utilizando uma arquitetura de micro serviços baseada em **Docker Compose**. A aplicação é composta por:

- **Frontend**: Criado com React.
- **Backend**: Desenvolvido em Flask.
- **Banco de Dados**: Utilizando PostgreSQL.
- **NGINX**: Configurado como proxy reverso e balanceador de carga.

---

## Opções de Design Adotadas

Este projeto foi desenvolvido com as seguintes escolhas de design para garantir escalabilidade, organização e facilidade de manutenção:

### **Serviços**
- Divididos em três componentes principais: frontend (React), backend (Flask) e banco de dados (PostgreSQL).  
  Essa separação facilita a escalabilidade e o isolamento das funcionalidades.

### **Volumes**
- Utilizados para persistir dados importantes, como os dados do PostgreSQL, mesmo após a parada ou reinicialização dos contêineres.

### **Redes**
- Configuradas no Docker Compose para permitir a comunicação eficiente e segura entre os serviços, sem expô-los externamente desnecessariamente.

### **Estratégia de Balanceamento de Carga**
- O NGINX foi configurado como proxy reverso e balanceador de carga, distribuindo as requisições de maneira uniforme entre os serviços backend, aumentando a resiliência e eficiência.

---

## Sobre a Aplicação

A aplicação implementa o jogo **Guess Game**, no qual os usuários tentam adivinhar números gerados aleatoriamente. As funcionalidades estão organizadas nos seguintes componentes:

- **Frontend**: Exibe a interface gráfica para os jogadores.
- **Backend**: Processa a lógica do jogo e gerencia as interações entre o frontend e o banco de dados.
- **Banco de Dados**: Utilizado para armazenar os dados persistentes do jogo, como tentativas e resultados.


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

Nesta seção, são detalhados os principais arquivos usados no projeto e suas funções.

### 1. `docker-compose.yml`

O arquivo `docker-compose.yml` gerencia todos os serviços, definindo como eles se conectam e suas configurações específicas.

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


O arquivo **nginx/nginx.conf**** configura o NGINX como proxy reverso para gerenciar o tráfego entre os serviços e balancear as requisições para o backend.

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

### Passos para Executar

1. **Clone o Repositório**
   ```bash
   git clone git@github.com:LuizSilva-1/dockercompose-implemetacao.git
   cd dockercompose-implemetacao
    ```

2. **Construa e Suba os Containers**
    ```bash
      docker-compose up --build
    ```

3. **Acesse a Aplicação**


      Após iniciar os containers, acesse a aplicação no navegador através do seguinte endereço:

- **Frontend e Backend:** 

  ```plaintext 
  http://localhost:80
  ```
## Tecnologias Utilizadas

- **NGINX**: Proxy reverso e balanceador de carga para gerenciar o tráfego entre os serviços.
- **Flask**: Framework utilizado no backend para lógica de negócios e integração com o banco de dados.
- **React**: Biblioteca frontend para criar uma interface interativa.
- **PostgreSQL**: Banco de dados relacional para armazenar dados persistentes.
- **Docker Compose**: Para orquestrar todos os serviços do projeto.


## Créditos

O jogo original foi baseado no projeto [Guess Game](https://github.com/fams/guess_game).  
Todos os créditos pela ideia e implementação inicial são devidos ao criador do repositório.



## Observações Finais

Este projeto foi desenvolvido como parte do curso de **Containers e Orquestração**, com foco em:

- Configuração de serviços usando **Docker Compose**.
- Criação de infraestrutura escalável e resiliente.
- Integração de serviços independentes para formar uma aplicação completa.
