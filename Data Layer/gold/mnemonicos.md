# Mnemônicos e Dicionário Resumido (Camada Gold)

Este documento resume os mnemônicos usados nas tabelas da camada Gold.

## Fato: Fato_Corridas
- corrida_key: Chave primária (Booking_ID) — string
- data_key: FK → Dim_Data (YYYYMMDD) — integer
- veiculo_key: FK → Dim_Veiculo — long
- status_key: FK → Dim_Status — long
- pagamento_key: FK → Dim_Pagamento — long
- pickup_local_key: FK → Dim_Localizacao (origem) — long
- drop_local_key: FK → Dim_Localizacao (destino) — long
- booking_value: Valor monetário — double
- ride_distance: Distância da corrida — double
- avg_vtat: Tempo médio para atribuição de veículo — double
- avg_ctat: Tempo médio de resposta ao cliente — double

## Dimensões (resumo)
- Dim_Data: data_key, data_completa, ano, mes, dia, dia_da_semana
- Dim_Veiculo: veiculo_key, vehicle_type
- Dim_Status: status_key, booking_status, motivos de cancelamento
- Dim_Localizacao: local_key, local_nome
- Dim_Pagamento: pagamento_key, payment_method
