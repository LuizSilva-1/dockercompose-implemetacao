import boto3
from .entities import Repository
from flask import current_app
import os


class DynamoDBRepository(Repository):
    def __init__(self, table_name, endpoint_url=None):
        self.table_name = table_name
        self.endpoint_url = endpoint_url
        self.region_name = os.getenv('AWS_REGION', 'sa-east-1')  # Define a região padrão como 'sa-east-1'
        self.dynamodb = boto3.resource(
            'dynamodb',
            region_name=self.region_name,  # Define a região
            endpoint_url=self.endpoint_url  # Caso esteja usando um endpoint customizado (local ou remoto)
        )
        self.table = self.dynamodb.Table(self.table_name)

    def store(self, id, data):
        response = self.table.put_item(Item={'game_id': id, 'data': data})
        return response

    def retrieve(self, id):
        current_app.logger.debug(f"Buscando item {id}")
        response = self.table.get_item(Key={'game_id': id})
        if 'Item' not in response:
            raise KeyError(f"Item {id} not found")
        return response.get('Item').get("data")

