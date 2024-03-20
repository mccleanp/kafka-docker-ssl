#!/bin/bash
set -euf -o pipefail

cd "$(dirname "$0")/../secrets/" || exit

echo "🔖  Generating some fake certificates and other secrets."
sleep 2

TLD="local"
PASSWORD="awesomekafka"

# Generate CA key
openssl req -new -x509 -keyout fake-ca-1.key \
	-out fake-ca-1.crt -days 9999 \
	-subj "/CN=ca1.${TLD}/OU=CIA/O=REA/L=Melbourne/S=VIC/C=AU" \
	-passin pass:$PASSWORD -passout pass:$PASSWORD

for i in broker control-center metrics schema-registry kafka-tools rest-proxy; do
	echo ${i}
	# Create keystores
	keytool -genkey -noprompt \
		-alias ${i} \
		-dname "CN=${i}.${TLD}, OU=CIA, O=REA, L=Melbourne, S=VIC, C=AU" \
		-keystore kafka.${i}.keystore.jks \
		-keyalg RSA \
		-storepass $PASSWORD \
		-keypass $PASSWORD

	# Create CSR, sign the key and import back into keystore
	keytool -keystore kafka.$i.keystore.jks -alias $i -certreq -file $i.csr -storepass $PASSWORD -keypass $PASSWORD <<EOF
yes
EOF

	openssl x509 -req -CA fake-ca-1.crt -CAkey fake-ca-1.key -in $i.csr -out $i-ca1-signed.crt -days 9999 -CAcreateserial -passin pass:$PASSWORD

	keytool -keystore kafka.$i.keystore.jks -alias CARoot -import -file fake-ca-1.crt -storepass $PASSWORD -keypass $PASSWORD <<EOF
yes
EOF

	keytool -keystore kafka.$i.keystore.jks -alias $i -import -file $i-ca1-signed.crt -storepass $PASSWORD -keypass $PASSWORD <<EOF
yes
EOF

	# Create truststore and import the CA cert.
	keytool -keystore kafka.$i.truststore.jks -alias CARoot -import -file fake-ca-1.crt -storepass $PASSWORD -keypass $PASSWORD <<EOF
yes
EOF

	echo $PASSWORD >${i}_sslkey_creds
	echo $PASSWORD >${i}_keystore_creds
	echo $PASSWORD >${i}_truststore_creds
done

# Create regular SSL client cert without keystore
openssl genrsa -des3 -passout "pass:$PASSWORD" -out my_client.key 2048 
openssl req -key my_client.key -new -out my_client.req \
	-subj "/CN=ca1.${TLD}/OU=CIA/O=REA/L=Melbourne/S=VIC/C=AU" \
	-passin pass:$PASSWORD -passout pass:$PASSWORD

openssl x509 -req -passin "pass:$PASSWORD" -in my_client.req -CA fake-ca-1.crt -CAkey fake-ca-1.key -CAcreateserial -out my_client.pem -days 10000


echo "✅  All done."
