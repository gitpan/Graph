require 5;

# $Id: Makefile.PL,v 1.1 1998/11/02 09:40:46 jhi Exp jhi $

use ExtUtils::MakeMaker;

require 5.004_04;

sub MY::libscan
{
 my($self, $path) = @_;

 return '' 
        if($path =~ m:/(RCS|CVS|SCCS)/: ||
           $path =~ m:[~%]$: ||
           $path =~ m:\.(orig|rej)$:
          );
 
 $path;
}

WriteMakefile(
    VERSION_FROM => 'Graph.pm',
    NAME         => 'Graph',
    VERSION      => $VERSION,
    dist         => { COMPRESS => 'gzip -9f',
		      SUFFIX   => 'gz', 
		      DIST_DEFAULT => 'all tardist',
		    },
    clean        => { FILES    => join(" ",
				       map { "$_ */$_ */*/$_" }
				       qw(*% *.html *.b[ac]k *.old *.orig)),
		    },
);
