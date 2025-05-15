-- Step 1: Create the Iceberg catalog
CREATE CATALOG iceberg_catalog WITH (
'type' = 'iceberg',
'catalog-type' = 'hive',
'uri' = 'thrift://hms:9083',
'warehouse' = 'hdfs://namenode:9000/warehouse/iceberg',
'default-database' = 'default'
);

-- Step 2: Create the target database (if not exists)
CREATE DATABASE IF NOT EXISTS iceberg_catalog.etl_db;

-- Step 3: Define the Kafka SINK table
CREATE TABLE clean_data (
    key INT,
    user_id INT,
    item_id INT,
    total_id INT,
    `timestamp` TIMESTAMP(3),
    processing_time TIMESTAMP(3)
) WITH (
    'connector' = 'kafka',
    'topic' = 'clean-data',
    'properties.bootstrap.servers' = 'kafka1:9092,kafka2:9092,kafka3:9092',
    'sink.partitioner' = 'default',
    'sink.delivery-guarantee' = 'at-least-once',

    -- Performance tuning
    'sink.parallelism' = '12',                    -- Match source parallelism
    'properties.batch.size' = '16384',            -- 16KB batches
    'properties.linger.ms' = '5',                 -- Small wait to group messages
    'properties.buffer.memory' = '67108864',      -- 64MB producer buffer
    'properties.compression.type' = 'lz4',        -- Fast compression
    
    -- Data Format
    'format' = 'json',
    'json.fail-on-missing-field' = 'false',
    'json.ignore-parse-errors' = 'true',
    'json.timestamp-format.standard' = 'SQL'
);

-- Step 4: Execute the streaming INSERT
INSERT INTO clean_data /*+ OPTIONS('sink.parallelism'='12') */
SELECT
    key,
    user_id,
    item_id,
    CAST((user_id * item_id) AS INT) as total_id,
    `timestamp`,
    CURRENT_TIMESTAMP + INTERVAL '3' HOUR AS processing_time
FROM iceberg_catalog.etl_db.extract_transform_data /*+ OPTIONS('streaming'='true', 'monitor-interval'='1s') */;