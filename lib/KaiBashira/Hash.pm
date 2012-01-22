package KaiBashira::Hash;
use feature 'switch';
use Mojo::Base 'Mojolicious::Plugin';
use Carp;

sub register {
  my ( $self , $app ) = @_;

  $app->helper(
    h_to_a => sub {
      my ( $c, $hash ) = @_;
      my $result;
      while( my ( $key, $value ) = each %{ $hash } ){
        my $element;
        push @{ $element } , $key , $value;
        push @{ $result } , $element;
      }
      $result;
    }
  );
}

sub assert_valid_keys {
  my ( $self , $hash , @allow_args ) = @_;
  my $error = 0;
  foreach my $input_arg ( keys %{ $hash } ){
    unless( $input_arg ~~ @allow_args ) {
      carp 'Invalid Argument! =>' . $input_arg;
      $error = 1;
    }
  }
  croak 'ArgumentError!' if $error;
}

1;