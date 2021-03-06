FROM quay.io/openshifthomeroom/workshop-dashboard:4.2.2

USER root

COPY . /tmp/src

RUN rm -rf /tmp/src/.git* && \
    chown -R 1001 /tmp/src && \
    chgrp -R 0 /tmp/src && \
    chmod -R g+w /tmp/src && \
    chmod -R 700 /opt/app-root

ENV TERMINAL_TAB=split

USER 1001

RUN /usr/libexec/s2i/assemble
