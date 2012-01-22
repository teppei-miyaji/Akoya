package Akoya::Data::User;
use lib qw|/Users/tripper/akoya/lib|;
use Akoya::Data::Project;
use Akoya::Data::Principal;
use Akoya::Data::UserPreference;
use KaiBashira::Base -base;
use KaiBashira::Data 'Akoya::Data::Principal';
use Digest::SHA1 'sha1_hex';

use Data::Dumper;

has [qw/id login hashed_password firstname lastname mail admin status last_login_on language auth_source_id created_on updated_on type identity_url mail_notification salt/];

pub table => "users";

our $STATUS_ANONYMOUS  = 0;
our $STATUS_ACTIVE     = 1;
our $STATUS_REGISTERED = 2;
our $STATUS_LOCKED     = 3;

our $USER_FORMATS = {
  firstname_lastname => { string => '#{firstname} #{lastname}', order => [qw(firstname lastname id)] },
  firstname => { string => '#{firstname}', order => [qw(firstname id)] },
  lastname_firstname => { string => '#{lastname} #{firstname}', order => [qw(lastname firstname id)] },
  lastname_coma_firstname => { string => '#{lastname}, #{firstname}', order => [qw(lastname firstname id)] },
  username => { string => '#{login}', order => [qw(login id)] },
};

our $MAIL_NOTIFICATION_OPTIONS = [
    [qw/all label_user_mail_option_all/],
    [qw/selected label_user_mail_option_selected/],
    [qw/only_my_events label_user_mail_option_only_my_events/],
    [qw/only_assigned label_user_mail_option_only_assigned/],
    [qw/only_owner label_user_mail_option_only_owner/],
    [qw/none label_user_mail_option_none/]
];

has_and_belongs_to_many name => 'groups' , after_add => sub { my ( $user, $group ); $group->user_added( $user ) },
                                           after_remove => sub { my ( $user, $group ); $group->user_removed( $user ) };
has_many name => 'changesets' , dependent => 'nullify';
has_one name => 'preference' , dependent => 'destroy' , class_name => 'UserPreference';
has_one name => 'rss_token' , class_name => 'Token', conditions => { action => 'feeds' };
has_one name => 'api_token' , class_name => 'Token', conditions => { action => 'api' };
belongs_to name => 'auth_source';

sub new {
  my $self = shift->SUPER::new( @_ );
  if( $self->{id} && $self->parent->dbi->count( table => $self->table , where => { id => $self->id } ) ){
    my $result = $self->parent->dbi->select( table => $self->table , where => { id => $self->id } )->one;
    while( my ( $attr , $value ) = each %{ $result } ){
      $self->{ "${attr}" } = $value;
    }
  }
  $self;
}

sub set_mail_notification {
  my ( $self ) = @_;
  $self->mail_notification( $self->parent->setting->default_notification_option ) unless $self->mail_notification;
  1;
}

sub update_hashed_password {
  my ( $self, $password ) = @_;
  # update hashed_password if password was set
  if( $self->password && ! $self->auth_source_id ){
    $self->salt_password( $password );
  }
}

sub reload {
  my ( $self ) = @_;
  $self->name( undef );
  $self->projects_by_role( undef );
  $self = $self->SUPER::new( @_ );
  $self;
}

sub mail {
  my ( $self , $arg ) = @_;
  $self->mail( $arg );
}

sub identity_url {
  my ( $self, $url ) = @_;
  if( ! $url ){
    $self->identity_url( '' );
  }
  else {
  #    begin
  #      write_attribute(:identity_url, OpenIdAuthentication.normalize_identifier(url))
  #    rescue OpenIdAuthentication::InvalidOpenId
  #      # Invlaid url, don't save
  #    end
  }
  $self->identity_url;
}

sub try_to_login {
  my ( $self, $login, $password ) = @_;
  # Make sure no one can sign in with an empty password
  return undef unless $password;

  my $user = $self->find_by_login( $login );
  if( $user ){
    # user is already in local database
    return undef unless $user->is_active;
    if( $user->auth_source->id ) {
      # user has an external authentication method
      return undef unless $user->auth_source->authenticate( $login, $password );
    }
    else {
      # authentication with local password
      return undef unless $user->check_password( $password );
    }
  }
  else {
    # user is not yet registered, try to authenticate with available sources
    my $attrs = Akoya::Data::AuthSource->authenticate( $login, $password );
    if( $attrs ) {
      $user = ref( $self )->new( %{ $attrs } , parent => $self->parent );
      $user->login( $login );
      $user->language = $self->parent->setting->default_language;
      if( $user->save ){
        $user->reload;
        #logger.info("User '#{user.login}' created from external auth source: #{user.auth_source.type} - #{user.auth_source.name}") if logger && user.auth_source
      }
    }
  }
  $user->update_attribute( 'last_login_on' , $self->parent->dbi->now ) if $user && ! $user->is_new_record;
  $user;
}

sub try_to_autologin {
  my ( $self, $key ) = @_;
  my $tokens = $self->parent->dbi->model('token')->find_all_by_action_and_value( 'autologin', $key );
  # Make sure there's only 1 token that matches the key
  if( $tokens->size == 1 ){
    my $token = tokens->first;
    if( $token->created_on > $self->parent->setting->autologin && $token->user && $token->user->is_active ) {
      $token->user->update_attribute( 'last_login_on' , $self->parent->dbi->now );
      $token->user;
    }
  }
}

sub name_formatter {
  my ( $self , $formatter ) = @_;
  $formatter ||= undef;
  my $user_format = $self->parent->setting->user_format;
  #$user_format = $user_format->{value} if $user_format->{value};
  $USER_FORMATS->{ $formatter || $user_format } || $USER_FORMATS->{firstname_lastname};
}

sub fields_for_order_statement {
  my ( $self, $table ) = @_;
  $table ||= 'users';
  $self->name_formatter('order');
}

sub name {
  my ( $self, $formatter ) = @_;
  my $f = $self->name_formatter( $formatter );
  if( $formatter ){
    $self->_f( $f->{string} );
  }
  else {
    $self->{name} ||= $self->_f( $f->{string} );
  }
}

sub _f {
  my ( $self, $format ) = @_;
  my $result = "$format";
  $result =~ s/\#\{firstname\}/$self->firstname/e;
  $result =~ s/\#\{lastname\}/$self->lastname/e;
  $result =~ s/\#\{login\}/$self->login/e;
  $result =~ s/\#\{id\}/$self->id/e;
  $result;
}

sub is_active {
  my ( $self ) = @_;
  $self->status eq $STATUS_ACTIVE ? 1 : 0;
}

sub is_registered {
  my ( $self ) = @_;
  $self->status eq $STATUS_REGISTERED ? 1 : 0;
}

sub is_locked {
  my ( $self ) = @_;
  $self->status eq $STATUS_LOCKED ? 1 : 0;
}

sub activate {
  my ( $self ) = @_;
  $self->status( $STATUS_ACTIVE );
}

sub register {
  my ( $self ) = @_;
  $self->status( $STATUS_REGISTERED );
}

sub lock {
  my ( $self ) = @_;
  $self->status( $STATUS_LOCKED );
}

sub bang_activate {
  my ( $self ) = @_;
  $self->update_attribute( 'status' , $STATUS_ACTIVE );
}

sub bang_register {
  my ( $self ) = @_; 
  $self->update_attribute( 'status' , $STATUS_REGISTERED );
}

sub bang_lock {
  my ( $self ) = @_;
  $self->update_attribute( 'status' , $STATUS_LOCKED );
}

sub check_password {
  my ( $self, $clear_password) = @_;
  if( $self->auth_source_id ) {
    $self->auth_source->authenticate( $self->login , $clear_password );
  }
  else {
    $self->hash_password( $self->salt . $self->hash_password( $clear_password ) ) eq $self->hashed_password;
  }
}

sub is_change_password_allowed {
  my ( $self ) = @_;  
  return 1 unless $self->auth_source_id;
  return $self->auth_source->is_allow_password_changes;
}

sub random_password {
  my ( $self ) = @_;
  my @chars = ( 0..9 , "a".."z" , "A".."Z" );
  my $password = '';
  my $size = @chars;
  foreach my $i( 1..40 ){
    $password .= $chars[ int( rand( $size - 1 ) ) ];
  }
  $self->password( $password );
  $self->password_confirmation( $password );
  $self;
}

sub pref {
  my ( $self ) = @_;
  $self->preference( Akoya::Data::UserPreference->new( user_id => $self->id , parent => $self->parent ) ) unless $self->preference;
  $self->preference;
}

sub time_zone {
  #  @time_zone ||= (self.pref.time_zone.blank? ? nil : ActiveSupport::TimeZone[self.pref.time_zone])
}

sub is_wants_comments_in_reverse_order {
  my ( $self ) = @_;
  $self->pref->comments_sorting == 'desc' ? 1 : 0;
}

sub rss_key {
  my ( $self ) = @_; 
  my $token = $self->rss_token || Akoya::Data::Token->create( user_id => $self->id , parent => $self->parent , action => 'feeds' );
  $token->value;
}

sub api_key {
  my ( $self ) = @_; 
  my $token = $self->api_token || $self->create_api_token( action => 'api' );
  $token->value;
}

sub notified_projects_ids {
  #@notified_projects_ids ||= memberships.select {|m| m.mail_notification?}.collect(&:project_id)
}

sub valid_notification_options {
  my ( $self , $user ) = @_;
  $user ||= undef;
  if( ! $user || $user->memberships->length < 1 ){
    # MAIL_NOTIFICATION_OPTIONS.reject {|option| option.first == 'selected'}
    my $new_mail_notification_options;
    foreach my $element( @{ $MAIL_NOTIFICATION_OPTIONS } ){
      push @{ $new_mail_notification_options } , $element unless $element->[0] eq 'selected';
    }
    $new_mail_notification_options;
  }
  else {
    $MAIL_NOTIFICATION_OPTIONS;
  }
}

sub find_by_login {
  my ( $self, $login) = @_;
  $self->find_first( { login => $login } );
#  my $result = $self->find_first( { login => $login } );
#  return undef unless $result;
#  my $user = $result->{id};
#  ref( $self )->new( id => $user , parent => $self->parent );
}

sub find_by_rss_key {
  my ( $self, $key ) = @_;
  my $token = Akoya::Token->find_by_value( $key );
  $token && $token->user->is_active ? $token->user : undef;
}

sub is_logged { 1; }

sub is_admin {
  my ( $self ) = @_;
  $self->admin eq 't' ? 1 : 0;
}

sub is_allowed_to {
  my ( $self, $action, $context, $options , $sub ) = @_;
  if( $context && ref( $context ) eq 'Akoya::Project' ){
    # No action allowed on archived projects
    return 0 unless $context->is_active;
    # No action allowed on disabled modules
    return 0 unless $context->is_allows_to( $action );
    # Admin users are authorized for anything else
    return 1 if $self->is_admin;

    my @roles = $self->roles_for_project( $context );
    return 0 unless @roles;
    foreach my $role ( @roles ){ #detect
      return 1 if ( $context->is_public || $role->is_member ) &&
      $role->is_allowed_to( $action ) &&
      ( $sub ? $sub->( $role, $self ) : 1);
    }
    return 0;
  }
  elsif( $context && ref( $context ) eq 'ARRAY' ){
    # Authorize if user is authorized on every element of the array
    my $memo;
    my $allowed;
    foreach my $project( @{ $context } ){
      $allowed = $self->is_allowed_to( $action, $project, $options, $sub );
      $memo = $memo && $allowed;
    }
  }
  elsif( $options->{global} ){
    # Admin users are always authorized
    return 1 if $self->is_admin;

    # authorize if user has at least one role that has this permission
    my @roles = $self->memberships;#.collect {|m| m.roles}.flatten.uniq
    push @roles , $self->is_logged ? Role->non_member : Role->anonymous;
    foreach my $role( @roles ){ #detect
      return 1 if $role->is_allowed_to( $action ) &&
        ( $sub ? $sub->( $role, $self) : 1);
    }
  }
  else {
    return 0;
  }
}

sub current {
  my ( $self ) = @_;
  my $id = $self->parent->session('logged_user') || 0;
  warn Dumper( "fanyafanya" , $id );
  my $user;
  if( $id ){

    $user = ref( $self )->new( id => $id , parent => $self->parent );
  }
  else{
    $user = Akoya::Data::User::AnonymousUser->new( parent => $self->parent );
  }
  $user;
}

sub hash_password {
  my ( $self, $clear_password ) = @_;
  sha1_hex( $clear_password || "" );
}

#?
#sub projects {
#  my ( $self ) = @_;
#  my @projects;
#  my $sql = 'select distinct project_id from members where user_id = ( select :id union select group_id from groups_users where user_id = :id)';
#  #pre
#  if( $self->parent->dbi->execute( $sql , { id => $self->id } , after_build_sql => sub { "select count(*) from ($_[0]) as ct" } )->one->{ct} || 0  > 0 ){
#    my $result = $self->parent->dbi->execute( $sql , { id => $self->id } );
#    while( my $project = $result->one ){
#      push @projects , Akoya::Project->new( id => $project->{project_id} , parent => $self->parent );
#    }
#  }
#  @projects;
#}

sub custom_field_values { undef }

package Akoya::Data::User::AnonymousUser;
use Mojo::Base 'Akoya::Data::User';

sub is_logged { 0; }
sub is_admin { 0; }

1;

