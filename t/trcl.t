use Graph;

print "1..2\n";

my $g1 = Graph->new;

$g1->add_edge(qw(a b));
$g1->add_edge(qw(a c));
$g1->add_edge(qw(c d));
$g1->add_edge(qw(d e));
$g1->add_edge(qw(c e));
$g1->add_edge(qw(e f));
$g1->add_edge(qw(e g));
$g1->add_edge(qw(g c));

print "not " unless $g1->transitive_closure eq
                    "a-a,a-b,a-c,a-d,a-e,a-f,a-g,b-b,c-c,c-d,c-e,c-f,c-g,d-c,d-d,d-e,d-f,d-g,e-c,e-d,e-e,e-f,e-g,f-f,g-c,g-d,g-e,g-f,g-g";

print "ok 1\n";

my $g2 = Graph->new;

$g2->add_edge(qw(a b));
$g2->add_edge(qw(b d));
$g2->add_edge(qw(d e));
$g2->add_edge(qw(e b));
$g2->add_edge(qw(a c));
$g2->add_edge(qw(c f));
$g2->add_edge(qw(f g));
$g2->add_edge(qw(g h));
$g2->add_edge(qw(h i));
$g2->add_edge(qw(f h));

print $g2->transitive_closure, "\n";
print "not " unless $g2->transitive_closure eq
                    "a-a,a-b,a-c,a-d,a-e,a-f,a-g,a-h,a-i,b-b,b-d,b-e,c-c,c-f,c-g,c-h,c-i,d-b,d-d,d-e,e-b,e-d,e-e,f-f,f-g,f-h,f-i,g-g,g-h,g-i,h-h,h-i,i-i";

print "ok 2\n";

