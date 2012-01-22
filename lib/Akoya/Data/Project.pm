package Akoya::Data::Project;
use lib qw|/Users/tripper/akoya/lib|;
use KaiBashira::Base -base;
use KaiBashira::Data -base;

use Data::Dumper;

has [qw/id name description homepage is_public parent_id created_on updated_on identifier status lft rgt/];

pub table => "projects";

our $STATUS_ACTIVE = 1;
our $STATUS_ARCHIVED = 9;

our $IDENTIFIER_MAX_LENGTH = 100;

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

sub latest {
  my ( $self , $user , $count ) = @_;
  my $result = $self->parent->dbi->execute('select id from projects');
  my @projects = ();
  while( my $project = $result->fetch_hash ){
    push @projects , ref( $self )->new( id => $project->{id} ,parent => $self->parent );
  }
  \@projects;
}

sub is_visible {
  my ( $self , $user ) = @_;
  $user ||= $self->parent->user->current;
  $user->is_allowed_to( 'view_project' , $self );
}

sub visible_condition {
  shift if $_[0] eq __PACKAGE__;  shift if ref( $_[0] ) eq __PACKAGE__;
  my ( $user, $options ) = @_;
  &allowed_to_condition( $user, 'view_project' , $options );
}

sub allowed_to_condition {
  shift if $_[0] eq __PACKAGE__;  shift if ref( $_[0] ) eq __PACKAGE__;
  my ( $user, $permission, $options , $code ) = @_;
  my $base_statement = "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}";
  if( my $perm = Akoya::AccessControl->permission( $permission ) ){
    if( $perm->project_module ){
      # If the permission belongs to a project module, make sure the module is enabled
      $base_statement .= " AND #{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name='#{perm.project_module}')";
    }
  }
  if( $options->{project} ){
    my $project_statement = "#{Project.table_name}.id = #{options[:project].id}";
    $project_statement .= " OR (#{Project.table_name}.lft > #{options[:project].lft} AND #{Project.table_name}.rgt < #{options[:project].rgt})" if $options->{with_subprojects};
    $base_statement .= "(#{project_statement}) AND (#{base_statement})";
  }

  if( $user->is_admin ){
    return $base_statement;
  }
  my $statement_by_role = {};
  unless( $options->{member} ){
    my $role = $user->is_logged ? Akoya::Role->non_member : Akoya::Role->anonymous;
    if( $role->is_allowed_to( $permission ) ){
      $statement_by_role->{ $role } = "#{Project.table_name}.is_public = #{connection.quoted_true}"
    }
  }
  if( $user->is_logged ){
    foreach my $item( $user->projects_by_role ){
      my ( $role, $projects ) = @_;
      if( $role->is_allowed_to( $permission ) ){
        $statement_by_role->{role} = "#{Project.table_name}.id IN (#{projects.collect(&:id).join(',')})";
      }
    }
  }
  if( ! $statement_by_role ){
    "1=0";
  }
  else {
    if( $code eq 'CODE' ){
      while( my ( $role, $statement ) = %{ $statement_by_role } ){
        if( my $s = $code->( $role, $user ) ){
          $statement_by_role->{ $role } = "(#{statement} AND (#{s}))";
        }
      }
    }
    "((#{base_statement}) AND (#{statement_by_role.values.join(' OR ')}))";
  }
}

sub is_active {
  my ( $self ) = @_;
  $self->status eq $STATUS_ACTIVE ? 1 : 0;
}

sub is_archived {
  my ( $self ) = @_;
  $self->status eq $STATUS_ARCHIVED ? 1 : 0;
}

sub project_tree {
  my ( $self, $projects, $sub ) = @_;
  my @ancestors = ();
  local $Data::Dumper::Maxdepth = 2;
  warn Dumper( 'pararirapararira' , $projects );
  foreach my $project( sort { $a->{lft} <=> $b->{lft} } @{ $projects } ){ 
    while ( @ancestors && !$project->is_descendant_of( $ancestors[ $#ancestors ] ) ){
        pop @ancestors;
    }
    $sub->( $project, $#ancestors );
    push @ancestors, $project;
  }
  @ancestors;
}

1;
