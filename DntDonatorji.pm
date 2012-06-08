package DntDonatorji;
use base 'CGI::Application';
use DBI;

#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use strict;
#use Apache::Session::DBI;

#use HTML::Template;
#use CGI::Session;
#use Data::Dumper;

use Digest::MD5 qw(md5_hex);
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
	
    my $user = DntFunkcije::AuthenticateSession(11, $nivo);
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
	my $seja;
	my $dbh;
	my $sql;
	my $sth;
	my $res;
	my $uporabnik;
	my $result;
	my $redirect_url;
	
	
	$seja = DntFunkcije::Piskotki('id');
	$dbh = DntFunkcije->connectDB;
	
	#DntFunkcije::AuthenticateSession($seja);
    #$self->dbh_config("dbi:PgPP:dbname=donator;host=localhost", "postgres", "ni2mysql");
    $self->start_mode('seznam');
    
    $self->run_modes(
        'seznam' => 'DonatorjiSeznam',
		'Donatorji' => 'SfrDonatorji',
		'Prikazi' => 'DonatorjiSeznam',
		'uredi_donatorja' => 'DonatorUredi',
		'donator_komentar' => 'DonatorKomentar',
		'donator_klici' => 'DonatorKlici',
		'donator_telefon' => 'DonatorTelefon',
		'dodaj' => 'DonatorDodaj',
		'spremeni' => 'DonatorDodaj',	
		'shrani' => 'DonatorSpremeni',
		'posta' => 'IzberiPosto',
		'davcna' => 'IzberiDavcno',
		'zbrisi' => 'DonatorZbrisi',
		'check' => 'check',
		'login' => 'Login',
		'error' => 'Error'
		
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub DonatorjiSeznam{
	
    my $self = shift;
    my $q = $self->query();
    my $seja;
	my $datum;
	my $davcna;	
    my $html_output ;
    my $ime;
    my @loop;
    my $menu_pot;
    my $priimek;
	my $posta;
	my $podjetje;
	my $isci=$q->param('isci');
    my $ulica;
    my $uporabnik;
    my $template ;
	my $oseba;
	my $rowNum=1;
	
	if($isci && $isci eq "1"){
		$isci='0';
	}
	else{
		$isci='1';
	}
	
	
    $seja = $q->param('seja');
    $uporabnik = $q->param('uporabnik');
    $ime  = DntFunkcije::trim($q->param('edb_ime'));
    $priimek = DntFunkcije::trim($q->param('edb_priimek'));
    $ulica = DntFunkcije::trim($q->param('edb_ulica'));
	$posta = DntFunkcije::trim($q->param('edb_posta'));
	my $dan = DntFunkcije::trim($q->param('edb_dan'));
	my $mesec = DntFunkcije::trim($q->param('edb_mesec'));
	my $leto = DntFunkcije::trim($q->param('edb_leto'));
	$podjetje = DntFunkcije::trim($q->param('edb_podjetje'));
	$davcna = DntFunkcije::trim($q->param('edb_davcna'));
	$oseba = $q->param('oseba');
	my $podjetjePosta = DntFunkcije::trim($q->param('edb_podjetjePosta'));
	my $podjetjeUlica = DntFunkcije::trim($q->param('edb_podjetjeUlica'));
	
	my $poKorenuIme=$q->param('po_korenu_ime');
	my $poKorenuPriimek=$q->param('po_korenu_priimek');
	my $poKorenuUlica=$q->param('po_korenu_ulica');
	my $poKorenuPodjetje=$q->param('po_korenu_podjetje');
	my $poKorenuPodjetjeUlica=$q->param('po_korenu_podjetje_ulica');
	my $triPike;
	my $zbrisi;
	my $sth2;
	my $res2;
	my $sql2;
	
	#return 'seznam 123';
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"DntStart.cgi?seja="}, "Zacetek")  ;
	
    $template = $self->load_tmpl(	    
	            'DntDonatorjiSeznam.tmpl',
			      cache => 1,
			     );
    $template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'Seznam donatorjev',
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
		isci => $isci,			 
	);
	my $dbh;
	my $res;
	my $sql;
	my $sth;	
	my $dbh2;
	
	my $hid_sort = $q->param("hid_sort");	
   
	$sql = "select *, name_post from sfr_donor, sfr_post WHERE 1=1 ";
	if($oseba && $oseba eq "pravna"){
		$sql.= " and entity='1'";
	}
	elsif($oseba && $oseba eq "fizicna"){
		$sql.= " and entity='0'";
	}

	$sql.="and id_post = CAST(post AS integer)";
	if($ime)
	{		
		if($poKorenuIme==1){
			$sql .= " and first_name ilike '%$ime%'";
			$poKorenuIme = "checked=checked";
		}
		else{
			$sql .= " and first_name ilike '$ime%'";
			$poKorenuIme = "";	
		}
	}
	if($priimek)
	{
		if($poKorenuPriimek==1){
			$sql .= " and scnd_name ilike '%$priimek%'";
			$poKorenuPriimek = "checked=checked";
		}
		else{
			$sql .= " and scnd_name ilike '$priimek%'";
			$poKorenuPriimek = "";	
		}
	}
	if($ulica)
	{
		if($poKorenuUlica==1){
			$sql .= " and street ilike '%$ulica%'";
			$poKorenuUlica = "checked=checked";
		}
		else{
			$sql .= " and street ilike '$ulica%'";
			$poKorenuUlica = "";	
		}
	}
	if($posta)
	{

		$sql .= " and post ilike '$posta%'";
	}
	
	if($dan && $mesec && $leto)
	{
		if($dan>0){
			if($dan<10 && length($dan)<2){
				$dan="0".$dan;				
			}
			$dan="-".$dan;
		}
		if($mesec>0){
			if($mesec<10 && length($mesec)<2){
				$mesec="0".$mesec;
			}
			$mesec="-".$mesec;
		}
		$datum=$leto.$mesec.$dan;
		$sql .= " and born_date = '$datum'";
		$mesec=substr($mesec, 1,2);
		$dan=substr($dan, 1,2);
	}
	if($davcna)
	{
		$sql .= " and tax_number ilike '%$davcna%'";
	}
	if($podjetje)
	{
		if($poKorenuPodjetje eq "1"){
			$sql .= " and name_company ilike '%$podjetje%'";
			$poKorenuPodjetje = "checked=checked";
		}
		else{
			$sql .= " and name_company ilike '$podjetje%'";
			$poKorenuPodjetje = "";	
		}
	}
	if($podjetjeUlica)
	{
		if($poKorenuPodjetjeUlica eq "1"){
			$sql .= " and street ilike '%$podjetjeUlica%'";
			$poKorenuPodjetjeUlica = "checked=checked";
		}
		else{
			
			$sql .= " and street ilike '$podjetjeUlica%'";
			$poKorenuPodjetjeUlica = "";	
		}
	}
	
	if($podjetjePosta)
	{
		$sql .= " and post ilike '%$podjetjePosta%'";
	}
	#return 'seznam 4123';
	$dbh = DntFunkcije->connectDB;
	$dbh2 = DntFunkcije->connectDB;
	#return 'aa';
	$sql.=" ORDER BY id_donor DESC";
	unless ($ime || $priimek || $ulica || $posta || $dan || $mesec || $leto || 
			   $davcna || $podjetje || $podjetjeUlica || $podjetjePosta){
		$triPike="...";
		$sql.=" LIMIT 12";
	}
	
	if ($dbh){
	    
		my $izbor;
		
		$sth = $dbh->prepare($sql);		
		$sth->execute();
		#return $sql;
		#return $sql;
		while ($res = $sth->fetchrow_hashref) {
			if($isci==1){
				$izbor=$q->a({-href=>"DntDonatorji.cgi?".
				"rm=uredi_donatorja&id_donor=$res->{'id_donor'}".
				"&seja="}, 'uredi');
			}
			else{
				$izbor="<a href=\"#\" onclick=\"TestZapri('myForm', '".
				$rowNum++."', '".$res->{'entity'}."', "."'".$res->{'prefix'}.
				"', '".$res->{'retired'}."', '".$res->{'liable_for_tax'}."'".
				", '".$res->{'name_post'}."')\">izberi</a>";
			}
			$sql2="SELECT * FROM sfr_agreement WHERE id_donor=?";
			$sth2 = $dbh2->prepare($sql2);		
			$sth2->execute($res->{'id_donor'});
			if($res2 = $sth2->fetchrow_hashref){				
				$zbrisi="";
			}		
			else{
				$zbrisi='<input type="checkbox" onclick="PreveriOznacene()"
							 name="brisiId" value="'.$res->{'id_donor'}.'"/>
							 ';
			}
			my $datumRojstva;
			if($res->{'born_date'}){
				$datumRojstva=substr($res->{'born_date'},8,2).'/'.
				substr($res->{'born_date'},5,2).'/'.
				substr($res->{'born_date'},0,4);
			}
			else{
				$datumRojstva="  ";
			}
			my $ime_r=" ";
			my $priimek_r=" ";
			my $naslov_r=" ";
			my $hisnaSt_r=" ";
			my $posta_r=" ";
			my $podjetje_r=" ";
			my $davcna_r=" ";
			my $emso_r=" ";
			
			if ($res->{'first_name'}){
				$ime_r=$res->{'first_name'};
			}
			if ($res->{'scnd_name'}){
				$priimek_r=$res->{'scnd_name'};
			}
			if ($res->{'street'}){
				$naslov_r=$res->{'street'};
			}
			if($res->{'street_number'}){
				$hisnaSt_r=$res->{'street_number'};
			}
			if($res->{'post'}){
				$posta_r=$res->{'post'};
			}
			if($res->{'emso'}){
				$emso_r=$res->{'emso'};
			}
			if($res->{'name_company'}){
				$podjetje_r=$res->{'name_company'};
			}
			if($res->{'tax_number'}){
				$davcna_r=$res->{'tax_number'};
			}
			
			my %row = (				
			izbor => $izbor,
			id_donor => $res->{'id_donor'},
			ime => $ime_r,
			priimek => $priimek_r,
			naslov => $naslov_r,
			hisnaSt => $hisnaSt_r,
			posta => $posta_r,
			datum => $datumRojstva,
			podjetje => $podjetje_r,
			davcna => $davcna_r,
			emso => $emso_r,					
			disable => $zbrisi,
					
			 );
		    
			# put this row into the loop by reference             
			push(@loop, \%row);
		}
			$template->param(
				donator_loop => \@loop,
				edb_ulica => $ulica,
				edb_priimek => $priimek,
				edb_ime => $ime,
				edb_posta => $posta,
				edb_dan => $dan,
				edb_mesec => $mesec,
				edb_leto => $leto,
				edb_podjetje => $podjetje,
				edb_podjetjePosta => $podjetjePosta,
				edb_podjetjeUlica => $podjetjeUlica,
				edb_davcna => $davcna,
				edb_korenIme => $poKorenuIme,
				edb_korenPriimek => $poKorenuPriimek,
				edb_korenUlica => $poKorenuUlica,
				edb_korenPodjetje => $poKorenuPodjetje,
				edb_korenPodjetjeUlica => $poKorenuPodjetjeUlica,
				edb_triPike => $triPike,				
				);
	}
	else{
		return 'Napaka. Povezava do baze ni uspela ';
	}
	
	#}
	
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
    return $html_output;
    
}

sub DonatorUredi() {
	
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	
	my $html_output ;
	my $id_donor = $q->param('id_donor');
	my $uredi= $q->param('uredi');
	my $menu_pot ;
	my $template ;
	my $isci=$q->param('isci');
	my $dbh;
	my $res;
	my $sql;
	my $sth;    
		
    unless($isci){
		$isci=0;
	}
		
	my $counter=1;
	my $status="";
	my $statusF="";
	my $statusP="";
	my $podjetje="";
	my $prednaziv="";
	my $gospod="";
	my $gospa="";
	my $upokojenec="";		
	my $ime="";
	my $priimek="";
	my $ulica="";
	my $hisnaSt="";
	my $postnaSt="";
	my $davcnaSt="";
	my $davcniZavezanec=0;
	my $telefon="";
	my $datumRojstva="";
	my $emso="";
	my $osebniDokument="";
	my $stOsebnegaDokumenta="";
	my $poEmail="";
	my $poUlica="";
	my $poHisnaSt="";
	my $poPostnaSt="";
	my $dovoliEmail="";
	my $dovoliPosta="";
	my $posebniDonator="";
	my $aktivniDonator="";
	my $cestitka="";
	my $novoLeto="";
	my $zahvala="";
	my $ponudba="";
	my $imePoste="";
	my $imePoste2="";
	my @loop;
	my @loop2;
	my @loop3;
	my @loop4;
	my @loop5;
	my $telefonId="";
	my $danRojstva="";
	my $mesecRojstva="";
	my $letoRojstva="";
	my $onload="";
	my $seznamPost="";
	my $linkTelefon="";
	my $linkKlic="";
	my $linkKomentar="";	
	my $countCalls="";
	my $countPhones="";
	my $countComments="";
	my $unique_id=0;
	
	my $dbh2;
	my $sql2;
	my $sth2;
	my $res2;
	my $disabled;
	
	if(!$id_donor){
		$unique_id=time();
	}
	
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {	
		$sql = "SELECT *"
				." FROM sfr_donor "
				." WHERE id_donor =?";
		
		$sth = $dbh->prepare($sql);
		$sth->execute($id_donor);
		$dbh2 = DntFunkcije->connectDB;
		if($dbh2){
			$sql = "SELECT * FROM sfr_donor_phone WHERE id_donor=?";		
			$sth2 = $dbh2->prepare($sql);
			$sth2->execute($id_donor);
			$counter=0;
			while($res2 = $sth2->fetchrow_hashref){
				$counter++;				
			}
			if($counter>0){
				$countPhones='style="font-weight:bold;"';
			}				
			$sql = "SELECT * FROM sfr_donor_comment WHERE id_donor=?";			
			
			$sth2 = $dbh2->prepare($sql);
			$sth2->execute($id_donor);
			$counter=0;
			while($res2 = $sth2->fetchrow_hashref){
				$counter++;				
			}
			if($counter>0){
				$countComments='style="font-weight:bold;"';
			}
			$sql = "SELECT * FROM sfr_donor_call WHERE id_donor=?";			
			
			$sth2 = $dbh2->prepare($sql);
			$sth2->execute($id_donor);
			$counter=0;
			while($res2 = $sth2->fetchrow_hashref){
				$counter++;					
			}
			if($counter>0){
				$countCalls='style="font-weight:bold;"';
			}
		}
		
		
		if($dbh2){
			$sql = "SELECT * FROM sfr_post ORDER BY id_post";			
		}
		$sth2 = $dbh2->prepare($sql);
		$sth2->execute();		
		while($res2 = $sth2->fetchrow_hashref){
			my %row = (id_post => $res2->{'id_post'},
					   name_post => DntFunkcije::trim($res2->{'name_post'}),
				   
					   );
			push(@loop4, \%row);
		}
			
		if($dbh2){
			$sql = "select id_agreement, id_donor, first_name, scnd_name,";
			$sql.= " street, status from sfr_agreement WHERE id_donor=? ";
			$sth2 = $dbh2->prepare($sql);
			$sth2->execute($id_donor);
			while ($res2 = $sth2->fetchrow_hashref) {					
				my %row = (				
					izbor => $q->a({-href=>"DntPogodbe.cgi?".
					"rm=uredi_pogodbo&id_agreement=$res2->{'id_agreement'}&".
					"nazaj=donator&uredi=1"}, 'uredi'),
					id_agreement => DntFunkcije::trim($res2->{'id_agreement'}),
					"agreement_status" => DntFunkcije::trim($res2->{'status'}),
				);
				# put this row into the loop by reference             
				push(@loop5, \%row);
			}
		
		}
		
			
		
		if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
		{
				
			$status = $res->{'entity'};				
			$podjetje = $res->{'name_company'};
			$prednaziv = $res->{'prefix'};
			$upokojenec = $res->{'retired'};
			$ime = $res->{'first_name'};
			$priimek = $res->{'scnd_name'};
			$ulica =$res->{'street'};
			$hisnaSt =$res->{'street_number'};
			$postnaSt =DntFunkcije::trim($res->{'post'});
			$davcnaSt =$res->{'tax_number'};
			$davcniZavezanec =$res->{'liable_for_tax'};
			#$telefon =$res->{'??'};
			$datumRojstva =$res->{'born_date'};
			$emso =$res->{'emso'};
			$osebniDokument =$res->{'personal_dc'};
			$stOsebnegaDokumenta =$res->{'prs_dc_nmbr'};
			$poEmail =$res->{'email'};
			$poUlica =$res->{'street_mail'};
			$poHisnaSt =$res->{'street_num_mail'};
			$poPostnaSt =$res->{'post_mail'};
			$dovoliEmail =$res->{'emailing_alow'};
			$dovoliPosta =$res->{'post_emailing_alow'};
			$posebniDonator =$res->{'special_donor'};
			$aktivniDonator =$res->{'active_donor'};
			$cestitka =$res->{'greting_card'};
			$novoLeto =$res->{'new_year'};
			$zahvala =$res->{'special_thanks'};
			$ponudba =$res->{'offer'};
		}
		
	
		$menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek");
		$template = $self->load_tmpl(	    
					 'DntDonatorEdit.tmpl',
					  cache => 1,
					 );
		
		if($datumRojstva){
			$letoRojstva = substr($datumRojstva,0,4);
			$danRojstva = substr($datumRojstva,8,2);
			$mesecRojstva = substr($datumRojstva,5,2);		
		}
		if($status eq "0"){
			$statusF="checked=\"checked\"";
			$statusP="";
		}
		else{
			$statusP="checked=\"checked\"";
			$statusF="";
		}

		if(DntFunkcije::trim($prednaziv) eq "Gospa"){
			$gospa="selected=\"selected\"";
			$gospod="";
		}
		elsif(DntFunkcije::trim($prednaziv) eq "Gospod"){
			$gospod="selected=\"selected\"";
			$gospa="";
		}
		
		if(defined $davcniZavezanec && $davcniZavezanec==1){
			$davcniZavezanec="checked=\"checked\"";
		}
		else{
			$davcniZavezanec="";
		}
		if($dovoliEmail && $dovoliEmail==1){
			$dovoliEmail="checked=\"checked\"";
		}
		else{
			$dovoliEmail="";
		}
		if($dovoliPosta && $dovoliPosta==1){
			$dovoliPosta="checked=\"checked\"";
		}
		else{
			$dovoliPosta="";
		}
		if($cestitka && $cestitka==1){
			$cestitka="checked=\"checked\"";
		}
		else{
			$cestitka="";
		}
		if($upokojenec && $upokojenec==1){
			$upokojenec="checked=\"checked\"";
		}
		else{
			$upokojenec="";
		}
		if($zahvala && $zahvala==1){
			$zahvala="checked=\"checked\"";
		}
		else{
			$zahvala="";
		}
		if($aktivniDonator && $aktivniDonator==1){
			$aktivniDonator="checked=\"checked\"";
		}
		else{
			$aktivniDonator="";
		}
		if($novoLeto && $novoLeto==1){
			$novoLeto="checked=\"checked\"";
		}
		else{
			$novoLeto="";
		}
		if($ponudba && $ponudba==1){
			$ponudba="checked=\"checked\"";
		}
		else{
			$ponudba="";
		}
		if($posebniDonator && $posebniDonator==1){
			$posebniDonator="checked=\"checked\"";
		}
		else{
			$posebniDonator="";
		}
		
		if($id_donor && $id_donor>0){
			$onload="";
			$sql = "SELECT *"
					." FROM sfr_post "
					." WHERE id_post =?";
			
			$sth = $dbh->prepare($sql);
			$sth->execute($postnaSt);
			$disabled="disabled='true'";
			
			if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
			{
				$imePoste =$res->{'name_post'};
				
			}
			$sql = "SELECT *"
					." FROM sfr_post "
					." WHERE id_post =?";
			
			$sth = $dbh->prepare($sql);
			$sth->execute($poPostnaSt);
			
			if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
			{
				$imePoste2 =$res->{'name_post'};				
			}
		}	
		
		else{
			$onload="onload=\"Uredi();\"";	
		}
		
		if ($uredi){
			$onload="onload=\"Uredi();\"";
		}
		
		$template->param(
			#MENU_POT => $menu_pot,
			IME_DOKUMENTA => 'Podatki o donatorju',
			IME_DOKUMENTA2 => 'Podatki za posiljanje',
			POMOC => "<input type='button' value='?' ".
			"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
			#edb_counter => $counter,
			edb_id => $id_donor,
			edb_statusF => $statusF,
			edb_statusP => $statusP,
			edb_podjetje => DntFunkcije::trim($podjetje),
			edb_gospod => $gospod,
			edb_gospa => $gospa,
			edb_upokojenec => $upokojenec,
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
			edb_poEmail => DntFunkcije::trim($poEmail),
			edb_poUlica => DntFunkcije::trim($poUlica),
			edb_poHisnaSt => DntFunkcije::trim($poHisnaSt),
			edb_poPostnaSt => DntFunkcije::trim($poPostnaSt),
			edb_dovoliEmail => $dovoliEmail,
			edb_dovoliPosta => $dovoliPosta,
			edb_cestitka => $cestitka,
			edb_posebniDonator => $posebniDonator,
			edb_aktivniDonator => $aktivniDonator,
			edb_novoleto => $novoLeto,
			edb_ponudba => $ponudba,
			edb_zahvala => $zahvala,
			edb_loop4 => \@loop4,
			edb_loop5 => \@loop5,
			edb_countPhones => $countPhones,
			edb_countCalls => $countCalls,
			edb_countComments => $countComments,
			edb_isci => $isci,
			edb_unique_id => $unique_id,	
			#klic_loop => \@loop3,
			edb_onload => $onload,	
		);
	
		$html_output = $template->output; #.$tabelica;		
		return $html_output;
	}
	else{
		return 'Napaka. Povezava do baze ni uspela ';
	}
	

}

sub DonatorSpremeni(){

	my $self = shift;
	
	my $q = $self->query();
	my $hiddenId = $q->param('hiddenId');
	my $id_donor = $q->param('edb_id');
	my $seja = $q->param('seja');
	my $html_output;
	my $template;
	my $menu_pot;
	my $imeDokumenta;
	my $napaka;
	my $isci=$q->param('isci');
	my $redirect_url='DntDonatorji.cgi?rm=seznam';
	if($isci==1){
		$redirect_url="DntDonatorji.cgi?rm=seznam&isci=1";
	}	
	if($hiddenId=~"donator"){
		my $cookie = $ENV{'HTTP_COOKIE'};
		$cookie = substr ($cookie, 3);
		my @arr = split(",", $cookie);
		$cookie = $arr[0];
		my $ui = $q->param('ui');
		my $davcniZavezanec = $q->param('davcniZavezanec');		
		my $id = $q->param('edb_id');
		my $status= $q->param('edb_status');
		my $podjetje = $q->param('edb_podjetje');
		my $prednaziv = $q->param('edb_prednaziv');
		my $ime = $q->param('edb_ime');
		my $priimek = $q->param('edb_priimek');
		my $ulica = $q->param('edb_ulica');
		my $hisnaSt = $q->param('edb_hisnaSt');
		my $postnaSt = $q->param('edb_postnaSt');
		my $postnaSt2 = $q->param('edb_postnaSt2');
		my $davcnaSt = $q->param('edb_davcnaSt');		
		my $datumRojstva= $q->param('edb_danRojstva');
		my $posebenDonator = $q->param('edb_posebniDonator');
		my $aktivenDonator = $q->param('edb_aktivniDonator');
		my $dovoliEmail= $q->param('edb_dovoliEmail');
		my $dovoliPosta= $q->param('edb_dovoliPosta');
		my $cestitka= $q->param('edb_cestitka');
		my $novoLeto= $q->param('edb_novoLeto');
		my $zahvala= $q->param('edb_zahvala');
		my $ponudba= $q->param('edb_ponudba');
		my $danRojstva = $q->param('edb_danRojstva');
		my $mesecRojstva = $q->param('edb_mesecRojstva');
		my $letoRojstva = $q->param('edb_letoRojstva');
		my $emso = $q->param('edb_emso');
		my $osebniDokument = $q->param('edb_osebniDokument');
		my $stOsebnegaDokumenta = $q->param('edb_stOsebnegaDokumenta');
		my $poEmail = $q->param('edb_poEmail');
		my $poUlica = $q->param('edb_poUlica');
		my $poHisnaSt = $q->param('edb_poHisnaSt');
		my $poPostnaSt = $q->param('edb_poPostnaSt');
		my $poPostnaSt2 = $q->param('edb_poPostnaSt2');
		my $upokojenec = $q->param('upokojenec');		
		
		my $dbh;
		my $res;
		my $sql;
		my $sth;
		$podjetje =~ s/\n//g;
		$podjetje =~ s/\r//g;
		if($upokojenec=~"on"){
			$upokojenec=1;
		}
		else{
			$upokojenec=0;
		}		
		if($davcniZavezanec=~"on"){			
			$davcniZavezanec=1;
		}
		else{
			$davcniZavezanec=0;
		}	
		
		if(!defined $dovoliEmail){
			$dovoliEmail=0;
		}
		if(!defined $dovoliPosta){
			$dovoliPosta=0;
		}
		if(!defined $cestitka){
			$cestitka=0;
		}
		if(!defined $novoLeto){
			$novoLeto=0;
		}
		if(!defined $zahvala){
			$zahvala=0;
		}
		if(!defined $ponudba){
			$ponudba=0;
		}
		if(!defined $posebenDonator){
			$posebenDonator=0;
		}
		if(!defined $aktivenDonator){
			$aktivenDonator=0;
		}		
		
		$imeDokumenta = "Shrani donatorja";
		$napaka = "Shranjevanje uspesno!<br />";
		
		if($letoRojstva<1000 || $danRojstva<0 || $danRojstva>31 ||
		   $mesecRojstva<0 || $mesecRojstva>12){
		   $napaka="NAPAKA! Neveljaven datum!";
		}
		
		$datumRojstva=$letoRojstva."-".$mesecRojstva."-".$danRojstva;
		unless (length($datumRojstva)>3){
			$datumRojstva="";
		}
		
		
		$dbh = DntFunkcije->connectDB;
		if ($dbh && $napaka == "Shranjevanje uspesno!<br />") {
			#ZAČETEK TRANSACTION BLOKA:
			
			
			if($id_donor>0){			
				
				$redirect_url="DntDonatorji.cgi?rm=seznam";				
				$napaka = DonatorUpdate($dbh, $podjetje, $ime, $priimek,
				  $ulica, $hisnaSt, $postnaSt,
				  $davcnaSt, $osebniDokument, $stOsebnegaDokumenta,
				  $emso, $poEmail, $davcniZavezanec,
				  $poUlica, $poHisnaSt, $poPostnaSt,
				  $status, $prednaziv, $upokojenec,
				  $dovoliEmail, $dovoliPosta,
				  $cestitka, $novoLeto, $zahvala,
				  $ponudba, $posebenDonator, $aktivenDonator,
				  $postnaSt2, $poPostnaSt2,
				  $id_donor, $datumRojstva);
			}
			else{
				
				$napaka = DonatorInsert($dbh, $podjetje, $ime, $priimek,
				  $ulica, $hisnaSt, $postnaSt,
				  $davcnaSt, $osebniDokument, $stOsebnegaDokumenta,
				  $emso, $poEmail, $davcniZavezanec,
				  $poUlica, $poHisnaSt, $poPostnaSt,
				  $status, $prednaziv, $upokojenec,
				  $dovoliEmail, $dovoliPosta,
				  $cestitka, $novoLeto, $zahvala,
				  $ponudba, $posebenDonator, $aktivenDonator,
				  $postnaSt2, $poPostnaSt2,
				  $id_donor, $datumRojstva);
				if($napaka!=0){
					$id_donor = $napaka;
				}
				#Vstavljanje telefona, klicev in komentarjev iz zacasnih tabel:
				$sql= "SELECT * FROM uporabniki_tmp WHERE id_user='$cookie' AND".
						" id_unique='$ui' AND tmp_source ilike '%_don'".
						" ORDER BY id ASC";
				$sth = $dbh->prepare($sql);
				$sth->execute();

				my $sth3;
				while($res = $sth->fetchrow_hashref){
					#komentar
					if($res->{'tmp_source'} eq "komentarji_don"){
						if($res->{'tmp_date2'}){
						$sql = "INSERT INTO sfr_donor_comment (".
						" id_donor,".
						" date, comment,".
						" alarm, alarm_active,".
						" comment_alarm) VALUES (".
						" '$id_donor', ".
						" '$res->{'tmp_date1'}', '$res->{'tmp_field1'}', ".
						" '$res->{'tmp_date2'}', '$res->{'tmp_toggle'}', ".
						" '$res->{'tmp_field2'}')";
						}
						else{
						$sql = "INSERT INTO sfr_donor_comment (".
						" id_donor,".
						" date, comment,".
						" alarm, alarm_active,".
						" comment_alarm) VALUES (".
						" '$id_donor', ".
						" '$res->{'tmp_date1'}', '$res->{'tmp_field1'}', ".
						" NULL, '$res->{'tmp_toggle'}', ".
						" '$res->{'tmp_field2'}')";	
						}
						$sth3 = $dbh->prepare($sql);
						unless($sth3->execute()){
							
						};
						
					}
					#telefon
					elsif($res->{'tmp_source'} eq "telefoni_don"){
						$sql = "INSERT INTO sfr_donor_phone (".
						" id_donor,".
						" phone, phone_num,".
						" default_phone) VALUES (".
						" '$id_donor', ".
						" '$res->{'tmp_field1'}', '$res->{'tmp_field2'}', ".
						" '$res->{'tmp_toggle'}')";
						$sth3 = $dbh->prepare($sql);
						unless($sth3->execute()){
							
						}
						$sql = "SELECT currval('sfr_donor_phone_id_vrstice_seq') as last";
						$sth3 = $dbh->prepare($sql);
						$sth3->execute();
						my $last_id;
						my $res2;
						if($res2 = $sth3->fetchrow_hashref){
							$last_id=$res2->{'last'};
						}
						else{
							
						}
						$sql = "UPDATE uporabniki_tmp SET tmp_field2='$last_id' ".
							" WHERE tmp_field2='$res->{'id'}'";
						$sth3 = $dbh->prepare($sql);
						unless($sth3->execute()){
							
						};
						
					}
				}
				$sql= "SELECT * FROM uporabniki_tmp WHERE id_user='$cookie' AND".
						" id_unique='$ui' AND tmp_source='klici_don'".
						" ORDER BY id ASC";
				$sth = $dbh->prepare($sql);
				$sth->execute();
				while($res = $sth->fetchrow_hashref){
					#klic
					$sql = "INSERT INTO sfr_donor_call (".
					" id_donor,".
					" date, comment,".
					" id_phone) VALUES (".
					" '$id_donor', ".
					" '$res->{'tmp_date1'}', '$res->{'tmp_field1'}', ".
					" '$res->{'tmp_field2'}')";						
					$sth3 = $dbh->prepare($sql);
					unless($sth3->execute()){
						
					};
				}
			}
			if($napaka == 0){
					$template = $self->load_tmpl(	    
						'DntRocniVnosNapaka.tmpl',
					cache => 1,
					);
					$template->param(
						MENU => DntFunkcije::BuildMenu(),
						IME_DOKUMENTA => 'Napaka!',
						napaka_opis => "Napaka pri vnosu donatorja.",
						akcija => ''
					);			
					$html_output = $template->output; #.$tabelica;
					return $html_output;
			}
			#KONEC TRANSACTION BLOKA:
	
		}
		$dbh->disconnect();
		
	}
	#$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	#$template = $self->load_tmpl('DntDodajSpremeni.tmpl',
	#				              cache => 1,
	#				            );
	
	#$template->param(
	#			 MENU_POT => $menu_pot,
	#			 IME_DOKUMENTA => $imeDokumenta,
	#			 edb_error => $napaka,
	#			 );

	#$html_output = $template->output; #.$tabelica;	
	$self->header_type('redirect');
    $self->header_props(-url => $redirect_url);
	return $redirect_url;
}
sub DonatorUpdate{
	my $dbh = $_[0];
	my $podjetje= $_[1];
	my $ime= $_[2];
	my $priimek = $_[3];
	my $ulica= $_[4];
	my $hisnaSt= $_[5];
	my $postnaSt= $_[6];
	my $davcnaSt= $_[7];
	my $osebniDokument= $_[8];
	my $stOsebnegaDokumenta = $_[9];
	my $emso= $_[10];
	my $poEmail= $_[11];
	my $davcniZavezanec = $_[12];				  
	my $poUlica= $_[13];
	my $poHisnaSt= $_[14];
	my $poPostnaSt = $_[15];
	my $status= $_[16];
	my $prednaziv= $_[17];
	my $upokojenec = $_[18];
	my $dovoliEmail= $_[19];
	my $dovoliPosta = $_[20];
	my $cestitka= $_[21];
	my $novoLeto= $_[22];
	my $zahvala = $_[23];
	my $ponudba= $_[24];
	my $posebenDonator= $_[25];
	my $aktivenDonator = $_[26];
	my $postnaSt2= $_[27];
	my $poPostnaSt2 = $_[28];
	my $id_donor = $_[29];
	my $datumRojstva = $_[30];
	my $html_output="0";
	my $sql =
		"UPDATE sfr_donor ".
		"SET name_company=?, first_name=?, scnd_name=?,".
		"street=?, street_number=?, post=?, ".
		"tax_number=?, personal_dc=?, prs_dc_nmbr=?, ".
		"emso=?, email=?, liable_for_tax=?, ".
		"street_mail=?, street_num_mail=?, post_mail=?,".
		"entity=?, prefix=?, retired=?,".
		"born_date=NULL, emailing_alow=?, post_emailing_alow=?,".
		"greting_card=?, new_year=?, special_thanks=?,".
		"offer=?, special_donor=?, active_donor=?, ".
		"post_name=?, post_name_mail=?".
		"WHERE id_donor=?";
	my $sth = $dbh->prepare($sql);
	unless($sth->execute($podjetje, $ime, $priimek,
				  $ulica, $hisnaSt, $postnaSt,
				  $davcnaSt, $osebniDokument, $stOsebnegaDokumenta,
				  $emso, $poEmail, $davcniZavezanec,
				  $poUlica, $poHisnaSt, $poPostnaSt,
				  $status, $prednaziv, $upokojenec,
				  $dovoliEmail, $dovoliPosta,
				  $cestitka, $novoLeto, $zahvala,
				  $ponudba, $posebenDonator, $aktivenDonator,
				  $postnaSt2, $poPostnaSt2,
				  $id_donor)){
		
		my $napaka_opis = $sth->errstr;
		return 0;
	}
	if($datumRojstva){
		$sql="UPDATE sfr_donor set born_date=? WHERE id_donor=?";
		$sth = $dbh->prepare($sql);
		unless($sth->execute($datumRojstva, $id_donor)){					
			my $napaka_opis = $sth->errstr;
			#return 0;
			
		}
	}
	return $id_donor;
	
}
sub DonatorInsert{

	my $dbh = $_[0];
	my $podjetje= $_[1];
	my $ime= $_[2];
	my $priimek = $_[3];
	my $ulica= $_[4];
	my $hisnaSt= $_[5];
	my $postnaSt= $_[6];
	my $davcnaSt= $_[7];
	my $osebniDokument= $_[8];
	my $stOsebnegaDokumenta = $_[9];
	my $emso= $_[10];
	my $poEmail= $_[11];
	my $davcniZavezanec = $_[12];				  
	my $poUlica= $_[13];
	my $poHisnaSt= $_[14];
	my $poPostnaSt = $_[15];
	my $status= $_[16];
	my $prednaziv= $_[17];
	my $upokojenec = $_[18];
	my $dovoliEmail= $_[19];
	my $dovoliPosta = $_[20];
	my $cestitka= $_[21];
	my $novoLeto= $_[22];
	my $zahvala = $_[23];
	my $ponudba= $_[24];
	my $posebenDonator= $_[25];
	my $aktivenDonator = $_[26];
	my $postnaSt2= $_[27];
	my $poPostnaSt2 = $_[28];
	my $id_donor = $_[29];
	my $datumRojstva = $_[30];
	my $html_output="0";
	
	
	
	my $sql = "INSERT INTO sfr_donor ".
			"(name_company, first_name, scnd_name,".
			 "street, street_number, post, ".
			 "tax_number, personal_dc, prs_dc_nmbr, ".
			 "emso, email, liable_for_tax, ".
			 "street_mail, street_num_mail, post_mail,".
			 "entity, prefix, retired,".
			 "born_date, emailing_alow, post_emailing_alow,".
			 "greting_card, new_year, special_thanks,".
			 "offer, special_donor, active_donor, ".
			 "post_name, post_name_mail) ".
			 "VALUES (?, ? , ?, ".
					 "?, ?, ?, ".
					 "?, ?, ?, ".
					 "?, ?, ?, ".
					 "?, ?, ?, ".
					 "?, ?, ?, ".
					 "NULL, ?, ?, ".
					 "?, ?, ?, ".								
					 "?, ?, ?, ".
					 "?, ? )";
	 my $sth = $dbh->prepare($sql);
	 unless($sth->execute($podjetje, $ime , $priimek,
					 $ulica, $hisnaSt, $postnaSt, 
					 $davcnaSt, $osebniDokument, $stOsebnegaDokumenta, 
					 $emso, $poEmail, $davcniZavezanec, 
					 $poUlica, $poHisnaSt, $poPostnaSt, 
					 $status, $prednaziv, $upokojenec, 
					 $dovoliEmail, $dovoliPosta, 
					 $cestitka, $novoLeto, $zahvala, 								
					 $ponudba, $posebenDonator, $aktivenDonator, 
					 $postnaSt2, $poPostnaSt2)){					
		 my $napaka_opis = $sth->errstr;
		 return 0;
		 
	 }
	 $sql="SELECT id_donor FROM sfr_donor ORDER BY id_donor ".
		 "DESC LIMIT 1";
	 $sth = $dbh->prepare($sql);
	 my $res;
	 $sth->execute();
	 if($res = $sth->fetchrow_hashref){
		$id_donor=$res->{'id_donor'};
	 }
	 if($datumRojstva){					
	
		 $sql="UPDATE sfr_donor SET born_date='$datumRojstva' WHERE id_donor='$id_donor'";
		 $sth = $dbh->prepare($sql);
		 unless($sth->execute()){					
			 my $napaka_opis = $sth->errstr;
			 #return 0;
		 }
		 
	 }
	 return $id_donor;
}
sub DonatorDodaj(){
	
	my $self = shift;
	my $q = $self->query();
	my $hiddenId = $q->param('hiddenId');
	my $id_donor = $q->param('edb_id');
	my $id_komentar = $q->param('id_komentar');
	my $unique_id = $q->param('ui');
	my $seja = $q->param('seja');
	my $html_output;
	my $template;
	my $menu_pot;
	my $imeDokumenta;
	my $napaka;
	my $redirect_url;
	
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
		
		$redirect_url="?rm=donator_komentar&amp;id_donor=$id_donor&amp;ui=$unique_id";
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
				if($unique_id){
					$sql = "UPDATE uporabniki_tmp SET ".
						"tmp_date1=?, tmp_field1=? ".
						"WHERE id=? ";
				}
				else{
					$sql = "UPDATE sfr_donor_comment SET ".
						"date=?, comment=? ".
						"WHERE id_vrstice=? ";
				}
							
				$sth = $dbh->prepare($sql);
				unless($sth->execute("'".$datumKomentarja."'", $komentar, 
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
				if($unique_id){
					$sql = "UPDATE uporabniki_tmp SET ".
						"tmp_date2=?, tmp_toggle=?, tmp_field2=? ".
						"WHERE id=? ";
				}
				else{
					$sql = "UPDATE sfr_donor_comment SET ".
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
			else {									
				if($unique_id){
					$id= $unique_id;
					$sql = "INSERT INTO uporabniki_tmp ".
						"(id_unique, tmp_date1, tmp_field1, tmp_source, id_user) ".
						"VALUES (?, ?, ?, 'komentarji_don', $cookie) ";
				}
				else{
					$sql = "INSERT INTO sfr_donor_comment ".
						"(id_donor, date, comment) ".
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
					return $html_output;
				}
				if($unique_id){
					$sql = "SELECT id FROM uporabniki_tmp ".
					"WHERE id_user=$cookie AND id_unique = $unique_id ".
					"ORDER BY id DESC LIMIT 1";				
				}
				else{
					$sql = "SELECT id_vrstice FROM sfr_donor_comment ORDER BY".
						" id_vrstice DESC LIMIT 1";	
				}
				#return $sql;
				$sth = $dbh->prepare($sql);
				$sth->execute();
				if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
				{
					if($unique_id){
						$id_komentar= $res->{'id'};
					}
					else{
						$id_komentar= $res->{'id_vrstice'};
					}
				}
				if($unique_id){
					$sql = "UPDATE uporabniki_tmp SET ".
						"tmp_date2=?, tmp_toggle=?, tmp_field2=? ".
						"WHERE id=? ";
				}
				else{
					$sql = "UPDATE sfr_donor_comment SET ".
						"alarm=?, alarm_active=?, comment_alarm=? ".
						"WHERE id_vrstice=? ";
				}
				#return "$sql <br />$datumAlarm, $aktiven,
				#		$komentarAlarm, $id_komentar";
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
		}
		$sth->finish;
		$dbh->disconnect();
		
	}
	if($hiddenId=~"klic"){
		my $id = $q->param('edb_id');
		my $id_klic= $q->param('klicId');
		my $telefon = $q->param('edb_telefon');
		my $datum = $q->param('edb_datum');
		my $komentar = $q->param('edb_komentar');
		$redirect_url="?rm=donator_klici&amp;id_donor=$id_donor";
		my $dbh;
		my $res;
		my $sql;
		my $sth;		
		$imeDokumenta="Dodaj klic";
		$napaka="Uspesno dodano!";		
		$datum = substr($datum,6,4).'-'.
						substr($datum,3,2).'-'.
						substr($datum,0,2);
		if($unique_id){
			$id_donor= $unique_id;
		}
		$dbh = DntFunkcije->connectDB;
		if ($dbh) {
			if($id_klic>0){
				if($unique_id){
					$sql = "UPDATE uporabniki_tmp SET id_unique=?, tmp_date1=?, ".
					   "tmp_field1=?, tmp_field2=? WHERE id=? AND tmp_source='klici_don'";	
				}
				else{
					$sql = "UPDATE sfr_donor_call SET id_donor=?, date=?, ".
						   "comment=?, id_phone=? WHERE id_vrstice=?";
				}
				$sth = $dbh->prepare($sql);
				unless($sth->execute($id, "'".$datum."'", $komentar,
									 $telefon, $id_klic)){
					
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
			else{
				if($unique_id){
					$sql="INSERT INTO uporabniki_tmp (id_unique, tmp_date1, tmp_field1, tmp_field2, id_user, tmp_source) ".
					   "VALUES (?, ?, ?, ?, '$cookie', 'klici_don')";
				}
				else{
					$sql="INSERT INTO sfr_donor_call (id_donor, date, comment, id_phone) ".
					   "VALUES (?, ?, ?, ?)";
				}
				$sth = $dbh->prepare($sql);
				unless($sth->execute($id, "'".$datum."'", $komentar, $telefon)){
					
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
		my $unique_id = $q->param('ui');
		my $dbh;
		my $res;
		my $sql;
		my $sth;
		if($unique_id){
			$id = $unique_id;
		}
		$imeDokumenta="Dodaj klic";
		$napaka="Uspesno dodano!";
		$redirect_url="?rm=donator_telefon&amp;id_donor=$id_donor";
		
		my $cookie = $ENV{'HTTP_COOKIE'};
		$cookie = substr ($cookie, 3);
		my @arr = split(",", $cookie);
		$cookie = $arr[0];
		
		$dbh = DntFunkcije->connectDB;
		if($primarni=~"on"){
			$primarni=1;
			if ($dbh) {
				if($unique_id){
					$sql = "UPDATE uporabniki_tmp SET tmp_toggle = 0 WHERE id_unique = ?";
				}
				else{
					$sql = "UPDATE sfr_donor_phone SET default_phone = 0 WHERE id_donor = ?";
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
			if($id_telefona>0){
				if($unique_id){
					$sql = "UPDATE uporabniki_tmp SET id_unique=?, tmp_field1=?, tmp_field2=?, tmp_toggle=?".
					   "WHERE id=?";	
				}
				else{
					$sql = "UPDATE sfr_donor_phone SET id_donor=?, phone=?, phone_num=?, default_phone=?".
					   "WHERE id_vrstice=?";	
				}

			#print $q->p($sql_vprasaj);
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
						napaka_opis => $napaka_opis,
						akcija => ''
					);
            
                    $html_output = $template->output; #.$tabelica;
                    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
                    return $html_output;	
				}	
				
			}
			else{		
				if($unique_id){
					$sql = "INSERT INTO uporabniki_tmp (id_unique, tmp_field1, tmp_field2, tmp_toggle, tmp_source, id_user) ".
					   "VALUES (?, ?, ?, ?, 'telefoni_don', '$cookie')";					
				}
				else{
					$sql = "INSERT INTO sfr_donor_phone (id_donor, phone, phone_num, default_phone) ".
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
	
	#$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	#	$template = $self->load_tmpl(	    
	#						  'DntDodajSpremeni.tmpl',
	#				  cache => 1,
	#				 );
	#$template->param(

	#			);

	#$html_output = $template->output; #.$tabelica;
	#return $html_output;
	if($unique_id){
		$redirect_url.="&amp;ui=$unique_id";
	}
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
	
	
}
sub DonatorKomentar(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id_donor = $q->param('id_donor') || "";
	my $unique_id = $q->param('ui');
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
	my $cookie = $ENV{'HTTP_COOKIE'};
	$cookie = substr ($cookie, 3);
	my @arr = split(",", $cookie);
	$cookie = $arr[0];


	if ($dbh) {
		if($id_komentar>0){
			if($unique_id){
				$sql = "SELECT * ".
					"FROM uporabniki_tmp ".
					"WHERE id='$id_komentar' and tmp_source='komentarji_don'".
					"AND id_user='$cookie'";
			}
			else{
			$sql = "SELECT first_name, scnd_name, date, comment, alarm, ".
					"alarm_active, comment_alarm ".
					"FROM sfr_donor, sfr_donor_comment ".
					"WHERE sfr_donor.id_donor='$id_donor' AND id_vrstice='$id_komentar'";
			}
			$sth = $dbh->prepare($sql);			
			$sth->execute();
			$gumbek="spremeni";
			$ime_dokumenta="Urejanje komentarja";		
		}
		else {			
			$sql="SELECT first_name, scnd_name FROM sfr_donor WHERE id_donor=?";
			#, sfr_donor_phone
			#, phone, phone_num, default_phone
			$sth = $dbh->prepare($sql);
			if($id_donor eq ""){
				$sth->execute(0);
			}
			else{
				$sth->execute($id_donor);
			}
			$gumbek="dodaj";
			$ime_dokumenta="Dodaj nov komentar";
		}
		#return $sql;
		if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
		{
			if($unique_id){
				$ime = $res->{'first_name'};				
				$priimek = $res->{'scnd_name'};
				$datum = $res->{'tmp_date1'};
				$komentar = $res->{'tmp_field1'};
				$alarm = $res->{'tmp_date2'};
				$alarmAktivni = $res->{'tmp_toggle'};
				$komentarAlarm = $res->{'tmp_field2'};
			}
			else{
				$ime = $res->{'first_name'};				
				$priimek = $res->{'scnd_name'};
				$datum = $res->{'date'};
				$komentar = $res->{'comment'};
				$alarm = $res->{'alarm'};
				$alarmAktivni = $res->{'alarm_active'};
				$komentarAlarm = $res->{'comment_alarm'};	
			}
		
		}
		if($unique_id){
			$sql = "SELECT tmp_date1, tmp_field1, id ".
			"FROM uporabniki_tmp WHERE id_unique='$unique_id' ".
			"AND tmp_source='komentarji_don' AND id_user='$cookie'".
			"ORDER BY tmp_date1";			
	
		}
		else{
			$sql = "SELECT date, comment, id_vrstice ".
			"FROM sfr_donor_comment WHERE id_donor='$id_donor' ORDER BY date";			
	
		}
		#return $sql;
		$sth = $dbh->prepare($sql);
		$sth->execute();		
		while($res = $sth->fetchrow_hashref){
			
			if($unique_id){
				if($res->{'tmp_date1'}){	
					$lepiDatum=substr($res->{'tmp_date1'}, 8,2)."/".substr($res->{'tmp_date1'}, 5,2)."/".substr($res->{'tmp_date1'}, 0,4);
				}
				my %row = (datum => $lepiDatum,
				   komentar => $res->{'tmp_field1'},
				   komentarId => $res->{'id'},
				   tmp_link => "&amp;ui=$unique_id",
				   edb_komentar_if => 1,
				   edb_id => "",
				   
				);
				push(@loop2, \%row);
			}
			else{
				if($res->{'date'}){	
				$lepiDatum=substr($res->{'date'}, 8,2)."/".substr($res->{'date'}, 5,2)."/".substr($res->{'date'}, 0,4);
				}
				my %row = (datum => $lepiDatum,
						   komentar => $res->{'comment'},
						   komentarId => $res->{'id_vrstice'},
						   edb_komentar_if => 1,
						   edb_id => $id_donor,
						   
				);				
				push(@loop2, \%row);
			}
		}
	}
	if($datum>0){
		$lepiDatum=substr($datum, 8,2)."/".substr($datum, 5,2)."/".substr($datum, 0,4);
		$datum=$lepiDatum;
		$lepiDatum=substr($alarm, 8,2)."/".substr($alarm, 5,2)."/".substr($alarm, 0,4);
		$alarm=$lepiDatum;
	}
	if($alarmAktivni==1){
			$alarmAktivni="checked=\"checked\"";
		}
	else{
			$alarmAktivni="";
		}
	my $brisi_ui = "";
	if($unique_id){
		$brisi_ui = "_tmp";
		$id_donor = $unique_id;
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
		edb_id => $id_donor,
		komId => $id_komentar,
		edb_ime => DntFunkcije::trim($ime),
		edb_priimek => DntFunkcije::trim($priimek),
		edb_datum => DntFunkcije::trim($datum),
		edb_komentar => DntFunkcije::trim($komentar),
		edb_alarm => DntFunkcije::trim($alarm),
		edb_alarmAktivni => DntFunkcije::trim($alarmAktivni),
		edb_komentarAlarm => DntFunkcije::trim($komentarAlarm),
		edb_onload => $onload,
		ui => $unique_id,
		edb_gumbek => $gumbek,
		komentar_loop => \@loop2,
		edb_komentar_if => 1,
		brisi_ui => $brisi_ui
	);
	$html_output = $template->output; #.$tabelica;
	return $html_output;
	
    
	
}
sub DonatorZbrisi(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $redirect_url;
	my @deleteIds=$q->param('brisiId');
	my $source=$q->param('brisi');
	my $isci=$q->param('isci');
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
	my $id_donor=$q->param('id_donor');
	if($source=~"telefon"){		
		
		$sql="DELETE FROM sfr_donor_phone WHERE ";
			
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id_vrstice='$id' ";
				$counter++;
			}
			$sql.="OR id_vrstice='$id' ";
		}	
		$redirect_url="?rm=donator_telefon&id_donor=$id_donor";
	}
	if($source=~"telefon_tmp"){		
		$sql="DELETE FROM uporabniki_tmp WHERE ";
		$counter= 0;	
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id='$id' ";
				$counter++;
			}
			$sql.="OR id='$id' ";
		}
		
		$redirect_url="?rm=donator_telefon&ui=$id_donor";
	}
	
	if($source=~"donator"){		
		
		$sql="DELETE FROM sfr_donor WHERE ";
		$sql2="DELETE FROM sfr_donor_call WHERE ";
		$sql3="DELETE FROM sfr_donor_comment WHERE ";
		$sql4="DELETE FROM sfr_donor_phone WHERE ";
		
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id_donor='$id' ";
				$counter++;
				$sql2.="id_donor='$id' ";
				$sql3.="id_donor='$id' ";
				$sql4.="id_donor='$id' ";
			}
			else{
				$sql.="OR id_donor='$id' ";
				$sql2.="OR id_donor='$id' ";
				$sql3.="OR id_donor='$id' ";
				$sql4.="OR id_donor='$id' ";
			}
		}
		if($isci==1){
			$redirect_url="?rm=seznam&id_donor=$id_donor&isci=1";
		}
		else{
			$redirect_url="?rm=seznam&id_donor=$id_donor";
		}
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
		
		
		$sql="DELETE FROM sfr_donor_comment WHERE ";
		$counter = 0;	
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id_vrstice='$id' ";
				$counter++;
			}
			$sql.="OR id_vrstice='$id' ";
		}
		$redirect_url="?rm=donator_komentar&id_donor=$id_donor";
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
		$sql.=" AND tmp_source = 'komentarji_don'";
		$redirect_url="?rm=donator_komentar&ui=$id_donor";
		#return $redirect_url." ".$sql;
	}
	if($source=~"klic"){		
		
		$sql="DELETE FROM sfr_donor_call WHERE ";
			
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id_vrstice='$id' ";
				$counter++;
			}
			$sql.="OR id_vrstice='$id' ";
		}	
		$redirect_url="?rm=donator_klici&id_donor=$id_donor";
	}
	if($source=~"klic_tmp"){		
		
		$sql="DELETE FROM uporabniki_tmp WHERE ";
		$counter=0;
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id='$id' ";
				$counter++;
			}
			$sql.="OR id='$id' ";
		}	
		$redirect_url="?rm=donator_klici&id_donor=$id_donor&ui=$id_donor";
	}
	
	if($source=~"pogodba"){
		
		$sql="DELETE FROM sfr_agreement WHERE ";
				
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id_agreement='$id' ";
				$counter++;
			}
			$sql.="OR id_agreement='$id' ";
		}	
		$redirect_url="?rm=uredi_donatorja&id_donor=$id_donor";		
	}
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
	
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
	
}
sub DonatorTelefon(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id_donor = $q->param('id_donor');
	my $id_telefon = $q->param('id_phone');
	my $unique_id = $q->param('ui');
	my $menu_pot;
	my $template;	
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
	if($unique_id){
		$id_donor = $unique_id;

	}
	my $cookie = $ENV{'HTTP_COOKIE'};
	$cookie = substr ($cookie, 3);
	my @arr = split(",", $cookie);
	$cookie = $arr[0];
	
	$dbh = DntFunkcije->connectDB;
	
	if ($dbh) {
		if($id_telefon>0){
			if($unique_id){
				$sql="SELECT * FROM uporabniki_tmp".
					" WHERE id_unique = ? AND tmp_source = 'telefoni_don' ".
					"AND id=? AND id_user=$cookie";
			}
			else{
				$sql="SELECT first_name, scnd_name, phone, phone_num, default_phone".
					" FROM sfr_donor, sfr_donor_phone WHERE sfr_donor.id_donor=? ".
					"AND id_vrstice=?";
			}
			$sth = $dbh->prepare($sql);			
			$sth->execute($id_donor, $id_telefon);
			$gumbek="spremeni";
			$onload="onload=\"Uredi(); Uredi2();\"";
		}
		else{
			$onload="onload=\"Uredi();\"";
			$sql="SELECT first_name, scnd_name FROM sfr_donor WHERE id_donor=?";
			$sth = $dbh->prepare($sql);
			$sth->execute($id_donor);
			$gumbek="dodaj";			
		}
		#return "$sql, $id_donor, $id_telefon";
		if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
		{
			#return "assa";
			if($unique_id){
				$ime = $res->{'first_name'};
				$priimek = $res->{'scnd_name'};
				$telefon = $res->{'tmp_field1'};
				$telefonskaSt = $res->{'tmp_field2'};
				$primarni = $res->{'tmp_toggle'};	
			}
			else{
				$ime = $res->{'first_name'};
				$priimek = $res->{'scnd_name'};
				$telefon = $res->{'phone'};
				$telefonskaSt = $res->{'phone_num'};
				$primarni = $res->{'default_phone'};
			}
		}

		if($unique_id){
			$sql = "SELECT * FROM uporabniki_tmp ".
					"WHERE id_unique=? AND tmp_source = 'telefoni_don' AND id_user=$cookie";			
		}
		else{
			$sql = "SELECT phone, phone_num, id_vrstice FROM sfr_donor_phone WHERE id_donor=?"			
		}
		#return $sql." ".$id_donor;
		$sth = $dbh->prepare($sql);
		$sth->execute($id_donor);			
		while($res = $sth->fetchrow_hashref){
			if($unique_id){
				my %row = (telefon => $res->{'tmp_field1'},
				   telefonska => $res->{'tmp_field2'},
				   telefonId => $res->{'id'},
				   tmp_link => "&amp;ui=$id_donor",
				   edb_id => $id_donor,					   
			    );
			push(@loop, \%row);
			}
			else{
				my %row = (telefon => $res->{'phone'},
						   telefonska => $res->{'phone_num'},
						   telefonId => $res->{'id_vrstice'},
						   edb_id => $id_donor,
						   
						   );
				push(@loop, \%row);
			}
		}
	}	
	if($primarni==1){
		$primarni="checked=\"checked\"";
	}
	else{
		$primarni="";
	}
	my $ui_brisi="";
	if($unique_id){
		$ui_brisi= "_tmp"
	}
	$menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
		$template = $self->load_tmpl(	    
							  'DntDonatorTelefon.tmpl',
					  cache => 1,
					 );
	$template->param(
		IME_DOKUMENTA => "Uredi telefonske stevilke",
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		edb_id => $id_donor,
		id_telefona => $id_telefon,
		edb_ime => DntFunkcije::trim($ime),
		edb_priimek => DntFunkcije::trim($priimek),
		edb_telefon => DntFunkcije::trim($telefon),
		edb_telefonskaSt => DntFunkcije::trim($telefonskaSt),
		edb_primarni => $primarni,
		gumbek => $gumbek,
		edb_onload => $onload,
		brisi_ui => $ui_brisi,
		ui => $unique_id,
		donator_loop => \@loop,
	);
	$html_output = $template->output; #.$tabelica;
	return $html_output;
	
    
	
}

sub DonatorKlici(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id_donor = $q->param('id_donor');
	my $id_klic = $q->param('id_klic');
	my $unique_id = $q->param('ui');
	my $menu_pot ;
	my $template ;
	my $onload;
	my $gumbek;	
	my $counter=0;
	my $datum;
	my $ime;
	my $komentar;
	my $priimek;
	my $primarni;
	my $lepiDatum;	
	my $dbh;
	my $sql;
	my $sth;
	my $res;
	my $dbh2;
	my $sql2;
	my $sth2;
	my $res2;
	my @loop;
	my @loop3;
	
	my $cookie = $ENV{'HTTP_COOKIE'};
	$cookie = substr ($cookie, 3);
	my @arr = split(",", $cookie);
	$cookie = $arr[0];

	if($id_klic>0){		
		$gumbek="spremeni";
	}
	else{		
		$gumbek="dodaj";
	}
	
	if($unique_id){
		$id_donor = $unique_id;
	}
		
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {	
		$sql = "SELECT first_name, scnd_name FROM sfr_donor WHERE id_donor=?";
		#, sfr_donor_phone
	    #, phone, phone_num, default_phone
		$sth = $dbh->prepare($sql);
		$sth->execute($id_donor);
		
		if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
		{
			$ime = $res->{'first_name'};
			$priimek = $res->{'scnd_name'};
		}
		if($unique_id){
			$sql = "SELECT * FROM uporabniki_tmp WHERE id=? AND tmp_source='klici_don'";
		}
		else{
			$sql = "SELECT date, comment FROM sfr_donor_call WHERE id_vrstice=?";
		}
		#, sfr_donor_phone
	    #, phone, phone_num, default_phone
		$sth = $dbh->prepare($sql);
		$sth->execute($id_klic);
		
		if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
		{
			if($unique_id){
				$datum = $res->{'tmp_date1'};
				$komentar = $res->{'tmp_field1'};				
			}
			else{
				$datum = $res->{'date'};
				$komentar = $res->{'comment'};
			}
		}
		if($datum>0){
		$lepiDatum=substr($datum, 8,2)."/".substr($datum, 5,2)."/".substr($datum, 0,4);
		$datum=$lepiDatum;
		}
	}
	
	$dbh2 = DntFunkcije->connectDB;
	if($dbh2){
		if($unique_id){
			$sql = "SELECT * FROM uporabniki_tmp WHERE id_unique=? AND id_user='$cookie' AND tmp_source='telefoni_don'";		
		}
		else{
			$sql = "SELECT phone_num, id_vrstice, default_phone FROM sfr_donor_phone WHERE id_donor=?";	
		}
		$sth2 = $dbh2->prepare($sql);
		$sth2->execute($id_donor);	
		
		while($res2 = $sth2->fetchrow_hashref){
			if($unique_id){
				if($res2->{'tmp_toggle'} == 1){
					$primarni = "<option value=".$res2->{'id'}.">*".$res2->{'tmp_field1'}."</option>";
				}
				else{
					my %row = (telefon => $res2->{'tmp_field1'},
							   telefonId => $res2->{'id'},
							   );
				push(@loop, \%row);	
				}
			}
			else{
				if($res2->{'default_phone'} == 1){
					$primarni = "<option value=".$res2->{'id_vrstice'}.">*".$res2->{'phone_num'}."</option>";
				}
				else{
					my %row = (telefon => $res2->{'phone_num'},
							   telefonId => $res2->{'id_vrstice'},
							   );
				push(@loop, \%row);				
				}
			
			}
		}
		if($unique_id){
			
			$sql = "SELECT * FROM uporabniki_tmp WHERE ".
					"id_unique=? AND id_user='$cookie' AND tmp_source='klici_don'".
					" ORDER by id DESC";
		}
		else{
			$sql = "SELECT sfr_donor_call.id_vrstice, date, comment, phone_num ".
				   "FROM sfr_donor_call, sfr_donor_phone ".
				   "WHERE sfr_donor_call.id_donor=?	 ".
				   "AND id_phone=sfr_donor_phone.id_vrstice  ".
				   "ORDER BY date";			
		}
		$sth2 = $dbh2->prepare($sql);
		$sth2->execute($id_donor);
			
		while($res2 = $sth2->fetchrow_hashref){
			if($unique_id){
				$lepiDatum=substr($res2->{'tmp_date1'}, 8,2)."/".substr($res2->{'tmp_date1'}, 5,2).
						   "/".substr($res2->{'tmp_date1'}, 0,4);
				my %row = (datum => $lepiDatum,
						   komentar => $res2->{'tmp_field1'},
						   klicId => $res2->{'id'},
						   edb_id => $id_donor,
						   ui => "&ui=$id_donor",
						   );
				push(@loop3, \%row);				
			}
			else{
				$lepiDatum=substr($res2->{'date'}, 8,2)."/".substr($res2->{'date'}, 5,2).
						   "/".substr($res2->{'date'}, 0,4);
				my %row = (datum => $lepiDatum,
						   komentar => $res2->{'comment'},
						   klicId => $res2->{'id_vrstice'},
						   telefon => $res2->{'phone_num'},
						   edb_id => $id_donor,				   
						   );
				push(@loop3, \%row);
			}
		}
	}
	if ($id_klic>0){
		
		
		$onload="onload=\"Uredi(); Uredi2()\"";
	}
	else {
		$onload="onload=\"Uredi();\"";
	}
	my $ui_brisi="";
	if($unique_id){
		$ui_brisi="_tmp";
	}
	$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
		$template = $self->load_tmpl(	    
							  'DntDonatorKlici.tmpl',
					  cache => 1,
					 );
	$template->param(
		IME_DOKUMENTA => "Dodaj klic",
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		edb_id => $id_donor,
		edb_klicId => $id_klic,
		edb_ime => DntFunkcije::trim($ime),
		edb_priimek => DntFunkcije::trim($priimek),				 
		edb_primarni => $primarni,
		edb_datum => $datum,
		edb_komentar => $komentar,
		edb_loop => \@loop,
		klic_loop3 => \@loop3,
		edb_onload => $onload,
		edb_gumbek => $gumbek,
		ui => $unique_id,
		ui_brisi => $ui_brisi
	);

	$html_output = $template->output; #.$tabelica;
	return $html_output;
	
    
	
}

sub SfrDonatorji(){
	my $self = shift;
	my $q = $self->query();
	my $redirect_url= '/cgi-bin/DntDonatorji.pl?seja=';
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	$redirect_url .= $seja; # .'&uporabnik='.$uporabnik;
	#
	#$session->param();
	#return 'klik na register'.($session->param('uporabnik'));
	#
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
}

sub SfrSeznamDonatorjev(){
	my $self = shift;
	my $q = $self->query();
	
	return 'Seznamcek';
}

sub IzberiPosto(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $st = $q->param('st');
	my $insertId= $q->param('insert');
	my $pogodba= $q->param('pogodba') || 0;
	my $html_output;
	my $menu_pot;
	my $template;
	my $imeDokumenta;
	my @loop;
	my $vrstica=0;
	my $dbh;
	my $sql;
	my $sth;
	my $res;


	$dbh = DntFunkcije->connectDB;
	
	if($pogodba>0){
		if ($dbh) {
			$sql = "SELECT * FROM sheets WHERE serial_root=? AND ".
				   "id_agreement is null ORDER BY serial_id ASC";
			$sth = $dbh->prepare($sql);			
			$sth->execute($pogodba);
			
			while($res = $sth->fetchrow_hashref){				
				my %row = (postnaSt => $res->{'serial_id'},
						   posta => "",
						   insertId => $insertId,
						   );
				push(@loop, \%row);
			}
		
		}
		$imeDokumenta="Seznam pogodb";
	}
	else{
		$imeDokumenta="Seznam post";
		if ($dbh) {		
			$sql = "SELECT * FROM sfr_post WHERE CAST(id_post AS char) ilike '$st%' or ".
					"name_post ilike '$st%' ORDER BY id_post";
			$sth = $dbh->prepare($sql);			
			$sth->execute();
			
			while($res = $sth->fetchrow_hashref){
					
				my %row = (postnaSt => $res->{'id_post'},
						   posta => DntFunkcije::trim($res->{'name_post'}),
						   insertId => $insertId,
						   vrstica => $vrstica++,
						   );
				push(@loop, \%row);
			}
		}
	}
	$menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek");
	$template = $self->load_tmpl(	    
						  'posta.tmpl',
				  cache => 1,
				 );
	$template->param(
		IME_DOKUMENTA => $imeDokumenta,
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		edb_loop => \@loop,
	);

	
	$html_output = $template->output; #.$tabelica;
	return $html_output;
}
sub IzberiDavcno(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $st = $q->param('st');
	my $insertId= $q->param('insert');
	my $pogodba= $q->param('pogodba');
	my $html_output;
	my $menu_pot;
	my $template;
	my $imeDokumenta;
	my @loop;
	my $vrstica=1;
	my $dbh;
	my $sql;
	my $sth;
	my $res;


	$dbh = DntFunkcije->connectDB;
	

	if ($dbh) {
		$sql = "SELECT * FROM davcni_zavezanci WHERE davcna_st ILIKE '$st%' AND vrsta_zavezanca != 'F' ".
			   " ORDER BY id_dz ASC".
			   " LIMIT 50";
		$sth = $dbh->prepare($sql);
		#return $sql;
		$sth->execute();
		
		while($res = $sth->fetchrow_hashref){				
			my %row = (davcna => $res->{'davcna_st'},
					   ddv => $res->{'reg_za_ddv'},
					   #maticna => $res->{'maticna_st'},
					   #dejavnost => $res->{'sifra_dejavnosti'},
					   podjetje => DntFunkcije::trim($res->{'ime'}),
					   naslov => DntFunkcije::trim($res->{'naslov'}),
					   insertId => $insertId,
					   vrstica => $vrstica++,
					   );
			push(@loop, \%row);
		}
	
	}
	$imeDokumenta="Seznam davcnih zavezancev";
	

	$menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek");
	$template = $self->load_tmpl(	    
						  'davcni.tmpl',
				  cache => 1,
				 );
	$template->param(
		IME_DOKUMENTA => $imeDokumenta,
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		edb_loop => \@loop,
	);

	
	$html_output = $template->output; #.$tabelica;
	return $html_output;
}
sub check{
    my $self = shift;
    my $q = $self->query();
    my $sth;
    
    my $dbh = DntFunkcije->connectDB;

	if ($dbh) {
		my $sql = "SELECT * FROM sfr_donor WHERE tax_number = ? ";
		$sth = $dbh->prepare($sql);
		$sth->execute($q->param('davcna'));
        if($sth->rows > 0){
            return $sth->fetchrow_hashref->{'id_donor'};
        }
	
	}
    return "";
}


#če uporabnik ni prijavljen:
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'Donatorji';
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
