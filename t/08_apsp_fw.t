use Graph::Directed;

my $test = 1;

print "1..12\n";

my $g1 = Graph::Directed->new;

$g1->add_attributed_path(qw(Weight a 1 b 2 c 1 d));
$g1->add_attributed_path(qw(Weight a 2 c));
$g1->add_attributed_path(qw(Weight c 2 e 1 f));
$g1->add_attributed_path(qw(Weight c 1 g 3 f));

my $p1 = $g1->APSP_floyd_warshall;
my $e;

foreach my $v (sort $g1->vertices) {
    $e = $p1->edge( $v->name, $v->name );
    print "not "
        unless defined $e->Weight and $e->Weight == 0 and not defined $e->Prev;
    print "ok ", $test++, "\n";
}

$e = $p1->edge(qw(a c));
print "not " unless $e->Weight == 2 and $e->Prev eq "a";
print "ok ", $test++, "\n";

$e = $p1->edge(qw(a f));
print "not " unless $e->Weight == 5 and $e->Prev eq "e";
print "ok ", $test++, "\n";

my $g2 = $g1->copy;

$g2->edge(qw(g f))->Weight(-1);

my $p2 = $g2->APSP_floyd_warshall;

$e = $p2->edge(qw(c f));
print "not " unless $e->Weight == 0 and $e->Prev eq "g";
print "ok ", $test++, "\n";

$e = $p2->edge(qw(a g));
print "not " unless $e->Weight == 3 and $e->Prev eq "c";
print "ok ", $test++, "\n";

$e = $p2->edge(qw(g f));
print "not " unless $e->Weight ==-1 and $e->Prev eq "g";
print "ok ", $test++, "\n";

