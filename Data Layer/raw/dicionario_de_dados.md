
| Nome                                | Descrição                                                                 | Tipo               | Restrições de Domínio |
|-------------------------------------|---------------------------------------------------------------------------|--------------------|-----------------------|
| Date                                | Data da solicitação da corrida.                                          | DATE                | NOT NULL              |
| Time                                | Horário da solicitação da corrida.                                       | TIME                | NOT NULL              |
| Booking_ID                          | Identificador único da reserva.                                          | VARCHAR(20)         | PK                    |
| Booking_Status                      | Status da reserva                                                        | VARCHAR(30)         | NOT NULL              |
| Customer_ID                         | Identificador único do cliente.                                          | VARCHAR(20)         | NOT NULL              |
| Vehicle_Type                        | Tipo de veículo solicitado                                               | VARCHAR(30)         | NOT NULL              |
| Pickup_Location                     | Local de origem da corrida.                                              | VARCHAR(100)        | NOT NULL              |
| Drop_Location                       | Local de destino da corrida.                                             | VARCHAR(100)        | NOT NULL              |
| Avg_VTAT                            | Tempo médio para atribuir um veículo.                                    | NUMERIC(5,2)        |                       |
| Avg_CTAT                            | Tempo médio para atribuir um cliente.                                    | NUMERIC(5,2)        |                       |
| Reason_for_cancelling_by_Customer   | Motivo do cancelamento por parte do cliente                              | TEXT                |                       |
| Driver_Cancellation_Reason          | Motivo do cancelamento por parte do motorista.                           | TEXT                |                       |
| Incomplete_Rides_Reason             | Motivo pelo qual a corrida foi marcada como incompleta.                  | TEXT                |                       |
| Booking_Value                       | Valor monetário da corrida                                               | NUMERIC(7,2)        |                       |
| Ride_Distance                       | Distância percorrida na corrida                                          | NUMERIC(6,2)        |                       |
| Driver_Ratings                      | Avaliação média dada ao motorista                                        | NUMERIC(3,2)        |                       |
| Customer_Rating                     | Avaliação média dada pelo motorista ao cliente.                          | NUMERIC(3,2)        |                       |
| Payment_Method                      | Forma de pagamento utilizada                                             | VARCHAR(20)         |                       |
