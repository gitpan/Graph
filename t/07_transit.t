use Graph::Directed;

my $test = 1;

print "1..2\n";

my $g1 = Graph::Directed->new;

$g1->add_edges(qw(a b b c b d d e));

my $t1 = $g1->transitive_closure;

print "not " unless "$t1" eq "a-a,a-b,a-c,a-d,a-e,b-b,b-c,b-d,b-e,c-c,d-d,d-e,e-e";
print "ok ", $test++, "\n";

$g1->delete_edge(qw(b d));

my $t2 = $g1->transitive_closure;

print "not " unless "$t2" eq "a-a,a-b,a-c,b-b,b-c,c-c,d-d,d-e,e-e";
print "ok ", $test++, "\n";

