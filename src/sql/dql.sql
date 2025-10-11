-- Contagem de Corridas por Status

SELECT
    "Booking_Status",
    COUNT("Booking_ID") AS quantidade
FROM
    uber
GROUP BY
    "Booking_Status"
ORDER BY
    quantidade DESC;

-- Contagem de Corridas por Tipo de Veículo

SELECT
    "Vehicle_Type",
    COUNT("Booking_ID") AS quantidade_corridas
FROM
    uber
GROUP BY
    "Vehicle_Type"
ORDER BY
    quantidade_corridas DESC;

-- Avaliação Média dos Motoristas por Tipo de Veículo

SELECT
    "Vehicle_Type",
    ROUND(AVG("Driver_Ratings")::numeric, 2) AS avaliacao_media_motorista
FROM
    uber
WHERE
    "Booking_Status" = 'Completed' -- Apenas corridas completadas têm avaliação
GROUP BY
    "Vehicle_Type"
HAVING
    COUNT("Booking_ID") > 100 -- Filtra tipos de veículo com poucas corridas para relevância estatística
ORDER BY
    avaliacao_media_motorista DESC;