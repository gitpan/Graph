package Graph::Directed;

# $Id: Directed.pm,v 1.1 1998/05/31 16:05:07 hietanie Exp $

=pod

=head1 NAME

Graph::Directed - directed graphs

=head1 SYNOPSIS

	use Graph::Directed;

	$graph = Graph::Directed->new;

=head1 DESCRIPTION

This class is artificial syntactic sweetener and is provided only for
aesthetical reasons.  B<For all practical purposes this class is
identical to the C<Graph> class.>  Even C<ref $graph> will be C<Graph>.

Please see the C<Graph> documentation for more information about
directedness.

=cut

use strict;
use Carp 'confess';
use vars qw(@ISA);

use Graph;

@ISA = qw(Graph::Element Graph);

=pod

=head1 SEE ALSO

L<Graph>, L<Graph::Undirected>, L<Graph::Element>.

=head1 VERSION

Version 0.003.

=head1 AUTHOR

Jarkko Hietaniemi, <F<jhi@iki.fi>>

=head1 COPYRIGHT

Copyright 1998, O'Reilly & Associates.

This code is distributed under the same copyright terms as perl itself.

=cut

1;
