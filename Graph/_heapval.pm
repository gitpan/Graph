package Graph::_heapval;

# This small helper package is used by mst_prim and sssp_dijkstra.
# It is used to subclass new heap classes.
# The name of the package is indicative of its internal-use-only status.

sub new {
    my ( $type, $heap, $seen, $cost, $vertex ) = @_;

    my $new = [ $cost, undef, $vertex ];

    bless $new, $type;
    $heap->add( $new );
    $seen->{ $vertex } = $new;

    return $new;
}

sub val {
    my $self = shift;

    return @_ ? ( $self->[ 0 ] = shift ) : $self->[ 0 ];
}
    
sub heap {
    my $self = shift;

    return @_ ? ( $self->[ 1 ] = shift ) : $self->[ 1 ];
}
    
sub vertex {
    my $self = shift;
	
    return $self->[ 2 ]; # A read-only method.
}

sub cmp {
    my ( $self1, $self2 ) = @_;

    my $val1 = $self1->[ 0 ];
    my $val2 = $self2->[ 0 ];

    my $def2 = defined $val2;

    if ( defined $val1 ) {
	return $val1 <=> $val2 if $def2;
	return -1;
    } elsif ( $def2 ) {
	return  1;
    } else {
	return  0;
    }
}

1;
