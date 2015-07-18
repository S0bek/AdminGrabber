#!/usr/bin/perl -w
#programme qui permet d'automatiser la recherche d'éventuels repertoire d'administration sur un site défini
#Usage: ./UrlParser.pl -s http://www.google.com -f results.txt
use strict;
use Getopt::Std;#module utilisé pour la gestion des arguments
#http request use

#gestion des paramètres
my %opts = ();#hash qui contiendra les paramètres du programme
getopt("s:f:" , \%opts);
my $opt = 0;

#utilisation du programme
sub usage {

  my $usage = "./UrlParser.pl -s http://www.google.com -f results.txt\n-s: url du site cible\n-f (optionnel): fichier de log\n";
  return $usage;

}

if (defined($opts{s}) and defined($opts{f})) {
  $opt = 2;
} elsif (defined($opts{s})) {
  $opt = 1;
} else {
  my $usage = usage();
  die "$usage";
}

sub log_results {

  my ($result) = @_;

  if ($opt == 2) {

    open(RESULT , ">" , "$opts{f}") or die "Impossible d'ouvrir le fichier $opts{f} pour ecriture: $!\n";
    print RESULT $result;
    close(RESULT);

  }

}

sub try_admin {
  
}

if ($opt == 2) {

  #log_results("tested\n");
}
