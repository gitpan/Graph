package Graph::BitMatrix;

use strict;

# $SIG{__DIE__ } = sub { use Carp; confess };
# $SIG{__WARN__} = sub { use Carp; confess };

sub new {
    my ($class, $g) = @_;
    my @V = $g->vertices;
    my $V = @V;
    my $Z = "\0" x (($V + 7) / 8);
    my %V; @V{ @V } = 0 .. $#V;
    bless [ [ ( $Z ) x $V ], \%V ], $class;
}

sub set {
    my ($m, $u, $v) = @_;
    my ($i, $j) = map { $m->[1]->{ $_ } } ($u, $v);
    vec($m->[0]->[$i], $j, 1) = 1;
}

sub get {
    my ($m, $u, $v) = @_;
    my ($i, $j) = map { $m->[1]->{ $_ } } ($u, $v);
    vec($m->[0]->[$i], $j, 1);
}

sub vertices {
    my ($m, $u, $v) = @_;
    keys %{ $m->[1] };
}

1;
__END__
=pod

=head1 NAME

Graph::BitMatrix - create and manipulate a V x V bit matrix of graph G

=head1 SYNOPSIS

    use Graph::BitMatrix;
    use Graph::Directed;
    my $g  = Graph::Directed->new;
    $g->add_...(); # build $g
    my $m = Graph::BitMatrix->new($g);
    $m->get($u, $v)
    $m->set($u, $v)
    $a->vertices()

=head1 DESCRIPTION

B<This module is meant for internal use by the Graph module.>

=head2 Class Methods

=over 4

=item new($g)

Create a bit matrix from a Graph $g.

=back

=head2 Object Methods

=over 4

=item get($u, $v)

Return true if the bit matrix has a "one bit" between the vertices
$u and $v; in other words, if there is (at least one) a vertex going from
$u to $v.  If there is no vertex and therefore a "zero bit", return false.

=item set($u, $v)

Set the bit between the vertices $u and $v; in other words, connect
the vertices $u and $v by an edge.

=item vertices

Return the list of vertices in the bit matrix.

=back

=head1 AUTHOR AND COPYRIGHT

Jarkko Hietaniemi F<jhi@iki.fi>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=cut
