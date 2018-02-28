FROM ubuntu:16.04
MAINTAINER Simon Erhardt <hello@rootlogin.ch>

ENV TINI_VERSION=v0.16.1 \
  SWARM_CLIENT_VERSION=3.10 \
  JENKINS_MASTER=https://example.org \
  JENKINS_USERNAME=jenkins \
  JENKINS_PASSWORD=jenkins \
  JENKINS_EXECUTORS=1 \
  JENKINS_LABELS="" \
  JENKINS_NAME=example-slave

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/local/bin/tini
ADD https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 /usr/local/bin/jq

COPY root /

RUN set -ex \
  && chmod +x /usr/local/bin/run-container.sh \
  && chmod +x /usr/local/bin/tini \
  && chmod +x /usr/local/bin/jq

RUN dpkg --add-architecture i386

RUN set -ex \
  && apt-get update \
  && apt-get upgrade -y \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ansible \
    apt-transport-https \
    automake \
    autotools-dev \
    bc \
    bsdmainutils \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    faketime \
    fonts-tuffy \
    git \
    g++-mingw-w64-i686 \
    g++-mingw-w64-x86-64 \
    g++-multilib \
    gcc-multilib \
    gnupg \
    imagemagick \
    libboost-all-dev \
    libbz2-dev \
    libcap-dev \
    libdbus-1-dev \
    libevent-dev \
    libharfbuzz-dev \
    libminiupnpc-dev \
    libprotobuf-dev \
    libqrencode-dev \
    libqt5core5a \
    libqt5dbus5 \
    libqt5gui5 \
    librsvg2-bin \
    libssl-dev \
    libtiff-tools \
    libtool \
    libz-dev \
    libzmq3-dev \
    locales \
    lsof \
    mingw-w64-i686-dev \
    mingw-w64-x86-64-dev \
    nsis \
    openjdk-8-jre-headless \
    openssh-client \
    openssl \
    pkg-config \
    protobuf-compiler \
    python3 \
    python3-dev \
    python3-pip \
    python3-zmq \
    python-dev \
    python-setuptools \
    qtbase5-dev \
    qttools5-dev \
    qttools5-dev-tools \
    rsync \
    s3cmd \
    software-properties-common \
    sshpass \
    sudo \
    util-linux \
    wget \
    wine1.6 \
    zip 
    
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y g++-arm-linux-gnueabihf
    
RUN apt-get autoremove -y
RUN apt-get clean

RUN update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix
RUN update-alternatives --set i686-w64-mingw32-g++ /usr/bin/i686-w64-mingw32-g++-posix

RUN pip3 install litecoin_scrypt

RUN set -ex \
  && wget -O /usr/local/bin/swarm-client.jar https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_CLIENT_VERSION}/swarm-client-${SWARM_CLIENT_VERSION}.jar \
  && useradd -m -s /bin/sh jenkins

RUN set -ex \
  && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  && sed -i -e 's/# de_CH.UTF-8 UTF-8/de_CH.UTF-8 UTF-8/' /etc/locale.gen \
  && dpkg-reconfigure --frontend=noninteractive locales \
  && locale-gen en_US.UTF-8 \
  && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8

RUN set -ex \
  && cd /tmp \
  && wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz \
  && tar -xzvf db-4.8.30.NC.tar.gz \
  && cd db-4.8.30.NC/build_unix \
  && ../dist/configure --enable-cxx --disable-shared --with-pic \
  && make \
  && make install \
  && ln -s /usr/local/BerkeleyDB.4.8/lib/libdb-4.8.so /usr/lib/libdb-4.8.so \
  && ln -s /usr/local/BerkeleyDB.4.8/lib/libdb_cxx-4.8.so /usr/lib/libdb_cxx-4.8.so

ENV BDB_INCLUDE_PATH=/usr/local/BerkeleyDB.4.8/include \
  BDB_LIB_PATH=/usr/local/BerkeleyDB.4.8/lib \
  BDB_PREFIX=/usr/local/BerkeleyDB.4.8
  
RUN echo '/usr/local/BerkeleyDB.4.8/lib/' >> /etc/ld.so.conf
RUN ldconfig



VOLUME ["/home/jenkins"]

ENTRYPOINT ["/usr/local/bin/tini", "--"]
CMD ["/usr/local/bin/run-container.sh"]
