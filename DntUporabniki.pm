package DntUporabniki;
use base 'CGI::Application';
#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use strict;
use DBI;
#use HTML::Template;
#use CGI::Session;
#use Data::Dumper;
use DntFunkcije;
use Digest::MD5 qw(md5_hex);

sub cgiapp_prerun {
	
    my $self = shift;
    my $q = $self->query();
	my $nivo='r';
	my $str = $q->param('rm');
	#nastavi write nivo funkcij, ki zapisujejo v bazo:
	if ($str eq 'Shrani' || $str eq 'zbrisi' || $str eq 'uredi'){
		$nivo = 'w';
	}
	
    my $user = DntFunkcije::AuthenticateSession(51, $nivo);
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
        'seznam' => 'UporabnikiSeznam',
		'Prikazi' => 'UporabnikiSeznam',
		'uredi' => 'UporabnikiUredi',
		'Shrani' => 'UporabnikiShrani',
		'zbrisi' => 'UporabnikiZbrisi',
		'Preusmeri' => 'Preusmeri',
		'login' => 'Login',
		'error' => 'Error'
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub UporabnikiSeznam{
	
    my $self = shift;
    my $q = $self->query();	
	my $seja= $q->param('seja');	
	my $html_output ;
	my $ime= $q->param('edb_ime');
	my @loop;
	my $menu_pot;
	my $triPike;
	my $poKorenuIme= $q->param('po_korenu_ime');
	my $st= $q->param('edb_st');
	my $uporabnik= $q->param('uporabnik');
    my $template ;
	$self->param(testiram =>'rez');
	    
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
		'DntUporabnikiSeznam.tmpl',
		 cache => 1,
   );
    $template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'Seznam uporabnikov',
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		MENU => DntFunkcije::BuildMenu(),
		
	);
	#Ce so se parametri za poizvedbo izpise rezultat

        my $dbh;
		my $res;
		my $sql;
		my $sth;
		
		my $hid_sort = $q->param("hid_sort");
		$dbh = DntFunkcije->connectDB;
		
		if ($dbh) {
			#if(length($ime)+length($st)>0){
			$sql = "SELECT * FROM uporabniki ORDER BY id_uporabnik ASC";
			
			$sth = $dbh->prepare($sql);
			$sth->execute();
			while ($res = $sth->fetchrow_hashref) {
					
				my %row = (				
					izbor => $q->a({-href=>"DntUporabniki.cgi?".
						"rm=uredi&id_Uporabniki=$res->{'id_uporabnik'}".
						"&seja=&uredi=1"}, 'uredi'),
					ime => DntFunkcije::trim($res->{'uporabnik'}),
					admin => DntFunkcije::trim($res->{'administrator'}),
					id => DntFunkcije::trim($res->{'id_uporabnik'})					
		        );
				# put this row into the loop by reference             
				push(@loop, \%row);
			}
			$template->param(donator_loop => \@loop,

					edb_ime => DntFunkcije::trim($ime),
					edb_triPike => $triPike,
					edb_st => DntFunkcije::trim($st));
			#}	
		}
		else{
			return 'Povezava do baze ni uspela';
		}
                
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}
sub UporabnikiShrani{
	

	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id_uporabnik = $q->param('edb_id');
	my $ime = $q->param('edb_ime');
	my $geslo = $q->param('edb_geslo');
	my $geslo2 = $q->param('edb_geslo2');
	my $staroGeslo;
	my $uredi = $q->param('uredi');
	my @sifranti= reverse($q->param('sifranti'));
	my @pogodbe = reverse($q->param('pogodbe'));
	my @placila = reverse($q->param('placila'));
	my @orodja  = reverse($q->param('orodja'));
	my @uporabniki = reverse($q->param('uporabniki'));
	my @pomoc = reverse($q->param('pomoc'));
	
	my $menu_pot;
	my $template;
	
	my $dbh;
	my $sql;
	my $sth;
	my $res;
	
	my $i;
	my $modul;
	my $nivo;
		
	my $redirect_url="?rm=seznam&amp;";
	
	if($q->param('edb_novo_geslo')){
		$geslo = $q->param('edb_novo_geslo');
		$geslo2 = $q->param('edb_novo_geslo2');
	}
	
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {		
		if($uredi==1){
			if($geslo){
				if($geslo ne "" && $geslo eq $geslo2){
					$sql = "UPDATE uporabniki SET ".
					"geslo='".md5_hex($geslo)."' ".
					"WHERE id_uporabnik='$id_uporabnik'";
				$sth = $dbh->prepare($sql);
				$sth->execute();
				}
				else{
					my $napaka_opis = "Gesla se ne ujemata";
					$template = $self->load_tmpl(	    
						'DntRocniVnosNapaka.tmpl',
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
			#$sql = "UPDATE sfr_uporabnik SET ".
			#	"uporabnik='$ime', geslo='".md5_hex($geslo)."' ".
			#	"WHERE id_vrstice='$id_uporabnik'";
			#print $q->p($sql_vprasaj);
			#$sth = $dbh->prepare($sql);
			#unless($sth->execute()){
			#
			#my $napaka_opis = $sth->errstr;
			#	$template = $self->load_tmpl(	    
			#		'DntDodajSpremeni.tmpl',
			#	cache => 1,
			#	);
			#	$template->param(
			#					MENU_POT => '',
			#					IME_DOKUMENTA => 'Napaka !',
			#					napaka_opis => $napaka_opis,
			#					akcija => ''
			#					 );		
			#	$html_output = $template->output; #.$tabelica;
			#	return $html_output;	
			#}
			$sql = "DELETE FROM uporabniki_dostop ".
				   "WHERE id_uporabnik='$id_uporabnik'";
			$sth = $dbh->prepare($sql);
			$sth->execute();
		}
		else{	
			if($geslo eq $geslo2 && DntFunkcije::trim($geslo ne "")){
				$geslo= md5_hex($geslo);
				$sql = "INSERT INTO uporabniki (uporabnik, geslo) ".
				       "VALUES ('$ime', '$geslo')";
				#print $q->p($sql_vprasaj);
				#return $sql;
				$sth = $dbh->prepare($sql);
				unless($sth->execute()){
					
					my $napaka_opis = $sth->errstr;
					$template = $self->load_tmpl(	    
						'DntRocniVnosNapaka.tmpl',
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
				$sql = "SELECT currval('uporabniki_id_uporabnik_seq') as last";
				$sth = $dbh->prepare($sql);
				$sth->execute();
				if($res = $sth->fetchrow_hashref){
					$id_uporabnik=$res->{'last'};
				}
			}
			elsif(DntFunkcije::trim($geslo2) eq "" &&
				  DntFunkcije::trim($geslo) ne ""){
				#ne shrani novega gesla
			}
			else{
				
				my $napaka_opis = "Gesla se ne ujemata";
					$template = $self->load_tmpl(	    
						'DntRocniVnosNapaka.tmpl',
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
		for ($i=0; $i<@sifranti; $i++){
			$modul="1".substr($sifranti[$i], 0, 1);
			$nivo= substr($sifranti[$i], 1, 1);
			$sql = "INSERT INTO uporabniki_dostop ".
					"(id_uporabnik, uporabnik, modul, nivo_dostopa) ".
					"VALUES ('$id_uporabnik', '$ime', '$modul', '$nivo')";
			#print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			$sth->execute();
		
			if($nivo eq "w"){
				$i++;	
			}
			
		}
		for ($i=0; $i<@pogodbe; $i++){
			$modul="2".substr($pogodbe[$i], 0, 1);
			$nivo= substr($pogodbe[$i], 1, 1);
			$sql = "INSERT INTO uporabniki_dostop ".
					"(id_uporabnik, uporabnik, modul, nivo_dostopa) ".
					"VALUES ('$id_uporabnik', '$ime', '$modul', '$nivo')";
			#print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			$sth->execute();
			if($nivo eq "w"){
				$i++;	
			}
			
		}
		for ($i=0; $i<@placila; $i++){
			$modul="3".substr($placila[$i], 0, 1);
			$nivo= substr($placila[$i], 1, 1);
			$sql = "INSERT INTO uporabniki_dostop ".
					"(id_uporabnik, uporabnik, modul, nivo_dostopa) ".
					"VALUES ('$id_uporabnik', '$ime', '$modul', '$nivo')";
			#print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			$sth->execute();
			if($nivo eq "w"){
				$i++;	
			}
			
		}
		for ($i=0; $i<@orodja; $i++){
			$modul="4".substr($orodja[$i], 0, 1);
			$nivo= substr($orodja[$i], 1, 1);
			$sql = "INSERT INTO uporabniki_dostop ".
					"(id_uporabnik, uporabnik, modul, nivo_dostopa) ".
					"VALUES ('$id_uporabnik', '$ime', '$modul', '$nivo')";
			#print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			$sth->execute();
			if($nivo eq "w"){
				$i++;	
			}
		}
		for ($i=0; $i<@uporabniki; $i++){
			$modul="5".substr($uporabniki[$i], 0, 1);
			$nivo= substr($uporabniki[$i], 1, 1);
			$sql = "INSERT INTO uporabniki_dostop ".
					"(id_uporabnik, uporabnik, modul, nivo_dostopa) ".
					"VALUES ('$id_uporabnik', '$ime', '$modul', '$nivo')";
			#print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			$sth->execute();
			if($nivo eq "w"){
				$i++;	
			}
		}
		$sql = "INSERT INTO uporabniki_dostop ".
					"(id_uporabnik, uporabnik, modul, nivo_dostopa) ".
					"VALUES ('$id_uporabnik', '$ime', '61', 'r')";
		#print $q->p($sql_vprasaj);
		$sth = $dbh->prepare($sql);
		$sth->execute();
		for ($i=0; $i<@pomoc; $i++){
			$modul="6".substr($pomoc[$i], 0, 1);
			$nivo= substr($pomoc[$i], 1, 1);
			$sql = "INSERT INTO uporabniki_dostop ".
					"(id_uporabnik, uporabnik, modul, nivo_dostopa) ".
					"VALUES ('$id_uporabnik', '$ime', '$modul', '$nivo')";
			#print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			$sth->execute();
			if($nivo eq "w"){
				$i++;	
			}
		}
	}
	$sth->finish;
	$dbh->disconnect();	
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
}
	

sub UporabnikiUredi{
	my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');	
	my $html_output ;
	my $menu_pot;
	my $id_uporabnik= $q->param('id_Uporabniki');
	my $uredi=$q->param('uredi');
	my $imeUporabniki;
	my $Vuporabnik;
	my $uporabnik;
	my $id_geslo;
    my $template;
	my $disabled;
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(
	                      'DntUporabnikiEdit.tmpl',
			      cache => 1,
			     );
    $template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'uporabnika',
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(), MENU => DntFunkcije::BuildMenu(),		
	);
	#Ce so se parametri za poizvedbo izpise rezultat
	
	if($uredi==1){
		$disabled="readonly=\"readonly\"";
	}
	else{
		$disabled="";
		$uredi=0;
	}
	
    my $dbh;
	my $res;
	my $sql;
	my $sth;
	my $moduli;
	my $hid_sort = $q->param("hid_sort");
	my $admin=0;
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		$sql = "select * FROM uporabniki";
		$sql.= " where id_uporabnik='$id_uporabnik'";

		$sth = $dbh->prepare($sql);
		$sth->execute();
		if($res = $sth->fetchrow_hashref) {
				
			$imeUporabniki=DntFunkcije::trim($res->{'uporabnik'});
			$id_geslo=DntFunkcije::trim($res->{'geslo'});
			$id_uporabnik=DntFunkcije::trim($res->{'id_uporabnik'});
			$admin=DntFunkcije::trim($res->{'administrator'});
		}
		
		$sql ="select * FROM uporabniki_dostop ".
				"WHERE id_uporabnik='$id_uporabnik'";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		while($res = $sth->fetchrow_hashref){
			$moduli .= DntFunkcije::trim($res->{'nivo_dostopa'}).
					   DntFunkcije::trim($res->{'modul'}).",";
		}
	}
	else{
		return 'Povezava do baze ni uspela';
	}
	if ($uredi == 0){
		$imeUporabniki = "";
	}

	$template->param(
		edb_ime => $imeUporabniki,
		edb_id => $id_uporabnik,
		edb_moduli => DntFunkcije::trim($moduli),
		admin => $admin,
		#edb_uporabnik => $Vuporabnik,
		#edb_disabled => $disabled,
		edb_uredi=> $uredi
	);       
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
}

sub UporabnikiZbrisi(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $redirect_url;
	my @deleteIds=$q->param('brisiId');
	my $source=$q->param('brisi');
	my $template;
	my $html_output;
	my $counter=0;
	my $sql;
	my $sth;
	my $dbh;
	my $id=$q->param('id_placilo');

	$sql="DELETE FROM uporabniki_dostop WHERE ";
	$counter = 0;
	foreach $id (@deleteIds){
		if ($counter==0){
			$sql.="id_uporabnik='$id' ";
			$counter++;
		}
		$sql.="OR id_uporabnik='$id' ";
	}	

	$dbh = DntFunkcije->connectDB;
	if($dbh){
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
	$sql="DELETE FROM uporabniki WHERE ";
	$counter = 0;
	foreach $id (@deleteIds){
		if ($counter==0){
			$sql.="id_uporabnik='$id' ";
			$counter++;
		}
		$sql.="OR id_uporabnik='$id' ";
	}	

	$dbh = DntFunkcije->connectDB;
	if($dbh){
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
	$redirect_url="?rm=seznam";
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
	
}
#če uporabnik ni prijavljen:
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
		'DntRocniVnosNapaka.tmpl',
	cache => 1,
	);
	$template->param(
		#MENU_POT => '',
		MENU => DntFunkcije::BuildMenu(),
		IME_DOKUMENTA => 'Napaka!',
		napaka_opis => $napaka_opis,
		akcija => ''
	);

	my $html_output = $template->output; #.$tabelica;
	return $html_output;
}
1;    # Perl requires this at the end of all modules