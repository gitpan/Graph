
# Copyright (C) 1995, Mats Kindahl. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# E-mail: matkin@docs.uu.se
#
# Test code for Graph package.

use lib './lib';
use strict;

use Graph::Directed;

use Data::Dumper;

my $bar = Graph::Directed->new
    ->add('A' => 'B', 'A' => 'F', 'A' => 'G',
	  'C' => 'A',
	  'D' => 'F',
	  'E' => 'D',
	  'F' => 'E',
	  'G' => 'C', 'G' => 'J', 'G' => 'H',
	  'H' => 'I',
	  'I' => 'H',
	  'J' => 'K', 'J' => 'L', 'J' => 'M',
	  'L' => 'G', 'L' => 'M',
	  'M' => 'L');

print $bar->dump();

my @text = map("{" . join(' ',sort {$a cmp $b} @$_) . "}", $bar->scc);
print "Strongly connected components : @text\n";

print "\nThe following two graphs should have the same SCCs.\n";

$bar = Graph::Directed->new->add(1 => 2);
@text = map("{" . join(' ',sort {$a cmp $b} @$_) . "}", $bar->scc);
print "Strongly connected components : @text\n";

$bar = Graph::Directed->new->add(2 => 1);
@text = map("{" . join(' ',sort {$a cmp $b} @$_) . "}", $bar->scc);
print "Strongly connected components : @text\n";

# Testing topological sorting.
print '-' x 48, "\nTesting topological sorting\n\n";
my $baz = Graph::Directed->new
    ->add('A' => 'B', 'A' => 'C', 'A' => 'F', 'A' => 'G',
	  'E' => 'D',
	  'F' => 'D', 'F' => 'E',
	  'G' => 'C', 'G' => 'E', 'G' => 'H',
	  'H' => 'I',
	  'J' => 'G', 'J' => 'K', 'J' => 'L', 'J' => 'M',
	  'L' => 'G', 'L' => 'M');

my @list = topsort($baz);
print "\nA topological sorting: [@list]\n";


