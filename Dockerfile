FROM centos
MAINTAINER d9magai

ENV OPENSSL_PREFIX /opt/openssl
ENV OPENSSL_SRC_DIR $OPENSSL_PREFIX/src
ENV OPENSSL_VERSION 1.0.2d
ENV OPENSSL_ARCHIVE_URL https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz

ENV NGHTTP2_PREFIX /opt/nghttp2
ENV NGHTTP2_SRC_DIR $NGHTTP2_PREFIX/src
ENV NGHTTP2_VERSION 1.4.0
ENV NGHTTP2_BASENAME nghttp2-$NGHTTP2_VERSION
ENV NGHTTP2_ARCHIVE $NGHTTP2_BASENAME.tar.gz
ENV NGHTTP2_ARCHIVE_URL https://github.com/tatsuhiro-t/nghttp2/releases/download/v$NGHTTP2_VERSION/$NGHTTP2_ARCHIVE

ENV HTTPD_BUILD_DIR /opt/httpd_build
ENV HTTPD_VERSION 2.4.17
ENV HTTPD_BASENAME httpd-$HTTPD_VERSION
ENV HTTPD_ARCHIVE $HTTPD_BASENAME.tar.bz2
ENV HTTPD_ARCHIVE_URL http://ftp.jaist.ac.jp/pub/apache//httpd/$HTTPD_ARCHIVE

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
    && curl --tlsv1 -sL $OPENSSL_ARCHIVE_URL | tar xz -C $OPENSSL_SRC_DIR \
    && cd $OPENSSL_SRC_DIR/openssl-$OPENSSL_VERSION \
    && ./config --prefix=$OPENSSL_PREFIX shared zlib \
    && make \
    && make test \
    && make install \
    && rm -rf $OPENSSL_SRC_DIR
RUN echo "$OPENSSL_PREFIX/lib/" > /etc/ld.so.conf.d/openssl.conf && ldconfig
ENV PKG_CONFIG_PATH $OPENSSL_PREFIX/lib/pkgconfig/:$PKG_CONFIG_PATH

RUN mkdir -p $NGHTTP2_SRC_DIR \
    && cd $NGHTTP2_SRC_DIR \
    && curl -o $NGHTTP2_ARCHIVE -L $NGHTTP2_ARCHIVE_URL \
    && tar xvf $NGHTTP2_ARCHIVE \
    && cd $NGHTTP2_BASENAME \
    && ./configure --prefix=$NGHTTP2_PREFIX \
    && make \
    && make install \
    && rm -rf $NGHTTP2_SRC_DIR
RUN echo "$NGHTTP2_PREFIX/lib/" > /etc/ld.so.conf.d/nghttp2.conf && ldconfig
ENV PKG_CONFIG_PATH $NGHTTP2_PREFIX/lib/pkgconfig/:$PKG_CONFIG_PATH

RUN mkdir -p $HTTPD_BUILD_DIR \
    && cd $HTTPD_BUILD_DIR \
    && curl -o $HTTPD_ARCHIVE  $HTTPD_ARCHIVE_URL \
    && tar xvf $HTTPD_ARCHIVE \
    && cd $HTTPD_BASENAME \
    && ./configure --enable-http2 --enable-ssl --with-ssl=$OPENSSL_PREFIX --enable-so --enable-mods-shared=all \
    && make \
    && make install \
    && rm -rf $HTTPD_BUILD_DIR

COPY server.key /usr/local/apache2/conf/server.key
COPY server.crt /usr/local/apache2/conf/server.crt
COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY httpd-ssl.conf /usr/local/apache2/conf/extra/httpd-ssl.conf

EXPOSE 443
CMD ["/usr/local/apache2/bin/httpd", "-D", "FOREGROUND"] 

