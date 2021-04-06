ARG BASE_IMAGE
FROM $BASE_IMAGE

ARG JAVA_VERSION
ARG SCALA_VERSION
ARG SPARK_VERSION
ARG HADOOP_VERSION

ARG spark_uid=185

# disable tzdata configuration
ENV DEBIAN_FRONTEND=noninteractive 
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,DL3013
RUN set -ex && \
    sed -i 's/http:\/\/deb.\(.*\)/https:\/\/deb.\1/g' /etc/apt/sources.list && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt-get install --no-install-recommends -qq -y bash tini libc6 libpam-modules krb5-user libnss3 procps curl zip unzip python3-pip && \
    pip3 install --no-cache-dir --upgrade pip setuptools && \
    mkdir -p /opt/spark/work-dir && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/* 

ENV HOME=/tmp/sdkman

RUN curl -s https://get.sdkman.io | bash
RUN chmod a+x "$HOME/.sdkman/bin/sdkman-init.sh"
RUN . "$HOME/.sdkman/bin/sdkman-init.sh" && sdk install java ${JAVA_VERSION}
RUN . "$HOME/.sdkman/bin/sdkman-init.sh" && sdk install scala ${SCALA_VERSION}
RUN . "$HOME/.sdkman/bin/sdkman-init.sh" && sdk use java ${JAVA_VERSION}

# Spark installation
WORKDIR /tmp
RUN curl -O "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"
RUN tar xvf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}/* /opt/spark && \
    rm "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \ 
    rm -rf /spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} && \
    cp /opt/spark/kubernetes/dockerfiles/spark/*.sh /opt/

# Configure Spark
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
# # additional sh script for future spark 3.1.1
# RUN chmod a+x /opt/decom.sh

ENTRYPOINT [ "/opt/entrypoint.sh" ]
USER ${spark_uid}
