#!/usr/bin/env bash
# Pruebas de carga con Apache Benchmark (ab) contra el balanceador.
# ab corre en un contenedor (imagen httpd) dentro de la red del compose,
# así no hace falta instalarlo. Los resultados quedan en resultados/.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p resultados

# docker compose (v2) o docker-compose (v1), el que esté instalado
if docker compose version >/dev/null 2>&1; then DC="docker compose"; else DC="docker-compose"; fi
RED=globallogistics_default
URL=http://balanceador/

ab() {  # ab <archivo> <peticiones> <concurrencia>
  echo ">> $1: $2 peticiones, $3 concurrentes"
  # Uso de CPU de los contenedores del TP a mitad de la prueba
  ( until docker inspect ab-carga >/dev/null 2>&1; do sleep 0.2; done; sleep 2; docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' \
      $($DC ps -q) ab-carga > "resultados/$1-cpu.txt" ) &
  docker run --rm --name ab-carga --network "$RED" httpd:2.4-alpine \
    ab -k -n "$2" -c "$3" -s 30 "$URL" > "resultados/$1.txt"
  wait
  grep -E "Requests per second|Failed requests|Total: " "resultados/$1.txt"
  grep -E "^ +(50|95|99|100)%" "resultados/$1.txt"
}

# Calentamiento (no se mide): JIT de Node y conexiones keepalive del balanceador
docker run --rm --network "$RED" httpd:2.4-alpine ab -k -n 20000 -c 100 "$URL" > /dev/null

# Escenario 1: concurrencia moderada (100 usuarios concurrentes)
ab escenario1-c100 150000 100

# Escenario 2: concurrencia extrema (saturación de CPU de las réplicas)
ab escenario2-c1000 200000 1000
