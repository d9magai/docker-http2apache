FROM centos
MAINTAINER d9magai

ENV OPENSSL_PREFIX /opt/openssl
ENV OPENSSL_SRC_DIR $OPENSSL_PREFIX/src
ENV OPENSSL_VERSION 1.0.2d
ENV OPENSSL_BASENAME openssl-$OPENSSL_VERSION
ENV OPENSSL_ARCHIVE $OPENSSL_BASENAME.tar.gz
ENV OPENSSL_ARCHIVE_URL https://www.openssl.org/source/$OPENSSL_ARCHIVE

RUN yum update -y && yum install -y \
    gcc \
    gcc-c++ \
    make \
    autoconf \
    automake \
    libtool \
    perl \
    bzip2 \
    zlib-devel \
    libev-devel \
    apr-devel \
    apr-util-devel \
    pcre-devel \
    && yum clean all

RUN mkdir -p $OPENSSL_SRC_DIR \
    && cd $OPENSSL_SRC_DIR \
    && curl --tlsv1 -o $OPENSSL_ARCHIVE $OPENSSL_ARCHIVE_URL \
    && tar xvf $OPENSSL_ARCHIVE \
    && cd $OPENSSL_BASENAME \
    && ./config --prefix=$OPENSSL_PREFIX shared zlib \
    && make \
    && make test \
    && make install \
    && rm -rf $OPENSSL_SRC_DIR
RUN echo "$OPENSSL_PREFIX/lib/" > /etc/ld.so.conf.d/openssl.conf && ldconfig
ENV PKG_CONFIG_PATH $OPENSSL_PREFIX/lib/pkgconfig/:$PKG_CONFIG_PATH

ENV LIBNGHTTP2_PREFIX /opt/libnghttp2
ENV LIBNGHTTP2_SRC_DIR $LIBNGHTTP2_PREFIX/src
ENV LIBNGHTTP2_VERSION 1.4.0
ENV LIBNGHTTP2_BASENAME nghttp2-$LIBNGHTTP2_VERSION
ENV LIBNGHTTP2_ARCHIVE $LIBNGHTTP2_BASENAME.tar.gz
ENV LIBNGHTTP2_ARCHIVE_URL https://github.com/tatsuhiro-t/nghttp2/releases/download/v1.4.0/nghttp2-1.4.0.tar.bz2

RUN mkdir -p $LIBNGHTTP2_SRC_DIR \
    && cd $LIBNGHTTP2_SRC_DIR \
    && curl -o $LIBNGHTTP2_ARCHIVE -L $LIBNGHTTP2_ARCHIVE_URL \
    && tar xvf $LIBNGHTTP2_ARCHIVE \
    && cd $LIBNGHTTP2_BASENAME \
    && ./configure --prefix=$LIBNGHTTP2_PREFIX \
    && make \
    && make install \
    && rm -rf $LIBNGHTTP2_SRC_DIR
RUN echo "$LIBNGHTTP2_PREFIX/lib/" > /etc/ld.so.conf.d/libnghttp2.conf && ldconfig
ENV PKG_CONFIG_PATH $LIBNGHTTP2_PREFIX/lib/pkgconfig/:$PKG_CONFIG_PATH

RUN mkdir -p /opt/httpd_build \
    && cd /opt/httpd_build \
    && curl -o httpd-2.4.17.tar.bz2  http://ftp.jaist.ac.jp/pub/apache//httpd/httpd-2.4.17.tar.bz2 \
    && tar xvf httpd-2.4.17.tar.bz2 \
    && cd httpd-2.4.17 \
    && ./configure --enable-http2 --enable-ssl --enable-so --enable-mods-shared=all \
    && make \
    && make install \
    && rm -rf /opt/httpd_build

COPY server.key /usr/local/apache2/conf/server.key
COPY server.crt /usr/local/apache2/conf/server.crt
COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY httpd-ssl.conf /usr/local/apache2/conf/extra/httpd-ssl.conf

EXPOSE 443
CMD ["/usr/local/apache2/bin/httpd", "-D", "FOREGROUND"] 

