use Graph;

my $test = 1;

print "1..4\n";

my $g = Graph->new;

$g->add_edge(qw(a b));
$g->add_edge(qw(b c));
$g->add_edge(qw(b d));
$g->add_edge(qw(a e));
$g->add_edge(qw(e f));
$g->add_edge(qw(e g));
$g->add_edge(qw(h i));
$g->add_edge(qw(i h));
$g->add_edge(qw(h h));
$g->add_edge(qw(i j));
$g->add_edge(qw(j h));
$g->add_edge(qw(h j));
$g->add_edge(qw(j i));

my @t = $g->topological_sort;

print "not " unless @t == $g->vertices;
print "ok ", $test++, "\n";

my %s;

@s{ @t } = 0..$#t;

print "not " unless $s{a} < $s{b} and
	            $s{a} < $s{c} and
	            $s{b} < $s{d} and
	            $s{a} < $s{e} and
	            $s{e} < $s{f} and
	            $s{e} < $s{g};
print "ok ", $test++, "\n";

print "not " unless $g->vertex("a")->Seen == 0 and
                    $g->vertex("b")->Seen < $g->vertex("c")->Seen  and
                    $g->vertex("b")->Seen < $g->vertex("d")->Seen  and
                    $g->vertex("e")->Seen < $g->vertex("f")->Seen  and
                    $g->vertex("e")->Seen < $g->vertex("g")->Seen;
print "ok ", $test++, "\n";

print "not " unless $g->vertex("a")->Done == 6 and
                    $g->vertex("b")->Done > $g->vertex("c")->Done  and
                    $g->vertex("b")->Done > $g->vertex("d")->Done  and
                    $g->vertex("e")->Done > $g->vertex("f")->Done  and
                    $g->vertex("e")->Done > $g->vertex("g")->Done;
print "ok ", $test++, "\n";
