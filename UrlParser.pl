#!/usr/bin/perl -w
#programme qui permet d'automatiser la recherche d'éventuels repertoire d'administration sur un site défini
#Usage: ./UrlParser.pl -s http://www.google.com -f results.txt
use strict;
use Getopt::Std;#module utilisé pour la gestion des arguments
use LWP::UserAgent;#requêtes http
use MIME::Base64;#envoi des données user et password sous forme encodée pour http
#use Crypt::SSLeay;#permettre la gestion de http over ssl

#gestion des paramètres
my %opts = ();#hash qui contiendra les paramètres du programme
getopt("s:f:" , \%opts);
my $opt = 0;

#compte factice pour tenter l'authentification sur le site web donné, la connexion peut aussi être un succès...
my $credentials = "admin:password";

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

  my ($url , $base) = ($opts{s} , "");
  my $alt_port = 8080;

  if ($url =~ m/\/\//) {

    #suppression du dernier "/" si celui-ci est présent dans l'url donnée
    if($url =~ /\/$/) {
      chop($url);
    }

    my @extensions = (".php" , ".asp" , ".aspx" , ".jsp" , ".html");
    my @admin_url = (
                  "/admin",
                  "/administration",
                  "/admin_panel",
                  "/adminpanel",
                  "/administrator",
                  "/admin_url",
                  "/admin-login",
                  "/admin-url",
                  "/admin-panel",
                  "/administration_panel",
                  "/administration-panel",
                  "/adm",
                  "/adm_url",
                  "/admin_login",
                  "/login",
                  "/login_panel",
                  "/login-panel",
                  "/administrator_panel",
                  "/auth",
                  "/auth-login",
                  "/auth_login",
                  "/authentication",
                  #wordpress url
                  "/wp-admin",
                  "/wp-login"
                  );

    foreach (@admin_url) {

      my $try = "$url$_";
      my $alt = "$url:$alt_port$_";

      #on initialise la requête
      #preparation de la requête avec le UserAgent
      my $ua = LWP::UserAgent->new();

      my $req = HTTP::Request->new( GET => $try );
      my $alt_req = HTTP::Request->new( GET => $alt );

      #gestion des token d'authentification
      my $token = encode_base64($credentials);
      $req->header( Autorization => "Basic $token" );
      $alt_req->header( Autorization => "Basic $token" );

      #on demarre la requête
      print "*[CHECK] Tentative avec l'url $try\n";
      my $response = $ua->request($req);

      #print "*[CHECK] Tentative avec l'url $alt\n";
      #my $alt_res = $ua->request($alt_req);
      #print $alt_res."\n";

      if ($response->is_success) {
        #print $response->decoded_content;-->réponse de la requête, affiche le code source de la page html, étudier son contenu

      } else {
        print STDERR $response->get_status;
      }

    }

  } else {
    my $usage = usage();
    die "$usage";
  }

  #my @admin_url = ("http://");
}

if ($opt == 2) {
  try_admin();
  #log_results("tested\n");
} else {
  try_admin();
}
