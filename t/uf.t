use Graph::Undirected;

print "1..3\n";

my $g1 = Graph::Undirected->new;

$g1->add_edge(qw(a b));
$g1->add_edge(qw(c e));
$g1->add_edge(qw(c d));
$g1->add_edge(qw(a c));

print "not " unless $g1->find(qw(e a))
                and $g1->find(qw(d a))
                and $g1->find(qw(a b));

print "ok 1\n";

$g1->add_edge(qw(g h));
$g1->add_edge(qw(i j));
$g1->add_edge(qw(h i));

print "not " unless $g1->find(qw(g h))
                and $g1->find(qw(g i))
                and $g1->find(qw(g j));

print "ok 2\n";

$g1->add_edge(qw(h b));

print "not " unless $g1->find(qw(e j));

print "ok 3\n";
