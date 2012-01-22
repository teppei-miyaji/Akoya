package Models;
use DBIx::Custom::Model -base;

1
__DATA__
use feature 'switch';
use DBIx::Custom::Model -base;
use KaiBashira::Inflector;

has this_table => '';
has appname => 'Akoya';
has [qw/columns single_package/];
has [qw/relation/];
has infrector => sub{ KaiBashira::Inflector->new };

use Data::Dumper;

sub new{
  my $self = shift->SUPER::new( @_ );

  if( $self->this_table ){

    my $table = $self->this_table;
    my @all_table_columns = @{ $self->get_column_info };
    my $this_table_columns = [qw//];
    foreach my $column( @all_table_columns ){
      next unless $column->{table} eq $table;
      push @{ $this_table_columns } ,  $column->{column};
    }

    $self->single_package( $self->build_single_package( $self->infrector->singularize( $self->this_table ) ) );
    $self->columns( $this_table_columns );

    $self->setup_attr;
    $self->build_initialize;
  }
  $self;
}

sub build_single_package {
  my ( $self, $singularized ) = @_;
  my $single = $self->infrector->camelize( $singularized );
  my $appname = $self->appname;
  "${appname}::${single}";
}

sub setup_attr {
  my ( $self ) = @_;
  foreach my $column( @{ $self->columns } ){
    given( $column ){
      when( 'id' ){ has primary_key => 'id' }
      when( 'updated_on' ){ has updated_at => 'updated_on' }
      when( 'updated_at' ){ has updated_at => 'updated_at' }
      when( 'created_on' ){ has created_at => 'created_on' }
      when( 'created_at' ){ has created_at => 'created_at' }
    }
  }  
}

sub build_initialize {
  my ( $self ) = @_;

  my $target_package = $self->single_package;
  my $code = "package ${target_package};\n";
  $code .= "use Mojo::Base -base;\n";
  $code .= "has [qw/parent/];\n";
  my @attributes = @{ $self->columns };
  my $attrs = join( ' ' , @attributes );

  $code .= "has [qw/${attrs}/];\n";
  $code .= "\n";
  $code .= "sub new {\n";
  $code .= '  my $self = shift->SUPER::new( @_ );' . "\n";
  $code .= '  my $columns = $self->find;' . "\n";
  $code .= '  while( my ( $key , $value ) = each %{ $columns } ){ $self->{ $key } = $value; }' . "\n";
  $code .= '  $self;' . "\n";
  $code .= "}\n";

  if( my $relation = $self->relation ){
    $relation = $self->relation;
    my @relation_types = keys %{ $relation };

    my @attributes;
    my @use_packages;
    
    my $use_code = "\n";
    my $relation_code = "\n";

    foreach my $relation_type( @relation_types ){
      foreach my $key( keys %{ $relation->{ $relation_type } } ){
        push @attributes, $key;
        my $package = "";
        if( ref( $relation->{ $relation_type }->{ $key } ) eq 'HASH' && defined( $relation->{ $relation_type }->{ $key }->{class_name} ) ){
          $package = $relation->{ $relation_type }->{ $key }->{class_name};
        }
        else{
          $package = $key;
        }

        if( $relation_type ~~ [qw/has_and_belongs_to_many has_many/] ){
          $package = $self->infrector->singularize( $package );
        }
        push @use_packages, $self->build_single_package( $package );

        my $table = $self->infrector->underscore( $self->infrector->pluralize ( $package ) ) ;

        given( $relation_type ){
          when( 'has_and_belongs_to_many' ){
            $relation_code .= "\n";
            $relation_code .= "sub ${key} {\n";
            $relation_code .= '  my ( $self ) = @_;' . "\n";
            $relation_code .= '  $self->{' . $key . '} ||= ' . $self->build_single_package( $package ) . '->new;' . "\n";
            $relation_code .= '  $self->{' . $key . '};' . "\n";
            $relation_code .= "}\n";
          }
          when( 'has_many' ){
            $relation_code .= "\n";
            $relation_code .= "sub ${key} {\n";
            $relation_code .= '  my ( $self ) = @_;' . "\n";
            $relation_code .= '  unless( $self->{' . $key . '} ){' . "\n";
            $relation_code .= '  delete $self->{' . $key . '} );' . "\n";
            if( ref( $relation->{ $relation_type }->{ $key } ) eq 'HASH' && $relation->{ $relation_type }->{ $key }->{through} ){
              $relation_code .= '    my $through = $self->' . $relation->{ $relation_type }->{ $key }->{through} . ';' . "\n";
              $relation_code .= '    foreach my $item( @{ $through } ){' . "\n";              
              $relation_code .= '      my $result = $self->dbi->select( ' . "\n";
              $relation_code .= '        table => "' . $table . '" , ' . "\n";
              $relation_code .= '        where => { id => $item->' . $self->infrector->singularize( $table ) . '_id }'. "\n";
              $relation_code .= '      );' . "\n";
              $relation_code .= '      while( my $row = $result->one ){' . "\n";
              $relation_code .= '        push @{ $self->{' . $key . '} } , ' . $self->build_single_package( $package ) . '->new( id => $row->{id}, parent => $self->parent );' . "\n";
              $relation_code .= '      }' . "\n";
              $relation_code .= '    }' . "\n";
            }
            else{
              $relation_code .= '    my $result = $self->dbi->select( table => "' . $table . '" , where => { ' . $self->infrector->singularize( $self->this_table ) . '_id => $self->id } );' . "\n";
              $relation_code .= '    while( my $row = $result->all ){' . "\n";
              $relation_code .= '      push @{ $self->{' . $key . '} } , ' . $self->build_single_package( $package ) . '->new( id => $row->{id}, parent => $self->parent );' . "\n";
              $relation_code .= '    }' . "\n";
            }
            $relation_code .= '  }' . "\n";
            $relation_code .= '  $self->{' . $key . '};' . "\n";
            $relation_code .= "}\n";
          }
          when( 'has_one' ){
            $relation_code .= "\n";
            $relation_code .= "sub ${key} {\n";
            $relation_code .= '  my ( $self ) = @_;' . "\n";
            $relation_code .= '  unless( $self->{' . $key . '} ){' . "\n";
            $relation_code .= '    my $result = $self->dbi->select( table => "' . $table . '" , where => { ' . $self->infrector->singularize( $self->this_table ) . '_id => $self->id } );' . "\n";
            $relation_code .= '    my $row = $result->one;' . "\n";
            $relation_code .= '    $self->{' . $key . '} = ' . $self->build_single_package( $package ) . '->new( id => $row->{id}, parent => $self->parent );' . "\n";
            $relation_code .= '  }' . "\n";
            $relation_code .= '  $self->{' . $key . '};' . "\n";
            $relation_code .= "}\n";
          }
          when( 'belongs_to' ){
            my $foreign_key =
              ref( $relation->{ $relation_type }->{ $key } ) eq 'HASH' &&
              defined( $relation->{ $relation_type }->{ $key }->{foreign_key} )
                ? $relation->{ $relation_type }->{ $key }->{foreign_key} : $key . '_id';
            $relation_code .= "\n";
            $relation_code .= "sub ${key} {\n";
            $relation_code .= '  my ( $self ) = @_;' . "\n";
            $relation_code .= '  unless( $self->{' . $key . '} ){' . "\n";
            $relation_code .= '    my $result = $self->dbi->select( table => "' . $table . '" , where => { id => $self->' . $foreign_key . ' } );' . "\n";
            $relation_code .= '    my $row = $result->one;' . "\n";
            $relation_code .= '    $self->{' . $key . '} = ' . $self->build_single_package( $package ) . '->new( id => $row->{id}, parent => $self->parent );' . "\n";
            $relation_code .= '  }' . "\n";
            $relation_code .= '  $self->{' . $key . '};' . "\n";
            $relation_code .= "}\n";
          }
        }
      }
    }

    foreach my $use_package( @use_packages ){
      $use_code .= "use ${use_package};\n";
    }

    $code .= $use_code;
    $code .= $relation_code;

  }

  #find helper
  $code .= "\n";
  $code .= "sub find {\n";
  $code .= '  my ( $self , $param ) = @_;' . "\n";
  $code .= '  $param = $self->id unless $param;' . "\n";
  $code .= '  $self->parent->dbi->model("' . $self->this_table . '")->find( $param );' . "\n";
  $code .= "}\n";

  #now helper
  $code .= "\n";
  $code .= "sub now {\n";
  $code .= '  shift->parent->dbi->now;' . "\n";
  $code .= "}\n";

  #dbi shortcut
  $code .= "\n";
  $code .= "sub dbi {\n";
  $code .= '  shift->parent->dbi;' . "\n";
  $code .= "}\n";

  #select helper
  $code .= "\n";
  $code .= "sub select {\n";
  $code .= '  my ( $self , @args ) = @_;' . "\n";
  $code .= '  return undef unless $self->parent->dbi->model("' . $self->this_table . '")->count( @args );' . "\n";
  $code .= '  @{ $self->parent->dbi->model("' . $self->this_table . '")->select( @args )->all };' . "\n";
  $code .= "}\n";

  #is_new_record helper
  $code .= "\n";
  $code .= "sub is_new_record {\n";
  $code .= '  my ( $self ) = @_;' . "\n";
  $code .= '  $self->parent->dbi->model("' . $self->this_table . '")->is_new_record( $self->id );' . "\n";
  $code .= "}\n";

  #update_attribute helper
  $code .= "\n";
  $code .= "sub update_attribute {\n";
  $code .= '  my ( $self, $attribute, $value  ) = @_;' . "\n";
  $code .= '  $self->parent->dbi->model("' . $self->this_table . '")->update_attribute( $self->id, $attribute, $value );' . "\n";
  $code .= "}\n";

  $code .= "\n1;\n";
  warn $code if ref( $self ) eq 'Models::users';
  eval $code;
  if( $@ ){
	warn "catch!! $@\n";
	warn $code;
  }
}

#model functions

sub find {
  my ( $self , $option ) = @_;

  return undef unless $option;
  my $id;

  if( ref( $option ) eq 'HASH' ){
    my ( $key , $value ) = each( %{ $option } );
    return undef unless $self->count( where => { "${key}" => $value } );
    $self->select( where => { "${key}" => $value } )->one;
  }
  else {
    $id = $option;
    return undef unless $self->count( primary_key => 'id' , id => $id );
    $self->select( primary_key => 'id' , id => $id )->one;
  }
}

sub is_new_record {
  my ( $self , $id ) = @_;
  $self->find( $id ) ? 0 : 1;
}

sub update_attribute {
  my ( $self , $id, $attribute , $value ) = @_;
  $self->update( { "$attribute" => $value } , primary_key => 'id', id => $id );
}

1;
