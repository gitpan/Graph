use Graph;

print "1..2\n";

my $g1 = Graph->new;

$g1->add_Weight_path(qw(a 1 b -5 g 4 h));
$g1->add_Weight_path(qw(a 2 d 2 e 7));
$g1->add_Weight_path(qw(a 3 c 4 i 1 h));
$g1->add_Weight_path(qw(b 4 d 3 f 5 i 2 g));
$g1->add_Weight_path(qw(f 3 e));
$g1->add_Weight_path(qw(f 3 e -2 f));
$g1->add_Weight_path(qw(c 1 i -3 c));

my $w1 = $g1->APSP_floyd_warshall;

print "not " unless $w1->edges(qw(a a))->Weight == 0
                and $w1->edges(qw(a b))->Weight == 1
                and $w1->edges(qw(a c))->Weight == 1
                and $w1->edges(qw(a d))->Weight == 2
                and $w1->edges(qw(a e))->Weight == 4
                and $w1->edges(qw(a f))->Weight == 2
                and $w1->edges(qw(a g))->Weight == -4
                and $w1->edges(qw(a h))->Weight == 0
                and $w1->edges(qw(a i))->Weight == 2
                and $w1->edges(qw(d c))->Prev->Id eq 'i'
                and $w1->edges(qw(d e))->Prev->Id eq 'd'
                and $w1->edges(qw(d f))->Prev->Id eq 'e'
                and $w1->edges(qw(d g))->Prev->Id eq 'i'
                and $w1->edges(qw(d h))->Prev->Id eq 'i'
                and $w1->edges(qw(d i))->Prev->Id eq 'c';

print "ok 1\n";

my $g2 = Graph->new;

$g2->add_Weight_path(qw(a 1 b 3 d -2 b));
$g2->add_Weight_path(qw(a 2 c -2 b));
$g2->add_Weight_path(qw(a 5 d));

my $w2 = $g2->APSP_floyd_warshall;

print "not " unless $w2->edges(qw(a b))->Weight == 0
                and $w2->edges(qw(a c))->Weight == 2
                and $w2->edges(qw(a d))->Weight == 3
                and $w2->edges(qw(a b))->Prev->Id eq 'c'
                and $w2->edges(qw(a c))->Prev->Id eq 'a'
                and $w2->edges(qw(a d))->Prev->Id eq 'b';

print "ok 2\n";
