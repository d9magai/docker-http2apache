FROM centos
MAINTAINER d9magai

ENV OPENSSL_PREFIX /opt/openssl
ENV OPENSSL_SRC_DIR $OPENSSL_PREFIX/src
ENV OPENSSL_VERSION 1.0.2d
ENV OPENSSL_ARCHIVE_URL https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz

ENV NGHTTP2_PREFIX /opt/nghttp2
ENV NGHTTP2_SRC_DIR $NGHTTP2_PREFIX/src
ENV NGHTTP2_VERSION 1.4.0
ENV NGHTTP2_ARCHIVE_URL https://github.com/tatsuhiro-t/nghttp2/releases/download/v$NGHTTP2_VERSION/nghttp2-$NGHTTP2_VERSION.tar.gz

ENV HTTPD_BUILD_DIR /opt/httpd_build
ENV HTTPD_VERSION 2.4.17
ENV HTTPD_ARCHIVE_URL http://ftp.jaist.ac.jp/pub/apache//httpd/httpd-$HTTPD_VERSION.tar.bz2

RUN yum update -y && yum install -y \
    gcc \
    gcc-c++ \
    make \
    libtool \
    bzip2 \
    zlib-devel \
    apr-util-devel \
    pcre-devel \
    && yum clean all

RUN mkdir -p $OPENSSL_SRC_DIR \
    && curl --tlsv1 -sL $OPENSSL_ARCHIVE_URL | tar xz -C $OPENSSL_SRC_DIR \
    && cd $OPENSSL_SRC_DIR/openssl-$OPENSSL_VERSION \
    && ./config --prefix=$OPENSSL_PREFIX shared zlib \
    && make -s \
    && make -s install \
    && rm -rf $OPENSSL_SRC_DIR
RUN echo "$OPENSSL_PREFIX/lib/" > /etc/ld.so.conf.d/openssl.conf && ldconfig
ENV PKG_CONFIG_PATH $OPENSSL_PREFIX/lib/pkgconfig/:$PKG_CONFIG_PATH

RUN mkdir -p $NGHTTP2_SRC_DIR \
    && curl -sL $NGHTTP2_ARCHIVE_URL | tar xz -C $NGHTTP2_SRC_DIR \
    && cd $NGHTTP2_SRC_DIR/nghttp2-$NGHTTP2_VERSION \
    && ./configure --prefix=$NGHTTP2_PREFIX \
    && make -s \
    && make -s  install \
    && rm -rf $NGHTTP2_SRC_DIR
RUN echo "$NGHTTP2_PREFIX/lib/" > /etc/ld.so.conf.d/nghttp2.conf && ldconfig
ENV PKG_CONFIG_PATH $NGHTTP2_PREFIX/lib/pkgconfig/:$PKG_CONFIG_PATH

RUN mkdir -p $HTTPD_BUILD_DIR \
    && curl -sL $HTTPD_ARCHIVE_URL | tar xj -C $HTTPD_BUILD_DIR \
    && cd $HTTPD_BUILD_DIR/httpd-$HTTPD_VERSION \
    && ./configure --enable-http2 --enable-ssl --with-ssl=$OPENSSL_PREFIX --enable-so --enable-mods-shared=all \
    && make -s \
    && make -s install \
    && rm -rf $HTTPD_BUILD_DIR

COPY server.key /usr/local/apache2/conf/server.key
COPY server.crt /usr/local/apache2/conf/server.crt
COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY httpd-ssl.conf /usr/local/apache2/conf/extra/httpd-ssl.conf

EXPOSE 443
CMD ["/usr/local/apache2/bin/httpd", "-D", "FOREGROUND"] 

