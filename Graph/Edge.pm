package Graph::Edge;

=pod

=head1 NAME

Graph::Edge - baseclass for Graph class representing a graph edge (link)

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

# Jarkko Hietaniemi <jhi@iki.fi>
# Copyright 1998, O'Reilly & Associates.
# This code is distributed under the same copyright terms as Perl itself.

# A simple base class for edges.
#
# The attribute methods are inherited from the Graph::_element class.

use strict;
use vars qw(@ISA);

use Graph::_element;

@ISA = qw(Graph::_element);

use overload q("") => \&as_string;

# as_string($edge)
#   The stringification.
#   Returns the end vertices connected by the joiner
#   appropriate for the directedness of the graph.
#   Also if the graph is undirected, the vertices are
#   always (alphabetically) sorted.
#

sub as_string {
    my $e = shift;

    my $g = $e->G;

    return join( $g->directed ? "-" : "=",
		 $g->directed ?
		 ( $e->P, $e->S ) :
		 sort $e->vertices );
}

# _new($type, $predecessor, $successor)
#   The constructor.
#   Connects the end point vertices to the edge.
#

sub _new {
    my $type = shift;

    my $e = { };

    bless $e, $type;

    $e->P( $_[ 0 ] );
    $e->S( $_[ 1 ] );

    return $e;
}

# vertices($edge)
#   Returns the end point vertices of the edge.
#

sub vertices {
    my $e = shift;

    return ( $e->P, $e->S );
}

# vertex_ids($edge)
#   Returns the ids of the end point vertices of the edge.
#

sub vertex_Ids {
    my $e = shift;

    return ( $e->P->Id, $e->S->Id );
}

1;
