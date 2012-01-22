package Akoya::Model;
use lib qw|/Users/tripper/akoya/lib|;
use Mojo::Base 'Mojolicious::Plugin';
use DBIx::Custom;

use Data::Dumper;

use Akoya::Data::Project;
use Akoya::Data::Principal;
use Akoya::Data::User;
use Akoya::Data::News;
use Akoya::Data::Token;
use Akoya::Data::Setting;
use Akoya::Data::AuthSource;
use Akoya::Data::Member;
use Akoya::Data::Role;

sub register {
  my ( $self , $app ) = @_;
  my $dbi = DBIx::Custom->connect( $app->defaults->{database}->{ $app->mode } );
  #$dbi->include_model('Models');
  $app->helper( dbi => sub{ $dbi; } );

  $app->helper( user    => sub { Akoya::Data::User->new( parent => $_[0] ); } );
  $app->helper( news    => sub { Akoya::Data::News->new( parent => $_[0] ); } );
  $app->helper( project => sub { Akoya::Data::Project->new( parent => $_[0] ); } );
  $app->helper( token   => sub { Akoya::Data::Token->new( parent => $_[0] ); } ); 
  $app->helper( setting => sub { Akoya::Data::Setting->new( parent => $_[0] ); } ); 

}

1;