package KaiBashira::Plugin;
use Mojo::Base 'Mojolicious::Plugin';

my @plugin_funcs = qw//;

sub register_helper{
  my ( $self , $app ) = @_;
  foreach my $func( @plugin_funcs ){
    $app->helper( "${func}" => &${func}( @_ ) );
  }
}

sub plugin_funcs{
  @plugin_funcs;
}

1;
