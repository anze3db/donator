package DntPole;
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
	if ($str eq 'Shrani' || $str eq 'zbrisi' || $str eq 'Zadolzi' ||
		$str eq 'uredi'){
		$nivo = 'w';
	}
	
    my $user = DntFunkcije::AuthenticateSession(27, $nivo);
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
        'seznam' => 'PoleSeznam',
		'Prikazi' => 'PoleSeznam',
		'uredi' => 'PoleUredi',
		'Shrani' => 'PoleShrani',
		'zbrisi' => 'PoleZbrisi',
		'zadolziDat' => 'PoleZadolzi',
		'Zadolzi' => 'PoleShrani',
		'sheets' => 'PoleSheets',
		'tiskaj' => 'PoleTiskaj',
		'login' => 'Login',
		'error' => 'Error'

    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub PoleSeznam{

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
	my $id_pole= $q->param('edb_id');
	my $projekt= $q->param('edb_projekt');
	my $leto= $q->param('edb_leto');
	my $dogodek= $q->param('edb_dogodek');
	my $komercialist= $q->param('edb_komercialist');
	my $samoKomercialist= $q->param('komercialist');
	my $odprte= $q->param('odprte');
	my $selected;
	my @loop5;
	my @loop6;
	my @loop7;
	my @loop8;
	my @loop9;
	my @loop10;
	my $tmp;
	my $d1tmp;
	my $d2tmp;
	my $now=localtime;
	$now=substr($now, -2, 2);
	$self->param(testiram =>'rez');
	if(!$dogodek){
		$dogodek="";
	}
	    
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntPoleSeznam.tmpl',
			      cache => 1,
			     );
    $template->param(
		#MENU_POT => $menu_pot,
	   IME_DOKUMENTA => 'Seznam pol',
	   POMOC => "<input type='button' value='?' ".
	   "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),

		);
	#Ce so se parametri za poizvedbo izpise rezultat
	
        my $dbh;
		my $res;
		my $sql;
		my $sth;
		my $zbrisi;
		my $hid_sort = $q->param("hid_sort");
		$dbh = DntFunkcije->connectDB;
		
		if ($dbh) {
			#if(length($ime)+length($st)>0){
			$sql = "select * FROM sheets_series";
			$sql.= " where 1=1";
			if($id_pole)
			{			
				$sql .= " and series ilike '$id_pole'";				
			}
			
			if($projekt)
			{
				$sql .= " and id_project = $projekt";
			}
			if($leto)
			{
				$sql .= " and year ilike '$leto'";
			}
			if($dogodek)
			{
				$sql .= " and id_event ilike '$dogodek'";
			}
			if($komercialist)
			{
				$sql .= " and id_staff = $komercialist";
			}
			if(!$odprte){ $odprte=0; }
			else        { $odprte=1; }
			
			$sql.=" ORDER BY series DESC";
			
			if(defined($ime) || defined($st)==0){
				$sql.=" LIMIT 18";
				$triPike="...";
			}
			
			$sth = $dbh->prepare($sql);
			$sth->execute();
			my $tmp2;
			my $skk;
			while ($res = $sth->fetchrow_hashref) {
				
				if(!$res->{'date_delivery'}){
					$tmp=$q->a({-href=>"DntPole.cgi?".
						"rm=zadolziDat&id_pole=$res->{'series'}".
						"&seja=$seja"}, 'zadolzi');
					$tmp2="";
				}
				else{
					$tmp=$q->a({-href=>"DntPole.cgi?".
						"rm=sheets&id_pole=$res->{'series'}".
						"&seja=&uredi=1"}, 'pokazi');
					$tmp2="<a href=\"\" onclick=\"javascript:Tiskaj('".
							$res->{'series'}."')\" >Tiskaj</a>";
				}
				if(length($res->{'date_create'})>0){
					$d1tmp=substr($res->{'date_create'},8,2).'/'.
							substr($res->{'date_create'},5,2).'/'.
							substr($res->{'date_create'},0,4);
				}
				else{
					$d1tmp="";
				}
				if($res->{'date_delivery'}){
					$d2tmp=substr($res->{'date_delivery'},8,2).'/'.
							substr($res->{'date_delivery'},5,2).'/'.
							substr($res->{'date_delivery'},0,4);
					$zbrisi='';
				}
				else{
					$d2tmp="";
					$zbrisi='<input type="checkbox" onclick="PreveriOznacene()"
                             name="brisiId" value="'.$res->{'series'}.'">
                             ';
				}
				my $sql2;
				my $sth2;
				my $res2;
				
				$sql2="SELECT * FROM sheets WHERE series=".$res->{'series'};
				if($odprte==1){
					$sql2.=" AND id_agreement isnull ";
					
				}
				$sql2 .= " ORDER BY serial_id";
				$skk .= $sql2."<br />";
				$sth2 = $dbh->prepare($sql2);
				$sth2->execute();
				my $i=0;
				my $j=0;
				my @loop11;
				if(defined $samoKomercialist && $samoKomercialist==1){
					while ($res2 = $sth2->fetchrow_hashref) {
						my %row2 = (	
						serial => DntFunkcije::trim($res2->{'serial_id'}),
						);
						push(@loop11, \%row2);
					}
				}
				
				my %row = (				
					izbor => $tmp,					
					id => DntFunkcije::trim($res->{'series'}),
					tiskaj => $tmp2,
					year => DntFunkcije::trim($res->{'year'}),
					id_staff => DntFunkcije::trim($res->{'id_staff'}),
					id_event => DntFunkcije::trim($res->{'id_event'}),
					date_create => $d1tmp,
					date_delivery => $d2tmp,					
					#closed => DntFunkcije::trim($res->{'closed'}),
					#serial_root => DntFunkcije::trim($res->{'serial_root'}),
					sheets_num => DntFunkcije::trim($res->{'sheets_num_created'}),
					#od_stevilke => DntFunkcije::trim($res->{'od_stevilke'}),
					id_project => DntFunkcije::trim($res->{'id_project'}),
					zbrisi => $zbrisi,
					deleted=> DntFunkcije::trim($res->{'sheets_deleted'}),
					loop11 => \@loop11
					
					
				);

					# put this row into the loop by reference             
					push(@loop, \%row);
			}
			
			if($odprte==1){
				$odprte="checked=true";
			}
			else{
				$odprte="";
			}
			$template->param(donator_loop => \@loop,
					#koren => DntFunkcije::trim($poKorenuIme),
					#edb_ime => DntFunkcije::trim($ime),
					edb_triPike => $triPike,
					odprte => $odprte,
					#edb_st => DntFunkcije::trim($st)
					);

			#}
			$sql = "SELECT * FROM sfr_pay_type ORDER BY id_pay_type";			
		
			$sth = $dbh->prepare($sql);
			$sth->execute();
					
			while($res = $sth->fetchrow_hashref){
				
				if(defined $komercialist && $komercialist eq $res->{'debit_type'}){
					$selected="selected='selected'";
				}
				else{
					$selected="";
				}
				
				my %row = (tip => DntFunkcije::trim($res->{'debit_type'}),
						   ime => DntFunkcije::trim($res->{'name_pay_type'}),
						   selected => $selected,
					   
						   );
				push(@loop5, \%row);
				
			}
			$now++;
			while($now>5){
				if ($now <10 && $now!~ /[0]/g){
					$now="0".$now;
				}
				if(defined $leto && $leto eq $now){
					$selected="selected='selected'";
				}
				else{
					$selected="";
				}
				
				my %row = (datum => $now--,
						   selected => $selected,
					   
						   );
				push(@loop6, \%row);
				
			}
			$sql = "SELECT * FROM sfr_project ORDER BY id_project";			
			
			$sth = $dbh->prepare($sql);
			$sth->execute();
					
					while($res = $sth->fetchrow_hashref){
						
						if(!$projekt) { $projekt=""; }
						$tmp=DntFunkcije::trim($res->{'id_project'});
						if($projekt eq $res->{'id_project'}){
							$selected="selected='selected'";
						}
						else{
							$selected="";
						}
						
						my %row = (id => DntFunkcije::trim($res->{'id_project'}),
								   id_lep => $tmp,
								   ime => DntFunkcije::trim($res->{'name_project'}),
									selected => $selected,
								   );
						push(@loop7, \%row);
						
					}
					
			$sql = "SELECT * FROM sfr_events ORDER BY id_event";			
			
			$sth = $dbh->prepare($sql);
			$sth->execute();
					
					while($res = $sth->fetchrow_hashref){
						
						$tmp=DntFunkcije::trim($res->{'id_event'});
						if($dogodek eq $res->{'id_event'}){
							$selected="selected='selected'";
						}
						else{
							$selected="";
						}
						
						my %row = (id => $tmp,
								   ime => DntFunkcije::trim($res->{'name_event'}),
								   selected => $selected,
						
								   );
						push(@loop8, \%row);
						
					}
			$sql = "SELECT * FROM sfr_staff ORDER BY id_staff";			
			
			$sth = $dbh->prepare($sql);
			$sth->execute();
					
			while($res = $sth->fetchrow_hashref){
				
				if(defined $komercialist && $komercialist eq $res->{'id_staff'}){
					$selected="selected='selected'";
				}
				else{
					$selected="";
				}
				
				my %row = (id => DntFunkcije::trim($res->{'id_staff'}),
						ime => DntFunkcije::trim($res->{'first_name'}),
						priimek => DntFunkcije::trim($res->{'scnd_name'}),
						selected => $selected,
				);
				push(@loop9, \%row);
				
			}
			$template->param(
				edb_loop6 => \@loop6,
				edb_loop7 => \@loop7,
				edb_loop8 => \@loop8,
				edb_loop9 => \@loop9,
				edb_loop10 => \@loop10,
			);
		}
		else{
			return 'Povezava do baze ni uspela';
		}
                
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}
sub PoleSheets{
	
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
	my $id_pole= $q->param('id_pole') || 0;
	my $id_sifra= $q->param('id_sifra') || 0;
	#return $id_sifra;
	my $projekt= $q->param('edb_projekt');
	my $leto= $q->param('edb_leto');
	my $dogodek= $q->param('edb_dogodek');
	my $komercialist= $q->param('edb_komercialist');
	my $selected;
	my @loop5;
	my @loop6;
	my @loop7;
	my @loop8;
	my @loop9;
	my $tmp;
	my $d1tmp;
	my $d2tmp;
	my $now=localtime;
	$now=substr($now, -2, 2);
	$self->param(testiram =>'rez');
	    
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntPoleSheets.tmpl',
			      cache => 1,
			     );
    $template->param(
		IME_DOKUMENTA => 'Seznam pol',
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
		edb_id => $id_pole.$id_sifra,
	
		 );
	#Ce so se parametri za poizvedbo izpise rezultat
	
        my $dbh;
		my $res;
		my $sql;
		my $sth;
		
		my $hid_sort = $q->param("hid_sort");
		$dbh = DntFunkcije->connectDB;
		
		if ($dbh) {
			
			if(defined $id_sifra && $id_sifra>0){
				$sql = "select * FROM sheets WHERE serial_root=? AND ".
						" id_agreement ISNULL ORDER BY id_vrstce";
				
				$sth = $dbh->prepare($sql);
				$sth->execute($id_sifra);
				$tmp="";
				
				
			}
			else{
			#if(length($ime)+length($st)>0){
				$sql = "select * FROM sheets WHERE series=? ORDER BY id_vrstce";				
				$sth = $dbh->prepare($sql);
				$sth->execute($id_pole);
				#return $sql;
				$tmp="";
			}
			while ($res = $sth->fetchrow_hashref) {
				
				if($res->{'id_agreement'}){
					$tmp="";
				}
				else{
					$tmp="<input type='checkbox' onclick='PreveriOznacene()'
						   name='brisiId' value='".$res->{'id_vrstce'}."' />";
				}
				my %row = (	
				
				id => DntFunkcije::trim($res->{'id_vrstce'}),
				serial_id => DntFunkcije::trim($res->{'serial_id'}),
				id_agreement => DntFunkcije::trim($res->{'id_agreement'}),
				brisi => $tmp,
				);

				# put this row into the loop by reference             
				push(@loop, \%row);
			}
			
			$template->param(donator_loop => \@loop);
		}
		else{
			return 'Povezava do baze ni uspela';
		}
                
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}
sub PoleShrani{
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id = $q->param('edb_id');
	my $datum = $q->param('edb_datum');
	my $ime = $q->param('edb_ime');
	my $uporabnik = $q->param('edb_uporabnik');
	my $uredi = $q->param('uredi');
	my $id_pole= $q->param('edb_id');
	my $projekt= $q->param('edb_projekt');
	my $stPol=$q->param('edb_pole');	
	my $leto= $q->param('edb_leto');
	my $dogodek= $q->param('edb_dogodek');
	my $komercialist= $q->param('edb_komercialist');
	my $zadolzi=$q->param('zadolzi');
	my $komerc;
	my $menu_pot ;
	my $template ;
	my $serial;
	my $date;
	(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) =
    localtime(time);
	$mon+=1;
	if($mon<10){
		$mon="0$mon";
	}
	if($mday<10){
		$mday="0$mday"
	}
	$year+=1900;
	$date="$year-$mon-$mday";
	if($komercialist<10){
		$komerc="00$komercialist";
	}
	elsif($komercialist<100){
		$komerc="0$komercialist";
	}
	else{
		$komerc=$komercialist;
	}
	if($stPol>9999){
		my $napaka_opis = "Preveliko stevilo pol! Najvec 9999";
		$template = $self->load_tmpl(	    
			'DntDodajSpremeni.tmpl',
		cache => 1,
		);
		$template->param(
						MENU_POT => '',
						IME_DOKUMENTA => 'Napaka !',
						napaka_opis => $napaka_opis,
						akcija => '',
						);

		$html_output = $template->output; #.$tabelica;
		return $html_output;
		
	}
	$serial=$projekt.$leto.$dogodek.$komerc;

	my $dbh;
	my $sql;
	my $sth;
	my $res;
	my $serialRoot;
	my $serialId;
	
	my $tmp;
	
	my $redirect_url="?rm=seznam&amp;";

		
		$dbh = DntFunkcije->connectDB;
	
		
		if ($dbh) {
			
			if($zadolzi==1){	
				
				
					
				$sql = "select * FROM sheets_series";
				$sql.= " where series=?";
				my $odSt;
				$sth = $dbh->prepare($sql);
				$sth->execute($id);
				if($res = $sth->fetchrow_hashref) {
						
					$serialRoot=DntFunkcije::trim($res->{'serial_root'});
					$stPol=DntFunkcije::trim($res->{'sheets_num_created'});
					$odSt=DntFunkcije::trim($res->{'od_stevilke'});
				}
				my $i=$odSt;
				if($datum>0){
							$datum = substr($datum,6,4).'-'.
							substr($datum,3,2).'-'.
							substr($datum,0,2);
				}
				
				while($i++!=$stPol+$odSt){
					if($i<10){
						$tmp="000$i";
					}
					elsif($i<100){
						$tmp="00$i";
					}
					elsif($i<1000){
						$tmp="0$i";
					}
					else{
						$tmp="$i";
					}
					
					$tmp=$serialRoot.$tmp.DntFunkcije::EanCheckDigit($serialRoot.$tmp, 13);
					
					$sql="INSERT INTO sheets (series, serial_id, serial_root) ".
						 "VALUES (?, ?, ?)";
			
					$sth = $dbh->prepare($sql);
					unless($sth->execute($id, $tmp, $serialRoot)){
					
						my $napaka_opis = $sth->errstr;
						$template = $self->load_tmpl(	    
							'DntDodajSpremeni.tmpl',
						cache => 1,
						);
						$template->param(
										MENU_POT => '',
										IME_DOKUMENTA => 'Napaka !',
										napaka_opis => $napaka_opis,
										akcija => '',
									    );				
						$html_output = $template->output; #.$tabelica;
						return $html_output;
					}
					
					$sql = "UPDATE sheets_series SET".
					       " date_delivery=? WHERE series=?";			
					$sth = $dbh->prepare($sql);
					unless($sth->execute($datum, $id)){					
						my $napaka_opis = $sth->errstr;
						$template = $self->load_tmpl(	    
							'DntDodajSpremeni.tmpl',
						cache => 1,
						);
						$template->param(
										MENU_POT => '',
										IME_DOKUMENTA => 'Napaka !',
										napaka_opis => $napaka_opis,
										akcija => '',
									    );
				
						$html_output = $template->output; #.$tabelica;
						return $html_output;
					}
					
				}
				
			}
			
			
			
			elsif($uredi==1){
				return "ne da se urejat pol";
				
			}
			else{
				
				my $odSt=0;
				$sql="SELECT od_stevilke, serial_root, sheets_num_created FROM".
				 " sheets_series WHERE serial_root=? ORDER BY CAST(od_stevilke as integer) DESC";
				$sth = $dbh->prepare($sql);
				$sth->execute($serial);
				if($res = $sth->fetchrow_hashref){	
					
					$odSt=$res->{'sheets_num_created'}+$res->{'od_stevilke'};
				}				
				#return $odSt." [$serial]";
				$sql = "INSERT INTO sheets_series ".
							"(year, id_staff, closed,".
							" serial_root, date_create, date_delivery,". 
							" sheets_num_created, id_project, id_event,".
							" od_stevilke".
							") ".
					   "VALUES (?, ?, 0, ".
							   "?, ?, NULL, ".
							   "?, ?, ?, ".
					   		   "? )";
			#print $q->p($sql_vprasaj);
			
				$sth = $dbh->prepare($sql);
				unless($sth->execute($leto, $komerc,
									 $serial, $date,
									 $stPol, $projekt, $dogodek,
									 $odSt)){
					
					my $napaka_opis = $sth->errstr;
                    $template = $self->load_tmpl(	    
                        'DntDodajSpremeni.tmpl',
					cache => 1,
					);
                    $template->param(
                                    MENU_POT => '',
                                    IME_DOKUMENTA => 'Napaka !',
                                    napaka_opis => $napaka_opis,
                                    akcija => '',
									);
            
                    $html_output = $template->output; #.$tabelica;
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
	

sub PoleUredi{
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
	my $id_pole= $q->param('edb_id');
	my $projekt= $q->param('edb_projekt');
	my $leto= $q->param('edb_leto');
	my $dogodek= $q->param('edb_dogodek');
	my $komercialist= $q->param('edb_komercialist');
	my $selected;
	my $mesec;
	my $dan;

	
	my $now=localtime;
	$now=substr($now, -2, 2);
	
	
	my @loop5;
	my @loop6;
	my @loop7;
	my @loop8;
	my @loop9;
	my $tmp;
	$self->param(testiram =>'rez');
	    
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntPoleUredi.tmpl',
			      cache => 1,
			     );
    $template->param(
		     #MENU_POT => $menu_pot,
			IME_DOKUMENTA => 'Dodaj polo',
			POMOC => "<input type='button' value='?' ".
			"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
		     );
	#Ce so se parametri za poizvedbo izpise rezultat
	
        my $dbh;
		my $res;
		my $sql;
		my $sth;
		
		my $hid_sort = $q->param("hid_sort");
		$dbh = DntFunkcije->connectDB;
		
		if ($dbh) {
			
			$sql = "SELECT * FROM sfr_pay_type ORDER BY id_pay_type";			
		
		$sth = $dbh->prepare($sql);
		$sth->execute();
				
				while($res = $sth->fetchrow_hashref){
					
					if($komercialist eq $res->{'debit_type'}){
						$selected="selected='selected'";
					}
					else{
						$selected="";
					}
					
					my %row = (tip => DntFunkcije::trim($res->{'debit_type'}),
							ime => DntFunkcije::trim($res->{'name_pay_type'}),
							selected => $selected,						   
					);
					push(@loop5, \%row);
					
				}
		$sql = "SELECT * FROM sfr_pay_type ORDER BY id_pay_type";			
		
		$sth = $dbh->prepare($sql);
		$sth->execute();
				$now++;
				while($now >= 6){
					
					if(length($now)<2){
						$now="0$now";
					}
					
					
					my %row = (datum => $now--);
						   
							   
					push(@loop6, \%row);
					
		}
		$sql = "SELECT * FROM sfr_project ORDER BY id_project";			
		
		$sth = $dbh->prepare($sql);
		$sth->execute();
				
				while($res = $sth->fetchrow_hashref){
					
					
					$tmp=DntFunkcije::trim($res->{'id_project'});
					if(defined $projekt && $projekt==$res->{'id_project'}){
						$selected="selected='selected'";
					}
					else{
						$selected="";
					}
					
					my %row = (id => DntFunkcije::trim($res->{'id_project'}),
							   id_lep => $tmp,
							   ime => DntFunkcije::trim($res->{'name_project'}),
								selected => $selected,
							   );
					push(@loop7, \%row);
					
				}
				
		$sql = "SELECT * FROM sfr_events ORDER BY id_event";			
		
		$sth = $dbh->prepare($sql);
		$sth->execute();
				
				while($res = $sth->fetchrow_hashref){
					
					$tmp=DntFunkcije::trim($res->{'id_event'});
					if(defined $dogodek && $dogodek==$res->{'id_event'}){
						$selected="selected='selected'";
					}
					else{
						$selected="";
					}
					
					my %row = (id => $tmp,
							   ime => DntFunkcije::trim($res->{'name_event'}),
							   selected => $selected,
					
							   );
					push(@loop8, \%row);
					
				}
		$sql = "SELECT * FROM sfr_staff ORDER BY id_staff";			
		
		$sth = $dbh->prepare($sql);
		$sth->execute();
				
				while($res = $sth->fetchrow_hashref){
					
					if(defined $komercialist && $komercialist==$res->{'id_staff'}){
						$selected="selected='selected'";
					}
					else{
						$selected="";
					}
					
					my %row = (id => DntFunkcije::trim($res->{'id_staff'}),
							ime => DntFunkcije::trim($res->{'first_name'}),
							priimek => DntFunkcije::trim($res->{'scnd_name'}),
							selected => $selected,					
					);
					push(@loop9, \%row);
					
				}
		$template->param(
		     #MENU_POT => $menu_pot,
				
			#edb_loop5 => \@loop5,
			edb_loop6 => \@loop6,
			edb_loop7 => \@loop7,
			edb_loop8 => \@loop8,
			edb_loop9 => \@loop9,
			 
		     );
		}
		else{
			return 'Povezava do baze ni uspela';
		}
                
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
}

sub PoleZadolzi(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id_pole = $q->param('id_pole');
	my $menu_pot;
	my $template;
	my $date;
	my $odSt;
	my $serialRoot;
	my $stPol;
	
	my $sql;
	my $dbh;
	my $sth;
	my $res;
	
	
	(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) =
    localtime(time);
	$mon+=1;
	$year+=1900;
	if($mon<10){
		$mon="0$mon";
	}
	if($mday<10){
		$mday="0$mday"
	}
	$date="$mday/$mon/$year";
	$sql = "select * FROM sheets_series";
	$sql.= " where series=?";

	$dbh = DntFunkcije->connectDB;
	if($dbh){
		$sth = $dbh->prepare($sql);
		$sth->execute($id_pole);
		if($res = $sth->fetchrow_hashref) {
				
			$serialRoot=DntFunkcije::trim($res->{'serial_root'});
			$stPol=DntFunkcije::trim($res->{'sheets_num_created'});
			$odSt=DntFunkcije::trim($res->{'od_stevilke'});
		}
	}
	#$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
							  'DntPoleZadolzi.tmpl',
					  cache => 1,
					 );
	$template->param(
		IME_DOKUMENTA => "Uredi telefonske stevilke",
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
		edb_id => $id_pole,
		date => $date,
		edb_od => $odSt,
		edb_st_pol => $stPol,
		edb_serial => $serialRoot,
	);


	$html_output = $template->output; #.$tabelica;
	return $html_output;	
}

sub PoleZbrisi(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $redirect_url;
	my @deleteIds=$q->param('brisiId');
	my $source=$q->param('brisi');
	my $template;
	my $html_output;
	my $counter=0;
	my $id;
	my $sql;
	my $sth;
	my $dbh;
	my $res;
	$id=$q->param('edb_id');
	my $numFields;

	if($source=~"nezadolzene"){	
		
		$sql="DELETE FROM sheets_series WHERE ";
				
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="series='$id' ";
				$counter++;
			}
			$sql.="OR series='$id' ";
		}	
		$redirect_url="?rm=seznam";
	
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
				return $html_output;
			}
		}
	}
	elsif($source=~"sheets"){	
		
		$sql="DELETE FROM sheets WHERE ";
				
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id_vrstce='$id' ";
				$counter++;
			}
			else{
				$sql.="OR id_vrstce='$id' ";
				$counter++;
			}
		}
		
		
		$redirect_url="?rm=sheets&id_pole=$id&uredi=1";
	
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
			$sql="SELECT sheets_deleted, sheets_num_created FROM".
					" sheets_series WHERE series=?";
			$sth = $dbh->prepare($sql);
			$sth->execute($id);
			$numFields=0;
			my $numDeleted;
			if($res = $sth->fetchrow_hashref){
				$numFields=$res->{'sheets_num_created'};
				$numDeleted=$res->{'sheets_deleted'};
			}
			
			if ($numFields==$numDeleted+$counter){
				$sql="UPDATE sheets_series SET".
						"date_delivery=NULL, sheets_deleted=0 WHERE series=?";
				$sth = $dbh->prepare($sql);
				$sth->execute($id);
				$redirect_url="?rm=seznam";
			}
			#return "$numFields, $id, $sql";
			else{			
			
				$sql="UPDATE sheets_series SET sheets_deleted=? WHERE series=?";
				$sth = $dbh->prepare($sql);
				$sth->execute($numDeleted+$counter, $id);
			}
		}
		
	}
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
	
}

sub PoleTiskaj(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $id = $q->param('id');
	my $html_output ;
	my $fileName = "";
	my $menu_pot ;
	my $template ;
	my $serialRoot;
	my $stUstvarjenih;
	my $odSt;
	
	
	my $dbh;
	my $sql;
	my $sth;
	my $res;
		
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		
			
		$sql = "SELECT * FROM sheets_series WHERE series=?";
		$sth = $dbh->prepare($sql);
		$sth->execute($id);


		if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
		{
			$serialRoot = $res->{'serial_root'};
			$stUstvarjenih = $res->{'sheets_num_created'};
			$odSt = $res->{'od_stevilke'};			
		}	
		$sql = "SELECT * FROM sheets WHERE serial_root=? ORDER BY id_vrstce DESC LIMIT 1";
		$sth = $dbh->prepare($sql);
		$sth->execute($serialRoot);
		

		if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
		{
			$fileName = substr($res->{serial_id}, 0, -1) . '.txt';		
		}	
	}	
	$template = $self->load_tmpl(	    
		'DntPoleTiskaj.tmpl',
		cache => 1,
	);
	$template->param(
		IME_DOKUMENTA => "Tiskaj pole",
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >", 
		edb_root => $serialRoot,
		edb_st => $stUstvarjenih+$odSt,
		edb_odSt => $odSt,
		edb_shrani => $fileName,
	);

	$html_output = $template->output; #.$tabelica;
	return $html_output;  
	
}
#če uporabnik ni prijavljen:
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'Pole';
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
