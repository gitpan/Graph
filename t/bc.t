use Graph::Undirected;

print "1..4\n";

my $g1 = Graph::Undirected->new;

$g1->add_path(qw(a b d e f h g e));
$g1->add_path(qw(a c d));
$g1->add_path(qw(h i));

print "not " unless not $g1->biconnected;

print "ok 1\n";

print "not " unless "@{[$g1->articulation_points]}" eq "h d e";

print "ok 2\n";

print "not " unless "@{[$g1->bridges]}" eq "d=e h=i";

print "ok 3\n";

print "not " unless "@{[$g1->biconnected_components]}" eq
                    "a=b,a=c,b=d,c=d e=f,e=g,f=h,g=h";

print "ok 4\n";
