package KaiBashira::Tree;
use Mojo::Base -base;
use Carp;

has [qw/content name parent/];

sub new {
  my $self = shift->SUPER::new( @_ );
  $self->set_as_root;
  $self->{children_hash} = {};
  @{ $self->{children} } = ();
  $self;
}

sub detached_copy {
  my ( $self ) = @_;
  __PACKAGE__->new( __PACKAGE__ , $self->name , $self->content ? $self->content : undef );
}

sub to_s {
  my ( $self ) = @_;
  "Node Name: " . $self->name .
    "Content: " . ( $self->content || "<Empty>" ) .
    "Parent: " . ( $self->is_root ? "<None>" : $self->parent ) .
    "Children: " . $self->children->length;
    "Total Nodes: " . $self->size;
}

sub parentage {
  my ( $self ) = @_;
  return undef if $self->is_root;

  my @parentage_array = ();
  my $prev_parent = $self->parent;
  while( $prev_parent ){
    push @parentage_array , $prev_parent;
    $prev_parent = $prev_parent->parent;
  }

  @parentage_array;
}

#sub parent{
#  my ( $self , $parent ) = @_;
#  $self->{parent} = $parent;
#}

sub lt_lt {
  my ( $self , $child ) = @_;
  $self->add( $child );
}

sub add {
  my ( $self , $child ) = @_;
  croak "Child already added" if $self->{children}->{ $child->name };

  $self->{children_hash}->{ $child->name } = $child;                                                                                                                                                                                                                                                                                                                                                                 
}

sub remove {
  my ( $self , $child ) = @_;
  delete $self->{children_hash}->{ $child->name };
  foreach my $index ( 0 .. scalar( @{ $self->{children} } ) ) {
    if( $self->{children}->[ $index ] ~~ $child ) {
      delete $self->{children}->[ $index ];
      last;
    }
  }
  $child->set_as_root unless $child;
  $child;
}

sub remove_from_parent{
  my ( $self ) = @_;
  $self->parent->remove( $self ) unless $self->is_root;
}

sub remove_all {
  my ( $self ) = @_;
  foreach my $child ( @{ $self->{children} } ) {
   $child->set_as_root;
  }

  $self->{children_hash} = {};
  @{ $self->{children} } = ();
  $self;
}

sub has_content {
  my ( $self ) = @_;
  $self->content ? 1 : 0;
}

sub set_as_root {
  my ( $self ) = @_;
  $self->parent( undef );
}

sub is_root {
  my ( $self ) = @_;
  $self->parent ? 0 : 1;
}

sub has_children {
  my ( $self ) = @_;
  scalar( @{ $self->{children} } ) ? 1 : 0;
}

sub is_leaf {
  my ( $self ) = @_;
  $self->has_children ? 0 : 1;
}

sub children {
  my ( $self , $code ) = @_;
  if( ref( $code ) eq 'CODE' ) {
    foreach my $child( @{ $self->{children} } ){
      $code->( $child );
    }
  }
  else {
    @{ $self->{children} };
  }
}

sub root {
  my ( $self ) = @_;
  my $root = $self;
  while( ! $root->is_root ){ $root = $root->parent }
  $root;
}
  
1;