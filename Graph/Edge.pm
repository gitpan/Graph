package Graph::Edge;

# $Id: Edge.pm,v 1.8 1998/06/08 22:45:25 hietanie Exp $

=pod

=head1 NAME

Graph::Edge - a base class for graph edges

=head1 SYNOPSIS

B<Not to be used directly>.

=head1 DESCRIPTION

This class is not to be used directly because an edge always must
belong to a graph.  The graph classes will do this right.  Some useful
public methods exist, though.

=head2 RETRIEVING EDGES

	$edge  = $graph->edge($v1, $v2);

Return an edge of the graph by its vertex names, or vertices.  If the
edge does not exist, C<undef> is returned.

	@edges = $graph->edges($e1_v1, $e1_v2,
                               $e2_v1, $e2_v2,
                               ...,
                               $en_v1, $en_v2);

Return the list of I<n> edges of the graph by their vertex names, or
vertices.  If an edge by its vertices does not exist, C<undef> is
returned for that edge.  If no names are specified all the edges are
returned, in pseudorandom order.

=cut

use strict;
local $^W = 1;

use Graph::Element;

use vars qw(@ISA);

use overload q("") => \&as_string;

@ISA = qw(Graph::Element);

sub as_string {
    my ( $u, $v ) = $_[0]->vertices;

    return "$u-$v"; # There are no 'undirected' edges.
}

sub _new ($$$$;$) {
    my ( $class, $graph, $vertex_from, $vertex_to, $name ) = @_;

    die "$class->_new: Usage: $class->new(graph, vertex_from, vertex_to, name)\n"
	unless defined $graph and defined $vertex_from and defined $vertex_to;

    my $edge = Graph::Element::_new( $class, $name );

    $edge->_add_to_graph( $graph, '_EDGES', $name );

    # Names to vertices if needed.
    $vertex_from = $graph->add_vertex( $vertex_from ) unless ref $vertex_from;
    $vertex_to   = $graph->add_vertex( $vertex_to   ) unless ref $vertex_to;

    $graph->{ _BY_VERTICES }->
            { $vertex_from->_id }->{ $vertex_to->_id } = $edge;

=pod

=head2 RETRIEVING EDGE VERTICES

	$start_vertex = $edge->start;
	$stop_vertex  = $edge->stop;

The start and stop vertices of the edge.

	( $start_vertex, $stop_vertex ) = $edge->vertices;

Even in an undirected graph these will be in the order defined
originally by C<add_edge> method.

=cut

    $edge->start( $vertex_from );
    $edge->stop ( $vertex_to   );

    $vertex_from->{ _OUT_VERTICES }->{ $edge->_id } = $vertex_to;
    $vertex_to  ->{ _IN_VERTICES  }->{ $edge->_id } = $vertex_from;

    $vertex_from->{ _OUT_EDGES }->{ $vertex_to->_id   } = $edge;
    $vertex_to  ->{ _IN_EDGES  }->{ $vertex_from->_id } = $edge;

    if ( $graph->undirected ) {

	$graph->{ _BY_VERTICES }->
                { $vertex_to->_id }->{ $vertex_from->_id } = $edge;

	$vertex_from->{ _IN_VERTICES   }->{ $edge->_id } = $vertex_to;
	$vertex_to  ->{ _OUT_VERTICES  }->{ $edge->_id } = $vertex_from;

	$vertex_from->{ _IN_EDGES   }->{ $vertex_to->_id   } = $edge;
	$vertex_to  ->{ _OUT_EDGES  }->{ $vertex_from->_id } = $edge;

	$graph->_union( $vertex_from, $vertex_to );
    }

    return $edge;
}

sub vertices {
    my $edge = shift;

    return $edge->start, $edge->stop;
}

=pod

=head2 ADDING AND DELETING EDGES

See L<Graph>.

=cut

=pod

=head1 SEE ALSO

L<Graph>, L<Graph::Element>.

=head1 VERSION

Version 0.003.

=head1 AUTHOR

Jarkko Hietaniemi <F<jhi@iki.fi>>

=head1 COPYRIGHT

Copyright 1998, O'Reilly and Associates.

This code is distributed under the same copyright terms as Perl itself.

=cut

1;
