FROM debian:buster

RUN apt-get update
RUN apt-get install -y gnupg2 curl procps patch bzip2 gawk g++ gcc autoconf automake bison libc6-dev libffi-dev libgdbm-dev libncurses5-dev libsqlite3-dev libtool libyaml-dev make patch pkg-config sqlite3 zlib1g-dev libgmp-dev libreadline-dev libssl-dev git

RUN gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s stable

WORKDIR /remote_ruby
COPY . .

SHELL [ "/bin/bash", "-l", "-c" ]

RUN for ruby_version in "3.0.2" "2.7.4" "2.6.8" "2.5.8"; do \
  rvm install $ruby_version && rvm use $ruby_version && gem install bundler --no-document && bundle install; \
done

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
