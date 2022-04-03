# Copyright (c) 2002 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Authen::SASL::CRAM_MD5;

use 5.018; ## no critic (ProhibitImplicitImport)
use warnings;
use strict;
use utf8;

use vars qw($VERSION);

$VERSION = '2.14';

use Authen::SASL ();

sub new {
  shift;
  return Authen::SASL->new(@_, mechanism => 'CRAM-MD5');
}

1;

