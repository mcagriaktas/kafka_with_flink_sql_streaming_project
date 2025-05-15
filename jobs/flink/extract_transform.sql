-- Set execution properties for high throughput
SET 'execution.checkpointing.interval' = '30s';
SET 'execution.checkpointing.unaligned' = 'true';
SET 'execution.checkpointing.mode' = 'AT_LEAST_ONCE';
SET 'execution.checkpointing.min-pause' = '30s';
SET 'execution.checkpointing.max-concurrent-checkpoints' = '1';
SET 'execution.checkpointing.timeout' = '10m';

-- Step 1: Create the Iceberg catalog
CREATE CATALOG IF NOT EXISTS iceberg_catalog WITH (
    'type' = 'iceberg',
    'catalog-type' = 'hive',
    'uri' = 'thrift://hms:9083',
    'warehouse' = 'hdfs://namenode:9000/warehouse/iceberg',
    'default-database' = 'etl_db'
);

-- Step 2: Create the target database
CREATE DATABASE IF NOT EXISTS iceberg_catalog.etl_db;

-- Step 3: Optimized Kafka source table
CREATE TABLE raw_data (
    `key` INT,
    user_id STRING,
    item_id STRING,
    `timestamp` TIMESTAMP(3),
    WATERMARK FOR `timestamp` AS `timestamp` - INTERVAL '5' SECONDS
) WITH (
    'connector' = 'kafka',
    'topic' = 'raw-data',
    'properties.bootstrap.servers' = 'kafka1:9092,kafka2:9092,kafka3:9092',
    'properties.group.id' = 'flink-job1-raw-data-reader',
    'scan.startup.mode' = 'group-offsets',
    
    -- High-performance consumer settings
    'properties.enable.auto.commit' = 'false',
    'properties.auto.offset.reset' = 'earliest',
    'properties.fetch.min.bytes' = '1',  -- Don't wait for batching
    'properties.fetch.max.wait.ms' = '100',  -- Reduced wait time
    'properties.max.poll.records' = '5000',  -- Increased batch size
    'properties.receive.buffer.bytes' = '8388608',  -- 8MB buffer
    'properties.max.partition.fetch.bytes' = '1048576',  -- 1MB per partition
    'properties.session.timeout.ms' = '30000',
    'properties.request.timeout.ms' = '40000',
    
    -- Format settings
    'format' = 'json',
    'json.fail-on-missing-field' = 'false',
    'json.ignore-parse-errors' = 'true',
    
    -- IMPORTANT: Source parallelism
    'sink.parallelism' = '12'
);


-- Step 4: Optimized DLQ Kafka Sink
CREATE TABLE raw_data_dlq (
    `key` INT,
    original_user_id STRING,
    original_item_id STRING,
    original_timestamp TIMESTAMP(3),
    error_message STRING
) WITH (
    'connector' = 'kafka',
    'topic' = 'raw-data-dlq',
    'properties.bootstrap.servers' = 'kafka1:9092,kafka2:9092,kafka3:9092',
    'format' = 'json',
    'sink.parallelism' = '4',  -- Lower parallelism for DLQ
    
    -- Producer optimizations
    'properties.batch.size' = '32768',  -- 32KB batches
    'properties.linger.ms' = '10',  -- Small linger time
    'properties.compression.type' = 'lz4',
    'properties.buffer.memory' = '67108864'  -- 64MB
);

-- Step 5: Optimized Iceberg table (switch back to CoW for streaming)
CREATE TABLE IF NOT EXISTS iceberg_catalog.etl_db.extract_transform_data (
    `key` INT,
    user_id INT,
    item_id INT,
    `timestamp` TIMESTAMP(3)
) WITH (
    'format' = 'parquet',
    'format-version' = '2',
    'sink.parallelism' = '12',
    'write.format.default' = 'parquet',
    'write.parquet.compression-codec' = 'snappy',
    
    -- File size optimization
    'write.target-file-size-bytes' = '67108864',  -- 64MB (smaller files for faster commits)
    'write.parquet.row-group-size-bytes' = '8388608',  -- 8MB row groups
    
    -- Distribution for better parallelism
    'write.distribution-mode' = 'hash',
    
    -- Faster commits
    'commit.manifest.target-size-bytes' = '8388608',  -- 8MB manifests
    'commit.manifest-merge.enabled' = 'false',  -- Disable for speed
    'commit.retry.num-retries' = '2',
    'commit.retry.min-wait-ms' = '50',
    
    -- Minimal metadata tracking
    'write.metadata.delete-after-commit.enabled' = 'false',
    'history.expire.min-snapshots-to-keep' = '3',
    'history.expire.max-snapshot-age-ms' = '180000'  -- 3 minutes
);

-- Step 6: Process data with explicit DLQ routing
-- First, create a view that attempts transformations and identifies errors
CREATE TEMPORARY VIEW processed_data AS
SELECT
    `key`,
    user_id AS original_user_id,
    item_id AS original_item_id,
    `timestamp` AS original_timestamp,
    REGEXP_EXTRACT(user_id, '([0-9]+)', 1) AS extracted_user_id,
    REGEXP_EXTRACT(item_id, '([0-9]+)', 1) AS extracted_item_id,
    CASE
        WHEN REGEXP_EXTRACT(user_id, '([0-9]+)', 1) IS NULL THEN 'User ID format invalid'
        WHEN REGEXP_EXTRACT(item_id, '([0-9]+)', 1) IS NULL THEN 'Item ID format invalid'
        ELSE NULL
    END AS error_message
FROM raw_data;

-- Step 7: Insert valid records into Iceberg
INSERT INTO iceberg_catalog.etl_db.extract_transform_data /*+ OPTIONS('parallelism'='24') */
SELECT
    `key`,
    CAST(extracted_user_id AS INT) AS user_id,
    CAST(extracted_item_id AS INT) AS item_id,
    original_timestamp AS `timestamp`
FROM processed_data
WHERE error_message IS NULL 
AND extracted_user_id IS NOT NULL 
AND extracted_item_id IS NOT NULL;

-- Step 8: Insert invalid records into DLQ
INSERT INTO raw_data_dlq
SELECT
    `key`,
    original_user_id,
    original_item_id,
    original_timestamp,
    COALESCE(
        error_message,
        CASE
            WHEN extracted_user_id IS NULL OR extracted_item_id IS NULL THEN 'Extraction failed'
            ELSE 'Unknown transformation error'
        END
    ) AS error_message
FROM processed_data
WHERE error_message IS NOT NULL 
   OR extracted_user_id IS NULL 
   OR extracted_item_id IS NULL;