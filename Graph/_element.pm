package Graph::_element;

=pod

=head1 NAME

Graph::_element - baseclass for all graph elements

=head1 SYNOPSIS

B<Not intended for public use>.

=head1 DESCRIPTION

=head1 VERSION

Version 0.01.

=head1 AUTHOR

Jarkko Hietaniemi, <F<jhi@iki.fi>>

=head1 COPYRIGHT

Copyright 1998, O'Reilly & Associates.

This code is distributed under the same copyright terms as perl itself.

=cut

# A base class for attribute methods for all the graph elements:
# vertices, edges, and the graphs themselves.
#

use strict;
use Exporter;
use Carp 'confess';
use vars qw(@ISA $AUTOLOAD @EXPORT);

@EXPORT = qw(AUTOLOAD);

@ISA = qw(Exporter);

# attr( $self, $attr_key, $attr_val )
#   The generic attribute get/set method.
#
sub attr {
    my ( $self, $attr_key, $attr_val ) = @_;

    if ( @_ == 2 ) {
	return $self->{ ATTR }->{ $attr_key };
    } elsif ( @_ == 3 ) {
	$self->{ ATTR }->{ $attr_key } = $attr_val;
    } else {
	warn "Illegal number of arguments (", scalar @_, "), need 2 or 3.";
	confess "Died";
    }
}

# delete_attr( $self, $attr_key )
#   Deletes the attribute $attr_key from the $self.
#
sub delete_attr {
    my ( $self, $attr_key ) = @_;

    delete $self->{ ATTR }->{ $attr_key };
}

# has_attr( $self, $attr_key )
#   Tests whether $self has the attribute $attr_key.
#
sub has_attr {
    my ( $self, $attr_key ) = @_;

    return exists $self->{ ATTR }->{ $attr_key };
}

# AUTOLOAD( @method_arguments )
# Here used for a virtual attribute set/get method (see perlobj).
# The attribute names ($method) must begin with an uppercase letter,
# lowercase methods are supposed to be implemented non-virtually.
# Idea for this nice technique from Neil Bowers, neilb@cre.canon.co.uk.
#

sub AUTOLOAD {
    my $method = $AUTOLOAD;

    $method =~ s/^.*:://; # Leave only the "name" of "ba::se::name".

    # Also the DESTROY method (see perlobj) comes here.
    return if $method eq 'DESTROY';

    my $Initial = substr( $method, 0, 1 );

    # Enforce Capital Initial.
    unless ( $Initial eq uc $Initial ) {
	warn "AUTOLOAD: Cannot autoload method '$AUTOLOAD'.\n";
	confess "Died";
    }

    my $self = shift;

    return $self->attr( $method, @_ );
}

1;
