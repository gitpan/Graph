package Graph::Undirected;

# $Id: Undirected.pm,v 1.1 1998/05/31 16:05:09 hietanie Exp $

=pod

=head1 NAME

Graph::Undirected - undirected graphs

=head1 SYNOPSIS

	use Graph::Undirected;

	$graph = Graph::Undirected->new;

=head1 DESCRIPTION

This class is largely just syntactic sweetener.

Everything except the constructor method is inherited from the classes
C<Graph::Element> and C<Graph>.  Note that an undirected graph is just
a graph, C<ref $graph> will be C<Graph>.

The constructor creates B<undirected> graphs, as opposed to the
classes C<Graph> and C<Graph::Directed> which create B<directed>
graphs.

Please see the C<Graph> documentation for more information about
directedness.

=cut

use strict;
use Carp 'confess';
use vars qw(@ISA);

use Graph;

@ISA = qw(Graph::Element Graph);

sub new {
    shift; # Throw away the 'Graph::Undirected'.

    my $new = Graph->new( @_ );

    $new->undirected( 1 );

    return $new;
}

=pod

=head1 SEE ALSO

L<Graph>, L<Graph::Directed>, L<Graph::Element>.

=head1 VERSION

Version 0.003.

=head1 AUTHOR

Jarkko Hietaniemi, <F<jhi@iki.fi>>

=head1 COPYRIGHT

Copyright 1998, O'Reilly & Associates.

This code is distributed under the same copyright terms as perl itself.

=cut

1;
