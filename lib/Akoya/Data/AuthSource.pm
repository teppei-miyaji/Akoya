package Akoya::Data::AuthSource;
use lib qw|/Users/tripper/akoya/lib|;
use KaiBashira::Base -base;
use KaiBashira::Data -base;

pub table => 'auth_sources';

has [qw/id type name host port account account_password base_dn attr_login attr_firstname attr_lastname attr_mail onthefly_register tls/];

sub new {
  my $self = shift->SUPER::new( @_ );
  if( $self->table && $self->{id} && $self->parent->dbi->count( table => $self->table , where => { id => $self->id } ) ){
    my $result = $self->parent->dbi->select( table => $self->table , where => { id => $self->id } )->one;
    while( my ( $attr , $value ) = each %{ $result } ){
      $self->{ "${attr}" } = $value;
    }
  }
  $self;
}

sub authenticate {
  my ( $self, $login, $password) = @_;
  return undef if ! $login ||  ! $password;
  #  attrs = get_user_dn(login)

  #  if attrs && attrs[:dn] && authenticate_dn(attrs[:dn], password)
  #    logger.debug "Authentication successful for '#{login}'" if logger && logger.debug?
  #    return attrs.except(:dn)
  #  end
  #rescue  Net::LDAP::LdapError => text
  #  raise "LdapError: " + text
  undef; #not transrate
}
  
1;



