use Graph;
use Graph::Directed;
use Graph::Undirected;

print "1..15\n";

my $test = 1;

my $g0 = Graph->new;
my $g1 = Graph::Directed->new;
my $g2 = Graph::Undirected->new;
my $g3 = Graph::Directed->new;

my @e = qw(a b a c b c b d);

$g1->add_edges(@e);
$g2->add_edges(@e);
$g3->add_edges(@e, qw(c d));

my $g4 = $g1->complete_graph;

print "not " unless join(" ", $g1->density_limits) eq "4 8";

# 1..10

print "not " unless $g0->is_sparse;
print "ok ", $test++, "\n";

print "not " if $g0->is_dense;
print "ok ", $test++, "\n";

print "not " unless $g1->is_sparse;
print "ok ", $test++, "\n";

print "not " if $g1->is_dense;
print "ok ", $test++, "\n";

print "not " if $g2->is_sparse;
print "ok ", $test++, "\n";

print "not " unless $g2->is_dense;
print "ok ", $test++, "\n";

print "not " if $g3->is_sparse;
print "ok ", $test++, "\n";

print "not " if $g3->is_dense;
print "ok ", $test++, "\n";

print "not " if $g4->is_sparse;
print "ok ", $test++, "\n";

print "not " unless $g4->is_dense;
print "ok ", $test++, "\n";

# 11..15

print "not " unless $g0->density == 0;
print "ok ", $test++, "\n";

print "not " unless $g1->density == 4/12;
print "ok ", $test++, "\n";

print "not " unless $g2->density == 4/12;
print "ok ", $test++, "\n";

print "not " unless $g3->density == 5/12;
print "ok ", $test++, "\n";

print "not " unless $g4->density == 1;
print "ok ", $test++, "\n";

# eof
