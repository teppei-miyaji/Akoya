package Akoya::Config;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ( $self , $app ) = @_;
  
  $app->plugin(
    config => {
      file      => $app->home->rel_file('config/config.conf'),
      stash_key => 'setting'
    }
  );

  $app->plugin(
    config => {
      file      => $app->home->rel_file('config/database.conf'),
      stash_key => 'database'
    }
  );

}

1;