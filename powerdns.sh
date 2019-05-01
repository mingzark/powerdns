#!/bin/bash
#
#********************************************************************
#Author:		13
#Date: 			2019-04-30
#FileName：		powerdns.sh
#URL: 			http://www.magedu.com
#Description：		The test script
#Copyright (C): 	2019 All rights reserved
#********************************************************************
#dnsip地址以及本地域名自行定义，数据库名powerdns，用户名powerdns，密码centos
ip=172.18.13.11
domain="ming.net"
yum -y install nginx php php-fpm mariadb-server wget php-devel php-gd php-mcrypt php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mhash gettext epel-release
yum install -y pdns pdns-backend-mysql pdns-recursor
systemctl start mariadb
mysql -e "CREATE DATABASE powerdns; GRANT ALL ON powerdns.* TO 'powerdns'@'localhost' IDENTIFIED BY 'centos'; use powerdns;          CREATE TABLE domains (
  id                    INT AUTO_INCREMENT,
  name                  VARCHAR(255) NOT NULL,
  master                VARCHAR(128) DEFAULT NULL,
  last_check            INT DEFAULT NULL,
  type                  VARCHAR(6) NOT NULL,
  notified_serial       INT DEFAULT NULL,
  account               VARCHAR(40) DEFAULT NULL,
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE UNIQUE INDEX name_index ON domains(name);


CREATE TABLE records (
  id                    BIGINT AUTO_INCREMENT,
  domain_id             INT DEFAULT NULL,
  name                  VARCHAR(255) DEFAULT NULL,
  type                  VARCHAR(10) DEFAULT NULL,
  content               VARCHAR(64000) DEFAULT NULL,
  ttl                   INT DEFAULT NULL,
  prio                  INT DEFAULT NULL,
  change_date           INT DEFAULT NULL,
  disabled              TINYINT(1) DEFAULT 0,
  ordername             VARCHAR(255) BINARY DEFAULT NULL,
  auth                  TINYINT(1) DEFAULT 1,
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE INDEX nametype_index ON records(name,type);
CREATE INDEX domain_id ON records(domain_id);
CREATE INDEX recordorder ON records (domain_id, ordername);


CREATE TABLE supermasters (
  ip                    VARCHAR(64) NOT NULL,
  nameserver            VARCHAR(255) NOT NULL,
  account               VARCHAR(40) NOT NULL,
  PRIMARY KEY (ip, nameserver)
) Engine=InnoDB;


CREATE TABLE comments (
  id                    INT AUTO_INCREMENT,
  domain_id             INT NOT NULL,
  name                  VARCHAR(255) NOT NULL,
  type                  VARCHAR(10) NOT NULL,
  modified_at           INT NOT NULL,
  account               VARCHAR(40) NOT NULL,
  comment               VARCHAR(64000) NOT NULL,
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE INDEX comments_domain_id_idx ON comments (domain_id);
CREATE INDEX comments_name_type_idx ON comments (name, type);
CREATE INDEX comments_order_idx ON comments (domain_id, modified_at);


CREATE TABLE domainmetadata (
  id                    INT AUTO_INCREMENT,
  domain_id             INT NOT NULL,
  kind                  VARCHAR(32),
  content               TEXT,
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE INDEX domainmetadata_idx ON domainmetadata (domain_id, kind);


CREATE TABLE cryptokeys (
  id                    INT AUTO_INCREMENT,
  domain_id             INT NOT NULL,
  flags                 INT NOT NULL,
  active                BOOL,
  content               TEXT,
  PRIMARY KEY(id)
) Engine=InnoDB;

CREATE INDEX domainidindex ON cryptokeys(domain_id);


CREATE TABLE tsigkeys (
  id                    INT AUTO_INCREMENT,
  name                  VARCHAR(255),
  algorithm             VARCHAR(50),
  secret                VARCHAR(255),
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE UNIQUE INDEX namealgoindex ON tsigkeys(name, algorithm); "
cat >/etc/pdns/pdns.conf <<EOF
launch=gmysql
gmysql-host=localhost
gmysql-port=3306
gmysql-dbname=powerdns
gmysql-user=powerdns
gmysql-password=centos
local-address=127.0.0.1
local-port=53
setgid=pdns
setuid=pdns
EOF
cat >/etc/pdns-recursor/recursor.conf <<EOF
forward-zones-file=/etc/pdns-recursor/zone
forward-zones-recurse=.=114.114.114.114
local-address=$ip
setgid=pdns-recursor
setuid=pdns-recursor
EOF
echo "$domain=127.0.0.1:53" >/etc/pdns-recursor/zone
mv nginx.conf /etc/nginx/nginx.conf
cd /usr/share/nginx/html
wget http://downloads.sourceforge.net/project/poweradmin/poweradmin-2.1.7.tgz
tar xvf poweradmin-2.1.7.tgz
mv poweradmin-2.1.7 poweradmin
systemctl start pdns pdns-recursor php-fpm nginx

