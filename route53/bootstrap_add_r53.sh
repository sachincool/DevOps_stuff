#!/bin/bash -xe
sudo snap install aws-cli --classic
sudo apt update -q && sudo apt install -qy jq 
# pidof python3 >&-  && echo "Service is running Exiting....." ;exit 0 || echo "Service is not running"

WORKDIR=/home/ubuntu
cd $WORKDIR
# Test Server
cat > server.py <<-EOF
from http.server import BaseHTTPRequestHandler, HTTPServer
import time

hostName = "0.0.0.0"
serverPort = 80

class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(bytes("<html><head><title>https://pythonbasics.org</title></head>", "utf-8"))
        self.wfile.write(bytes("<p>Request: %s</p>" % self.path, "utf-8"))
        self.wfile.write(bytes("<body>", "utf-8"))
        self.wfile.write(bytes("<p>This is an example `hostname`.</p>", "utf-8"))
        self.wfile.write(bytes("</body></html>", "utf-8"))

if __name__ == "__main__":
    webServer = HTTPServer((hostName, serverPort), MyServer)
    print("Server started http://%s:%s" % (hostName, serverPort))

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server stopped.")

EOF

sudo python3 server.py & 


record_name="backend.server.sachin.cool."
# I deleted this Ofcourse

DNS=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`

#zone_name="BLAH"

	action=${action:-UPSERT}
	record_type=${record_type:-A}
	ttl=${ttl:-60}

	record_value=$(aws route53 list-resource-record-sets --hosted-zone-id $zone_name --query "ResourceRecordSets[?Name == '"$record_name"']" | jq -c ".[].ResourceRecords | .+ [{\"Value\": \"$DNS\"}]")


function change_batch() {
	jq -c -n "{\"Changes\": [{\"Action\": \"$action\", \"ResourceRecordSet\": {\"Name\": \"$record_name\", \"Type\": \"$record_type\", \"TTL\": $ttl, \"ResourceRecords\": $record_value } } ] }"
}

function update_route53(){
 aws route53 change-resource-record-sets --hosted-zone-id $zone_name \
	 --change-batch $(change_batch)
}


update_route53
