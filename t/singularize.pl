#!/usr/bin/env perl

use lib qw/lib/;
use feature 'say';
use KaiBashira::Inflector;

my $inflector = KaiBashira::Inflector->new;

say $inflector->singularize( "moves"                      ) ;

