package Graph::Vertex;

=pod

=head1 NAME

Graph::Edge - baseclass for Graph class representing a graph vertex (node)

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 VERSION

Version 0.01.

=head1 AUTHOR

Jarkko Hietaniemi, <F<jhi@iki.fi>>

=head1 COPYRIGHT

Copyright 1998, O'Reilly & Associates.

This code is distributed under the same copyright terms as perl itself.

=cut

# A simple base class for vertices.
#
# The attribute methods are inherited from the Graph::_element class.

use strict;
use vars qw(@ISA);

use Graph::_element;

@ISA = qw(Graph::_element);

use overload q("") => \&as_string, q(cmp) => \&cmp;

# as_string($vertex)
#   The stringification.
#   Simply returns the Id attribute.
#

sub as_string {
    my $v = shift;

    return $v->Id;
}

# _new($type, $id)
#   The constructor.
#   Sets the Id attribute.
#

sub _new {
    my $type = shift;

    my $v = { };

    bless $v, $type;

    $v->Id( shift );

    return $v;
}

# cmp($vertex, $other_vertex)
#   Tests the equality of the Ids of the vertices.
#

sub cmp {
    my ( $v1, $v2 ) = @_;

    return $v1->Id cmp $v2->Id;
}

# successors($vertex)
#   Returns the successors of the vertex.
#   ASSUMES the $v->G has been set.
#

sub successors {
    my $v = shift;

    return $v->G->successors( $v );
}

1;
