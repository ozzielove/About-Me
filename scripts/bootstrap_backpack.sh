#!/bin/sh
set -e
NAMESPACE=backpack

DB_POD=$(kubectl get pods -n $NAMESPACE -l app=postgres -o jsonpath='{.items[0].metadata.name}')
if [ -n "$DB_POD" ]; then
  kubectl exec -n $NAMESPACE "$DB_POD" -- psql -U postgres -c "CREATE SCHEMA IF NOT EXISTS backpack;" || true
fi

echo "name,url" > products.csv
echo "demo,https://example.com" >> products.csv

OLLAMA="http://ollama.backpack.svc.cluster.local:11434"
curl -X POST "$OLLAMA/agents/register" -d '{"name":"sentinel"}' || true
