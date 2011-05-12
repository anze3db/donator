package DntRocniVnosi;
use base 'CGI::Application';
#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
#use strict;

use DntFunkcije;
use ObjektPogodbaObroki;
sub cgiapp_prerun {
	
    my $self = shift;
    my $q = $self->query();
	my $nivo='r';
	my $str = $q->param('rm');
	#nastavi write nivo funkcij, ki zapisujejo v bazo:
	if ($str eq 'Shrani'|| $str eq 'zbrisi' || $str eq 'uredi'){
		$nivo = 'w';
	}
	
    my $user = DntFunkcije::AuthenticateSession(34, $nivo);
	
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
    $self->start_mode('index');
    
    $self->run_modes(
        'zaporedne_stevilke' => 'zaporedne_stevilke',
	'Shrani DB' => 'btn_shrani_zap_st_db',
	'btn_prepisi_zap_st_DB' => 'btn_prepisi_zap_st_DB',
	'Direktne_br_vnos_placil' => 'Direktne_br_vnos_placil',
	'Shrani placilo' => 'Shrani_placilo_DB',
	'placaj04' => 'Placaj_direktno_db',
	'prenos04' => 'Prenesi_direktno_db',
	'vzdrzevanje_agrrement_close' => 'vzdrzevanje_agrrement_close',
	'Shrani' => 'shraniPlacilo',
    );
}

sub btn_prepisi_zap_st_DB(){
	#Pogodba, ki ze ima vpisano zaporedno stevilko prepise z novo.
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	
	my $html_output;
	my $id_agreement;
	my $napaka;
	my $napaka_opis;
	my $redirect_url= 'DntRocniVnosi.cgi?rm=zaporedne_stevilke&seja=';
	my $template;
	my $zap_st_db;
	
        my $dbh;
	my $res;
	my $sql;
        my $sth;
	$id_agreement = $q->param('id_agreement');
	$zap_st_db = $q->param('nova_zap_st');
	$dbh = DntFunkcije->connectDB;
        if ($dbh) {
            $sql = "UPDATE sfr_agreement SET zap_st_dolznika = ? WHERE id_agreement = ?";
            $sth = $dbh->prepare($sql);
			#return $sql . " " . $zap_st_db . " " . $id_agreement;
            unless($sth->execute( $zap_st_db , $id_agreement))
            {
                    $napaka_opis = $q->($sth->errstr);
                    $template = $self->load_tmpl(	    
                        'DntRocniVnosNapaka.tmpl',
			cache => 1,
		    );
                    $template->param(
                                    MENU_POT => '',
									POMOC => "<input type='button' value='?' ".
	   "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
                                    IME_DOKUMENTA => 'Napaka !',
									MENU => DntFunkcije::BuildMenu(),
                                    napaka_opis => $napaka_opis,
                                    akcija => ''
                                     );
            
                    $html_output = $template->output; #.$tabelica;
                    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
                    return $html_output;
            }
            $redirect_url .= $seja; 
            $self->header_type('redirect');
            $self->header_props(-url => $redirect_url);
            return $redirect_url;
        }
        else{
            
        }
	
}

sub Placaj_direktno_db(){
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	
	my $datum_placila;
	my $id_agreement ;
	my $pogodbaObroki = PogodbaObroki->new();
	my $redirect_url= 'DntRocniVnosi.cgi?rm=Shrani placilo';
	my $vrstica ;
	my $znesek_placila;
	
	
	$seja = $q->param('seja');
	$id_agreement = $q->param('id_agreement');
	
	$vrstica = $q->param('id_vrstica');
	
	$pogodbaObroki->{id_agreement} = $id_agreement;
	$znesek_placila = $q->param('znesek');
	$datum_placila = $q->param('edb_datum');
	
	$redirect_url .= '&edb_id_agreement='.$id_agreement.'&seja='.$seja.'&edb_datum_placila='.
			$datum_placila.'&edb_znesek_placila='.$znesek_placila;	
	#return $redirect_url;
	$pogodbaObroki->obrok_oznaci_kot_placan($id_agreement,$vrstica,$znesek_placila );
	
		$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
}


sub Prenesi_direktno_db(){
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	
	my $datum_placila;
	my $id_agreement ;
	my $pogodbaObroki = PogodbaObroki->new();
	my $redirect_url= '/cgi-bin/DntRocniVnosi.cgi?rm=Shrani placilo';
	my $vrstica ;
	my $znesek_placila;
	
	
	$seja = $q->param('seja');
	$id_agreement = $q->param('id_agreement');
	
	$vrstica = $q->param('id_vrstica');
	
	$pogodbaObroki->{id_agreement} = $id_agreement;
	$znesek_placila = $q->param('znesek');
	$datum_placila = $q->param('edb_datum');
	
	$redirect_url .= '&edb_id_agreement='.$id_agreement.'&seja='.$seja.'&edb_datum_placila='.
			$datum_placila.'&edb_znesek_placila='.$znesek_placila;	
	#return $redirect_url;
	
	$pogodbaObroki->prestavi_obrok($vrstica, $id_agreement);
	
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
	
	#return 'Direktna prenesena na nov obrok';
}

sub Shrani_placilo_DB(){
    my $self = shift;
    my $q = $self->query();
    my $seja = $q->param('seja');
    
    my $datum_obroka;
    my $datum_placila;
    my $db_id_vrstica ;
    my $db_amount ;
    my $db_amount_payed ;
    my $first_name ;
    my $html_output;
    my $id_agreement;
    my $id_donor ;
    my $id_post;
    my $installment_nr ;
    my @loop;
    my $name_company ;
    my $napaka_opis;
    my $napaka;
    my $nasel_zapis = "0";
    my $placaj ;
    my $prenos ;
    my $prefix ;
    my $scnd_name ;
    my $street ;
    my $street_number ;
    my $sum_obroki;
    my $sum_placano ;
    my $template;
    my $td_placaj ;
    my $td_prenesi_na_nov_obrok ;
    my $td_vpisi_komentar ;
    my $velikost_obroka ;
    my $vrsta_bremenitve ;
    my $vrsta_bremenitve_opis ;
    my $zap_st = 1;
    my $znesek_placano;
    my $pogodba_status="P";
    my $dbh;
    my $res;
    my $sql;
    my $sth;
	
	#prejete spremenljivke:
    $datum_placila = $q->param('edb_datum_placila');
    $id_agreement = $q->param('edb_id_agreement');
    $znesek_placano = $q->param('edb_znesek_placila');
	my $znsk = $znesek_placano;
	$znesek_placano =~ s/,/./;
	
	#shranjevanje datuma:
	DntFunkcije::SetCookie('datumPlacila', $datum_placila, 60*60*24);
    #preveri pravilnost prejetih spremenljivk:
	$napaka ='0';
    if (length($datum_placila)!=10){
		$napaka_opis = $napaka_opis."Napacen datum "."<p>";
		$napaka = '1';
		#return 0;
    }
    if (($znesek_placano+0) <= 0){
		$napaka_opis = $napaka_opis."Nepravilno vpisan znesek ".
			$znesek_placano."<p>";
		$napaka = '1';
		#return 0;
    }

    if (length(DntFunkcije::trim($id_agreement)) < 1){		
	    $napaka_opis = $napaka_opis."Stevilka pogodbe ni vpisana"."<p>";
	    $napaka = '1';
    }
    
    if ($napaka eq '1'){
		$template = $self->load_tmpl(	    
				'DntRocniVnosNapaka.tmpl',
			cache => 1,
		   );
		$template->param(
			MENU_POT => '',
			IME_DOKUMENTA => 'Napaka pri vnosu !',
			napaka_opis => $napaka_opis,
			MENU => DntFunkcije::BuildMenu(),
			akcija => ''
		 );	
		$html_output = $template->output; #.$tabelica;
		return $html_output;
    }
    #Preveri ce pogodba sploh obstaja
    $dbh = DntFunkcije::connectDB();
    $sql = "SELECT sfr_agreement.id_agreement, sfr_agreement.id_donor, ".
	    " sfr_agreement.debit_type, sfr_agreement.amount2, ".
	    " sfr_agreement.prefix, sfr_agreement.first_name,".
	    " sfr_agreement.scnd_name, sfr_agreement.street, ".
	    " sfr_agreement.street_number, sfr_agreement.id_post,".
	    " sfr_agreement.name_company, ".
	    " sfr_post.name_post ".
	    " FROM sfr_agreement, sfr_post WHERE ".
	    " id_agreement = ? AND ".
	    " sfr_agreement.id_post = sfr_post.id_post";
    $sth = $dbh->prepare($sql);
    $sth->execute($id_agreement);
    
    if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
    {
		$vrsta_bremenitve = $res->{'debit_type'};
		$velikost_obroka = $res->{'amount2'};
		$id_donor = $res->{'id_donor'};
		$prefix = $res->{'prefix'};
		$first_name = $res->{'first_name'};
		$scnd_name = $res->{'scnd_name'};
		$street = $res->{'street'};
		$street_number = $res->{'street_number'};
		$id_post = $res->{'id_post'}.' '.$res->{'name_post'};
		$name_company = $res->{'name_company'};
		#Preveri ali se znesek placila ujema z obrokom na pogodbi
		#if ($vrsta_bremenitve eq "04" && $velikost_obroka != $znesek_placano){			
		#    $napaka = '1';
		#    $napaka_opis .= $q->p("Pri direktni bremenitvi mora biti znesek placila enak obroku !");
		#    $napaka_opis .= $q->p("Velikost obroka :".$velikost_obroka);
			#$napaka_opis .= $q->button(-name=>"btn_nazaj", -value=>"Nazaj", -onClick=>"javascript:window.history.back()");
		#}
    }
    else{
		$napaka_opis = $napaka_opis."Pogodbe: ".$id_agreement.' ne najdem'."<p>";
		$napaka = '1';
    }
    #vrsta bremenitve:
	$sql = "SELECT * FROM sfr_pay_type WHERE debit_type = ?";
	$sth = $dbh->prepare($sql);
	$sth->execute($vrsta_bremenitve);
	if($res = $sth->fetchrow_hashref){		
		$vrsta_bremenitve_opis = $res->{'name_pay_type'};
	}
	else {
	    $vrsta_bremenitve_opis = 'Neznana vrsta bremenitve s }ifro:'.$id_agreement;   #$vrsta_bremenitve ;
	}
    if ($napaka eq '1'){
	    $template = $self->load_tmpl(	    
		'DntRocniVnosNapaka.tmpl',
		  cache => 1,
	    );
	    $template->param(
		MENU_POT => '',
		MENU => DntFunkcije::BuildMenu(),
		IME_DOKUMENTA => 'Napaka pri vnosu !',
		napaka_opis => $napaka_opis,
		akcija => ''
	    );
    
	    $html_output = $template->output; #.$tabelica;
	    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
	    return $html_output;
    }
    
    #Izpise se obroke da se potrdi placani obrok
    #Preveri, ce se zneski ujemajo z velikostjo obroka
    $sql = "SELECT id_vrstica, amount, amount_payed, installment_nr,".
		    " date_activate, storno FROM agreement_pay_installment WHERE "
			     ." id_agreement = ? ORDER BY installment_nr";
    $sth = $dbh->prepare($sql);
    $sth->execute($id_agreement);        
    $nasel_zapis = "0";
    $zap_st = 1;
    
	    
    $sum_obroki = 0;	
    $sum_placano = $znesek_placano;
	my $sum_ostanek = 0;
	my $zneski;
	my $id_obroki;
	my $sum_placani_obroki = 0;
	my $storno = 0.0;
    while ($res = $sth->fetchrow_hashref) {
		if($res->{storno}){
			$pogodba_status = "S";
			$sum_ostanek -= $res->{'amount_payed'};
			$storno += $res->{amount}
			
		}
	
		my $placan_obrok;
		$nasel_zapis = "1";			
		$db_id_vrstica = $res->{'id_vrstica'};	#@$vrstica[0] ;
		$db_amount = $res->{'amount'}; #@$vrstica[1];
		$db_amount_payed = $res->{'amount_payed'};  #@$vrstica[2];
		$sum_obroki = $sum_obroki + $db_amount;
		$sum_placani_obroki += $db_amount_payed;
		$installment_nr = $res->{'installment_nr'};
		if ($nasel_zapis eq '1' && !($res->{storno})){
			
			
			if($znesek_placano >= $db_amount-$db_amount_payed && $db_amount != $db_amount_payed){
				$zneski .= $db_amount.",";
				$id_obroki .= $db_id_vrstica.",";
				$znesek_placano = $znesek_placano-$db_amount+$db_amount_payed;
				$sum_ostanek += $db_amount-$db_amount_payed;
				$placan_obrok = "<b>".DntFunkcije::FormatFinancno($db_amount)."</b>";
			}
			elsif($znesek_placano > 0 && $db_amount != $db_amount_payed){
				$zneski .= $znesek_placano+$db_amount_payed.",";
				$id_obroki .= $db_id_vrstica.",";
				$sum_ostanek += $db_amount-$db_amount_payed;
				$placan_obrok = "<b>".DntFunkcije::FormatFinancno($znesek_placano+$db_amount_payed)."</b>";
				$znesek_placano = 0;			
			}
			elsif($db_amount == $db_amount_payed){
				$placan_obrok = $db_amount;
				$sum_ostanek += $db_amount-$db_amount_payed;
				
				
			}
			else{
				$placan_obrok = "0,00";
			}
			$td_placaj = $q->a({-href=>"DntRocniVnosi.cgi?rm=$placaj&".
			"id_vrstica=$db_id_vrstica&id_agreement=$id_agreement&".
			"znesek=$znesek_placano&seja=&".
			"edb_datum=$datum_placila"}, "Placano");
			$td_prenesi_na_nov_obrok = $q->a({-href=>"DntRocniVnosi.cgi?".
			"rm=$prenos&id_vrstica=$db_id_vrstica&".
			"id_agreement=$id_agreement&znesek=$znesek_placano&".
			"seja=&edb_datum=$datum_placila"}, "Prenesi na nov obrok");
			$td_vpisi_komentar = $q->a({-href=>"#",
										-id=>"uredi$db_id_vrstica",
										-onClick=>"Komentar($db_id_vrstica, $id_agreement)"}, "komentar") ;
		}
		else{
			$td_placaj = '';
			$td_prenesi_na_nov_obrok = '';
			$td_vpisi_komentar  = $q->a({-href=>"DntRocniVnosi.cgi?".
			"hid_menu=placila_direktnih_db&hid_akcija='komentar'&".
			"id_vrstica=$db_id_vrstica&id_agreement=$id_agreement&".
			"id_donor=$id_donor&seja=$seja&edb_datum=$datum_placila&".
			"id_obrok=$installment_nr"}, "komentar") ;
		}
		($datum_obroka) = DntFunkcije::si_date(
					substr($res->{'date_activate'},0,10));
		my %row = (				
			st_obroka => $res->{'installment_nr'},
			datum_obroka => $datum_obroka,
			znesek_obroka=> DntFunkcije::FormatFinancno($res->{'amount'}),
			placano => $placan_obrok,
			vpisi_komentar => $td_vpisi_komentar
		   );
		push(@loop, \%row);
		$zap_st = $zap_st +1 ;
    }
	$id_obroki = substr($id_obroki, 0, -1);
	$zneski = substr($zneski, 0, -1);
	if ($sum_ostanek - $sum_placano<0){
	    $template = $self->load_tmpl(	    
		'DntRocniVnosNapaka.tmpl',
		  cache => 1,
	    );
	    $template->param(
		MENU_POT => '',
		MENU => DntFunkcije::BuildMenu(),
		IME_DOKUMENTA => 'Napaka pri vnosu !',
		napaka_opis => "Znesek je vecji od vsote obrokov.",
		akcija => ''
	    );
    
	    $html_output = $template->output; #.$tabelica;
	    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
	    return $html_output;
    }
	
	    #print $q->Tr
	    #	(
	    #		$q->th
	    #		([
	    #			$q->p(""),
	    #			$q->p(""),
	    #			$q->p($sum_obroki),
	    #			$q->p($sum_placano),
	    #			$q->p("Odprto:".($sum_obroki - $sum_placano)),
	    #			$q->p("")
	    #		])
	    #	);
	    #print $q->end_table;
    
    $template = $self->load_tmpl(	    
        'DntRocniVnosPlacilaDirektnihBrPotrditev.tmpl',
	  cache => 1,
	);
    $template->param(
	MENU_POT => '',
	MENU => DntFunkcije::BuildMenu(),
	POMOC => "<input type='button' value='?' ".
	   "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
	obroki_loop => \@loop,
	IME_DOKUMENTA => 'Potrjevanje placila !',
	datum=> $datum_placila,
	ime_priimek_podjetje => $prefix.' '.$first_name.' '.$scnd_name.
		' '.$name_company,
	id_agreement=> $id_agreement,
	ulica_st => $street.' '.$street_number,
	placano => DntFunkcije::FormatFinancno($znsk),
	posta=> $id_post,
	sporocilce => '',
	id_obrokov => $id_obroki,
	zneski => $zneski,
	date => DntFunkcije::date_sl_to_db($datum_placila),
	vrsta_bremenitve_opis => $vrsta_bremenitve_opis,
	sum_skupaj => DntFunkcije::FormatFinancno($sum_obroki),
	sum_placano => DntFunkcije::FormatFinancno($sum_placano+$sum_placani_obroki),
	sum_odprto => "Odprto: ".DntFunkcije::FormatFinancno($sum_obroki - ($sum_placano+$sum_placani_obroki)-$storno)
	
	 );

    $html_output = $template->output; #.$tabelica;
    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
    return $html_output;
}

sub btn_shrani_zap_st_db(){
	my $self = shift;
	my $q = $self->query();
	
	my $id_agreement;
	
	my $zap_St_db;
	
	
	$id_agreement = $q->param('edb_id_agreement');
	$zap_St_db = $q->param('edb_zap_st_db');
	ZapDBPreveriJo($self,$id_agreement,$zap_St_db);
	#return 'shranjeno'.$id_agreement.$zap_St_db ;
}


sub index(){
	
}

sub Direktne_br_vnos_placil(){
    my $self = shift;
    my $q = $self->query();
    
    my $html_output;
    my $template;
    # return 'Dbvp';
    $template = $self->load_tmpl(	    
            'DntRocniVnosPlacilaDirektnihBr.tmpl',
            cache => 1,
        );
	my $datum = DntFunkcije::Cookie('datumPlacila');
    $template->param(
        MENU_POT => '',
		POMOC => "<input type='button' value='?' ".
	   "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
		MENU => DntFunkcije::BuildMenu(),
		edb_datum_placila => $datum,
        IME_DOKUMENTA => 'Rocni vnos placil:',
        );
    $html_output = $template->output; #.$tabelica;
    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
    return $html_output;
}

sub Shrani_zap_st_db{
	#shrani zaporedno stevilko bremenitve
	return "OMG";
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	
	my $id_agreement = shift;
	my $zap_st_dolznika = shift;
	
	my $redirect_url= 'DntRocniVnosi.cgi?rm=btn_prepisi_zap_st_DB&seja=';
	$redirect_url .= $seja;
	$redirect_url .= '&id_agreement='.$id_agreement.'&nova_zap_st='.$zap_st_dolznika;
	
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;	
}

sub ZapDBPreveriJo($$){
    #Prever, ce je vse OK za vpisano zaporedno stevilko
    my $self = shift;
    my $q = $self->query();	
    my $id_agreement = shift;
    my $zap_st_dolznika = shift;
    
    my $akcija;
    my $html_output;
    my $napaka;
    my $napaka_opis;
    my $template;    
    my $ze_vpisan_zap_st_dolznika;	
    
    my $dbh;
    my $res;
    my $sql;
    my $sth;
    my $isok = 1;
    my $nasel_pogodbo = '0';
    #my $jsKontrola;
    my $errstr;
    $napaka = '0';
	
    if (length(DntFunkcije::trim($zap_st_dolznika)) < 1){
	$napaka = '1';
	$napaka_opis = 'Zaporedna stevilka dolznika ni vpisana';
    }
	
    #Najprj preveri ce je zap_st_dolznika ze vpisana
	
    if ($dbh = DntFunkcije->connectDB()){
		$napaka = '0';
	}
	else{
		return 'napaka'; #.$dbh->errstr;
	}
	
	
    $sql = "SELECT zap_st_dolznika FROM sfr_agreement WHERE id_agreement = ?";
	#return $sql;
    $sth = $dbh->prepare($sql);
	#return 'napaka'.$sth->errstr;
    $sth->execute($id_agreement);
	#return $napaka.' '.$napaka_opis;	
    if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
    {
        $ze_vpisan_zap_st_dolznika = DntFunkcije::trim($res->{'zap_st_dolznika'});
	    $nasel_pogodbo = '1';
	    $akcija ='';
	    #$ze_vpisan_zap_st_dolznika = DntFunkcije::trim("123ad");
	}
		
	if (length($ze_vpisan_zap_st_dolznika) > 0){
		
	    #pomeni da je za to pogodbo zaporedna st. dolznika ze vpisana, preveri ce je enaka
	    if ($ze_vpisan_zap_st_dolznika eq $zap_st_dolznika){
		#Opozoro, da ima ta pogodba ze vpisano zap_st_db, Vrne se na vnos za vpisZap_st_DB
		$napaka = '1';
		$napaka_opis = "Zaporedna stevilka :".$zap_st_dolznika." je ze vpisana za to pogodbo ".$id_agreement;
		$akcija = $q->a({-href =>"DntRocniVnosi.cgi?rm=zaporedne_stevilke"}, "Vnos nove Zap. st. dolznika");
		#print $q->p($q->a({-href =>"DntRocniVnosi.pl?hid_menu=zaporedne_stevilke"}, "Vnos nove Zap. st. dolznika"));
	    }
	    else {
		$napaka = '1';
		$napaka_opis = "Pogodba :".$id_agreement." ima ze vpisano zaporedno stevilko ".$ze_vpisan_zap_st_dolznika;
		$akcija = $q->p("prepisi z novo {t:".$zap_st_dolznika .'  '.
		    $q->a({-href =>"DntRocniVnosi.cgi?rm=btn_prepisi_zap_st_DB&id_agreement=".$id_agreement."&nova_zap_st=".$zap_st_dolznika}, "DA")."   ".
		    $q->a({-href =>"DntRocniVnosi.cgi?rm=zaporedne_stevilke"}, "NE"));
		
		#print $q->p("pogodba :".$id_agreement." ima ze vpisano zaporedno stevilko ".$ze_vpisan_zap_st_dolznika);
		#print $q->param("hid_menu","");
		#print $q->param("hid_akcija","");
		
		#print $q->p("prepisi : ".$q->a({-href =>"DntRocniVnosi.pl?hid_menu=btn_prepisi_zap_st_DB&hid_akcija=btn_prepisi_zap_st_DB&id_agreement=".$id_agreement."&nova_zap_st=".$zap_st_dolznika}, "DA")."   ".
		#			$q->a({-href =>"DntRocniVnosi.pl?hid_menu=zaporedne_stevilke"}, "NE")); #  NE");
		#
	    }
		
	}
	else{

	    #Vse je OK, zato jo zapise
	    if ($nasel_pogodbo eq '1'){
			$napaka = '0';
			#PotrdiNovoZapStDBZapisi($self,$id_agreement, $zap_st_dolznika);
			my $redirect_url= 'DntRocniVnosi.cgi?rm=btn_prepisi_zap_st_DB&seja=';
			
			$redirect_url .= '&id_agreement='.$id_agreement.'&nova_zap_st='.$zap_st_dolznika;
			#return $redirect_url;
			$self->header_type('redirect');
			$self->header_props(-url => $redirect_url);
			return $redirect_url;	
	    }
	    else {
		$napaka = '1';
		$napaka_opis = "Ne najdem pogodbe st.:".$id_agreement;
		$akcija = $q->button(-name=>"btn_nazaj", -value=>"Nazaj", -onClick=>"javascript:window.history.back()");
		#print $q->p("ne najdem pogodbe st.:".$id_agreement);
		#print $q->button(-name=>"btn_nazaj", -value=>"Nazaj", -onClick=>"javascript:window.history.back()");				
	    }
	}
	if ($napaka eq '1'){
	    $template = $self->load_tmpl(	    
		'DntRocniVnosNapaka.tmpl',
		cache => 1,
	       );
	    $template->param(
		MENU_POT => '',
		POMOC => "<input type='button' value='?' ".
	   "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
		MENU => DntFunkcije::BuildMenu(),
		IME_DOKUMENTA => 'Napaka pri vnosu !',
		napaka_opis => $napaka_opis,
		akcija => $akcija
	     );

	    $html_output = $template->output; #.$tabelica;
	    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
	    return $html_output;
	}
	
    
    
}

sub zaporedne_stevilke(){
	my $self = shift;
	my $q = $self->query();
	
	my $html_output;
	my $template;
	#return 'zs';
	$template = $self->load_tmpl(	    
            'DntRocniVnosZaporednaSt.tmpl',
            cache => 1,
	 );
	
		
		
		$template->param(
				MENU => DntFunkcije::BuildMenu(),
				POMOC => "<input type='button' value='?' ".
	   "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
				MENU_POT => '',
				IME_DOKUMENTA => 'Rocni vnosi:',
				);
		$html_output = $template->output; #.$tabelica;
		#$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
		return $html_output;
}

sub vzdrzevanje_agrrement_close(){
	my $self = shift;
	my $q = $self->query();
	my $rez;
	
	my $dbh;
	my $sql;
	my $sth;
	$rez = $q->p("generiram tabelo zapiranje pogodb");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
		$sql = "CREATE TABLE agreement_close (".
				" id_row serial,".
				" id_agreement char(13),". 		#stevilka pogodbe
				" num_installments int,".
				" payed numeric(10,2),".
				" storno_installments int,".
				" must_be_payed numeric(10,2),".
				" last_installment timestamp, ".
				" id_project int,".
				" id_staff int,".
				" id_event char(2),".
				" debit_type char(2),".
				" noticed char(1),". 		#'1'-sporocilo poslano 
				" CONSTRAINT agreement_close_pkey PRIMARY KEY (id_row) )".
				" WITHOUT OIDS ;".
				" ALTER TABLE agreement_close OWNER TO postgres ;";
        $rez .=  $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			$rez .=  $q->p(" tabela datoteke_poslane je zgenerirana");
		}
		else{
			$rez .=  $q->p("napaka ! tabela datoteke_poslane ni uspelo zgenerirati");
		}
	}
	return $rez;
}
sub shraniPlacilo(){
	my $self = shift;
    my $q = $self->query();	
    my $id_obrokov = $q->param('id_obrokov');
	my $zneski = $q->param('zneski');
	my $date = $q->param('date');
    my @id = split(",", $id_obrokov);
	my @zn = split(",", $zneski);
	my $sql;
	my $sth;
	my $dbh;

	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
	for(my $i = 0; $i<@id; $i++){	
        
            $sql = "UPDATE agreement_pay_installment SET amount_payed = '$zn[$i]', date_due = '$date'  WHERE id_vrstica = '$id[$i]'";
            $sth = $dbh->prepare($sql);
            unless($sth->execute())
            {
                    $napaka_opis = $q->($sth->errstr);
                    $template = $self->load_tmpl(	    
                        'DntRocniVnosNapaka.tmpl',
			cache => 1,
		    );
                    $template->param(
                                    MENU_POT => '',
                                    IME_DOKUMENTA => 'Napaka !',
									MENU => DntFunkcije::BuildMenu(),
                                    napaka_opis => $napaka_opis,
                                    akcija => ''
                                     );
            
                    $html_output = $template->output; #.$tabelica;
                    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
                    return $html_output;
			}
			
	}
	$sql = "SELECT id_agreement FROM agreement_pay_installment WHERE id_vrstica=?";
	$sth = $dbh->prepare($sql);
	$sth->execute($id[0]);
	my $res = $sth->fetchrow_hashref;
	my $id_pogodbe = $res->{'id_agreement'};
	#preveri ce je pogodba zakljucena:
	$dbh->disconnect();
	my $pogodbaObroki = PogodbaObroki->new();
	$pogodbaObroki->preveri_pogodba_zakljucena($id_pogodbe, $self);
	}
	my $redirect_url='DntRocniVnosi.cgi?rm=Direktne_br_vnos_placil';
	$self->header_type('redirect');
    $self->header_props(-url => $redirect_url);
	return $redirect_url;
	
	
}
#če uporabnik ni prijavljen:
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'DntRocniVnosi.cgi?rm=Direktne_br_vnos_placil';
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
1;
