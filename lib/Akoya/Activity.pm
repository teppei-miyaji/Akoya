package Akoya::Activity;
use KaiBashira::Base -base;
use KaiBashira::Hash;
use Mojo::ByteStream qw/b/;

pub activity => sub { {} };

sub map { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  my ( $sub ) = @_;
  $sub->( __PACKAGE__->activity );
}

sub entry { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  my ( $event_type , $options ) = @_;
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

  __PACKAGE__->activity->{available_event_types}->{ $event_type } = $event_type unless __PACKAGE__->activity->{available_event_types}->{ $event_type };
  $options->{default} = 1 unless defined $options->{default};
  __PACKAGE__->activity->{default_event_types}->{ $event_type } = $event_type unless $options->{default} == 0;
  push @{ __PACKAGE__->activity->{providers}->{ $event_type } } , @providers;
}

1;