package Akoya::Hook;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ( $self , $app ) = @_;

  $app->helper(
    emit_hook => sub{
      my $c = shift;
      $c->app->plugins->emit_hook( @_ );
    }
  );
}

1;