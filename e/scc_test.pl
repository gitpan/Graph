
use lib qw(./lib ../lib);

use Graph::Directed;
use Data::Dumper;

my $graph = Graph::Directed->new()
    ->add(1 => 2, 1 => 3, 
	  2 => 4, 
	  3 => 4, 
	  4 => 2);

print Dumper($graph);

my @text = map("{" . join(' ',sort {$a cmp $b} @$_) . "}", $graph->scc);
print "Strongly connected components : @text\n";

