use Graph;

print "1..2\n";

my $g1 = Graph->new;

print "ok 1\n";

$g1->add_Capacity_path(qw(a 3 b 4 d 2 f));
$g1->add_Capacity_path(qw(a 1 c 9 e 7 f));
$g1->add_Capacity_path(qw(b 1 e));
$g1->add_Capacity_path(qw(c 5 d));

my $f1 = $g1->flow_edmonds_karp(qw(a f));

print "not " unless $f1->edges(qw(a b))->Flow == 3
                and $f1->edges(qw(a c))->Flow == 1
                and $f1->edges(qw(b d))->Flow == 2
                and $f1->edges(qw(b e))->Flow == 1
                and $f1->edges(qw(c d))->Flow == 0
                and $f1->edges(qw(c e))->Flow == 1
                and $f1->edges(qw(d f))->Flow == 2
                and $f1->edges(qw(e f))->Flow == 2;

my $g2 = Graph->new;

$g2->add_Capacity_path(qw(a 20 b 30 c 25 f 20 h));
$g2->add_Capacity_path(qw(b 10 e  3 g  8 h));
$g2->add_Capacity_path(qw(a 10 e));
$g2->add_Capacity_path(qw(a  1 c));
$g2->add_Capacity_path(qw(a 15 d  5 h));
$g2->add_Capacity_path(qw(d  2 c));
$g2->add_Capacity_path(qw(d 12 g));
$g2->add_Capacity_path(qw(b  7 f));

my $f2 = $g2->flow_edmonds_karp(qw(a h));

if (0) {
    foreach $e ( sort $f2->edges ) {
	print "$e ", $f2->edges($e->vertex_Ids)->Flow, "\n";
    }
}

print "not " unless $f2->edges(qw(a b))->Flow == 19
                and $f2->edges(qw(a c))->Flow == 1
                and $f2->edges(qw(a d))->Flow == 13
                and $f2->edges(qw(a e))->Flow == 0
                and $f2->edges(qw(b c))->Flow == 12
                and $f2->edges(qw(b e))->Flow == 0
                and $f2->edges(qw(b f))->Flow == 7
                and $f2->edges(qw(c f))->Flow == 13
                and $f2->edges(qw(d c))->Flow == 0
                and $f2->edges(qw(d g))->Flow == 8
                and $f2->edges(qw(d h))->Flow == 5
                and $f2->edges(qw(e g))->Flow == 0
                and $f2->edges(qw(f h))->Flow == 20
                and $f2->edges(qw(g h))->Flow == 8;

print "ok 2\n";
