FROM centos:centos7
LABEL Maintainer = "Tim Fournet tfournet@radersolutions.com"
ENV build_date 2018-07-31

RUN yum update -y
RUN yum install epel-release kernel-headers gcc gcc-c++ cpp ncurses bzip2 patch ncurses-devel libxml2 libxml2-devel sqlite sqlite-devel openssl-devel newt-devel kernel-devel libuuid-devel net-snmp-devel xinetd tar make git jansson-devel -y 

ENV AUTOBUILD_UNIXTIME 1418234402

# Download asterisk.
WORKDIR /tmp/
RUN git clone -b 15 http://gerrit.asterisk.org/asterisk asterisk-15
WORKDIR /tmp/asterisk-15

# make asterisk.
ENV rebuild_date 2015-05-15
# Configure
RUN ./configure --libdir=/usr/lib64 1> /dev/null
# Remove the native build option
RUN make menuselect.makeopts
RUN menuselect/menuselect \
  --disable BUILD_NATIVE \
  --enable cdr_csv \
  --enable chan_sip \
  --enable res_snmp \
  --enable res_http_websocket \
  --enable ODBC_STORAGE \
  menuselect.makeopts

# Continue with a standard make.
RUN make 1> /dev/null
RUN make install 1> /dev/null
#RUN make basic-pbx 1> /dev/null
WORKDIR /

# Update max number of open files.
RUN sed -i -e 's/# MAXFILES=/MAXFILES=/' /usr/sbin/safe_asterisk
# Set tty
RUN sed -i 's/TTY=9/TTY=/g' /usr/sbin/safe_asterisk
# Create and configure asterisk for running asterisk user.
RUN useradd -m asterisk -s /sbin/nologin
RUN chown asterisk:asterisk /var/run/asterisk
RUN chown -R asterisk:asterisk /etc/asterisk/
RUN chown -R asterisk:asterisk /var/{lib,log,spool}/asterisk
RUN chown -R asterisk:asterisk /usr/lib64/asterisk/

# Running asterisk with user asterisk.
CMD /usr/sbin/asterisk -f -U asterisk -G asterisk -vvvg -c

