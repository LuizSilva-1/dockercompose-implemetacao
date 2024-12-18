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
