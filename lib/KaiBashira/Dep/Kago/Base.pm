package KaiBashira::Kago::RecordError;
use Mojo::Base -base;

package KaiBashira::Kago::SubclassNotFound;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::AssociationTypeMismatch;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::SerializationTypeMismatch;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::AdapterNotSpecified;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::AdapterNotFound;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::ConnectionNotEstablished;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::RecordNotFound;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::RecordNotSaved;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::StatementInvalid;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::PreparedStatementInvalid;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::StaleObjectError;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::ConfigurationError;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::ReadOnlyRecord;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::Rollback;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::DangerousAttributeError;
use Mojo::Base 'KaiBashira::Kago::RecordError';

package KaiBashira::Kago::MissingAttributeError;
use Mojo::Base -base;

package KaiBashira::Kago::UnknownAttributeError;
use Mojo::Base -base;

package KaiBashira::Kago::AttributeAssignmentError;
use Mojo::Base 'KaiBashira::Kago::RecordError';

has [qw/message exception attribute/];

sub new {
  my $self = shift->SUPER::new( @_ );
  my ( $message, $exception, $attribute ) = @_;
  $self->exception( $exception );
  $self->attribute( $attribute );
  $self->message( $message );
  $self;
}

package KaiBashira::Kago::MultiparameterAssignmentErrors;
use Mojo::Base 'KaiBashira::Kago::RecordError';

has [qw/errors/];

sub new {
  my $self = shift->SUPER::new( @_ );
  my ( $errors ) = @_;
  $self->errors( $errors );
  $self;
}

package KaiBashira::Kago::Base;
use Mojo::Base -base;

our $logger;
our $instance_writer = 0;

our $subclasses = {};

sub inherited { #Nothing...
  my ( $class , $child ) = @_;
  $subclasses->{__PACKAGE__} = $child;
#  $class->SUPER::inherited( @_ );
}



1;