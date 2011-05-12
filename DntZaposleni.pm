package DntZaposleni;
use base 'CGI::Application';
#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use strict;
use DBI;
#use HTML::Template;
#use CGI::Session;
#use Data::Dumper;
use DntFunkcije;

#authenticate:
sub cgiapp_prerun {
	
    my $self = shift;
    my $q = $self->query();
	my $nivo='r';
	my $str = $q->param('rm');
	#nastavi write nivo funkcij, ki zapisujejo v bazo:
	if ($str eq 'dodaj' || $str eq 'spremeni' ||
		$str eq 'shrani'|| $str eq 'zbrisi'){
		$nivo = 'w';
	}
	
    my $user = DntFunkcije::AuthenticateSession(12, $nivo);
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
        'seznam' => 'ZaposleniSeznam',
		'uredi' => 'ZaposleniUredi',
		'Prikazi' => 'ZaposleniSeznam',
		'shrani' => 'ZaposleniShrani',
		'zaposleni_telefon' => 'ZaposleniTelefon',
		'dodaj' => 'ZaposleniDodaj',
		'spremeni' => 'ZaposleniDodaj',
		'donator_telefon' => 'ZaposleniTelefon',
		'donator_komentar' => 'ZaposleniKomentar',
		'zaposleni_komentar' => 'ZaposleniKomentar',
		'zaposleni_delo' => 'ZaposleniDelo',
		'zbrisi' => 'ZaposleniZbrisi',
		'login' => 'Login',
		'error' => 'Error'
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}
sub ZaposleniShrani{
	
	my $self = shift;
	my $q = $self->query();
	my $id_staff = $q->param('edb_id');
	my $seja = $q->param('seja');
	my $html_output;
	my $template;
	my $menu_pot;
	my $imeDokumenta;
	my $napaka;
	my $redirect_url='DntZaposleni.cgi?rm=uredi';
	my $cookie = $ENV{'HTTP_COOKIE'};
	$cookie = substr ($cookie, 3);
	my @arr = split(",", $cookie);
	$cookie = $arr[0];
	my $ui = $q->param('ui');	
	my $ime= $q->param('edb_ime')	;
    my $priimek= $q->param('edb_priimek');
    my $ulica = $q->param('edb_ulica');
	my $hisnaSt = $q->param('edb_hisnaSt');
	my $postnaSt = $q->param('edb_postnaSt');
	my $davcnaSt= $q->param('edb_davcnaSt');
	my $davcniZavezanec= $q->param('davcniZavezanec');
	my $datumRojstva;
	my $emso= $q->param('edb_emso');
	my $osebniDokument= $q->param('edb_osebniDokument');
	my $stOsebnegaDokumenta= $q->param('edb_stOsebnegaDokumenta');
	my $poUlica= $q->param('edb_poUlica');
	my $poHisnaSt= $q->param('edb_poHisnaSt');
	my $poPostnaSt= $q->param('edb_poPostnaSt');
	my $izobrazba= $q->param('edb_izobrazba');
	my $pogodba=$q->param('edb_pogodba');
	my $pogodbaZacetek=$q->param('edb_zacetek');
	my $pogodbaKonec=$q->param('edb_konec');
	my $poklic= $q->param('edb_poklic');
	my $zaposlitev= $q->param('edb_zaposlitev');
	my $vrsta= $q->param('edb_vrsta');
	my $stUr= $q->param('edb_stUr');
	my $veljaDo= $q->param('edb_veljaDo');
	my $izdal= $q->param('edb_izdal');
	my $trr= $q->param('edb_trr');
	my $imeBanke= $q->param('edb_imeBanke');
	my $danRojstva = $q->param('edb_danRojstva');
	my $mesecRojstva = $q->param('edb_mesecRojstva');
	my $letoRojstva = $q->param('edb_letoRojstva');
	
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	
	if($davcniZavezanec=~"on"){
		
		$davcniZavezanec=1;
	}
	else{
		$davcniZavezanec=0;
	}		
	if($veljaDo>0){
		$veljaDo = substr($veljaDo,6,4).'-'.
				substr($veljaDo,3,2).'-'.
				substr($veljaDo,0,2);
	}
	if(length($stUr)==0){
		$stUr=0;
	}
	if($pogodbaZacetek){
		$pogodbaZacetek = substr($pogodbaZacetek,6,4).'-'.
				substr($pogodbaZacetek,3,2).'-'.
				substr($pogodbaZacetek,0,2);
	}
	if($pogodbaKonec){
		$pogodbaKonec = substr($pogodbaKonec,6,4).'-'.
				substr($pogodbaKonec,3,2).'-'.
				substr($pogodbaKonec,0,2);
	}
	$imeDokumenta = "Shrani";
	$napaka = "Shranjevanje uspesno!<br />";
		
	if($letoRojstva<1000 || $danRojstva<0 || $danRojstva>31 || $mesecRojstva<0
	   || $mesecRojstva>12){
		$napaka="NAPAKA! Neveljaven datum!";
	}
		
	$datumRojstva=$letoRojstva."-".$mesecRojstva."-".$danRojstva;
	if(!(length($datumRojstva) > 3)){
		$datumRojstva="";
	}
	#$return "$pogodbaKonec, $pogodbaZacetek, $veljaDo";	
		
	$dbh = DntFunkcije->connectDB;
	
	if ($dbh && $napaka == "Shranjevanje uspesno!<br />") {
		if($id_staff>0){
			$redirect_url="DntZaposleni.cgi?rm=seznam";
			$sql = "UPDATE sfr_staff ".
				"SET first_name=?, scnd_name=?,".
				"prmnt_address=?, prmnt_address_number=?, prmnt_post_number=?, ".
				"tmp_address=?, tmp_address_number=?, tmp_post=?, ".
				"emso=?, tax_number=?, ".
				"liable_for_tax=?, personal_dc=?, prs_dc_nmbr=?, ".
				"prs_dc_valid=NULL, prs_dc_issuer=?,".
				"trr=?, trr_bank=?, education=?,".
				"profession=?, occupation=?, type_occupation=?,".
				"email=NULL, num_wrk_hour=?, staff_agreement=? ".					
				"WHERE id_staff=?";
			  #print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			unless($sth->execute(
						$ime, $priimek,
						$ulica, $hisnaSt, $postnaSt,
						$poUlica, $poHisnaSt, $poPostnaSt,
						$emso, $davcnaSt,
						$davcniZavezanec, $osebniDokument, $stOsebnegaDokumenta,
						$izdal,
						$trr, $imeBanke, $izobrazba,
						$poklic, $zaposlitev, $vrsta,
						$stUr, $pogodba,						  
						$id_staff)){
				
				my $napaka_opis = $sth->errstr;
				$template = $self->load_tmpl(	    
					'DntRocniVnosNapaka.tmpl',
				cache => 1,
				);
				$template->param(
					#MENU_POT => '',
					IME_DOKUMENTA => 'Napaka !',
					napaka_opis => $napaka_opis,
					akcija => ''
				);
		
				$html_output = $template->output; #.$tabelica;
				return $html_output;
			}
			if($datumRojstva){
				$sql="UPDATE sfr_staff SET born_date=? WHERE id_staff=?";
				$sth = $dbh->prepare($sql);				
				unless($sth->execute($datumRojstva, $id_staff)){
				
					my $napaka_opis = $sth->errstr;
                    $template = $self->load_tmpl(	    
                        'DntRocniVnosNapaka.tmpl',
					cache => 1,
					);
                    $template->param(
						#MENU_POT => '',
						IME_DOKUMENTA => 'Napaka !',
						napaka_opis => "Neveljaven datum rojstva!",
						akcija => ''
					);
            
                    $html_output = $template->output; #.$tabelica;
                    return $html_output;
				}
			}
			else{
				$sql="UPDATE sfr_staff SET born_date=NULL WHERE id_staff=?";
				$sth = $dbh->prepare($sql);
				$sth->execute($id_staff);
			}
			if(length($veljaDo)>3){
				$sql="UPDATE sfr_staff SET prs_dc_date=? WHERE id_staff=?";
				$sth = $dbh->prepare($sql);
				$sth->execute($veljaDo, $id_staff);
			}
			else{
				$sql="UPDATE sfr_staff SET prs_dc_date=NULL WHERE id_staff=?";
				$sth = $dbh->prepare($sql);
				$sth->execute($id_staff);
			}
			if(length($pogodbaZacetek)>3){
				$sql="UPDATE sfr_staff SET date_assign_agreement=? WHERE id_staff=?";
				$sth = $dbh->prepare($sql);
				$sth->execute($pogodbaZacetek, $id_staff);
			}
			else{
				$sql="UPDATE sfr_staff SET date_assign_agreement=NULL WHERE id_staff=?";
				$sth = $dbh->prepare($sql);
				$sth->execute($id_staff);
			}
			if(length($pogodbaKonec)>3){
				$sql="UPDATE sfr_staff SET end_agreement=? WHERE id_staff=?";
				$sth = $dbh->prepare($sql);
				$sth->execute($pogodbaKonec, $id_staff);
			}
			else{
				$sql="UPDATE sfr_staff SET end_agreement=NULL WHERE id_staff=?";
				$sth = $dbh->prepare($sql);
				$sth->execute($id_staff);
			}

		}
		else{

			$sql = "INSERT INTO sfr_staff ".
				   "(first_name, scnd_name,".
				    "prmnt_address, prmnt_address_number, prmnt_post_number, ".
					"tmp_address, tmp_address_number, tmp_post, ".
					"emso, tax_number, ".
					"liable_for_tax, personal_dc, prs_dc_nmbr, ".
					"prs_dc_valid, prs_dc_issuer,".
					"trr, trr_bank, education,".
					"profession, occupation, type_occupation,".
					"email, num_wrk_hour, staff_agreement)".
					"VALUES (?, ?,".
							"?, ?, ?,".
							"?, ?, ?,".
							"?, ?, ".
							"?, ?, ?,".
							"NULL, ?,".
							"?, ?, ?,".
							"?, ?, ?,".
							"NULL, ?, ?)";
					
        #print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			unless($sth->execute($ime, $priimek,
					$ulica, $hisnaSt, $postnaSt,
					$poUlica, $poHisnaSt, $poPostnaSt,
					$emso, $davcnaSt,
					$davcniZavezanec, $osebniDokument, $stOsebnegaDokumenta,
					$izdal,
					$trr, $imeBanke, $izobrazba,
					$poklic, $zaposlitev, $vrsta,
					$stUr, $pogodba
					)
				   ){
					
					
					
				my $napaka_opis = $sth->errstr;
                $template = $self->load_tmpl(	    
                    'DntRocniVnosNapaka.tmpl',
				cache => 1,
				);
				#$napaka_opis="Neveljaven datum rojstva ali pogodbe!";

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
			$sql = "SELECT currval('sfr_staff_id_staff_seq') as last";
			$sth = $dbh->prepare($sql);
			$sth->execute();
			if($res = $sth->fetchrow_hashref){
				$id_staff=$res->{'last'};
				if($datumRojstva){
					$sql="UPDATE sfr_staff SET born_date=? WHERE id_staff=?";
					$sth = $dbh->prepare($sql);
					$sth->execute($datumRojstva, $id_staff);
				}
				if(length($veljaDo)>3){
					$sql="UPDATE sfr_staff SET prs_dc_date=? WHERE id_staff=?";
					$sth = $dbh->prepare($sql);
					$sth->execute($veljaDo, $id_staff);
				}
				if(length($pogodbaZacetek)>3){
					$sql="UPDATE sfr_staff SET date_assign_agreement=? WHERE id_staff=?";
					$sth = $dbh->prepare($sql);
					$sth->execute($pogodbaZacetek, $id_staff);
				}
				if(length($pogodbaKonec)>3){
					$sql="UPDATE sfr_staff SET end_agreement=? WHERE id_staff=?";
					$sth = $dbh->prepare($sql);
					$sth->execute($pogodbaKonec, $id_staff);
				}
				
			}
			
			
			#Vstavljanje telefona, klicev in komentarjev iz zacasnih tabel:
			$sql= "SELECT * FROM uporabniki_tmp WHERE id_user='$cookie' AND".
					" id_unique='$ui' AND tmp_source ilike '%_zap'".
					" ORDER BY id ASC";
			$sth = $dbh->prepare($sql);
			$sth->execute();

			my $sth3;
			while($res = $sth->fetchrow_hashref){
				#komentar
				my $date1;
				if(length($res->{'tmp_date1'})>0){
					$date1 = "'" . $res->{'tmp_date1'} . "'";
				}
				else{
					$date1 = "NULL";
				}
				my $date2;
				if(length($res->{'tmp_date2'})>0){
					$date2 = "'" . $res->{'tmp_date2'} . "'";
				}
				else{
					$date2 = "NULL";
				}
				if($res->{'tmp_source'} eq "komentarji_zap"){

					$sql = "INSERT INTO sfr_staff_comment (".
							" id_staff,".
							" date, comment,".
							" alarm, alarm_active,".
							" comment_alarm) VALUES (".
							" '$id_staff', ".
							" $date1, '$res->{'tmp_field1'}', ".
							" $date2, '$res->{'tmp_toggle'}', ".
							" '$res->{'tmp_field2'}')";					
					
					$sth3 = $dbh->prepare($sql);
					unless($sth3->execute()){
						return "FAIL: <br />".$sql;
					};
					
				}
				#telefon
				elsif($res->{'tmp_source'} eq "telefon_zap"){
					$sql = "INSERT INTO sfr_staff_phone (".
					" id_staff,".
					" phone, phone_num,".
					" default_phone) VALUES (".
					" '$id_staff', ".
					" '$res->{'tmp_field1'}', '$res->{'tmp_field2'}', ".
					" '$res->{'tmp_toggle'}')";
					$sth3 = $dbh->prepare($sql);
					unless($sth3->execute()){
						return "FAIL: <br />".$sql;
					}
					#$sql = "SELECT currval('sfr_donor_phone_id_vrstice_seq') as last";
					#$sth3 = $dbh->prepare($sql);
					#$sth3->execute();
					#my $last_id;
					#my $res2;
					#if($res2 = $sth3->fetchrow_hashref){
					#	$last_id=$res2->{'last'};
					#}
					#else{
					#	return $sql;
					#}
					#$sql = "UPDATE uporabniki_tmp SET tmp_field2='$last_id' ".
					#	" WHERE tmp_field2='$res->{'id'}'";
					#$sth3 = $dbh->prepare($sql);
					#unless($sth3->execute()){
					#	return "FAIL: <br />".$sql;
					#};
					
					
				}
				#delo
				elsif($res->{'tmp_source'} eq "delo_zap"){
					$sql = "INSERT INTO sfr_staff_project (".
					" id_staff,".
					" id_project, id_prjct_mng,".
					" active_since, active_end) VALUES (".
					" '$id_staff', ".
					" '$res->{'tmp_field1'}', '$res->{'tmp_field2'}', ".
					" $date1, $date2)";
					$sth3 = $dbh->prepare($sql);
					unless($sth3->execute()){
						return "FAIL: <br />".$sql;
					}
				}
			}
		}
	}
	$sth->finish;
	$dbh->disconnect();
	
	
	$self->header_type('redirect');
    $self->header_props(-url => $redirect_url);
	return $redirect_url;

}
sub ZaposleniSeznam{
	
    my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');
	
	my $html_output ;
	my $ime= $q->param('edb_ime');
	my @loop;
	my $menu_pot;
	my $poKorenuIme= $q->param('po_korenu_ime');
	my $poKorenuPriimek= $q->param('po_korenu_priimek');
	my $priimek= $q->param('edb_priimek');
	my $ulica= $q->param('edb_ulica');
	my $uporabnik= $q->param('uporabnik');
    my $template ;
	my $triPike;
	$self->param(testiram =>'rez');
	    
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntZaposleniSeznam.tmpl',
			      cache => 1,
			     );
    $template->param(
		     #MENU_POT => $menu_pot,
			 IME_DOKUMENTA => 'Seznam zaposlenih',			 
			 POMOC => "<input type='button' value='?' onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
			 MENU => DntFunkcije::BuildMenu(),
		     );
	#Ce so se parametri za poizvedbo izpise rezultat
	#if (length($ime)+length($priimek)+length($ulica)>0){
        my $dbh;
		my $res;
		my $sql;
		my $sth;
		
		my $hid_sort = $q->param("hid_sort");
		$dbh = DntFunkcije->connectDB;
		if ($dbh) {
			$sql = "select id_staff, first_name, scnd_name,";
			$sql.= " prmnt_address from sfr_staff";
			$sql.= " where 1=1";
			if($ime)
			{
				if ($poKorenuIme){
					$sql .= " and first_name ilike '%$ime%'";
					$poKorenuIme="checked='checked'";
				}
				else{
					$sql .= " and first_name ilike '$ime%'";
					$poKorenuIme="";
				}
			}
			if($priimek)
			{
				if ($poKorenuPriimek){
					$sql .= " and scnd_name ilike '%$priimek%'";
					$poKorenuPriimek="checked='checked'";
				}
				else{
					$sql .= " and scnd_name ilike '$priimek%'";
					$poKorenuPriimek="";
				}
			}
			if($ulica)
			{
					$sql .= " and prmnt_address ilike '%$ulica%'";
			}
			
			$sql.= "ORDER BY id_staff DESC";
			
			unless ($ime || $priimek || $ulica){
				$triPike="...";
				$sql.=" LIMIT 17";	
			}
			$sth = $dbh->prepare($sql);
			$sth->execute();
			while ($res = $sth->fetchrow_hashref) {
					
				my %row = (				
					izbor => $q->a({-href=>"DntZaposleni.cgi?".
						"rm=uredi&id_staff=$res->{'id_staff'}".
						"&seja=$seja&uredi=1"}, 'uredi'),
					ime => DntFunkcije::trim($res->{'first_name'}),
					priimek => DntFunkcije::trim($res->{'scnd_name'}),
					id => DntFunkcije::trim($res->{'id_staff'}),
					naslov => DntFunkcije::trim($res->{'prmnt_address'})
					
		  );

					# put this row into the loop by reference             
					push(@loop, \%row);
			}
			$template->param(donator_loop => \@loop,					
					edb_ime => DntFunkcije::trim($ime),
					edb_priimek => DntFunkcije::trim($priimek),
					koren_ime => DntFunkcije::trim($poKorenuIme),
					koren_priimek => DntFunkcije::trim($poKorenuPriimek),
					edb_ulica => DntFunkcije::trim($ulica),
					edb_triPike => $triPike);
				
		}
		else{
			return 'Povezava do baze ni uspela';
		}
                
	#}
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}

sub ZaposleniUredi{
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	
	my $html_output ;
	my $id_staff = $q->param('id_staff');
	my $uredi= $q->param('uredi');
	my $menu_pot ;
	my $template ;
	my $ui;
	
	my $dbh;
	my $res;
    my $sql;
    my $sth; 
   	
	my $ime;
    my $priimek;
    my $ulica;
	my $hisnaSt;
	my $postnaSt;
	my $davcnaSt;
	my $davcniZavezanec;
	my $datumRojstva;
	my $emso;
	my $osebniDokument;
	my $stOsebnegaDokumenta;
	my $poUlica;
	my $poHisnaSt;
	my $poPostnaSt;
	my $imePoste;
	my $imePoste2;
	my @loop4;
	my $danRojstva;
	my $mesecRojstva;
	my $letoRojstva;
	my $onload;
	my $seznamPost;
	my $linkTelefon;
	my $linkKlic;
	my $linkKomentar;
	my $izobrazba;
	my $pogodba;
	my $pogodbaZacetek;
	my $pogodbaKonec;
	my $poklic;
	my $zaposlitev;
	my $vrsta="";
	my $stUr;
	my $veljaDo;
	my $izdal;
	my $trr;
	my $imeBanke;
	my $student;
	my $pogodbena;
	my $redna;
	my $zacasna;
	
	my $countPhones;
	my $countWork;
	my $countComments;
	if(!$id_staff){
		$ui=time();
	}
    $dbh = DntFunkcije->connectDB;
	    if ($dbh) {	
			$sql = "SELECT *"
					." FROM sfr_staff "
					." WHERE id_staff =?";
			
			$sth = $dbh->prepare($sql);
			$sth->execute($id_staff);
	
			
			
			if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
			{
					
				$ime = $res->{'first_name'};
				$priimek = $res->{'scnd_name'};
				$ulica =$res->{'prmnt_address'};
				$hisnaSt =$res->{'prmnt_address_number'};
				$postnaSt =DntFunkcije::trim($res->{'prmnt_post_number'});
				$davcnaSt =$res->{'tax_number'};
				$davcniZavezanec =$res->{'liable_for_tax'};
				#$telefon =$res->{'??'};
				$datumRojstva =$res->{'born_date'};
				$emso =$res->{'emso'};
				$osebniDokument =$res->{'personal_dc'};
				$stOsebnegaDokumenta =$res->{'prs_dc_nmbr'};
				$poUlica =$res->{'tmp_address'};
				$poHisnaSt =$res->{'tmp_address_number'};
				$poPostnaSt =$res->{'tmp_post'};
				$izobrazba=$res->{'education'};
				$poklic=$res->{'profession'};
				$zaposlitev=$res->{'occupation'};
				$vrsta=$res->{'type_occupation'};
				$stUr=$res->{'num_wrk_hour'};
				$veljaDo=$res->{'prs_dc_date'};
				$izdal=$res->{'prs_dc_issuer'};
				$trr=$res->{'trr'};
				$imeBanke=$res->{'trr_bank'};
				$pogodba=$res->{'staff_agreement'};
				$pogodbaZacetek=$res->{'date_assign_agreement'};
				$pogodbaKonec=$res->{'end_agreement'};
				#$text_naslova = $res->{'naslov'};
				#return $res->{'id_staff'}.$res->{'first_name'}.$res->{'scnd_name'}.$res->{'street'};
			}
			
			
			$sql = "SELECT * FROM sfr_post ORDER BY id_post";		
			
			$sth = $dbh->prepare($sql);
			$sth->execute();				
			while($res = $sth->fetchrow_hashref){
					my %row = (id_post => $res->{'id_post'},
							   name_post => DntFunkcije::trim($res->{'name_post'}),
						   
							   );
					push(@loop4, \%row);
				}
			
		
		$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
		$template = $self->load_tmpl(	    
							  'DntZaposleniEdit.tmpl',
					  cache => 1,
					 );
		if(defined $datumRojstva){
		$letoRojstva = substr($datumRojstva,0,4);
		$danRojstva = substr($datumRojstva,8,2);
		$mesecRojstva = substr($datumRojstva,5,2);
		}
		
		if(defined $pogodbaKonec){
			$pogodbaKonec=substr($pogodbaKonec, 8,2)."/".substr($pogodbaKonec, 5,2)."/".substr($pogodbaKonec, 0,4);
		}
		if(defined $pogodbaZacetek){
			$pogodbaZacetek=substr($pogodbaZacetek, 8,2)."/".substr($pogodbaZacetek, 5,2)."/".substr($pogodbaZacetek, 0,4);
		}
		
		
		if(defined $davcniZavezanec && $davcniZavezanec eq "1"){
			$davcniZavezanec="checked=\"checked\"";
		}
		else{
			$davcniZavezanec="";
		}
		$vrsta = DntFunkcije::trim($vrsta);
		if($vrsta eq "redna"){
			$redna="selected=\"selected\"";
		}
		elsif($vrsta eq "zacasna"){
			$zacasna="selected=\"selected\"";			
		}
		elsif($vrsta eq "student"){
			$student="selected=\"selected\"";
		}
		else{
			$pogodbena="selected=\"selected\"";
		}
		if(defined $veljaDo){
		$veljaDo=substr($veljaDo, 8,2)."/".substr($veljaDo, 5,2)."/".substr($veljaDo, 0,4);		
		}
		
		if(defined $id_staff && $id_staff>0){
			$onload="";
			if($postnaSt ne ""){
				$sql = "SELECT *"
						." FROM sfr_post "
						." WHERE id_post =?";
				
				$sth = $dbh->prepare($sql);
				$sth->execute($postnaSt);
				
				if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
				{
					$imePoste =$res->{'name_post'};
					
				}
			}
			if(DntFunkcije::trim($poPostnaSt) ne ""){
				
				$sql = "SELECT *"
						." FROM sfr_post "
						." WHERE id_post =?";
				
				$sth = $dbh->prepare($sql);
				#return $sql . $poPostnaSt;
				$sth->execute($poPostnaSt);
				
				if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
				{
					$imePoste2 =$res->{'name_post'};
					
				}
			}
		}
		
		
		else{
			$onload="onload=\"Uredi();\"";
			

		}
		my $counter;
		$sql = "SELECT * FROM sfr_staff_phone WHERE id_staff=?";			
			
			$sth = $dbh->prepare($sql);
			$sth->execute($id_staff);
				$counter=0;
				while($res = $sth->fetchrow_hashref){
					$counter++;
					
				}
				if($counter>0){
					$countPhones='style="font-weight:bold;"';
				}
			
		
		$sql = "SELECT * FROM sfr_staff_project WHERE id_staff=?";			
			
			$sth = $dbh->prepare($sql);
			$sth->execute($id_staff);
				$counter=0;
				while($res = $sth->fetchrow_hashref){
					$counter++;
					
				}
				if($counter>0){
					$countWork='style="font-weight:bold;"';
				}
			
		
		$sql = "SELECT * FROM sfr_staff_comment WHERE id_staff=?";			
			
			$sth = $dbh->prepare($sql);
			$sth->execute($id_staff);
				$counter=0;
				while($res = $sth->fetchrow_hashref){
					$counter++;
					
				}
				if($counter>0){
					$countComments='style="font-weight:bold;"';
				}
			
		
		$template->param(
				 #MENU_POT => $menu_pot,
				 IME_DOKUMENTA => 'Zaposleni',
				 IME_DOKUMENTA1 => 'Osnovni podatki',
				 IME_DOKUMENTA2 => 'Podatki o zaposlitvi',
				 IME_DOKUMENTA3 => 'Zacasni naslov',
				 IME_DOKUMENTA4 => 'Osebni dokument',
				 IME_DOKUMENTA5 => 'Bancni podatki',
				 IME_DOKUMENTA6 => 'Podatki o pogodbi',
				 POMOC => "<input type='button' value='?' onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
				 MENU => DntFunkcije::BuildMenu(),
				 #edb_counter => $counter,
				 edb_id => $id_staff,
				# edb_statusF => $statusF,
				# edb_statusP => $statusP,
				 #edb_podjetje => DntFunkcije::trim($podjetje),
				# edb_gospod => $gospod,
				# edb_gospa => $gospa,
				# edb_upokojenec => $upokojenec,
				 edb_ime => DntFunkcije::trim($ime),
				 edb_priimek => DntFunkcije::trim($priimek),
				 edb_ulica => DntFunkcije::trim($ulica),
				 edb_hisnaSt => DntFunkcije::trim($hisnaSt),
				 edb_postnaSt => DntFunkcije::trim($postnaSt),
				 edb_imePoste => DntFunkcije::trim($imePoste),
				 edb_imePoste2 => DntFunkcije::trim($imePoste2),
				 edb_davcnaSt => DntFunkcije::trim($davcnaSt),
				 edb_davcniZavezanec => DntFunkcije::trim($davcniZavezanec),
				 edb_danRojstva => DntFunkcije::trim($danRojstva),
				 edb_mesecRojstva => DntFunkcije::trim($mesecRojstva),
				 edb_letoRojstva => DntFunkcije::trim($letoRojstva),
				 edb_emso => DntFunkcije::trim($emso),
				 edb_osebniDokument => DntFunkcije::trim($osebniDokument),
				 edb_stOsebnegaDokumenta => DntFunkcije::trim($stOsebnegaDokumenta),
				# edb_poEmail => DntFunkcije::trim($poEmail),
				 edb_poUlica => DntFunkcije::trim($poUlica),
				 edb_poHisnaSt => DntFunkcije::trim($poHisnaSt),
				 edb_poPostnaSt => DntFunkcije::trim($poPostnaSt),
				 
				 edb_izobrazba => DntFunkcije::trim($izobrazba),
				 edb_poklic => DntFunkcije::trim($poklic),
				 edb_zaposlitev => DntFunkcije::trim($zaposlitev),
				 edb_stUr => DntFunkcije::trim($stUr),
				 edb_veljaDo => DntFunkcije::trim($veljaDo),
				 edb_izdal => DntFunkcije::trim($izdal),
				 edb_trr => DntFunkcije::trim($trr),
				 edb_imeBanke => DntFunkcije::trim($imeBanke),
				 edb_redna=> DntFunkcije::trim($redna),
				 edb_zacasna=> DntFunkcije::trim($zacasna),
				 edb_pogodbena=> DntFunkcije::trim($pogodbena),
				 edb_student=> DntFunkcije::trim($student),
				 edb_pogodba=> DntFunkcije::trim($pogodba),
				 edb_zacetek=> DntFunkcije::trim($pogodbaZacetek),
				 edb_konec=> DntFunkcije::trim($pogodbaKonec),
				 edb_countPhone=> DntFunkcije::trim($countPhones),
				 edb_countWork=> DntFunkcije::trim($countWork),
				 edb_countComments=> DntFunkcije::trim($countComments),
				 edb_ui => $ui,
				 edb_loop4 => \@loop4,
				 

				 #klic_loop => \@loop3,
				 edb_onload => $onload,

				 );

		$html_output = $template->output; #.$tabelica;
		
		#$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
		return $html_output;
	    }
	    else{
		return 'Napaka. Povezava do baze ni uspela ';
	    }
	

}
sub ZaposleniZbrisi(){
	
	
	
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $redirect_url;
	my @deleteIds=$q->param('brisiId');
	my $source=$q->param('brisi');
	my $ui = $q->param('ui');
	my $template;
	my $html_output;
	my $counter=0;
	my $id;
	my $sql;
	my $sql2;
	my $sql3;
	my $sql4;
	my $sth;
	my $dbh;
	my $id_staff=$q->param('id_donor');
	
	if($source=~"telefon"){
		
		
		$sql="DELETE FROM sfr_staff_phone WHERE ";
			
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id_vrstice='$id' ";
				$counter++;
			}
			$sql.="OR id_vrstice='$id' ";
		}	
		$redirect_url="?rm=zaposleni_telefon&id_staff=$id_staff";
	}
	if($source=~"telefon_tmp"){
		
		
		$sql="DELETE FROM uporabniki_tmp WHERE ";
		$counter=0;
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id='$id' ";
				$counter++;
			}
			$sql.="OR id='$id' ";
		}	
		$redirect_url="?rm=zaposleni_telefon&id_staff=$id_staff&ui=$id_staff";
	}
	
	if($source=~"zaposleni"){
		
		
		$sql="DELETE FROM sfr_staff WHERE ";
		$sql2="DELETE FROM sfr_staff_phone WHERE ";
		$sql3="DELETE FROM sfr_staff_comment WHERE ";
		$sql4="DELETE FROM sfr_staff_project WHERE ";
			
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id_staff='$id' ";
				$sql2.="id_staff='$id' ";
				$sql3.="id_staff='$id' ";
				$sql4.="id_staff='$id' ";
				
				$counter++;
			}
			else{
				$sql.="OR id_staff='$id' ";
				$sql2.="OR id_staff='$id' ";
				$sql3.="OR id_staff='$id' ";
				$sql4.="OR id_staff='$id' ";
			}
			
			
		}	
		$redirect_url="?rm=seznam";
		$dbh = DntFunkcije->connectDB;
			if($dbh){
				$sth = $dbh->prepare($sql2);
				$sth->execute();
				$sth = $dbh->prepare($sql3);
				$sth->execute();
				$sth = $dbh->prepare($sql4);
				$sth->execute();
			}
		
	}
	
	if($source=~"komentar"){
		
		
		$sql="DELETE FROM sfr_staff_comment WHERE ";
			
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id_vrstice='$id' ";
				$counter++;
			}
			$sql.="OR id_vrstice='$id' ";
		}	
		$redirect_url="?rm=zaposleni_komentar&id_staff=$id_staff";
	}
	if($source=~"komentar_tmp"){
		
		
		$sql="DELETE FROM uporabniki_tmp WHERE ";
		$counter = 0;
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id='$id' ";
				$counter++;
			}
			$sql.="OR id='$id' ";
		}	
		$redirect_url="?rm=zaposleni_komentar&id_staff=$id_staff&ui=$id_staff";
	}
	if($source=~"delo"){
		
		
		$sql="DELETE FROM sfr_staff_project WHERE ";
			
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id_vrstice='$id' ";
				$counter++;
			}
			$sql.="OR id_vrstice='$id' ";
		}	
		$redirect_url="?rm=zaposleni_delo&id_staff=$id_staff";
	}
	if($source=~"delo_tmp"){
		
		
		$sql="DELETE FROM uporabniki_tmp WHERE ";
		$counter=0;
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id='$id' ";
				$counter++;
			}
			$sql.="OR id='$id' ";
		}	
		$redirect_url="?rm=zaposleni_delo&id_staff=$id_staff&ui=$id_staff";
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
										#MENU_POT => '',
										IME_DOKUMENTA => 'Napaka !',
										napaka_opis => $napaka_opis,
										akcija => ''
										 );
				
						$html_output = $template->output; #.$tabelica;
						#$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
						return $html_output;
		}
	}
	
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
	
}
sub ZaposleniKomentar(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id_staff = $q->param('id_staff');
	my $id_komentar = $q->param('id_komentar');
	my $ui = $q->param('ui');
	my $menu_pot ;
	my $template ;
	my $gumbek;
	my $alarm;
	my $alarmAktivni;
	my $counter=0;	
	my $datum;
	my $ime;
	my $ime_dokumenta;
	my $komentar;
	my $komentarAlarm;
	my $priimek;
	my $lepiDatum;
	my $onload;
	my $cookie = $ENV{'HTTP_COOKIE'};
	$cookie = substr ($cookie, 3);
	my @arr = split(",", $cookie);
	$cookie = $arr[0];
	my @loop2;
	my $brisi_ui='';
	if($ui){
		$brisi_ui='_tmp';
	}
	
	my $dbh;
	my $sql;
	my $sth;
	my $res;

	if(length($id_staff)==0){
		$id_staff=$q->param('id_donor');
	}
		
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		#dodaj v uporabniki_tmp
		if($ui){
			$id_staff=$ui;
			if($id_komentar){
				$sql = "SELECT * FROM uporabniki_tmp WHERE id='$id_komentar' ";
				$sth = $dbh->prepare($sql);			
				$sth->execute();
				$gumbek="spremeni";
				$ime_dokumenta="Urejanje komentarja";
				$onload="onload=\"document.myForm['nazaj'].disabled = false; Uredi()\"";			
				if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
				{
					$ime = $res->{'first_name'};				
					$priimek = $res->{'scnd_name'};
					$datum = $res->{'tmp_date1'};
					$komentar = $res->{'tmp_field1'};
					$alarm = $res->{'tmp_date2'};
					$alarmAktivni = $res->{'tmp_toggle'};
					$komentarAlarm = $res->{'tmp_field2'};
					
				}
				else{
					return $sql;
				}
			}
			else{
				#, sfr_staff_phone
				#, phone, phone_num, default_phone
				$gumbek="dodaj";
				$ime_dokumenta="Dodaj nov komentar";
			}
			$sql = "SELECT * FROM uporabniki_tmp WHERE id_user='$cookie' AND".
					" id_unique = '$ui' AND tmp_source = 'komentarji_zap'".
					" ORDER BY tmp_date1";		
			$sth = $dbh->prepare($sql);
			$sth->execute();
			
			while($res = $sth->fetchrow_hashref){
				my %row = (datum => $res->{'tmp_date1'},
						   komentar => $res->{'tmp_field1'},
						   komentarId => $res->{'id'},
						   edb_id => $ui,
						   tmp_link => "&ui=$ui",
						   edb_komentar_if => 1,
						   );
				
				push(@loop2, \%row);			
			}
		}
		else{
			if($id_komentar>0){
				$sql = "SELECT * FROM sfr_staff, sfr_staff_comment WHERE sfr_staff.id_staff=? AND id_vrstice=?";
				$sth = $dbh->prepare($sql);			
				$sth->execute($id_staff, $id_komentar);
				$gumbek="spremeni";
				$ime_dokumenta="Urejanje komentarja";
				$onload="onload=\"document.myForm['nazaj'].disabled = false; Uredi()\"";
				
			}
			else{
				
				$sql = "SELECT first_name, scnd_name FROM sfr_staff WHERE id_staff=?";
				#, sfr_staff_phone
				#, phone, phone_num, default_phone
				$sth = $dbh->prepare($sql);
				$sth->execute($id_staff);
				$gumbek="dodaj";
				$ime_dokumenta="Dodaj nov komentar";
			}	
			if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
			{
				$ime = $res->{'first_name'};				
				$priimek = $res->{'scnd_name'};
				$datum = $res->{'date'};
				$komentar = $res->{'comment'};
				$alarm = $res->{'alarm'};
				$alarmAktivni = $res->{'alarm_active'};
				$komentarAlarm = $res->{'comment_alarm'};
				
			}	
			$sql = "SELECT date, comment, id_vrstice FROM sfr_staff_comment WHERE id_staff=? ORDER BY date";		
			$sth = $dbh->prepare($sql);
			$sth->execute($id_staff);
				
			while($res = $sth->fetchrow_hashref){
				my %row = (datum => substr($res->{'date'}, 0, 10),
						   komentar => $res->{'comment'},
						   komentarId => $res->{'id_vrstice'},
						   edb_id => $id_staff,
						   edb_komentar_if => 1,
						   
						   );
				
				push(@loop2, \%row);			
			}
		}
	}
	if(length($datum)>0){
		$datum=substr($datum, 8,2)."/".substr($datum, 5,2)."/".substr($datum, 0,4);
		
	}
	if(length($alarm)>0){
		$alarm=substr($alarm, 8,2)."/".substr($alarm, 5,2)."/".substr($alarm, 0,4);
	}
	
	if($alarmAktivni==1){
			$alarmAktivni="checked=\"checked\"";
		}
	else{
			$alarmAktivni="";
		}

	$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
		$template = $self->load_tmpl(	    
							  'DntDonatorKomentar.tmpl',
					  cache => 1,
					 );
	$template->param(
				 IME_DOKUMENTA => $ime_dokumenta,
				 POMOC => "<input type='button' value='?' onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
				 edb_id => $id_staff,
				 komId => $id_komentar,
				 edb_ime => DntFunkcije::trim($ime),
				 edb_priimek => DntFunkcije::trim($priimek),
				 edb_datum => DntFunkcije::trim($datum),
				 edb_komentar => DntFunkcije::trim($komentar),
				 edb_alarm => DntFunkcije::trim($alarm),
				 edb_alarmAktivni => DntFunkcije::trim($alarmAktivni),
				 edb_komentarAlarm => DntFunkcije::trim($komentarAlarm),
				 edb_onload => $onload,
				 edb_gumbek => $gumbek,
				 edb_komentar_if => 1,
				 ui => $ui,
				 brisi_ui => $brisi_ui,
				 komentar_loop => \@loop2,
				);

	$html_output = $template->output; #.$tabelica;
	return $html_output;
	
    
	
}

sub ZaposleniTelefon(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id_staff = $q->param('id_staff');
	my $id_telefon = $q->param('id_phone');
	my $ui = $q->param('ui');
	my $menu_pot ;
	my $template ;
	
	my $gumbek;
	my $ime;
	my $priimek;
	my $primarni;
	my $telefon;
	my $telefonskaSt;
	my $onload;
	
	my @loop;
	
	my $dbh;
	my $sql;
	my $sth;
	my $res;
	my $cookie = $ENV{'HTTP_COOKIE'};
	$cookie = substr ($cookie, 3);
	my @arr = split(",", $cookie);
	$cookie = $arr[0];
	if(!$id_staff){
		$id_staff=$q->param('id_donor');
		
	}
	if(length($id_staff)==0){
		$id_staff=$q->param('id_staff');
	}
	if($ui){
		$id_staff= $ui;
	}
	my $brisi_ui='';
	if($ui){
		$brisi_ui='_tmp';
	}
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		if($id_telefon>0){
			if($ui){
				$sql = "SELECT tmp_field1 as phone, tmp_field2 as phone_num,".
					" tmp_toggle as default_phone  FROM uporabniki_tmp ".
					" WHERE id_unique=? AND id=? ";
			}
			else{
				$sql = "SELECT first_name, scnd_name, phone, phone_num, default_phone FROM sfr_staff, sfr_staff_phone WHERE sfr_staff.id_staff=? AND id_vrstice=?";
			}
			$sth = $dbh->prepare($sql);			
			$sth->execute($id_staff, $id_telefon);
			$gumbek="spremeni";
			$onload="onload=\"Uredi(); Uredi2();\"";
		}
		else{
			$onload="onload=\"Uredi();\"";
			$sql = "SELECT first_name, scnd_name FROM sfr_staff WHERE id_staff=?";
			$sth = $dbh->prepare($sql);
			$sth->execute($id_staff);
			$gumbek="dodaj";

			
		}
		
		if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
		{
			$ime = $res->{'first_name'};
			$priimek = $res->{'scnd_name'};
			$telefon = $res->{'phone'};
			$telefonskaSt = $res->{'phone_num'};
			$primarni = $res->{'default_phone'};
			
		}
		
		if($ui){
		$sql = "SELECT tmp_field1 as phone, tmp_field2 as phone_num, id as id_vrstice".
				" FROM uporabniki_tmp WHERE id_unique=? AND id_user='$cookie'".
				" AND tmp_source='telefon_zap'";			
			
		}
		else{
		$sql = "SELECT phone, phone_num, id_vrstice FROM sfr_staff_phone WHERE id_staff=?";			
			
		}			
		$sth = $dbh->prepare($sql);
		$sth->execute($id_staff);
		#return $sql.$id_staff;
		while($res = $sth->fetchrow_hashref){
			
			my %row = (telefon => $res->{'phone'},
					   telefonska => $res->{'phone_num'},
					   telefonId => $res->{'id_vrstice'},
					   edb_id => $id_staff,
					   tmp_link => "&amp;ui=$ui",
					   
					   
					   );
			push(@loop, \%row);
		}
	}
	
	if($primarni==1){
		$primarni="checked=\"checked\"";
	}
	else{
		$primarni="";
	}
	$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
		$template = $self->load_tmpl(	    
							  'DntDonatorTelefon.tmpl',
					  cache => 1,
					 );
	$template->param(
				 IME_DOKUMENTA => "Uredi telefonske stevilke",
				 POMOC => "<input type='button' value='?' onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
				 edb_id => $id_staff,
				 id_telefona => $id_telefon,
				 edb_ime => DntFunkcije::trim($ime),
				 edb_priimek => DntFunkcije::trim($priimek),
				 edb_telefon => DntFunkcije::trim($telefon),
				 edb_telefonskaSt => DntFunkcije::trim($telefonskaSt),
				 edb_primarni => $primarni,
				 gumbek => $gumbek,
				 edb_onload => $onload,
				 donator_loop => \@loop,
				 ui => $ui,
				 brisi_ui => $brisi_ui,
				 );


	$html_output = $template->output; #.$tabelica;
	return $html_output;
	
    
	
}
sub ZaposleniDelo(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id_staff = $q->param('id_staff');
	my $id_delo = $q->param('id_delo');
	my $idProjekt;
	my $idManager;
	my $menu_pot ;
	my $template ;
	my $onload;
	my $gumbek;
	my $ui = $q->param('ui');
		my $cookie = $ENV{'HTTP_COOKIE'};
	$cookie = substr ($cookie, 3);
	my @arr = split(",", $cookie);
	$cookie = $arr[0];
	my $counter=0;
	my $datum;
	my $datum1;
	my $datum2;
	my $ime;
	my $sifraProjekta;
	my $priimek;
	my $vodjaProjekta;
	my $izbranManager;
	my $izbranProjekt;
	my $od;
	my $do;
	
	my $dbh;
	my $sql;
	my $sth;
	my $res;
	my $dbh2;
	my $sql2;
	my $sth2;
	my $res2;
	my @loop;
	my @loop2;
	my @loop3;
	if($ui){
		$id_staff=$ui;
	}
	my $brisi_ui='';
	if($ui){
		$brisi_ui='_tmp';
	}
	if($id_delo>0){
		
		$gumbek="spremeni";
	}
	else{
		
		$gumbek="dodaj";
	}
		
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {	
		$sql = "SELECT first_name, scnd_name FROM sfr_staff WHERE id_staff=?";
		#, sfr_staff_phone
	    #, phone, phone_num, default_phone
		$sth = $dbh->prepare($sql);
		$sth->execute($id_staff);
		
		if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
		{
			
			$ime = $res->{'first_name'};
			$priimek = $res->{'scnd_name'};

		}
		if($ui){
			$sql = "SELECT tmp_field1 as id_project, tmp_field2 as id_prjct_mng, ".
			"tmp_date1 as active_since, tmp_date2 as active_end FROM ".
			"uporabniki_tmp WHERE id=?";
		
		}
		else{
			$sql = "SELECT id_project, id_prjct_mng, active_since, active_end FROM sfr_staff_project WHERE id_vrstice=?";
			
		}
		#, sfr_staff_phone
	    #, phone, phone_num, default_phone
		$sth = $dbh->prepare($sql);
		$sth->execute($id_delo);
		
		if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
		{
			$idProjekt=$res->{'id_project'};
			$idManager=$res->{'id_prjct_mng'};
			$od= $res->{'active_since'};
			$do= $res->{'active_end'};		

		}
		if($od>0){
			$od=substr($od, 8,2)."/".substr($od, 5,2)."/".substr($od, 0,4);
		}
		if($do>0){
			$do=substr($do, 8,2)."/".substr($do, 5,2)."/".substr($do, 0,4);
		}
	
	
		$sql = "SELECT id_project, name_project FROM sfr_project";			
		$sth = $dbh->prepare($sql);
		$sth->execute();

				
				
		while($res = $sth->fetchrow_hashref){
			
			if($idProjekt==$res->{'id_project'}){
				$izbranProjekt="selected=\"selected\"";
				
			}
			else{
				$izbranProjekt="";
			}
			my %row = (id => DntFunkcije::trim($res->{'id_project'}),
					   projekt => DntFunkcije::trim($res->{'name_project'}),
					   izbran => $izbranProjekt,
					   );
			push(@loop, \%row);		
		}
		
		$sql = "SELECT id_staff, first_name, scnd_name FROM sfr_staff ORDER BY id_staff";			
		$sth = $dbh->prepare($sql);
		$sth->execute();
				
				
		while($res = $sth->fetchrow_hashref){
			
			if($idManager==$res->{'id_staff'}){
				$izbranManager="selected=\"selected\"";
				
			}
			else{
				$izbranManager="";
			}
			
			my %row = (id => DntFunkcije::trim($res->{'id_staff'}),
					   ime => DntFunkcije::trim($res->{'first_name'}),
					   priimek => DntFunkcije::trim($res->{'scnd_name'}),
					   izbran => $izbranManager,
					   );
			push(@loop2, \%row);		
		}
				
		if($ui){	
		$sql = "SELECT tmp_field1 as id_project, tmp_field2 as id_prjct_mng, ".
				"tmp_toggle as id_staff, tmp_date1 as active_since, ".
				"tmp_date2 as active_end, id as id_vrstice ".
				"FROM uporabniki_tmp ".
			    "WHERE id_unique=? AND id_user='$cookie' AND tmp_source='delo_zap' ".
				"ORDER BY id";
		}
		else{
		$sql =  "SELECT sfr_staff_project.id_project, id_prjct_mng, id_staff, active_since, active_end, name_project, id_vrstice ".
				"FROM sfr_staff_project, sfr_project ".
			    "WHERE id_staff=? AND CAST(sfr_project.id_project AS integer)=sfr_staff_project.id_project ".
				"ORDER BY id_vrstice";
		}
		#return $sql.$id_staff;
		$sth = $dbh->prepare($sql);
		$sth->execute($id_staff);
				
		while($res = $sth->fetchrow_hashref){
			
			
			$datum1=$res->{'active_since'};
			if($datum1>0){
				$datum1=substr($datum1, 8,2)."/".substr($datum1, 5,2)."/".substr($datum1, 0,4);
		
			}
			$datum2=$res->{'active_end'};
			if($datum2>0){
				$datum2=substr($datum2, 8,2)."/".substr($datum2, 5,2)."/".substr($datum2, 0,4);
		
			}
			
			
			my %row = (id => $res->{'id_vrstice'},
					   edb_id => $res->{'id_staff'},
					   name => $res->{'name_project'},
					   od => $datum1,
					   do => $datum2,
					   ui => $ui,
					   );
			push(@loop3, \%row);
		}
	}
	if ($id_delo>0){
		
		
		$onload="onload=\"Uredi(); Uredi2()\"";
	}
	else {
		$onload="onload=\"Uredi();\"";
	}

	$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
		$template = $self->load_tmpl(	    
							  'DntZaposleniDelo.tmpl',
					  cache => 1,
					 );
	
	$template->param(
				 IME_DOKUMENTA => "Dodaj delo",
				 POMOC => "<input type='button' value='?' onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
				 edb_id => $id_staff,
				 edb_deloId => $id_delo,
				 edb_ime => DntFunkcije::trim($ime),
				 edb_priimek => DntFunkcije::trim($priimek),		 
				 ui => $ui,
				 ui_brisi => $brisi_ui,
				 edb_od => $od,
				 edb_do => $do,
				 edb_loop => \@loop,
				 edb_loop2 => \@loop2,
				 edb_loop3 => \@loop3,
				 edb_onload => $onload,
				 edb_gumbek => $gumbek,
				 );

	$html_output = $template->output; #.$tabelica;
	return $html_output;
	
    
	
}
sub ZaposleniDodaj(){
	
	my $self = shift;
	my $q = $self->query();
	my $hiddenId = $q->param('hiddenId');
	my $id_staff = $q->param('edb_id');
	my $id_komentar = $q->param('id_komentar');
	my $seja = $q->param('seja');
	my $html_output;
	my $template;
	my $menu_pot;
	my $imeDokumenta;
	my $napaka;
	my $redirect_url;
	my $ui = $q->param('ui');
	if($ui){
		$id_staff=$ui;
	}
	my $cookie = $ENV{'HTTP_COOKIE'};
	$cookie = substr ($cookie, 3);
	my @arr = split(",", $cookie);
	$cookie = $arr[0];
	
	if($hiddenId=~"komentar"){		
		
		my $id = $q->param('edb_id');
		my $id_komentar = $q->param('komId');
		my $datumKomentarja = $q->param('edb_datum');
		my $komentar = $q->param('edb_komentar');
		my $aktiven = $q->param('edb_alarmAktivni');
		my $datumAlarm = $q->param('edb_datum_alarm');
		my $komentarAlarm = $q->param('edb_komentar_alarm');	
		my $dbh;
		my $res;
		my $sql;
		my $sth;
		my $query;
		my $query2;
		
		if ($aktiven!=1){
			$aktiven=0;
		}
		
		$redirect_url="?rm=donator_komentar&amp;id_staff=$id_staff&amp;ui=$ui";
		$imeDokumenta="Dodaj komentar";
		$napaka="Uspesno dodano!";
		if($datumKomentarja>0){
			$datumKomentarja = substr($datumKomentarja,6,4).'-'.
							substr($datumKomentarja,3,2).'-'.
							substr($datumKomentarja,0,2);
		}
		if($datumAlarm>0){
			$datumAlarm = substr($datumAlarm,6,4).'-'.
							substr($datumAlarm,3,2).'-'.
							substr($datumAlarm,0,2);
		}
		
		
		$dbh = DntFunkcije->connectDB;
		if ($dbh) {
			
			if($id_komentar>0){
				if($ui){
					$sql = "UPDATE uporabniki_tmp SET ".
						"id_unique=?, tmp_date1=?, tmp_field1=? ".
						"WHERE id=? ";	
				}
				else{
					$sql = "UPDATE sfr_staff_comment SET ".
						"id_staff=?, date=?, comment=? ".
						"WHERE id_vrstice=? ";
				}		
				$sth = $dbh->prepare($sql);
				unless($sth->execute($id, "'".$datumKomentarja."'", $komentar, 
						  	  $id_komentar)){
					
					my $napaka_opis = $sth->errstr;
						$template = $self->load_tmpl(	    
							'DntDodajSpremeni.tmpl',
						cache => 1,
						);
						$template->param(
										MENU_POT => '',
										IME_DOKUMENTA => 'Napaka !',
										napaka_opis => $napaka_opis.$sql,
										akcija => ''
										 );
				
						$html_output = $template->output; #.$tabelica;
						#$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
						return $html_output;
				}
				if($ui){
					$sql = "UPDATE uporabniki_tmp SET ".
					"tmp_date2=?, tmp_toggle=?, tmp_field2=? ".
					"WHERE id=? ";
				}
				else{
					$sql = "UPDATE sfr_staff_comment SET ".
					"alarm=?, alarm_active=?, comment_alarm=? ".
					"WHERE id_vrstice=? ";
				}
							
				$sth = $dbh->prepare($sql);
				unless($sth->execute("'".$datumAlarm."'", $aktiven, $komentarAlarm,
						  $id_komentar)){
					
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
						if($aktiven==1){
							return $html_output;
						}
				}
			
				
			}
			else {									
				if($ui){	
					$sql = "INSERT INTO uporabniki_tmp ".
					"(id_unique, id_user, tmp_date1, tmp_field1, tmp_source) ".
					"VALUES (?, '$cookie', ?, ?, 'komentarji_zap') ";
				}
				else{	
					$sql = "INSERT INTO sfr_staff_comment ".
					"(id_staff, date, comment) ".
					"VALUES (?, ?, ?) ";
				}
				$sth = $dbh->prepare($sql);
				unless($sth->execute($id, "'".$datumKomentarja."'", $komentar)){
					
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
				if($ui){
					$sql = "SELECT id as id_vrstice FROM uporabniki_tmp ORDER BY id_vrstice DESC LIMIT 1";
	
				}
				else{
					$sql = "SELECT id_vrstice FROM sfr_staff_comment ORDER BY id_vrstice DESC LIMIT 1";
				}
				$sth = $dbh->prepare($sql);
				$sth->execute();
				if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
				{
				
				$id_komentar= $res->{'id_vrstice'};
				
				}
				if($ui){
				$sql = "UPDATE uporabniki_tmp SET ".
					"tmp_date2=?, tmp_toggle=?, tmp_field2=? ".
					"WHERE id=? ";
				}
				else{
				$sql = "UPDATE sfr_staff_comment SET ".
					"alarm=?, alarm_active=?, comment_alarm=? ".
					"WHERE id_vrstice=? ";
				}	
				$sth = $dbh->prepare($sql);
				
				unless($sth->execute("'".$datumAlarm."'", $aktiven, $komentarAlarm,
						  $id_komentar))
					{
						
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
						if($aktiven==1){
							return $html_output;
						}
					}

			}
        #print $q->p($sql_vprasaj);
			
			
		
		}
		$sth->finish;
		$dbh->disconnect();
		
		
	}
	if($hiddenId=~"delo"){
		my $id = $q->param('edb_id');
		my $id_delo= $q->param('deloId');
		my $projekt = $q->param('edb_projekt');
		my $vodja = $q->param('edb_vodja');
		my $od = $q->param('edb_od');
		my $do = $q->param('edb_do');
		my $ui = $q->param('ui');

		$redirect_url="?rm=zaposleni_delo&amp;id_staff=$id_staff";
		my $dbh;
		my $res;
		my $sql;
		my $sth;
		
		$imeDokumenta="Dodaj delo";
		$napaka="Uspesno dodano!";
		
		if(length($od)>0){
		$od = "'" . substr($od,6,4).'-'.
						substr($od,3,2).'-'.
						substr($od,0,2) . "'";
		}
		else{
			$od = "NULL";
		}
		if(length($do)>0){				
			$do = "'" . substr($do,6,4).'-'.
							substr($do,3,2).'-'.
							substr($do,0,2) . "'";
	    }
		else{
			$do = "NULL";
		}


		if($ui){
			$id=$ui;
			$id_staff=$ui;
		}
		$dbh = DntFunkcije->connectDB;
		if ($dbh) {
			if($id_delo>0){
			if($ui){
				$sql = "UPDATE uporabniki_tmp SET id_unique=?, tmp_field1=?,".
				   "tmp_field2=? ";
				$sql .= ", tmp_date1=$od"; 
				$sql .= ", tmp_date2=$do"; 
				$sql .= "WHERE id=?";	
			}
			else{
				$sql = "UPDATE sfr_staff_project SET id_staff=?, id_project=?,".
				   "id_prjct_mng=?" .
				   ", active_since=$od";

				$sql .= ", active_end=$do";
				
				$sql .= " WHERE id_vrstice=?";			
			}

        #print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			unless($sth->execute($id_staff, $projekt, $vodja, $id_delo)){
				
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
			else{
				if($ui){
					
					$sql = "INSERT INTO uporabniki_tmp (id_unique, tmp_field1,".
					   "tmp_field2, tmp_date1, tmp_date2, id_user, tmp_source)".
					   "VALUES (?, ?, ?, $od, $do, '$cookie', 'delo_zap')";					
				}
				else{
					$sql = "INSERT INTO sfr_staff_project (id_staff, id_project,".
					   "id_prjct_mng, active_since, active_end)".
					   "VALUES (?, ?, ?, $od, $do)";
					
				}
				$sth = $dbh->prepare($sql);
				unless($sth->execute($id_staff, $projekt, $vodja)){
					
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
	}
	if($hiddenId=~"telefon"){
		my $id = $q->param('edb_id');
		my $id_telefona = $q->param('id_telefona');
		my $telefon = $q->param('edb_telefon');
		my $telefonska = $q->param('edb_telefonskaSt');
		my $primarni = $q->param('edb_primarni');
		my $ui = $q->param('ui');
		if($ui){
			$id= $ui;
		}
		my $dbh;
		my $res;
		my $sql;
		my $sth;

		$imeDokumenta="Dodaj delo";
		$napaka="Uspesno dodano!";
		$redirect_url="?rm=zaposleni_telefon&amp;id_staff=$id_staff";

		
		$dbh = DntFunkcije->connectDB;
		if($primarni=~"on"){
			$primarni=1;
			if ($dbh) {
				if($ui){
					$sql = "UPDATE uporabniki_tmp SET tmp_toggle= 0 WHERE id= ?";
				
				}
				else{
					$sql = "UPDATE sfr_staff_phone SET default_phone = 0 WHERE id_staff = ?";
					
				}
				$sth = $dbh->prepare($sql);
				unless($sth->execute($id)){
				
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
		else{
			$primarni=0;
		}
		if ($dbh) {
			if($id_telefona){
				
				if($ui){
					$sql = "UPDATE uporabniki_tmp SET id_unique=?, tmp_field1=?".
							", tmp_field2=?, tmp_toggle=? WHERE id=?";
			
				}
				else{
					$sql = "UPDATE sfr_staff_phone SET id_staff=?, phone=?, phone_num=?, default_phone=? WHERE id_vrstice=?";
			
				}
				$sth = $dbh->prepare($sql);
				unless($sth->execute($id, $telefon, $telefonska, $primarni, $id_telefona)){
				
				my $napaka_opis = $sth->errstr;
                    $template = $self->load_tmpl(	    
                        'DntDodajSpremeni.tmpl',
					cache => 1,
					);
                    $template->param(
                                    MENU_POT => '',
                                    IME_DOKUMENTA => 'Napaka !',
                                    napaka_opis => $napaka_opis.$sql,
                                    akcija => ''
                                     );
            
                    $html_output = $template->output; #.$tabelica;
                    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
                    return $html_output;	
				}	
				
			}
			else{
				if($ui){
					$sql = "INSERT INTO uporabniki_tmp (id_unique, tmp_field1, tmp_field2, tmp_toggle, id_user, tmp_source) ".
					   "VALUES (?, ?, ?, ?, '$cookie', 'telefon_zap')";				
				}
				else{
					$sql = "INSERT INTO sfr_staff_phone (id_staff, phone, phone_num, default_phone) ".
					   "VALUES (?, ?, ?, ?)";				
				}
				$sth = $dbh->prepare($sql);
				unless($sth->execute($id, $telefon, $telefonska, $primarni)){
					
					my $napaka_opis = $sth->errstr;
                    $template = $self->load_tmpl(	    
                        'DntDodajSpremeni.tmpl',
					cache => 1,
					);
                    $template->param(
                                    MENU_POT => '',
                                    IME_DOKUMENTA => 'Napaka !',
                                    napaka_opis => $napaka_opis.$sql,
                                    akcija => ''
                                     );
            
                    $html_output = $template->output; #.$tabelica;
                    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
                    return $html_output;
				}
			}
		}
	}
	$redirect_url.="&amp;ui=$ui";
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
	
}

#če uporabnik ni prijavljen:
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'Zaposleni';
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
	#error tmpl brez menija:
	if ($q->param('rm') eq "spremeni" || $q->param('rm') eq "dodaj"){
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
	}
	#error tmpl z menijem:
	else{
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
	}
	my $html_output = $template->output; #.$tabelica;
	return $html_output;
}

1;    # Perl requires this at the end of all modules