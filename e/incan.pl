
# Analysis of file inclusion hierarchies for C/C++

use lib qw(./blib/lib ../blib/lib);
use strict;
use Graph::Directed qw(scc);

$| = 1;				# Autoflush streams

my $graph = Graph::Directed->new();

print "reading...";

my $file;			# Base file name

while (<>) {
    $file = $1 if $ARGV =~ m[.*/(.*)];
    if (/^#\s*include\s+<(.*?)>/) { 
	$graph->add($file => $1); 
    } 
    elsif (/^#\s*include\s*\"(.*?)\"/) 
    {
	$graph->add($file => $1);
    }
}

print "done\n";

# Find all strongly connected components with more than one node.
my @list = grep(@$_ > 1, scc($graph));
my @text = map("{" . join(' ',sort {$a cmp $b} @$_) . "}", @list);
print "Cyclic inclusions in the groups: @text\n" if @text > 0;
