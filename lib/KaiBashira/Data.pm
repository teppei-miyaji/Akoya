package KaiBashira::Data;
use feature 'switch';
use lib qw|/Users/tripper/akoya/lib|;
use Module::Load;
use KaiBashira::Base -base;
use Carp;

use Data::Dumper;

our $appname = 'Akoya';
has [qw/parent/];
pub infrector => sub{ KaiBashira::Inflector->new };
has 'auto_hook';

pub table => "";
pub 'relay';

sub import {
  my $class = shift;
  return unless my $flag = shift;

  no strict 'refs';
  no warnings 'redefine';

  if ($flag) {
    my $caller = caller;
    push @{"${caller}::ISA"}, $class;

    unless($flag eq '-base') {
      if( $flag->relay ){
        $caller->relay( $flag->relay );
      } 
    }

    *{"${caller}::column"} = sub { set_column( @_) };
    *{"${caller}::belongs_to"} = sub { set_belongs_to( @_) };
    *{"${caller}::has_many"} = sub { set_has_many( @_) };
    *{"${caller}::has_one"} = sub { set_has_one( @_) };
    *{"${caller}::has_and_belongs_to_many"} = sub { set_has_and_belongs_to_many( @_) };

  }

  strict->import;
  warnings->import;
  feature->import(':5.10');
}

#self
sub set_relay_type { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  my ( %hash ) = @_;
  __PACKAGE__->relay( {} ) unless __PACKAGE__->relay;
  __PACKAGE__->relay->{ $hash{name} } = \%hash if $hash{name};
}

sub set_belongs_to { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  my ( %hash ) = @_;
  __PACKAGE__->set_relay_type( %hash , type => 'belongs_to' );
}

sub set_has_many { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  my ( %hash ) = @_;
  __PACKAGE__->set_relay_type( %hash , type => 'has_many' );
}

sub set_has_one { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  my ( %hash ) = @_;
  __PACKAGE__->set_relay_type( %hash , type => 'has_one' );
}

sub set_has_and_belongs_to_many { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  my ( %hash ) = @_;
  __PACKAGE__->set_relay_type( %hash , type => 'has_and_belongs_to_many' );
}

sub appname { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  $appname = shift if defined( $_[0] );
  $appname;
}

sub gen_package_name { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  return unless defined( $_[0] );
  sprintf "%s::Data::%s" , $appname , __PACKAGE__->infrector->camelize( __PACKAGE__->infrector->singularize( $_[0] ) );
}

#instance
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

sub find_first {
  my ( $self , $where , $options ) = @_;
  my $table = ref( $options ) eq 'HASH' && defined( $options->{table} ) ? delete $options->{table} : $self->table;
  croak 'need $table value.' unless $self->table;
  croak 'need where argument' unless $where;

  return undef unless $self->parent->dbi->count( table => $table , where => $where );

  my $package = ref( $self );

  warn Dumper( $table );
  my $result = $self->parent->dbi->select( table => $table , where => $where )->one;
  $package->new( %{ $result } , parent => $self->parent );
}

sub find {
  my ( $self , $where , $options ) = @_;
  my $table = ref( $options ) eq 'HASH' && defined( $options->{table} ) ? delete $options->{table} : $self->table;
  croak 'need $table value.' unless $table;
  croak 'need where argument' unless $where;

  my $join = defined( $options->{join} ) ? delete $options->{join} : undef;
  warn Dumper( $join );
  return undef unless $self->parent->dbi->count( table => $table , where => $where , join => $join , %{ $options } );

  my $package = ref( $self );

  my $result = $self->parent->dbi->select( table => $table , where => $where , join => $join , %{ $options } );

  my @results;
  while( my $row = $result->fetch_hash ){
    push @results, $package->new( %{ $result } , parent => $self->parent );
  }
  wantarray ? @results : \@results;
}

sub count {
  my ( $self , @args ) = @_;
  my $count = $self->parent->dbi->count( table => $self->table , @args );
  $count;
}

sub select {
  my ( $self , @args ) = @_;
  return undef unless $self->parent->dbi->count( table => $self->table , @args );
  @{ $self->parent->dbi->select( table => $self->table , @args )->all };
}

sub is_new_record {
  $_[0]->id ? 0 : 1;
}

sub do_relay {
  my ( $self , $relation_name, @args ) = @_;
  my $type = __PACKAGE__->relay->{ $relation_name }->{type};
  given( $type ){
    when( 'belongs_to' ){ $self->do_belongs_to( $relation_name, @args ) }
    when( 'has_many' ){ $self->do_has_many( $relation_name, @args ) }
    when( 'has_one' ){ $self->do_has_one( $relation_name, @args ) }
    when( 'has_and_belongs_to_many'){ $self->do_has_and_belongs_to_many( $relation_name, @args ) }
  }
}

sub do_belongs_to {
  my ( $self , $relation_name, @args ) = @_;

  my $relation = __PACKAGE__->relay->{ $relation_name };

  my $package = "";
  if( defined( $relation->{class_name} ) ){
    $package = $relation->{class_name};
  }
  else{
    $package = $relation->{name};
  }

  my $table = $self->infrector->underscore( $self->infrector->pluralize( $package ) ) ;
  my $foreign_key = "";
  if( defined( $relation->{foreign_key} ) ){
    $foreign_key = $relation->{foreign_key};
  }
  else{
    $foreign_key = join( '_' , $self->infrector->singularize( $table ) , 'id' );
  }

  my $full_package = __PACKAGE__->gen_package_name( $package );
  my $relay_object = $full_package->new( parent => $self->parent );
  my $result = $relay_object->find_first( { "id" => $self->{$foreign_key} } );
  $result ? $result : $relay_object->new( parent => $self->parent );
}

sub do_has_many {
  my ( $self , $relation_name, @args ) = @_;

  my $relation = __PACKAGE__->relay->{ $relation_name };

  my $package = "";
  if( defined( $relation->{class_name} ) ){
    $package = $relation->{class_name};
  }
  else{
    $package = $relation->{name};
  }

  my $table = $self->infrector->underscore( $self->infrector->pluralize ( $package ) ) ;
  my $foreign_key = "";
  if( defined( $relation->{foreign_key} ) ){
    $foreign_key = $relation->{foreign_key};
  }
  else{
    $foreign_key = join( '_' , $self->infrector->singularize( $self->table ) , 'id' );
  }

  my $where;
  $where->{"${foreign_key}"} = $self->{id} ;

  if( defined( $relation->{conditions} ) ){
    while( my ( $key , $value ) = each ( %{ $relation->{conditions} } ) ){
      $where->{"${key}"} = $value;
    }
  }

  my $options = {};
  $options->{table} = $table;
  if( $relation->{include} ){
    if( ref( $relation->{include} ) eq 'ARRAY' ){
      warn Dumper( $relation->{include} );
      foreach my $item( @{ $relation->{include} } ){
        my $join = sprintf(
          "left outer join %s on %s.%s_id = %s.id" ,
          $self->infrector->pluralize( $item ) ,
          $table ,
          $self->infrector->singularize( $item ) ,
          $self->infrector->pluralize( $item )
        );
        push @{ $options->{join} } , $join;
      }
    }
    else{
      $options->{join} = sprintf(
        "left outer join %s on %s.%s_id = %s.id" ,
        $self->infrector->pluralize( $relation->{include} ) ,
        $table ,
        $self->infrector->singularize( $relation->{include} ) ,
        $self->infrector->pluralize( $relation->{include} )
      );
    }
  }
  warn Dumper( $options->{join} );
  my $full_package = __PACKAGE__->gen_package_name( $package );
  load ${full_package};
  my $relay_object = $full_package->new( parent => $self->parent );
  my $result = $relay_object->find( $where , $options );
  $result ? $result : $relay_object->new( parent => $self->parent );
}

sub do_has_one {
  my ( $self , $relation_name, @args ) = @_;

  my $relation = __PACKAGE__->relay->{ $relation_name };

  my $package = "";
  if( defined( $relation->{class_name} ) ){
    $package = $relation->{class_name};
  }
  else{
    $package = $relation->{name};
  }

  my $table = $self->infrector->underscore( $self->infrector->pluralize ( $package ) ) ;
  my $foreign_key = "";
  if( defined( $relation->{foreign_key} ) ){
    $foreign_key = $relation->{foreign_key};
  }
  else{
    $foreign_key = join( '_' , $self->infrector->singularize( $self->table ) , 'id' );
  }

  my $where;
  $where->{ "${foreign_key}" } = $self->{id} ;

  if( defined( $relation->{conditions} ) ){
    while( my ( $key , $value ) = each ( %{ $relation->{conditions} } ) ){
      $where->{ "${key}" } = $value;
    }
  }

  my $full_package = __PACKAGE__->gen_package_name( $package );
  my $relay_object = $full_package->new( parent => $self->parent );
  my $result = $relay_object->find_first( $where , { table => $table } );
  $result ? $result : $relay_object->new( parent => $self->parent );
}

BEGIN{}
DESTROY{}

sub AUTOLOAD{
    our $AUTOLOAD;
    my ( $self ,  @arg ) = @_; # 関数名と引数を受け取れます。
 
    my @package_path = split( /::/, $AUTOLOAD );
 
    if( $package_path[$#package_path] ~~ [ keys( __PACKAGE__->relay ) ] ){
      return $self->do_relay( $package_path[$#package_path], @arg );
    }
 
    my @caller = caller(0);
    print "AUTOLOAD が呼び出されました。\n";
    print "呼び出そうとした関数は、 $AUTOLOAD です。\n";
    print "引数は、", join( ',', @arg ), "です。\n";
    print "呼び出しは、", join( ',', @caller ), "です。\n";
    undef;
}

1;