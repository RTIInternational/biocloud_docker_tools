#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $dir = dirname(__FILE__);
my $inDockerfileTemplate = $dir.'/Dockerfile_template';
my $inS3FileList = $dir.'/s3_files.tsv';
my $outDockerFile = $dir.'/Dockerfile';
my $presignedURLExpiration = 8640;

GetOptions (
    'in_dockerfile_template:s' => \$inDockerfileTemplate,
    'in_s3_files:s' => \$inS3FileList,
    'out_dockerfile:s' => \$outDockerFile,
    'presigned_url_expiration:i' => \$presignedURLExpiration
) or die("Invalid options");

# Get presigned URLs for S3 files
my %s3Files = ();
open(S3_FILES, $inS3FileList);
while(<S3_FILES>) {
    chomp;
    my @F = split;
    $s3Files{$F[0]} = `aws s3 presign $F[1] --expires-in $presignedURLExpiration`;
    $s3Files{$F[0]} =~ s/\n//;
}
close S3_FILES;

# Open output Dockerfile
open(DOCKERFILE, "> $outDockerFile");
open(TEMPLATE, $inDockerfileTemplate);
while(<TEMPLATE>) {
    foreach my $key (keys(%s3Files)) {
        s/$key/$s3Files{$key}/;
    }
    print DOCKERFILE $_;
}
close TEMPLATE;
close DOCKERFILE;
