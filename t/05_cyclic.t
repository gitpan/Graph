use Graph;

my $test = 1;

print "1..3\n";

my $g = Graph->new;

print "not " if $g->is_cyclic;
print "ok ", $test++, "\n";

$g->add_edge(qw(a b));
$g->add_edge(qw(b c));
$g->add_edge(qw(b d));
$g->add_edge(qw(a e));
$g->add_edge(qw(e f));
$g->add_edge(qw(e g));

print "not " if $g->is_cyclic;
print "ok ", $test++, "\n";

my $h = Graph->new;

$h->add_edge(qw(h h));

print "not " unless $h->is_cyclic;
print "ok ", $test++, "\n";
