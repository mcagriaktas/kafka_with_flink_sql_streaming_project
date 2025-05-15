#!/bin/bash
set -e

FLINK_LIB_DIR=/opt/flink/lib
FLINK_VERSION=1.20.0
HADOOP_VERSION=3.4.1
ICEBERG_VERSION=1.8.1
HIVE_VERSION=3.1.3

mkdir -p $FLINK_LIB_DIR

download_with_check() {
    local url=$1
    local target_dir=$2
    local jar_name=$(basename "$url")
    
    echo "Downloading $jar_name..."
    
    if curl --output /dev/null --silent --head --fail "$url"; then
        wget -q "$url" -P "$target_dir" || {
            echo "ERROR: FAILED TO DOWNLOAD $jar_name"
            return 1
        }
        echo "✓ Successfully downloaded $jar_name"
    else
        echo "ERROR: URL NOT FOUND OR INACCESSIBLE: $url"
        return 1
    fi
}

declare -a dependencies=(
    # Core Iceberg dependencies
    "https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-flink-runtime-1.20/$ICEBERG_VERSION/iceberg-flink-runtime-1.20-$ICEBERG_VERSION.jar"
    
    # Core Hadoop dependencies
    "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/$HADOOP_VERSION/hadoop-common-$HADOOP_VERSION.jar"
    "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-hdfs-client/$HADOOP_VERSION/hadoop-hdfs-client-$HADOOP_VERSION.jar"
    "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-auth/$HADOOP_VERSION/hadoop-auth-$HADOOP_VERSION.jar"
    "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-client-runtime/$HADOOP_VERSION/hadoop-client-runtime-$HADOOP_VERSION.jar"
    
    # Hadoop's missing dependencies
    "https://repo1.maven.org/maven2/org/apache/commons/commons-configuration2/2.10.0/commons-configuration2-2.10.0.jar"
    "https://repo1.maven.org/maven2/commons-logging/commons-logging/1.2/commons-logging-1.2.jar"
    
    # Hadoop MapReduce dependencies
    "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-mapreduce-client-core/$HADOOP_VERSION/hadoop-mapreduce-client-core-$HADOOP_VERSION.jar"
    
    # Hive Metastore dependencies
    "https://repo1.maven.org/maven2/org/apache/hive/hive-exec/$HIVE_VERSION/hive-exec-$HIVE_VERSION.jar"
    
    # Woodstox XML parser dependencies
    "https://repo1.maven.org/maven2/com/fasterxml/woodstox/woodstox-core/6.5.1/woodstox-core-6.5.1.jar"
    "https://repo1.maven.org/maven2/org/codehaus/woodstox/stax2-api/4.2.1/stax2-api-4.2.1.jar"
    
    # Caffeine cache library
    "https://repo1.maven.org/maven2/com/github/ben-manes/caffeine/caffeine/3.1.8/caffeine-3.1.8.jar"
    
    # libfb303 dependency
    "https://repo1.maven.org/maven2/org/apache/thrift/libfb303/0.9.3/libfb303-0.9.3.jar"
)

success=true
failed_downloads=()

for url in "${dependencies[@]}"; do
    if ! download_with_check "$url" "$FLINK_LIB_DIR"; then
        success=false
        failed_downloads+=("$(basename "$url")")
    fi
done

echo ""
echo "==== Download Summary ===="
if [ "$success" = true ]; then
    echo "✓ All dependencies successfully downloaded to $FLINK_LIB_DIR"
    exit 0
else
    echo "⚠ Some downloads failed. Failed dependencies:"
    for jar in "${failed_downloads[@]}"; do
        echo "  - $jar"
    done
    echo "Please check the Maven repository availability."
    exit 1
fi