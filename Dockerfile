ARG BASE_IMAGE
FROM $BASE_IMAGE

ARG JAVA_VERSION
ARG SCALA_VERSION
ARG SPARK_VERSION
ARG HADOOP_VERSION

ARG spark_uid=185
    # sed -i 's/http:\/\/deb.\(.*\)/https:\/\/deb.\1/g' /etc/apt/sources.list && \
    # ln -s /lib /lib64 && \

# disable tzdata configuration
ENV DEBIAN_FRONTEND=noninteractive 

RUN set -ex && \
    apt update && apt-get upgrade -y && \
    apt install -qq -y bash tini libc6 libpam-modules krb5-user libnss3 procps curl zip unzip python3-pip && \
    pip3 install --upgrade pip setuptools && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/work-dir && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/* 

ENV HOME=/tmp/sdkman

RUN curl -s https://get.sdkman.io | bash
RUN chmod a+x "$HOME/.sdkman/bin/sdkman-init.sh"
RUN source "$HOME/.sdkman/bin/sdkman-init.sh" && sdk install java ${JAVA_VERSION}
RUN source "$HOME/.sdkman/bin/sdkman-init.sh" && sdk install scala ${SCALA_VERSION}
RUN source "$HOME/.sdkman/bin/sdkman-init.sh" && sdk use java ${JAVA_VERSION}

# Spark installation
WORKDIR /tmp
# Using the preferred mirror to download Spark
# hadolint ignore=SC2046
RUN curl -O "https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"
RUN tar xvf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}/* /opt/spark && \
    rm "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \ 
    rm -rf /spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} && \
    cp /opt/spark/kubernetes/dockerfiles/spark/*.sh /opt/

# Configure Spark
ENV SPARK_HOME=/opt/spark
# ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin


WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh

ENTRYPOINT [ "/opt/entrypoint.sh" ]