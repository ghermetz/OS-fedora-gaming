#!/usr/bin/python3
# fedora-gaming — apps/naruto-httpdns.py — relais local pour le chargement de Naruto Online (blocage à 14 %).
#
# Au chargement, le jeu interroge le service DNS de Tencent (DNSPod HTTPDNS) à
# l'adresse 182.254.116.117. Toute requête qui porte ce nom (en-tête Host) est
# coupée en route, quelle que soit l'adresse visée, alors que le même service
# répond normalement sous ses autres adresses. Le pare-feu (naruto-reseau.sh)
# envoie donc ces requêtes ici, et ce relais les transmet au même service, à
# une adresse qui fonctionne, avec un en-tête correct.
# N'écoute que sur la machine (127.0.0.1:8117) et ne parle qu'à Tencent.

import http.client
import http.server
import socketserver

ECOUTE = ("127.0.0.1", 8117)
SERVEURS = ["119.29.29.29", "182.254.116.116", "182.254.118.118"]  # même service DNSPod
SANS_TRANSFERT = {"connection", "keep-alive", "proxy-connection", "transfer-encoding", "upgrade"}


class Relais(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.0"

    def do_GET(self):
        for serveur in SERVEURS:
            try:
                conn = http.client.HTTPConnection(serveur, 80, timeout=5)
                entetes = {k: v for k, v in self.headers.items()
                           if k.lower() not in SANS_TRANSFERT and k.lower() != "host"}
                entetes["Host"] = serveur
                conn.request("GET", self.path, headers=entetes)
                rep = conn.getresponse()
                corps = rep.read()
            except OSError:
                continue
            self.send_response(rep.status, rep.reason)
            for k, v in rep.getheaders():
                if k.lower() not in SANS_TRANSFERT and k.lower() != "content-length":
                    self.send_header(k, v)
            self.send_header("Content-Length", str(len(corps)))
            self.end_headers()
            self.wfile.write(corps)
            return
        self.send_error(502, "Service DNS de Tencent injoignable")

    def log_message(self, fmt, *args):
        pass


class Serveur(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True


if __name__ == "__main__":
    Serveur(ECOUTE, Relais).serve_forever()
