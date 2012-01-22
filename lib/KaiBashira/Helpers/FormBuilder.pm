package KaiBashira::Helpers::FormBuilder;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';

has [qw/parent/];
has [qw/base_name builder_target/];

sub register {
  my ( $self , $app ) = @_;

  $app->helper(
    form_builder_base => sub {
      my ( $c , $base_name , $builder_target ) = @_;
      __PACKAGE__->new( base_name => $base_name , builder_target => $builder_target , parent => $c );
    }
  );
}

sub text_field {
  my ( $self , $name , $options ) = @_;
  my $tag = '';
  $tag .= sprintf('<label for="%s_%s">' , $self->base_name , $name );
  $tag .= $self->parent->l( 'field_' . $name );
  $tag .= '<span class="required"> *</span>' if $options->{required};
  $tag .= '</label>';
  $tag .= sprintf(
    '<input id="%s_%s" name="%s[%s]" size="30" type="text" value="%s" />',
    $self->base_name , $name ,
    $self->base_name , $name ,
    $self->builder_target->{ $name }
  );
  $tag;
}

sub select {
  my ( $self , $name , @items ) = @_;
  my $tag = '';
  $tag .= sprintf('<label for="%s_%s">' , $self->base_name , $name );
  $tag .= $self->parent->l( 'field_' . $name );
  $tag .= '</label>';
  $tag .= sprintf(
    '<select id="%s_%s" name="%s[%s]">',
    $self->base_name , $name ,
    $self->base_name , $name ,
  );
  $tag .= '<option value="">(auto)</option>';
  foreach my $item( $self->parent->a_flatten( @items ) ){

    my ( $value , $view ) = each( %{ $item } );
    if( ( $self->builder_target->{ $name } || "" ) eq "${value}" ){
      $tag .= "\n" . sprintf( '<option value="%s" selected="selected">%s</option>' , $value , b( $view )->decode('UTF8')->to_string );
    }
    else {
      $tag .= "\n" . sprintf( '<option value="%s">%s</option>' , $value , $view );
    }
  }
  $tag .= '</select>';
  $tag;
}

sub check_box {
  my ( $self , $name , $options ) = @_;
  my $tag = '';
  $tag .= sprintf('<label for="%s_%s">' , $self->base_name , $name );
  $tag .= $self->parent->l( 'field_' . $name );
  $tag .= '<span class="required"> *</span>' if $options->{required};
  $tag .= '</label>';
  $tag .= sprintf(
    '<input name="%s[%s]" type="hidden" value="0" />',
    $self->base_name , $name
  );
  $tag .= sprintf(
    '<input id="%s_%s" name="%s[%s]" size="30" type="checkbox" value="%s" />',
    $self->base_name , $name ,
    $self->base_name , $name ,
    $self->builder_target->{ $name } eq 't' ? 1 :0
  );
  $tag;
}

1;