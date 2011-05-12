package DntPrijava;
use base 'CGI::Application';
#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use strict;
use DBI;
#use HTML::Template;
#use CGI::Session;
#use Data::Dumper;
use DntFunkcije;
use Digest::MD5 qw(md5_hex);

sub setup {

    my $self = shift;
    #$self->dbh_config("dbi:PgPP:dbname=donator;host=localhost", "postgres", "ni2mysql");
    #$self->start_mode('ZaposleniSeznam');    
    $self->run_modes(
        'prijava' => 'PrijavaVnos',
		'Prijavi' => 'Prijavi',
		'registracija' => 'NovUporabnik',
		'uspeh' => 'Uspesna',
		'odjavi' => 'Odjavi'
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub PrijavaVnos{
	my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');
	my $uspeh= $q->param('uspeh');
	my $returnUrl= $q->param('url');
	my $gumb="Prijavi";
	my $html_output ;
	my $menu_pot;
	my $template;
	my $uporabnik;
	my $logged =0;
	my $cookie;
	my @cookies = split(";", $ENV{'HTTP_COOKIE'});
	foreach my $ck (@cookies){
		
		if(substr($ck, 0, 3) eq "id="){
			$cookie = $ck;
		}
	}
	#return $cookie;
	if (!defined $cookie){
		
		$cookie="1";
	}
	else{
		$cookie = substr ($cookie, 3);
		my @arr = split(",", $cookie);
		my $dbh;
		my $res;
		my $sql;
		my $sth;
		$dbh = DntFunkcije->connectDB;
		if ($dbh) {
			$sql = "select * FROM uporabniki WHERE id_uporabnik=? AND geslo=?";
			$sth = $dbh->prepare($sql);
			#return $geslo." ".$ime;
			$sth->execute($arr[0], $arr[1]);

			if($res = $sth->fetchrow_hashref){
				$logged =1;
				$uporabnik=DntFunkcije::trim($res->{'uporabnik'});
			}
		}
		
	}
	
	if(defined $uspeh && $uspeh != 1){
		$uspeh = 0;
	}

    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntPrijava.tmpl',
			      cache => 1,
			     );
    $template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'Prijava',
		uporabnik => $uporabnik,
		logged => $logged ,
		return => $returnUrl,
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
	);
    $html_output = $template->output; #.$tabelica;
	return $html_output;
}

sub Prijavi{
	my $self = shift;
    my $q = $self->query();
	my $id;
	my $ime=  $q->param('edb_ime');
	my $geslo= $q->param('edb_geslo');
	my $geslo2= $q->param('edb_geslo');
	my $zapomni= $q->param('edb_zapomni');
	my $returnUrl= $q->param('url');
	my $gumb="Prijavi";
	my $html_output ;
	my $menu_pot;
	my $template;
	my $uporabnik;

	my $dbh;
	my $res;
	my $sql;
	my $sth;
	
	my $cookie = $ENV{'HTTP_COOKIE'};
	
	if (!defined $cookie){
		
		$cookie="1";
	}
	else{
		$cookie="0";
	}
	
	$dbh = DntFunkcije->connectDB;
	
	if ($dbh) {
		$sql = "select * FROM uporabniki WHERE uporabnik=? AND geslo=?";
		$sth = $dbh->prepare($sql);
		$geslo=md5_hex($geslo);
		#return $geslo." ".$ime;
		$sth->execute($ime, $geslo);
		
		if($res = $sth->fetchrow_hashref){
			
			#NASTAVI COOKIE
			$id = $res->{'id_uporabnik'};
			#return $id;
			my $cookie= "Set-Cookie:id=";
			$cookie.="$id,$geslo";
			if(defined $zapomni && $zapomni>0){
				$cookie.="; expires=".localtime(time+60*60*16);
			}
			$cookie.="\n";
			print $cookie;
			my $redirect_url="DntStart.cgi?rm=";
			if($returnUrl){
				$redirect_url.=$returnUrl;
			}
			else{
				$redirect_url="DntPrijava.cgi?rm=prijava&uspeh=1";
			}
			$self->header_type('redirect');
			$self->header_props(-url => $redirect_url);
			return $redirect_url;
		}
		else{
			if (defined $zapomni && $zapomni==1){
				$zapomni="checked='checked'";
			}
			else{
				$zapomni="";
			}
			my $seja;
			$menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek");
			$template = $self->load_tmpl(	    
								  'DntPrijava.tmpl',
						  cache => 1,
						 );
			$template->param(
				#MENU_POT => $menu_pot,
				IME_DOKUMENTA => 'Napacno uporabnisko ime ali geslo!',
				MENU => DntFunkcije::BuildMenu(),
				edb_ime=>$ime,
				edb_zapomni=>$zapomni,
				edb_geslo=>"",
				#edb_cookie=>$cookie,
				
			);
			
			$html_output = $template->output; #.$tabelica;
			return $html_output;
					
		}
	}
}

sub NovUporabnik{
	my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');
	my $ime= $q->param('edb_ime');
	my $geslo= $q->param('edb_geslo');
	my $zapomni= $q->param('edb_zapomni');
	my $gumb="Shrani";
	my $html_output ;
	my $menu_pot;
	my $template;
	my $uporabnik;

	my $dbh;
	my $res;
	my $sql;
	my $sth;
	
	$dbh = DntFunkcije->connectDB;
	
	if ($dbh) {
		$sql = "INSERT INTO uporabniki (uporabnik, geslo) VALUES (?, ?)";
		$sth = $dbh->prepare($sql);
		$sth->execute($ime, $geslo);
		if($res = $sth->fetchrow_hashref){
			
			$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek");
			$template = $self->load_tmpl(	    
								  'DntPrijava.tmpl',
						  cache => 1,
						 );
			$template->param(
				#MENU_POT => $menu_pot,
				IME_DOKUMENTA => 'Registracija je uspela!'.$uporabnik,
				edb_ime=>$ime,
				edb_zapomni=>$zapomni,
				edb_geslo=>$geslo,
			);
			$html_output = $template->output; #.$tabelica;
			return $html_output;
		}
		else{
			$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
			$template = $self->load_tmpl(	    
								  'DntPrijava.tmpl',
						  cache => 1,
						 );
			$template->param(
				#MENU_POT => $menu_pot,
				IME_DOKUMENTA => 'Registracija ni uspela!'.$uporabnik,
				edb_ime=>$ime,
				edb_zapomni=>$zapomni,
				edb_geslo=>$geslo,					 
			);
			$html_output = $template->output; #.$tabelica;
			return $html_output;
					
		}
	}
}

sub Odjavi(){
	my $self = shift;
    my $q = $self->query();
	my $cookie= "Set-Cookie:id=";
	$cookie.="; expires=-1";

	$cookie.="\n";
	print $cookie;
	my $redirect_url="DntStart.cgi?rm=";
	$redirect_url="DntPrijava.cgi?rm=prijava&uspeh=1";
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
}


1;    # Perl requires this at the end of all modules