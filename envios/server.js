// Microservicio "Envíos" de GlobalLogistics S.A. (API REST mínima, sin dependencias).
// GET /        -> endpoint principal: devuelve el hostname (= ID del contenedor) que atendió.
// GET /health  -> health check usado por Docker y por el balanceador.
const http = require("http");
const os = require("os");

const PORT = process.env.PORT || 3000;
const INSTANCIA = os.hostname();

function responder(res, status, body) {
  const json = JSON.stringify(body);
  res.writeHead(status, {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(json),
  });
  res.end(json);
}

http
  .createServer((req, res) => {
    if (req.method === "GET" && req.url === "/") {
      return responder(res, 200, { servicio: "envios", instancia: INSTANCIA });
    }
    if (req.method === "GET" && req.url === "/health") {
      return responder(res, 200, { status: "UP", instancia: INSTANCIA });
    }
    responder(res, 404, { error: "no encontrado" });
  })
  .listen(PORT, () => console.log(`envios escuchando en :${PORT} (instancia ${INSTANCIA})`));
