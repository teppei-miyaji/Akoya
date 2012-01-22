package Akoya::Data::Token;
use lib qw|/Users/tripper/akoya/lib|;
use Mojo::Base 'KaiBashira::Data';

has table => "tokens";

has [qw/parent/];
has [qw/id user_id action value created_on/];

sub create {
  my $self = shift->SUPER::new( @_ );
  $self;
}

1;

