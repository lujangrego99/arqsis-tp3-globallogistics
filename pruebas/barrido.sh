#!/usr/bin/env bash
# Barrido de concurrencia para ubicar el punto en que se degradan los tiempos de respuesta.
# Cada punto corre 10 segundos. Misma herramienta (ab) y mismo destino que pruebas/carga.sh. Resumen en resultados/barrido.csv.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p resultados/barrido

RED=globallogistics_default
URL=http://balanceador/

docker run --rm --network "$RED" httpd:2.4-alpine ab -k -n 20000 -c 100 "$URL" > /dev/null  # calentamiento

echo "concurrencia,req_por_seg,latencia_promedio_ms,p50_ms,p95_ms,p99_ms,max_ms,fallidas" > resultados/barrido.csv
for c in 1 10 25 50 100 250 500 1000; do
  out="resultados/barrido/c$c.txt"
  docker run --rm --network "$RED" httpd:2.4-alpine ab -k -t 10 -n 10000000 -c "$c" -s 30 "$URL" > "$out" 2>&1
  rps=$(awk '/Requests per second/ {print $4}' "$out")
  prom=$(awk '/^Total:/ {print $3}' "$out")
  p() { awk -v k="$1%" '$1==k {print $2}' "$out"; }
  fail=$(awk '/Failed requests/ {print $3}' "$out")
  echo "$c,$rps,$prom,$(p 50),$(p 95),$(p 99),$(p 100),$fail" | tee -a resultados/barrido.csv
done
