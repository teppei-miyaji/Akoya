package Akoya::CustomFieldFormat;
use Mojo::Base 'Mojolicious::Plugin';

has [qw/name order label edit_as class_names/];

sub register {
  my ( $self , $app ) = @_;
  my $custom_field_format = __PACKAGE__->new;
  $app->helper( custom_field_format => sub{ $custom_field_format; } );
}

sub new {
  my $self = shift->SUPER::new( @_ );
  $self->{label} = $self->{options}->{label};
  $self->{order} = $self->{options}->{order};
  $self->{edit_as} = $self->{options}->{edit_as} || $self->name;
  $self->{class_names} = $self->{options}->{only};
  $self;
}

sub format {
  my ( $self , @value ) = @_;
  &{ "format_as_" . $self->name }( $self , @value );
}

sub format_as_date {
  my ( $self , $value ) = @_;
  format_date($value);
}

sub format_as_bool {
  my ( $self , $value ) = @_;
  l( $value == "1" ? "general_text_Yes" : "general_text_No");
}

foreach my $name ( qw/string text int float list/ ){
  no strict 'refs';
  *{"format_as_$name"} = sub {
    my ( $self , $value ) = @_;
    $value;
  };
}

foreach my $name ( qw/user version/ ){
  no strict 'refs';
  *{"format_as_$name"} = sub {
    my ( $self , $value ) = @_;
    $value ? $self->name : "";
  };
}

sub map {
  my ( $self , $sub ) = @_;
  $sub->( $self );
}

sub entry {
  my ( $self , $custom_field_format, $options ) = @_;
  $self->{available}->{ $custom_field_format->name } = $custom_field_format unless $self->{available}->{ $custom_field_format->name };
}

sub available_formats {
  keys %{ shift->{available} };
}

sub find_by_name {
  my ( $self , $name ) = @_;
  $self->{available}->{ $name };
}

sub label_for {
  my ( $self , $name ) = @_;
  my $format = $self->{available}->{name};
  $format->label if $format;
}

sub as_select {
  my ( $self , $class_name ) = @_;
  my @fields;
  map { push @fields , $self->{available}->{ $_ } } keys %{ $self->{available} };
  my @select_fields;
  foreach my $field ( @fields ) {
    push @select_fields , ! $field->class_names || $field->class_names eq $class_name ? $field : undef;
  }
  push my @collect_fields , sort { $a->order <=> $b->order } @select_fields;
  map { $_ = [ l( $_->label ) , $_->name ] } @collect_fields;
  @collect_fields;
}

1;