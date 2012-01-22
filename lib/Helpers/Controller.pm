package Helpers::Controller;
use lib qw|/Users/tripper/akoya/lib|;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';

sub register {
  my ( $self , $app ) = @_;

  $app->helper(
    back_url => sub {
      my ( $c ) = @_;
      $c->param('back_url') || $c->req->headers->referrer;
    }
  );

  $app->helper(
    redirect_back_or_default => sub{
      my ( $c , $default ) = @_;
      my $back_url = b( $c->param('back_url') )->url_unescape;
      if( $back_url ){
        #my $uri = URI.parse(back_url)
        # do not redirect user to another host or to the login or register page
        #if (uri.relative? || (uri.host == request.host)) && !uri.path.match(%r{/(login|account/register)})
        $c->redirect_to( $back_url );
        #end
      }
      $c->redirect_to( $default );
    }
  );
}

1;