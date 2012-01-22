package KaiBashira::Base;
use strict;
use warnings;
require feature;
require Carp;

sub import {
  my $class = shift;
  return unless my $flag = shift;
  no strict 'refs';
  no warnings 'once';
  no warnings 'redefine';
  if ($flag eq '-base') { $flag = $class }
  elsif ($flag eq '-strict') { $flag = undef }
  else {
    my $file = $flag;
    $file =~ s/::|'/\//g;
    require "$file.pm" unless $flag->can('new');
  }

  if ($flag) {
    my $caller = caller;
    push @{"${caller}::ISA"}, $flag;
    *{"${caller}::self"} = {} unless *{"${caller}::self"};
    *{"${caller}::has"} = sub { attr($caller, @_) };
    *{"${caller}::pub"} = sub { class_value($caller, @_) };
  }
  strict->import;
  warnings->import;
  feature->import(':5.10');
}

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub attr {
  my ($class, $attrs, $default) = (shift, shift, shift);

  Carp::croak('Attribute generator called with too many arguments') if @_;
  return unless $class && $attrs;
  $class = ref $class || $class;

  Carp::croak('Default has to be a code reference or constant value')
    if ref $default && ref $default ne 'CODE';

  $attrs = [$attrs] unless ref $attrs eq 'ARRAY';
  my $ws = '  ';
  for my $attr (@$attrs) {

    Carp::croak(qq/Attribute "$attr" invalid/)
      unless $attr =~ /^[a-zA-Z_]\w*$/;

    my $code = "sub {\n";

    $code .= "${ws}if (\@_ == 1) {\n";
    unless (defined $default) {

      $code .= "$ws${ws}return \$_[0]->{'$attr'};\n";
    }
    else {

      $code .= "$ws${ws}return \$_[0]->{'$attr'} ";
      $code .= "if exists \$_[0]->{'$attr'};\n";

      $code .= "$ws${ws}return \$_[0]->{'$attr'} = ";
      $code .=
        ref $default eq 'CODE'
        ? '$default->($_[0])'
        : '$default';
      $code .= ";\n";
    }
    $code .= "$ws}\n";

    $code .= "$ws\$_[0]->{'$attr'} = \$_[1];\n";

    $code .= "${ws}\$_[0];\n";

    $code .= '};';

    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::$attr"} = eval $code;

    Carp::croak("KaiBashira::Base compiler error: \n$code\n$@\n") if $@;

    if ($ENV{MOJO_BASE_DEBUG}) {
      warn "\nATTRIBUTE: $class->$attr\n";
      warn "$code\n\n";
    }
  }
}

sub class_value {
  my ($class, $attrs, $default) = (shift, shift, shift);

  Carp::croak('class value generator called with too many arguments') if @_;
  return unless $class && $attrs;
  $class = ref $class || $class;

  Carp::croak('Default has to be a code reference or constant value')
    if ref $default && ref $default ne 'CODE';

  $attrs = [$attrs] unless ref $attrs eq 'ARRAY';
  my $ws = '  ';
  for my $attr (@$attrs) {

    Carp::croak(qq/Class value "$attr" invalid/)
      unless $attr =~ /^[a-zA-Z_]\w*$/;

    my $code = "sub {\n";

    $code .= "${ws}if (\@_ == 1) {\n";
    unless (defined $default) {

      $code .= "$ws${ws}return *{\"${class}::self\"}->{'$attr'};\n";
    }
    else {

      $code .= "$ws${ws}return *{\"${class}::self\"}->{'$attr'} ";
      $code .= "if exists *{\"${class}::self\"}->{'$attr'};\n";

      $code .= "$ws${ws}return *{\"${class}::self\"}->{'$attr'} = ";
      $code .=
        ref $default eq 'CODE'
        ? '$default->( *{"${class}::self"}, $attr )'
        : '$default';
      $code .= ";\n";
    }
    $code .= "$ws}\n";

    $code .= "$ws*{\"${class}::self\"}->{'$attr'} = \$_[1];\n";

    $code .= "${ws}*{\"${class}::self\"}->{'$attr'};\n";

    $code .= '};';

    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::$attr"} = eval $code;

    Carp::croak("KaiBashira::Base compiler error: \n$code\n$@\n") if $@;

    if ($ENV{MOJO_BASE_DEBUG}) {
      warn "\nATTRIBUTE: $class->$attr\n";
      warn "$code\n\n";
    }
  }
}

1;