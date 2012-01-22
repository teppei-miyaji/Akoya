package Akoya::AccessControl;
use Mojo::Base 'Mojolicious::Plugin';

our $permissions;

sub register {
  my ( $self , $app ) = @_;
  my $access_control = __PACKAGE__->new;
  $self->{permissions} = [qw//];
  $app->helper( access_control => sub{ $access_control; } );
}

sub map {
  my ( $self , $sub ) = @_;
  my $mapper = Akoya::AccessControl::Mapper->new;
  $sub->( $mapper );
  push @{ $self->{permissions} } , $mapper->mapped_permissions; 
}

sub permissions { #shift if $_[0] eq __PACKAGE__;  shift if ref( $_[0] ) eq __PACKAGE__;
  @{ $permissions };
}

sub permission { shift if $_[0] eq __PACKAGE__;  shift if ref( $_[0] ) eq __PACKAGE__;
  my ( $name ) = @_;
  foreach my $p ( @{ $permissions } ) { return $p if $p->name eq $name }
  undef;
}

sub allowed_actions {
  my ( $self , $permission_name ) = @_;
  my $perm = $self->permission( $permission_name );
  $perm ? $perm->actions : ();
}

sub public_permissions {
  my ( $self ) = @_;
  unless( @{ $self->{public_permissions} } ){
    foreach my $p ( @{ $self->{permissions} } ) { push @{ $self->{public_permissions} } , $p if $p->is_public };
  }
  @{ $self->{public_permissions} };
}

sub members_only_permissions {
  my ( $self ) = @_;
  unless( @{ $self->{members_only_permissions} } ){
    foreach my $p ( @{ $self->{permissions} } ) { push @{ $self->{members_only_permissions} } , $p if $p->is_require_member }
  }
  @{ $self->{members_only_permissions} };
}

sub loggedin_only_permissions {
  my ( $self ) = @_;
  unless( @{ $self->{loggedin_only_permissions} } ){
    foreach my $p ( @{ $self->{permissions} } ) { push @{ $self->{loggedin_only_permissions} } , $p if $p->is_require_loggedin }
  }
  @{ $self->{loggedin_only_permissions} };
}

sub available_project_modules {
  my ( $self , $project_module ) = @_;
  unless( @{ $self->{available_project_modules} } ){
    my @collect = ();
    if( ref( $project_module ) eq q|CODE| ){
      foreach my $p ( @{ $self->{permissions} } ){
        push @collect , $p if $project_module->( $p );
      }
      push @{ $self->{available_project_modules} } , @collect;
    }
    else {
      @{ $self->{permissions} };
    }
  }
}

sub modules_permissions {
  my ( $self , $modules ) = @_;
  my @modules_permissions = ();
  foreach my $p ( @{ $self->{permissions} } ) {
    push @modules_permissions , $p->project_module->is_undef || $modules->is_include( $p->project_module->to_s ); 
  }
  @modules_permissions;
}

package Akoya::AccessControl::Mapper;
use Mojo::Base -base;
use Data::Dumper;

sub new {
  my $self = shift->SUPER::new( @_ );
  $self->{project_module} = "";
  $self;
}

sub permission {
  my ( $self , $name , $hash , $options ) = @_;
  @{ $self->{permissions} } = () unless $self->{permissions};
  $options->{project_module} = $self->{project_module};
  push @{ $self->{permissions} } , Akoya::AccessControl::Permission->new( name => $name , hash => $hash , options => $options );
}

sub project_module {
  my ( $self , $name , $sub ) = @_;
  my $mapper = __PACKAGE__->new;
  $mapper->{project_module} = $name;
  $sub->( $mapper );
  push @{ $self->{permissions} } , $mapper->mapped_permissions;
}

sub mapped_permissions {
  @{ shift->{permissions} };
}

package Akoya::AccessControl::Permission;
use Mojo::Base -base;

has [qw/name actions project_module/];

sub new {
   my $self = shift->SUPER::new( @_ );
  $self->{action} = [qw//];
  $self->{public} = delete $self->{options}->{public} || 0;
  $self->{require} = delete $self->{options}->{require};
  $self->{project_module} = delete $self->{options}->{project_module};
  delete $self->{options};

  foreach my $controller ( keys %{ $self->{hash} } ){
    if( ref( $self->{hash}->{ $controller } ) eq q|ARRAY| ){
      push @{ $self->{action} } , map { $controller . q|/| . $_ } @{ $self->{hash}->{ $controller } };
    }
    else{
      push @{ $self->{action} } , $controller . q|/| . $self->{hash}->{ $controller };
    }
  }
  delete $self->{hash};
#  @{ $self->{action} };
  $self;
}

sub is_public {
  shift->{public};
}

sub is_require_member {
  my ( $self ) = @_;
  $self->{require} && $self->{require} eq q|member| ? 1 : 0;
}

sub require_loggedin {
  my ( $self ) = @_;
  $self->{require} && ( $self->{require} eq q|member| || $self->{require} eq q|loggedin| ) ? 1 : 0;
}

1;