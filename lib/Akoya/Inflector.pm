package Akoya::Inflector;
use Mojo::Base 'Mojolicious::Plugin';
use KaiBashira::Inflector;

sub register {
  my ( $self , $app ) = @_;
  my $inflector = KaiBashira::Inflector->new;
  $app->helper( inflector => sub{ $inflector; } );
  
  foreach my $func ( qw/
    capitalize pluralize singularize
    camelize titleize underscore
    dasherize humanize demodulize
    parameterize transliterate
    tableize
  / ){
    $app->helper( "$func" => sub{
      my $c = shift;
      $c->inflector->$func( @_ );
    } );
  }
}

1;