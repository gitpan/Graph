package Graph;

=pod

=head1 NAME

Graph - graph data structures and algorithms

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 VERSION

Version 0.001.

=head1 AUTHOR

Jarkko Hietaniemi, <F<jhi@iki.fi>>

=head1 COPYRIGHT

Copyright 1998, O'Reilly & Associates.

This code is distributed under the same copyright terms as Perl itself.

=cut

# The top-level graph class, meant for public consumption.
#
# Implementation Notes:
#
# None the base classes: Graph::_element, Graph::Vertex, and
# Graph::Edge, is meant to be used directly.  A vertex or an edge
# is meaningful only in the context of a graph, therefore please
# not use those classes directly, let the Graph use them for you.
#
# There are also two `fake' classes: Graph::Directed and Graph::Undirected.
# The former is in practice identical to Graph, the latter almost, the
# only difference being that is produces undirected graphs from new(),
# the default of Graph (and obviously Graph::Directed) being a directed
# graph.
#
# As usual, the methods or subroutines starting with an underscore
# are not meant to be used directly; internal use only.
#
# Unknown methods are trapped by the Graph::_element::AUTOLOAD to
# be attribute set/get methods but only iff the method names begin
# with an uppercase letter.  Methods beginning with lowercase letters
# are assumed to be typos and cause a fatal runtime exception.
# For example if $e is an edge $e->Weight will return the current
# value of the 'Weight' attribute of the edge and $e->Weight( 3 )
# will set the attribute to be 3.
#
# By using this `virtual' attribute method every element
# (whether a graph, vertex, or edge) can have an 'Id' attribute.
# For vertices this is mandatory (how else one could refer to
# a vertex), for graph optional, and for edges rarely needed
# because the two end vertices unambiguously define the edge.
#
# Being an undirected or a directed graph is simply a flag in
# the graph: where it matters is how the successors are predecessors
# of a vertex are defined.  For undirected graphs, these sets of
# vertices are always equal.  For directed graphs, they may be,
# but seldom are (only for a strongly connected graph, I guess).
#
# The $state used in DFS, BFS, and the flow networks, is a hash
# reference carrying both static and dynamic state.  Most importantly
# it holds the various hooks used by the algorithms.  It is, if you will,
# the own private stack frame and heap of the algorithms, in a word, state.
#

use strict;
use Carp 'confess';
use vars qw(@ISA);

use Graph::_element;
use Graph::Vertex;
use Graph::Edge;

@ISA = qw(Graph::_element);

use overload q("") => \&as_string,
             q(eq) => sub { as_string( $_[ 0 ] ) eq $_[ 1 ] };

# as_string($g)
#   The stringification.
#   Uses the stringifications of edges (and vertices) and vertices.
#

sub as_string {
    my $g = shift;
    
    return join( ",",
		 sort $g->edges, $g->unconnected_vertices );
}

# new($type, $id)
#   The constructor.
#   Sets the Id attribute.
#

sub new {
    my $type = shift;

    my $g = { };

    bless $g, $type;

    $g->Id( shift ) if @_;

    return $g;
}

# add_vertex($graph, $vertex_ids)
#   Adds one or more (or no) vertices to a graph.
#

sub add_vertex {
    my $g = shift;

    foreach my $id ( @_ ) {
	unless ( exists $g->{ V }->{ $id } ) {
	    $g->{ V }->{ $id } = Graph::Vertex->_new( $id );
	    $g->{ V }->{ $id }->G( $g );
	}
    }
}

# add_edge($graph, $start_vertex, $end_vertex, ...)
#   Adds one or more edges, represented by their start and
#   end vertex ids, to the graph.
#

sub add_edge {
    my $g = shift;

    my ( $p, $s, $has_p, $has_s, $e );
    my @edges;

    while ( ( $p, $s ) = splice( @_, 0, 2 )) {

	if ( not defined $s ) {
	    warn "Uneven number of vertices, last vertex '$p'.\n";
	    confess "Died";
	}

	$has_p = exists $g->{ V }->{ $p };
	$has_s = exists $g->{ V }->{ $s };

	$g->add_vertex( $p ) unless $has_p;
	$g->add_vertex( $s ) unless $has_s;

	if ( not $has_p or
	     not $has_s or
	     not exists $g->{ E }->{ $p }->{ S }->{ $s } or
	     not exists $g->{ E }->{ $s }->{ P }->{ $p } ) {

	    $p = $g->{ V }->{ $p };
	    $s = $g->{ V }->{ $s };
	    
	    $e = Graph::Edge->_new( $p, $s );
	    $e->G( $g );

	    $g->{ E }->{ $p }->{ S }->{ $s } = $e;
	    $g->{ E }->{ $s }->{ P }->{ $p } = $e;

	    # Introduce the union-find structure.
	    # NOTE: delete_edge does not yet update
	    # the union-find structure.
	    $g->union( $p, $s ) if $g->undirected;
	}
    }
}

# merge_edges($destination_graph, $source_graph)
#   Imports all the edges from the source graph
#   to the destination graph.  The import is
#   done by the vertex ids (that is, by cloning),
#   otherwise the vertices would be shared by
#   the two graphs, which would not be a Good Thing.
#

sub merge_edges {
    my ( $g_dst, $g_src ) = @_;

    my ( $p, $s );

    foreach my $e ( $g_src->edges ) {
	$g_dst->add_edge( $e->vertex_Ids );
    }
}

# _make_sense($graph, $sense, $make, $concept)
#   A helper method for throwing a fatal exception if the
#   asked question makes no sense for the type of the graph.
#

sub _make_sense {
    my ( $g, $sense, $make, $concept ) = @_;

    unless ( $make ) {
	warn( ( caller( 2 ))[ 3 ], ":\n");
	warn "\u$concept make sense only for $sense graphs.\n";
	warn "The graph $g is not one.\n";
	confess "Died";
    }
}

# _make_directed_sense($graph, $concept)
#   A helper method for throwing a fatal exception if the
#   asked question makes no sense for a directed graph.
#

sub _make_directed_sense {
    my ( $g, $concept ) = @_;

    $g->_make_sense( "directed",   $g->directed,   $concept );
}

# _make_undirected_sense()
#   A helper method for throwing a fatal exception if the
#   asked question makes no sense for an undirected graph.
#

sub _make_undirected_sense {
    my ( $g, $concept ) = @_;

    $g->_make_sense( "undirected", $g->undirected, $concept );
}

# union_find($graph, $do_union, $vertex, $other_vertex)
#   The union-find operation.  The $do_union flag tells
#   whether this a union operation or a find operation.
#

sub union_find {
    my ( $g, $do_union, $p, $s ) = @_;

    my ( $i, $j );

    unless ( defined $g->{ union_find_by_vertex }->{ $p } ) {
	$i = ++$g->{ union_find_next_id };
	$g->{ union_find_by_vertex }->{ $p } = $i;
	$g->{ union_find_by_id     }->[ $i ] = $p;
	$g->{ union_find_parent    }->[ $i ] = 0;
    } else {
	$i = $g->{ union_find_by_vertex }->{ $p };
    }	

    unless ( defined $g->{ union_find_by_vertex }->{ $s } ) {
	$j = ++$g->{ union_find_next_id };
	$g->{ union_find_by_vertex }->{ $s } = $j;
	$g->{ union_find_by_id     }->[ $j ] = $s;
	$g->{ union_find_parent    }->[ $j ] = 0;
    } else {
	$j = $g->{ union_find_by_vertex }->{ $s };
    }

    my ( $oi, $oj ) = ( $i, $j ); # Save these for path compression.

    $i = $g->{ union_find_parent }->[ $i ]
	while $g->{ union_find_parent }->[ $i ] > 0;

    $j = $g->{ union_find_parent }->[ $j ]
	while $g->{ union_find_parent }->[ $j ] > 0;

    # Path compression, do another pass (well, two passes)
    # connecting all the vertices to the newly found root.

    ( $oi, $g->{ union_find_parent }->[ $oi ] ) =
	( $g->{ union_find_parent }->[ $oi ], $i )
	    while $g->{ union_find_parent }->[ $oi ] > 0;

    ( $oj, $g->{ union_find_parent }->[ $oj ] ) =
	( $g->{ union_find_parent }->[ $oj ], $j )
	    while $g->{ union_find_parent }->[ $oj ] > 0;

    my $same = $i == $j;

    # Make the union.
    if ( $do_union and not $same ) {

	# Weight balancing, no balancing would be simply:
	# $g->{ union_find_parent }->[ $j ] = $i;

	# Pick the smaller of the trees.
	if ( $g->{ union_find_parent }->[ $j ]
	     <
	     $g->{ union_find_parent }->[ $i ] ) {

	    $g->{ union_find_parent }->[ $j ] +=
		$g->{ union_find_parent }->[ $i ] - 1;
	    $g->{ union_find_parent }->[ $i ] = $j;

	} else {

	    $g->{ union_find_parent }->[ $i ] +=
		$g->{ union_find_parent }->[ $j ] - 1;
	    $g->{ union_find_parent }->[ $j ] = $i;

	}
    }

    return $same;
}

# find($graph, $vertex, $other_$vertex)
#   The find operation of the union-find fame.
#

sub find {
    my ( $g, $p, $s ) = @_;

    $g->_make_undirected_sense( "union-find" );

    return $g->union_find( 0, $p, $s );
}

# union($graph, $vertex, $other_vertex)
#   The union operation of the union-find fame.
#

sub union {
    my ( $g, $p, $s ) = @_;

    $g->_make_undirected_sense( "union-find" );

    return $g->union_find( 1, $p, $s );
}

# has_vertex($g, @ids)
#   Return true if the graph has all the named vertices.
#

sub has_vertex {
    my $g = shift;

    foreach my $id ( @_ ) {
	return 0 unless exists $g->{ V }->{ $id };
    }

    return 1;
}

# directed($graph)
#   Get or set the directedness of the graph.
#

sub directed {
    my $g = shift;

    if ( @_ ) {
	$g->attr( 'directed', shift());
    } else {
	# The default is directed.
	$g->attr( 'directed', 1 )
	    unless defined $g->attr( 'directed' );

	return $g->attr( 'directed' );
    }
}

# undirected($graph)
#   Get or set the undirectedness of the graph.
#

sub undirected {
    my $g = shift;

    if ( @_ ) {
	$g->attr( 'directed', shift() ? 0 : 1 );
    } else {
	# The default is directed.
	$g->attr( 'directed', 1 )
	    unless defined $g->attr( 'directed' );

	return $g->attr( 'directed' ) ? 0 : 1;
    }
}

# _successors($graph, $vertex)
#   The true successors of the vertex in the graph.
#   True means that only the successors expliclity
#   added by add_edge(), regardless whether the graph
#   is undirected or directed.
#

sub _successors {
    my ( $g, $v ) = @_;

    return map { $_->S } values %{ $g->{ E }->{ $v }->{ S } };
}

# _predecessors()
#   The true predecessors of the vertex in the graph.
#   For the meaning of true see _successors().
#

sub _predecessors {
    my ( $g, $v ) = @_;

    return map { $_->P } values %{ $g->{ E }->{ $v }->{ P } };
}

# neighbors($graph, $vertex)
#   The union of _successors() and _predecessors,
#   all the neighboring vertices of the vertex in the graph.
#

sub neighbors {
    my ( $g, $v ) = @_;

    return ( $g->_successors  ( $v ),
	     $g->_predecessors( $v ) );
}

# successors()
#   The successor vertices of the vertex in the graph.
#   Directedness-scient, as opposed to _successors().
#

sub successors {
    my ( $g, $v ) = @_;

    return $g->directed ?
	   $g->_successors( $v ):
	   $g-> neighbors ( $v );
}

# predecessors()
#   The predecessor vertices of the vertex in the graph.
#   Directedness-scient, as opposed to _predecessors().
#

sub predecessors {
    my ( $g, $v ) = @_;

    return $g->directed ?
	   $g->_predecessors( $v ):
	   $g-> neighbors   ( $v );
}

# delete_vertex($graph, @vertex_ids)
#   Delete one or more (or no) vertices from the graph.
#   A bit tricky because all the connecting edges
#   also need to be deleted.
#

sub delete_vertex {
    my $g = shift;

    foreach my $id ( @_ ) {
	if ( exists $g->{ V }->{ $id } ) {
	    my $v = $g->{ V }->{ $id };

	    foreach my $s ( $g->_successors( $v ) ) {
		delete $g->{ E }->{ $s }->{ P }->{ $v };
	    }
	    delete $g->{ E }->{ $v }->{ S };

	    foreach my $p ( $g->_predecessors( $v ) ) {
		delete $g->{ E }->{ $p }->{ S }->{ $v };
	    }
	    delete $g->{ E }->{ $v }->{ P };

	    delete $g->{ V }->{ $v };
	}
    }
}

# delete_edge($graph, $start_vertex, $end_vertex, ...)
#   Delete one or more (or no) edges from the graph.
#   The edges are specified by their end vertices.
#   Note that also the knowledge of the edge by the
#   end vertices needs to undone.
#   NOTE: delete_edge does not yet update
#   the union-find structure.
#

sub delete_edge {
    my $g = shift;

    my ( $p, $s );

    while ( ( $p, $s ) = splice( @_, 0, 2 )) {
	$p = $g->{ V }->{ $p };
	$s = $g->{ V }->{ $s };
	delete $g->{ E }->{ $p }->{ S }->{ $s }
	    if exists $g->{ E }->{ $p };
	delete $g->{ E }->{ $s }->{ P }->{ $p }
	    if exists $g->{ E }->{ $s };
    }
}

# vertices($graph, @vertex_ids)
#   Return all or selected vertices of the graph.
#   If no ids are given, all the vertices are returned.
#   If one id is given, that one vertex is returned.
#   If more ids are given, the list of corresponding vertices is returned.
#   Unknown vertices return as undefs.
#

sub vertices {
    my $g = shift;

    my $id;

    if ( @_ == 1 ) {
	$id = shift;

	return $g->{ V }->{ $id };
    } elsif ( @_ ) {
	my @V;

	foreach my $id ( @_ ) {
	    push( @V, $g->{ V }->{ $id } );
	}

	return @V;
    } else {
	return values %{ $g->{ V } };
    }
}

# edges($graph, @edge_ids)
#   Return all or selected edges of the graph.
#   If no ids are given, all the edges are returned.
#   If one id pair is given, that one edge is returned.
#   If more ids are given, the list of corresponding edges is returned.
#   Unknown edges return as undefs.
#

sub edges {
    my $g = shift;

    my ( $v, $p, $s, @E );

    if ( @_ == 2 ) {
	( $p, $s ) = @_;

	return $g->{ E }->{ $p }->{ S }->{ $s }
	    if defined $g->{ E }->{ $p }->{ S }->{ $s };

	return $g->{ E }->{ $s }->{ S }->{ $p }
	    if $g->undirected and
               defined $g->{ E }->{ $s }->{ S }->{ $p };
	
	return undef;

    } elsif ( @_ ) {

	if ( $g->directed ) {

	    while ( ( $p, $s ) = splice( @_, 0, 2 )) {
		push( @E, $g->{ E }->{ $p }->{ S }->{ $s } );
	    }

	} else {

	    while ( ( $p, $s ) = splice( @_, 0, 2 )) {
		if ( defined $g->{ E }->{ $p }->{ S }->{ $s } ) {
		    push( @E, $g->{ E }->{ $p }->{ S }->{ $s } );
		} elsif ( defined $g->{ E }->{ $s }->{ S }->{ $p } ) {
		    push( @E, $g->{ E }->{ $s }->{ S }->{ $p } );
		}
	    }

	}

	return @E;

    } else {

	foreach $p ( $g->vertices ) {
	    # True successors.
	    foreach $s ( $g->_successors( $p ) ) {
		push( @E, $g->{ E }->{ $p }->{ S }->{ $s } );
	    }
	}
	
	return @E;
    }
}

# classify_vertices($graph)
#   Classify the vertices of the graph.
#   The classification is returned as hash reference where
#   the keys are qw(connected unconnected self sink source)
#   and the values are hash references which have the appropriate
#   vertices both as the values and as the keys.
#   If this sounds complicated, you can used the
#   derived methods, connected_vertices() ... source_vertices().
#   After the call, the class of a vertex $v
#   is available as the Class attribute: $v->Class.
#

sub classify_vertices {
    my $g = shift;

    my ( %Vc, %Vu, %Vslf, %Vsnk, %Vsrc); # Classification slots.

    foreach my $v ( $g->vertices ) {
	# True successors or predecessors.
	my @s = $g->_successors  ( $v );
	my @p = $g->_predecessors( $v );
	if ( @s or @p ) {
	    $Vc{ $v } = $v;
	    if ( @s == 0 ) {
		$v->Class( 'sink' );
		$Vsnk{ $v } = $v;
	    } elsif ( @p == 0 ) {
		$v->Class( 'source' );
		$Vsrc{ $v } = $v;
	    }
	    foreach my $s ( @s ) {
		if ( $s eq $v ) {
		    $v->Class( 'self' );
		    $Vslf{ $v } = $v;
		    last;
		}
	    }
	} else {
	    $v->Class( 'unconnected' );
	    $Vu{ $v } = $v;
	}
	# Mark the in- and out-degrees.
	$v->In ( scalar @p );
	$v->Out( scalar @s );
    }

    return { connected   => \%Vc,
	     unconnected => \%Vu,
	     self        => \%Vslf,
	     sink        => \%Vsnk,
	     source      => \%Vsrc };
}

# connected_vertices($graph)
#   Returns the (unordered) list of connected vertices of the graph.
#

sub connected_vertices {
    my $g = shift;

    return values %{ $g->classify_vertices->{ connected } };
}

# unconnected_vertices($graph)
#   Returns the (unordered) list of unconnected vertices of the graph.
#

sub unconnected_vertices {
    my $g = shift;

    return values %{ $g->classify_vertices->{ unconnected } };
}

# self_vertices($graph)
#   Returns the (unordered) list of self-looping vertices of the graph.
#

sub self_vertices {
    my $g = shift;

    return values %{ $g->classify_vertices->{ self } };
}

# sink_vertices($graph)
#   Returns the (unordered) list of sink vertices of the graph.
#

sub sink_vertices {
    my $g = shift;

    return values %{ $g->classify_vertices->{ sink } };
}

# source_vertices($graph)
#   Returns the (unordered) list of source vertices of the graph.
#

sub source_vertices {
    my $g = shift;

    return values %{ $g->classify_vertices->{ source } };
}

# density($graph)
#   Returns the density of the graph as a number between
#   0 and 1.  Zero means an empty graph (no edges, and possibly
#   no vertices...) and one means a complete graph.  Works
#   correctly for both directed and undirected graphs.
#

sub density {
    my $g = shift;

    my $V = scalar $g->vertices;
    my $m = $V * ( $V - 1 );

    $m /= 2 if $g->undirected;

    return $g->edges / $m;
}

# sparse($graph)
#   Returns true if the graph is sparse.
#   This is of course a judgement call but we use the limit
#   E < V log(V).
#

sub sparse {
    my $g = shift;

    my $V = scalar $g->vertices;

    return 1 if $V == 0;

    my $m = $V * log( $V );

    $m /= 2 if $g->undirected;

    return $g->edges < $m;
}

# dense()
#   Returns true if the graph is dense.
#   This is of course a judgement call but we use the limit
#   E > V - V log(V).
#

sub dense {
    my $g = shift;

    my $V = scalar $g->vertices;

    return 0 if $V == 0;

    my $m = $V - $V * log( $V );

    $m /= 2 if $g->undirected;

    return $g->edges < $m;
}

# _path_to_edge()
#   A private helper function that converts a list of vertices
#   that is supposed to represent of path to a list of
#   vertices that can be fed to, say, the add_edge() method.
#   The furious map() is doing nothing more complicated than
#   converting a list like: a b c d ... to a list like:
#   a b b c c d d ..., not unlike stuttering.
#

sub _path_to_edge {
    return
	map { ( $_[0]->[ $_ ], $_[0]->[ $_ + 1 ] ) }
            0..( $#{ $_[0] } - 1 );
}

# _find_vertex()
#   A private helper function that verifies that a given
#   vertex really is a vertex in a given graph.  Returns
#   the vertex as a real vertex object even if the vertex
#   was specified only by its id.
#

sub _find_vertex {
    my ( $g, $v ) = @_;
    
    unless ( ref $v ) {
	my $u = $g->vertices( $v );

	unless ( defined $u ) {
	    my $sub = ( caller(1) )[ 3 ];

	    warn "$sub: vertex $v\n";
	    warn "not in graph $g.\n";
	    confess "Died";
	}

	return $u;
    }
	

    return $v;
}

# add_path($graph, @path_vertices)
#   Add a path of vertices (as edges) to the graph.
#

sub add_path {
    my $g = shift;
    
    $g->add_edge( _path_to_edge( \@_ ) );
}

# delete_path()
#   Delete a path of vertices (the edges) from the graph.
#

sub delete_path {
    my $g = shift;
    
    $g->delete_edge( _path_to_edge( \@_ ) );
}

# _walk_init($graph, $state)
#   A private helper method used by both DFS and BFS.
#   Initializes the state and the graph vertices for a traversal.
#

sub _walk_init {
    my ( $g, $state ) = @_;

    $state->{ graph   } = $g;
    $state->{ order   } = 0;
    
    $state->{ unseen } = { };

    foreach my $v ( $g->vertices ) {
	$state->{ unseen }->{ $v } = 1;
    }
}

# _walk_successors($graph, $vertex, $state)
#   A private helper method used by both DFS and BFS.
#   For a vertex in a graph returns its successors,
#   possibly filtered by a hook and ordered by another hook.
#   Marks the vertex as seen (not un-seen) and
#   marks the `seen' time stamp.
#

sub _walk_successors {
    my ( $g, $v, $state ) = @_;

    delete $state->{ unseen }->{ $v };

    $state->{ seen }->{ $v } = $state->{ order }++;
		
    my @s = $v->successors;
		
    my $successor_grep = $state->{ successor_grep }; # Selector.
    my $successor_sort = $state->{ successor_sort }; # Orderer.

    # If some successors are (not) wanted.
    @s = grep { $successor_grep->( $v, $_, $state ) } @s
	if defined $successor_grep;

    # If some successor order is preferred.
    @s = sort { $successor_sort->( $a, $b, $state ) } @s
	if defined $successor_sort;
		
    return @s;
}

# classify_edges($graph, $state)
#   Classify the edges to one of the classes
#   qw(tree back forward cross)
#   After the call the class of edge $e is available
#   as the attribute Class: $e->Class.
#   For an undirected graph, no forward or cross edges exist:
#   potential forward edges become back edges.
#

sub classify_edges {
    my ( $g, $state ) = @_;

    # Reset edge classifications.

    foreach my $e ( $g->edges ) {
	$e->delete_attr( 'class' );
    }
    
    $state->{ edge_class } = { };

    $state->{ edge_unseen_hook } =
	sub {
	    my ( $p, $s, $state ) = @_;

	    $state->{ edge_class }->{ $p }->{ $s } = "tree";
	};

    $state->{ edge_seen_hook } =
	sub {
	    my ( $p, $s, $state ) = @_;
	     
	    if ( not exists $state->{ done }->{ $s } ) {
		$state->{ edge_class }->{ $p }->{ $s } = "back";
	    } elsif ( $state->{ seen }->{ $p }
		      <
		      $state->{ seen }->{ $s } ) {
		if ( $state->{ graph }->directed ) {
		    $state->{ edge_class }->{ $p }->{ $s } = "forward";
		} else {
		    # Remove and reinserted edge reversed.
		    $g->delete_edge( $p->Id, $s->Id );

		    $g->add_edge( $s->Id, $p->Id );
		    $state->{ edge_class }->{ $s }->{ $p } = "back";
		}
	    } else {
		$state->{ edge_class }->{ $p }->{ $s } = "cross";
	    }
	};

    $g->depth_first( $state );

    my %class;

    foreach my $e ( $g->edges ) {
	my ( $p, $s ) = $e->vertices;
	my $c = $state->{ edge_class }->{ $p }->{ $s };
	if ( defined $c ) {
	    $e->Class( $c );
	    push( @{ $class{ $c } }, $e );
	}
    }

    return \%class;
}

# cyclic($graph)
#   Returns true if the graph is cyclic (has back edges).
#

sub cyclic {
    my $g = shift;

    my $class = $g->classify_edges;

    return exists $class->{ back };
}

# dag($graph)
#   Returns true if the graph is directed and acyclic.
#

sub dag {
    my $g = shift;
    
    # Directed and a-cyclic.
    return $g->directed && not $g->cyclic;
}

# connected($graph)
#   Returns true if the graph is connected (has multiple roots,
#   a depth-first forest).  A meaningful question only for
#   undirected graphs.
#

sub connected {
    my $g = shift;
    
    $g->_make_undirected_sense( "Being connected" );

    my $state = { };

    my @v = $g->vertices;
    my $v = shift @v;

    for my $u ( @v ) {
	# If not in same union-tree component, give up.
	return 0 unless $g->find( $u, $v );
    }

    return 1;
}

# transpose_graph($graph)
#   Returns the transpose of the graph.
#

sub transpose_graph {
    my $g = shift;

    $g->_make_directed_sense( "transpose" );

    my $t = ( ref $g )->new;

    foreach my $e ( $g->edges ) {
	# Reverse every edge.
	$t->add_edge( reverse $e->vertex_Ids );
    }

    return $t;
}

# complete_graph($graph)
#   Returns the complete graph of the graph.
#

sub complete_graph {
    my $g = shift;

    my $c = ( ref $g )->new;

    my @V = $g->vertices;

    foreach my $p ( @V ) {
	foreach my $s ( @V ) {
	    # Add every possible edge...
	    $c->add_edge( $p->Id, $s->Id )
		# ...except selfloops.
		unless $p eq $s;
	}
    }

    return $c;
}

# complement_graph($graph)
#   Returns the complement graph of the graph.
#

sub complement_graph {
    my $g = shift;

    my $c = $g->complete_graph;

    foreach my $e ( $g->edges ) {
	# Delete every edge present in the original.
	$c->delete_edge( $e->vertex_Ids );
    }

    return $c;
}

# depth_first_forest($graph, $state)
#   Returns the depth-first forest of the graph.
#   The $state can be used to filter out certain vertices.
#

sub depth_first_forest {
    my ( $g, $state ) = @_;

    $state = { } unless defined $state;

    my $f = ( ref $g )->new;

    $g->classify_edges( $state );

    foreach my $e ( $g->edges ) {
	if ( defined $e->Class and $e->Class eq "tree" ) {
	    $f->add_edge( $e->vertex_Ids );
	}
    }

    return $f;
}

# topo_sort($graph, $state)
#   Returns the topological sort of the vertices of the graph.
#   The $state can be used to filter out certain vertices.
#

sub topo_sort {
    my ( $g, $state ) = @_;

    $state = { } unless defined $state;

    $g->depth_first( $state );

    # A Schwartzian Transform.
    return map { $_->[ 0 ] }
               sort { $b->[ 1 ] <=> $a->[ 1 ] } # Note: $b $a
                    map { [ $_, $state->{ done }->{ $_ } ] }
                        $g->vertices;
}

# add_attributed_edge($graph, $attribute_name, $vertex,
#                     $attribute_value, $other_vertex)
#   Sets the $attribute_name of the edge defined by
#   the vertices in the graph to the $attribute_value.
#

sub add_attributed_edge {
    my ( $g, $a, $p, $w, $s ) = @_;

    $g->add_edge( $p->Id, $s->Id );
    $g->edges( $p, $s )->$a( $w );
}

# add_attributed_path($graph, $attribute_name,
#                     @vertices_and_attribute_values)
#   Sets the attributed path: a bulk version of add_attributed_edge.
#

sub add_attributed_path {
    my $g = shift;
    my $a = shift; # The attribute name.

    # The path vertices: every even element of @_.
    my @pv = @_[ map { 2 * $_     } 0..( $#_ / 2     ) ];

    # The attributes: every odd element of @_.
    my @a  = @_[ map { 2 * $_ + 1 } 0..( $#_ / 2 - 1 ) ];

    # The path vertices as edge vertices.
    my @ev = _path_to_edge( \@pv );

    # Add them edges.
    $g->add_edge( @ev );

    # Add the attributes to the edges.

    my $e;
    
    foreach $e ( $g->edges( @ev ) ) {
	$e->$a( shift @a );
    }
}

# add_Weight_edge($graph, $vertex, $weight, $other_vertex)
#   Sets the Weight attribute of the edge defined by
#   the vertices to the $weight.
#

sub add_Weight_edge {
    my ( $g, $p, $w, $s ) = @_;

    $g->add_attributed_edge( 'Weight', $p, $w, $s );
}

# add_Weight_path($graph, @vertices_and_Weights)
#   Sets the Weight attribute of the path defined by
#   the vertices to the weights.
#

sub add_Weight_path {
    my $g = shift;

    $g->add_attributed_path( 'Weight', @_ );
}

# _depth_first_visit($graph, $vertex, $state)
#   The actual recursive workhorse of the DFS.
#   Visits the vertex, recursively visits the
#   successors (chosen and sorted by _walk_successors())
#   recursively, and calls all the edge-related hooks.
#

sub _depth_first_visit {
    my ( $g, $v, $state ) = @_;

    my $edge_hook        = $state->{ edge_hook        };
    my $edge_unseen_hook = $state->{ edge_unseen_hook };
    my $edge_seen_hook   = $state->{ edge_seen_hook   };

    # Something to do for each vertex?
    $state->{ vertex_hook }->( $v, $state )
	if defined $state->{ vertex_hook };

    foreach my $s ( $g->_walk_successors( $v, $state ) ) {
		    
	# Something to do for each edge?
	$edge_hook->( $v, $state )
	    if defined $edge_hook;

	if ( exists $state->{ unseen }->{ $s } ) {
			
	    # Something to do for each unseen edge?
	    $edge_unseen_hook->( $v, $s, $state )
		if defined $edge_unseen_hook;
			
	    $g->_depth_first_visit( $s, $state );
	    
	} else {
			
	    # Something to do for each seen edge?
	    $edge_seen_hook->( $v, $s, $state )
		if defined $edge_seen_hook;
	}
    }

    # Record the finishing time of this vertex.
    $state->{ done }->{ $v } = $state->{ order }++;
}

# depth_first($graph, $state)
#   The frontend of the DFS.
#   Calls the root vertex hooks and
#   calls the real DFS engine at each yet unseen root vertex.
#

sub depth_first {
    my ( $g, $state ) = @_;

    $state = { } unless defined $state;

    $g->_walk_init( $state );

    my @V = $g->vertices;

    # Apply the possible preferred ordering for the
    # wanted starting (aka root) vertices.

    @V = grep { $state->{ root_grep }->( $_    , $state ) } @V
	if exists $state->{ root_grep };

    @V = sort { $state->{ root_sort }->( $a, $b, $state ) } @V
	if exists $state->{ root_sort };

    if ( exists $state->{ root } ) {
	my $v = $g->_find_vertex( $state->{ root } );
	# If the _find_vertex succeeded, move the $v
	# to the front of the root candidates.
	@V = ( $v, grep { $_->Id ne $v->Id } @V );
    }

    my $root_hook = $state->{ root_hook };

    foreach my $v ( @V ) {

	if ( exists $state->{ unseen }->{ $v } ) {

	    push( @{ $state->{ roots } }, $v );

	    $root_hook->( $v, $state )
		if defined $root_hook;

	    $g->_depth_first_visit( $v, $state )
	}

	# If only one tree wanted, not a forest.
	last if $state->{ tree_only };
    }

    return $state;
}


# breadth_first($graph, $state)
#   The BFS.  Implements the whole iterative queue
#   and calls all the relevant hooks.
#

sub breadth_first {
    my ( $g, $state ) = @_;

    $state = { } unless defined $state;

    my $edge_hook        = $state->{ edge_hook        };
    my $edge_unseen_hook = $state->{ edge_unseen_hook };
    my $edge_seen_hook   = $state->{ edge_seen_hook   };

    $g->_walk_init( $state );

    my @V = $g->vertices;

    # Apply the possible preferred ordering for the
    # wanted starting (aka root) vertices.

    @V = grep { $state->{ root_grep }->( $_,     $state ) } @V
	if exists $state->{ root_grep };

    @V = sort { $state->{ root_sort }->( $a, $b, $state ) } @V
	if exists $state->{ root_sort };

    if ( exists $state->{ root } ) {
	my $v = $g->_find_vertex( $state->{ root } );
	# If the _find_vertex succeeded, move the $v
	# to the front of the root candidates.
	@V = ( $v, grep { $_->Id ne $v->Id } @V );
    }

    my $root_hook = $state->{ root_hook };

 TREE:

    foreach my $v ( @V ) {

	if ( exists $state->{ unseen }->{ $v } ) {
	    
	    # Seed the queue: enqueue the root vertex.
	    push( @{ $state->{ todo } }, $v );
    
	    $root_hook->( $v, $state ) if defined $root_hook;

	    push( @{ $state->{ roots } }, $v );

	    while ( @{ $state->{ todo } } ) {
	    
		$v = shift @{ $state->{ todo } };
	    
		if ( exists $state->{ unseen }->{ $v } ) {
		
		    foreach my $s ( $g->_walk_successors( $v, $state ) ) {
				
			$edge_hook->( $v, $s, $state )
			    if defined $edge_hook;
			
			if ( exists $state->{ unseen }->{ $s } ) {
			
			    push( @{ $state->{ todo } }, $s );

			    $edge_unseen_hook->( $v, $s, $state )
				if defined $edge_unseen_hook;
			
			} else {
			
			    $edge_seen_hook->( $v, $s, $state )
				if defined $edge_unseen_hook;
			}
		    }
		}
	    }

	    # If only one tree wanted, not a forest.
	    last TREE if $state->{ tree_only };
	}
    }	
    
    return $state;
}


# MST_kruskal($graphg)
#   Returns the Kruskal MST.
#   Makes sense only for undirected graphs.
#

sub MST_kruskal {
    my $g = shift;

    $g->_make_undirected_sense( "minimum spanning tree" );

    my $mst = ( ref $g )->new; # The minimum spanning tree.

    $mst->undirected( 1 );

    my @e  = $g->edges;

    # The weighted edges.
    my @we = map { [ $_, $_->Weight ] } @e;

    # Walk the edges in the order of increasing weight.
    foreach my $we ( sort { $a->[ 1 ] <=> $b->[ 1 ] } @we ) {
	my ( $p, $s ) = ( $we->[ 0 ]->P, $we->[ 0 ]->S );
	# Add edge only iff no cycle imminent.
	unless ( $mst->find( $p, $s ) ) {
	    $mst->add_edge( $p->Id, $s->Id );
	    $mst->edges( $p->Id, $s->Id )->Weight( $we->[ 1 ] );
	}
    }

    return $mst;
}

# MST_prim($graph, $start_vertex)
#   Returns the Prim MST, possibly starting from a vertex
#   (if none specified, a good candidate is chosen).
#   Makes sense only for undirected graphs.
#

sub MST_prim {
    my ( $g, $v ) = @_;

    $g->_make_undirected_sense( "minimum spanning tree" );

    use Heap::Fibonacci;

    my $heap = Heap::Fibonacci->new;

    # If no start vertex defined pick a vertex next to
    # a short/light edge to start with.
    $v = ( sort { $a->Weight <=> $b->Weight } $g->edges )[ 0 ]->P
	unless defined $v;

    # Verify the vertex.
    $v = $g->_find_vertex( $v );

    my ( %seen, %tree, $hpv, $hps );

    use Graph::_heapval;

    # Start a new heap.
    $hpv = Graph::_heapval->new( $heap, \%seen, 0, $v );

    while ( defined $heap->minimum ) {
	$hpv = $heap->extract_minimum;
	$v = $hpv->vertex;
	foreach my $s ( $v->successors ) {
	    my $w = $g->edges( $v, $s )->Weight;
	    unless ( exists $seen{ $s } ) {
		$hps = Graph::_heapval->new( $heap, \%seen, $w, $s );
		$tree{ $s } = $v;
	    } else {
		$hps = $seen{ $s };
		if ( $w < $hps->val ) {
		    $hps->val( $w );
		    $heap->decrease_key( $hps );
		    $tree{ $s } = $v;
		}
	    }
	}
    }

    my $mst = ( ref $g )->new;

    $mst->undirected( 1 );

    foreach my $s ( $g->vertices ) {
	$mst->add_edge( $tree{ $s }->Id, $s->Id )
	    if defined $tree{ $s };
    }

    return $mst;
}

# strongly_connected_components($graph, $state)
#   Returns the strongly connected components of the graph.
#   The components are returned as a list of new vertices
#   whose names are formed by joining the names of the
#   constituent vertices by underlines: for example if
#   the vertices a b c form a strongly connected component,
#   a new component would be a_b_c.
#   Makes sense only for directed graphs.
#   The $state can be used to filter out certain vertices.
#

sub strongly_connected_components {
    my ( $g, $state ) = @_;
    
    $g->_make_directed_sense( "strong connectivity" );

    $state = { } unless defined $state;

    $g->depth_first( $state );

    my %done = %{ $state->{ done } };

    my $t  = $g->transpose_graph;

    # Reset the state for $t.

    $state = { };

    $state->{ successor_sort } =
	sub {
	    my ( $a, $b ) = @_;
			 
	    $done{ $a } <=> $done{ $b };
	};
	
    $t->depth_first( $state );

    my ( $sct, @sct, %sct, %scf, @scc, $scc );

    foreach my $root ( @{ $state->{ roots } } ) {

	# Grow the strongly-connected tree.
	$sct =
	    $t->depth_first_forest
		( {
		   root_sort => sub {
		       my ( $a, $b ) = @_;
		       
		       return -1 if $a eq $root;
		       return  1 if $b eq $root;

		       return $a->Id cmp $b->Id;
		   },
		   tree_only => 1     
		  } );

	# Delete from the %sct the vertices already in %scf.
	@sct = $sct->vertices;
	@sct{ @sct } = @sct;

	# In Perl 5.004 and newer,
	# delete @sct{ keys %scf } is fine.
	foreach my $v ( keys %scf ) {
	    delete $sct{ $v };
	}

	# Now we have just the `new' tree.
	@sct = keys %sct;
	@scf{ @sct } = @sct;

	# Make a new graph and add this new tree to it.
	$scc = ( ref $g )->new;
	$scc->add_vertex( @sct );

	# Stash for return.
	push( @scc, $scc );
    }

    return @scc;
}

# strongly_connected_component_graph($graph)
#   Return the strongly connected component graph of
#   the original graph.  The names of the new vertices
#   are as described in strongly_connected_components()
#   and the edges will be between those vertices.
#   Makes sense only for directed graphs.
#   The $state can be used to filter out certain vertices.
#

sub strongly_connected_component_graph {
    my ( $g, $state ) = @_;
    
    $g->_make_directed_sense( "strong connectivity" );

    $state = { } unless defined $state;

    my $scc = ( ref $g )->new;
    my @scc = $g->strongly_connected_components( $state );

    my ( %scc_v2i, @scc_i2sv, %scc_e );

    foreach my $v ( $g->vertices ) {

	my $component;

	for ( my $i = 0; $i < @scc; $i++ ) {
	    $component = $i;
	    last if grep { $v eq $_ } $scc[ $i ]->vertices;
	}

	$scc_v2i{ $v } = $component;

	unless ( defined $scc_i2sv[ $component ] ) {
	    my $sv = "(" . $scc[ $component ] . ")";
	    $scc->add_vertex( $sv );
	    $scc_i2sv[ $component ] = $scc->vertices( $sv );
	}
    }

    foreach my $e ( $g->edges ) {
	my ( $p, $s ) = $e->vertices;
	unless ( $scc_v2i{ $p } == $scc_v2i{ $s } ) {
	    unless ( $scc_e{ $scc_v2i{ $p } }->{ $scc_v2i{ $s } } ) {
		$scc_e{ $scc_v2i{ $p } }->{ $scc_v2i{ $s } } = 1;
		$scc->add_edge(
		    $scc_i2sv[ $scc_v2i{ $p } ],
		    $scc_i2sv[ $scc_v2i{ $s } ]
			      );
	    }
	}
    }

    return $scc;
}


# _articulation_points_visit($graph, $vertex, $root_vertex, $state)
#   A private helper method.
#   The recursive part of finding the articulation points.
#   Makes sense only for undirected graphs.
#

sub _articulation_points_visit {
    my ( $g, $v, $r, $state ) = @_;

    my $min = $state->{ id }++;

    $state->{ min }->{ $v } = $state->{ val }->{ $v } = $min;

    foreach my $s ( $v->successors ) {

	if ( exists $state->{ min }->{ $s } ) {

	    $min = $state->{ min }->{ $s }
	        if $state->{ min }->{ $s } < $min;

	    $state->{ back }->{ $s }++;

	} else {

	    # Descend looking for a better minimum.
	    my $try = $g->_articulation_points_visit( $s, $r, $state );

	    $min = $try if $try < $min;

	    if ( $try >= $state->{ val }->{ $v } ) {

		# If this is a root vertex for the second time or
		# this is a non-root vertex.
		if ( ( exists $state->{ root }->{ $v } and
		       ++$state->{ root }->{ $v } == 2 )
		     or
		     $try > $state->{ val }->{ $r } ) {
		    $state->{ articulation_points }->{ $v } = $v;
		}
	    }
	}
    }

    $state->{ min }->{ $v } = $min;

    return $min;
}

# articulation_points($graph)
#   Returns the articulation points (vertices) of the graph.
#   Makes sense only for undirected graphs.
#

sub articulation_points {
    my $g = shift;

    $g->_make_undirected_sense( "biconnectivity" );

    my $state = { };

    foreach my $v ( $g->vertices ) {
	unless ( exists $state->{ min }->{ $v } ) {
	    $state->{ root }->{ $v } = 0;
	    $g->_articulation_points_visit( $v, $v, $state );
	}
    }

    return values %{ $state->{ articulation_points } };
}

# biconnected($grah)
#   Returns true if the graph is biconnected (has no articulation points).
#   Makes sense only for undirected graphs.
#   The $state can be used to filter out certain vertices.
#

sub biconnected {
    my $g = shift;

    $g->_make_undirected_sense( "biconnectivity" );

    return ( $g->articulation_points ) == 0;
}

# bridges()
#   Returns the bridges (edges) of the graph (none for a biconnected one).
#   Makes sense only for undirected graphs.
#

sub bridges {
    my $g = shift;

    $g->_make_undirected_sense( "biconnectivity (bridges)" );

    my @V = $g->vertices;
    my $state = { };

    my @av = $g->articulation_points;
    my @sv = $g->sink_vertices;

    my %bv;		# The bridge vertices.

    @bv{ @av } = @av;	# A bridge connects articulation vertices...
    @bv{ @sv } = @sv;	# ...or sink vertices.

    my @bridges;	# The result.

    foreach my $e ( $g->edges ) {
	my ( $p, $s ) = $e->vertices;

	# If both ends are bridge vertices, we have a bridge.
	push( @bridges, $e )
	    if exists $bv{ $p->Id } and exists $bv{ $s->Id };
    }

    return @bridges;
}

# biconnected_components($graph)
#   Returns the biconnected components of the graph
#   as list of of smaller graphs.
#   Makes sense only for undirected graphs.
#

sub biconnected_components {
    my $g = shift;

    $g->_make_undirected_sense( "biconnectivity" );

    my $b = ( ref $g )->new;

    $b->undirected( 1 );

    # First make a copy of the original graph
    # but leave only the vertices and edges that
    # can belong to biconnected components.

    $b->merge_edges( $g );

    # Delete the bridges.
    foreach my $e ( $g->bridges ) {
	$b->delete_edge( $e->vertex_Ids );
    }

    # Delete the now unconnected (deleting bridges
    # above may have disconnected some) vertices.
    foreach my $v ( $b->unconnected_vertices ) {
	$b->delete_vertex( $v->Id );
    }

    my @v = $b->vertices;
    my @a = $b->articulation_points;

    my ( %a, %id);

    @a{ @a } = @a;	# Hash for easier access.

    my $id = 0;	        # The biconnected component id.

    my $state = { };

    $state->{ root_grep } =
	sub {
	    my ( $v ) = @_;

	    # Must not be an articulation point nor
	    # a singly-connected sink or source nor
	    # unconnected.
	    return ( exists $a{ $v } or $v->In + $v->Out < 2 ) ? 0 : 1;
	};

    $state->{ successor_grep } =
	sub {
	    my ( $v, $s, ) = @_;

	    # Must not be an articulation point.
	    return exists $a{ $v } ? 0 : 1;
	};

    $state->{ root_hook } =
	sub {
	    my ( $v, $state ) = @_;

	    $id++;
	};

    $state->{ edge_hook } =
	sub {
	    my ( $p, $s, $state ) = @_;

	    # Label both the vertices: the p...
	    if ( defined $p->Bcc ) { # No, not Blind-carbon-copy...
		$p->Bcc->{ $id } = $id;
	    } else {
		$p->Bcc( { $id, $id } );
	    }

	    # ...and the s.
	    if ( defined $s->Bcc ) {
		$s->Bcc->{ $id } = $id;
	    } else {
		$s->Bcc( { $id, $id } );
	    }
	};

    $b->breadth_first( $state );

    my ( %p, %s );	# The labels for each vertex end.
    my @bcc;		# The returned biconnected components.
    my @nv;		# Per-edge vertex counter.

    foreach my $e ( $b->edges ) {
	my ( $p, $s ) = $e->vertices;
	if ( defined $p->Bcc and defined $s->Bcc ) {
	    %p = %{ $p->Bcc };
	    %s = %{ $s->Bcc };

	    @nv = ( );	# Reset the counters.

	    foreach my $i ( keys %p ) {
		$nv[ $i ] += 2; # Both ends of an edge == two ends.
	    }

	    foreach my $i ( 0..$#nv ) {
		# If both ends (two of them) of this edge
		# are in this ($i) component, add them to
		# the corresponding biconnected component.
		if ( defined $nv[ $i ] and $nv[ $i ] == 2 ) {
		    unless ( defined $bcc[ $i ] ) {
			$bcc[ $i ] = ( ref $b )->new;
			$bcc[ $i ]->undirected( 1);
		    }
		    $bcc[ $i ]->add_edge( $p->Id, $s->Id );
		}
	    }
	}
    }

    shift @bcc;	# The first element is always unused.

    return @bcc;
}


# _SSSP_relax($graph,
#             $vertex, $weight_at_vertex,
#	      $weight,
#             $other_vertex, $weight_at_other_vertex)
#   A private helper method, used by SSSP_dijkstra and SSSP_bellman_ford.
#   Returns either the new relaxed value or undef.
#   Makes sense only for directed graphs.
#

sub _SSSP_relax {
    my ( $g, $p, $pval, $w, $s, $sval ) = @_;

    # If the start vertex is undefined (== infinite)
    # it cannot be smaller than the end vertex + weight.
    return undef unless defined $pval;

    # Weight at the end vertex of an edge equals
    # the weight of the edge plus the weight at
    # the start vertex.
    $w += $pval;

    return $w # Houston, we have a relaxation.
	if not defined $sval or $sval > $w;

    return undef;
}

# SSSP_dijkstra($graph, $starte_vertex)
#   Returns the Dijkstra SSSP as a graph.
#   More specifically: returns a graph that has the single-source
#   shortest paths as edges, and the path lengths to the end vertex
#   as Weight attributes.
#   Makes sense only for directed graphs.
#

sub SSSP_dijkstra {
    my ( $g, $v ) = @_;

    $g->_make_directed_sense( "single-source shortest path" );

    use Heap::Fibonacci;

    my $heap = Heap::Fibonacci->new;

    # If no start vertex defined pick a vertex next to
    # a short edge to start with.
    $v = ( sort { $a->Weight <=> $b->Weight } $g->edges )[ 0 ]->P
	unless defined $v;

    # Verify the vertex.
    $v = $g->_find_vertex( $v );

    my ( %seen, $hpv, $hps, $relax, %path, %dist );

    $hpv = Graph::_heapval->new( $heap, \%seen, 0, $v );

    while ( defined ( $hpv = $heap->extract_minimum ) ) {
	$v = $hpv->vertex;
	foreach my $s ( $v->successors ) {
	    my $w = $g->edges( $v, $s )->Weight;
	    if ( $w < 0 ) {
		warn "SSSP_dijkstra: edge $v -> $s negative.\n";
		die  "use of SSSP_bellman_ford suggested.\n";
	    } elsif ( $w == 0 ) {
		warn "SSSP_dijkstra: edge $v -> $s weightless.\n";
		warn "the vertices $v and $s could be combined.\n";
	    }
	    unless ( exists $seen{ $s } ) {
		$hps = Graph::_heapval->new( $heap, \%seen, undef, $s );
		$path{ $s } = $v;
	    } else {
		$hps = $seen{ $s };
	    }
	    $relax = $g->_SSSP_relax( $v, $hpv->val,
				      $w,
				      $s, $hps->val );
	    if ( defined $relax ) {
		$hps->val( $relax );
		$heap->decrease_key( $hps );
		$dist{ $s } = $hps->val;
		$path{ $s } = $v;
	    }
	}
    }

    # Build the SSSP.

    my $sssp = ( ref $g )->new;

    foreach $v ( $g->vertices ) {
	# For all except the root vertex.
	$sssp->add_Weight_edge( $path{ $v }, $dist{ $v }, $v )
	    if defined $path{ $v };
    }

    return $sssp;
}

# SSSP_bellman_ford($graph, $start_vertex)
#   Returns the Bellman-Ford SSSP as a graph.
#   More specifically: returns a graph that has the single-source
#   shortest paths as edges, and the path lengths to the end vertex
#   as the Weight attributes.
#   The start vertex must be given.
#   Makes sense only for directed graphs.
#

sub SSSP_bellman_ford {
    my ( $g, $v ) = @_;

    unless ( defined $v ) {
	warn "SSSP_bellman_ford: source vertex must be given.\n";
	confess "Died";
    }

    $g->_make_directed_sense( "single-source shortest path" );

    my ( %dist, %path );

    # Verify the vertex.
    $v = $g->_find_vertex( $v );

    # Start vertex starts first.
    $dist{ $v } = 0;

    my @V = $g->vertices;
    my $V = @V;

    # Relax all edges |V| - 1 times (NOT |V| times)
    for ( my $i = 1; $i < $V; $i++ ) {
	foreach my $e ( $g->edges ) {
	    my ( $p, $s ) = $e->vertices;
	    my $w = $g->edges( $p, $s )->Weight;
	    if ( $w == 0 ) {
		warn "SSSP_bellman_ford: edge $p -> $s weightless.\n";
		warn "the vertices $p and $s could be combined.\n";
	    }
	    my $relax = $g->_SSSP_relax( $p, $dist{ $p },
					 $w,
					 $s, $dist{ $s } );
	    if ( defined $relax ) {
		$dist{ $s } = $relax;
		$path{ $s } = $p;
	    }	    
	}
    }

    # Check for negative cycles.
    foreach my $e ( $g->edges ) {
	my ( $p, $s ) = $e->vertices;
	my $w = $g->edges( $p, $s )->Weight;
	if ( defined $path{ $s } and
	     $path{ $s } eq $p   and
	     $dist{ $s } > $dist{ $p } + $w ) {
	    warn "SSSP_bellman_ford: edge $p -> $s in negative cycle.\n";
	    warn "SSSP_bellman_ford: ($dist{$s} > $dist{$p} + $w)\n";
	}
    }

    # Build the SSSP.

    my $sssp = ( ref $g )->new;

    foreach $v ( $g->vertices ) {
	# For all except the root vertex.
	$sssp->add_Weight_edge( $path{ $v }, $dist{ $v }, $v )
	    if defined $path{ $v };
    }

    return $sssp;
}

# SSSP_dag($dag, $start_vertex)
#   Returns the DAG SSSP as a graph.
#   More specifically: returns a graph that has the single-source
#   shortest paths as edges, and the path lengths to the end vertex
#   as the Weight attributes.
#   The start vertex must be given.
#   Makes sense only for directed graphs.
#

sub SSSP_dag {
    my ( $g, $v ) = @_;

    $g->_make_directed_sense( "single-source shortest path" );

    unless ( defined $v ) {
	warn "SSSP_dag: source vertex must be given.\n";
	confess "Died";
    }

    my ( %dist, %path );

    if ( defined $v ) { # If a start vertex was given.
	# Verify the vertex.
	$v = $g->vertices( $v ) unless ref $v;

	# Start vertex starts first.
	$dist{ $v } = 0;
    }

    foreach $v ( $g->topo_sort ) {
	foreach my $s ( $v->successors ) {
	    my $w = $g->edges( $v, $s )->Weight;
	    if ( $w == 0 ) {
		warn "SSSP_dag: edge $v -> $s weightless.\n";
		warn "the vertices $v and $s could be combined.\n";
	    }
	    my $relax = $g->_SSSP_relax( $v, $dist{ $v },
					 $w,
					 $s, $dist{ $s } );
	    if ( defined $relax ) {
		$dist{ $s } = $relax;
		$path{ $s } = $v;
	    }	    
	}
    }

    # Build the SSSP.

    my $sssp = ( ref $g )->new;

    foreach $v ( $g->vertices ) {
	# For all except the root vertex.
	$sssp->add_Weight_edge( $path{ $v }, $dist{ $v }, $v  )
	    if defined $path{ $v };
    }

    return $sssp;
}

# APSP_floyd_warshall($graph)
#   Returns the Floyd-Warshall all-pairs shortest paths as a graph.
#   More specifically: in the returned graph every possible (path-connected)
#   pair is an edge.  Each edge has two attributes: Weight, which is the
#   length of the minimal path, and Prev, which is the second to last
#   vertex on the minimal path.  Example:  If there is a path from
#   vertex 'a' to vertex 'f', the edge 'a-f' has the attributes Weight,
#   for example 6, and Prev, for example 'd', which means that the
#   last edge of the minimal path from 'a' to 'f' is 'd-f'.  To trace
#   the path backwards, see the edge 'a-d'.  Sounds good but there is
#   a catch: if there is a negative cycle in the path the Prev attributes
#   point along this negative cycle and there is no way to break out of it
#   back to the original minimal path.
#

sub APSP_floyd_warshall {
    my $g = shift;

    my @V = $g->vertices;
    my $V = @V;

    my ( $v, %v2i, @i2v,
	 $i, $j, $k,
	 $e, $p, $s,
	 $dist, $prev_dist,
	 $path, $prev_path,
	 $prev_dist_ij, $prev_dist_ikpkj,
	 $prev_path_ij, $prev_path_kj
       );

    foreach $v ( $g->vertices ) {
	$v2i{ $v } = $i++;	# Number the vertices.
	$i2v[ $v2i{ $v } ] = $v;
    }

    # The distance matrix diagonal is naturally zero.
    # (and the path matrix diagonal is implicitly undefs).
    foreach $v ( $g->vertices ) {
	$i = $v2i{ $v };
	$dist->[ $i ]->[ $i ] = 0;
    }

    # The rest of the distance matrix are the Weights
    # and the rest of the path matrix are the parent vertices.
    foreach $e ( $g->edges ) {
	( $p, $s ) = $e->vertices;
	$i = $v2i{ $p };
	$j = $v2i{ $s };
	$dist->[ $i ]->[ $j ] = $g->edges( $p, $s )->Weight;
	$path->[ $i ]->[ $j ] = $p;
    }

    # O($V**3) quite obviously: three loops till $V.

    for ( $k = 0; $k < $V; $k++ ) {

	$prev_dist = $dist;	# Save and...
	$dist      = [ ];	# ...reset.

	$prev_path = $path;	# Save and...
	$path      = [ ];	# ...reset.

	for ( $i = 0; $i < $V; $i++ ) {
	    for ( $j = 0; $j < $V; $j++ ) {

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

    my $apsp = ( ref $g )->new;

    for ( $i = 0; $i < $V; $i++ ) {
	$p = $i2v[ $i ];
	for ( $j = 0; $j < $V; $j++ ) {
	    $s = $i2v[ $j ];
	    $apsp->add_Weight_edge( $p, $dist->[ $i ]->[ $j ], $s );
	    $apsp->add_attributed_edge( 'Prev',
					$p, $path->[ $i ]->[ $j ], $s );
	}
    }

    return $apsp;
}

# transitive_closure($graph)
#   Returns the transitive closure of the graph.
#   The closure is returned as a graph that has an edge from vertex
#   u to vertex v if there is a path from u to v in the original graph.
#

sub transitive_closure {
    my $g = shift;

    my @V = $g->vertices;
    my $V = @V;

    my ( $v, %v2i, @i2v,
	 $i, $j, $k,
	 $e, $p, $s,
	 $closure_matrix,
	 $prev_closure_matrix,
	 $prev_closure_ij,
	 $prev_closure_jk,
	 $prev_closure_kj
       );

    foreach $v ( $g->vertices ) {
	$v2i{ $v } = $i++;	# Number the vertices.
	$i2v[ $v2i{ $v } ] = $v;
    }

    # Initialize the closure matrix to zeros.
    for ( $i = 0; $i < $V; $i++ ) {
	$closure_matrix->[ $i ] = [ ( 0 ) x $V ];
    }

    # The closure matrix diagonal is naturally one.
    foreach $v ( $g->vertices ) {
	$i = $v2i{ $v };
	$closure_matrix->[ $i ]->[ $i ] = 1;
    }

    # Also the edges are ones.
    foreach $e ( $g->edges ) {
	( $p, $s ) = $e->vertices;
	$i = $v2i{ $p };
	$j = $v2i{ $s };
	$closure_matrix->[ $i ]->[ $j ] = 1;
    }

    # O($V**3) quite obviously: three loops till $V.

    for ( $k = 0; $k < $V; $k++ ) {

	$prev_closure_matrix = $closure_matrix;	# Save and...
	$closure_matrix      = [ ];	        # ...reset.

	for ( $i = 0; $i < $V; $i++ ) {
	    for ( $j = 0; $j < $V; $j++ ) {

		$closure_matrix->[ $i ]->[ $j ] =
		    $prev_closure_matrix->[ $i ]->[ $j ] |
		    ( $prev_closure_matrix->[ $i ]->[ $k ] &
		      $prev_closure_matrix->[ $k ]->[ $j ] );
	    }
	}
    }

    # Map the closure matrix into a closure graph.

    my $closure_graph = ( ref $g )->new;

    for ( $i = 0; $i < $V; $i++ ) {
	for ( $j = 0; $j < $V; $j++ ) {
	    if ( $closure_matrix->[ $i ]->[ $j ] ) {
		$closure_graph->add_edge( $i2v[ $i ], $i2v[ $j ] );
	    }
	}
    }

    return $closure_graph;
}

# add_Capacity_edge($graph, $vertex, $capacity, $other_vertex)
#   Sets the Capacity attribute of the edge defined by
#   the vertices to be $w.
#

sub add_Capacity_edge {
    my ( $g, $p, $w, $s ) = @_;

    $g->add_attributed_edge( 'Capacity', $p, $w, $s );
}

# add_Capacity_path($graph, @vertices_and_Capacities)
#   Sets the Capacity attribute of the pathedge defined by
#   the vertices to be Capacities.
#

sub add_Capacity_path {
    my $g = shift;

    $g->add_attributed_path( 'Capacity', @_ );
}

# flow_ford_fulkerson($graph, $state)
#   The Ford-Fulkerson method/framework for solving network
#   flow problems.  Three things MUST be defined in the $state:
#   the source vertex, the sink vertex, and the next_path hook.
#   Returns the maximal flow network as a graph.  The flows
#   at each edge $e can be retrieved by $e->Flow.
#   Does all the work of finding the minimal residual
#   capacity of each potential augmenting path returned
#   by the next_state hook; the hook only needs to return
#   the next potential path.
#   Makes sense only for directed graphs.
#

sub flow_ford_fulkerson {
    my ( $g, $state ) = @_;

    $g->_make_directed_sense( "single-source shortest path" );

    my $source = $state->{ source };

    unless ( defined $source ) {
	warn "ford_fulkerson: source vertex undefined.\n";
	confess "Died";
    }

    my $sink   = $state->{ sink };

    unless ( defined $sink ) {
	warn "ford_fulkerson: sink vertex undefined.\n";
	confess "Died";
    }

    my $next_path = $state->{ next_path };

    unless ( defined $next_path ) {
	warn "ford_fulkerson: next_path hook undefined.\n";
	confess "Died";
    }

    my $flow = ( ref $g )->new;

    # Copy the edges to the flow.
    $flow->merge_edges( $g );

    # Copy the Capacities and zero the Flows.
    foreach my $e ( $g->edges ) {
	my $c = $e->Capacity;
	unless ( $c ) {
	    warn <<EOW;
ford_fulkerson: edge $e
of graph $g
has no defined Capacity.
EOW
            confess "Died";
	}
	# Now copy the Capacity to the flow graph...
	$e = $flow->edges( $e->vertex_Ids );
	$e->Capacity( $c );
	# ...and zero the flow.
	$e->Flow( 0 );
    }
    
    # Update the source and the sink to point to the flow.

    $state->{ source } = $flow->vertices( $source->Id );
    $state->{ sink   } = $flow->vertices( $sink  ->Id );

    my $ap;	# Augmenting path.

    while ( defined ( $ap = $next_path->( $flow, $g, $state ) ) ) {
	if ( @{ $ap } > 1 ) { # == 1: source == sink ?

	    # Augmenting Path Edges.
	    my @ape = $flow->edges( _path_to_edge( $ap ) );

	    # Residual Capacity Candidate.
	    my $rcc = $ape[ 0 ]->Capacity - $ape[ 0 ]->Flow;
	    # Residual Capacity.
	    my $rc  = $rcc > 0 ? $rcc : 0;

	    # Find the minimum non-negative residual capacity.
	    for ( my $i = 1; $i < @ape; $i++ ) {
		# Residual Capacity Candidate.
		$rcc = $ape[ $i ]->Capacity - $ape[ $i ]->Flow;
		$rc  = $rcc if $rcc >= 0 and $rcc < $rc;
	    }

	    if ( $rc > 0 ) {
		# Augment the path.
		foreach my $e ( @ape ) {
		    $e->Flow( $e->Flow + $rc );
		}
	    }
	}
   }

    return $flow;
}

# flow_edmonds_karp($graph, $vertex, $other_vertex)
#   An application of Ford-Fulkerson framework.
#   The potential augmenting paths are returned by the
#   next_state hook, which is a BFS turned inside out into an iterator.
#

sub flow_edmonds_karp {
    my ( $g, $a, $b ) = @_;

    # Verify the vertices.
    $a = $g->_find_vertex( $a );
    $b = $g->_find_vertex( $b );

    my $state = { };

    $state->{ source } = $a;
    $state->{ sink   } = $b;

    $state->{ next_path } = sub {
	my ( $flow, $g, $state ) = @_;

	my $source = $state->{ source };
	my $sink   = $state->{ sink   };

	# Seed the queue.
	if ( not defined $state->{ todo } ) {
	    # The todo-queue has two parts:
	    # the first element is an anymous hash
	    # holding the vertices seen on this path,
	    # the rest of the elements are the
	    # vertices of the path.
	    push( @{ $state->{ todo } },
		  [ { $source, undef }, $source ] );
	}

	# While the queue empties.

	while ( @{ $state->{ todo } } ) {

	    my $ap = shift @{ $state->{ todo } };

	    my $seen = shift @{ $ap };

	    my $v = $ap->[ -1 ]; # The last one.

	    # If this path reached the sink.
	    if ( $v eq $sink ) {
		return $ap;
	    } else {
		# Make new extended paths.
		foreach my $s ( $v->successors ) {
		    unless ( exists $seen->{ $s } ) {
			my $e = $flow->edges( $v, $s );
			push(
			     @{ $state->{ todo } },
			     [ 
			      # Add this successor to
			      # the seen vertices and..
		              { %{ $seen },
				$s, undef },
			      # ..the path so far and...
			      @{ $ap },
			      # ...this successor.
			      $s ] );
		    }
		}
	    }
	}

	return undef;
    };

    return $g->flow_ford_fulkerson( $state );
}


# TSP_approx_prim($graph)
#   Returns an approximation for the TSP by using the Prim MST.
#   Guaranteed to be no worse than twice the minimal tour.
#

sub TSP_approx_prim {
    my $g = shift;

    my $full_tour = $g->complete_graph;

    $full_tour->undirected( 1 );

    # Copy the coordinates.
    foreach my $v ( $g->vertices ) {
	$full_tour->vertices( $v->Id )->X( $v->X );
	$full_tour->vertices( $v->Id )->Y( $v->Y );
    }

    # Compute the distances.
    foreach my $e ( $full_tour->edges ) {
	my ( $p, $s ) = $e->vertices;
	my $dX = $s->X - $p->X;
	my $dY = $s->Y - $p->Y;
	# No need to take the square root, because
	# if a >= 0 and b >=0 and a > b then
	# also sqrt(a) > sqrt(b).
	# We use the Weight attribute instead of, say, Dist,
	# because MST_prim() uses Weight.
	$e->Weight( $dX * $dX + $dY * $dY );
    }

    my $MST_prim = $full_tour->MST_prim;

    my $state = { };

    $MST_prim->depth_first( $state );

    # Next take the vertex names of the MST in preorder.
    # A Schwartzian Transform.
    my @e = map { $_->[ 0 ]->Id }
                sort { $a->[ 1 ] <=> $b->[ 1 ] }
                     map { [ $_, $state->{ seen }->{ $_ } ] }
                         $g->vertices;

    my $tour = ( ref $g )->new;

    $tour->add_path( @e );
    $tour->add_edge( $e[ 0 ], $e[ -1 ] ); # Complete the tour.

    return $tour;
}

1;
