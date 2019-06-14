package DntPogodbe;
use base 'CGI::Application';
#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use strict;
use DBI;
#use HTML::Template;
#use CGI::Session;
#use Data::Dumper;
use DntFunkcije;
use ObjektPogodba;
use ObjektPogodbaObroki;

#authenticate:
sub cgiapp_prerun {
	
    my $self = shift;
    my $q = $self->query();
	my $nivo='r';
	my $str = $q->param('rm');
	#nastavi write nivo funkcij, ki zapisujejo v bazo:
	if ($str eq 'Potrdi stornacijo izbranih obrokov' || 
		$str eq 'spremeni nacin bremenitve' || 
		$str eq 'spremeni FREKVENCO bremenitve' || 
		$str eq 'storniraj obroke' ||
		$str eq 'shrani spremembo nacin bremenitve' ||
		$str eq 'prenesi_obrok'|| $str eq 'shrani_pogodbo' ||
		$str eq 'zbrisi'|| $str eq 'dodaj' ||
		$str eq 'spremeni'|| $str eq 'opomin_shrani'){
		$nivo = 'w';
	}
	
    my $user = DntFunkcije::AuthenticateSession(21, $nivo);
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
    $self->start_mode('PogodbeSeznam');
    $self->run_modes(
        'seznam' => 'PogodbeSeznam',
	'Prikazi zaprte' => 'Potrdila_o_placanih_obrokih_prikazi',
	'Donatorji' => 'SfrDonatorji',	#
	'Izvozi in zapri' => 'Potrdila_o_placanih_obrokih_zapri',
	'Nova pogodba' => 'PogodbaUredi',
	'Prikazi' => 'PogodbeSeznam', 
	'uredi_pogodbo' => 'PogodbaUredi', #
	'Potrdi stornacijo izbranih obrokov' => 'Shrani_spremembo_obroka',
	'Potrdila_o_placanih_obrokih' => 'Potrdila_o_placanih_obrokih',
	'spremeni nacin bremenitve' => 'Spremeni_nacin_bremenitve',
	'spremeni FREKVENCO bremenitve' => 'Spremeni_FREKVENCO_bremenitve',
	'storniraj obroke' => 'StornirajObroke',
	'shrani spremembo nacin bremenitve' => 'Shrani_spremembo_obroka',
	'shrani spremembo frekvence' => 'Shrani_spremembo_obroka',
	'prenesi_obrok' => 'PrenosNaNovObrok',
	'Zahtevki_za_zapiranje' => 'ZahtevkeZaZapiranjePrikazi',
	'shrani_pogodbo' => 'PogodbaShrani',
	'zbrisi' => 'PogodbeZbrisi',
	'komentar' => 'PogodbeKomentar',
	'komentarShrani' => 'PogodbeKomentar',
	'pogodba_komentar' => 'Komentar',
	'dodaj' => 'KomentarShrani',
	'spremeni' => 'KomentarShrani',
	'opomini' => 'PogodbaOpomin',
	'opomin_shrani' => 'OpominiShrani',
	'zapri_pogodbo_izpis' => 'ZapriPogodboIzpis',
	'login' => 'Login',
	'error' => 'Error'
    );
	
}


sub PogodbeSeznam{
	
    my $self = shift;
    my $q = $self->query();
	my $seja  ;
	
	my $html_output ;
	my $pogodba;
	my $ime;
	my @loop;
	my $menu_pot;
	my $poKorenuIme;
	my $poKorenuPriimek;
	my $priimek;
	my $ulica;
	my $posta;
	my $uporabnik;
    my $template ;
	
	$self->param(testiram =>'rez');
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	$pogodba = $q->param('edb_pogodba');
	$ime  = $q->param('edb_ime');
	$poKorenuIme = $q->param('po_korenu_ime');
	$priimek = $q->param('edb_priimek');
	$poKorenuPriimek = $q->param('po_korenu_priimek');
	$ulica = $q->param('edb_ulica');
	$posta= $q->param('edb_posta');
	
	my $poKorenuUlica =$q->param('po_korenu_ulica');
    
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntPogodbeSeznam.tmpl',
			      cache => 1,
			     );
    $template->param(
		     #MENU_POT => $menu_pot,
			 IME_DOKUMENTA => 'Seznam pogodb',
			 
			 POMOC => "<input type='button' value='?' onclick='".
			 "Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
			 MENU => DntFunkcije::BuildMenu()
			 
		     );
	#Ce so se parametri za poizvedbo izpise rezultat
	#if (length($pogodba.$ime.$priimek.$ulica)>0){
    my $dbh;
	my $res;
	my $sql;
	my $sth;
	
	my $hid_sort = $q->param("hid_sort");
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		$sql = "select id_agreement, id_donor, name_company, first_name, scnd_name, date_enter,";
		$sql.= " street, id_post from sfr_agreement ";
		$sql.= " where 1=1";
		if($pogodba)
		{
				$sql .= " and id_agreement ilike '$pogodba%'";
		}
		if($ime)
		{
			if ($poKorenuIme){
				$sql .= " and first_name ilike '%$ime%'";
				$poKorenuIme="checked='checked'";
			}
			else{
				$sql .= " and first_name ilike '$ime%'";
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
			}
		}
		if($ulica)
		{	
			if ($poKorenuUlica){
				$sql .= " and street ilike '%$ulica%'";
				$poKorenuUlica="checked='checked'";
			}
			else{
				$sql .= " and street ilike '$ulica%'";
			}
		}
		if($posta)
		{	
			$sql .= " and CAST(id_post as varchar) ilike '$posta%'";
		}
		
		$sql.= " ORDER BY date_enter DESC LIMIT 16";
		#return $sql;
		$sth = $dbh->prepare($sql);
		$sth->execute();
		while ($res = $sth->fetchrow_hashref) {
				
			my %row = (				
				izbor => $q->a({-href=>"DntPogodbe.cgi?".
					"rm=uredi_pogodbo&id_agreement=$res->{'id_agreement'}".
					"&seja=&uredi=1"}, 'uredi'),
				id_agreement => DntFunkcije::trim($res->{'id_agreement'}),
				podjetje => DntFunkcije::trim($res->{'name_company'}),
				ime => DntFunkcije::trim($res->{'first_name'}),
				priimek => DntFunkcije::trim($res->{'scnd_name'}),
				naslov => DntFunkcije::trim($res->{'street'}),
				posta => DntFunkcije::trim($res->{'id_post'}),
				#brisi => DntFunkcije::trim($res->{'id_donor'})
			);

				# put this row into the loop by reference             
				push(@loop, \%row);
		}
		$template->param(donator_loop => \@loop,
				edb_pogodba => DntFunkcije::trim($pogodba),
				edb_ime => DntFunkcije::trim($ime),
				edb_priimek => DntFunkcije::trim($priimek),
				edb_korenIme => $poKorenuIme,
				edb_korenPriimek => $poKorenuPriimek,
				edb_korenUlica => $poKorenuUlica,
				edb_ulica => DntFunkcije::trim($ulica),
				edb_posta => DntFunkcije::trim($posta)
				);			
	}
	else{
		return 'Povezava do baze ni uspela';
	}
                
	#}
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}

sub PogodbaUredi() {
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	
	my $aktivirajDne;
	my $amount=0;
	my $amount1=0;
	my $amount2=0;
	my $emso;
	my $frekvenca;
	my $fr08;
	my $fr18;
	my $fr28;
	my $gospod;
	my $gospa;
	my $id_donor;
	my $ime;
	my $imePoste;
	my $datumVnosa;
	my $datumPogodbe;
	my $datumRojstva;
	my $davcnaSt;
	my $davcniZavezanec;
	my $danRojstva;
	my $mesecRojstva;
	my $letoRojstva;	
	my $hisnaSt;
	my $nacinPlacila;
	my $nacinG1;
	my $nacinC1;
	my $posiljanjeOpominov;
	my $num_installments;
	my $onload;
	my $opominiGumb;
	my $placanDne;
	my $podaljsanjePogodbe;
	my $podjetje;
	my $pokrovitelj;
	my $postnaSt;	
	my $prednaziv;
	my $priimek;
	my $selectPlacilo;
	my $selectObremenitev;
	my $staraPogodba;
	my $status;
	my $statusF;
	my $statusP;
	my $status_kontrole;
	my $trr;
	my $approval;
	my $approvalDate;
	my $ulica;
	my $upokojenec;
	my $uredi=DntFunkcije::trim($q->param('uredi'));
	my $urejanje;
	my $valuta=0;
	my $vrstaBremenitve;
	my $zap_st_dolznika ;
	my $znesek;
	
	my $hid_id;
	my $hid_status;
	my $hid_podjetje;
	my $hid_prednaziv;
	my $hid_ime;
	my $hid_priimek;
	my $hid_ulica;
	my $hid_hisnaSt;
	my $hid_postnaSt;
	my $hid_davcnaSt;
	my $hid_davcniZavezanec;
	my $hid_datumRojstva;
	my $hid_emso;	
	my $hid_upokojenec;
	my $vneseno;
	my $nazajBtn=DntFunkcije::trim($q->param('nazaj')) || "pogodbe";
	my $nazajLink=DntFunkcije::trim($q->param('nazaj'));
	my $now=localtime;
	$now=substr($now, -2, 2);

	
	
	my @loop4;
	my @loop5;
	my @loop6;
	my @loop7;
	my @loop8;
	my @loop9;
	my @loop10;
	my @loop_opomini;
	my $dbh;
	my $sql;
	my $sth;
	my $res;
	my $tmp;
	
	my $count_comments;
	my $html_output ;
	my $id_agreement = $q->param('id_agreement');
	my $menu_pot ;
	my $template ;
    $template = $self->load_tmpl(	    
		'DntPogodbaEdit.tmpl',
		cache => 1,
	);
	if (defined $uredi && $uredi==1){
		$uredi="1";
	}
	my $unique_id;
	if(!$id_agreement){
		$unique_id=time();
	}
	
    
	if (defined $id_agreement){
	    $urejanje = '1';
		$vneseno='1';
		$status_kontrole = 'readonly';		
		#Pokaze pogodbo
		#$template = Pokazi_pogodbo($self,$id_agreement);
		$dbh = DntFunkcije->connectDB;
		
		if ($dbh) {
			
			$sql = "SELECT * FROM sfr_post ORDER BY id_post";			
			
			$sth = $dbh->prepare($sql);
			$sth->execute();
				
				while($res = $sth->fetchrow_hashref){
					my %row = (
						id_post => $res->{'id_post'},
					    name_post => DntFunkcije::trim($res->{'name_post'}),
					);
					push(@loop4, \%row);
				}
				
			$sql = "SELECT  * ".
			" FROM sfr_agreement  "
						." WHERE id_agreement =?";
			
			$sth = $dbh->prepare($sql);
			$sth->execute($id_agreement);		
					
			if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
			{
				$datumVnosa=$res->{'date_enter'};
				$datumPogodbe=$res->{'date_agreement'};
				$id_donor=$res->{'id_donor'};
				$status=$res->{'entity'};
				$podjetje=$res->{'name_company'};
				$prednaziv=$res->{'prefix'};
				$ime = $res->{'first_name'};
				$priimek = $res->{'scnd_name'};
				$ulica =$res->{'street'};
				$hisnaSt= $res->{'street_number'};
				$postnaSt= $res->{'id_post'};
				$davcnaSt=$res->{'tax_number'};
				$davcniZavezanec=$res->{'liable_for_tax'};
				$datumRojstva=$res->{'born_date'};
				$emso = $res->{'emso'};
				$pokrovitelj=$res->{'pokrovitelj'};
				$podaljsanjePogodbe=$res->{'podaljsanje_pogodbe'};
				$upokojenec=$res->{'retired'};
				$staraPogodba=$res->{'stara_pogodba'};
				$posiljanjeOpominov=$res->{'ne_posiljaj_opomine'};
				$nacinPlacila=$res->{'pay_type1'} || "";
				$frekvenca=$res->{'frequency'};
				$placanDne=$res->{'date_1st_amount'};
				$trr=$res->{'bank_account2'};
				$approval=$res->{'approval'};
				$approvalDate=$res->{'approval_date'};
				$vrstaBremenitve=$res->{'pay_type2'};
				$aktivirajDne=$res->{'start_date'};
				$amount1= $res->{'amount1'};
				$num_installments= $res->{'num_installments'};
				$amount2= $res->{'amount2'};
				$amount= $res->{'amount'};
				$valuta= $res->{'valuta'};
				$zap_st_dolznika = $res->{'zap_st_dolznika'};
				$znesek= $res->{'amount2'};
				
			}
			
			$sql = "SELECT  * ".
			" FROM sfr_donor  "
						." WHERE id_donor =?";
			
			$sth = $dbh->prepare($sql);
			$sth->execute($id_donor);		
			#nastavijo se skrita polja (za preverjanje sprememb po vnosu iz donatorjev)		
			if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
			{
				
				$hid_id=$res->{'id_donor'};
				$hid_status=$res->{'entity'};
				$hid_podjetje=$res->{'name_company'};
				$hid_prednaziv=$res->{'prefix'};
				$hid_ime = $res->{'first_name'};
				$hid_priimek = $res->{'scnd_name'};
				$hid_ulica =$res->{'street'};
				$hid_hisnaSt= $res->{'street_number'};
				$hid_postnaSt= $res->{'post'};
				$hid_davcnaSt=$res->{'tax_number'};
				$hid_davcniZavezanec=$res->{'liable_for_tax'};
				$hid_datumRojstva=$res->{'born_date'};
				$hid_emso = $res->{'emso'};	
				$hid_upokojenec=$res->{'retired'};		
				
			}
			
			$sql = "SELECT *"
					." FROM sfr_post "
					." WHERE id_post =?";
			
			$sth = $dbh->prepare($sql);
			$sth->execute($postnaSt);
			
			if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
			{
				$imePoste =$res->{'name_post'};
				
			}
			#pokaze obroke
			$template = Pokazi_obroke_pogodbe(
						$self,
						$id_agreement,
						$template,
						$znesek
						);		
		}
	}
	
	else{
		#Gre se za vnos nove pogodbe
		$urejanje ='0';
		$onload="onload=\"Uredi();\"";
		$status_kontrole = '';#'readonly';
	}
	my $id_staff="";
	if(defined $id_agreement){
		$id_staff= substr($id_agreement, 5, 3);
	}
	my $staff_name = "";
	$dbh = DntFunkcije->connectDB;
	if($dbh){
		
		$sql = "SELECT * FROM sfr_post ORDER BY id_post";		
		$sth = $dbh->prepare($sql);
		$sth->execute();
				
			while($res = $sth->fetchrow_hashref){
				
				my %row = (id_post => $res->{'id_post'},
					name_post => DntFunkcije::trim($res->{'name_post'}),						   
				);
				push(@loop4, \%row);
				
			}
		$sql = "SELECT * FROM sfr_pay_type ORDER BY id_pay_type";			
		
		$sth = $dbh->prepare($sql);
		$sth->execute();
				
		while($res = $sth->fetchrow_hashref){
			
			if(defined $nacinPlacila && $nacinPlacila eq $res->{'debit_type'}){
				$selectPlacilo="selected=\"selected\"";
			}
			else{
				$selectPlacilo="";
			}
			
			my %row = (tip => DntFunkcije::trim($res->{'debit_type'}),
					ime => DntFunkcije::trim($res->{'name_pay_type'}),
					izbran => $selectPlacilo,						
			);
			push(@loop5, \%row);
			
		}
		$sql = "SELECT * FROM sfr_pay_type ORDER BY id_pay_type";			
		
		$sth = $dbh->prepare($sql);
		$sth->execute();
				
		while($res = $sth->fetchrow_hashref){
			
			if(defined $vrstaBremenitve && $vrstaBremenitve eq $res->{'debit_type'}){
				$selectPlacilo="selected=\"selected\"";
				#return $vrstaBremenitve;
			}
			else{
				$selectPlacilo="";
			}
			
			my %row = (tip => DntFunkcije::trim($res->{'debit_type'}),
				ime => DntFunkcije::trim($res->{'name_pay_type'}),
				izbran => $selectPlacilo,   
				);
			push(@loop10, \%row);
			
		}		
		while($now >= 6){
			
			if(length($now)<2){
				$now="0$now";
			}				
			
			my %row = (datum => $now--);						   
					   
			push(@loop6, \%row);					
		}
		$sql = "SELECT * FROM sfr_project ORDER BY id_project";			
		my $tmp2;
		$sth = $dbh->prepare($sql);
		$sth->execute();
			
		while($res = $sth->fetchrow_hashref){
			
			if($res->{'id_project'}<10){
				$tmp="0".DntFunkcije::trim($res->{'id_project'});
			}					
			else{
				$tmp=DntFunkcije::trim($res->{'id_project'});
			}
			if($res->{'id_project'}==1){
				$tmp2="onchange=javascript:Dogodek();";
			}
			else{
				$tmp2="";
			}
			my %row = (id => DntFunkcije::trim($res->{'id_project'}),
					   id_lep => $tmp,
					   onclick=> $tmp2,
					   ime => DntFunkcije::trim($res->{'name_project'}),
			
					   );
			push(@loop7, \%row);			
		}
			
		$sql = "SELECT * FROM sfr_events ORDER BY id_event";			
		
		$sth = $dbh->prepare($sql);
		$sth->execute();
		
		while($res = $sth->fetchrow_hashref){
			
			$tmp=DntFunkcije::trim($res->{'id_event'});
			
			
			my %row = (id => $tmp,
					   ime => DntFunkcije::trim($res->{'name_event'}),
					   
			
					   );
			push(@loop8, \%row);
			
		}
		
		$sql = "SELECT * FROM sfr_staff ORDER BY id_staff";	
		$sth = $dbh->prepare($sql);
		$sth->execute();				
		while($res = $sth->fetchrow_hashref){
			
			if($res->{'id_staff'}<10){
				$tmp="00".DntFunkcije::trim($res->{'id_staff'});
			}
			elsif($res->{'id_staff'}<100){
				$tmp="0".DntFunkcije::trim($res->{'id_staff'});
			}
			else{
				$tmp=DntFunkcije::trim($res->{'id_staff'});
			}
			if($id_staff eq $tmp){
				$staff_name = $id_staff." ".DntFunkcije::trim($res->{'first_name'})." ".DntFunkcije::trim($res->{'scnd_name'});
			}
			my %row = (id => $tmp,
				ime => DntFunkcije::trim($res->{'first_name'}),
				priimek => DntFunkcije::trim($res->{'scnd_name'}),
			
					   );
			push(@loop9, \%row);			
		}
		
		$sql = "SELECT * FROM agreement_notice ".
				"WHERE id_agreement=? ORDER BY datum";	
		$sth = $dbh->prepare($sql);
		$sth->execute($id_agreement);
		my $stev=1;
		while($res = $sth->fetchrow_hashref){
			
			my %row = (
				datum => "<br /> <span style=\"margin-left:5px;\">".DntFunkcije::sl_date(DntFunkcije::trim($res->{'datum'}))."</span>",	
			);
			
			push(@loop_opomini, \%row);	
		}
		my $lp = @loop_opomini;
		if($lp < 1){
			my %row = (
				datum => "/",	
			);
			
			push(@loop_opomini, \%row);	
		}
		
		$sql = "SELECT * FROM sfr_agreement_comment WHERE id_agreement=?";			
		$sth = $dbh->prepare($sql);
		$sth->execute($id_agreement);
		my $counter=0;
		while($res = $sth->fetchrow_hashref){
			$counter++;
					
		}
		if($counter>0){
			$count_comments='style="font-weight:bold;"';
		}
				
	
	}
	if(defined $datumVnosa){
		$datumVnosa=substr($datumVnosa, 8,2)."/".
					substr($datumVnosa, 5,2)."/".
					substr($datumVnosa, 0,4);
	}
	if(defined $approvalDate){
		$approvalDate=substr($approvalDate, 8,2)."/".
					substr($approvalDate, 5,2)."/".
					substr($approvalDate, 0,4);
	}
	if(defined $datumPogodbe){
		$datumPogodbe=substr($datumPogodbe, 8,2)."/".
					  substr($datumPogodbe, 5,2)."/".
					  substr($datumPogodbe, 0,4);
	}
	if(defined $aktivirajDne){
		$aktivirajDne=substr($aktivirajDne, 8,2)."/".
					  substr($aktivirajDne, 5,2)."/".
					  substr($aktivirajDne, 0,4);
	}
	if(defined $placanDne){
		$placanDne=substr($placanDne, 8,2)."/".
				   substr($placanDne, 5,2)."/".
				   substr($placanDne, 0,4);
	}
	if(defined $status && $status==0){
			$statusF="checked=\"checked\"";
			$statusP="";
		}
	else{
		$statusP="checked=\"checked\"";
		$statusF="";
	}
	$prednaziv = lc DntFunkcije::trim($prednaziv);

	if($prednaziv eq "gospa"){
			$gospa="selected=\"selected\"";
			$gospod="";
		}
	elsif($prednaziv eq "gospod"){
		$gospod="selected=\"selected\"";
		$gospa="";
	}
	else{
		
		$gospod = uc $prednaziv;
		$gospa = $prednaziv;
	}
	if(defined $frekvenca){	
		if($frekvenca=~"18"){
			$fr18="selected=\"selected\"";
		}
		if($frekvenca=~"28"){
			$fr28="selected=\"selected\"";
		}
		if($frekvenca=~"08"){
			$fr08="selected=\"selected\"";
		}
	}
	if($nacinPlacila eq "C1"){
		$nacinC1 = "selected=\"selected\"";
	}
	elsif($nacinPlacila eq "G1"){
		$nacinG1 = "selected=\"selected\"";
	}
	if(defined $upokojenec && $upokojenec==1){
			$upokojenec="checked=\"checked\"";
	}
	else{
		$upokojenec="";
	}
	if(defined $posiljanjeOpominov && $posiljanjeOpominov==1){
			$posiljanjeOpominov="checked=\"checked\"";
	}
	else{
		$posiljanjeOpominov="";
	}
	if(defined $staraPogodba && $staraPogodba==1){
			$staraPogodba="checked=\"checked\"";
	}
	else{
		$staraPogodba="";
	}
	if(defined $podaljsanjePogodbe && $podaljsanjePogodbe==1){
			$podaljsanjePogodbe="checked=\"checked\"";
	}
	else{
		$podaljsanjePogodbe="";
	}
	if(defined $pokrovitelj && $pokrovitelj==1){
			$pokrovitelj="checked=\"checked\"";
	}
	else{
		$pokrovitelj="";
	}
	if(defined $davcniZavezanec && $davcniZavezanec==1){
			$davcniZavezanec="checked=\"checked\"";
	}
	else{
		$davcniZavezanec="";
	}
	if(defined $datumRojstva){
	$letoRojstva = substr($datumRojstva,0,4);
	$danRojstva = substr($datumRojstva,8,2);
	$mesecRojstva = substr($datumRojstva,5,2);
	}
	my $hid_letoRojstva;
	my $hid_danRojstva;
	my $hid_mesecRojstva;
	if(defined $hid_datumRojstva){
		$hid_letoRojstva = substr($hid_datumRojstva,0,4);
		$hid_danRojstva = substr($hid_datumRojstva,8,2);
		$hid_mesecRojstva = substr($hid_datumRojstva,5,2);
	}
	if($amount != 0){
	$amount = substr($amount, 0, length($amount)-3).",".
			  substr($amount, length($amount)-2, 2);
	}
	else{
		$amount = "";
	}
	if($amount1 != 0){
	$amount1 = substr($amount1, 0, length($amount1)-3).",".
			   substr($amount1, length($amount1)-2, 2);
	}
	else{
		$amount1 = "";
	}
	if($amount2 != 0){
	$amount2 = substr($amount2, 0, length($amount2)-3).",".
			   substr($amount2, length($amount2)-2, 2);
	}
	else{
		$amount2 = "";
	}
	
	if($valuta==0){
		$valuta="";
	}
	my $return_url = $q->param('return');
	if($return_url){
		$return_url =~ s/\///;
		$return_url =~ s/_amp_/&/g;
	}
	#return $return_url;
	if($nazajBtn eq "donator"){
		$nazajBtn="DntDonatorji.cgi?rm=uredi_donatorja&seja=&id_donor=$id_donor";		
	}
	elsif($nazajBtn eq "obroki"){
		$nazajBtn="DntObroki.cgi?rm=seznam";
	}
	elsif($nazajBtn eq "obrokiIzvoz"){
		$nazajBtn=$return_url;
	}
	elsif($nazajBtn eq "potrdila"){
		$nazajBtn=$return_url;
	}
	elsif($nazajBtn eq "opomini"){
		$nazajBtn=$return_url;
	}
	elsif($nazajBtn eq "zahtevki"){
		$nazajBtn=$return_url;
	}
	elsif($nazajBtn eq "nepotrjene"){
		$nazajBtn=$return_url;
	}
	else{
		$nazajBtn="?rm=seznam&seja=";
	}
	
	$menu_pot = $q->a({-href=>"dntStart.cgi"}, "Zacetek")  ;
	$template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'Podatki o pogodbi:'.$id_agreement,
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
		edb_id_agreement => DntFunkcije::trim($id_agreement),
		edb_datumVnosa => DntFunkcije::trim($datumVnosa),
		edb_datumPodpisa => DntFunkcije::trim($datumPogodbe),
		edb_id_donator => DntFunkcije::trim($id_donor),
		edb_statusF => DntFunkcije::trim($statusF),
		edb_statusP => DntFunkcije::trim($statusP),
		edb_podjetje => DntFunkcije::trim($podjetje),
		edb_gospod => DntFunkcije::trim($gospod),
		edb_gospa => DntFunkcije::trim($gospa),
		edb_upokojenec => DntFunkcije::trim($upokojenec),
		edb_stara_pogodba => DntFunkcije::trim($staraPogodba),
		edb_opomin => DntFunkcije::trim($posiljanjeOpominov),
		edb_ime => DntFunkcije::trim($ime),
		edb_priimek => DntFunkcije::trim($priimek),
		edb_ulica => DntFunkcije::trim($ulica),
		edb_hisnaSt => DntFunkcije::trim($hisnaSt),
		edb_postnaSt => DntFunkcije::trim($postnaSt),
		edb_imePoste => DntFunkcije::trim($imePoste),
		edb_davcnaSt => DntFunkcije::trim($davcnaSt),
		edb_davcniZavezanec => DntFunkcije::trim($davcniZavezanec),
		edb_danRojstva => DntFunkcije::trim($danRojstva),
		edb_mesecRojstva => DntFunkcije::trim($mesecRojstva),
		edb_letoRojstva => DntFunkcije::trim($letoRojstva),
		edb_emso => DntFunkcije::trim($emso),
		
		hid_id => DntFunkcije::trim($hid_id),
		hid_status => DntFunkcije::trim($hid_status),
		hid_podjetje => DntFunkcije::trim($hid_podjetje),
		hid_prednaziv => DntFunkcije::trim($hid_prednaziv),
		hid_upokojenec => DntFunkcije::trim($hid_upokojenec),
		hid_ime => DntFunkcije::trim($hid_ime),
		hid_priimek => DntFunkcije::trim($hid_priimek),
		hid_ulica => DntFunkcije::trim($hid_ulica),
		hid_hisnaSt => DntFunkcije::trim($hid_hisnaSt),
		hid_postnaSt => DntFunkcije::trim($hid_postnaSt),
		hid_davcnaSt => DntFunkcije::trim($hid_davcnaSt),
		hid_davcniZavezanec => DntFunkcije::trim($hid_davcniZavezanec),
		hid_danRojstva => DntFunkcije::trim($hid_danRojstva),
		hid_mesecRojstva => DntFunkcije::trim($hid_mesecRojstva),
		hid_letoRojstva => DntFunkcije::trim($hid_letoRojstva),
		hid_emso => DntFunkcije::trim($hid_emso),
		hid_vneseno => $vneseno,
		
		edb_pokrovitelj => DntFunkcije::trim($pokrovitelj),
		edb_podaljsanjePogodbe => DntFunkcije::trim($podaljsanjePogodbe),
		edb_amount1 => DntFunkcije::trim($amount1),
		edb_num_installments => DntFunkcije::trim($num_installments),
		edb_amount2 => DntFunkcije::trim($amount2),
		edb_amount => DntFunkcije::trim($amount),
		edb_placanDne => DntFunkcije::trim($placanDne),
		edb_valuta => DntFunkcije::trim($valuta),
		edb_aktiviraj => DntFunkcije::trim($aktivirajDne),
		edb_zap_st_db => DntFunkcije::trim($zap_st_dolznika),
		hid_id_agreement => DntFunkcije::trim($id_agreement),
		edb_trr => DntFunkcije::trim($trr),
		edb_db_approval => DntFunkcije::trim($approval),
		edb_db_approval_date => DntFunkcije::trim($approvalDate),
		hid_urejanje => $urejanje,
		edb_uredi => $uredi,
		edb_loop4 => \@loop4,
		#edb_loop5 => \@loop5,
		edb_loop6 => \@loop6,
		edb_loop7 => \@loop7,
		edb_loop8 => \@loop8,
		edb_loop9 => \@loop9,
		edb_loop10 => \@loop10,
		edb_opomini => \@loop_opomini,
		fr08=> $fr08,
		fr18=> $fr18,
		fr28=> $fr28,
		nacinC1 => $nacinC1,
		nacinG1 => $nacinG1,
		edb_onload=> $onload,
		edb_nazaj_btn=>$nazajBtn,
		edb_nazaj_link=>$nazajLink,
		edb_bold => $count_comments,		
		edb_ui => $unique_id,
		edb_staff_name => $staff_name,
		#status_kontrole => $status_kontrole
	);
	$html_output = $template->output; #.$tabelica;
	#$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
	return $html_output;
	
}

sub PogodbaShrani{
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $test = $q->param('test');
	if(!defined $test){ $test = 0};
	my $aktivirajDne= DntFunkcije::trim($q->param('edb_aktiviraj')) || "0";
	my $amount= DntFunkcije::trim($q->param('edb_amount')) || 0;
	my $amount1= DntFunkcije::trim($q->param('edb_amount1')) || 0;
	my $amount2= DntFunkcije::trim($q->param('edb_amount2')) || 0;
	my $celaKoda = DntFunkcije::trim($q->param('edb_celaKoda')) || 0;
	my $emso= DntFunkcije::trim($q->param('edb_emso'));
	my $dogodek= DntFunkcije::trim($q->param('edb_dogodek'));
	my $don= DntFunkcije::trim($q->param('hid_don'));
	my $frekvenca= DntFunkcije::trim($q->param('edb_frekvenca'));
	my $fr08;
	my $fr18;
	my $fr28;
	my $gospod;
	my $gospa;
	my $id_donor= DntFunkcije::trim($q->param('edb_id_donator'));
	my $id_donor_star= DntFunkcije::trim($q->param('id_don_nov'));
	my $ime= DntFunkcije::trim($q->param('edb_ime'));
	my $imePoste= DntFunkcije::trim($q->param('edb_imePoste'));
	my $datumVnosa= DntFunkcije::trim($q->param('edb_datumVnosa')) || "0";
	my $datumPogodbe= DntFunkcije::trim($q->param('edb_datumPodpisa')) || "0";
	my $datumRojstva;
	my $davcnaSt= DntFunkcije::trim($q->param('edb_davcnaSt'));
	my $davcniZavezanec= DntFunkcije::trim($q->param('davcniZavezanec')) || 0;
	my $danRojstva= DntFunkcije::trim($q->param('edb_danRojstva'));
	my $mesecRojstva= DntFunkcije::trim($q->param('edb_mesecRojstva'));
	my $letoRojstva= DntFunkcije::trim($q->param('edb_letoRojstva'));
	my $komercialist= DntFunkcije::trim($q->param('edb_komercialist'));
	#my $leto= DntFunkcije::trim($q->param('edb_leto'));
	my $hisnaSt= DntFunkcije::trim($q->param('edb_hisnaSt'));
	my $nacinPlacila= DntFunkcije::trim($q->param('edb_nacinPlacila'));
	my $num_installments= DntFunkcije::trim($q->param('edb_num_installments')) || 0;
	my $placanDne= DntFunkcije::trim($q->param('edb_placanDne')) || "0";
	my $podaljsanjePogodbe= DntFunkcije::trim($q->param('edb_podaljsanjePogodbe')) || 0;
	my $podjetje= DntFunkcije::trim($q->param('edb_podjetje'));
	my $pokrovitelj= DntFunkcije::trim($q->param('edb_pokrovitelj')) || 0;
	my $postnaSt= DntFunkcije::trim($q->param('edb_postnaSt')) || 0;
	my $post_name = DntFunkcije::trim($q->param('edb_postnaSt2')) || 0;
	my $prednaziv= DntFunkcije::trim($q->param('edb_prednaziv'));
	my $projekt= DntFunkcije::trim($q->param('edb_projekt'));
	my $priimek= DntFunkcije::trim($q->param('edb_priimek'));
	my $redirect_url="DntPogodbe.cgi?&rm=Nova+pogodba&seja=";
	my $status= DntFunkcije::trim($q->param('edb_status'));
	my $statusF;
	my $statusP;
	my $status_kontrole;
	my $trr= DntFunkcije::trim($q->param('edb_TRR'));
	my $approval= DntFunkcije::trim($q->param('edb_db_approval')) || 0;
	my $approvalDate= DntFunkcije::trim($q->param('edb_db_approval_date')) || "0";
	my $ulica= DntFunkcije::trim($q->param('edb_ulica'));
	my $upokojenec= DntFunkcije::trim($q->param('upokojenec')) || 0;
	my $staraPogodba= DntFunkcije::trim($q->param('stara_pogodba')) || 0;
	my $posiljanjeOpominov= DntFunkcije::trim($q->param('opomini')) || 0;
	my $urejanje= DntFunkcije::trim($q->param('uredi')) || 0;
	my $valuta= DntFunkcije::trim($q->param('edb_valuta')) || 0;
	my $vrstaBremenitve= DntFunkcije::trim($q->param('edb_vrstaBremenitve'));
	my $zap_st_dolznika= DntFunkcije::trim($q->param('edb_zap_st_db'));
	my $sifrantBank;
	my $znesek;
	my $status_pogodbe= ($num_installments == 0) ? "P" : "O";
	my @loop4;
	
	my $dbh;
	my $sql;
	my $sth;
	my $res;
	
	my $cookie = $ENV{'HTTP_COOKIE'};
	$cookie = substr ($cookie, index($cookie, 'id=')+3);
	my @arr = split(",", $cookie);
	$cookie = $arr[0];
	
	my $html_output ;
	my $id_agreement = $q->param('edb_id_agreement');
	my $menu_pot ;
	my $template ;
	if(defined $trr){
		$sifrantBank = substr(DntFunkcije::trim($trr), 0, 2);
		
	}
	if($letoRojstva && $mesecRojstva && $danRojstva){
		$datumRojstva=$letoRojstva."-".$mesecRojstva."-".$danRojstva;
		#return $celaKoda;
	}
	else{
		$datumRojstva="0";
		
	}
	if ($celaKoda){
		
		$dogodek= substr($id_agreement,3,2);
		$komercialist= substr($id_agreement,5,3);
		$projekt= substr($id_agreement,0,1);
		#return "kljukica dg:".$dogodek."komerci".$komercialist."projekt".$projekt;
	}
	else{
		#čita vnešene podatke
		#return $celaKoda."cela dg:".$dogodek."komerci".$komercialist."projekt".$projekt;;
	}

	if($num_installments==0){
		$status_pogodbe = "P";
	}
	
		
	if($aktivirajDne ne "0"){
			$aktivirajDne = substr($aktivirajDne,6,4).'-'.
							substr($aktivirajDne,3,2).'-'.
							substr($aktivirajDne,0,2);
		}

	
		
	if($datumVnosa ne "0"){
			$datumVnosa = substr($datumVnosa,6,4).'-'.
							substr($datumVnosa,3,2).'-'.
							substr($datumVnosa,0,2);
	}
	
	if($datumPogodbe ne "0"){
			$datumPogodbe = substr($datumPogodbe,6,4).'-'.
							substr($datumPogodbe,3,2).'-'.
							substr($datumPogodbe,0,2);
	}
	
	if($placanDne ne "0"){
			$placanDne = substr($placanDne,6,4).'-'.
							substr($placanDne,3,2).'-'.
							substr($placanDne,0,2);
	}
	if($approvalDate ne "0"){
			$approvalDate = substr($approvalDate,6,4).'-'.
							substr($approvalDate,3,2).'-'.
							substr($approvalDate,0,2);
	}

	$amount = substr($amount, 0, length($amount)-3).".".
				substr($amount, length($amount)-2, 2);
	$amount1 = substr($amount1, 0, length($amount1)-3).".".
				substr($amount1, length($amount1)-2, 2);
	$amount2 = substr($amount2, 0, length($amount2)-3).".".
				substr($amount2, length($amount2)-2, 2);
	if($test == 1){
		$dbh = DntFunkcije->connectDBtest;
	}
	else{
		$dbh = DntFunkcije->connectDB;
	}	
		if ($dbh) {
			
			if($urejanje==1){
				$redirect_url="DntPogodbe.cgi?rm=seznam&seja=";	
				$sql = "UPDATE sfr_agreement ".
					   "SET id_donor=?, ".
					   "name_company=?, first_name=?, scnd_name=?,".
						"street=?, street_number=?, ".
						"tax_number=?, liable_for_tax=?,".
						"emso=?, pay_type1=?, pay_type2=?, debit_type=?, ".
						"date_enter=?, date_agreement=?, ".
						"entity=?, prefix=?, valuta=?, ". #retired=?,
						"bank_account2=?, frequency=?, ".
						"num_installments=?, ".
						"amount=?, amount1=?, amount2=?, ".
						"retired=?, pokrovitelj=?, podaljsanje_pogodbe=?, sifra_banke=?, ".
						"ne_posiljaj_opomine=?, stara_pogodba=?, id_staff_enter=?, approval=? ".
						"WHERE id_agreement=?";
				#print $q->p($sql_vprasaj);
				$sth = $dbh->prepare($sql);
				
				unless($sth->execute($id_donor,
						$podjetje, $ime, $priimek,
						$ulica, $hisnaSt,
						$davcnaSt, $davcniZavezanec,
						$emso, $nacinPlacila, $vrstaBremenitve, $vrstaBremenitve,
						$datumVnosa, $datumPogodbe, 
						$status, $prednaziv, $valuta,
						$trr, $frekvenca,
						$num_installments,
						$amount, $amount1, $amount2,
						$upokojenec, $pokrovitelj, $podaljsanjePogodbe, $sifrantBank,
						$posiljanjeOpominov, $staraPogodba, $cookie, $approval, 
						$id_agreement)){
						
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
					if($test == 1){	return 0; }
					else {return $html_output;}
				}
				if($placanDne eq "0"){
					$sql = "UPDATE sfr_agreement ".
						   "SET date_1st_amount=NULL ".		
						   "WHERE id_agreement=?";
				#print $q->p($sql_vprasaj);
					$sth = $dbh->prepare($sql);
					
					$sth->execute($id_agreement);		
					
				}
				else{
					$sql = "UPDATE sfr_agreement ".
						   "SET date_1st_amount=? ".		
						   "WHERE id_agreement=?";
				#print $q->p($sql_vprasaj);
					$sth = $dbh->prepare($sql);
					
					$sth->execute($placanDne,
								  $id_agreement);	
				}

				if($approvalDate eq "0"){
					$sql = "UPDATE sfr_agreement ".
						   "SET approval_date=NULL ".		
						   "WHERE id_agreement=?";
				#print $q->p($sql_vprasaj);
					$sth = $dbh->prepare($sql);
					
					$sth->execute($id_agreement);		
					
				}
				else{
					$sql = "UPDATE sfr_agreement ".
						   "SET approval_date=? ".		
						   "WHERE id_agreement=?";
				#print $q->p($sql_vprasaj);
					$sth = $dbh->prepare($sql);
					
					$sth->execute($approvalDate,
								  $id_agreement);	
				}
				$sql = "UPDATE approvals ".
						   "SET available=FALSE ".		
						   "WHERE approval=?";
				$sth = $dbh->prepare($sql);
				$sth->execute($approval);
				
				if($aktivirajDne eq "0"){
					
					$sql = "UPDATE sfr_agreement ".
						   "SET start_date=NULL ".		
						   "WHERE id_agreement=?";
				#print $q->p($sql_vprasaj);
					$sth = $dbh->prepare($sql);
					
					$sth->execute($id_agreement);					
				}
				else{					
				
					$sql = "UPDATE sfr_agreement ".
						   "SET start_date=? ".		
						   "WHERE id_agreement=?";
				#print $q->p($sql_vprasaj);
					$sth = $dbh->prepare($sql);
					
					$sth->execute($aktivirajDne,
								  $id_agreement);
				}
				
				if($datumRojstva eq "0"){
					$sql = "UPDATE sfr_agreement ".
						   "SET born_date=NULL ".		
						   "WHERE id_agreement=?";
					$sth = $dbh->prepare($sql);
					
					$sth->execute($id_agreement);					
				}
				else{
				$sql = "UPDATE sfr_agreement ".
					   "SET born_date=? ".		
					   "WHERE id_agreement=?";
				#print $q->p($sql_vprasaj);
				$sth = $dbh->prepare($sql);
				
				unless($sth->execute($datumRojstva,
							  $id_agreement)){
						
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
					if($test == 1){	return 0; }
					else { return $html_output; }
					}
				}
				#print $q->p($sql_vprasaj);
				if($postnaSt==0){
					
					$sql = "UPDATE sfr_agreement ".
						   "SET id_post=NULL ".		
						   "WHERE id_agreement=?";
					#print $q->p($sql_vprasaj);
					$sth = $dbh->prepare($sql);
					
					$sth->execute($id_agreement);					
				}
				else{					
				
					$sql = "UPDATE sfr_agreement ".
						   "SET id_post=?, post_name=? ".		
						   "WHERE id_agreement=?";
				#print $q->p($sql_vprasaj);
					$sth = $dbh->prepare($sql);
				
					$sth->execute($postnaSt, $post_name,
							  $id_agreement);
				}				
			}
			else{
				my $id_agreement_check = 0;
				
				if($test == 0){
					$sql= "SELECT * FROM sheets WHERE serial_id=? AND id_agreement is null ORDER BY id_vrstce";
					$sth = $dbh->prepare($sql);
					$sth->execute($id_agreement);
					unless($res = $sth->fetchrow_hashref){
						my $napaka_opis = "Napaka s st. pogodbe";
						$template = $self->load_tmpl(	    
								'DntRocniVnosNapaka.tmpl',
								cache => 1,
								);
						$template->param(
									MENU => DntFunkcije::BuildMenu(),
									IME_DOKUMENTA => 'Napaka !',
									napaka_opis => $napaka_opis,
									akcija => ''
								 );
						
						$html_output = $template->output; #.$tabelica;
						#$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
						if($test == 1){	return "NO SHEET SERIES"; }
						else {return $html_output;}
					}
				}
				$sql = "INSERT INTO sfr_agreement ".
					   "(id_donor, id_agreement,".
					   "name_company, first_name, scnd_name,".
						"street, street_number,".
						"tax_number, liable_for_tax,".
						"emso, pay_type1, pay_type2, debit_type, ".
						"date_enter, date_agreement, ".
						"entity, prefix, valuta,". #retired,
						"bank_account2, frequency, ".
						"num_installments, ".
						"retired, pokrovitelj, podaljsanje_pogodbe,".
						"id_project, id_event, id_staff,".
						"amount, amount1, amount2,status, sifra_banke, ".
						"ne_posiljaj_opomine, stara_pogodba, id_staff_enter, approval) ".
						"VALUES (?, ?,".
								"?, ?, ?,".
								"?, ?,".
								"?, ?,".
								"?, ?, ?, ?,".
								"?, ?,".
								"?, ?, ?, ".
								"?, ?,".
								"?, ".
								"?, ?, ?,".
								"?, ?, ?,".
								"?, ?, ?, ?, ?,".
								"?, ?, ?, ?)";
				#print $q->p($sql_vprasaj);
				$sth = $dbh->prepare($sql);
				
				if($sth->execute($id_donor, $id_agreement,
						$podjetje, $ime, $priimek,
						$ulica, $hisnaSt,
						$davcnaSt, $davcniZavezanec,
						$emso, $nacinPlacila, $vrstaBremenitve, $vrstaBremenitve,
						$datumVnosa, $datumPogodbe, 
						$status, $prednaziv, $valuta,
						$trr, $frekvenca,
						$num_installments,
						$upokojenec, $pokrovitelj, $podaljsanjePogodbe,
						$projekt, $dogodek, $komercialist,
						$amount, $amount1, $amount2, $status_pogodbe, $sifrantBank,
						$posiljanjeOpominov, $staraPogodba, $cookie, $approval ))
				{
					if($test == 0){	
						$sql = "UPDATE sheets SET id_agreement=? WHERE serial_id=?";
						$sth = $dbh->prepare($sql);				
						$sth->execute($id_agreement, $id_agreement);
					}
					if($aktivirajDne ne "0"){
					$sql = "UPDATE sfr_agreement ".
						"SET start_date=? ".		
					   "WHERE id_agreement=?";
					$sth = $dbh->prepare($sql);
					
					$sth->execute($aktivirajDne,
								  $id_agreement);
					}
					if($placanDne ne "0"){
					$sql = "UPDATE sfr_agreement ".
						   "SET date_1st_amount=? ".		
						   "WHERE id_agreement=?";
				#print $q->p($sql_vprasaj);
					$sth = $dbh->prepare($sql);
					
					$sth->execute($placanDne,
								  $id_agreement);
					}
					if($datumRojstva ne "0"){
					$sql = "UPDATE sfr_agreement ".
						   "SET born_date=? ".		
						   "WHERE id_agreement=?";
					#print $q->p($sql_vprasaj);
					$sth = $dbh->prepare($sql);
					
					$sth->execute("'".$datumRojstva."'",
								  $id_agreement);
					}
					if($approvalDate ne "0"){
					$sql = "UPDATE sfr_agreement ".
						   "SET approval_date=? ".		
						   "WHERE id_agreement=?";
					#print $q->p($sql_vprasaj);
					$sth = $dbh->prepare($sql);
					
					$sth->execute("'".$approvalDate."'",
								  $id_agreement);
					}
					$sql = "UPDATE sfr_agreement ".
						   "SET id_post=?, post_name=? ".		
						   "WHERE id_agreement=?";
					#print $q->p($sql_vprasaj);
					$sth = $dbh->prepare($sql);
					
					$sth->execute($postnaSt, $post_name,
								  $id_agreement);


					$sql = "UPDATE approvals ".
						   "SET available=FALSE ".		
						   "WHERE approval=?";
					#print $q->p($sql_vprasaj);
					$sth = $dbh->prepare($sql);
					
					$sth->execute($approval);

					my $ui=$q->param('ui');
					#Vstavljanje komentarjev iz zacasnih tabel:
					if($test == 0){
					$sql= "SELECT * FROM uporabniki_tmp WHERE id_user='$cookie' AND".
							" id_unique='$ui' AND tmp_source ilike '%_pog'".
							" ORDER BY id ASC";
					$sth = $dbh->prepare($sql);
					$sth->execute();
					my $sql312=$sql;
					my $sth3;
					while($res = $sth->fetchrow_hashref){
						#komentar
						if($res->{'tmp_source'} eq "komentarji_pog"){
							if($res->{'tmp_date2'}){
							$sql = "INSERT INTO sfr_agreement_comment (".
							" id_agreement,".
							" date, comment,".
							" alarm, alarm_active,".
							" comment_alarm) VALUES (".
							" '$id_agreement', ".
							" '$res->{'tmp_date1'}', '$res->{'tmp_field1'}', ".
							" '$res->{'tmp_date2'}', '$res->{'tmp_toggle'}', ".
							" '$res->{'tmp_field2'}')";
							}
							else{
							$sql = "INSERT INTO sfr_agreement_comment (".
							" id_agreement,".
							" date, comment,".
							" alarm, alarm_active,".
							" comment_alarm) VALUES (".
							" '$id_agreement', ".
							" '$res->{'tmp_date1'}', '$res->{'tmp_field1'}', ".
							" NULL, '$res->{'tmp_toggle'}', ".
							" '$res->{'tmp_field2'}')";	
							}		
							
						}
						$sth3 = $dbh->prepare($sql);
							unless($sth3->execute()){
								return "FAIL: <br />".$sql;
							};
					}
					}
				}
				else{
					my $napaka_opis = $sth->errstr;
					$template = $self->load_tmpl(	    
							'DntRocniVnosNapaka.tmpl',
							cache => 1,
							);
					$template->param(
								MENU => DntFunkcije::BuildMenu(),
								IME_DOKUMENTA => 'Napaka !',
								napaka_opis => $napaka_opis,
								akcija => ''
							 );
					
					$html_output = $template->output; #.$tabelica;
					#$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
					if($test == 1){	return 0; }
					else {return $html_output; }
				}
				
				
					
			}			
			if($don==1){
			
			$sql = "UPDATE sfr_donor ".
					   "SET ".
					   "name_company=?, first_name=?, scnd_name=?,".
						"street=?, street_number=?, post=?, ".
						"tax_number=?, liable_for_tax=?,".
						"emso=?, ".
						
						"entity=?, prefix=?, ". #retired=?,
						
					
					
						"retired=? ".#pokrovitelj=?, podaljsanje_pogodbe=? ".
						"WHERE id_donor=?";
			#print $q->p($sql_vprasaj);
				$sth = $dbh->prepare($sql);
				
				unless($sth->execute(
							  $podjetje, $ime, $priimek,
							  $ulica, $hisnaSt, $postnaSt,
							  $davcnaSt, $davcniZavezanec,
							  $emso, 							  
							  $status, $prednaziv, #$upokojenec,
							  $upokojenec, #$pokrovitelj, $podaljsanjePogodbe,
							  $id_donor)){
						
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
					return $html_output;
				}
				$sql = "UPDATE sfr_donor ".
					   "SET born_date=? ".		
					   "WHERE id_donor=?";
			#print $q->p($sql_vprasaj);
				$sth = $dbh->prepare($sql);
				
				$sth->execute("'".$datumRojstva."'",
							  $id_donor);
				
			}
			
			$self->header_type('redirect');
			$self->header_props(-url => $redirect_url);
			if($test == 1){return 1}
			else {return $redirect_url };
		}
	
		
}

sub Pokazi_obroke_pogodbe($$$$){
    my $self = shift;
    my $id_agreement = shift;
    my $template  = shift;
    my $znesek = shift; #Znesek obroka, kakrsen bi moral biti po pogodbi
    my $q = $self->query();
	
    my $datum;
	my $st_obrokov;
    my $html_output;
    my $id_transakcije;
    my $id_vrstica;
    my $installment_nr  ;  #zaporena stevilka obroka
    #my $dbh = CarpeDiem->connectDB;
    my @loop;
    my $nasel_zapis ;
    my $na_nov_obrok;
    my $placaj ;
    my %placila;
    
    my $pogodbaObroki = PogodbaObroki->new();
    
    my $prenos ;
    my $skupni_znesek;
    my $skupaj_placano;
    my $st_obroka;
    my $sum_obroki ;
    my $sum_placano ;
	
    my $vrstica;
    my @tabelica ;
    my $vrsta_bremenitve;
    my $vpisi_komentar ;
    my $zap_st;
	
    my $db_id_vrstica ;
    my $db_amount ;
    my $db_amount_payed ;
    my $db_debit_type;
    
    my $dbh;
    my $sth;
    my $res;
    my $sql;
	
	my $vsota_obrokov=0;
	my $vsota_placil=0;
	my $vsota_dolgov=0;
	my $status;
	my $potrdilo;
	#Izpise obroke izbrane pogodbe
	
	#	$template = $self->load_tmpl(	    
	#                      'DntPogodbaEdit.tmpl.html',
	#		      cache => 1,
	#		     );
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		$sql = "SELECT num_installments, status, potrdilo FROM".
				" sfr_agreement WHERE id_agreement=?";
		$sth = $dbh->prepare($sql);
		$sth->execute($id_agreement);
		if ($res = $sth->fetchrow_hashref) {
			$st_obrokov=$res->{'num_installments'};
			$status=$res->{'status'};
			$potrdilo=$res->{'potrdilo'};
		}
		
		$sql = "SELECT id_vrstica, date_due, amount, amount_payed, installment_nr, komentar, ".
			" date_activate, debit_type, frequency, storno, obracun, date_izpis  ".
			" FROM agreement_pay_installment WHERE "
			." id_agreement = ? ORDER BY date_activate, installment_nr ASC";
		$sth = $dbh->prepare($sql);
		$sth->execute($id_agreement);        
		$nasel_zapis = "0";

		$skupni_znesek =0;
		$skupaj_placano = 0;
		$sum_obroki = 0;
		$sum_placano = 0;
		while ($res = $sth->fetchrow_hashref) {
			$nasel_zapis = "1";			
			$db_id_vrstica = $res->{'id_vrstica'};	#@$vrstica[0] ;
			$db_debit_type = $res->{'debit_type'};
			$db_amount = $res->{'amount'}; #@$vrstica[1];
			$db_amount_payed = $res->{'amount_payed'};  #@$vrstica[2];
			if(!defined $db_amount_payed){
				$db_amount_payed= 0;
			}
			$sum_obroki = $sum_obroki + $db_amount;
			$sum_placano = $sum_placano + $db_amount_payed;
			$vsota_obrokov += $db_amount;
			$vsota_placil += $db_amount_payed;
			if(defined $res->{'storno'}){
				
				$vsota_dolgov += $db_amount;
			}
			if ($db_amount != 0 && $db_amount != $db_amount_payed && !(defined $res->{'storno'})){
				$st_obroka = "<input type='checkbox' name='hid_izbrani_obroki'".
					"value='".$res->{'installment_nr'}.'#'.
					substr($res->{'date_activate'},0,10).'#'.
					$res->{'debit_type'}.'#'.$res->{'frequency'}.'#'.
					$db_amount."' -checked  >$res->{'installment_nr'}";
			}
			else{
				$st_obroka = $res->{'installment_nr'};
			}
			if ($db_amount == $znesek && $db_amount_payed == 0 && !(defined $res->{'storno'})){
				
				my $sql2;
				my $sth2;
				my $res2;
				my $napaka=0;
				
				$sql2="SELECT * FROM sfr_pay_type";
				$sth2 = $dbh->prepare($sql2);
				$sth2->execute();     
				while ($res2 = $sth2->fetchrow_hashref) {
					
					if ($res->{'debit_type'} eq $res2->{'debit_type'}){
						$vrsta_bremenitve = $res2->{'name_pay_type'}	;
						$placaj = "placaj".$res2->{'debit_type'};
						$prenos = "prenos".$res2->{'debit_type'};
						$napaka=1;
					}
				}
				if($napaka==0){
					$vrsta_bremenitve = "napaka, vpisano je: ".
						$res->{'debit_type'};
				}
				$na_nov_obrok= $q->a({-href=>"DntPogodbe.cgi?rm=prenesi_obrok".
					"&id_vrstica=$db_id_vrstica&id_agreement=$id_agreement"},
					"prenesi") ;
				#$vpisi_komentar = $q->a({-href=>"DntPogodbaEdit.pl?hid_menu=placila_direktnih_db&hid_akcija='komentar'&id_vrstica=$db_id_vrstica&id_agreement=$id_agreement&znesek=$znesek&id_transakcije=$id_transakcije"},"Vpisi - vpogled v komentar") ;
				if($res->{'komentar'}){
				$vpisi_komentar = $q->a({-href=>"#",-id=>"uredi$db_id_vrstica", -onclick=>"javascript:Komentar($db_id_vrstica, $id_agreement)"},"uredi") ;
				}
				else{
				$vpisi_komentar = $q->a({-href=>"#",-id=>"uredi$db_id_vrstica", -onclick=>"javascript:Komentar($db_id_vrstica, $id_agreement)"},"dodaj") ;					
				}
				
			}
			else{
				#je ze placano zato je brez linkov ali napacen znesek obroka						
				my $sql2;
				my $sth2;
				my $res2;
				my $napaka=0;
				
				$sql2="SELECT * FROM sfr_pay_type";
				$sth2 = $dbh->prepare($sql2);
				$sth2->execute();
				$na_nov_obrok="";
				if($res->{'komentar'}){
				$vpisi_komentar = $q->a({-href=>"#",-id=>"uredi$db_id_vrstica", -onclick=>"javascript:Komentar($db_id_vrstica, $id_agreement)"},"uredi") ;
				}
				else{
				$vpisi_komentar = $q->a({-href=>"#",-id=>"uredi$db_id_vrstica", -onclick=>"javascript:Komentar($db_id_vrstica, $id_agreement)"},"dodaj") ;					
				}
				while ($res2 = $sth2->fetchrow_hashref) {
					
					if ($res->{'debit_type'} eq $res2->{'debit_type'}){
						$vrsta_bremenitve = $res2->{'name_pay_type'}	;
						$placaj = "placaj".$res2->{'debit_type'};	#.$res->{'id_vrstica'};
						$prenos = "prenos".$res2->{'debit_type'};	#.$res->{'id_vrstica'};
						$napaka=1;
					}
					
				}
				
				if($napaka==0){
					$vrsta_bremenitve = "napaka, vpisano je: ".
						$res->{'debit_type'};
				}
				
				#if ($res->{'debit_type'} eq "01"){
				#	$vrsta_bremenitve = "splosna poloznica";
				#}
				#elsif ($res->{'debit_type'} eq "04"){
				#	$vrsta_bremenitve = "direktna bremenitev";
				#}
				#elsif ($res->{'debit_type'} eq "A1"){
				#	$vrsta_bremenitve = "racun";
				#}
				#else{
				#	$vrsta_bremenitve = "napaka, vpisano je: ".
				#		$res->{'debit_type'};
				#}
				#if ($db_amount == 0){
					#print $q->td("");
				#}
				#elsif ($db_amount != $znesek ){
				#	#print $q->td("napacen znesek obroka ");
				#}
				#$na_nov_obrok= "" ;
				#$vpisi_komentar = "";
			}
			$datum = DntFunkcije::sl_date($res->{'date_activate'});
			my $poslano = DntFunkcije::sl_date($res->{'date_izpis'});
			my $obracun = DntFunkcije::sl_date($res->{'obracun'});
			my $storno = DntFunkcije::sl_date($res->{'storno'});
			my $db_date_payed = DntFunkcije::sl_date($res->{'date_due'});
			my %row = (				
				st_obroka => $st_obroka,
				datum => $datum,
				znesek => DntFunkcije::FormatFinancno( $db_amount),
				placano => DntFunkcije::FormatFinancno($db_amount_payed),
				datum_placila => $db_date_payed,
				vrsta_bremenitve => $vrsta_bremenitve ,
				na_nov_obrok => $na_nov_obrok,
				vpisi_komentar => $vpisi_komentar,
				storno => $storno,
				obracun => $obracun,
				poslano => $poslano,
			);
			# put this row into the loop by reference             
			push(@loop, \%row);
		}
		my $generiraj;
		if($nasel_zapis!=1){
			$generiraj="<input type=\"button\" value=\"Generiraj obroke\" onclick=\"javascript:self.location='DntStart.cgi?rm=Obroki'\" /><br />"
		}
		$vsota_dolgov=$vsota_obrokov-$vsota_placil-$vsota_dolgov;
		$template->param(obroki_loop => \@loop,
				generiraj => $generiraj,
				vsota_dolgov => DntFunkcije::FormatFinancno($vsota_dolgov),
				vsota_obrokov => DntFunkcije::FormatFinancno($vsota_obrokov),
				vsota_placano => DntFunkcije::FormatFinancno($vsota_placil),
				st_obrokov => "Skupaj: ".$st_obrokov,
				status => $status,
				potrdilo => substr($potrdilo, 0, 10)
				);
		#$html_output = $template->output;
		return $template; #$html_output;
	}            
				#print $q->p("v:".$db_id_vrstica."z:".$db_amount."p".$db_amount_payed);
#				print $q->start_Tr;
#					if ($db_amount == $znesek && $db_amount_payed == 0){
#						print $q->td("<input type='checkbox' name='hid_izbrani_obroki' value='".$res->{'installment_nr'}.'#'.substr($res->{'date_activate'},0,10).'#'.$res->{'debit_type'}.'#'.$res->{'frequency'}."' -checked  >$res->{'installment_nr'}");
#					}
#					else{
#						print $q->td($res->{'installment_nr'});
#					}
#					#print $q->td($res->{'installment_nr'});
#					print $q->td(substr($res->{'date_activate'},0,10));
#					
#					#$db_amount=~s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
#					
#					print $q->td(CarpeDiem::FormatFinancno( $db_amount)); #$res->{'amount'});
#					print $q->td(CarpeDiem::FormatFinancno($res->{'amount_payed'}));
#					$installment_nr = $res->{'installment_nr'};
#					
#					if ($db_amount == $znesek && $db_amount_payed == 0){
#						
#						#print $q->td("splosna poloznica".$res->{'debit_type'});
#						if ($res->{'debit_type'} eq "01"){
#							print $q->td("<i>splosna poloznica</i>");
#							$placaj = "placaj01";	#.$res->{'id_vrstica'};
#							$prenos = "prenos01";	#.$res->{'id_vrstica'};
#						}
#						elsif ($res->{'debit_type'} eq "04"){
#							print $q->td("<i>direktna bremenitev</i>");
#							$placaj = "placaj04";	#.$res->{'id_vrstica'};
#							$prenos = "prenos04";	#.$res->{'id_vrstica'};
#						}
#						elsif ($res->{'debit_type'} eq "A1"){
#							print $q->td("<i>racun</i>");
#							$placaj = "placajA1";	#.$res->{'id_vrstica'};
#							$prenos = "prenosA1";	#.$res->{'id_vrstica'};
#						}
#						else{
#							print $q->td("napaka, vpisano je: ".$res->{'debit_type'});
#						}
#						
#						#print $q->p();
##						print $q->td( $q->a({-href=>"DntPogodbaEdit.pl?hid_menu=placila_direktnih_db&hid_akcija=$placaj&id_vrstica=$db_id_vrstica&id_agreement=$id_agreement&znesek=$znesek&id_transakcije=$id_transakcije&edb_datum=$datum_placila"}, "Placano") );
#						print $q->td( $q->a({-href=>"DntPogodbaEdit.pl?hid_menu=placila_direktnih_db&hid_akcija=$prenos&id_vrstica=$db_id_vrstica&id_agreement=$id_agreement&znesek=$znesek&id_transakcije=$id_transakcije"}, "Prenesi na nov obrok") );
#						print $q->td( $q->a({-href=>"DntPogodbaEdit.pl?hid_menu=placila_direktnih_db&hid_akcija='komentar'&id_vrstica=$db_id_vrstica&id_agreement=$id_agreement&znesek=$znesek&id_transakcije=$id_transakcije"}, "Vpisi - vpogled v komentar") );
#						#print $q->td( $q->a({-href=>"DntPogodbaEdit.pl?hid_menu=placila_direktnih_db&hid_akcija='komentar'&id_vrstica=$db_id_vrstica&id_agreement=$id_agreement&id_donor=$id_donor&id_transakcije=$id_transakcije&id_obrok=$installment_nr"}, "komentar") );
#						
#					}
#					else{
#						#je ze placano zato je brez linkov ali napacen znesek obroka						
#						if ($res->{'debit_type'} eq "01"){
#							print $q->td("splosna poloznica");
#						}
#						elsif ($res->{'debit_type'} eq "04"){
#							print $q->td("direktna bremenitev");
#						}
#						elsif ($res->{'debit_type'} eq "A1"){
#							print $q->td("racun");
#						}
#						else{
#							print $q->td("napaka, vpisano je: ".$res->{'debit_type'});
#						}
#						if ($db_amount == 0){
#							print $q->td("");
#						}
#						elsif ($db_amount != $znesek ){
#							print $q->td("napacen znesek obroka ");
#						}
#						#print $q->td( $q->a({-href=>"DntRocniVnosi.pl?hid_menu=placila_direktnih_db&hid_akcija='komentar'&id_vrstica=$db_id_vrstica&id_agreement=$id_agreement&id_donor=$id_donor&id_transakcije=$id_transakcije&edb_datum=$datum_placila&id_obrok=$installment_nr"}, "komentar") );
#					}
#				print $q->end_Tr;
				$zap_st = $zap_st +1 ;
		#}
	return;
}

sub Potrdila_o_placanih_obrokih(){
	my $self = shift;
	my $q = $self->query();
	my $dogodek;
	my @dogodki;
	my $id;
	my $id_opis;
	my $projekt;
	my @projekti;
	my $template;
	
	my $dbh;
    my $sth;
    my $res;
    my $sql;
	
	$dbh = DntFunkcije->connectDB;
	if (!$dbh) {
		return 'povezava z bazo ni uspela';	
	}
	#Dobi seznam projektov
	$sql = "SELECT id_project, name_project ".
            " FROM sfr_project ";
	$sth = $dbh->prepare($sql);
	$sth->execute();
	push(@projekti,'(*) Vsi projekti');
	while ($res = $sth->fetchrow_hashref) {
		#$nasel_zapis = "1";			
		$id = DntFunkcije::trim($res->{'id_project'});	#@$vrstica[0] ;
		$id_opis = $res->{'name_project'};
		push(@projekti,'('.$id.') '.$id_opis);
	}
	#dobi seznam dogodkov
	$sql = "SELECT id_event, name_event".
            " FROM sfr_events ";        
	$sth = $dbh->prepare($sql);
	$sth->execute();
	push(@dogodki,'(*) Vsi dogodki');
	while ($res = $sth->fetchrow_hashref) {
		#$nasel_zapis = "1";			
		$id = DntFunkcije::trim($res->{'id_event'});	#@$vrstica[0] ;
		$id_opis = $res->{'name_event'};
		push(@dogodki,'('.$id.') '.$id_opis);
	}
	#naredi kontorle projekti in dogodki
	$projekt = $q->scrolling_list(-name=>'list_projekti',
                                -values=>[@projekti],
                                -default=>['meenie'],
                                -size=>1);
                                #-multiple=>'false');
        #-labels=>\%labels,
        #-attributes=>\%attributes);
	$dogodek = $q->scrolling_list(-name=>'list_dogodki',
                                -values=>[@dogodki],
                                -default=>['meenie'],
                                -size=>1);
	$template = $self->load_tmpl(	    
	    'DntPogodbaPotrdilaZaprto.tmpl',
	    cache => 1,
	   );
	
	$template->param(
	    #MENU_POT => 'Potrdila o placanih obrokih',
	    PROJEKT=>$projekt,
		DOGODEK=>$dogodek,
		MENU => DntFunkcije::BuildMenu()
	);
	# Parse the template
	my $html_output = $template->output;
	return $html_output;
	
}

sub Potrdila_o_placanih_obrokih_prikazi(){
	my $self = shift;
	my $q = $self->query();
	
	my $cb_agreement;
	my $desno;
	my $dogodek;
	my $dogodek_opis;
	my $edb_od_dne;
	my $edb_do_dne;
	my $ime;
	my @izpisi_polja;
	my $last_installment;
	my $levo;
	my $lmdOd_dne;
	my $lmdDo_dne;
	my $nov_projekt;
	my $nov_dogodek;
	my @loop;
	my $pogodba;
	my $priimek;
	my $projekt;
	my $projekt_opis;
	my $template;
	my $test;
	my $tmp_dogodek;
	my $tmp_projekt;
	my $ulica;
	
	my $dbh;
    my $res;
    my $sql;
    my $sth;
	
	my $dbh_sf;
    my $res_sf;
    my $sql_sf;
    my $sth_sf;
	$projekt = $q->param('list_projekti');
	$dogodek = $q->param('list_dogodki');
	$levo = index($projekt,'(')+1;
	$desno = index($projekt,')');
	$projekt = substr($projekt,$levo, $desno-$levo);
	$levo = index($dogodek,'(')+1;
	$desno = index($dogodek,')');
	$dogodek= substr($dogodek,$levo, $desno-$levo);	
	$edb_od_dne  = DntFunkcije::trim($q->param('edb_od_dne'));
	$edb_do_dne = DntFunkcije::trim($q->param('edb_do_dne'));
	#print $q->p('Zahtevki za zapiranje');
    $dbh = DntFunkcije->connectDB();	
    if (!$dbh) {
		return 'povezava z bazo ni uspela';	
	}
	$dbh_sf = DntFunkcije->connectDB();
	$sql = "SELECT agreement_close.id_agreement, ".
	    " agreement_close.last_installment ,".
	    " sfr_agreement.first_name, sfr_agreement.scnd_name, ".
	    " sfr_agreement.street, ".
		" agreement_close.id_project, agreement_close.id_event ".
	    " FROM agreement_close, sfr_agreement ".
	    " WHERE  agreement_close.noticed IS NULL ".
	    " AND agreement_close.id_agreement = ".
	    " sfr_agreement.id_agreement ";
	if (!($projekt eq '*')){
		$sql .= "AND agreement_close.id_project =? ";
	}
	else{
		$sql .= "AND '*' =? ";
	}
	if (!($dogodek eq '*')){
		$sql .= "AND agreement_close.id_event =? ";
	}
	else{
		$sql .= "AND '*' =? ";
	}
	if (length($edb_od_dne)>0){
		$lmdOd_dne = substr($edb_od_dne,6,4).'-'.
						substr($edb_od_dne,3,2).'-'.substr($edb_od_dne,0,2);
		$sql .= " AND last_installment >= ? ";
	}
	else{
		$lmdOd_dne = '';
		$sql .= " AND '".$lmdOd_dne."' = ?";
	}
	if (length($edb_do_dne)>0){
		$lmdDo_dne = substr($edb_do_dne,6,4).'-'.
						substr($edb_do_dne,3,2).'-'.substr($edb_do_dne,0,2);
		$sql .= " AND last_installment <= ? ";
	}
	else{
		$lmdDo_dne ='';
		$sql .= " AND '".$lmdDo_dne."' = ?";
	}
	#return $sql;
	$sth = $dbh->prepare($sql);
	$res = $sth->execute($projekt, $dogodek, $lmdOd_dne, $lmdDo_dne);
	
	
	$tmp_dogodek = '';
	$tmp_projekt = '';
	while ($res = $sth->fetchrow_hashref) 
	{
		if ($tmp_projekt ne $res->{'id_project'}){
			#Ker je nov dogodek izpise v glavi ime dogodka
			$tmp_projekt = $res->{'id_project'};
			$tmp_dogodek = $res->{'id_event'};
			$sql_sf = "SELECT name_project ".
				" FROM sfr_project ".
				" WHERE  id_project = ?";
			$sth_sf = $dbh_sf->prepare($sql_sf);
			$res_sf = $sth_sf->execute($tmp_projekt);
			if($res_sf = $sth_sf->fetchrow_hashref) {
				$projekt_opis = $res_sf->{'name_project'};
			}
			#Precita se dogodek
			$sql_sf = "SELECT name_event ".				
				" FROM sfr_events ".
				" WHERE  id_event = ?";
			$sth_sf = $dbh_sf->prepare($sql_sf);
			$res_sf = $sth_sf->execute($tmp_dogodek);
			if($res_sf = $sth_sf->fetchrow_hashref) {
				$dogodek_opis = $res_sf->{'name_event'};
			}
			my %row = (
				cb_agreement =>  $projekt_opis,
				pogodba => $dogodek_opis
				
			);			
			# put this row into the loop by reference             
			push(@loop, \%row);
			
        }		
		if ($tmp_dogodek ne $res->{'id_event'}){
			$tmp_dogodek = $res->{'id_event'};
			$sql_sf = "SELECT name_event ".				
				" FROM sfr_events ".
				" WHERE  id_event = ?";
			$sth_sf = $dbh_sf->prepare($sql_sf);
			$res_sf = $sth_sf->execute($tmp_dogodek);
			if($res_sf = $sth_sf->fetchrow_hashref) {
				$dogodek_opis = $res_sf->{'name_event'};
			}
			my %row = (
				cb_agreement =>  '',
				pogodba => $dogodek_opis
				
			);
			
			push(@loop, \%row);
		}		
	    $cb_agreement = "<input type='checkbox' ".
		    "name='hid_izbrani_obroki' value='".
		    $res->{'id_agreement'}."' -checked  >"; 
	    $pogodba = $res->{'id_agreement'};
		$last_installment = DntFunkcije::trim($res->{'last_installment'});
		if (length($last_installment)>0){
			($last_installment) = DntFunkcije::si_date(substr($last_installment,0,10));
		}
	    $ime = $res->{'first_name'};
	    $priimek = $res->{'scnd_name'};
	    $ulica = $res->{'street'};
		
	    my %row = (
		    cb_agreement =>  $cb_agreement,
		    pogodba => $pogodba,
		    datum_zahtevka => $last_installment,
		    ime => $ime,
		    priimek => $priimek,
		    ulica => $ulica
	    );
		#$tmp_dogodek = $res->{'id_event'};
		#$tmp_projekt = $res->{'id_project'};

	    # put this row into the loop by reference             
	    push(@loop, \%row);
	}
	push(@izpisi_polja,'pogodba');
	push(@izpisi_polja,'prefix');
	push(@izpisi_polja,'ime');
	push(@izpisi_polja,'priimek');
	push(@izpisi_polja,'podjetje');
	push(@izpisi_polja,'ulica');
	push(@izpisi_polja,'posta');
	push(@izpisi_polja,'obrokov');
	push(@izpisi_polja,'placanih_obrokov');
	push(@izpisi_polja,'placan_znesek');
	$projekt = $q->scrolling_list(-name=>'list_projekti',
                                -values=>[@izpisi_polja],
                                -default=>['meenie'],
                                -size=>8,
                                -multiple=>'true');
        #-labels=>\%labels,
        #-attributes=>\%attributes);
	$template = $self->load_tmpl(	    
	    'DntPogodbaZahtevkiZaZapiranje.tmpl',
	    cache => 1,
	   );
	$template->param(
	    #MENU_POT => 'Zahtevki za zapiranje',
		izpisi_polja => $projekt,
	    zahtevki_loop => \@loop,
	);
	# Parse the template
	my $html_output = $template->output;
	return $html_output;
}

sub Potrdila_o_placanih_obrokih_zapri(){
	my $self = shift;
	my $q = $self->query();
	my $i;
	my $id_agreement;
	my %imena_polj;
	my @izbranaPolja;
	my @izbranePogodbe;
	my @izpisiPolja;
	my $opis;
	my $id_post;
	my $rez;
	
	my @tabelca;
	my @tabelca1;
	my $vrstica;
	my $vrstica_izpisi;
	
	my $dbh;
    my $res;
    my $sql;
    my $sth;
	
	my $dbh_pst;
    my $res_pst;
    my $sql_pst;
    my $sth_pst;
	
	$dbh = DntFunkcije->connectDB();	
    if (!$dbh) {
		return 'povezava z bazo ni uspela';	
	}
	$dbh_pst = DntFunkcije->connectDB();	
    if (!$dbh_pst) {
		return 'povezava z bazo ni uspela';	
	}
	%imena_polj= (
		"pogodba" => "id_agreement",
		"prefix" => "prefix",
		"ime" => "first_name",
		"priimek" => "scnd_name",
		"podjetje" => "name_company",
		"ulica" => "street, street_number",
		"posta" => "id_post",
		"obrokov" => "1",
		"placanih_obrokov" => "1",
		"placan_znesek" => "1"
	);
	@izbranePogodbe = $q->param('hid_izbrani_obroki');
	@izbranaPolja = $q->param('list_projekti');
	$sql = "SELECT ";
	$i = 0;
	foreach $vrstica (@izbranaPolja) {
		#foreach $vrstica ($q->hidden('hid_izbrani_obroki')){
		@tabelca = split(/#/, $vrstica);		
		$opis = $tabelca[0];
		$sql .= $imena_polj{$opis};
		if ($i < $#izbranaPolja){
			$sql .= ', ';
		}
		$rez .= $opis;
		push(@izpisiPolja,$opis);
		$i = $i+1;
	}
	$sql .= ' FROM sfr_agreement WHERE id_agreement = ?';
	
	$rez .= '<br>';
	foreach $vrstica (@izbranePogodbe) {
		#foreach $vrstica ($q->hidden('hid_izbrani_obroki')){
		@tabelca = split(/#/, $vrstica);
		$id_agreement = $tabelca[0];
		$sth = $dbh->prepare($sql);
		$res = $sth->execute($id_agreement);
		if($res = $sth -> fetchrow_hashref) {
			$i = 0;
			foreach $vrstica_izpisi (@izbranaPolja) {
				@tabelca1 = split(/#/, $vrstica_izpisi);		
				$opis = $tabelca1[0];
				if ($opis eq 'ulica'){
					$rez  .= $res->{'street'}.$res->{'street_number'};
				}
				elsif ($opis eq 'posta'){
					$id_post = $res->{'id_post'};					
					$sql_pst = 'SELECT name_post FROM sfr_post WHERE id_post = ?';
					$sth_pst = $dbh_pst->prepare($sql_pst);
					$res_pst = $sth_pst->execute($id_post);
					#return $id_post.' '.$sql_pst;
					if($res_pst = $sth_pst -> fetchrow_hashref) {
						$rez  .= $id_post.' '.$res_pst->{'name_post'};
					}
					else{
						$rez  .= 'ne najdem'.$id_post.'x';
					}
				}
				else{
					$rez  .= $res->{$imena_polj{$opis}};
				}
				if ($i < $#izbranaPolja){
					$rez .= ', ';
				}				
				$i = $i+1;
			}
			$rez .= '<br>'
			
		}		
		
		#push(@izpisiPolja,$opis);
	}
	
	if ($#izpisiPolja<= 0){
		return 'Napaka! Izberi vsaj 2 polja za izpis vrstic';
	}
	return 'Zaprto'.$rez;
}

sub PrenosNaNovObrok() {
	my $self = shift;
	my $q = $self->query();
	my $id_agreement ;
	my $installment_nr;
	my $pogodbaObroki = PogodbaObroki->new();
	my $redirect_url= 'DntPogodbe.cgi?rm=uredi_pogodbo';
	my $rez;
	my $seja;
	my $vrstica;	
	
	$seja = $q->param('seja');
	$id_agreement = $q->param('id_agreement');
	$redirect_url .= '&id_agreement='.$id_agreement.'&seja='.$seja;	
	$vrstica = $q->param('id_vrstica');
	#$installment_nr = 
	$pogodbaObroki->{id_agreement} = $id_agreement;
	$rez = $pogodbaObroki->prestavi_obrok($vrstica, $id_agreement);
	#print $q->p('rez :'.$rez);
	#print $q->h2("Prenos obroka na nov obrok".$q->param('hid_akcija'));
	#print $q->p("Pogodba".$id_agreement); # $q->param('id_agreement'));
	#print $q->p("obrok");
	#print $q->p("vrstica".$vrstica); # $q->param('id_vrstica'));
	
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
}

sub Shrani_spremembo_obroka(){
    my $self = shift;
    my $q = $self->query();
    
    my $debit_type ;
    my $id_agreement;
    my $installment_nr;
    my $izbrani_gumb ;
    my @izbrani_obroki = $q->param("hid_izbrani_obroki");
    
	my %placila;
    my $pogodbaObroki = PogodbaObroki->new();
    my $redirect_url ;
    
    my $rez;
    my $seja;
    my $spremeni_kaj = $q->param('spremeni_kaj');
    my $shrani_kaj;
    my $stara_frekvenca;
    my @tabelca;
    my $vrstica;
    
    $seja = $q->param('seja');
    $id_agreement = $q->param('hid_id_agreement');
	$redirect_url = 'DntPogodbe.cgi?rm=uredi_pogodbo'.
			'&id_agreement='.$id_agreement.'&uredi=1';
    
    $pogodbaObroki->{id_agreement} = $id_agreement;
    $stara_frekvenca = $pogodbaObroki->{frequency};
    if ($spremeni_kaj eq 'bremenitev'){
		$shrani_kaj = $q->param('vrsta_bremenitve');
    }
    elsif ($spremeni_kaj eq 'frekvenca'){
		$shrani_kaj = $q->param('frekvenca');
    }
    #$rez = 'a';
    
    foreach $vrstica (@izbrani_obroki) {
		#foreach $vrstica ($q->hidden('hid_izbrani_obroki')){
		@tabelca = split(/#/, $vrstica);
		
		$id_agreement = $tabelca[0];
		$installment_nr = $tabelca[1];
		#$rez .= $installment_nr.'_';
		
		$pogodbaObroki->{installment_nr} = $installment_nr;
		
		$pogodbaObroki->citaj_pogodbo_obrok();		
		$stara_frekvenca = $pogodbaObroki->{frequency};
		if ($spremeni_kaj eq 'bremenitev'){
			if ($q->param('vrsta_bremenitve') eq 'direktna bremenitev'){
				$debit_type = '04';
			}
			elsif ($q->param('vrsta_bremenitve') eq 'racun'){
				$debit_type = 'A1';
			}
			else{
				# gre za splosno poloznico
				$debit_type = '01';
			}
			#$pogodbaObroki->obrok_sprememba_shrani($id_agreement,$installment_nr,$nova_vrsta_bremenitve);
			$pogodbaObroki->obrok_sprememba_shrani($id_agreement,
				$installment_nr,$debit_type);
		}
		elsif ($spremeni_kaj eq 'frekvenca'){
			
			#$stara_frekvenca = $tabelca[2];
			#$nova_frekvenca = $tabelca[3];
			
			$pogodbaObroki->obrok_sprememba_frekvence_shrani(
				$id_agreement,$installment_nr,$shrani_kaj);
			#$rez .= $pogodbaObroki->{napaka}
		}
		elsif ($spremeni_kaj eq 'storniraj'){
			#return 'bb_'.$id_agreement.'/'.$installment_nr.'_cc';
			$pogodbaObroki->storniraj_obrok(
				$id_agreement,$installment_nr,"");
			#$rez .= $pogodbaObroki->{napaka}
		}
	}
	#return $rez.'y'.$spremeni_kaj.'n'.$pogodbaObroki->{napaka};
	if ($spremeni_kaj eq 'storniraj'){
		$debit_type = $pogodbaObroki->{debit_type};
		%placila =$pogodbaObroki->stevilo_odprtih_obrokov();
		if ($debit_type == '04'){
			#Pogleda ce gre za direktno bremenitev
			#Ce je zadnji obrok da zahtevek za zaprtje direktnih
			$pogodbaObroki->Podaj_zahtevek_za_zaprtje();
		}
		if (($placila{"splosne"}[0] == $placila{"splosne"}[3])
			 && ($placila{"racuni"}[0] == $placila{"racuni"}[3])
			 && ($placila{"direktne"}[0] == $placila{"direktne"}[3])){
			#Vsi obroki so zaprti, zato se pogodba zapre
			$pogodbaObroki->Podaj_zahtevek_za_sporocilo_Vse_zaprto();
			#return $pogodbaObroki->{napaka}.'xx';
			#Ce je  zadnji obrok gre na zapiranje			
			
		}
		
	}
    $self->header_type('redirect');
    $self->header_props(-url => $redirect_url);
    return $redirect_url;
}

sub Spremeni_nacin_bremenitve(){
	my $self = shift;
	my $q = $self->query();
	return Spremeni_obrok($self,'bremenitev');
	
	#return 'Spremenjen nacin';
}

sub Spremeni_FREKVENCO_bremenitve(){
	
	my $self = shift;
	my $q = $self->query();
	return Spremeni_obrok($self,'frekvenca');
}
sub Spremeni_obrok($$){
	my $self = shift;
	my $spremeni_kaj = shift;
	my $q = $self->query();
	my $html_output;
	my @izbrani_obroki = $q->param("hid_izbrani_obroki");
	my @spremeni_obroke;
	my $id_agreement = $q->param("hid_id_agreement");
	my $ime;
	my $izberi_gumb;
	my @loop;
	my $opis_bremenitve;
	my $potrdi_gumb;
	my $priimek;
	my $rez;
	my $st_obroka;
	my @tabelca;
	my $template;
	my $vrsta_bremenitve;
	
	my $ena;
	my $dve;
	my $tri;
	my $stiri;
	my $pet;
	my $vrstica;
	$ime = DntFunkcije::trim($q->param("edb_ime"));
	$priimek = DntFunkcije::trim($q->param("edb_priimek"));
	
	$rez ='';
	$template = $self->load_tmpl(	    
	    'DntPogodbaSpremeniObroke.tmpl',
	    cache => 1,
	);
	foreach $vrstica (@izbrani_obroki) {
		@tabelca = split(/#/, $vrstica);
		
	    $rez = $q->start_Tr;
		$vrsta_bremenitve = $tabelca[2];
		$st_obroka = $tabelca[0];
		$dve = $q->td($tabelca[0]." ".$vrstica.length(@tabelca));
		$tri = $q->td($tabelca[1]);
		if ($vrsta_bremenitve eq '04'){
			$opis_bremenitve = 'direktna bremenitev';
		}
		elsif ($vrsta_bremenitve eq '01'){
			$opis_bremenitve =	'splosna poloznica';
		}
			    #print $q->p($tabelca[0].'x'.$tabelca[1]."<br>");
	    $st_obroka =  "<input type='checkbox' name='hid_izbrani_obroki' ".
					  "value='".$id_agreement.'#'.$st_obroka.
					  "# -checked='checked'  >$st_obroka";
			
	    my %row = (				
               st_obroka => $st_obroka,
               datum => $tabelca[1],
               znesek => $tabelca[4],			   
			   vrsta_bremenitve => $opis_bremenitve,
			   frekvenca => $tabelca[3]
              );

			# put this row into the loop by reference             
			push(@loop, \%row);
			#my %obrokZaSprement = (
			#	id_agreement =>'('.$id_agreement.',',
			#	installment_nr => $st_obroka.'),'
			#);
			#
		
	}
	;
	#$template->param(hid_izbrani_obroki => \@spremeni_obroke);
	if ($spremeni_kaj eq 'bremenitev'){
		$izberi_gumb = $q->radio_group(-name=>'vrsta_bremenitve',
							-values=>['splosna poloznica','racun'],
							-default=>'splosna poloznica',
							-linebreak=>'0')
	}
	elsif ($spremeni_kaj eq 'frekvenca'){
		$izberi_gumb = $q->radio_group(-name=>'frekvenca',
                             -values=>['8','18','28'],
                             -default=>'8',
                             -linebreak=>'0')
	}
	elsif ($spremeni_kaj eq 'storniraj'){
		
	}
	if ($spremeni_kaj eq 'storniraj'){
		$potrdi_gumb = $q->submit(-name=>"rm", -value=>"Potrdi stornacijo izbranih obrokov");		
	}
	elsif($spremeni_kaj eq 'frekvenca'){
		$potrdi_gumb = $q->submit(-name=>"rm", -value=>"shrani spremembo frekvence",
						 -onClick=>"javascript:dopostback('hid_akcija','btn_spremeni_pred_bremenitev_shrani')");
	}
	else{
		$potrdi_gumb = $q->submit(-name=>"rm", -value=>"shrani spremembo nacin bremenitve",
						 -onClick=>"javascript:dopostback('hid_akcija','btn_spremeni_pred_bremenitev_shrani')");
	}	
	$template->param(obroki_loop => \@loop,
			 MENU => DntFunkcije::BuildMenu(),
			spremeni_kaj=> $spremeni_kaj,			
			IZBERI_GUMB => $izberi_gumb,
			POTRDI_GUMB => $potrdi_gumb,
			hid_id_agreement => $id_agreement,
			POGODBA => 'Pogodba:'.$id_agreement,
			IME_PRIIMEK => 'ime:'.$ime.' '.$priimek,
			#spremeni_obroke_loop => \@spremeni_obroke
		     );
	#$self->hidden(-name=>"obroki_poslji_spremembe", -values => \@spremeni_obroke);
	#$self->param(-name=>"hid_izbrani_obroki", -values => \@spremeni_obroke);
	$html_output = $template->output; #.$tabelica;
	
	#$q->param(-name=>"hid_spremeni_obroke", -values => @spremeni_obroke);	
	#$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
    return $html_output;
}

sub StornirajObroke(){
	my $self = shift;
	my $q = $self->query();
	return Spremeni_obrok($self,'storniraj');
}

sub ZahtevkeZaZapiranjePrikazi(){
    my $self = shift;
    my $q = $self->query();
    
    my $cb_agreement ;
    my $datum_zahtevka; 
    my $ime ;
    my @loop;
    my $pogodba ;
    my $priimek ;
    
    my $template;
    my $ulica;
    
    my $dbh;
    my $res;
    my $sql;
    my $sth;
    #print $q->p('Zahtevki za zapiranje');
    $dbh = DntFunkcije->connectDB();
	
    if ($dbh) {
	$sql = "SELECT d.id_agreement, ".
	    " d.datum_prijave ,".
	    " a.*, p.name_post ".
	    " FROM direktne_zahtevek_za_zapri as d, sfr_agreement as a, sfr_post as p ".
	    " WHERE  d.potrjeno IS NULL ".
	    " AND d.id_agreement = a.id_agreement AND p.id_post =a.id_post "; 
	    
		
	$sth = $dbh->prepare($sql);
	$res = $sth->execute();

	while ($res = $sth->fetchrow_hashref) 
	{
	    $cb_agreement = "<input type='checkbox' ".
		    "name='multi-con' value='".
		    $res->{'id_agreement'}."' checked = true  />"; 
	    $pogodba = $res->{'id_agreement'};			 
	    ($datum_zahtevka) = DntFunkcije::si_date(substr($res->{'datum_prijave'},0,10)); 
	    $ime = $res->{'first_name'};
	    $priimek = $res->{'scnd_name'};
	    $ulica = $res->{'street'};
	    my %row = (
		    cb_agreement =>  $cb_agreement,
		    pogodba => $pogodba,
		    datum_zahtevka => $datum_zahtevka,
		    ime => $ime,
		    priimek => $priimek,
		    ulica => $ulica,
			stevilka => $res->{street_number},
			posta => $res->{name_post},
			postna_stevilka => $res->{id_post},
	    );

	    # put this row into the loop by reference             
	    push(@loop, \%row);
	}
	(my $datum, my $cas) = DntFunkcije->time_stamp();
	my $date = substr($datum,8,2).".".substr($datum,5,2).".".substr($datum,0,4);
	$template = $self->load_tmpl(	    
	    'DntPogodbaZahtevkiZaZapiranje.tmpl',
	    cache => 1,
	   );
	$template->param(
	    #MENU_POT => 'Zahtevki za zapiranje',
		IME_DOKUMENTA => "Zahtevki za zapiranje",
	    zahtevki_loop => \@loop,
		filename => "ZAP_" . $datum . ".csv",
		MENU => DntFunkcije::BuildMenu()
	);
	# Parse the template
	my $html_output = $template->output;
	return $html_output;
    }
}
sub ZapriPogodboIzpis{
	my $self = shift;
    my $q = $self->query();
	
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	my @pogodbe = $q->param('hid_potrjeni_zahtevki_za_ukinitev');
	my $file = "";
	my $pogodbe ="";
	$dbh = DntFunkcije::connectDB;
	my ($date, $cas) = DntFunkcije::si_date("");
	my $fileName;
	if($dbh){
		
		$sql = "SELECT sfr_agreement.*, sfr_donor.post_name, sfr_donor.id_donor FROM sfr_agreement, sfr_donor ".
				"WHERE sfr_agreement.id_donor = sfr_donor.id_donor AND id_agreement IN (";
		foreach my $pogodba (@pogodbe){
			$pogodbe .= "'".$pogodba."', ";
		}
		$pogodbe = substr($pogodbe, 0, -2);
		$sql .= $pogodbe.")";			
	
		$sth = $dbh->prepare($sql);
		$res = $sth->execute();
		
		while ($res = $sth->fetchrow_hashref) {
			$file .= DntFunkcije::trim($res->{'id_agreement'}).";".
					 DntFunkcije::trim($res->{'first_name'}).";".
					 DntFunkcije::trim($res->{'scnd_name'}).";".
					 DntFunkcije::trim($res->{'street'}).";".
					 DntFunkcije::trim($res->{'street_number'}).";".
					 DntFunkcije::trim($res->{'id_post'}).";".
					 DntFunkcije::trim($res->{'post_name'}).";".					 
					 DntFunkcije::trim($res->{'id_donor'}).";";			
			$file .= "\n";
		}
		$sql = "UPDATE direktne_zahtevek_za_zapri SET datum_potrditve=CURRENT_TIMESTAMP, potrjeno=1".
				"WHERE id_agreement IN ($pogodbe)";
		$sth = $dbh->prepare($sql);
		$res = $sth->execute();
		
		my $sql = "INSERT INTO datoteke_izvozene (filename, content)
							VALUES (?, ?)";
		my $sth = $dbh->prepare($sql);
		$fileName = "ZAP_".$date.".csv";
		$sth->execute($fileName, $file);
		
	}


}
sub nadaljevanje(){
	my $self = shift;
	my $id_agreement = shift;
	my $q = $self->query();
	
    
	my $id_transakcije;
	my $id_vrstica;
	my $installment_nr  ;  #zaporena stevilka obroka
    my $dbh = DntFunkcije->connectDB;
    my $nasel_zapis ;
	my $placaj ;
	my %placila;
	my $pogodbaObroki = PogodbaObroki->new();
	my $prenos;
    my $skupni_znesek;
    my $skupaj_placano;
	my $sum_obroki ;
	my $sum_placano ;
    my $vrstica;
	my @tabelica ;
	my $zap_st;
	my $znesek; #Znesek obroka, kakrsen bi moral biti po pogodbi
	
    my $db_id_vrstica ;
    my $db_amount ;
    my $db_amount_payed ;
	my $db_debit_type;
    if ($dbh) 
    {
		$id_transakcije = $q->param('hid_id_transakcije');
        my $sth;
        my $res;
        my $sql;# = CarpeDiem->genSqlDonatorji($q, 1); #to tahko naredim ker v edb_emso in ostalih se ni nic in bo return navaden stavek brez while
        $sql .= "SELECT id_agreement, id_donor, first_name, scnd_name, street, amount, ".
            " amount1, num_installments, amount2, zap_st_dolznika ".
            " FROM sfr_agreement WHERE id_agreement = ? ";
        
        $sth = $dbh->prepare($sql);
        $sth->execute($id_agreement);
        
        if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
        {
			$q->param("edb_id_agreement", $res->{'id_agreement'});
            $q->param("edb_id_donor", $res->{'id_donor'});
            $q->param("edb_first_name", $res->{'first_name'});
            $q->param("edb_scnd_name", $res->{'scnd_name'});
            $q->param("edb_street", $res->{'street'});
            $q->param("edb_amount1", $res->{'amount1'});
            $q->param("edb_num_installments", $res->{'num_installments'});
            $q->param("edb_amount2", $res->{'amount2'});
            $q->param("edb_amount", $res->{'amount'});
			$q->param("edb_zap_st_db", $res->{'zap_st_dolznika'});
			
			$znesek = $res->{'amount2'};

        }
        #Izpise se obroke
        $sql = "SELECT id_vrstica, amount, amount_payed, installment_nr,".
				" date_activate, debit_type, frequency  FROM".
				" agreement_pay_installment WHERE "
                     ." id_agreement = ? ORDER BY date_activate ASC";
		$sth = $dbh->prepare($sql);
		$sth->execute($id_agreement);        
		$nasel_zapis = "0";

        print $q->p('Obroki');
        $skupni_znesek =0;
        $skupaj_placano = 0;
		print $q->start_table({-border=>"1"});
		print $q->Tr
		(
			$q->th
			([
				$q->p("st. obroka"),
				$q->p("datum"),
				$q->p("obrok"),
				$q->p("Placano"),
				$q->p("spremeni vrsto bremenitve"),
				$q->p("prenesi na nov obrok"),
				$q->p("vpis komentarja")
			])
		);
		
		
		while ($res = $sth->fetchrow_hashref) {
			$nasel_zapis = "1";			
				$db_id_vrstica = $res->{'id_vrstica'};	#@$vrstica[0] ;
				$db_debit_type = $res->{'debit_type'};
				$db_amount = $res->{'amount'}; #@$vrstica[1];
				$db_amount_payed = $res->{'amount_payed'};  #@$vrstica[2];
				$sum_obroki = $sum_obroki + $db_amount;
				$sum_placano = $sum_placano + $db_amount_payed;
				
				#print $q->p("v:".$db_id_vrstica."z:".$db_amount."p".$db_amount_payed);
				print $q->start_Tr;
					if ($db_amount == $znesek && $db_amount_payed == 0){
						print $q->td("<input type='checkbox' name='hid_izbrani_obroki' value='".$res->{'installment_nr'}.'#'.substr($res->{'date_activate'},0,10).'#'.$res->{'debit_type'}.'#'.$res->{'frequency'}."' -checked  >$res->{'installment_nr'}");
					}
					else{
						print $q->td($res->{'installment_nr'});
					}
					#print $q->td($res->{'installment_nr'});
					print $q->td(substr($res->{'date_activate'},0,10));
					
					#$db_amount=~s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
					
					print $q->td(DntFunkcije::FormatFinancno( $db_amount)); #$res->{'amount'});
					print $q->td(DntFunkcije::FormatFinancno($res->{'amount_payed'}));
					$installment_nr = $res->{'installment_nr'};
					
					if ($db_amount == $znesek && $db_amount_payed == 0){
						
						#print $q->td("splosna poloznica".$res->{'debit_type'});
						if ($res->{'debit_type'} eq "01"){
							print $q->td("<i>splosna poloznica</i>");
							$placaj = "placaj01";	#.$res->{'id_vrstica'};
							$prenos = "prenos01";	#.$res->{'id_vrstica'};
						}
						elsif ($res->{'debit_type'} eq "04"){
							print $q->td("<i>direktna bremenitev</i>");
							$placaj = "placaj04";	#.$res->{'id_vrstica'};
							$prenos = "prenos04";	#.$res->{'id_vrstica'};
						}
						elsif ($res->{'debit_type'} eq "A1"){
							print $q->td("<i>racun</i>");
							$placaj = "placajA1";	#.$res->{'id_vrstica'};
							$prenos = "prenosA1";	#.$res->{'id_vrstica'};
						}
						else{
							print $q->td("napaka, vpisano je: ".$res->{'debit_type'});
						}
						
						#print $q->p();
#						print $q->td( $q->a({-href=>"DntPogodbaEdit.pl?hid_menu=placila_direktnih_db&hid_akcija=$placaj&id_vrstica=$db_id_vrstica&id_agreement=$id_agreement&znesek=$znesek&id_transakcije=$id_transakcije&edb_datum=$datum_placila"}, "Placano") );
						print $q->td( $q->a({-href=>"DntPogodbaEdit.pl?hid_menu=placila_direktnih_db&hid_akcija=$prenos&id_vrstica=$db_id_vrstica&id_agreement=$id_agreement&znesek=$znesek&id_transakcije=$id_transakcije"}, "Prenesi na nov obrok") );
						print $q->td( $q->a({-href=>"DntPogodbaEdit.pl?hid_menu=placila_direktnih_db&hid_akcija='komentar'&id_vrstica=$db_id_vrstica&id_agreement=$id_agreement&znesek=$znesek&id_transakcije=$id_transakcije"}, "Vpisi - vpogled v komentar") );
						#print $q->td( $q->a({-href=>"DntPogodbaEdit.pl?hid_menu=placila_direktnih_db&hid_akcija='komentar'&id_vrstica=$db_id_vrstica&id_agreement=$id_agreement&id_donor=$id_donor&id_transakcije=$id_transakcije&id_obrok=$installment_nr"}, "komentar") );
						
					}
					else{
						#je ze placano zato je brez linkov ali napacen znesek obroka						
						if ($res->{'debit_type'} eq "01"){
							print $q->td("splosna poloznica");
						}
						elsif ($res->{'debit_type'} eq "04"){
							print $q->td("direktna bremenitev");
						}
						elsif ($res->{'debit_type'} eq "A1"){
							print $q->td("racun");
						}
						else{
							print $q->td("napaka, vpisano je: ".$res->{'debit_type'});
						}
						if ($db_amount == 0){
							print $q->td("");
						}
						elsif ($db_amount != $znesek ){
							print $q->td("napacen znesek obroka ");
						}
						#print $q->td( $q->a({-href=>"DntRocniVnosi.pl?hid_menu=placila_direktnih_db&hid_akcija='komentar'&id_vrstica=$db_id_vrstica&id_agreement=$id_agreement&id_donor=$id_donor&id_transakcije=$id_transakcije&edb_datum=$datum_placila&id_obrok=$installment_nr"}, "komentar") );
					}
				print $q->end_Tr;
				$zap_st = $zap_st +1 ;
		}
		print $q->end_table;
		print $q->submit(-name=>"btn_spremeni_nacin_bremenitve", -value=>"spremeni nacin bremenitve",
						 #-onClick=>"javascript:dopostback('hid_akcija','btn_spremeni_bremenitev')"
						 );
		print $q->submit(-name=>"btn_spremeni_frekvenco_bremenitve", -value=>"spremeni FREKVENCO bremenitve",
						 #-onClick=>"javascript:dopostback('hid_akcija','btn_spremeni_frekvenco_bremenitve')"
						 );
		#print $q->p("testing .:");
		#Izpise tabelco s placili
		$pogodbaObroki->{id_agreement} = $id_agreement;		
		%placila =$pogodbaObroki->stevilo_odprtih_obrokov();
		print $q->start_table({-border=>"1"});
		print $q->Tr
		(
			$q->th
			([
				$q->p("Tip bremenitve"),
				$q->p("stevilo obrokov"),
				$q->p("Znesek obrokov"),
				$q->p("Placano"),
				$q->p("placanih obrokov")
			])
		);
		
			if ($placila{"racuni"}[0] > 0){
				print $q->start_Tr;
					print $q->td("Racuni");
					print $q->td($placila{"racuni"}[0]);
					print $q->td(DntFunkcije::FormatFinancno($placila{"racuni"}[1]));
					print $q->td(DntFunkcije::FormatFinancno($placila{"racuni"}[2]));
					print $q->td($placila{"racuni"}[3]);
				print $q->end_Tr;
			}
			if ($placila{"splosne"}[0] > 0){
				print $q->start_Tr;
					print $q->td("Splosne poloznice");
					print $q->td(DntFunkcije::FormatFinancno($placila{"splosne"}[0]));
					print $q->td(DntFunkcije::FormatFinancno($placila{"splosne"}[1]));
					print $q->td(DntFunkcije::FormatFinancno($placila{"splosne"}[2]));
					print $q->td($placila{"splosne"}[3]);
				print $q->end_Tr;
			}
			if ($placila{"direktne"}[0] > 0){
				print $q->start_Tr;
					print $q->td("Direktnne bremenitve");
					print $q->td($placila{"direktne"}[0]);
					print $q->td(DntFunkcije::FormatFinancno($placila{"direktne"}[1]));
					print $q->td(DntFunkcije::FormatFinancno($placila{"direktne"}[2]));
					print $q->td($placila{"direktne"}[3]);
				print $q->end_Tr;
			}
			print $q->start_Tr;
					print $q->td("<b>Skupaj");
					print $q->td("<b>".($placila{"racuni"}[0]+$placila{"splosne"}[0]+$placila{"direktne"}[0]));
					print $q->td("<b>".DntFunkcije::FormatFinancno(($placila{"racuni"}[1]+$placila{"splosne"}[1]+$placila{"direktne"}[1])));
					print $q->td("<b>".DntFunkcije::FormatFinancno(($placila{"racuni"}[2]+$placila{"splosne"}[2]+$placila{"direktne"}[2])));
					print $q->td("<b>".($placila{"racuni"}[3]+$placila{"splosne"}[3]+$placila{"direktne"}[3]));
				print $q->end_Tr;
		
		print $q->end_table;

        $sth->finish;
        $dbh->disconnect();
	}
}

sub PogodbeZbrisi(){
	
	my $self = shift;
	my $q = $self->query();
	my $test = $q->param('test');
	if(!defined $test){ $test = 0};
	my $seja = $q->param('seja');
	my $redirect_url;
	my @deleteIds=$q->param('brisiId');
	my $source=$q->param('brisi');
	my $ui=$q->param('ui');
	my $template;
	my $html_output;
	my $counter=0;
	my $sql;
	my $sql2;
	my $sth;
	my $dbh;
	my $id=$q->param('id_placilo');
	my $cookie = $ENV{'HTTP_COOKIE'};
	$cookie = substr ($cookie, 3);
	my @arr = split(",", $cookie);
	$cookie = $arr[0];
	if($test == 1){
		$dbh = DntFunkcije->connectDBtest;
	}
	else{
		$dbh = DntFunkcije->connectDB;
	}
	if($dbh){
		if($source eq "komentar"){
			my $id_donor=$q->param('id_donor');
		
			$sql="DELETE FROM sfr_agreement_comment WHERE ";
			$counter=0;
			foreach $id (@deleteIds){
				if ($counter==0){
					
					$sql.="id_vrstice='$id' ";
					$counter++;
				}
				$sql.="OR id_vrstice='$id' ";
			}	
			$redirect_url="?rm=pogodba_komentar&id_pogodbe=$id_donor";
			$sth = $dbh->prepare($sql);
			$sth->execute();
	
		}
		elsif($source eq "komentar_tmp"){
			my $id_donor=$q->param('id_donor');
		
			$sql="DELETE FROM uporabniki_tmp WHERE ";
			$counter=0;	
			foreach $id (@deleteIds){
				if ($counter==0){
					
					$sql.="id='$id' ";
					$counter++;
				}
				$sql.="OR id='$id' ";
			}
			#return $sql;
			$redirect_url="?rm=pogodba_komentar&id_pogodbe=&ui=$id_donor";
			$sth = $dbh->prepare($sql);
			$sth->execute();
	
		}
		else{
			$sql="DELETE FROM sfr_agreement WHERE ";
					
			foreach $id (@deleteIds){
				if ($counter==0){
					$sql.="id_agreement='$id' ";
					$counter++;
				}
				$sql.="OR id_agreement='$id' ";
				if($test == 0){
				$sql2="UPDATE sheets SET id_agreement=NULL WHERE id_agreement=?";
				$sth = $dbh->prepare($sql2);
				$sth->execute($id);
				}
				$sql2="DELETE FROM agreement_pay_installment WHERE id_agreement=?";
				$sth = $dbh->prepare($sql2);
				$sth->execute($id);
				if($test == 0){
				$sql2="DELETE FROM sfr_agreement_comment WHERE id_agreement=?";
				$sth = $dbh->prepare($sql2);
				$sth->execute($id);
				}
			}	
			$redirect_url="?rm=seznam";	
			$sth = $dbh->prepare($sql);
			unless($sth->execute()){
				
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
							#$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
							if($test == 1) { return 1;}
							return $html_output;
			}
		}		
	}
	
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	if($test == 1) { return 1;}
	return $redirect_url;
	
}

sub PogodbeKomentar(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id_agreement = $q->param('id_agreement');
	my $spr = $q->param('spr');
	my $id_komentar = $q->param('id_vrstica');
	my $shrani = $q->param('shrani');
	my $komentar = $q->param('edb_komentar');
	my $menu_pot ;
	my $template ;
	my $gumbek;
	
	my $alarm;
	my $alarmAktivni;
	my $counter=0;
	my $datum;
	my $ime;
	my $ime_dokumenta;
	#my $komentar;
	my $komentarAlarm;
	my $priimek;
	my $lepiDatum;
	my $onload;
	
	my @loop2;
	
	my $dbh;
	my $sql;
	my $sth;
	my $res;


	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		
		if($shrani==1){
			$sql="UPDATE agreement_pay_installment SET komentar=? WHERE id_vrstica=?";
			$sth = $dbh->prepare($sql);
			
			unless($sth->execute($komentar, $id_komentar)){
						
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
			my $redirect_url="?rm=komentar&id_agreement=$id_agreement&id_vrstica=$id_komentar&spr=1";
			#return "$redirect_url $komentar;";
			$self->header_type('redirect');
			$self->header_props(-url => $redirect_url);
			
			return $redirect_url;
		}
		else{
			$sql = "SELECT komentar FROM agreement_pay_installment WHERE id_vrstica=?";
			#, sfr_donor_phone
			#, phone, phone_num, default_phone
			$sth = $dbh->prepare($sql);
			$sth->execute($id_komentar);
			
			$ime_dokumenta="Dodaj nov komentar";
			
				if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
				{
					
					$komentar = $res->{'komentar'};			
					
				}
		}
	}
	
	$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
		$template = $self->load_tmpl(	    
							  'DntPogodbeKomentar.tmpl',
					  cache => 1,
					 );
	$template->param(
				 IME_DOKUMENTA => "Komentar",
				 POMOC => "<input type='button' value='?' onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
				 edb_id => $id_agreement,
				 #komId => $id_komentar,
				 #edb_ime => DntFunkcije::trim($ime),
				 #edb_priimek => DntFunkcije::trim($priimek),
				 #edb_datum => DntFunkcije::trim($datum),
				 edb_komentar => DntFunkcije::trim($komentar),
				 edb_vrstica => DntFunkcije::trim($id_komentar),
				 spr => $spr,
				 #edb_alarm => DntFunkcije::trim($alarm),
				 #edb_alarmAktivni => DntFunkcije::trim($alarmAktivni),
				 #edb_komentarAlarm => DntFunkcije::trim($komentarAlarm),
				 #edb_onload => $onload,
				 #edb_gumbek => $gumbek,
				 #komentar_loop => \@loop2,
				);

	$html_output = $template->output; #.$tabelica;
	return $html_output;
	
    
	
}

sub Komentar(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id_agreement = $q->param('id_pogodbe');
	my $id_komentar = $q->param('id_komentar');
	my $menu_pot ;
	my $template ;
	my $gumbek;
	my $ui = $q->param('ui');
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
	
	my @loop2;
	
	my $dbh;
	my $sql;
	my $sth;
	my $res;
	my $brisi_ui;
	if(!$id_agreement){		
		$id_agreement = $ui;
		$brisi_ui='_tmp';
	}
		
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		if($id_komentar>0){
			if($ui){
				$sql = "SELECT tmp_date1 as date, tmp_field1 as comment, ".
					   "tmp_date2 as alarm, tmp_toggle as alarm_active, ".
					   "tmp_field2 as comment_alarm ".
					   "FROM uporabniki_tmp WHERE id=?";
			}
			else{
				$sql = "SELECT * FROM sfr_agreement_comment WHERE id_vrstice=?";
			}
			$sth = $dbh->prepare($sql);			
			$sth->execute($id_komentar);
			$gumbek="spremeni";
			$ime_dokumenta="Urejanje komentarja";
			#$onload="onload=\"document.myForm['nazaj'].disabled = false; Uredi()\"";
			if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
			{
				$datum = $res->{'date'};
				$komentar = $res->{'comment'};
				$alarm = $res->{'alarm'};
				$alarmAktivni = $res->{'alarm_active'};
				$komentarAlarm = $res->{'comment_alarm'};
			}
			
			
		}
		else{			
			$gumbek="dodaj";
			$ime_dokumenta="Dodaj nov komentar";
		}	
			
		if($ui){
			$sql = "SELECT tmp_date1 as date, tmp_field1 as comment, ".
				   "id as id_vrstice FROM".
			" uporabniki_tmp WHERE id_unique=? ORDER BY date"			
		}
		else{
			$sql = "SELECT date, comment, id_vrstice FROM".
			" sfr_agreement_comment WHERE id_agreement=? ORDER BY date"			
		}
		$sth = $dbh->prepare($sql);
		$sth->execute($id_agreement);
		
			while($res = $sth->fetchrow_hashref){
			if($res->{'date'}>0){	
				$lepiDatum=substr($res->{'date'}, 8,2)."/".substr($res->{'date'}, 5,2)."/".substr($res->{'date'}, 0,4);
			}
			if($ui){
				$ui = $id_agreement;
				$id_agreement='';
			}
			my %row = (datum => $lepiDatum,
					   komentar => $res->{'comment'},
					   komentarId => $res->{'id_vrstice'},
					   edb_id => $id_agreement,
					   tmp_link => "&amp;ui=$ui",
					   
					   );				
			push(@loop2, \%row);
			if($ui){
				$id_agreement=$ui;
			}	
			}
			
	}	
	if($datum>0){
		$lepiDatum=substr($datum, 8,2)."/".substr($datum, 5,2)."/".
					substr($datum, 0,4);
		$datum=$lepiDatum;
		$lepiDatum=substr($alarm, 8,2)."/".substr($alarm, 5,2)."/".
					substr($alarm, 0,4);
		$alarm=$lepiDatum;
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
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		edb_id => $id_agreement,
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
		ui => $ui,
		brisi_ui => $brisi_ui,
		komentar_loop => \@loop2,
	   );

	$html_output = $template->output; #.$tabelica;
	return $html_output;	
}

sub KomentarShrani(){

	my $self = shift;
	my $q = $self->query();
	my $hiddenId = $q->param('hiddenId');
	my $id_agreement = $q->param('edb_id');
	my $seja = $q->param('seja');
	my $ui = $q->param('ui');
	my $html_output;
	my $template;
	my $menu_pot;
	my $imeDokumenta;
	my $napaka;
	my $isci=$q->param('isci');
	my $redirect_url='?rm=seznam';
	if($isci==1){
		$redirect_url="?rm=seznam&isci=1";
	}
	if(!$id_agreement){
		$id_agreement=$ui;
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
		if($ui){
			
			$id='';
		}
		$redirect_url="?rm=pogodba_komentar&amp;id_pogodbe=$id&ui=$ui";
		if($id==''){			
			$id=$ui;
		}
		my $imeDokumenta="Dodaj komentar";
		my $napaka="Uspesno dodano!";
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
					$sql = "UPDATE sfr_agreement_comment SET ".
					"id_agreement=?, date=?, comment=? ".
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
										#MENU_POT => '',
										IME_DOKUMENTA => 'Napaka !',
										napaka_opis => $napaka_opis,
										akcija => ''
										 );				
						$html_output = $template->output; #.$tabelica;

						return $html_output;
				}
				if($ui){
					$sql = "UPDATE uporabniki_tmp SET ".
					"tmp_date2=?, tmp_toggle=?, tmp_field2=? ".
					"WHERE id=? ";
				}
				else{
					$sql = "UPDATE sfr_agreement_comment SET ".
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
										#MENU_POT => '',
										IME_DOKUMENTA => 'Napaka !',
										napaka_opis => $napaka_opis,
										akcija => ''
										 );				
						$html_output = $template->output; #.$tabelica;
						if($aktiven==1){
							return $html_output;
						}
				}			
				
			}
			else {									
				if($ui){
					$sql = "INSERT INTO uporabniki_tmp ".
					"(id_unique, tmp_date1, tmp_field1, id_user, tmp_source) ".
					"VALUES (?, ?, ?, '$cookie', 'komentarji_pog') ";
				}
				else{
					$sql = "INSERT INTO sfr_agreement_comment ".
					"(id_agreement, date, comment) ".
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
										napaka_opis => $napaka_opis."<br /> $ENV{'HTTP_COOKIE'}",
										akcija => ''
										 );
				
						$html_output = $template->output; #.$tabelica;
						return $html_output;
					}
				if($ui){
					$sql = "SELECT id as id_vrstice FROM uporabniki_tmp WHERE ".
						"id_unique='$ui' AND id_user='$cookie' ".
						"ORDER BY id DESC LIMIT 1";	
				}
				else{
					$sql = "SELECT id_vrstice FROM sfr_agreement_comment ".
						"ORDER BY id_vrstice DESC LIMIT 1";
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
					$sql = "UPDATE sfr_agreement_comment SET ".
						"alarm=?, alarm_active=?, comment_alarm=? ".
						"WHERE id_vrstice=? ";
				}
							
				$sth = $dbh->prepare($sql);
				
				unless($sth->execute("'".$datumAlarm."'", $aktiven,
							$komentarAlarm, $id_komentar)){
						
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
	$self->header_type('redirect');
    $self->header_props(-url => $redirect_url);
	return $redirect_url;
}

sub PogodbaOpomin(){

	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id_agreement = $q->param('id_agreement');
	my $id_komentar = $q->param('id_komentar');
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
	my @loop2;	
	my $dbh;
	my $sql;
	my $sth;
	my $res;
	
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		if($id_komentar>0){
			
			$sql = "SELECT * ".
					"FROM agreement_notice ".
					"WHERE id_agreement=? AND id=?";
			$sth = $dbh->prepare($sql);			
			$sth->execute($id_agreement, $id_komentar);
			$gumbek="spremeni";
			$ime_dokumenta="Urejanje opomina";		
		}
		else{			
			$sql="SELECT * FROM sfr_agreement WHERE id_agreement=?";
			#, sfr_donor_phone
			#, phone, phone_num, default_phone
			$sth = $dbh->prepare($sql);
			$sth->execute($id_agreement);
			$gumbek="dodaj";
			$ime_dokumenta="Dodaj nov opomin";
		}	
		if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
		{
			$datum = $res->{'datum'};
			$komentar = $res->{'besedilo'};
		}
		
	}		
	if($dbh){
		$sql = "SELECT * FROM agreement_notice WHERE id_agreement=? ".
			   "ORDER BY datum";			
	}
	$sth = $dbh->prepare($sql);
	$sth->execute($id_agreement);
	while($res = $sth->fetchrow_hashref){
		if($res->{'datum'}>0){	
			$lepiDatum=substr($res->{'datum'}, 8,2)."/".
			substr($res->{'datum'}, 5,2)."/".substr($res->{'datum'}, 0,4);
		}			
		my %row = (datum => $lepiDatum,
				   komentar => $res->{'besedilo'},
				   komentarId => $res->{'id'},
				   edb_id => $id_agreement,
				   
				   );
		
		push(@loop2, \%row);
		
	}
	
	if($datum>0){
		$lepiDatum=substr($datum, 8,2)."/".substr($datum, 5,2)."/".
				   substr($datum, 0,4);
		$datum=$lepiDatum;
	}

	$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek");
		$template = $self->load_tmpl(	    
							  'DntPogodbeOpomini.tmpl',
					  cache => 1,
					 );
	$template->param(
		IME_DOKUMENTA => $ime_dokumenta,
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
		edb_id => $id_agreement,
		edb_datum => DntFunkcije::trim($datum),
		edb_komentar => DntFunkcije::trim($komentar),
		edb_onload => $onload,
		edb_gumbek => $gumbek,
		komentar_loop => \@loop2,
		#edb_komentar_if => 1,
	);
	$html_output = $template->output; #.$tabelica;
	return $html_output;
}

sub OpominiShrani(){
	
	my $self = shift;
	my $q = $self->query();
	my $hiddenId = $q->param('hiddenId');
	my $id_agreement = $q->param('edb_id');
	my $id_komentar = $q->param('id_komentar');
	my $seja = $q->param('seja');
	my $html_output;
	my $template;
	my $menu_pot;
	my $imeDokumenta;
	my $napaka;
	my $redirect_url;
	
	if($hiddenId=~"komentar"){		
		
		my $id = $q->param('edb_id');
		my $id_komentar = $q->param('komId');
		my $datumKomentarja = $q->param('edb_datum');
		my $komentar = $q->param('edb_komentar');
		
		my $dbh;
		my $res;
		my $sql;
		my $sth;
		my $query;
		my $query2;
		
		$redirect_url="?rm=opomini&amp;id_agreement=$id_agreement";
		$imeDokumenta="Dodaj opomin";
		$napaka="Uspesno dodano!";
		if($datumKomentarja>0){
			$datumKomentarja = substr($datumKomentarja,6,4).'-'.
							substr($datumKomentarja,3,2).'-'.
							substr($datumKomentarja,0,2);
		}
		
		$dbh = DntFunkcije->connectDB;
		if ($dbh) {
			
			if($id_komentar>0){
				$sql = "UPDATE agreement_notice SET ".
					"id_agreement=?, datum=?, besedilo=? ".
					"WHERE id_vrstice=? ";
							
				$sth = $dbh->prepare($sql);
				unless($sth->execute($id, "'".$datumKomentarja."'", $komentar, 
					   $id_komentar)){
					
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
					return $html_output;
				}				
			}
			else {									
					
				$sql = "INSERT INTO agreement_notice ".
					"(id_agreement, datum, besedilo) ".
					"VALUES (?, ?, ?) ";
							
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
					return $html_output;
				}
			}
		}
		$sth->finish;
		$dbh->disconnect();
		
	}
	else{	

		my @deleteIds=$q->param('brisiId');
		my $source=$q->param('brisi');
		my $isci=$q->param('isci');
		my $counter=0;
		my $sql;
		my $sql2;
		my $sql3;
		my $sql4;
		my $sth;
		my $dbh;
		my $id = $q->param('id_agreement');		
			
		$sql="DELETE FROM agreement_notice WHERE ";
			
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id='$id' ";
				$counter++;
			}
			$sql.="OR id='$id' ";
		}	
		$redirect_url="?rm=opomini&id_agreement=$id";
		
		$dbh = DntFunkcije->connectDB;
		if($dbh){
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
				#$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
				return $html_output;
			}
		}

	
	}
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
}

#če uporabnik ni prijavljen:
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'Pogodbe';
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
	#error tmpl brez menija
	if ($q->param('rm') eq "pogodba_komentar" || $q->param('rm') eq "komentarShrani"){
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

1;
