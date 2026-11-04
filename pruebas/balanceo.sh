#!/usr/bin/env bash
# Envía peticiones consecutivas al balanceador y muestra qué instancia respondió cada una.
N=${1:-9}
for i in $(seq 1 "$N"); do
  echo "Petición $i -> $(curl -s http://localhost:8080/)"
done
