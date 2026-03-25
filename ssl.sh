#!/bin/bash

# Check for arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <hostname> <port>"
    exit 1
fi

HOSTNAME="$1"
PORT="$2"

# Generate X.509 Certificate
echo "[*] Generating certificate for $HOSTNAME..."
openssl genrsa -out "${HOSTNAME}.key" 2048
openssl req -new -key "${HOSTNAME}.key" -out "${HOSTNAME}.csr" -subj "/CN=${HOSTNAME}"
openssl x509 -req -in "${HOSTNAME}.csr" -signkey "${HOSTNAME}.key" -out "${HOSTNAME}.crt" -days 365
echo "[*] Certificate generated: ${HOSTNAME}.crt / ${HOSTNAME}.key"

# Function to handle a client connection
handle_client() {
    echo "[*] Waiting for client connections on ${HOSTNAME}:${PORT}..."
    # Using socat for SSL/TLS server
    socat -v OPENSSL-LISTEN:${PORT},cert=${HOSTNAME}.crt,key=${HOSTNAME}.key,verify=0,fork SYSTEM:'echo "Hello from the server!"'
}

# Start server
handle_client
