package Graph;

# $Id: Graph.pm,v 1.1 1998/10/15 18:51:13 jhi Exp jhi $

$VERSION = 0.004;

=pod

=head1 NAME

Graph - graphs and graph algorithms

=head1 SYNOPSIS

        use Graph;

=head1 DESCRIPTION

The C<Graph> class provides graph data structures and some commonly used
graph algorithms.

=cut

require 5.004_04;

use strict;
local $^W = 1;

use Graph::Element;
use Graph::Vertex;
use Graph::Edge;
use Graph::DFS;

use Carp qw(confess carp);

# $SIG{__DIE__} = sub { confess "Died" };

use vars qw(@ISA);

@ISA = qw(Graph::Element);

use overload q("") => \&as_string;

=pod

=head1 METHODS

=cut

=pod

=head2 CONSTRUCTOR


        $graph = Graph->new;

The Constructor.  Creates a new B<directed> graph.  If you want
undirected graphs, use the C<new()> constructor of the class
C<Graph::Undirected>.  Read more about directedness later in
this document.

=cut

sub new ($;$) {
    my ( $class, $name ) = @_;

    my $graph = Graph::Element::_new( $class, $name );

    return $graph;
}

=pod

        print "g = ", $g->as_string, "\n";

The stringifier -- a string representation of the graph.  Normally
there is no need to use this directly as I<operator overloading> (see
L<overload>) works:

        print "g = $g\n";

Edges are listed first, unconnected vertices last, all separated by
commas.  Vertices are printed by their names, edges from vertex I<u>
to vertex I<v> either

        u-v

or
        
        u=v

depending on whether the graph is directed or undirected, respectively.

=cut

sub as_string {
    my $graph = shift;
    
    my @e;

    if ( $graph->directed ) {
        foreach my $e ( $graph->edges ) {
            my ($u, $v) = $e->vertices;

            push @e, "$u-$v";
        }
    } else { # Undirected.
	my %e;

        foreach my $e ( $graph->edges ) {
            my ($u, $v) = sort $e->vertices;

            $e{$u}{$v}++;
        }

	foreach my $u ( keys %e ) {
	    foreach my $v ( keys %{ $e{ $u } } ) {
		push( @e, join( "=", sort $u, $v ) );
	    }
	}
    }

    return join( ",",
                 sort @e, sort $graph->unconnected_vertices );
}

# _make_sense($graph, $sense, $make, $concept)
#   A helper method for throwing a fatal exception if the
#   asked question makes no sense for the type of the graph.
#

sub _make_sense {
    my ( $graph, $sense, $make, $concept ) = @_;

    unless ( $make ) {
        warn( ( caller( 2 ))[ 3 ], ":\n");
        warn "\u$concept make sense only for $sense graphs.\n";
        confess "Died";
    }
}

# _make_directed_sense($graph, $concept)
#   A helper method for throwing a fatal exception if the
#   asked question makes no sense for a directed graph.
#

sub _make_directed_sense {
    my ( $graph, $concept ) = @_;

    $graph->_make_sense( "directed",   $graph->directed,   $concept );
}

# _make_undirected_sense()
#   A helper method for throwing a fatal exception if the
#   asked question makes no sense for an undirected graph.
#

sub _make_undirected_sense {
    my ( $graph, $concept ) = @_;

    $graph->_make_sense( "undirected", $graph->undirected, $concept );
}

=pod

=head2 ADDING VERTICES

        $vertex   = $graph->add_vertex($vertex_name);

Add one vertex to the graph.  Return the vertex, regardless of
whether it already was in the graph.

        @vertices = $graph->add_vertices($v1, $v2, ..., $vn);

Add one or more vertices to the graph.  In list context return the
list of the I<n> added vertices, regardless of whether they already
were in there graph.  In array context return the number of really
added vertices.

=cut

sub add_vertex ($$) {
    return Graph::Vertex->_new( @_ );
}

sub add_vertices ($;@) {
    my $graph = shift;

    if ( wantarray ) {
        my @vertices;

        foreach ( @_ ) {
            push @vertices, $graph->add_vertex( $_ );
        }

        return @vertices;
    } else {
        my $vertices = 0;
        
        foreach ( @_ ) {
            unless ( defined $graph->vertex( $_ ) ) {
                $graph->add_vertex( $_ );
                $vertices++;
            }
        }

        return $vertices;
    }
}

=pod

        $in_same_element = $graph->find( $vertex, $another_vertex );

Return true if the two vertices are in the same connected C<$graph>
element.  This is the other half of the I<union-find> fame.
Union-find is the name of a method which enables extremely fast graph
connectedness checks.  The other half, union, is not available because
explicitly using it would be a bad idea: C<add_edge> and C<add_edges>
will call it implicitly.

        $is_connected    = $graph->is_connected;

Return true if the C<$graph> is connected: that is, one can reach
every vertex from any other vertex.  Makes sense only for undirected
graphs, for directed graphs a similar concept does exist but it is
called I<strong connectivity>.

B<NOTE>: the union-find structure is not currently updated when
vertices or edges of the graph are I<deleted>.  Yes, this is a bug.

=cut

sub _union_find {
    my ( $graph, $u, $v, $do_union ) = @_;

    my ( $i, $j );

    unless ( defined $graph->{ union_find_by_vertex }->{ $u } ) {
        $i = ++$graph->{ union_find_next_id };
        $graph->{ union_find_by_vertex }->{ $u } = $i;
        $graph->{ union_find_by_id     }->[ $i ] = $u;
        $graph->{ union_find_parent    }->[ $i ] = 0;
    } else {
        $i = $graph->{ union_find_by_vertex }->{ $u };
    }   

    unless ( defined $graph->{ union_find_by_vertex }->{ $v } ) {
        $j = ++$graph->{ union_find_next_id };
        $graph->{ union_find_by_vertex }->{ $v } = $j;
        $graph->{ union_find_by_id     }->[ $j ] = $v;
        $graph->{ union_find_parent    }->[ $j ] = 0;
    } else {
        $j = $graph->{ union_find_by_vertex }->{ $v };
    }

    my ( $oi, $oj ) = ( $i, $j ); # Save these for path compression.

    $i = $graph->{ union_find_parent }->[ $i ]
        while $graph->{ union_find_parent }->[ $i ] > 0;

    $j = $graph->{ union_find_parent }->[ $j ]
        while $graph->{ union_find_parent }->[ $j ] > 0;

    # Path compression, do another pass (well, two passes)
    # connecting all the vertices to the newly found root.

    ( $oi, $graph->{ union_find_parent }->[ $oi ] ) =
        ( $graph->{ union_find_parent }->[ $oi ], $i )
            while $graph->{ union_find_parent }->[ $oi ] > 0;

    ( $oj, $graph->{ union_find_parent }->[ $oj ] ) =
        ( $graph->{ union_find_parent }->[ $oj ], $j )
            while $graph->{ union_find_parent }->[ $oj ] > 0;

    my $same = $i == $j;

    # Make the union.
    if ( $do_union and not $same ) {

        # Weight balancing, no balancing would be simply:
        # $graph->{ union_find_parent }->[ $j ] = $i;

        # Pick the smaller of the trees.
        if ( $graph->{ union_find_parent }->[ $j ]
             <
             $graph->{ union_find_parent }->[ $i ] ) {

            $graph->{ union_find_parent }->[ $j ] +=
                $graph->{ union_find_parent }->[ $i ] - 1;
            $graph->{ union_find_parent }->[ $i ] = $j;

        } else {

            $graph->{ union_find_parent }->[ $i ] +=
                $graph->{ union_find_parent }->[ $j ] - 1;
            $graph->{ union_find_parent }->[ $j ] = $i;

        }
    }

    return $same;
}

# $graph->find( $vertex, $another_$vertex )
#   The find operation of the union-find fame.
#

sub find {
    my ( $graph, $u, $v ) = @_;

    $graph->_make_undirected_sense( "union-find" );

    return $graph->_union_find( $u, $v, 0 );
}

# $graph->_union( $vertex, $another_vertex )
#   The union operation of the union-find fame.
#

sub _union {
    my ( $graph, $u, $v ) = @_;

    $graph->_make_undirected_sense( "union-find" );

    return $graph->_union_find( $u, $v, 1 );
}

sub is_connected {
    my $graph = shift;
    
    $graph->_make_undirected_sense( "Being connected" );

    my $state = { };

    my @v = $graph->vertices;
    my $v = shift @v;

    for my $u ( @v ) {
        # If not in same union-tree component, give up.
        return 0 unless $graph->find( $u, $v );
    }

    return 1;
}

=pod

=head2 ADDING EDGES

        $edge  = $add->add_edge($v1, $v2[, $edge_name]);

Add one edge to the graph by the names of the vertices.
The vertices are implicitly added to the graph if not already there.
Return the edge, regardless of whether it already was in the graph.
An optional symbolic name can be attached to the edge.  This is
normally unnecessary because an edge is fully specified by its
vertices.

        @edges = $add->add_edges($e1_v1, $e1_v2,
                                 $e2_v1, $e2_v2,
                                 ...,
                                 $en_v1, $e2_v2);

Add one or more edges to the graph by the names of the vertices.  The
vertices are implicitly added to the graph if not already there.  In
list context return the list of the I<n> edges, regardless of whether
they already were in the graph.  In scalar context return the number
of really added edges.

See L<Graph::Vertex> for how to find out which edges start from and
leave a vertex, and to find out which vertices are behind those edges.
See L<Graph::Edge> for how to retrieve the vertices of edges.

=cut

sub add_edge ($$$;$) {
    return Graph::Edge->_new( @_ );
}

sub add_edges ($;@) {
    my $graph = shift;
    my @edges;

    if ( wantarray ) {
        my @edges;

        push @edges, $graph->add_edge( splice @_, 0, 2 ) while @_;
        
        return @edges;
    } else {
        my $edges = 0;

        while ( @_ ) {
            my ( $u, $v ) = splice @_, 0, 2;

            unless ( $graph->edge( $u, $v ) ) {
                $graph->add_edge( $u, $v );
                $edges++;
            }
        }

        return $edges;
    }

    return @edges;
} 

=pod

=head2 RETRIEVING VERTICES

        $vertex   = $graph->vertex($vertex_name);

Return one vertex of the graph by its name names.  If the vertex does
not exist, C<undef> is returned.

        @vertices = $graph->vertices($v1, $v2, ..., $vn);

Return the list of the I<n> vertices of the graph by their names.  If
a vertex by a name does not exists, C<undef> is returned for that
vertex.

        @vertices = $graph->vertices;

If no names are specified all the vertices are returned, in
pseudorandom order.

=cut

sub vertices ($;@) {
    my $graph = shift;

    if ( @_ ) { # Some vertices by name.
        return @{ $graph->{ _BY_NAME }->{ _VERTICES } }{ @_ };
    } else {    # All the vertices.
        return values %{ $graph->{ _VERTICES } };
    }
}

sub vertex ($$$) {
    my $graph = shift;

    return ( $graph->vertices( $_[ 0 ] ) )[ 0 ];
}

=pod

        $has_vertex   = $graph->has_vertex($vertex_name);

Return true if the the graph has the vertex.

        @has_vertices = $graph->has_vertices($v1, $v2, ...);

In list context return a list of truth values, one for each vertex:
true if the graph has the vertex, false if not.  In scalar context,
return the logical and of the list, that is, all the vertices must
exist.

=cut

sub has_vertex ($$) {
    my ( $graph, $vertex ) = @_;

    return defined $graph->vertex( $vertex ) ? 1 : 0;
}

sub has_vertices ($;@) {
    my $graph = shift;
    my @has;

    push @has, defined $graph->vertex( shift @_ ) ? 1 : 0 while @_;

    if ( wantarray ) {
        return @has;
    } else {
        foreach ( @has ) { return 0 unless $_ }
        return 1;
    }
}

=pod

=head2 RETRIEVING EGDES

        $edge  = $graph->edge($v1, $v2);

Return an edge of the graph by its vertex names, or vertices.  If
vertices are used they must be vertices of the graph.  If the edge
does not exist, C<undef> is returned.

        @edges = $graph->edges($e1_v1, $e1_v2,
                               $e2_v1, $e2_v2,
                               ...,
                               $en_v1, $en_v2);

Return the list of I<n> edges of the graph by their vertex names, or
vertices.  If an edge by its vertices does not exist, C<undef> is
returned for that edge.

        @edges = $graph->edges;

If no names are specified all the edges are returned, in pseudorandom
order.

=cut

sub edges ($;@) {
    my $graph = shift;
    my @edges;

    if ( @_ ) { # Some edges by their vertices.
        while ( @_ ) {
            my ( $vertex_from, $vertex_to ) = splice( @_, 0, 2 );

            # Names to vertices if needed.
            $vertex_from = $graph->vertex( $vertex_from )
                unless ref $vertex_from;
            $vertex_to   = $graph->vertex( $vertex_to   )
                unless ref $vertex_to;

            push @edges,
                 ( ref $vertex_from and ref $vertex_to ) ?
                     $graph->{ _BY_VERTICES }->
                     { $vertex_from->_id }->
                     { $vertex_to->_id } :
                     undef;
        }
    } else { # All the edges.
        @edges = values %{ $graph->{ _EDGES } };
    }

    return @edges;
}

sub edge ($$$) {
    my $graph = shift;

    return ( $graph->edges( @_[ 0, 1 ] ) )[ 0 ];
}

=pod

        $has_edge  = $graph->has_edge($v1, $v2);

Return true if the graph has the edge defined by the vertices, false if not.

        @edges = $graph->edges($e1_v1, $e1_v2,
                               $e2_v1, $e2_v2,
                               ...,
                               $en_v1, $en_v2);

Return a list of I<n> truth values, one for each edge, true if the
edge exists, false if not.  In scalar context, return the logical and
of the list, that is, all the edges must exist.

=cut
          
sub has_edge ($$$) {
    my $graph = shift;

    return defined $graph->edge( @_ ) ? 1 : 0;
}

sub has_edges ($$) {
    my $graph = shift;
    my @has;
    
    push @has, defined $graph->edge( splice @_, 0, 2 ) while @_;

    if ( wantarray ) {
        return @has;
    } else {
        foreach ( @has ) { return 0 unless $_ }
        return 1;
    }
}

=pod

=head2 RETRIEVING EGDES BY NAMES

        $edge  = $graph->edge_by_name($edge_name);

        @edges = $graph->edges_by_names($e1, $e2, ...);

Return one or more edges by their symbolic names, or if no names are
given, all the edges.  The symbolic name can be given using either
in edge creation time

        $graph->add_edge($v1, $v2, $edge_name);

or later

        $edge->name($edge_name);

=cut

sub edges_by_names ($;@) {
    my $graph = shift;

    if ( @_ ) { # Some edges by name.
        return @{ $graph->{ _BY_NAME }->{ _EDGES } }{ @_ };
    } else {    # All the edges.
        return values %{ $graph->{ _BY_NAME }->{ _EDGES } };
    }
}

sub edge_by_name ($$$) {
    my $graph = shift;

    return ( $graph->edges_by_names( @_[ 0, 1 ] ) )[ 0 ];
}

=pod

=head2 DELETING EDGES

        $deleted = $graph->delete_edge( $v1, $v2 );

Delete one edge by its vertices.  Return true if the edge really
was deleted and false if the edge wasn't there.

        $deleted = $graph->delete_edge( $e );

Delete one edge. Return true if the edge really was deleted and false
if the edge wasn't there.

        @deleted = $graph->delete_edges( $e1_v1, $e1_v2,
                                         $e2_v1, $e2_v2,
                                         ...,
                                         $en_v1, $en_v2);

Delete one or more edges by their vertices.  In list context return
the list of I<n> truth values, one for each edge: true for the edges
really deleted and false for the edges that weren't there.  In scalar
context return the number of really deleted edges.

=cut

sub delete_edges {
    my $graph = shift;
    my @deleted;

    while ( @_ ) {
	my ( $u, $v ) = splice( @_, 0, 2 );

        my $edge = $graph->edge( $u, $v );

	$edge = $graph->edge( $v, $u )
	    if not ref $edge and $graph->undirected;

        if ( ref $edge ) {
            push @deleted, 1;

            $graph->_delete_from_graph( $edge, '_EDGES' );

            my ( $vertex_from, $vertex_to ) = $edge->vertices;

            delete $graph->{ _BY_VERTICES }->
                           { $vertex_from->_id }->{ $vertex_to->_id };

            $edge->delete_attribute( 'start' );
            $edge->delete_attribute( 'stop'  );

            delete $vertex_from->{ _OUT_VERTICES }->{ $edge->_id };
            delete $vertex_to  ->{ _IN_VERTICES  }->{ $edge->_id };

            delete $vertex_from->{ _OUT_EDGES    }->{ $vertex_to->_id   };
            delete $vertex_to  ->{ _IN_EDGES     }->{ $vertex_from->_id };

            $edge->_delete;

            if ( $graph->undirected ) {

		# Swap the endpoints.
		( $vertex_from, $vertex_to ) = ( $vertex_to, $vertex_from );

		$edge = $graph->edge( $vertex_from, $vertex_to );

		if ( ref $edge ) {
		    push @deleted, 1;

		    $graph->_delete_from_graph( $edge, '_EDGES' );

		    delete $graph->{ _BY_VERTICES }->
		                   { $vertex_from->_id }->{ $vertex_to->_id };

		    delete $vertex_from->{ _OUT_VERTICES }->{ $edge->_id };
		    delete $vertex_to  ->{ _IN_VERTICES  }->{ $edge->_id };

		    delete $vertex_from->{ _OUT_EDGES }->{ $vertex_to->_id   };
		    delete $vertex_to  ->{ _IN_EDGES  }->{ $vertex_from->_id };

		    # TODO: update the union-find structure.

		    $edge->_delete;
		}
            }
        } else {
            push @deleted, 0;
        }
    }

    return wantarray ? @deleted : grep { $_ } @deleted;
}

sub delete_edge ($$;$) {
    my $graph = shift;

    if ( @_ == 1 ) {    # One edge by name.
        return ( $graph->delete_edges( $_[0]->vertices ) )[ 0 ];
    } else {            # Edge by vertices.
        return ( $graph->delete_edges( @_[0, 1] ) )[ 0 ];
    }
}

=pod

=head2 DELETING VERTICES

        $deleted = $graph->delete_vertex($vertex_name);

Delete one vertex and the edges depending on it from the graph.  Return
true if the vertex did exist, false if not.

        @deleted = $graph->delete_vertices($v1, $v2, ...);

Delete one or more vertices and the edges depending on them from the
graph.  In list context return a list of truth values, one for each
vertex: true if the vertex did exist, false if not.  In scalar context
return the number of really deleted vertices.

=cut

sub delete_vertex {
    my $graph  = shift;
    my $vertex = shift;

    $vertex = $graph->vertex( $vertex ) unless ref $vertex;

    if ( ref $vertex ) {
        foreach my $edge ( $graph->vertex_edges( $vertex) ) {
	    my ( $u, $v) = $edge->vertices;

            $graph->delete_edge( $u, $v)
		if defined $u and defined $v;
        }

        $graph->_delete_from_graph( $vertex, '_VERTICES' );

        $vertex->_delete;

        return 1;
    } else {
        return 0;
    }
}

sub delete_vertices ($;@) {
    my $graph = shift;
    my @deleted;

    push @deleted, $graph->delete_vertex( shift @_ ) while @_;

    return wantarray ? @deleted : grep { $_ } @deleted;
}

=pod

=head2 RETRIEVING NEIGHBOURING VERTICES

        @neighbours   = $graph->vertex_neighbours( $vertex );

Return all the neighbouring vertices of the vertex.  Also the American
neigbors are available.

        @successors   = $graph->vertex_successors( $vertex );

Return all the successor vertices of the vertex.

        @predecessors = $graph->vertex_predecessors( $vertex );

Return all the predecessor vertices of the vertex.

=cut

sub _vertex_values {
    my $graph   = shift;
    my $element = shift;
    my $vertex  = shift;

    my $self = $graph->vertex( $vertex );

    if ( @_ ) { # Some values by name.
        return @{ $self->{ $element } }{ @_ };
    } else {    # All the values.
        return values %{ $self->{ $element } };
    }
}

sub _out_vertices {
    my $graph = shift;

    return $graph->_vertex_values( '_OUT_VERTICES', @_ );
}

sub _in_vertices {
    my $graph = shift;

    return $graph->_vertex_values( '_IN_VERTICES',  @_ );
}

sub vertex_successors {
    my $graph = shift;

    $graph->_make_directed_sense("out-vertices");

    return $graph->_vertex_values( '_OUT_VERTICES', @_ );
}

sub vertex_predecessors {
    my $graph = shift;

    $graph->_make_directed_sense("out-vertices");

    return $graph->_vertex_values( '_IN_VERTICES',  @_ );
}

sub vertex_neighbours {
    my $graph = shift;

    return $graph->_in_vertices( @_ );
}

*vertex_neighbors = \&vertex_neighbours;

=pod

=head2 RETRIEVING NEIGHBOURING EDGES

        @all = $graph->vertex_edges( $vertex );

Return all the neighboring edges of the vertex.

        @out = $graph->vertex_out_edges( $vertex );

Return all the edges leaving the vertex.

        @in  = $graph->vertex_in_edges( $vertex );

Return all the edges arriving at the vertex.

=cut

sub vertex_out_edges {
    my $graph = shift;

    return $graph->_vertex_values( '_OUT_EDGES', @_ );
}

sub vertex_in_edges {
    my $graph = shift;

    return $graph->_vertex_values( '_IN_EDGES',  @_ );
}

sub vertex_edges {
    my $graph = shift;

    if ( @_ ) { # Some edges by name.
        return $graph->vertex_in_edges( @_ ), $graph->vertex_out_edges( @_ );
    } else {    # All the edges.
        return $graph->vertex_in_edges, $graph->vertex_out_edges;
    }
}

=pod

=head2 VERTEX CLASSES

The vertices returned by the following methods are in pseudorandom order.

        @connected_vertices   = $graph->connected_vertices;

The list of connected vertices of the graph.

        @unconnected_vertices = $graph->unconnected_vertices;

The list of unconnected vertices of the graph.

        @sink_vertices        = $graph->sink_vertices;

The list of sink vertices of the graph.

        @source_vertices      = $graph->source_vertices;

The list of source vertices of the graph.

        @exterior_vertices    = $graph->exterior_vertices;

The list of exterior vertices (sinks and sources) of the graph.

        @interior_vertices    = $graph->interior_vertices;

The list of interior vertices (non-sinks and non-sources) of the graph.

        @selfloop_vertices    = $graph->selfloop_vertices;

The list of self-loop vertices of the graph.

=cut

sub connected_vertices {
    my $graph = shift;

    grep { $_->{ _OUT_EDGES } or $_->{ _IN_EDGES } } $graph->vertices;
}

sub unconnected_vertices {
    my $graph = shift;

    grep { not $_->{ _OUT_EDGES } and not $_->{ _IN_EDGES } } $graph->vertices;
}

sub sink_vertices {
    my $graph = shift;

    grep { not $_->{ _OUT_EDGES } and $_->{ _IN_EDGES } } $graph->vertices;
}

sub source_vertices {
    my $graph = shift;

    grep { $_->{ _OUT_EDGES } and not $_->{ _IN_EDGES } } $graph->vertices;
}

sub exterior_vertices {
    my $graph = shift;

    grep { $_->{ _OUT_EDGES } xor $_->{ _IN_EDGES } } $graph->vertices;
}

sub interior_vertices {
    my $graph = shift;

    grep { $_->{ _OUT_EDGES } and $_->{ _IN_EDGES } } $graph->vertices;
}

sub selfloop_vertices {
    my $graph = shift;
    my @self;

    foreach my $u ( $graph->vertices ) {
        my @v = $graph->vertex_successors( $u );

        @v = $graph->vertex_predecessors( $u ) unless @v;

        foreach my $v ( @v ) {
            if ( $u->_id eq $v->_id ) {
                push @self, $u;
                last;
            }
        }
    }

    return @self;
}

=pod

=head2 PATHS

A B<path> is a connected set of the I<n-1> edges I<v1 v2>, I<v2 v3>,
..., leading from the vertex I<v1> to the vertex I<vn>.

=over 4

=item ADDING PATHS

        @edges = $graph->add_path($v1, $v2, $v3, ..., $vn);

Add one or more edges, a B<path>, to the graph.  The vertices are
added to the graph explicitly if they already aren't there.  Return
the list of the I<n-1> edges.

=item RETRIEVING PATHS

        @edges  = $graph->path($v1, $v2, ..., $vn);

Return the I<n-1> edges of the path.  If an edge does not exist (that is,
the path does not exist), C<undef> is returned for that edge.

        $has_path = $graph->has_path($v1, $v2, ..., $vn);

Return true if the graph has the path, that is, it has all the I<n-1> edges.

=item DELETING PATHS

        @deleted = $graph->delete_path($v1, $v2, ..., $vn);

Delete one or more edges, a B<path>, from the graph.  Return a list
of I<n-1> truth values, one for each edge in the path: true if the
edge did exist, false if not.

=back

=cut

sub add_path {
    my $graph       = shift;
    my $vertex_from = shift;
    my @edges;

    while ( @_ ) {
        my $vertex_to = shift;
        push @edges, $graph->add_edge( $vertex_from, $vertex_to );
        $vertex_from = $vertex_to;
    }

    return @edges;
}

sub path ($;@) {
    my $graph       = shift;
    my $vertex_from = shift;
    my @path;

    my @try = @_; # Create the potential path.

    while ( @try ) {
        my $vertex_to = shift @try;
        push @path, scalar $graph->edge( $vertex_from, $vertex_to );
        $vertex_from = $vertex_to;
    }
    
    return @path;
}

sub has_path {
    my $graph = shift;

    foreach my $edge ( $graph->path( @_ ) ) {
        return 0 unless defined $edge;
    }

    return 1;
}

sub delete_path ($;@) {
    my $graph       = shift;
    my $vertex_from = shift;
    my @deleted;

    while ( @_ ) {
        my $vertex_to = shift;
        push @deleted, $graph->delete_edge( $vertex_from, $vertex_to );
        $vertex_from = $vertex_to;
    }

    return @deleted;
}

=pod

=head2 CYCLES

A B<cycle> is a cyclical path, defined by the I<n> edges I<v1 v2>,
I<v2 v3>, ..., I<vn v1>, starting from and returning back to the
vertex I<v1>.

=over 4

=item ADDING CYCLES

        @edges = $graph->add_cycle($v1, $v2, $v3, ..., $vn);

Add one or more edges, a cycle, to the graph.  The vertices are added
to the graph explicitly if they already aren't there.  Return the
list of the I<n> edges.

=item RETRIEVING CYCLES

        @edges  = $graph->cycle($v1, $v2, ..., $vn);

Return the I<n> edges of the cycle.  If an edge does not exist (that is,
the cycle does not exist), C<undef> is returned for that edge.

        $has_cycle = $graph->has_cycle($v1, $v2, ..., $vn);

Return true if the graph has the cycle, that is, it has all the I<n> edges.

=item DELETING CYCLES

        @edges = $graph->delete_cycle($v1, $v2, $v3, ..., $vn);

Delete one or more edges, a cycle, from the graph.  In list context
return a list of I<n> truth values, one for each edge in the cycle:
true if the edge did exist, false if not.

=back

=cut

sub add_cycle ($$;@) {
    add_path @_, $_[1];
}

sub cycle ($;@) {
    my $graph       = shift;
    my $vertex_from = shift;
    my @cycle;

    my @try = ( @_, $vertex_from ); # Create the potential cycle.

    while ( @try ) {
        my $vertex_to = shift @try;
        push @cycle, scalar $graph->edge( $vertex_from, $vertex_to );
        $vertex_from = $vertex_to;
    }
    
    return @cycle;
}

sub has_cycle {
    my $graph = shift;

    # No vertices, no cycles. (Null-cycles do not count.)
    return 0 unless @_ and $graph->vertices;

    foreach my $edge ( $graph->cycle( @_ ) ) {
        return 0 unless defined $edge;
    }

    return 1;
}

sub delete_cycle ($$;@) {
    delete_path @_, $_[1];
}

=pod

=head2 DETECTING CYCLES

        @cycle = $graph->is_cyclic;

Return true if the graph is cyclic, false if the graph is not cyclic
(I<acyclic>).

=cut

sub is_cyclic ($) {
    my $graph = shift;

    my $return_cyclic =
	Graph::DFS->new( { return_cyclic => 1 } );

    return $return_cyclic->( $graph );
}

=pod

=head1 ADDING ATTRIBUTED EDGES AND PATHS

        $graph->add_attributed_edge( $attribute_name,
                                     $vertex_from,
                                     $attribute_value,
                                     $vertex_to );

Add the attribute to the edge (and create the edge if it does not exist).

        $graph->add_attributed_path( $attribute_name,
                                     $vertex_1,
                                     $attribute_value_1,
                                     $vertex_2,
                                     $attribute_value_2,
                                     ...
                                     $vertex_n );

Add the I<n-1> attribute values to the I<n-1> edges along the path
(and creating the edges if needed).

=cut

sub add_attributed_edge ($$$$$) {
    my $graph = shift;
    my $attr  = shift;

    my $e = $graph->add_edge( $_[0], $_[2] );

    $e->attribute( $attr, $_[1] );

    if ( $graph->undirected ) {
	$e = $graph->edge( $_[2], $_[ 0 ]);
	$e ->attribute( $attr, $_[1] );
    }
}

sub add_attributed_path ($$$$$;@) {
    my $graph = shift;
    my $attr  = shift;

    my $vertex_from = shift;

    while ( @_ ) {
	my $val       = shift;
	my $vertex_to = shift;

        my $e = $graph->add_edge( $vertex_from, $vertex_to );

	$e->attribute( $attr, $val );

	if ( $graph->undirected ) {
	    $e = $graph->edge( $vertex_to, $vertex_from );
	    $e->attribute( $attr, $val );
	}

        $vertex_from = $vertex_to;
    }
}

=head1 RETRIEVING EDGES' AND PATHS' ATTRIBUTES

        $attribute_value = $graph->attributed_edge( $attribute_name,
                                                    $vertex_from,
                                                    $vertex_to );

Return the attribute of the edge.  If the edge does not exist
C<undef> is returned.

        @attribute_values = $graph->attributed_path( $attribute_name,
                                                     $vertex_1,
                                                     $vertex_2,
                                                     ...
                                                     $vertex_n );

Return the list of the I<n-1> attribute values.  If an edge does
not exist, C<undef> is returned for that edge.

=cut

sub attributed_edge ($$$$) {
    my $graph = shift;
    my $attr  = shift;

    my $e = $graph->edge( $_[0], $_[1] );

    return defined $e ? $e->attribute( $attr ) : undef;
}

sub attributed_path ($$$$;@) {
    my $graph = shift;
    my $attr  = shift;

    my $vertex_from = shift;

    my @attr;

    while ( @_ ) {
	my $vertex_to = shift;
        my $e = $graph->edge( $vertex_from, $vertex_to );

        push @attr, defined $e ? $e->attribute( $attr ) : undef;

        $vertex_from = $vertex_to;
    }

    return @attr;
}

=pod

=head1 GRAPH PROPERTIES

=head2 GRAPH DENSITY

        $density = $graph->density;

Return the density of the C<$graph> as a number between 0 and 1.
Graph density is defined as the relative number of edges.  A zero
signifies an empty graph: no edges; a one signifies a I<complete>
graph: I<|V|(|V|-1)/2> edges (for undirected graphs) or I<|V|(|V|-1)>
(for directed graphs), I<|V|> being the number of vertices.

        $is_sparse = $graph->is_sparse;

Return true if the C<$graph> is sparse; that is, its density is less
than I<|V|(|V|-1)/6> (for undirected graphs) or I<|V|(|V|-1)/3> (for
directed graphs).

        $is_dense = $graph->is_dense;

Return true if the C<$graph> is dense; that is, its density is greater
than I<|V|(|V|-1)/3> (for undirected graphs) or I<2|V|(|V|-1)/3> (for
directed graphs).

	($sparse, $dense) = $graph->density_limits;

Return the limits for being sparse and being dense.  The C<$graph> is
sparse if it has as many or less edges than C<$sparse> and dense
if it has as many or more fewer edges than C<$dense>.

=cut

sub density {
    my $graph = shift;

    my $V     = $graph->vertices;

    return 0 if $V < 2;

    my $max = $V * ( $V - 1 );

    $max *= 2 if $graph->undirected;

    return $graph->edges / $max;
}

sub density_limits {
    my $graph = shift;

    my $V     = $graph->vertices;

    my $max    = $V * ($V - 1);
    my $sparse = $V ? int(     $max / 3 ) : $V;
    my $dense  = $V ? int( 2 * $max / 3 ) : $V;

    $sparse = $V if $sparse < $V;
    $dense  = $V if $dense  < $V;
    $dense  = $sparse + 1 if $dense <= $sparse;
    $dense  = $max        if $dense > $max;

    if ($graph->undirected) {
	$sparse = int(($V + $sparse) / 2);
	$dense  = int(($V + $dense ) / 2);
    }

    return ($sparse, $dense);
}

sub is_sparse {
    my $graph = shift;

    return 1 if $graph->vertices == 0;

    my ($sparse, $dense) = density_limits($graph);

    return $graph->edges <= $sparse;
}

sub is_dense {
    my $graph = shift;

    return 0 if $graph->vertices == 0;

    my ($sparse, $dense) = density_limits($graph);

    return $graph->edges >= $dense;
}

=pod

=head2 DERIVATIVE GRAPHS

The four following methods are graph constructors.  They copy always
the vertices, the edges if applicable, and all the graph, vertex, and
edge attributes.

        $copy       = $graph->copy;

Return a copy of the C<$graph>.

        $transpose  = $graph->transpose_graph;

Return a transpose graph of the C<$graph>, a graph where every edge is
reversed.  Makes sense only for directed graphs.

        $complete   = $graph->complete_graph;

Return a complete graph of the C<$graph>, a graph that has every
possible edge (without resorting to multiedges).

        $complement = $graph->complement_graph;

Return a complement graph of the C<$graph>, a graph that has every
edge that the C<$graph> does B<not>.

=cut

sub _copy_graph_attributes {
    my ( $graph_dst, $graph_src ) = @_;

    my %a  = $graph_src->_attributes;
    my $id = $graph_dst->_id;

    $graph_dst->{ _ATTRIBUTE } = \%a;
    $graph_dst->_id( $id );
}

sub _copy_vertex_attributes {
    my ( $graph_dst, $graph_src ) = @_;

    foreach my $v ( $graph_src->vertices ) {
         my %a = $v->_attributes;
         my $w = $graph_dst->vertex( $v->name );
         my $id = $w->_id;

         $w->{ _ATTRIBUTE } = \%a;
         $w->_id( $id );
    }
}

sub _copy_edge_attributes {
    my ( $graph_dst, $graph_src ) = @_;

    foreach my $e ( $graph_src->edges ) {
         my ( $u, $v ) = $e->vertices;
         my $f = $graph_dst->edge( $u->name, $v->name );
         my %a = $e->_attributes;
         my $id = $f->_id;

         $f->{ _ATTRIBUTE } = \%a;

         $f->_id( $id );
    }
}

sub copy {
    my $graph = shift;

    my $copy = (ref $graph)->new;

    $copy->_copy_graph_attributes( $graph );

    foreach my $e ( $graph->edges ) {
        my ( $u, $v ) = $e->vertices;

        $copy->add_edge( $u->name, $v->name );
    }

    $copy->_copy_edge_attributes( $graph );

    foreach my $v ( $graph->unconnected_vertices ) {
        $copy->add_vertex( $v->name );
    }

    $copy->_copy_vertex_attributes( $graph );

    return $copy;
}

sub transpose_graph {
    my $graph = shift;

    my $transpose = (ref $graph)->new;

    $transpose->_copy_graph_attributes( $graph );

    foreach my $e ( $graph->edges ) {
        my ( $u, $v ) = $e->vertices;

        $transpose->add_edge( $v->name, $u->name ); # 'pose 'em.
    }

    foreach my $v ( $graph->unconnected_vertices ) {
        $transpose->add_vertex( $v->name );
    }

    $transpose->_copy_vertex_attributes( $graph );

    return $transpose;
}

sub complete_graph {
    my $graph = shift;

    my $complete = (ref $graph)->new;

    $complete->_copy_graph_attributes( $graph );

    my @v = $graph->vertices;

    foreach my $u ( @v ) {
        foreach my $v ( @v ) {
            $complete->add_edge( $u->name, $v->name ) # O(V**2).
		unless $u->name eq $v->name;
        }
    }

    $complete->_copy_vertex_attributes( $graph );
    $complete->_copy_edge_attributes  ( $graph );

    return $complete;
}

sub complement_graph {
    my $graph = shift;

    # Start off with a complete graph...
    my $complement = complete_graph( $graph );

    $complement->_copy_graph_attributes( $graph );

    foreach my $e ( $graph->edges ) {
        my ( $u, $v ) = $e->vertices;

	# ...and delete those vertices we have in the original graph.
        $complement->delete_edge( $u->name, $v->name );
    }

    $complement->_copy_vertex_attributes( $graph );

    return $complement;
}

=pod

=head1 DIRECTEDNESS

A graph can be B<directed> or B<undirected>.  Or more precisely, the
edges of the graph can be directed or undirected.  The difference
between a directed edge and an undirected edge is that if there is an
undirected edge from vertex I<v1> to vertex I<v2>, there is also an
implicit edge in the opposite direction, from vertex I<v2> to vertex
I<v1>.

For this module, however, the directedness property is attached to
the graph.  If a graph is undirected, either by instantiating an
object of the C<Graph::Undirected> class, or marking a graph
undirected (see below), whenever an edge is added to graph, also
the edge going to the other direction is added, and likewise for
deleting edges.  If you do not want this dual behaviour, mark the
graph directed.

The directedness of a graph can be examined and set using the
following methods:

        $is_directed   = $graph->directed;
        $is_undirected = $graph->undirected;

Test the directedness of the graph.

        $graph->directed( 1 );
        $graph->undirected( 0 );

Mark the graph directed.

        $graph->undirected( 1 );
        $graph->directed( 0 );

Mark the graph undirected.

=cut

sub directed {
    my $graph = shift;

    if ( @_ ) {
        $graph->attribute( 'directed', $_[0] ? 1 : 0);
    } else {
        # The default is directed.
        $graph->attribute( 'directed', 1 )
            unless defined $graph->attribute( 'directed' );

        return $graph->attribute( 'directed' );
    }
}

sub undirected {
    my $graph = shift;

    if ( @_ ) {
        $graph->attribute( 'directed', $_[0] ? 0 : 1 );
    } else {
        # The default is directed.
        $graph->attribute( 'directed', 1 )
            unless defined $graph->attribute( 'directed' );

        return $graph->attribute( 'directed' ) ? 0 : 1;
    }
}

=pod

=head1 TOPOLOGICAL SORT

        @topo = $graph->topological_sort;

Return the vertices of the C<$graph> sorted topologically, that is,
in an order that respects the partial ordering of the graph.  There may
be many possible topological orderings of the graph.

=cut

sub topological_sort {
    my $graph = shift;

    my $topological_sort =
	Graph::DFS->new( { return_done_vertex => 1 } );

    my @sort;

    while ( my $v = $topological_sort->( $graph ) ) {
	push @sort, $v;
    }

    return reverse @sort;
}

=pod

=head1 MINIMUM SPANNING TREES

A minimum spanning tree (MST) is a derivative graph of an undirected
`weighted' graph, a graph that has an B<attribute> called C<Weight>
attached to each edge, see the C<add_attributed_path> method.  Each
edge weighs something or in other words has a cost associated with it.
A MST spans all the vertices with the least possible total weight.

        $mst = $graph->MST_kruskal;

Return a Kruskal's minimum spanning tree of the C<$graph>.  Notice the
'a tree', if there are many edges with similar costs, multiple equally
minimal trees can exist.

As a matter of fact the `weight' does not need to be called C<Weight>:

        $mst = $graph->MST_kruskal('Distance');

as long as you adjust your call to C<add_attributed_path> accordingly.

=cut

sub MST_kruskal {
    my ( $graph, $attr ) = @_;

    $graph->_make_undirected_sense( "minimum spanning tree" );

    $attr = 'Weight' unless defined $attr;

    my $mst = ( ref $graph )->new; # The minimum spanning tree.

    $mst->undirected( 1 );

    # The weighted edges.  Numeric attributes assumed.
    my @we = map { $_->[ 0 ] }
                 sort { $a->[ 1 ] cmp $b->[ 1 ] }
                       map { [ $_, $_->attribute( $attr ) ] } $graph->edges;

    my $V = $graph->vertices;

    # Walk the edges in the order of increasing weight.
    foreach my $we ( @we ) {
        my ( $u, $v ) = ( $we->start->name, $we->stop->name );

        # Add edge only iff no cycle imminent.
        unless ( $mst->find( $u, $v ) ) {
            $mst->add_edge( $u, $v );
            $mst->edge( $u, $v )->attribute( $attr, $we->attribute( $attr ) );
            last if $mst->vertices == $V;
        }
    }

    return $mst;
}

=pod

=head1 ALL-PAIRS SHORTEST PATHS

All-pairs shortest paths algorithms find out the shortest possible paths
between any pair of vertices.

=head2 FLOYD-WARSHALL ALL-PAIRS SHORTEST PATHS

        $fw_apsp = $graph->APSP_floyd_warshall;

Return the Floyd-Warshall all-pairs shortest paths as a graph.  More
specifically: in the returned graph every possible (path-connected)
pair is an edge.

Before the method call each edge should have an attribute, by default
C<Weight>, that tells the `cost' of the edge.  The name of the
attribute can be changed by supplying an argument:

        $fw_apsp = $graph->APSP_floyd_warshall( 'Distance' );

After the method call each edge has two attributes: C<Weight> (or what
was specified), which is the length of the minimal path up to and
including that edge, and C<prev>, which is the second to last vertex
on the minimal path.Example: If there is a path from vertex C<a> to
vertex C<f>, the edge C<a-f> has the attributes C<Weight>, for example
6, and C<Prev>, for example C<d>, which means that the last edge of
the minimal path from C<a> to C<f> is C<d-f>.  To trace the path
backwards, see the edge C<a-d>.  Sounds good but there is a catch: if
there is a negative cycle in the path the Prev attributes point along
this negative cycle and there is no way to break out of it back to the
original minimal path.

=cut

sub APSP_floyd_warshall {
    my ( $graph, $attr ) = @_;

    $attr = 'Weight' unless defined $attr;

    my @V = $graph->vertices;
    my $V = @V;

    my ( %v2i, @i2v );
    my $vertex_id = 0;

    foreach my $v ( @V ) {
        $v2i{ $v } = $vertex_id++;      # Number the vertices.
        $i2v[ $v2i{ $v } ] = $v;
    }

    my $dist;

    # The distance matrix diagonal is initially zero.
    # (and the path matrix diagonal is implicitly undefs).
    foreach my $v ( $graph->vertices ) {
        my $i = $v2i{ $v };
        $dist->[ $i ]->[ $i ] = 0;
    }

    my $path;

    # The rest of the distance matrix are the weights
    # and the rest of the path matrix are the parent vertices.
    foreach my $e ( $graph->edges ) {
        my ( $p, $s ) = $e->vertices;
        my $i = $v2i{ $p };
        my $j = $v2i{ $s };
        $dist->[ $i ]->[ $j ] = $e->attribute( $attr );
        $path->[ $i ]->[ $j ] = $p;
    }

    my ( $prev_dist,    $prev_path,
         $prev_dist_ij, $prev_dist_ikpkj,
         $prev_path_ij, $prev_path_kj     );

    # O($V**3) quite obviously: three $V-sized loops.

    for ( my $k = 0; $k < $V; $k++ ) {

        $prev_dist = $dist;     # Save and...
        $dist      = [ ];       # ...reset.

        $prev_path = $path;     # Save and...
        $path      = [ ];       # ...reset.

        for ( my $i = 0; $i < $V; $i++ ) {
            for ( my $j = 0; $j < $V; $j++ ) {

                if ( defined $prev_dist->[ $i ]->[ $j ] ) {
                    $prev_dist_ij =
                        $prev_dist->[ $i ]->[ $j ];
                    $prev_path_ij = $prev_path->[ $i ]->[ $j ];
                } else {
                    undef $prev_dist_ij;
                }

                if ( defined $prev_dist->[ $i ]->[ $k ]
                     and
                     defined $prev_dist->[ $k ]->[ $j ] ) {
                    $prev_dist_ikpkj =
                        $prev_dist->[ $i ]->[ $k ]
                        +
                        $prev_dist->[ $k ]->[ $j ];
                    $prev_path_kj = $prev_path->[ $k ]->[ $j ];
                } else {
                    undef $prev_dist_ikpkj;
                }

                $prev_path_ij = $prev_path->[ $i ]->[ $j ];
                $prev_path_kj = $prev_path->[ $k ]->[ $j ];

                # Find the minimum and update the distance
                # and path matrices appropriately.

                if ( defined $prev_dist_ij and
                     ( not defined $prev_dist_ikpkj
                       or
                       $prev_dist_ij <= $prev_dist_ikpkj ) ) {
                    $dist->[ $i ]->[ $j ] = $prev_dist_ij;
                    $path->[ $i ]->[ $j ] = $prev_path_ij;
                } elsif ( defined $prev_dist_ikpkj ) {
                    $dist->[ $i ]->[ $j ] = $prev_dist_ikpkj;
                    $path->[ $i ]->[ $j ] = $prev_path_kj;
                } # Both were undef which means infinite.
            }
        }
    }

    # Map the matrices back to a graph.

    my $apsp = ( ref $graph )->new;

    for ( my $i = 0; $i < $V; $i++ ) {
        my $p = $i2v[ $i ];

        for ( my $j = 0; $j < $V; $j++ ) {
            my $s = $i2v[ $j ];
            my $e = $apsp->add_edge( $p->name, $s->name );

            $e->attribute( $attr,  $dist->[ $i ]->[ $j ] );
            $e->attribute( 'Prev', $path->[ $i ]->[ $j ] );
        }
    }

    return $apsp;
}

=pod

=head2 TRANSITIVE CLOSURE

        $closure_graph = $graph->transitive_closure;

Return as a graph the transitive closure of the C<$graph>.  If there
is a path between a pair of vertices the the C<$graph>, there is an
edge between that pair of vertices in the transitive closure graph.
Transitive closure is the Boolean reduction of the all-pairs shortest
paths: the length of the path does not matter, just the existence.

=cut

sub transitive_closure {
    my $graph = shift;

    my @V = $graph->vertices;
    my $V = @V;

    my ( %v2i, @i2v );
    my $vertex_id = 0;

    foreach my $v ( $graph->vertices ) {
        $v2i{ $v } = $vertex_id++;      # Number the vertices.
        $i2v[ $v2i{ $v } ] = $v;
    }

    my $closure_matrix;

    # Initialize the closure matrix to zeros.
    for ( my $i = 0; $i < $V; $i++ ) {
        $closure_matrix->[ $i ] = [ ( 0 ) x $V ];
    }

    # The closure matrix diagonal is naturally one.
    foreach my $v ( $graph->vertices ) {
        my $i = $v2i{ $v };
        $closure_matrix->[ $i ]->[ $i ] = 1;
    }

    # Also the edges are ones.
    foreach my $e ( $graph->edges ) {
        my ( $p, $s ) = $e->vertices;
        my $i = $v2i{ $p };
        my $j = $v2i{ $s };
        $closure_matrix->[ $i ]->[ $j ] = 1;
    }

    # O($V**3) quite obviously: three loops till $V.

    my ( $prev_closure_matrix,
         $prev_closure_ij,
         $prev_closure_jk,
         $prev_closure_kj );

    for ( my $k = 0; $k < $V; $k++ ) {

        $prev_closure_matrix = $closure_matrix; # Save and...
        $closure_matrix      = [ ];             # ...reset.

        for ( my $i = 0; $i < $V; $i++ ) {
            for ( my $j = 0; $j < $V; $j++ ) {

                $closure_matrix->[ $i ]->[ $j ] =
                    $prev_closure_matrix->[ $i ]->[ $j ] |
                    ( $prev_closure_matrix->[ $i ]->[ $k ] &
                      $prev_closure_matrix->[ $k ]->[ $j ] );
            }
        }
    }

    # Map the closure matrix into a closure graph.

    my $closure_graph = ( ref $graph )->new;

    for ( my $i = 0; $i < $V; $i++ ) {
        for ( my $j = 0; $j < $V; $j++ ) {
            if ( $closure_matrix->[ $i ]->[ $j ] ) {
                $closure_graph->add_edge( $i2v[ $i ], $i2v[ $j ] );
            }
        }
    }

    return $closure_graph;
}

=pod

=head1 COMPATIBILITY

Neil Bowers has written C<graph-modules-1.001> in Canon Research
Center Europe.  The whole graph model is very different.

In Bowers' model graph nodes (vertices) and graph edges are
instantiated explicitly, in that order.  In effect, there is only one
graph per one Perl script runtime.

In this module I<graphs> are instantiated and then vertices and edges
are added into them, either explicitly or implicitly.  There may be
multiple graphs active simultaneously, and they may have identically
named vertices.

Some simple compatibility mappings are possible:

=over 4

=item C<getAttribute()> and C<setAttribute()> are possible either
using explicit C<attribute()> or with the implicit virtual attributes,
see L<Graph::Element>.

=item C<Graph::Node> is C<Graph::Vertex> -- but note
that you should never explicitly use C<Graph::Vertex>, as
opposed to what you have been doing with C<Graph::Node>.

=back

The C<save()> method is available for graphs, see L<Graph::Archive>.

=cut

=head1 SAVING (AND, SOME DAY, LOADING) GRAPHS

=head2 GRAPH FILE FORMATS

The known graph file formats are

=over 4

=item graph adjacency list, suffix C<'gal'>

An example:

        gal 001
        vertices 6
        a b c d e f
        edges 5
        a b
        b c d
        c
        d
        e b e
        f
        2 _id GLOB(0x15b3e8) directed 1
        a 1 _id GLOB(0x15ccdc)
        ...
        b c 1 _id GLOB(0x15cee0)
        b d 1 _id GLOB(0x15cee8)
        ...

The first line identifies the C<gal> format and its version as C<001>.
The next line tells the number of the vertices, I<V>.  The next line
lists the vertices.  The next line tells the number of edges, I<E>.
The next I<E> lines are the edges in adjacency list format:

        start_vertex end_vertex_1 vertex_2 ...

After the edge lines lines are I<1+V+E> lines listing the attributes
of the graph, the vertices, and the edges.  The vertex attribute lines
begin with the vertices, the edges attributes lines with the two
vertices.  The attributes themselves are of the form:

        number_of_attributes attribute_key_1 attribute_value_1 ...

The vertices, edges, and attributes can contain whitespace characters
but they must be encoded like this: C<=XX> where the C<XX> are two
hexadecimal digits, for example C<=20> is the space character (in
ASCII or ISO Latin).  Obviously, any possible C<=>s need to be
encoded: C<=3d>.

=item graph adjacency matrix, suffix C<'gam'>

The C<gam> format is very similar to the C<gal> format.  The only
difference is in listing the edges an adjacency matrix is used: a
I<boolean matrix> in text format that has C<1> whenever there is an
edge from a vertex to another vertex, C<0> elsewhere.

        gal 001
        vertices 6
        a b c d e f
        edges 5
        0 1 0 0 0 0
        0 0 1 1 0 0
        0 0 0 0 0 0
        0 0 0 0 0 0
        0 1 0 0 1 0
        0 0 0 0 0 0
        2 _id GLOB(0x15b3e8) directed 1
        a 1 _id GLOB(0x15ccdc)
        ...
        b c 1 _id GLOB(0x15cee0)
        b d 1 _id GLOB(0x15cee8)
        ...

The above C<gam> specififies exactly the same edges as the
even-further-above C<gal>.

=item I<daVinci>, suffix C<'daVinci'>, see
C<http://www.informatik.uni-bremen.de/~davinci/>.

=back

=head2 SAVING GRAPHS

        $graph->save('daV');

The graph will be saved in daVinci format to C<graph.daVinci>.

        $graph->save('foo.daV');

The graph will be saved in daVinci format to C<foo.daVinci>.

        $graph->save('foo');

The graph will be saved in daVinci format to C<foo.daVinci>.

        $graph->save();

The graph will be saved in daVinci format to C<graph.daVinci>.

        $graph->save('gal');

The graph will be saved in adjacency list format to C<graph.gal>.

        $graph->save('foo.gal');

The graph will be saved in adjacency list format to C<foo.gal>.

        $graph->save('gam');

The graph will be saved in adjacency matrix format to C<graph.gam>.

        $graph->save('foo.gam');

The graph will be saved in adjacency matrix format to C<foo.gam>.

In all the above the 'suffix' is case-insensitive, the filename part
is not.

=cut

sub _vertex_encode {
    my $name = shift;

    $name =~ s/([\s%])/sprintf("%%%02x", ord $1)/eg;

    return $name;
}

sub _write_daVinci_vertex {
    my ( $depth, $graph, $vertex, $seen ) = @_;

    my $prefix = ' ' x $depth;

    if ( exists $seen->{ $vertex } ) {
        return sprintf 'r("%s")', $vertex;
    } else {
        $seen->{ $vertex } = 1;

        my $attributes = _write_daVinci_attributes( $depth + 1, $vertex );

        my $succ = _write_daVinci_succ( $depth + 1, $graph, $vertex, $seen );

        my $nev  = _vertex_encode( $vertex );

        return sprintf 'l("%s",n("%s",%s))',
                       $nev, $nev,
                       join ",\n$prefix", $attributes, $succ;
    }
}

sub _write_daVinci_attributes {
    my ( $depth, $self ) = @_;

    my $prefix = ' ' x $depth;

    my %a = $self->_attributes;

    my @a = map { my $k = $_;
                  my $v = $self->attribute( $_ );

                  if ( $k eq '_id' ) {
                      $k = 'OBJECT';
                      if ( ref $self eq 'Graph::Vertex' ) {
                          $v = $self->name;
                      } elsif ( ref $self eq 'Graph::Edge' ) {
                          $v = $self;
                      }
                  }

                  sprintf( 'a("%s","%s")',
                           _vertex_encode( $k ),
                           _vertex_encode( $v ) )
                }
                keys %a;

    return '[' . join( ",", @a ) . ']';
}

sub _write_daVinci_succ {
    my ( $depth, $graph, $vertex, $seen ) = @_;

    my $prefix = ' ' x $depth;

    my @succ;

    foreach my $u ( $graph->vertex_successors( $vertex ) ) {
        my $e = $graph->edge( $vertex, $u );
        push @succ, sprintf 'e("%s",%s,%s)',
                            $e,
                            _write_daVinci_attributes( $depth + 1, $e ),
                            $u eq $vertex ?
                               sprintf 'r("%s")', _vertex_encode( $u ) :
                               _write_daVinci_vertex( $depth + 1,
                                                      $graph,
                                                      $u,
                                                      $seen );
    }

    return sprintf '[' . join( ",\n$prefix", @succ ) . ']';
}

sub _write_daVinci {
    my $graph = shift;

    my $depth = 1;
    my %seen;

    my @daVinci;

    foreach my $v ( sort $graph->vertices ) {
        push @daVinci, _write_daVinci_vertex( $depth, $graph, $v, \%seen )
            unless $seen{ $v };
    }

    return "[\n" . join( ",\n", @daVinci ) . "\n]"; 
}

sub _file_defaults {
    my $spec = shift;

    if ( defined $spec ) {
        if ( "\L$spec" eq 'dav' ) {
            return ( 'graph.daVinci', 'daV' );
        } elsif ( "\L$spec" eq 'gal' ) {
            return ( 'graph.gal', 'gal' );
        } elsif ( "\L$spec" eq 'gam' ) {
            return ( 'graph.gam', 'gam' );
        }
        
        my ( $base, $suffix ) = ( $spec =~ /(.+)\.([^.]+)$/);

        if ( defined $suffix ) {
            if ( "\L$suffix" eq 'dav' ) {
                return ( "$base.daVinci", 'daV' );
            } elsif ( "\L$suffix" eq 'gal' ) {
                return ( $spec, 'gal' );
            } elsif ( "\L$suffix" eq 'gam' ) {
                return ( $spec, 'gam' );
            } else {
                warn "Unknown graph file format '$suffix'.\n";
                return ( );
            }
        } else {
            return ( "$spec.daVinci", 'daV' );
        }
    } else {
        return ( 'graph.daVinci', 'daV' );
    }
}

sub _ga_init ($$) {
    my ( $graph, $version ) = @_;

    my @v = sort $graph->vertices;

    my %c; # The vertex names encoded.

    @c{ @v } = map { _vertex_encode $_ } @v;

    return ( \@v,
             \%c,
             join "\n",
                  $version,
                  sprintf( "graph %s", defined $graph->name ?
                                              $graph->name : '' ),
                  sprintf( "vertices %d", scalar @v ),
                  join( " ", @c{ @v } ),
                  sprintf( "edges %d", scalar $graph->edges ) );
}

sub _ga_attributes ($$) {
    my ( $graph, $v ) = @_;

    my @att;

    my %gat = $graph->_attributes;

    push @att, join " ",
               scalar keys %gat,
               map { _vertex_encode $_ } %gat;

    foreach my $u ( @$v ) {
        my %att = $u->_attributes;

        push @att, sprintf( "%s %d %s",
                            _vertex_encode( $u ),
                            scalar keys %att,
                            join " ",
                                map { _vertex_encode $_ } %att );
    }

    foreach my $e ( $graph->edges ) {
        my ( $u, $v ) = $e->vertices;

        my %att = $e->_attributes;

        delete $att{ start };
        delete $att{ stop  };

        push @att, sprintf( "%s %s %d %s",
                            _vertex_encode( $u ),
                            _vertex_encode( $v ),
                            scalar keys %att,
                            join " ",
                                map { _vertex_encode $_ } %att );
                            
    }

    return @att;
}

my $gal_version = 'gal 001';

sub _write_adjlist {
    my $graph = shift;

    my ( $v, $c, $h ) = $graph->_ga_init( $gal_version );

    my @adj;

    foreach my $u ( @$v ) {
        push @adj, join " ",
                        $c->{ $u },
                        map { $c->{ $_ } }
                            sort $graph->vertex_successors( $u );
    }

    return join( "\n", $h, @adj, $graph->_ga_attributes( $v ) );
}

my $gam_version = 'gam 001';

sub _write_adjmatrix {
    my $graph = shift;

    my ( $v, $c, $h ) = $graph->_ga_init( $gam_version );

    my @adj;

    foreach my $u ( @$v ) {
        my @adv;

        foreach my $v ( @$v ) {
            push @adv, $graph->has_edge( $u, $v ) ? 1 : 0;
        }

        push @adj, join " ", @adv;
    }

    return join( "\n", $h, @adj, $graph->_ga_attributes( $v )  );
}

sub save {
    my ( $graph, $spec ) = @_;

    my ( $filename, $format ) = _file_defaults( $spec );

    my %saver = ( 'daV', \&_write_daVinci,
                  'gal', \&_write_adjlist,
                  'gam', \&_write_adjmatrix );

    my $saver = $saver{ $format };

    if ( defined $saver ) {
        if ( open( SAVE, ">$filename" ) ) {
            print SAVE $saver->( $graph );
            print SAVE "\n";
            close SAVE;
            return 1;
        } else {
            warn "Failed to open '$filename' for saving: $!\n";
            return 0;
        }
    } else {
        warn "save: unknown file specifier '$spec', cannot save.\n";
    }
}

=pod

=head1 LOADING GRAPHS

Sorry, at the moment no methods for loading graphs from files are
implemented.

=cut

# TODO: Graph::Element::destroy, to customize element destruction.

sub DESTROY {
    my $graph = shift;

    Graph::Element::debug "DESTROY Graph $graph, ID = ", $graph->_id;

    # Deleting the vertices will also delete the edges.
    foreach my $v ( $graph->vertices ) {
        $graph->delete_vertex( $v );
    }

    $graph->_delete;

    $graph->delete_attribute( '_id' );

    $graph->SUPER::DESTROY;
}

=pod

=head1 SEE ALSO

L<Graph::Directed>, L<Graph::Undirected>,
L<Graph::Vertex>, L<Graph::Edge>,
L<Graph::Element>, L<Graph::DFS>.

=head1 VERSION

Version 0.004.

=head1 AUTHOR

Jarkko Hietaniemi <F<jhi@iki.fi>>

=head1 COPYRIGHT

Copyright 1998, O'Reilly and Associates.

This code is distributed under the same copyright terms as Perl itself.

=cut

1;
