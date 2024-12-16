# Dockerfile para o backend
FROM python:3.9-slim

WORKDIR /app

# Copia os requisitos e instala as dependências
COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org -r requirements.txt


# Copia o restante do código para o container
COPY . .

# ENV FLASK_APP=run.py
EXPOSE 5000

CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
