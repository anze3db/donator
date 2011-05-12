package DntPomoc;
use base 'CGI::Application';
#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use strict;
use DBI;
#use HTML::Template;
#use CGI::Session;
#use Data::Dumper;
use DntFunkcije;

sub cgiapp_prerun {
	
    my $self = shift;
    my $q = $self->query();
	my $nivo='r';
	my $str = $q->param('rm');
	#nastavi write nivo funkcij, ki zapisujejo v bazo:
	if ($str eq 'uredi' || $str eq 'shrani'){
		$nivo = 'w';
	}
	
    my $user = DntFunkcije::AuthenticateSession(61, $nivo);
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
    #$self->dbh_config("dbi:PgPP:dbname=donator;host=localhost", "postgres", "ni2mysql");
    #$self->start_mode('ZaposleniSeznam');
    
    $self->run_modes(
        'seznam' => 'PomocSeznam',
		'uredi' => 'PomocUredi',
		'shrani' => 'PomocShrani',
		'login' => 'Login',
		'error' => 'Error'
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub PomocSeznam{
	
    my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');	
	my $html_output ;
	my $menu_pot;
    my $template;
	my $id=$q->param('id');
	my $besedilo;
	my $ustvarjeno;
	my $stran;

    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntPomocIzpis.tmpl',
			      cache => 1,
			     );
    
	#Ce so se parametri za poizvedbo izpise rezultat

	my $dbh;
	my $res;
	my $sql;
	my $sth;
	my $status;
	
	
	
	$dbh = DntFunkcije->connectDB;
	 	
	if ($dbh) {
		$sql="SELECT * FROM pomoc WHERE stran ilike '$id%'";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		if($res = $sth->fetchrow_hashref) {					
			
			$besedilo=DntFunkcije::trim($res->{'besedilo'});
			$ustvarjeno=DntFunkcije::trim($res->{'ustvarjeno'});
			$stran=DntFunkcije::trim($res->{'stran'});
			$status="spremeni";
		}
		else{
			$besedilo="Za podstran pomoc se ni bila napisana!";
			$ustvarjeno="/";
			$status="dodaj";
		}
	}
	else{
		return 'Povezava do baze ni uspela';
	}
    $besedilo=~s/\n/\n<br \/>/g;
	$id=~s/Prikazi/seznam/g;
	if($ustvarjeno>0){
		$ustvarjeno=substr($ustvarjeno, 8,2)."/".
					substr($ustvarjeno, 5,2)."/".
					substr($ustvarjeno, 0,4);
	}
	$template->param(
		     #MENU_POT => $menu_pot,
			 IME_DOKUMENTA => "Pomoc",
			 besedilo => $besedilo,
			 ustvarjeno => $ustvarjeno,
			 stran=>$id,
			 status => $status,
		     );
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	
    
}
sub PomocShrani{
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $besedilo = $q->param('besedilo');
	my $ime = $q->param('edb_ime');
	my $uporabnik = $q->param('edb_uporabnik');
	my $id = $q->param('id');
	my $status = $q->param('status');
	my $menu_pot ;
	my $template ;

	my $dbh;
	my $sql;
	my $sth;
	my $res;
	
	my $redirect_url="?rm=seznam&amp;id=$id";
	(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) =
    localtime(time);
	$year+=1900;
	$mon++;
	my $date="$year/$mon/$mday";
	
	$dbh = DntFunkcije->connectDB;
	
		
		if ($dbh) {
			if($status eq "spremeni"){
				
			$sql = "UPDATE pomoc SET besedilo='$besedilo', ustvarjeno='$date'".
					   "WHERE stran='$id'";
			#print $q->p($sql_vprasaj);
				$sth = $dbh->prepare($sql);
				unless($sth->execute()){
				
					my $napaka_opis = $sth->errstr;
                    $template = $self->load_tmpl(	    
                        'DntDodajSpremeni.tmpl',
					cache => 1,
					);
                    $template->param(
                                    MENU_POT => '',
                                    IME_DOKUMENTA => 'Napaka !',
                                    napaka_opis => $napaka_opis,
                                    akcija => ''
                                     );
            
                    $html_output = $template->output; #.$tabelica;

                    return $html_output;	
				}	
				
			}
			else{
				$sql = "INSERT INTO pomoc (stran, besedilo, ustvarjeno) ".
					   "VALUES ('$id', '$besedilo', '$date')";
			#print $q->p($sql_vprasaj);
				$sth = $dbh->prepare($sql);
				unless($sth->execute()){
					
					my $napaka_opis = $sth->errstr;
                    $template = $self->load_tmpl(	    
                        'DntDodajSpremeni.tmpl',
					cache => 1,
					);
                    $template->param(
                                    MENU_POT => '',
                                    IME_DOKUMENTA => 'Napaka !',
                                    napaka_opis => $napaka_opis,
                                    akcija => ''
                                     );
            
                    $html_output = $template->output; #.$tabelica;
                    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
                    return $html_output;
				}
			}	
		
		}
		$sth->finish;
		$dbh->disconnect();
		
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
}
	

sub PomocUredi{
	my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');	
	my $html_output ;
	my $menu_pot;
	my $besedilo;
	my $ustvarjeno;
	my $stran;
	my $id = $q->param('id');
	my $status = $q->param('status');
	my $uporabnik = $q->param('uporabnik');
	my $template;
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntPomocUredi.tmpl',
			      cache => 1,
			     );
	#Ce so se parametri za poizvedbo izpise rezultat
    my $dbh;
	my $res;
	my $sql;
	my $sth;

	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		if($status eq "spremeni"){
			
			$sql="SELECT * FROM pomoc WHERE stran ilike '$id%'";
			$sth = $dbh->prepare($sql);
			$sth->execute();
			if($res = $sth->fetchrow_hashref) {					
				$besedilo=DntFunkcije::trim($res->{'besedilo'});
				$ustvarjeno=DntFunkcije::trim($res->{'ustvarjeno'});
				$stran=DntFunkcije::trim($res->{'stran'});
			}
		}
	}	
	else{
		return 'Povezava do baze ni uspela';
	}
	if($ustvarjeno>0){
		$ustvarjeno=substr($ustvarjeno, 8,2)."/".
					substr($ustvarjeno, 5,2)."/".
					substr($ustvarjeno, 0,4);
	}
	$template->param(
		     #MENU_POT => $menu_pot,
			 IME_DOKUMENTA => "Pomoc",
			 besedilo => $besedilo,
			 ustvarjeno => $ustvarjeno,
			 stran=>$id,
			 status => $status,
		     );
			

    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
}
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'uporabniki';
	my $redirect_url="DntPrijava.cgi?rm=prijava&url=$return_url";
	$self->header_type('redirect');
    $self->header_props(-url => $redirect_url);
	return $redirect_url;
}
#če uporabnik nima dostopa do strani:
sub Error(){
	
	my $self = shift;	
	my $q = $self->query();
	my $napaka_opis = "Za izvedbo operacije nimate ustreznih pravic!";
	my $template;
	$template = $self->load_tmpl(	    
		'DntDodajSpremeni.tmpl',
	cache => 1,
	);
	$template->param(
		#MENU_POT => '',
		IME_DOKUMENTA => 'Napaka!',
		napaka_opis => $napaka_opis,
		akcija => ''
	);

	my $html_output = $template->output; #.$tabelica;
	return $html_output;
}

1;    # Perl requires this at the end of all modules