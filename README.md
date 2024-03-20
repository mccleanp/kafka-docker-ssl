## 💥 Local Kafka Cluster in Docker with SSL

> [!NOTE]
> This was forked from https://github.com/cloud-on-prem/kafka-docker-ssl.

This project sets up a local Kafka cluster with Zookeeper, Confluent Control Center, Confluent Rest Proxy, and Confluent Schema Registry.  

Also included:
  - Kafka Tools (CLI tools) for administration

### Initial set-up

0. Ensure Docker and Docker Compose are installed
1. Build the Docker containers.
   ```sh
     docker-compose build.
   ```

### Starting up

0. One-time set-up (or if you want to generate new secrets)
  ```sh
    ./auto/create-certs.sh
  ```

1. Bring the cluster up.
  ```sh
    ./auto/up.sh
  ```

Note: By default, some services like `kafka-tools` is scaled down as they are not useful to be up as a service.  
See below to learn more about running `kafka-tools` for admin tasks.


### Logs

```sh
  ./auto/logs.sh

```

### Shutting Down

```sh
  ./auto/down.sh

```
### Accessing the services

1. To access the Control Center, visit [http://localhost:9021](http://localhost:9021)
2. To access the Rest Proxy, interact with [http://localhost:8082](http://localhost:8082)
3. Broker is available at `localhost:19092`

### Running Kafka Tools

```sh
  ./auto/kafka-tools.sh <tool-name> <arguments>
  # Note that the broker is available at "broker:29092"
  # Example, list all topics
  ./auto/kafka-tools.sh kafka-topics --command-config /etc/kafka/config/command.properties --bootstrap-server broker.local:19092 --list
  # Example, create a topic
  ./auto/kafka-tools.sh kafka-topics --bootstrap-server=broker.local:19092 --command-config /etc/kafka/config/command.properties --create --topic UserEmail --partitions 1 --replication-factor 1
  # Example, delete a Topic
  ./auto/kafka-tools.sh kafka-topics --bootstrap-server=broker.local:19092 --command-config /etc/kafka/config/command.properties --delete --topic UserEmail
-
```

### Additional Kafka client

An additional set of SSL credentials are provided for another Kafka client. You can use these to connect an external kafka client to the the cluster. For example, using kcat to consume messages on a topic:

```sh
kcat -b "broker.local:19092" -X security.protocol=SSL -X ssl.ca.location=./secrets/fake-ca-1.crt -X ssl.certificate.location=./secrets/my_client.pem -X ssl.key.location=./secrets/my_client.key -X ssl.key.password=awesomekafka -t my_topic
```

Note that you also need to add `broker.local` to your hosts file to resolve to localhost.

