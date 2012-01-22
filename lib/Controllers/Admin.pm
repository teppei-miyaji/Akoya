package Controllers::Admin;
use Mojo::Base 'Mojolicious::Controller';

use Akoya::DefaultData::Loader;

sub index {
  my ( $self ) = @_;
  my $no_configuration_data => Akoya::DefaultData::Loader::is_no_data;
  $self->stash(
    no_configuration_data => $no_configuration_data 
  );
}

1;