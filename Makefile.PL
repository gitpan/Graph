require 5;

use ExtUtils::MakeMaker;

open(VERSION, "VERSION") and
    chomp($version = <VERSION>) and
    close(VERSION);
die "Version undefined: $!\n" unless defined $version;
die "Version $version illegal\n" unless $version > 0;

use Cwd;

my $cwd = getcwd();

die "ERROR: This directory ($cwd)\ndoes not look like version $version.\n"
    unless $cwd =~ /\Q$version\E$/;

if ( -M "Graph.pm" > -M "VERSION" or -M "Graph.pm" > -M "Makefile.PL" )  {
    print "Setting Graph.pm to version $version\n";
    local($^I, @ARGV) = ('.bak', 'Graph.pm');
    my $updates = 0;
    while (<>) {
        $updates++
           if s/^(Version|\$VERSION\s*=)\s*(?:\d.+)([.;])$/$1 $version$2/;
        print;
        close ARGV if eof;
    }
    die "ERROR: Updated $updates version stamps, expected 1 or 2.\n"
       unless $updates == 1 or $updates == 2;
}

WriteMakefile(
    'NAME'      => 'Graph',
    'VERSION'   => $version,
    'dist'      => { 'COMPRESS' => 'gzip' }
);
