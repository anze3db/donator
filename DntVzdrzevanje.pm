package DntVzdrzevanje;
use base 'CGI::Application';
#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use strict;
use DBI;


#use HTML::Template;
#use CGI::Session;
#use Data::Dumper;

use Digest::MD5 qw(md5_hex);
use DntFunkcije;
sub cgiapp_prerun {
	
    my $self = shift;
    my $q = $self->query();
	my $nivo='r';
	my $str = $q->param('rm');
	#nastavi write nivo funkcij, ki zapisujejo v bazo:
	if ($str eq 'Shrani' || $str eq 'zbrisi' || $str eq 'uredi'){
		$nivo = 'w';
	}
	
    my $user = DntFunkcije::AuthenticateSession(43, $nivo);
	# Redirect to login, če uporabnik ni prijavljen
	if($user == 0){    
        $self->prerun_mode('login');
    }
	# Redirect to error, če nima pravic za ogled strani
	elsif($user == -1){    
        $self->prerun_mode('error');
    }	
}

sub setup {

    my $self = shift;
    #$self->dbh_config("dbi:PgPP:dbname=donator;host=localhost", "uporabnikgres", "ni2mysql");

    
    $self->run_modes(
        'seznam' => 'VzdrzevanjeSeznam',
		'izpisi' => 'VzdrzevanjeSeznam',
		'poslji' => 'VzdrzevanjePoslji',
		'Shrani' => 'VzdrzevanjeShrani',
		'zbrisi' => 'VzdrzevanjeZbrisi',
		'Preusmeri' => 'Preusmeri',
		'login' => 'Login',
		'error' => 'Error'
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub VzdrzevanjeSeznam{
	
    my $self = shift;
    my $q = $self->query();

	my $dbh;
	my $res;
	my $sql;
	my $sth;
	
	my $DONATOR = "1.1.1";

	
    # Fill in some parameters	
    my $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek");
	my $template = $self->load_tmpl(	    
		'DntVzdrzevanje.tmpl',
		 cache => 0,
   );
	

	my @versions = (
			{modul => 'Apache::Request', version => $q->strong($Apache::Request::VERSION)},
			{modul => 'Apache::Registry', version => $q->strong($Apache::Registry::VERSION)},
			{modul => 'base', version => $q->strong($base::VERSION)},			 
			{modul => 'CGI ', version => $q->strong($CGI::VERSION)},
			{modul => 'CGI::Application ', version => $q->strong($CGI::Application::VERSION)},
			{modul => 'DBD::Pg', version => $q->strong($DBD::Pg::VERSION)},
			{modul => 'DBI ', version => $q->strong($DBI::VERSION)},
			{modul => 'HTML template', version => $q->strong($HTML::Template::VERSION)},
			{modul => 'Net::Daemon', version => $q->strong($Net::Daemon::VERSION)},
			{modul => 'RPC::PlClient', version => $q->strong($RPC::PlClient::VERSION)},			
			{modul => 'RPC::PlServer', version => $q->strong($RPC::PlServer::VERSION)},

			
           );
	
	$template->param(
		IME_DOKUMENTA => 'Vzdzevanje',
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		perl => $q->strong($]),
		mod_perl => $q->strong($mod_perl::VERSION),
		list => \@versions,
		MENU => DntFunkcije::BuildMenu(),
		DONATOR => $DONATOR,


	);

	#Ce so se parametri za poizvedbo izpise rezultat

    my $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}

sub VzdrzevanjePoslji(){
	my $self = shift;
    my $q = $self->query();
	
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	
	(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) =
					localtime();
	$year += 1900;
	$mon += 1;
	$mon = sprintf('%02d', $mon);
	$mday = sprintf('%02d', $mday);
	$hour = sprintf('%02d', $hour);
	$min = sprintf('%02d', $min);
	$sec = sprintf('%02d', $sec);
	my $shortYear = substr($year, 2, 2);
	my $davcnaSt = 99999999;
	my $vsota = 0.0;
	my $file;
	my @items = $q->param('items');
	my %item;
	my $it;
	my $stTransakcij = 0;
	my $stTrIzpis;
	my $znesek = 0.0;

	my $datum = $year.$mon.$mday;
	foreach my $item (@items){
		
		if(%item = getItems($item)){
			
			$vsota += $item{'znesek'};
			$stTransakcij++;
			
		$davcnaSt = $item{'davcnaSt'};
		
		$it .= "04".$item{'idZapisa'}."0".$datum.$item{'znesek'}."978".$item{'racunKomitenta'}.
				 $item{'referencnaSt'}.$item{'namen'}.$item{'sifraNakazila'}.$item{'poravnalniRacun'}.$item{'enota'}.
				 $item{'vrstaPosla'}.$item{'partija'}.$item{'sifraPrejemnika'}.$item{'vrstaInformacije'}.$item{'status'}.
				 $item{'sifraKonta'}.$item{'frekvenca'}.$item{'zapStUpn'}.$item{'zapStDol'}.$item{'operater'}."\n";
		}	
	}
	my $s1 = "02";
	my $pp = "01";
	my $stPaketa = $davcnaSt.$shortYear.$mon.$mday.$s1.$pp;
	my $prazno = sprintf('%152s', "");
	
	$file = "09".$stPaketa."0000000".$year.$mon.$mday.$hour.$min.$sec.$prazno."\n";
	$file .= $it;

	$vsota = sprintf('%013d%02d', int($vsota), substr($vsota, -2, 2));
	$znesek = sprintf('%015d',$znesek);
	$prazno = sprintf('%140s', "");
	
	$stTrIzpis = sprintf('%06d', $stTransakcij);
	$file .= "99".$stPaketa.$stTrIzpis."0".$datum.$vsota."978".$prazno."\n";
	
	$q->header(-type=>'application/octet-stream', -attachment=>'NIDB'.$davcnaSt.'.IN');	
	return $file;
}
sub getItems{
		
		my $item = shift;
		
		my $idZapisa="";
		my $racunKomitenta="";
		my $referencnaSt="";
		my $namen="";
		my $sifraNakazila="";
		my $poravnalniRacun="";
		my $enota=0;
		my $vrstaPosla=0;
		my $partija=0;
		my $sifraPrejemnika="";
		my $vrstaInformacije=0;
		my $status=0;
		my $sifraKonta=0;
		my $frekvenca=0;
		my $zapStUpn=0;
		my $zapStDol=0;
		my $operater="";
		my $znesek = 0.0;
		my $davcnaSt = "";

		
		my $dbh;
		my $sql;
		my $res;
		my $sth;
		
		(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) =
					localtime();
		$year += 1900;
		$mon += 1;
		$mon = sprintf('%02d', $mon);
		$mday = sprintf('%02d', $mday);
		$hour = sprintf('%02d', $hour);
		$min = sprintf('%02d', $min);
		$sec = sprintf('%02d', $sec);


		
		$dbh = DntFunkcije::connectDB();
		if($dbh){
			$sql = "SELECT p.*, pr.*, a.bank_account2, a.frequency, a.zap_st_dolznika ".
				   "FROM agreement_pay_installment as p, sfr_agreement as a, sfr_project as pr ".
				   "WHERE p.id_vrstica= ? AND a.id_agreement = p.id_agreement AND p.id_project = pr.id_project";
			$sth = $dbh->prepare($sql);
	        $sth->execute($item);
	        if($res = $sth->fetchrow_hashref) {
				
				
				$referencnaSt = $res->{'id_agreement'};
				$referencnaSt = sprintf('%20s', $referencnaSt);
				
				$namen = sprintf('%35s', $namen);
				
				$sifraNakazila = sprintf('%3s', $sifraNakazila);
				
				$racunKomitenta = sprintf('%18s', $racunKomitenta);
				
				$poravnalniRacun = $res->{'bank_account2'};
				$poravnalniRacun =~ s/ //g;
				$poravnalniRacun= sprintf('%15s', $poravnalniRacun);
				
				$enota = sprintf('%03d', $enota);
				
				$vrstaPosla = sprintf('%02d', $vrstaPosla);
			
				$partija = sprintf('%010d', $partija);
				
				$sifraPrejemnika = sprintf('%5s', $sifraPrejemnika);
				
				$vrstaInformacije = sprintf('%02d', $vrstaInformacije);
				
				$status= sprintf('%02d', $status);
				
				$sifraKonta = sprintf('%03d', $sifraKonta);
				
				$frekvenca = $res->{'frequency'};
				$frekvenca = sprintf('%02d', $frekvenca);
				
				$zapStUpn = $res->{'zap_st_upnika'} || 0;
				$zapStUpn = sprintf('%05d', $zapStUpn);
				
				$zapStDol = $res->{'zap_st_dolznika'};
				$zapStDol = sprintf('%010s', $zapStDol);
				
				$operater = sprintf('%5s', $operater);
				
				$davcnaSt = DntFunkcije::trim($res->{'tax_number'});
				$znesek = $res->{'amount'};
				$znesek = sprintf('%013d%02d', int($znesek), substr($znesek, -2, 2));

			}
			my $shortYear = substr($year, 2, 2);
			my $s1 = "02";
			my $pp = "01";
			$idZapisa = $davcnaSt.$shortYear.$mon.$mday.$s1.$pp."000001";

			return ('idZapisa'=>$idZapisa,
					'referencnaSt'=>$referencnaSt,
					'namen'=>$namen,
					'sifraNakazila'=>$sifraNakazila,
					'racunKomitenta'=>$racunKomitenta,
					'poravnalniRacun'=>$poravnalniRacun,
					'enota'=>$enota,
					'vrstaPosla'=>$vrstaPosla,
					'partija'=>$partija,
					'sifraPrejemnika'=>$sifraPrejemnika,
					'vrstaInformacije'=>$vrstaInformacije,
					'status'=>$status,
					'sifraKonta'=>$sifraKonta,
					'frekvenca'=>$frekvenca,
					'zapStUpn'=>$zapStUpn,
					'zapStDol'=>$zapStDol,
					'operater'=>$operater,
					'znesek'=>$znesek,
					'davcnaSt'=>$davcnaSt,
					);
		}
}
1;    # Perl requires this at the end of all modules
