# -*- Mode: Perl; comment-column: 32 -*-
#
# Copyright (C) 1995, Mats Kindahl. All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# E-mail: matkin@docs.uu.se

package Graph::Directed;

use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

    $VERSION = 0.01;

    @ISA = qw(Exporter);
    @EXPORT = ();

    @EXPORT_OK = qw(&topsort &scc %Visited);
}

use vars @EXPORT_OK;

use Carp;

# Variables local to the package. Used for internal purposes.

# Scratch hash to remember visited nodes, their discovery and
# finishing times. This variable may be exported.
%Visited = ();			


# Scalar containing the current "time". This variable is private to
# the package and not visible outside the package.
my $time;

# Scalar set to a defined non-zero value if there were a cycle in the
# graph, undefined or set to 0 otherwise.
my $cycle_found;

=head1 NAME

Graph::Directed - Perl class for representing directed graphs.

=head1 SYNOPSIS

    use Graph::Directed;

    my $graph = Graph::Directed->new();

    $graph->add(1 => 2, 2 => 3, 3 => 2);

    print join(' ', $graph->topsort());

=head1 DESCRIPTION

This module implements directed graphs and some common algorithms used
on such.

=cut

=head1 CLASS METHODS

Following is a list of class methods available. Class methods affect
the I<entire> class of objects; this in contrast with I<object methods>, 
which only affect the object they are applied to.

=over 4

=item new()

Construct a new graph.

=cut

sub new {
    my $class = shift;
    my $self = {
	FORWARD => +{},		# Forward edges in the graph
	BACKWARD => +{},	# Backward edges in the graph
	
    };

    bless $self,$class;
}

=back

=head1 OBJECT METHODS

For graphs, the following object methods are defined. Object methods
are applied to the objects (in this case the graph). We denote a graph
constructed using new (above) by C<$graph>.

=over 4

=item $graph->add((I<from>, <to>), ...)

Add the edges to the graph. Possibly create new nodes if
needed. Returns GRAPH to allow chained calls.

=cut

sub add {
    my $self = shift;
    my($from, $to);

    while (defined ($from = shift) && defined ($to = shift)) {
	$self->{FORWARD}{$from} = [] 
	    unless exists $self->{FORWARD}{$from};
	$self->{FORWARD}{$to} = [] 
	    unless exists $self->{FORWARD}{$to};
	$self->{BACKWARD}{$from} = [] 
	    unless exists $self->{BACKWARD}{$from};
	$self->{BACKWARD}{$to} = [] 
	    unless exists $self->{BACKWARD}{$to};

	push(@{$self->{FORWARD}{$from}}, $to);
	push(@{$self->{BACKWARD}{$to}}, $from);
    }
    return $self;
}

=item $graph->nodes()

Return the nodes of GRAPH as a list.

=cut

sub nodes {
    my $self = shift;
    return keys %{$self->{FORWARD}};
}

=item $graph->edge(I<from>,I<to>)

Test if the edge I<(from,to)> is in GRAPH.

=cut

sub edge {
    my $self = shift;
    my $from = shift;
    my $to = shift;

    return exists $self->{FORWARD}{$from} && grep($_ eq $to, @{$self->{FORWARD}{$from}});
}

=item $graph->succ(I<node>, ...)

Returns the set of successors to the supplied nodes. Observe that
duplicates may be returned.

=cut

sub succ {
    my $self = shift;
    my @result;

    foreach my $node (@_) {
	push(@result, @{$self->{FORWARD}{$node}});
    }

    return @result;
}

=item $graph->pred(I<node>, ...)

Returns the set of predecessors to the supplied nodes. Observe that
duplicates may be returned.

=cut

sub pred {
    my $self = shift;

    my @result;

    foreach my $node (@_) {
	push(@result, @{$self->{BACKWARD}{$node}});
    }

    return @result;
}

=item $graph->dump()

Emit a ASCII representation of the graph using the Dot format. 

=cut

sub dump {
    my $self = shift;
    my $string = "digraph G {\n";
    my @nodes = $self->nodes();
    $string .= "    /* Nodes */\n    ";
    $string .= join("; ", map { "\"$_\"" } @nodes) . ";";
    $string .= "\n\n    /* Edges */\n";
    foreach my $node (@nodes) {
	foreach my $target (@{$self->{FORWARD}{$node}}) {
	    $string .= "    \"$node\" -> \"$target\";\n";
	}
    }
    $string .= "}\n";
    return $string;
}

=item $graph->reachable_from(I<node>, ...)

Compute the I<forward reachability set> of the list of nodes, i.e. the
states that can be reached from any of the given nodes.

=cut

sub reachable_from {
    my $self = shift;
    my @work_list = @_;
    my %result;

    # All nodes in the list are reachable
    @result{@work_list} = (1) x @work_list;

    while (@work_list) { 
	my @temp = $self->succ(@work_list);
	@work_list = grep(! exists $result{$_}, @temp);
	@result{@temp} = (1) x @temp;
    }
    return keys %result;
}

=back

=head1 EXPORTABLE OBJECT METHODS

Following are exportable object methods, i.e., methods that can be
called either as e.g. C<$graph->scc()> or C<scc($graph)> (the latter
after importing the method).

=over 4

=item scc $graph

Use Tarjan's algorithm to find all strongly connected
components in the graph.

Returns a list of references to lists containing the strongly
connected components.

Since we are using the built-in sort, the time complexity is currently
O(I<e> + I<v> log I<v>), where I<v> is the number of nodes of the
graph and I<e> is the number of edges. This can be reduced to O(I<v> +
I<e>) by using counting sort instead of the built-in sorter.

=cut

# Let's take care of the single quote above, Emacs does not behave.

sub scc {
    my $self = shift;
    my @nodes = $self->nodes();

    # Compute finishing times for all nodes using depth first search.
    $self->dfs_forest(DIRECTION => 'FORWARD', 
		      NODES => \@nodes);

    # Sort the nodes by decreasing finishing times (stored as the
    # second element in @{$Visited{$node}}).
    @nodes = sort { $Visited{$b}[1] <=> $Visited{$a}[1] } @nodes;

    # Compute the depth first search forest by investigating the nodes
    # in decreasing finishing times.
    return $self->dfs_forest(DIRECTION => 'BACKWARD',
			     NODES => [@nodes]);
}

=item topsort $graph

Return a list of nodes topologically sorted with respect to the given
graph. It is implemented as a depth first pass through the graph,
since a topological sorting only exists if the graph is acyclic.

The result if the graph contains a cycle is the undefined value.

The time complexity of the algorithm is O(I<v> + I<e>), where I<v> is
the number of nodes in the graph and I<e> is the number of edges in
the graph.

=cut

# Let's take care of the single quote above, Emacs does not behave.

sub topsort {
    my $self = shift;
    my @nodes = $self->nodes();

    # Compute finishing times for all nodes in the graph using depth
    # first search.
    $self->dfs_forest(DIRECTION => 'FORWARD', NODES => \@nodes);

    if (defined $cycle_found) {
       	return undef;
    } else {
	# Sort the nodes by decreasing finishing times (stored as the
	# second element in @{$Visited{$node}}). This will be a
	# topological sort of the visited nodes.
	return sort { $Visited{$b}[1] <=> $Visited{$a}[1] } @nodes;
    }
}    

=back

=head1 INTERNAL OBJECT METHODS

Following are the internal object methods available in the
package. These are used for implementation of the routines above, but
also available for other uses, if the need should arise.

=over 4

=item $graph->dfs_forest(I<options>)

Compute the depth-first search forest of the graph. Currently there
are two options available:

=over 4

=item DIRECTION => I<direction>

The direction of the search, either C<FORWARD> or C<BACKWARD>.

=item NODES => [I<node1>, ... ]

The nodes to be searched, in the order of investigation. Observe that
this should be a I<reference> to a list.

=back

The forest will be returned as a list of references to lists.  This
method is used by, among other, the algorithm to compute strongly
connected components below.

=cut

sub dfs_forest {
    my $self = shift;
    my %option = @_;
    my $dir = $option{'DIRECTION'};

    croak "Only FORWARD or BACKWARD allowed as direction"
	unless $dir eq "FORWARD" || $dir eq "BACKWARD";

    undef %Visited;
    undef $time;
    undef $cycle_found;

    my @list;			# List of lists of visited nodes.

    foreach my $node (@{$option{'NODES'}}) {
	push(@list, +[dfs($self->{$dir}, $node)])
	    unless exists $Visited{$node};
    }

    return @list;
}

=item dfs(I<adjecency hash>, I<node>)

Perform a depth first search of the tree with root node I<node>,
marking progress in the hash C<%Visited>. Return a list of visited
nodes, in pre-order. Observe that C<%Visited> is not reset prior to
searching, this you have to do yourself.

The hash C<%Visited> will contain references to pairs of integers
where the first number is the discovery time of the node, while
the second number is the finishing time of the node.

=cut

sub dfs {
    my $node = pop;
    my @list = ($node);

    # Mark the discovery time, i.e. the time the node was first
    # discovered in the search.
    $Visited{$node} = +[ ++$time ];

    foreach my $succ (@{$_[0]->{$node}}) {
	push(@_,$succ);
	if (exists $Visited{$succ}) {
	    $cycle_found++;	# We found a cycle!
	} else {
	    push(@list, &dfs);
	}
    }

    # Mark the finishing time, i.e. the time when all successor nodes
    # to the current node were visited.
    push(@{$Visited{$node}}, ++$time);

    return @list;
}

=head1 NOTES

This version of the package is only a draft version. The final version
will have a better structure and separation between the graph
internals, the available output formats, and the different graph
algorithms.

There is also a package written by Neil Bowers from the Canon Research
Center and a package written by Jarkko Hietaniemi. Although the
package by Jarkko has a topological sort, the computation of
I<strongly connected components>, as well as I<forward reachability>
are missing in the packages (not a big deal, they can be added).

This package is acually the result of me needing exactly these
algorithms for other work. The package was written prior to the
distribution of packages by Neil and Jarkko, which is why the work was
not based on any of those.

=head1 COPYRIGHT

Copyright 1998 Mats Kindahl. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
