package Graph::Directed;

=pod

=head1 NAME

Graph::Directed - directed graphs

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 VERSION

Version 0.01.

=head1 AUTHOR

Jarkko Hietaniemi, <F<jhi@iki.fi>>

=head1 COPYRIGHT

Copyright 1998, O'Reilly & Associates.

This code is distributed under the same copyright terms as perl itself.

=cut

# This class is artificial syntactic sweetener.
#
# Everything is inherited from the Graph::_element and
# Graph classes, therefore for all practical purposes
# identical to the Graph class.

use strict;
use Carp 'confess';
use vars qw(@ISA);

use Graph;

@ISA = qw(Graph::_element Graph);

1;
