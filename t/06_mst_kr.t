use Graph::Undirected;

my $test = 1;

print "1..2\n";

my $g1 = Graph::Undirected->new;

$g1->add_attributed_path(qw(Weight a 1 b 2 c));
$g1->add_attributed_path(qw(Weight a 1 c 1 d));

my @e = $g1->edges;

my @a = $g1->attributed_path(qw(Weight a b c));

print "not " unless @a == 2 and "@a" eq "1 2";
print "ok ", $test++, "\n";

my $k1 = $g1->MST_kruskal;

my @vg1 = sort $g1->vertices;
my @vk1 = sort $k1->vertices;

print "not " unless "@vg1" eq "@vk1";
print "ok ", $test++, "\n";

