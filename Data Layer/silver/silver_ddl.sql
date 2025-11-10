-- Silver DDL: estrutura de tabela para dados tratados (camada silver)
CREATE SCHEMA IF NOT EXISTS silver;

CREATE TABLE IF NOT EXISTS silver.uber_silver (
    booking_id VARCHAR(100) PRIMARY KEY,
    date DATE,
    time TIME,
    booking_status VARCHAR(100),
    customer_id VARCHAR(100),
    vehicle_type VARCHAR(100),
    pickup_location VARCHAR(255),
    drop_location VARCHAR(255),
    avg_vtat DOUBLE PRECISION,
    avg_ctat DOUBLE PRECISION,
    reason_for_cancelling_by_customer VARCHAR(255),
    driver_cancellation_reason VARCHAR(255),
    incomplete_rides_reason VARCHAR(255),
    booking_value NUMERIC(12,2),
    ride_distance DOUBLE PRECISION,
    driver_ratings DOUBLE PRECISION,
    customer_rating DOUBLE PRECISION,
    payment_method VARCHAR(100)
);

-- Índice por localização para acelerar consultas
CREATE INDEX IF NOT EXISTS idx_uber_silver_pickup ON silver.uber_silver(pickup_location);
CREATE INDEX IF NOT EXISTS idx_uber_silver_drop ON silver.uber_silver(drop_location);
