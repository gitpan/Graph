package Graph::Vertex;

# $Id: Vertex.pm,v 1.7 1998/06/06 13:43:33 jhi Exp $

=pod

=head1 NAME

Graph::Vertex - a base class for graph edges

=head1 SYNOPSIS

B<Not to be used directly>.

=head1 DESCRIPTION

This class is not to be used directly because a vertex always must
belong to a graph.  The graph classes will do this right.  Some useful
public methods exist, though.

=cut

use strict;
local $^W = 1;

use Graph::Element;

use vars qw(@ISA);

@ISA = qw(Graph::Element);

use overload q("") => \&as_string, 'cmp' => \&cmp;

sub as_string {
    my $vertex = shift;

    return $vertex->name;
}

sub cmp {
    my ( $u, $v ) = @_;

    return $u->name cmp ( ref $v ? $v->name : $v );
}

sub _new ($$$) {
    my ( $class, $graph, $name ) = @_;

    die "$class->new: Usage: $class->_new( graph, name )\n"
	unless defined $graph and defined $name;

    my $vertex;

    if ( defined $graph->vertex( $name ) ) {
	$vertex = $graph->vertex( $name );
    } else {
	$vertex = Graph::Element::_new( $class, $name );
	$vertex->_add_to_graph( $graph, '_VERTICES', $name );
    }

    return $vertex;
}

=pod

=head2 ADDING AND DELETING VERTICES

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
