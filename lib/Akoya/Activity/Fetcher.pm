package Akoya::Activity::Fetcher;
use lib qw|/Users/tripper/akoya/lib|;
use KaiBashira::Base -base;

has [qw/user project scope/];

our $constantized_providers = {};

sub new {
  my $self = shift->SUPER::new( @_ );
  #$self->{options}->assert_valid_keys(:project, :with_subprojects, :author)
  #@user = user
  $self->project( $self->{options}->{project} );
  #@options = options

  #@scope = event_types
  $self;
}

sub event_types {
  my ( $self ) = @_;
  return $self->{event_types} if $self->{event_types};

  $self->{event_types} = Akoya::Activity->available_event_types;
  if( $self->project ){
    my @result;
    foreach my $o( @{ $self->{event_types} } ){
    }
    $self->{event_types} = \@result; #@event_types.select {|o| @project.self_and_descendants.detect {|p| @user.allowed_to?("view_#{o}".to_sym, p)}} if @project
  }
  $self->{event_types};
}

sub events {
  my ( $self , $from, $to, $options ) = @_;
  $from = undef unless $from;
  $to = undef unless $to;
  $options = {} unless $options;
  my @e = ();
  $self->{options}->{limit} = $options->{limit};

  foreach my $event_type( @{ $self->{scope}} ){
    foreach my $provider(__PACKAGE__->constantized_providers( $event_type ) ){
      push @e, $self->provider->find_events( $event_type, $self->{user} , $from, $to, $self->{options} );
    }
  }

  @e = sort{ $b->event_datetime <=> $a->event_datetime } @e;

  if( $options->{limit} ){
    my @result;
    for( my $i = 0; $i < @e ; $i++ ){
      push @result, $e[$i] if $i eq 0;
      push @result, $e[$i] if $i eq $options->{limit};
    }
    @e = @result;
  }
  wantarray ? @e : \@e;
}

sub constantized_providers { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  my ( $event_type ) = @_;
  $constantized_providers->{ $event_type };
}

1;