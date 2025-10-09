# Documentação de Modelagem de Dados – Projeto Uber Ride Analytics

## Contextualização

Este documento apresenta a modelagem de dados desenvolvida para o projeto Uber Ride Analytics, cujo objetivo é criar uma estrutura analítica em camadas (Bronze, Silver e Gold) para extração e tratamento de dados provenientes do dataset público do Kaggle: Uber Ride Analytics Dashboard.

A modelagem tem como finalidade representar, de forma conceitual e lógica, as principais entidades, relacionamentos e atributos necessários para compor o banco de dados MySQL containerizado que servirá como base para o processo ETL (Raw → Silver → Gold).

## 1. Modelo Entidade-Relacionamento (MER)

O Modelo Entidade-Relacionamento (também representado como MREL) apresenta a estrutura conceitual dos dados, identificando os principais atributos e suas relações hierárquicas dentro da entidade central Uber.

![Figura 1 – MER/MREL do Sistema Uber Ride Analytics](./assets/UBER_MREL.png)

### Descrição:

- A entidade Uber representa o registro principal de uma corrida.
- Cada corrida é identificada de forma única pelo atributo Booking_ID.
- A estrutura agrupa informações sobre o cliente, motorista, localização, tipo de veículo, avaliações, cancelamentos e métricas de tempo.
- Essa representação hierárquica facilita o entendimento do relacionamento entre atributos e o fluxo de dados ao longo do processo analítico.

## 2. Diagrama Entidade-Relacionamento Lógico (DER / DLD)

O Diagrama Lógico de Dados (DLD) representa o modelo físico preliminar da base de dados, com os campos e chaves primárias definidos. A figura abaixo mostra a tabela principal Uber, com todos os atributos que compõem o conjunto de dados extraído e tratado.

![Figura 2 – DER/DLD do Sistema Uber Ride Analytics](./assets/UBER_DER.png)

### Descrição:

- A tabela Uber contém 19 atributos principais.
- O campo Booking_ID é a chave primária (PK).
- Todos os demais campos estão relacionados a informações complementares sobre a corrida, como:
  - Dados do cliente e motorista (Customer_ID, Driver_Ratings, Customer_Rating)
  - Dados de tempo e distância (Date, Time, Ride_Distance, Avg_CTAT, Avg_VTAT)
  - Localização (Pickup_Location, Drop_Location)
  - Status e cancelamentos (Booking_Status, Reason_for_Cancelling_by_Customer, Driver_Cancellation_Reason, Incomplete_Rides_Reason)
  - Informações financeiras (Booking_Value, Payment_Method)
  - Características do veículo (Vehicle_Type)