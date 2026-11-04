# TP3 — Despliegue de Arquitectura Cloud-Native (GlobalLogistics S.A.)

Arquitectura de Sistemas · Licenciatura en Sistemas de Información · Ciclo 2026
Equipo: Lujan, Gregorio · Moya, Manuel

Entorno de prueba con **un (1) balanceador de carga NGINX** delante de **tres (3) réplicas**
del microservicio `envios` (API REST en Node.js). El endpoint principal `GET /` devuelve el
hostname del contenedor que atendió la petición (en Docker, el hostname es el ID del contenedor).

```
                 ┌──────────────► envios-1 (:3000)
cliente ──► balanceador (NGINX :8080) ──► envios-2 (:3000)
                 └──────────────► envios-3 (:3000)
```

## Estructura

| Archivo | Contenido |
|---|---|
| `docker-compose.yml` | Manifiesto IaC: 1 balanceador + 3 réplicas, límites de CPU/memoria y health checks |
| `envios/server.js`, `envios/Dockerfile` | Microservicio (API REST): `GET /` (hostname) y `GET /health` |
| `nginx/nginx.conf` | Balanceador: round robin + health checks pasivos (`max_fails` / `fail_timeout`) |
| `pruebas/balanceo.sh` | Peticiones consecutivas al balanceador para ver la rotación de instancias |
| `pruebas/carga.sh` | Pruebas de carga con Apache Benchmark (`ab`), escenarios moderado y extremo |
| `resultados/` | Salidas de `ab` y uso de CPU durante cada prueba |

## Requisitos

- Docker con Docker Compose.
- `curl` (para `pruebas/balanceo.sh`). `ab` **no** hace falta instalarlo: `pruebas/carga.sh` lo
  corre dentro de un contenedor `httpd:2.4-alpine` conectado a la red del compose.

## 1. Levantar el entorno

```bash
docker-compose up -d          # o: docker compose up -d
docker-compose ps             # las 4 instancias deben quedar "healthy"
```

El balanceador queda publicado en `http://localhost:8080`.

## 2. Verificar el balanceo

```bash
./pruebas/balanceo.sh         # 9 peticiones consecutivas
# o a mano:
curl http://localhost:8080/
```

Cada respuesta trae `"instancia": "<id del contenedor>"`; las peticiones consecutivas rotan entre
los tres IDs. Para relacionar cada ID con su réplica: `docker ps --format '{{.ID}}  {{.Names}}'`.

## 3. Reproducir las pruebas de carga

```bash
./pruebas/carga.sh
```

Ejecuta los dos escenarios y guarda los resultados en `resultados/`:

| Escenario | Comando `ab` | Archivo |
|---|---|---|
| 1. Concurrencia moderada | `ab -k -n 150000 -c 100 http://balanceador/` | `resultados/escenario1-c100.txt` |
| 2. Concurrencia extrema (saturación de CPU) | `ab -k -n 200000 -c 1000 http://balanceador/` | `resultados/escenario2-c1000.txt` |

Para cada escenario también se guarda un `docker stats` tomado durante la prueba
(`resultados/*-cpu.txt`). La latencia promedio es la fila `Total` (mean) y los percentiles p95 y
p99 están en la tabla `Percentage of the requests served within a certain time`.

Equivalente sin el script (con `ab` instalado en el host):

```bash
ab -k -n 150000 -c 100  http://localhost:8080/
ab -k -n 200000 -c 1000 http://localhost:8080/
```

## 4. Apagar

```bash
docker-compose down
```
