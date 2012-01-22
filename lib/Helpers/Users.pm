package Helpers::Users;
use Mojo::Base 'Mojolicious::Plugin';

use Data::Dumper;

sub register {
  my ( $self , $app ) = @_;

  $app->helper(
    user_mail_notification_options => sub {
      my ( $c , $user ) = @_;
      my @collect;
      foreach my $o( @{ $user->valid_notification_options } ){
        my $last = $o->[1];
        my $first = $o->[0];
        push @collect, [ $c->l("$last") , $first ];
      }  
      @collect;
    }
  );
}

1;