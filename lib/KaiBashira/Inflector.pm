package KaiBashira::Inflector;
use Mojo::Base -base;
use Encode qw/encode decode/;
use Encode::Guess;

has inflections_instance => sub { KaiBashira::Inflector::Inflections->new };

sub new {
  my $self = shift->SUPER::new( @_ );
  $self->inflections( sub { my ( $inflect ) = @_;
    $inflect->plural(qr/$/, "s");
    $inflect->plural(qr/s$/i, "s");
    $inflect->plural(qr/(ax|test)is$/i, "es");
    $inflect->plural(qr/(octop|vir)us$/i, "i");
    $inflect->plural(qr/(alias|status)$/i, "es");
    $inflect->plural(qr/(bu)s$/i, "ses");
    $inflect->plural(qr/(buffal|tomat)o$/i, "oes");
    $inflect->plural(qr/([ti])um$/i, "a");
    $inflect->plural(qr/sis$/i, "ses");
    $inflect->plural(qr/(?:([^f])fe|([lr])f)$/i, "ves");
    $inflect->plural(qr/(hive)$/i, "s");
    $inflect->plural(qr/([^aeiouy]|qu)y$/i, "ies");
    $inflect->plural(qr/(x|ch|ss|sh)$/i, "es");
    $inflect->plural(qr/(matr|vert|ind)(?:ix|ex)$/i, "ices");
    $inflect->plural(qr/([m|l])ouse$/i, "ice");
    $inflect->plural(qr/^(ox)$/i, "en");
    $inflect->plural(qr/(quiz)$/i, "zes");

    $inflect->singular(qr/s$/i, "");
    $inflect->singular(qr/(n)ews$/i, "ews");
    $inflect->singular(qr/([ti])a$/i, "um");
    $inflect->singular(qr/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$/i, "sis");
    $inflect->singular(qr/(^analy)ses$/i, "sis");
    $inflect->singular(qr/([^f])ves$/i, "fe");
    $inflect->singular(qr/(hive)s$/i, "");
    $inflect->singular(qr/(tive)s$/i, "");
    $inflect->singular(qr/([lr])ves$/i, "f");
    $inflect->singular(qr/([^aeiouy]|qu)ies$/i, "y");
    $inflect->singular(qr/(s)eries$/i, "eries");
    $inflect->singular(qr/(m)ovies$/i, "ovie");
    $inflect->singular(qr/(x|ch|ss|sh)es$/i, "");
    $inflect->singular(qr/([m|l])ice$/i, "ouse");
    $inflect->singular(qr/(bus)es$/i, "");
    $inflect->singular(qr/(o)es$/i, "");
    $inflect->singular(qr/(shoe)s$/i, "");
    $inflect->singular(qr/(cris|ax|test)es$/i, "is");
    $inflect->singular(qr/(octop|vir)i$/i, "us");
    $inflect->singular(qr/(alias|status)es$/i, "");
    $inflect->singular(qr/^(ox)en/i, "");
    $inflect->singular(qr/(vert|ind)ices$/i, "ex");
    $inflect->singular(qr/(matr)ices$/i, "ix");
    $inflect->singular(qr/(quiz)zes$/i, "");
    $inflect->singular(qr/(database)s$/i, "");

    $inflect->irregular('person', 'people');
    $inflect->irregular('man', 'men');
    $inflect->irregular('child', 'children');
    $inflect->irregular('sex', 'sexes');
 #   $inflect->irregular('move', 'moves');
    $inflect->irregular('cow', 'kine');
 
    $inflect->plural(qr/move$/i, "moves");
    $inflect->singular(qr/moves$/i, "move");

    $inflect->uncountable(qw/equipment information rice money species series fish sheep jeans/);
  } );
  $self;
}

sub inflections {
  my ( $self , $sub ) = @_;
  if( ref( $sub ) eq q|CODE| ){
    $sub->( $self->inflections_instance );
  }
  else{
    $self->inflections_instance;
  }
}

sub capitalize {
  my ( $self , $word ) = @_;
  ucfirst( lc( "$word" ) );
}

sub pluralize {
  my ( $self , $word ) = @_;
  my $result = "$word";

  return $result unless $word;

  foreach my $include( @{ $self->inflections_instance->{uncountables} } ){
    return $result if $include ~~ lc( $result );
  }

  my @plurals = @{ $self->inflections_instance->{plurals} };
  for( my $i = 0 ; $i < @plurals ; $i += 2 ){
    my $rule = $plurals[$i];
    my $replacement = $plurals[$i+1];
    if( $result =~ /$rule/ ){
      my $pre = $` || "";
      my $res1 = $1 || "";
      my $res2 = $2 || "";
      $result = join("",$pre,$res1,$res2,$replacement);
      last;
    }
  }

  $result;
}

sub singularize {
  my ( $self , $word ) = @_;
  my $result = "$word";

  return $result unless $word;

  foreach my $inflection( @{ $self->inflections_instance->{uncountables} } ){
    return $result if $result =~ /$inflection¥Z/i;
  }
  my @singulars = @{ $self->inflections_instance->{singulars} };
  for( my $i = 0 ; $i < @singulars ; $i += 2 ){
    my $rule = $singulars[$i];
    my $replacement = $singulars[$i+1];
    if( $result =~ /$rule/ ){
      my $pre = $` || "";
      my $res1 = $1 || "";
      my $res2 = $2 || "";
      $result = join("",$pre,$res1,$res2,$replacement);
      last;
    }
  }

  $result;

}

sub camelize {
  my ( $self , $lower_case_and_underscored_word , $first_letter_in_uppercase ) = @_;
  $first_letter_in_uppercase = 1 unless defined $first_letter_in_uppercase;
  if( $first_letter_in_uppercase ){
    $lower_case_and_underscored_word =~ s|/(.?)|"::" . uc($1)|ge;
    $lower_case_and_underscored_word =~ s/(?:^|_)(.)/uc($1)/ge;
  }
  else{
    $lower_case_and_underscored_word = lcfirst( $self->camelize( $lower_case_and_underscored_word ) );
  }
  $lower_case_and_underscored_word;
}

sub titleize {
  my ( $self , $word ) = @_;
  my $underscore = $self->humanize( $self->underscore ( "$word" ) );
  $underscore =~ s/¥b('?[a-z])/$self->capitalize($1)/ge;
}

sub underscore {
  my ( $self , $camel_cased_word ) = @_;
  $camel_cased_word =~ s|::|/|g;
  $camel_cased_word =~ s|([A-Z]+)([A-Z][a-z])|$1_$2|g;
  $camel_cased_word =~ s|([a-z\d])([A-Z])|$1_$2|g;
  $camel_cased_word =~ tr|-|_|;
  lc( $camel_cased_word );
}

sub dasherize {
  my ( $self , $underscored_word ) = @_;
  $underscored_word =~ s/_/-/g;
  $underscored_word;
}

sub humanize {
  my ( $self , $lower_case_and_underscored_word ) = @_;
  my $result = "$lower_case_and_underscored_word";

  my @humans = @{ $self->inflections_instance->{singulars} };
  for( my $i = 0 ; $i < @humans ; $i += 2 ){
    my $rule = $humans[$i];
    my $replacement = $humans[$i+1];
    $result =~ s/$rule/$replacement/;
    last unless $result eq $lower_case_and_underscored_word;
  }
  $result =~ s/_id$//g;
  $result =~ s/_/ /g;
  $self->capitalize( $result );
}

sub demodulize { #not perlism. this function is plain translation.
  my ( $self , $class_name_in_module ) = @_;
  $class_name_in_module =~ s/^.*:://;
  $class_name_in_module;
}

sub parameterize {
  my ( $self , $string , $sep ) = @_;
  $sep ||= '-';
  $string = decode("Guess", $string);
  my $parameterized_string = $self->transliterate( $string );
  $parameterized_string =~ s/[^a-z0-9\-_]+/$sep/gi;
  if( $sep ){
    # no idea. :(
    #re_sep = Regexp.escape(sep)
    #parameterized_string.gsub!(/#{re_sep}{2,}/, sep)
    #parameterized_string.gsub!(/^#{re_sep}|#{re_sep}$/i, '')
  }
  lc( $parameterized_string );
}

sub transliterate {
  my ( $self , $string ) = @_;
  encode( 'ascii' , $string );
}

sub tableize {
  my ( $self , $class_name ) = @_;
  $self->pluralize( $self->underscore( $class_name ) );
}

package KaiBashira::Inflector::Inflections;
use feature 'switch';
use Mojo::Base -base;
has [qw/plurals singulars uncountables humans/];

sub new {
  my $self = shift->SUPER::new( @_ );
  @{ $self->{plurals} } = (); 
  @{ $self->{singulars} } = ();
  @{ $self->{uncountables} } = ();
  @{ $self ->{humans} } = ();
  $self;
}

sub plural {
  my ( $self , $rule, $replacement ) = @_;
  @{ $self->{uncountables} } = map{ undef $_ if $_ ~~ $rule } @{ $self->{uncountables} }
  if ref( $rule ) eq q|SCALAR|;
  @{ $self->{uncountables} } = map{ undef $_ if $_ ~~ $replacement } @{ $self->{uncountables} };
  splice( @{ $self->{plurals} } , 0 , 0 , $rule , $replacement );
}

sub singular {
  my ( $self , $rule, $replacement ) = @_;
  @{ $self->{uncountables} } = map{ undef $_ if $_ ~~ $rule } @{ $self->{uncountables} }
  if ref( $rule ) eq q|SCALAR|;
  @{ $self->{uncountables} } = map{ undef $_ if $_ ~~ $replacement } @{ $self->{uncountables} };
  splice( @{ $self->{singulars} } , 0 , 0 , $rule , $replacement );
}

sub irregular {
  my ( $self , $singular , $plural ) = @_;
  @{ $self->{uncountables} } = map{ undef $_ if $_ ~~ $singular } @{ $self->{uncountables} };
  @{ $self->{uncountables} } = map{ undef $_ if $_ ~~ $plural } @{ $self->{uncountables} };
  if( uc( substr( $singular , 0 ,1 ) ) eq uc( substr( $plural , 0 ,1 ) ) ){
    my $singular_regex_base = '(' . substr( $singular , 0 ,1 ) . ')' . substr ( $singular , 1 ) . '$';
    my $singular_regex = qr/${singular_regex_base}/i;
    $self->plural( $singular_regex , $singular );
  
    my $plural_regex_base = '(' . substr( $plural , 0 ,1 ) . ')' . substr ( $plural , 1 ) . '$';
    my $plural_regex = qr/${plural_regex_base}/i;
    $self->singular( $plural_regex , $plural );
  }
  else {
    my $singular_regex_up_base = uc( substr( $singular , 0 ,1 ) ) . q|(?i)| . substr ( $singular , 1 ) . '$';
    my $singular_regex_up = qr/${singular_regex_up_base}/i;
    my $singular_replace_up = substr ( $singular , 1 );
    $self->plural( $singular_regex_up , $singular_replace_up );
    my $singular_regex_down_base = lc( substr( $singular , 0 ,1 ) ) . q|(?i)| . substr ( $singular , 1 ) . '$';
    my $singular_regex_down = qr/${singular_regex_down_base}/i;
    my $singular_replace_down = substr ( $singular , 1 );
    $self->plural( $singular_regex_down , $singular_replace_down );

    my $plural_regex_up_base = uc( substr( $plural , 0 ,1 ) ) . substr ( $plural , 1 ) . '$';
    my $plural_regex_up = qr/${plural_regex_up_base}/i;
    my $plural_replace_up = substr ( $plural , 1 );
    $self->singular( $plural_regex_up , $plural_replace_up );
    my $plural_regex_down_base = lc( substr( $plural , 0 ,1 ) ) . substr ( $plural , 1 ) . '$';
    my $plural_regex_down = qr/${plural_regex_down_base}/i;
    my $plural_replace_down = substr ( $plural , 1 );
    $self->singular( $plural_regex_down , $plural_replace_down );
  } 
}

sub uncountable {
  my ( $self , @words ) = @_;
  push @{ $self->{uncountables} } , @words;
}

sub human {
  my ( $self , $rule , $replacement ) = @_;
  splice( @{ $self->{humans} } , 0 , 0 , $rule , $replacement );
}

sub clear {
  my ( $self , $scope ) = @_;
  $scope ||= 'all';
  given( $scope ){
    when( 'all' ){
      @{ $self->{plurals} } = (); 
      @{ $self->{singulars} } = ();
      @{ $self->{uncountables} } = ();
    }
    default {
      @{ $self->{ $scope } } = ();
    }
  }
}

1;

