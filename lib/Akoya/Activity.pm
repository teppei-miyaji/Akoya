package Akoya::Activity;
use Mojo::Base 'Mojolicious::Plugin';
use KaiBashira::Hash;
use Mojo::ByteStream qw/b/;

sub register {
  my ( $self , $app ) = @_;
  my $activity = __PACKAGE__->new;
  $app->helper( activity => sub{ $activity; } );
}

sub map {
  my ( $self , $sub ) = @_;
  $sub->( $self );
}

sub entry {
  my ( $self , $event_type , $options ) = @_;
  my $hash_check = KaiBashira::Hash->new;
  $hash_check->assert_valid_keys( $options , qw/class_name default/ );

  my @providers = ();
  if( $options->{class_name} ){
    if( ref( $options->{class_name} ) eq q|ARRAY| ){
      push @providers , @{ $options->{class_name} };
    }
    else{
      push @providers , $options->{class_name};
    }
  }
  else{
    push @providers , b( $event_type )->camelize->to_string;
  }

  $self->{available_event_types}->{ $event_type } = $event_type unless $self->{available_event_types}->{ $event_type };
  $options->{default} = 1 unless defined $options->{default};
  $self->{default_event_types}->{ $event_type } = $event_type unless $options->{default} == 0;
  push @{ $self->{providers}->{ $event_type } } , @providers;
}

1;