# Aleesa-Jabber-bot - Simple Jabber chatty bot

## About

It is based on Perl modules [Net::Jabber::Bot][1] and [Hailo][2] as
conversation generator.

Config located in **data/config.json**, sample config provided as
**data/sample_config.json**.

Bot can be run via **bin/aleesa-jabber-bot** and acts as daemon.

## Installation

In order to run this application, you need to "bootstrap" it - download and
install all dependencies and libraries.

You'll need "Development Tools" or similar group of packages, perl, perl-devel,
perl-local-lib, perl-app-cpanm, sqlite-devel, zlib-devel, openssl-devel,
libdb4-devel (Berkeley DB devel), make.

After installng required dependencies it is possible to run:

```bash
bash bootstrap.sh
```

and all libraries should be downloaded, built, tested and installed.

[1]: https://metacpan.org/pod/Net::Jabber::Bot
[2]: https://metacpan.org/pod/Hailo
