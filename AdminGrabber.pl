#!/usr/bin/perl -w
#programme qui permet d'automatiser la recherche d'éventuels repertoire d'administration sur un site défini
#Usage: ./AdminGrabber.pl -s http://www.google.com -f results.txt
use strict;
use Getopt::Std;#module utilisé pour la gestion des arguments
use LWP::UserAgent;#requêtes http
use MIME::Base64;#envoi des données user et password sous forme encodée pour http

#gestion des paramètres
my %opts = ();#hash qui contiendra les paramètres du programme
getopt("s:f:i:" , \%opts);
my $opt = 0;

#compte factice pour tenter l'authentification sur le site web donné, la connexion peut aussi être un succès...
my $credentials = "admin:password";

#utilisation du programme
sub usage {

  die "$0 -s http://www.google.com -f results.txt\n-s: url du site cible\n-f (optionnel): fichier de log\n-i (optionnel): fichier contenant des url a tester\n";

}

if (defined($opts{i}) and defined($opts{s}) and defined($opts{f})) {
  $opt = 3;
} elsif (defined($opts{s}) and defined($opts{f}) and !defined($opts{i})) {
  $opt = 2;
} elsif (defined($opts{s}) and !defined($opts{f})) {
  $opt = 1;
} else {
  usage();
}

sub log_results {

  my ($result) = @_;

  if ($opt == 2 or $opt == 3) {

    open(RESULT , ">>" , "$opts{f}") or die "Impossible d'ouvrir le fichier $opts{f} pour ecriture: $!\n";
    print RESULT $result;
    close(RESULT);

  }

  print "$result";

}

#nouvelle fonction qui permettra d'injecter les nouvelles url contenues dans le fichier fourni en paramètre -i
sub inject_url {

  my @inject;

  if (defined($opts{i})) {

    if (-e "$opts{i}") {

      open(URLIST , "<" , $opts{i}) or die "Impossible d'ouvrir le fichier $opts{i} pour lecture: $!\n";
      while(<URLIST>) {

        chomp;
        $_ = join("" , (split(" " , $_))[0]);
        my $line;

        if (/\/$/) { chop($_); }

        if (/(\/)+/) {

          if (m!^\/!) {
            $line = "$_";
          } else {
            $line = "/$_";
          }

          push(@inject , $line);

        } else {

          if(/.(php|html|asp|aspx|jsp|htm)/){#omission de \%EXT\%
            $line = "/$_";
            push(@inject , $line);
          }

        }

      }

      close(URLIST);

    } else {
      print "*Le fichier $opts{i} n'existe pas\n";
      exit 0;
    }

  }

  return @inject;

}

sub try_admin {

  my ($url , $base) = ($opts{s} , "");
  #my $alt_port = 8080;#recherche future avec d'autres ports standards

  if ($url =~ m/\/\//) {

    #suppression du dernier "/" si celui-ci est présent dans l'url donnée
    if($url =~ /\/$/) { chop($url); }

    my @target_url;#tableau contenant toutes les URL a tester
    my @extensions = qw (.php .asp .aspx .jsp .html .htm);
    my @wordpress_url = ("/wp-admin" , "/wp-login");
    my @admin_url = (
                  "/admin",
                  "/admin/admin",
                  "/auth/admin",
                  "/login",
                  "/admin/login",
                  "/login/login",
                  "/auth/login",
                  "/administration",
                  "/admin/administration",
                  "/login/administration",
                  "/admin_panel",
                  "/admin/admin_panel",
                  "/login/admin_panel",
                  "/adminpanel",
                  "/administrator",
                  "/admin_url",
                  "/admin-login",
                  "/admin-url",
                  "/admin-panel",
                  "/admin_panel",
                  "/adminpanel",
                  "/administration_panel",
                  "/administration-panel",
                  "/admin_login",
                  "/login_panel",
                  "/admin/login_panel",
                  "/login/login_panel",
                  "/login-panel",
                  "/admin/login-panel",
                  "/login/login-panel",
                  "/auth",
                  "/auth-login",
                  "/auth_login",
                  "/admin/auth_login",
                  "/login/auth_login",
                  "/auth/auth_login",
                  "/authentication"
                  );

    print "*Mise a jour des url de recherche...\n";

    my $len = @admin_url;
    my $len_ = @extensions;
    my $var;
    my $var_;

    #decommenter pour prendre en compte la possibilite d'une redirection automatique
    #@target_url = @admin_url;
    for ($var = 0; $var < $len; $var++) {
      for ($var_ = 0; $var_ < $len_; $var_++) {
        my $extended_url = "$admin_url[$var]$extensions[$var_]";
        push(@target_url , $extended_url);
      }
    }

    #url pour tester aussi ce qu'il y a de plus commun concernant wordpress
    push(@target_url , @wordpress_url);

    #injection des url fournies en plus
    my @opt_url = inject_url();

    if (@opt_url != 0) {

      print "*Rajout des url fournies au programme\n";

      $len = @target_url;
      $len_ = @opt_url;
      my $var;
      my $var_;

      for ($var_ = 0; $var_ < $len_; $var_++) {

        for ($var = 0; $var < $len; $var++) {

          if (defined $opt_url[$var_]) {

            my $added_url = $opt_url[$var_];
            if ($added_url eq $target_url[$var]){
              splice(@opt_url , $var_ , 1);
            }

          }

        }

      }
      push(@target_url , @opt_url);
    }

    print "*Debut de l'analyse sur l'url donnee...\n";

    #requête pour chaque url cible
    foreach (@target_url) {

      my $try = "$url$_";

      #preparation de la requête avec le UserAgent
      my $ua = LWP::UserAgent->new();
      my $req = HTTP::Request->new( GET => $try );

      #gestion des token d'authentification si une demande d'authentification est initialisee
      my $token = encode_base64($credentials);
      $req->header( Autorization => "Basic $token" );

      #on demarre la requête
      print "*[CHECK] Tentative avec l'url $try\n";
      my $response = $ua->request($req);

      #prevention contre les eventuelles redirections
      my $redirection_status = 0;
      if (defined $response->previous) {
        my $location = $response->previous->header( 'Location' );
        $redirection_status = 1;
      }

      if ($redirection_status == 0) {

        if ($response->is_success) {

          my $page = $response->decoded_content;#réponse de la requête, affiche le code source de la page html
          my @target_keyword = ("[aA]dmin" , "[lL]ogin :" , "[pP]assword" , "authentication" , "administration" , "Index\ of");

          #recherche des mots clés
          my $keyword;
          foreach $keyword (@target_keyword) {

            if ($page =~ /$keyword/) {

              my $log = "\t*Page admin potentielle trouvee a l'emplacement suivant: $try.\n";
              log_results($log);

              #decommenter pour mettre fin a la recherche si on ne veut garder qu'un seul resultat
              #return 0;
            }

          }

        } else {
          #print STDERR $response->message."\n";
          my $status = $response->message;

          if ($status =~ /Forbidden/) {
            my $log = "*Le site indique \"$status\", une page eventuelle d'administration peut exister a cet emplacement ($try)\n";
            print "$log";
            log_results($log);
          }

        }

      }

    }

  } else {
    usage();
  }

}

try_admin();
print "Fin de la recherche\n";
