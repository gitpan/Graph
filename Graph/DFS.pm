package Graph::DFS;

# $Id: DF.pm,v 1.1 1998/06/29 22:48:05 jhi Exp jhi $

use strict;
local($^W) = 1;

=pod

=head1 NAME

Graph::DFS - a base class for depth-first graph traversal

=head1 SYNOPSIS

    use Graph;

    my $graph = Graph->new;

    # ... fill $graph ...

    use Graph::DFS;

    $df = Graph::DFS->new( { ... } );

    # Either...

    $df->( $graph ); # process all of it

    # ...or

    while ( $vertex = $df->( $graph ) )  {
        # do something about the $vertex ...
    }

=head1 DESCRIPTION

This class contains various methods for graph depth-first traversal,
applicable by the C<Graph> class.

Currently only one method is defined: the constructor B<new>.

=head2 CONSTRUCTOR

The constructor B<new> compiles a state machine that knows how to walk
C<Graph>s using depth-first traversal.  The state machine is returned
as an anonymous subroutine.

You can (and you probably will want to) pass parameters to the
compilation of the state machine.  You can walk the graph
either in single steps or iteratively.

For example to print out all the vertices of the graph you can use
either:

    $df = Graph::DFS->
              new( { for_vertex => sub { my $vertex = shift;
                                            print "vertex = $vertex\n" } } );

    $df->( $graph );

or

    $df = Graph::DFS->
              new( { return_vertex => 1 } );

    while( $vertex = $df->( $graph ) ) {
        print "vertex = $vertex\n"
    }

C<for_vertex> runs the anonymous subroutine for each vertex while
C<return_vertex> being true causes each vertex to be returned
iteratively.  C<return_vertex> could also be an anonymous subroutine
in which case the result of calling it with the vertex as the argument
of the anon sub would be returned.

The vertices are returned in the order they are met: this is in effect
the B<preorder> of the graph.

Analogous `hooks' (callbacks) exist for

=over 4

=item I<edges>: as each edge is seen: C<for_edge> and C<return_edge>

=item I<roots>: each tree of the depth-first
forest has a root vertex: C<for_root> and C<return_root>

=item I<paths>: a path is ready when the depth-first traversal can
proceed no deeper: C<for_path> and C<return_path>

=item I<done vertices>: a vertex is `done' when it no more has unseen
descendant vertices: C<for_done_vertex> and C<return_done_vertex> This
is in effect the B<postorder> of the graph.

In addition to these hooks each vertex gets two integer `timestamps'
as I<attribute>s (see L<Graph>): C<Seen> and C<Done>.  The
timestamps correspond to C<for_vertex>, C<for_done_vertex>.
Two additional timestamps called C<SeenG> and C<DoneG> record
the `global' timestamps of the whole traversal.

        $g = Graph->new;

	$g->add_edges(qw(a b b c b d d e));

        $w = Graph::DFS->new;

        $w->( $g );

        foreach $v ( sort $g->vertices ) {
            print $v, " ", $v->Seen,  " ", $v->Done,
                      " ", $v->SeenG, " ", $v->DoneG, "\n";
        }

should output the following

	a 0 4 0 9
	b 1 3 1 8
	c 2 0 2 3
	d 3 2 4 7
	e 4 1 5 6

=cut

use Graph::Element;

use vars qw(@ISA);

use strict;
local ($^W) = 1;

# cyclicity_check() is currently mostly unused because I think one
# cannot find all the cycles of a graph using a depth-first traversal
# of the vertices.  For example: a->b, b->c, c->a, c->b, b->a, a->c.
# cyclicity_check() is used only _once_ for the return_cyclic so
# $state->{cycles} will contain at most _one_ cycle.

sub cyclicity_check {
    my ( $state, $successor ) = @_;

    my $cyclic = 0;
    my @canon_cycle = @{ $state->{ path } };
    my $cycle_signature;
 
    if ( @canon_cycle > 1 ) {
	# Canonize it.
	my $origin  = $canon_cycle[ 0 ];
	my $origini = 0;

	print "canon: @canon_cycle -> " if $state->{ debug };

	# Find a unique defining vertex.
	for ( my $i = 1; $i < @canon_cycle; $i++ ) {
	    if ( $canon_cycle[ $i ] lt $origin ) {
		$origin  = $canon_cycle[ $i ];
		$origini = $i;
	    }
	}
          
	# Now the actual canonization: rotate the cycle
	# so that the unique defining vertex is first.
	if ( $origini > 0 ) {
	    my @canon_head = splice( @canon_cycle, 0, $origini );

	    push @canon_cycle, @canon_head;
	}

	print "@canon_cycle\n" if $state->{ debug };
    }

    $cycle_signature = join( " ", @canon_cycle );
 
  CYCLIC_CHECK:
    {
	if ( $state->{ cycles } and @{ $state->{ cycles } } ) {
	    foreach my $v ( @{ $state->{ path } } ) {
		if ( $v eq $successor ) {
		    my $signatures = @{ $state->{ cycle_signatures } };
		    
		    for ( my $i = 0; $i < $signatures; $i++ ) {
			last CYCLIC_CHECK
			    if $state->{ cycle_signatures }->[ $i ] eq
				$cycle_signature;
		    }
		    $cyclic = 1;
		    last CYCLIC_CHECK;
		}
	    }
	} else {
	    foreach my $v ( @{ $state->{ path } } ) {
		if ( $v eq $successor ) {
		    $cyclic = 1;
		    last CYCLIC_CHECK;
		}
	    }
	}
    }

    my $cycle;

    if ( $cyclic ) {
	$cycle = [ @{ $state->{ path } } ];
	print "cycle: @$cycle\n" if $state->{ debug };
	push @{ $state->{ cycles } },           $cycle;
	push @{ $state->{ cycle_signatures } }, $cycle_signature;
    }

    return wantarray ? ( $cyclic, $cycle ) : $cyclic;
}

sub new {
    my ( $type, $param ) = @_;

    my $state = $param;

    # init_state
    $param->{ init_state }->( $param, $state )
        if exists $param->{ init_state };
    
    my $code = sprintf q!
sub {
    my ( $graph ) = @_;

    unless ( exists $state->{ state } ) {
        # get_roots
        my @roots = %s;

        # Initialize roots and stuff.
        if ( @roots ) {
            @{ $state->{ unseen_vertices } }{ @roots } = ();
            $state->{ roots } = [ @roots ];

	    $state->{ rooti  } = 0;
	    $state->{ rootn  } = @roots;
	    $state->{ state  } = 'ROOT';
	    $state->{ DONE   } = 0;
	    $state->{ SEEN   } = 0;
	    $state->{ ORDERG } = 0;

	    foreach my $v ( $graph->vertices ) {
		$v->delete_attribute( 'Seen'  );
		$v->delete_attribute( 'Done'  );
		$v->delete_attribute( 'SeenG' );
		$v->delete_attribute( 'DoneG' );
            }
        } else {
	    return;
	}
    }

    my $vertex;
    my $successor;

    for( ; ; ) {
        print "state: $state->{ state }\n" if $state->{ debug };

        if ( $state->{ state } eq 'ROOT' ) {
            my $root;

            # Find next root.
            delete $state->{ root };
            if ( $state->{ unseen_vertices } ) {
		# TODO: next_root
                for ( my $i = $state->{ rooti };
                      $i < $state->{ rootn };
                      $i++ ) {
                    $root = $state->{ roots }->[ $i ];
                    $state->{ rooti } = $i;
                    if ( exists $state->{ unseen_vertices }->{ $root } ) {
                        $state->{ root }  = $root;
                        last;
                    }
                }
            }

            if ( exists $state->{ root } ) {
		print "root: $state->{root}\n" if $state->{ debug };

		$state->{ path   } = [ ];
		$state->{ vertex } = $state->{ root };

		# for_root
		%s

		$state->{ state } = 'VERTEX';

		# return_root
		%s
	    } else {
		print "return.\n" if $state->{ debug };

		delete $state->{ state };

		return;
	    }
        }

        if ( $state->{ state } eq 'EDGE' ) {
            $vertex    = $state->{ vertex };
            $successor = $state->{ successor };
            $state->{ vertex } = $successor;

            # for_edge
            %s

	    delete $state->{ successor };
            $state->{ state } = 'VERTEX';

            # return_edge
            %s
        }

        if ( $state->{ state } eq 'VERTEX' ) {
            $vertex = $state->{ vertex };
	    if ( exists $state->{ unseen_vertices }->{ $vertex } ) {
		$vertex = $state->{ vertex };
		print "vertex: $vertex\n" if $state->{ debug };
		push @{ $state->{ path } }, $vertex;
		# ...->{$vertex}->{ seen  } = $state->{ order };
		# ...->{$vertex}->{ order } = $state->{ order }++;

		delete $state->{ unseen_vertices }->{ $vertex };

		# Initialize successors.
		unless ( exists $state->{ successors }->{ $vertex } ) {
		    # get_successors
		    my @successors = %s;
                
		    if ( @successors ) {
			$state->{ successors }->{ $vertex } = [ @successors ];
			$state->{ successori }->{ $vertex } = 0;
			$state->{ successorn }->{ $vertex } = @successors;
			$state->{ successorl }->{ $vertex } = @successors - 1;
		    }
		    print "successors($vertex) = @successors\n"
			if $state->{ debug };
		}

		$graph->vertex( $vertex )->SeenG( $state->{ ORDERG }++ );
		$graph->vertex( $vertex )->Seen ( $state->{ SEEN   }++ );

		# for_vertex
		%s

		$state->{ state } = 'SUCCESSOR';

		# return_vertex
		%s
	    }
        }

	# $cyclic and $cycle
	%s

        if ( $state->{ state } eq 'SUCCESSOR' ) {
            $vertex = $state->{ vertex };
            print "successor($vertex):\n" if $state->{ debug };

            # Find next successor.
            delete $state->{ successor };

            if ( $state->{ successors }->{ $vertex } ) {
		# TODO: next_successor
		for ( my $i = $state->{ successori }->{ $vertex };
		      $i < $state->{ successorn }->{ $vertex };
		      $i++ ) {
		    $successor =
			$state->{ successors }->{ $vertex }->[ $i ];
		    $state->{ successori }->{ $vertex } = $i;
		    if ( exists
			 $state->{ unseen_vertices }->{ $successor } ) {
			print "successor($vertex)[$i]: $successor\n"
			    if $state->{ debug };
			$state->{ successor } = $successor;
			last;
		    } else {
			# cyclicity check
			%s
		    }
		}
	    }

            if ( exists $state->{ successor } ) {
		$state->{ retrace } = 0;
		$state->{ state   } = 'EDGE';
            } else {
		$state->{ state   } = 'END';
	    }
	}

	if ( $state->{ state } eq 'END' ) {
	    # return_cyclic
	    %s

  	    if ( defined $vertex ) {
		my $done_vertex =
		    exists $state->{ successors }->{ $vertex } &&
			( $state->{ successori }->{ $vertex } ==
			  $state->{ successorl }->{ $vertex } ) ||
			      not exists $state->{ successors }->{ $vertex };

		if ( $done_vertex ) {
		    $graph->vertex( $vertex )->DoneG( $state->{ ORDERG }++ );
		    $graph->vertex( $vertex )->Done ( $state->{ DONE   }++ );
		}

	        # for_done_vertex
	        %s

		if ( @{ $state->{ path } } > 1 ) {
		    $state->{ state } = 'RETRACE';
		} else {
		    $state->{ state } = 'ROOT';
		}

	        # return_done_vertex
	        %s
	    }
	}

	if ( $state->{ state } eq 'RETRACE' ) {
	    my @path = @{ $state->{ path } };

	    print "path: @path\n" if $state->{ debug };

	    $state->{ retrace }++;
	    $state->{ vertex } = $path[ -2 ];

	    # for_path
	    %s

	    pop @{ $state->{ path } };
	    $state->{ state } = 'SUCCESSOR';

	    # return_path
	    %s
	}

	# for_cycle?

	# return_cycle?
    }
}
!,

    $param->{ get_roots } ?
        '$state->{ get_roots }->( $state, $graph )' :
        'sort $graph->vertices',

    $param->{ for_root } ?
        '$state->{ for_root }->( $root, $state, $graph );' : '',

    $param->{ return_root } ?
        ( ref $param->{ return_root } eq 'CODE' ?
          'return $state->{ return_root }->( $root, $state, $graph );' :
          'return $state->{ root };' ) : '',

    $param->{ for_edge } ?
        '$state->{ for_edge }->( $vertex, $successor, $state, $graph );' : '',

    $param->{ return_edge } ?
        ( ref $param->{ return_edge } eq 'CODE' ?
          'return $state->{ return_edge }->
                          ( $vertex, $successor, $state, $graph );' :
          'return ( $vertex, $successor );' ) : '',

    $param->{ get_successors } ?
        '$state->{ get_successors }->( $vertex, $state, $graph )' :
        'sort $graph->vertex_successors( $vertex )',

    $param->{ for_vertex } ?
        '$state->{ for_vertex }->( $vertex, $state, $graph );' : '',

    $param->{ return_vertex } ?
        ( ref $param->{ return_vertex } eq 'CODE' ?
          'return $state->{ return_vertex }->( $vertex, $state, $graph );' :
          'return $state->{ vertex };' ) : '',

    $param->{ return_cyclic } ? 'my ( $cyclic, $cycle );' : '',

    $param->{ return_cyclic } ?
           '( $cyclic, $cycle ) = cyclicity_check( $state, $successor );
            last if $cyclic;' :
	   '',

    $param->{ return_cyclic } ?
           'return 1 if $cyclic;' :
           '',

    $param->{ for_done_vertex } ?
	'$state->{ for_done_vertex }->( $vertex, $state, $graph )
             if $done_vertex;' :
        '',

    $param->{ return_done_vertex } ?
	'return $vertex if $done_vertex;' : '',

    $param->{ for_path } ?
        '$state->{ for_path }->( \@path, $state, $graph )
             if $state->{ retrace } == 1;' :
        '',

    $param->{ return_path } ?
        ( ref $param->{ return_path } eq 'CODE' ?
          'return $state->{ return_path }->
                          ( \@path, $state, $graph )' :
          'return \@path' ) .
          ' if $state->{ retrace } == 1;' : '' ,

    ;

    print $code if $param->{ debug };

    my $df = eval $code;

    bless $df, $type;
}

=pod

=head1 SEE ALSO

L<Graph>.

=head1 VERSION

See L<Graph>.

=head1 AUTHOR

Jarkko Hietaniemi <F<jhi@iki.fi>>

=head1 COPYRIGHT

Copyright 1998, O'Reilly and Associates.

This code is distributed under the same copyright terms as Perl itself.

=cut

1;
