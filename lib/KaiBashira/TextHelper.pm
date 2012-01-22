package Akoya::Routes;
use feature 'switch';
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ( $self , $app ) = @_;
  $app->helper( pluralize => sub{
    my ( $c , $count , $singular , $plural ) = @_;
    $count eq 1 ? $singular : ( $plural || $c->singular_pluralize( $singular ) );
  } );
}

1;