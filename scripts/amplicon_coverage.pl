#!/usr/bin/perl
# Input a regions BED file and a BAM file and output tables indicating the median coverage for each amplicon,
# the identities of amplicons that did not meet the minumum threshold, and a summary table for the sample.
#
# 3/4/2014 - D Sims
#############################################################################################################

use warnings;
use strict;
use Getopt::Long;
use Data::Dump;
use Cwd;

( my $scriptname = $0 ) =~ s/^(.*\/)+//;
my $version = "v0.3.030914";
my $description = <<"EOT";
<fill_in_program_description>
EOT

my $usage = <<"EOT";
USAGE: $scriptname [options] <BED_file> <BAM_file>
    -s, --sample      Sample name
    -i, --ion         Using an Ion Torrent BED file that has been processed.
    -r, --reads       Total number of reads in the BAM file.
    -t, --threshold   Minimum number of reads threshold (DEFAULT: 450).
    -o, --outdir      Send output to custom directory.  Default is CWD.
    -v, --version     Version information
    -h, --help        Print this help information
EOT

my $help;
my $ver_info;
my $outdir = getcwd;
my $sample_name;
my $num_reads;
my $threshold = 450;
my $ion;

GetOptions( "outdir=s"    => \$outdir,
            "sample=s"    => \$sample_name,
            "ion"         => \$ion,
            "reads=i"     => \$num_reads,
            "threshold=i" => \$threshold,
            "version"     => \$ver_info,
            "help"        => \$help )
        or print $usage;

sub help {
	printf "%s - %s\n\n%s\n\n%s\n", $scriptname, $version, $description, $usage;
	exit;
}

sub version {
	printf "%s - %s\n", $scriptname, $version;
	exit;
}

help if $help;
version if $ver_info;

# Make sure enough args passed to script
if ( scalar( @ARGV ) != 2 ) {
    print "ERROR: Not enough arguments passed to script!\n\n";
    print "$usage\n";
    exit 1;
}

# Create some output filehandles for the data
my $lowcoverage_file = "$outdir/LowCoverageAmplicons.tsv";
my $allcoverage_file = "$outdir/AllAmpliconsCoverage.tsv";
my $summary_file = "$outdir/stat_table.txt";

open( my $aa_fh, ">", $allcoverage_file ) || die "Can't open the 'All Amplicons Coverage file for writing: $!";
open( my $low_fh, ">", $lowcoverage_file ) || die "Can't open the Low Amplicons Coverage file for writing: $!";
open( my $summary_fh, ">", $summary_file ) || die "Can't open the 'stat_table.txt' file for writing: $!";

#########------------------------------ END ARG Parsing ---------------------------------#########

my $bedfile = shift;
my $bamfile = shift;

# If we're using an Ion Torrent processed BED file from their API, we need to process it a bit to get the Gene ID
if ( $ion ) {
    my $proc_bed = proc_bed( \$bedfile );
    $bedfile = $proc_bed;
}

my %coverage_data;
my @all_coverage;

# Use BEDtools to get amplicon coverage data for each amplicon
open( my $covbed, "-|", "coverageBed -d -abam $bamfile -b $bedfile" ) || die "Can't open the stream: $!";

while (<$covbed>) {
    chomp;
    my @data = split;
    push( @{$coverage_data{join( ":", @data[3,5] )}}, $data[-1] );
    push( @all_coverage, $data[-1] );
}
close $covbed;

#dd \%coverage_data;

my %median_coverage;
for my $amplicon( sort keys %coverage_data ) {
    $median_coverage{ join( ":", $amplicon, scalar(@{$coverage_data{$amplicon}} ) )} = median( \@{$coverage_data{$amplicon}} );
}

#dd \%median_coverage;
#exit;

# Make tables of All Amplicon and Low Amplicon Coverage
print $aa_fh "Amplicon\tGene\tMedian\tLength\n";
print $low_fh "Amplicon\tGene\tMedian\tLength\n";

my $low_total = 0;
for my $amplicon( keys %median_coverage ) {
    my ( $ampid, $gene, $length ) = split( /:/, $amplicon );
    my $outstring = join( "\t", $ampid, $gene, $median_coverage{$amplicon}, $length );
    print $aa_fh "$outstring\n";

    if ( $median_coverage{$amplicon} < $threshold ) {
        print $low_fh "$outstring\n";
        $low_total++;
    }
}

close $aa_fh;
close $low_fh;

# Get quartile coverage data and create output file
my ( $quart1, $quart2, $quart3 ) = quartile_coverage( \@all_coverage );

printf $summary_fh "Sample name: %s\n", $sample_name;
printf $summary_fh "Total number of mapped reads: %d\n", $num_reads;
printf $summary_fh "Total number of amplicons: %d\n", scalar( keys %median_coverage );
printf $summary_fh "Number of amplicons below the threshold: %d\n", $low_total;
printf $summary_fh "Percent of amplicons below the threshold: %.2f%%\n", ($low_total/scalar(keys %median_coverage)) * 100;
printf $summary_fh "25%% Quartile Coverage: %d\n", $quart1;
printf $summary_fh "50%% Quartile Coverage: %d\n", $quart2;
printf $summary_fh "75%% Quartile Coverage: %d\n", $quart3;
close $summary_fh;

sub median {
    # Create a median function in order to prevent having to use non-core modules
    my $data = shift;

    my @sorted_list = sort { $a <=> $b } @$data;
    my $length = @sorted_list;
    if ( $length%2 ) {
        return $sorted_list[int($length/2)];
    } else {
        return ($sorted_list[int($length/2)-1] + $sorted_list[int($length/2)])/2;
    }
}

sub quartile_coverage {
    # Homebrew Quartile function to avoid non-core modules
    my $data = shift;

    my @sorted_list = sort { $a <=> $b } @$data;

    my $second_quartile = median( $data );
    my @lower_half = grep { $_ < $second_quartile } @sorted_list;
    my @upper_half = grep { $_ > $second_quartile } @sorted_list;
    my $first_quartile = median( \@lower_half );
    my $third_quartile = median( \@upper_half );

    return( $first_quartile, $second_quartile, $third_quartile );    
}

sub proc_bed {
    my $input_bed = shift;
    (my $new_name = $$input_bed) =~ s/(.*?)\.bed/$1_clean.bed/;
    my $output_bed = "$outdir/$new_name";

    open( my $fh, "<", $$input_bed ) || die "Can't open the BED file for processing: $!";
    open( my $out_fh, ">", $output_bed ) || die "Can't create the new BED file: $!";

    while (<$fh>) {
        if ( /track/ ) {
            print $out_fh $_;
            next;
        }

        my @fields = split;
        my ($gene, $pool) = $fields[7] =~ /GENE_ID=(.*);SUBMITTED_REGION=(.*)$/;

        print $out_fh join( "\t", @fields[0..3], $pool, $gene ), "\n";
    }
    close $fh;
    close $out_fh;

    return $output_bed;
}
