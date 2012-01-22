package Akoya::Helpers;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ( $self , $app ) = @_;

  my @helpers = qw/
    Helpers::Application
    Helpers::Controller
    Helpers::Users
  /;

  foreach my $helper( @helpers ){
    $app->plugin( $helper );
  }
}

1;
