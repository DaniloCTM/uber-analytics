import pandas as pd
from sqlalchemy import create_engine, text
import time
import os
import dotenv
dotenv.load_dotenv()

# --- Configurações ---
POSTGRES_USER = os.getenv('POSTGRES_USER')
POSTGRES_PASSWORD = os.getenv('POSTGRES_PASSWORD')
POSTGRES_DB = os.getenv('POSTGRES_DB')
DB_HOST = 'db'
RAW_DATA_FILE = os.path.join(os.path.dirname(__file__), '../../data/bronze/ncr_ride_bookings.csv')

def run_etl():
    """
    Executa o processo completo de ETL.
    """
    db_url = f'postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{DB_HOST}:5432/{POSTGRES_DB}'
    engine = None

    # 1. Tenta conectar ao banco de dados (espera o container 'db' ficar pronto)
    retries = 5
    while retries > 0:
        try:
            engine = create_engine(db_url)
            with engine.connect() as connection:
                print("Conexão com o PostgreSQL bem-sucedida!")
                break
        except Exception as e:
            print(f"Falha ao conectar. Tentando novamente em 5 segundos... ({retries} tentativas restantes)")
            retries -= 1
            time.sleep(5)
    
    if not engine:
        print("Não foi possível conectar ao banco de dados. Abortando.")
        return

    # 2. Criação da Tabela (DDL da Camada Silver) - Pego do uber.sql
    ddl_query = text("""
    CREATE TABLE IF NOT EXISTS uber (
        "Booking_ID" VARCHAR(20) PRIMARY KEY,
        "Date" DATE NOT NULL,
        "Time" TIME NOT NULL,
        "Booking_Status" VARCHAR(30) NOT NULL,
        "Customer_ID" VARCHAR(20) NOT NULL,
        "Vehicle_Type" VARCHAR(30) NOT NULL,
        "Pickup_Location" VARCHAR(100) NOT NULL,
        "Drop_Location" VARCHAR(100) NOT NULL,
        "Avg_VTAT" NUMERIC(5,2),
        "Avg_CTAT" NUMERIC(5,2),
        "Reason_for_cancelling_by_Customer" TEXT,
        "Driver_Cancellation_Reason" TEXT,
        "Incomplete_Rides_Reason" TEXT,
        "Booking_Value" NUMERIC(7,2),
        "Ride_Distance" NUMERIC(6,2),
        "Driver_Ratings" NUMERIC(3,2),
        "Customer_Rating" NUMERIC(3,2),
        "Payment_Method" VARCHAR(20)
    );
    """)
    
    with engine.connect() as connection:
        # Garante que começamos do zero - força a recriação da tabela
        connection.execute(text('DROP TABLE IF EXISTS uber CASCADE'))
        connection.commit()        # Usar 'replace' para garantir que a tabela seja completamente substituída

        connection.execute(ddl_query)
        connection.commit()
        print("✅ Tabela 'Uber' criada com sucesso.")

    # 3. Extração (Leitura do CSV) - Camada Bronze
    try:
        df_bronze = pd.read_csv(RAW_DATA_FILE)
        print(f"Dados brutos lidos de '{RAW_DATA_FILE}'.")
    except FileNotFoundError:
        print(f"Erro: Arquivo '{RAW_DATA_FILE}' não encontrado.")
        return

    # 4. Transformação (Bronze -> Silver)
    print("⏳ Iniciando transformação dos dados...")
    df_silver = df_bronze.copy()

    # Renomear colunas
    df_silver.rename(columns={
        'Booking ID': 'Booking_ID', 'Booking Status': 'Booking_Status', 'Customer ID': 'Customer_ID',
        'Vehicle Type': 'Vehicle_Type', 'Pickup Location': 'Pickup_Location', 'Drop Location': 'Drop_Location',
        'Avg VTAT': 'Avg_VTAT', 'Avg CTAT': 'Avg_CTAT', 'Reason for cancelling by Customer': 'Reason_for_cancelling_by_Customer',
        'Driver Cancellation Reason': 'Driver_Cancellation_Reason', 'Incomplete Rides Reason': 'Incomplete_Rides_Reason',
        'Booking Value': 'Booking_Value', 'Ride Distance': 'Ride_Distance', 'Driver Ratings': 'Driver_Ratings',
        'Customer Rating': 'Customer_Rating', 'Payment Method': 'Payment_Method'
    }, inplace=True)

    # Limpeza de dados: Remover colunas de flag
    df_silver.drop(columns=['Cancelled Rides by Customer', 'Cancelled Rides by Driver', 'Incomplete Rides'], inplace=True)

    # Limpeza de dados (remover aspas)
    df_silver['Booking_ID'] = df_silver['Booking_ID'].str.replace('"', '', regex=False)
    df_silver['Customer_ID'] = df_silver['Customer_ID'].str.replace('"', '', regex=False)

    # Remover duplicatas baseado no Booking_ID (chave primária)
    initial_count = len(df_silver)
    df_silver.drop_duplicates(subset=['Booking_ID'], keep='first', inplace=True)
    final_count = len(df_silver)
    if initial_count != final_count:
        print(f"  Removidas {initial_count - final_count} linhas duplicadas baseadas no Booking_ID.")

    # Tratamento de valores nulos (NaN)
    df_silver['Incomplete_Rides_Reason'].fillna('Reason Unknown', inplace=True)
    df_silver['Driver_Cancellation_Reason'].fillna('Reason Unknown', inplace=True)
    df_silver['Reason_for_cancelling_by_Customer'].fillna('Reason Unknown', inplace=True)
    
    # Imputação de valores
    for col in ['Avg_VTAT', 'Avg_CTAT', 'Booking_Value', 'Ride_Distance', 'Driver_Ratings', 'Customer_Rating']:
        df_silver[col].fillna(df_silver[col].mean(), inplace=True)
    df_silver['Payment_Method'].fillna(df_silver['Payment_Method'].mode()[0], inplace=True)
    
    # Conversão de tipos de dados
    df_silver['Date'] = pd.to_datetime(df_silver['Date']).dt.date
    df_silver['Time'] = pd.to_datetime(df_silver['Time']).dt.time
    print("Transformações de limpeza concluídas.")

    # 5. Carregamento (Load) na Tabela 'Uber' (Camada Silver)
    try:
        df_silver.to_sql('uber', con=engine, if_exists='replace', index=False, method='multi')
        print(f"Sucesso! {len(df_silver)} registros inseridos na tabela 'uber'.")
    except Exception as e:
        print(f"Erro ao inserir dados na tabela: {e}")

if __name__ == "__main__":
    run_etl()