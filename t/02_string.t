# Test graph stringification. (01_parts already does use it, though)

use Graph::Directed;
use Graph::Undirected;

print "1..14\n";

my $test = 1;

my $g1 = new Graph::Directed;

print "not " unless "$g1" eq "";
print "ok ", $test++, "\n";

$g1->add_vertex("a");

print "not " unless "$g1" eq "a";
print "ok ", $test++, "\n";

$g1->add_vertex(qw(b c)); # should skip c

print "not " unless "$g1" eq "a,b";
print "ok ", $test++, "\n";

$g1->add_vertices(qw(b c)); # should not double d and not skip c

print "not " unless "$g1" eq "a,b,c";
print "ok ", $test++, "\n";

$g1->delete_vertex(qw(b c d)); # should skip c and d

print "not " unless "$g1" eq "a,c";
print "ok ", $test++, "\n";

$g1->delete_vertices(qw(a b));

print "not " unless "$g1" eq "c";
print "ok ", $test++, "\n";

my $e1 = $g1->add_edge(qw(a b));

print "not " unless "$g1" eq "a-b,c";
print "ok ", $test++, "\n";

my @v = sort $e1->vertices;

print "not " unless @v == 2 and "@v" eq "a b";
print "ok ", $test++, "\n";

print "not " unless "@{[$e1->start]}" eq "a";
print "ok ", $test++, "\n";

print "not " unless "@{[$e1->stop]}"  eq "b";
print "ok ", $test++, "\n";

$g1->add_edges(qw(a c b d));

print "not " unless "$g1" eq "a-b,a-c,b-d";
print "ok ", $test++, "\n";

$g1->delete_edges(qw(a c a b));

print "not " unless "$g1" eq "b-d";
print "ok ", $test++, "\n";

my $g2 = new Graph::Undirected;

$g2->add_edges(qw(a b a c));
$g2->add_vertices(qw(d e));

print "not " unless "$g2" eq "a=b,a=c,d,e";
print "ok ", $test++, "\n";

my @e = sort $g2->edges;

print "not " unless @e == 4 and "@e" eq "a-b a-c b-a c-a";
print "ok ", $test++, "\n";
