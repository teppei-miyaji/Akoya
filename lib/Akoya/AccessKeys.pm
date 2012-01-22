package Akoya::AccessKeys;
use Mojo::Base 'Mojolicious::Plugin';

our $ACCESSKEYS = {
  edit => 'e',
  preview => 'r',
  quick_search => 'f',
  search => '4',
  new_issue => '7'
};

sub register {
  my ( $self , $app ) = @_;
  my $access_keys = __PACKAGE__->new;
  $app->helper( access_keys => sub{ $access_keys; } );
}

sub key_for {
  my ( $action ) = @_;
  $ACCESSKEYS->{ $action };
}

1;