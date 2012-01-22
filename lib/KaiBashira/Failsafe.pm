package KaiBashira::Failsafe;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';

sub register {
  my ( $self , $app ) = @_;
  $app->helper(
    h => sub{
      my ( $c , $value ) = @_;
      $value;
    }
  );
}

1;