from selenium.webdriver.chrome.options import Options 
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from dotenv import load_dotenv
from datetime import datetime

import pandas as pd
import boto3
import io
import logging
import os

load_dotenv()

# Configura o logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

aws_access_key_id = os.getenv("AWS_ACCESS_KEY_ID")
aws_secret_access_key = os.getenv("AWS_SECRET_ACCESS_KEY")
aws_session_token = os.getenv("AWS_SESSION_TOKEN")  
nome_bucket = os.getenv("NOME_BUCKET_RAW")

s3_client = boto3.client(
    "s3",
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    aws_session_token=aws_session_token
)

def executar_scraping():
    logging.info("Iniciando o processo de scraping da B3.")
    url = "https://sistemaswebb3-listados.b3.com.br/indexPage/day/IBOV?language=pt-br"
    
    # Configurar opções do navegador
    chrome_options = Options()
    chrome_options.add_argument("--headless")  # Executa sem interface
    chrome_options.add_argument("--disable-gpu") # Necessário no Windows
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")

    # O webdriver-manager baixa e gerencia o driver do Chrome automaticamente
    driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()), options=chrome_options)
    
    logging.info("Aguardando o carregamento da página...")
    driver.get(url)
    logging.info(f"Página acessada. Aguardando a tabela ser carregada...")

    # Espera explícita de até 20 segundos pelo elemento da tabela
    wait = WebDriverWait(driver, 20)
    wait.until(EC.presence_of_element_located((By.CLASS_NAME, "table")))
    
    logging.info("Tabela encontrada. Extraindo HTML para o pandas.")
    html_content = driver.page_source
    
    # O pandas lê o HTML e converte a tabela em um DataFrame
    df_list = pd.read_html(io.StringIO(html_content), match='Código', attrs={'class': 'table'})
    
    if not df_list:
        logging.error("Pandas não conseguiu extrair a tabela do HTML.")
        return None

    df = df_list[0]  
   
        
    logging.info("Scraping concluído com sucesso.")
    
    if df is not None:
        logging.info("\nIniciando o upload para o S3...")
        NOME_BUCKET_RAW = "big-data-architecture-fiap-fase-002" 
        
        data_hoje = datetime.today()
        caminho_s3 = f"raw/ano={data_hoje.year}/mes={data_hoje.month:02d}/dia={data_hoje.day:02d}/b3_dados_brutos.parquet"

        buffer_parquet = io.BytesIO()
        df.to_parquet(buffer_parquet, index=False)

        try:
            s3_client.put_object(
                Bucket=NOME_BUCKET_RAW, Key=caminho_s3, Body=buffer_parquet.getvalue()
            )
            logging.info(f"Upload para s3://{NOME_BUCKET_RAW}/{caminho_s3} concluído.")
        except Exception as e:
            logging.error(f"Erro no upload para o S3: {e}")
            return


if __name__ == "__main__":
    executar_scraping()