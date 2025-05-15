#!/bin/bash
# execute-flink-sql.sh - Execute Flink SQL queries

usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -o OPERATION    Operation to perform (execute, list, view)"
  echo "  -f FILE_NAME    SQL file name (required for execute and view)"
  echo "  -q SQL_QUERY    SQL query string or @FILE_PATH to read from file"
  exit 1
}

LOCAL_SQL_DIR="/opt/jenkins/flink-sql"
JOB_MANAGER="jobmanager"

while getopts "o:f:q:" opt; do
  case $opt in
    o) OPERATION=$OPTARG ;;
    f) FILE_NAME=$OPTARG ;;
    q) QUERY_ARG=$OPTARG ;;
    *) usage ;;
  esac
done

if [ -z "$OPERATION" ]; then
  echo "Error: Operation (-o) is required"
  usage
fi

if [ "$OPERATION" != "list" ] && [ -z "$FILE_NAME" ]; then
  echo "Error: File name (-f) is required for $OPERATION operation"
  usage
fi

if [ "$OPERATION" = "execute" ] && [ -z "$QUERY_ARG" ]; then
  echo "Error: SQL query (-q) is required for execute operation"
  usage
fi

if [ ! -z "$FILE_NAME" ] && [[ ! "$FILE_NAME" =~ \.sql$ ]]; then
  FILE_NAME="${FILE_NAME}.sql"
fi

mkdir -p "$LOCAL_SQL_DIR"

get_sql_query() {
  if [[ "$QUERY_ARG" == @* ]]; then
    local file_path="${QUERY_ARG:1}"
    if [ -f "$file_path" ]; then
      cat "$file_path"
    else
      echo "Error: SQL file $file_path not found"
      exit 1
    fi
  else
    echo "$QUERY_ARG"
  fi
}

case "$OPERATION" in
  execute)
    SQL_QUERY=$(get_sql_query)
    
    LOCAL_SQL_FILE="${LOCAL_SQL_DIR}/${FILE_NAME}"
    echo "$SQL_QUERY" > "$LOCAL_SQL_FILE"
    echo "Saved SQL query to local file: $LOCAL_SQL_FILE"
    echo "Executing SQL query..."
    
    OUTPUT_FILE=$(mktemp)
    
    /opt/flink/bin/sql-client.sh gateway --endpoint http://jobmanager:8082 -f "${LOCAL_SQL_FILE}" > "$OUTPUT_FILE" 2>&1
    SQL_EXIT_CODE=$?
    
    cat "$OUTPUT_FILE"
    
    if grep -q '\[ERROR\]' "$OUTPUT_FILE"; then
      echo "SQL execution failed with errors."
      rm "$OUTPUT_FILE"
      exit 1
    fi
    
    rm "$OUTPUT_FILE"
    
    exit $SQL_EXIT_CODE
    ;;
    
  list)
    echo "SQL files in Jenkins container:"
    ls -la "$LOCAL_SQL_DIR" | grep "\.sql$" || echo "No SQL files found"
    ;;
    
  view)
    LOCAL_SQL_FILE="${LOCAL_SQL_DIR}/${FILE_NAME}"
    
    if [ -f "$LOCAL_SQL_FILE" ]; then
      echo "Contents of local SQL file ${FILE_NAME}:"
      cat "$LOCAL_SQL_FILE"
    else
      echo "Error: SQL file ${FILE_NAME} not found in either local or remote storage"
      exit 1
    fi
    ;;
    
  *)
    echo "Error: Unknown operation: $OPERATION"
    usage
    ;;
esac