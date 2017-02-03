# Builds an image for Apache Kafka from binary distribution.
#

FROM openjdk:8-jre-alpine

ARG KAFKA_VERSION=0.10.1.1
ARG KAFKA_SCALA_VERSION=2.11
LABEL name="kafka" \
      version=$KAFKA_VERSION
      maintainer "Jack Pickett <p1ck@users.noreply.github.com>"

ENV KAFKA_VERSION=$KAFKA_VERSION KAFKA_SCALA_VERSION=$KAFKA_SCALA_VERSION JMX_PORT=7203
ENV KAFKA_RELEASE kafka_${KAFKA_SCALA_VERSION}-${KAFKA_VERSION}

RUN apk add --no-cache bash && \
    mkdir /data /logs

# Download Kafka binary distribution
ADD http://www.us.apache.org/dist/kafka/${KAFKA_VERSION}/${KAFKA_RELEASE}.tgz /tmp/
ADD https://dist.apache.org/repos/dist/release/kafka/${KAFKA_VERSION}/${KAFKA_RELEASE}.tgz.sha1 /tmp/

WORKDIR /tmp

# Check artifact digest integrity
# Converts from gpg digest output format to sha1sum input
RUN awk -F':' '{gsub(" ","",$0);print tolower($2) "  " $1}' ${KAFKA_RELEASE}.tgz.sha1 | sha1sum -c -

# Install Kafka to /kafka
RUN tar -zxf ${KAFKA_RELEASE}.tgz && \
    mv ${KAFKA_RELEASE}/ /kafka && \
    rm -rf kafka_*

ADD config /kafka/config
ADD start.sh /start.sh

# Set up a user to run Kafka
RUN addgroup kafka && \
    adduser -D -h /kafka -G kafka -s /bin/false kafka && \
    chown -R kafka:kafka /kafka /data /logs
USER kafka
ENV PATH /kafka/bin:$PATH
WORKDIR /kafka

# broker, jmx
EXPOSE 9092 ${JMX_PORT}
VOLUME [ "/data", "/logs" ]

CMD ["/start.sh"]

