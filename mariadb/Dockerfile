FROM piwik

# install git + other deps
RUN apt-get update && \
    apt-get install software-properties-common python-software-properties git wget curl \
                    tcl tk openssl mysql-client -y --no-install-recommends

RUN apt-get install -y --no-install-recommends \
           ca-certificates \
           bzip2 \
           libfontconfig \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install extensions
RUN docker-php-ext-install mysqli
RUN pecl install redis

# install python for log importer
RUN apt-get install python2.7 \
    && curl -L https://bootstrap.pypa.io/get-pip.py | python

