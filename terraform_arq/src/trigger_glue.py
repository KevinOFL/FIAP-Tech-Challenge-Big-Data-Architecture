import json
import boto3
import os
import urllib.parse
import logging

glue_client = boto3.client("glue")

# Configura o logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Função lambda que aciona o job no Glue entregando o path do arquivo adiciona ao bucket
def lambda_handler(event, context):
    try: 
        record = event['Records'][0] # Pegando o primeiro evento
        s3_bucket = record['s3']['bucket']['name'] # Pegando os dados do bucket
        s3_key = urllib.parse.unquote_plus(record['s3']['object']['key']) # Criando a url do objeto adicionado ao bucket
        s3_file_path = f"s3://{s3_bucket}/{s3_key}"
        logging.info(f"Arquivo recebido: {s3_file_path}")
        
        # Acessando o dado da variavel de ambiente que contém o nome do job no Glue
        glue_job_name = os.environ.get('GLUE_JOB_NAME')
        if not glue_job_name:
            raise ValueError("A variável de ambiente GLUE_JOB_NAME nãe está configurada.")
        
        logging.info(f"Iniciando o job do Glue: {glue_job_name}")
        
        # Startando o job no Glue
        response = glue_client.start_job_run(
            JobName=glue_job_name,
            Arguments={'--s3_source_path': s3_file_path}
        )
        
        job_run_id = response['JobRunId']
        logging.info(f"Job do Glue iniciado com sucesso. Run Id: {job_run_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps(f"Job {glue_job_name} iniciado. Run Id: {job_run_id}")
        }
        
    except Exception as e:
        print(f"Erro ao processar o evento: {e}")
        raise e