use Graph;

print "1..2\n";

my $g1 = Graph->new;

$g1->add_path(qw(a b a c d e c));
$g1->add_path(qw(b d f));
$g1->add_path(qw(b f));

print "not " unless ($g1->strongly_connected_components)[1] eq "c,d,e";

print "ok 1\n";

print "not " unless $g1->strongly_connected_component_graph eq
                    "(a,b)-(c,d,e),(a,b)-(f),(c,d,e)-(f)";

print "ok 2\n";
