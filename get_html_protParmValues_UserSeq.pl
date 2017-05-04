#!/usr/bin/perl

#library
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use File::Basename;

#HTTP::Request::Common qw(POST);
# ----> user parameter and network access ------

=head1 Name
    get_html_protParmValues_UserSeq.pl -  Perform ProtParam analysis through Web HTTP access


==head1 COPYRIGHT

Copyright 2011 Yoshiharu Sato
This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This is free software with ABSOLUTELY NO WARRANTY.
Use at your own risk.


=cut




#$my $url = 'http://au.expasy.org/cgi-bin/protparam?';
my $url = 'http://web.expasy.org/cgi-bin/protparam/protparam?';

# HIT IDs.

$#ARGV == 0 or die "ERROR : $0 [input aa. fasta] \n";
use Bio::SeqIO;
my $inputfile = $ARGV[0];  #### amino acid

my @nameArr = split(/\./, basename($inputfile));
my $protein_name = $nameArr[0];

#my @array = split(/\//, $inputfile);
#my $printvar = $array[$#array];
#my $printvar = substr ( $inputfile, 57, 9 );

my %seq = ();
my $in  = Bio::SeqIO->new(-file => "$inputfile" ,
                           -format => 'Fasta');

    while ( my $seq = $in->next_seq() ) {
       $seq{$seq->id} = $seq->seq;    
    }





for my $id ( keys %seq){
chomp $id;
my $seq = $seq{$id};

my $this_url = $url;
#$this_url .= "sequence=$seq";

# Makes a request to the URL
my %formdata = 
		(
		"submit"=>"on",
		"sequence"=>$seq,
		);
		
my $request  = POST($this_url, [%formdata]);

# ----> XML print out -------------------------------
my $ua  = LWP::UserAgent->new(timeout=>2000);
my $res = $ua->request($request);

my $html = $res->as_string;
  &pars_protParm_HTML( $id , $res->as_string);
}


sub pars_protParm_HTML{
	my $id = shift;
	my $html = shift;

	my %values = ();

	my @lines = split(/\n/,$html);

	for my $line (@lines){
		if($line =~ /Molecular weight\:\S+\s*(\d+.*\d*\b)/){
			$values{'mw'} = $1;
		}
		elsif($line =~ /Theoretical pI\:\S+\s*(\d+.*\d*\b)/){
			$values{'pI'} = $1;
		}
		elsif($line =~ /The instability index \(II\) is computed to be\s*([-]*\d+.*\d*\b)/){
		    $values{'insta'} = $1;
		}
		elsif($line =~ /Aliphatic index\:\S+\s*(\d+.*\d*\b)/){
			$values{'alipha'} = $1;
		}
		elsif($line =~ /Grand average of hydropathicity \(GRAVY\)\:\S+\s*([-]*\d+.*\d*\b)/){
			$values{'hydro'} = $1;
		}
		elsif($line =~ /Total number of negatively charged residues \(Asp \+ Glu\):\S+\s*(\d+\b)/){
			$values{'neg_charge'} = $1;
		}
		elsif($line =~ /Total number of positively charged residues \(Arg \+ Lys\):\S+\s*(\d+\b)/){
			$values{'pos_charge'} = $1;
		}
	}

	my $charge = $values{'pos_charge'} - $values{'neg_charge'};
	my @pri = (
				$values{'mw'},
				$charge,
				$values{'pI'},
				$values{'insta'},
				$values{'alipha'},
				$values{'hydro'});
	print "$protein_name\t" . join("\t",@pri) ."\n\n";

}


__END__
