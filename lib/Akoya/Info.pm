package Akoya::Info;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ( $self , $app ) = @_;
  my $info = __PACKAGE__->new;
  $app->helper( info => sub{ $info; } );
}

sub app_name { 'Akoya' }
sub url{ 'http://www.exsample.com/' }
sub help_url{ 'http://www.exsample.com' }
sub versioned_name{ app_name . ' ' .  $Akoya::VERSION }

1;