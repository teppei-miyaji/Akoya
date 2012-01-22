package Controllers::Account;
use Mojo::Base 'Mojolicious::Controller';
use lib qw|/Users/tripper/akoya/lib|;

has 'handler';

# Login request and validation
sub login {
  my ( $self ) = @_;
  if( $self->req->method eq 'GET' ){
    $self->logout_user;
  }
  else {
    $self->authenticate_user;
  }
}

# Log out current user and redirect to welcome page
sub logout {
  my ( $self ) = @_;
  $self->logout_user;
  $self->redirect_to( $self->url_for( 'home' ) );
}
 
sub lost_password { die }

# User self-registration
sub register { die }

# Token based account activation
sub activate { die }

# private
sub logout_user {
  my ( $self ) = @_;
  if( $self->user->current->is_logged ){
    $self->session( logged_user => 0 );
    $self->dbi->delete( table => 'tokens' , where => { user_id => $self->user->current->id , action => 'autologin' } );
  }
}

sub authenticate_user {
  my ( $self ) = @_;
  if( $self->setting->is_openid && $self->is_using_open_id ){
    $self->open_id_authenticate( $self->param('openid_url') );
  }
  else {
    $self->password_authentication;
  }
}

sub password_authentication {
  my ( $self ) = @_;
  my $user = $self->user->try_to_login( $self->param('username'), $self->param('password') );

  if( ! $user ){
    $self->invalid_credentials;
  }
  elsif( $user->is_new_record ){
    $self->onthefly_creation_failed( $user, { login => $user->login, auth_source_id => $user->auth_source_id } );
  }
  else {
    # Valid user
    $self->successful_authentication( $user );
  }
}

sub open_id_authenticate { die }

sub successful_authentication {
  my ( $self, $user ) = @_;
  # Valid user
  $self->session( logged_user => $user->id );
  # generate a key and set cookie if autologin
  if( $self->param('autologin') && $self->setting->is_autologin ){
    $self->set_autologin_cookie( $user );
  }
  $self->emit_hook( 'controller_account_success_authentication_after' , { user => $user } );
  $self->redirect_back_or_default( $self->url_for( 'my/page' ) );
}

sub set_autologin_cookie { die }

sub onthefly_creation_failed { die }

sub invalid_credentials {
  my ( $self ) = @_;
  $self->app->log->warn( "Failed login for '" . $self->param('username') . "' from " . $self->tx->remote_address . ' at ' . $self->dbi->now->() );
  $self->stash( flash => { error => $self->l('notice_account_invalid_creditentials') } );
}

sub register_by_email_activation { die }

sub register_automatically { die }

sub register_manually_by_administrator { die }

sub account_pending { die }

1;