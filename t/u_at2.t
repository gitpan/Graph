use Test::More tests => 2;

use strict;
use Graph;

my $g = Graph::Undirected->new;

while (<DATA>) {
    if (/(\S+)\s+(\S+)/) {
	$g->add_edge($1, $2);
    }
}

my $src = "Ap001a_ome01:14/1";
my $dst = "Mp001a_ome01:1/1";

my @u = qw(Ap001a_ome01:14/1
	   Ap001a_ome01:6/1
	   Zl001a_ome01:9/1
	   Zl001a_ome01:4/2
	   Mp001a_ome01:9/2
	   Mp001a_ome01:6/1
	   Mp001a_ome01:1/1);

print "# finding SP_Dijkstra path between $src and $dst\n";
my @v = $g->SP_Dijkstra($src, $dst);
is_deeply(\@v, \@u);
foreach (@v) {
    print "# $_\n";
}

{
    print "# finding APSP_Floyd_Warshall path between $src and $dst\n";
    my $apsp = $g->APSP_Floyd_Warshall();
    my @v = $apsp->path_vertices($src, $dst);
    is_deeply(\@v, \@u);
    foreach (@v) {
	print "# $_\n";
    }
}

__END__
Ah001a_ome01:6/1 Ah001a_ome01:9/1
Ah001a_ome01:6/1 Ap001a_ome01:9/1
Ah001a_ome01:9/1 Nm001a_ome01:6/1
Ap001a_ome01:14/1 Ap001a_ome01:6/1
Ap001a_ome01:14/1 Ap001a_ome01:9/1
Ap001a_ome01:6/1 Zl001a_ome01:9/1
Asd002a_ome02:5/1 Asd002a_ome02:6/1
Asd002a_ome02:5/1 Asd002a_ome07:10/1
Asd002a_ome02:6/1 Asd002a_ome06:10/1
Asd002a_ome06:10/1 Asd002a_ome06:6/1
Asd002a_ome06:6/1 Nm001a_ome01:10/1
Asd002a_ome07:10/1 Asd002a_ome07:5/1
Asd002a_ome07:5/1 Gn001a_ome01:9/1
Asn001a_ome01:6/1 Asn001a_ome01:9/1
Asn001a_ome01:6/1 Hgv001a_ome01:9/1
Asn001a_ome01:9/1 Gn001a_ome01:2/2
Gn001a_ome01:2/2 Gn001a_ome01:9/1
Hgv001a_ome01:10/1 Hgv001a_ome01:9/1
Hgv001a_ome01:10/1 Mp001a_ome01:6/1
Mp001a_ome01:1/1 Mp001a_ome01:6/1
Mp001a_ome01:6/1 Mp001a_ome01:9/2
Mp001a_ome01:9/2 Zl001a_ome01:4/2
Nm001a_ome01:10/1 Nm001a_ome01:6/1
Zl001a_ome01:4/2 Zl001a_ome01:9/1
