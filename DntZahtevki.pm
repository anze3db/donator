package DntZahtevki;
use base 'CGI::Application';
#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use strict;
use DBI;


#use HTML::Template;
#use CGI::Session;
#use Data::Dumper;

use Digest::MD5 qw(md5_hex);
require 'DntFunkcije.pm';
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
        'seznam' => 'ZahtevkiSeznam',
		'izpisi' => 'ZahtevkiSeznam',
		'poslji' => 'ZahtevkiPoslji',
		'Shrani' => 'ZahtevkiShrani',
		'zbrisi' => 'ZahtevkiZbrisi',
		'Preusmeri' => 'Preusmeri',
		'login' => 'Login',
		'error' => 'Error'
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub ZahtevkiSeznam{
	
    my $self = shift;
    my $q = $self->query();
	my $as = undef;
	my ($curr_date, $curr_time) = DntFunkcije::si_date("");
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	
	my $print_date;
	
	my $pro = $q->param('project');

    # Fill in some parameters	
    my $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek");
	my $template = $self->load_tmpl(	    
		'DntZahtevki.tmpl',
		 cache => 0,
   );
	my $check  = 0;
	my $day = substr($curr_date, 0, 2);
	my $month = substr($curr_date, 3, 2);
	my $year = substr($curr_date, 6, 4);
	my $project = "<select name = 'project'>";
	$dbh = DntFunkcije::connectDB();
	if($dbh){
		$sql = "SELECT * FROM sfr_project";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		while ($res = $sth->fetchrow_hashref) {
			$project .= "<option value='$res->{id_project}'>".DntFunkcije::trim($res->{name_project})."</option>";

		}
	}
	$project .= "</select>";

	
	my $select = "<label for='datumi'>Izpisi za: </label><select name = 'datumi' >";
	my @dates;
	my @labels;
	my @itemIds;
	my $currDay;

	if($day < 2 && $day > 28){ 
		if($day > 28){
			$month++;
			if($month == 13){
				$month = 1;
				$year++;
			}
			$currDay = '08';
		}
	}
	elsif($day < 12){
		
		$currDay = '18';
	}
	elsif($day < 22){		

		$currDay = '28';
	}

	my $date = '';
	#DAY:
	$date = "<select name = 'day'><option>08</option><option>18</option><option>28</option></select>";
	#MONTH:
	$date .= " - <select name = 'month'> ";
	for(my $i = 1; $i <= 12; $i++){
		$date .= "<option";
		if($i == $month){
			$date .= " selected='selected'";
		}
		
		$date  .= '>'.sprintf("%02d", $i) ."</option>";
	}
	$date .= "</select>";
	#YEAR:
	$date .= " - <select name = 'year'> ";
	for(my $i = $year-2; $i <= $year+3; $i++){
		$date .= "<option";
		if($i == $year){
			$date .= " selected='selected'";
		}
		
		$date  .= '>'.sprintf("%02d", $i) ."</option>";
	}
	$date .= "</select>";
	#$date .= "-".$q->popup_menu('year', [$year-1, $year, $year+1, $year+2], $year);

	my $form = $q->start_form(-name=>"myForm2");
	$form .= $q->hidden(-name => "rm", -value => "izpisi");
	$form .= "<label for='date'>Danasnji datum: </label>";
	$form .= $q->textfield(-name=>"date", -label=>"datum", -readonly=>"true", -value=>$curr_date);
	$form .= "<br /><br />".$date." za projekt ".$project."<br /><br />";
	$form .= $q->submit(-name => "izpisi", -value=>'Izpisi');
	$form .= $q->end_form();
    
	
	my $izpis;
	
	if(defined $q->param('year') && defined $q->param('month') && defined $q->param('day')){
		
		
		$print_date = $q->param('year')."-".$q->param('month')."-".$q->param('day');
		#$q->delete('rm');
		$izpis = "<strong>Izpis za $print_date:</strong>";
		$izpis .= $q->start_form();
		$izpis .= $q->hidden(-name=>'rm', -value=>'poslji');

		my $table;		
		$table = '<table border="1px">';
		$table .= '<tr>';
		my @table_header = (
						  "izbira",
						  "vrsta zapisa",
						  "id zapisa",
						  "oznaka knjizenja",
						  "datum",
						  "znesek",
						  "oznaka valute",
						  "racun komitenta",
						  "referencna stevilka",
						  "namen",
						  "sifra nakazila",
						  "poravnalni racun",
						  "enota",
						  "vrsta posla",
						  "partija",
						  "sifra prejemnika",
						  "vrsta informacije",
						  "status",
						  "sifra konta",
						  "frekvenca",
						  "zap. st. DB upnika",
						  "zap. st. DB dolznika",
						  "operater",
					      
		);
		foreach(@table_header){
			
			$table .= '<th>'.$_.'</th>';
		}
		$table .= '</tr>';
		#priprava podatkov:
		$dbh = DntFunkcije::connectDB();
		if($dbh){
			#TODO stara_pogodba?
			
			$sql = "SELECT p.id_vrstica, p.date_activate, p.id_project, a.stara_pogodba, a.id_agreement  FROM agreement_pay_installment as p, sfr_agreement as a ".
			"WHERE p.id_agreement = a.id_agreement AND p.date_activate = ? AND p.pay_type='04' ".
			"ORDER BY a.sifra_banke";
			
			$sth = $dbh->prepare($sql);
	        $sth->execute($print_date);
			my $stTransakcij = 0;
			#return $pro;
	        while ($res = $sth->fetchrow_hashref) {
				my $project = $res->{id_project} || 0;
				my $stara_pogodba = $res->{stara_pogodba} || 0;
				if($stara_pogodba == 1){
					
					$project = 1;
				}
				#return $project . " " . $pro . " " . $res->{stara_pogodba} . $res->{id_agreement};
				if($project ne $pro){
					next;
				}
				$stTransakcij++;
				$check = 1;
				my %item;
				%item = getItems($res->{'id_vrstica'});				
				
				push(@itemIds, $res->{'id_vrstica'});
				my $idZapisa = substr($item{'idZapisa'}, 0, 8)." ".substr($item{'idZapisa'}, 8, 2).".".
									substr($item{'idZapisa'}, 10, 2).".".substr($item{'idZapisa'}, 12, 2)." ".
									substr($item{'idZapisa'}, 14, 2)." ".substr($item{'idZapisa'}, 16, 2)." ".
									substr($item{'idZapisa'}, 18, 6);
				$table .= '<tr>';
				my $url = $ENV{'QUERY_STRING'};
				my @table_contents = (
								  $q->checkbox(-name=>'items', -value=>$res->{'id_vrstica'}, -checked=>'true', -label=>''),
								  "04",
								  '<div title="'.$item{'idZapisa'}.'style=>"width:220px;">'.$idZapisa." ".sprintf("%05d", $stTransakcij).'</div>',
								  "0",
								  DntFunkcije::sl_date($res->{'date_activate'}),
								  $item{'znesek'},
								  "978",
								  $item{'racunKomitenta'},
								  $q->a({-href=>'DntPogodbe.cgi?rm=uredi_pogodbo&id_agreement='.
												 DntFunkcije::trim($item{'referencnaSt'}).
												 "&uredi=1&nazaj=zahtevki&return=DntZahtevki.cgi?rm=izpisi_amp_date=". $q->param('date') .
												 "_amp_year=".$q->param('year')."_amp_month=".$q->param('month')."_amp_day=".$q->param('day') .
												 "_amp_izpisi=Izpisi_amp_project=" . $q->param('project'),},
											$item{'referencnaSt'}),
								  $item{'namen'},
								  $item{'sifraNakazila'},
								  $item{'poravnalniRacun'},
								  $item{'enota'},
								  $item{'vrstaPosla'},
								  $item{'partija'},
								  $item{'sifraPrejemnika'},
								  $item{'vrstaInformacije'},
								  $item{'status'},
								  $item{'sifraKonta'},
								  $item{'frekvenca'},
								  $item{'zapStUpn'},
								  $item{'zapStDol'},
								  $item{'operater'},
							
								  );
				foreach(@table_contents){
					$table .= '<td>'.$_.'</td>';
				}
				$table .= '</tr>'					
			}
			
		}
		$table .= $q->end_table();
		$izpis .= $table;
		$izpis .= $q->textarea(-name=>'field_name',
			-value=>generate(\@itemIds),
			-readonly=>'true',
			-cols => '194',
			-rows => '10');
		$izpis .= "<br />";
		my $dn_date = $q->param('date');
		$dn_date =~ s/-//g;
		$dn_date = substr($dn_date, 0, 4) . substr($dn_date, 6, 2);
		$izpis .= "Ime datoteke: ";
		$izpis .= $q->textfield(-name=>'filename',
								-value=>'DB_'.$dn_date.'001.txt',);
		$izpis .= $q->submit(-name=>'poslji', -value=>'Poslji');
		$izpis .= $q->end_form();
		if($check == 0){
			$izpis = "<b>Za izbrani datum in projekt ni zahtevkov!</b>";
		
		}
	}
	#return getItems($itemIds[0]);
	
	$template->param(
		IME_DOKUMENTA => 'Seznam zahtevkov',
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		MENU => DntFunkcije::BuildMenu(),
		form => $form,
		izpis => $izpis,
	);

	#Ce so se parametri za poizvedbo izpise rezultat

    my $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}
sub numOfSentPackeges{
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	my $pp = 1;
	(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) =
					localtime();
	$year += 1900;
	$mon += 1;
	$mon = sprintf('%02d', $mon);
	$mday = sprintf('%02d', $mday);
	$hour = sprintf('%02d', $hour);
	
	$dbh = DntFunkcije::connectDB();
	if($dbh){
		$sql = "SELECT count(id_datoteke) as num_rows FROM datoteke_poslane WHERE DATE(datum) = ?";
		$sth = $dbh->prepare($sql);
	    $sth->execute($year."-".$mon."-".$mday);
		if ($res = $sth->fetchrow_hashref) {
			$pp = $res->{'num_rows'}+1;
			
		}
	}
	#return sprintf("%02d", $pp);
	
	return sprintf("%02d", 1);
	

}
sub generate{

	my ($itemsRef) = @_;
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
	my %item;
	my $it="";
	my $stTransakcij = 0;
	my $stTrIzpis;
	my $znesek = 0.0;

	my $datum = $year.$mon.$mday;
	my $delni_vsota = 0;
	my $delni_sifra;
	my $delni_st = 0;
	
	my $s1 = "04";
	my $pp = numOfSentPackeges;
	
	my $prazno = sprintf('%152s', "");
	my $delni = 0;
	
	for (my $i = 0; $i<@$itemsRef; $i++){
		my $item = $$itemsRef[$i];
		if(%item = getItems($item)){
			
			my $trrBanke = $item{'trrBanke'};
			#delni zapisi:
			#if(defined $delni_sifra && $delni_sifra ne $item{'sifraBanke'}){
			#	$delni = 1;	
			#	$delni_vsota = sprintf('%015d', $delni_vsota);
			#	$delni_st = sprintf('%06d', $delni_st);
			#	$prazno = sprintf('% 49s', "");
			#	$it .= "94".$stPaketa.$delni_st."0".$datum.$delni_vsota."978".$item{'racunKomitenta'}.
			#			$item{'referencnaSt'}.$item{'namen'}.$item{'sifraNakazila'}.$item{'poravnalniRacun'}.
			#			$prazno."\n";	
			#	$delni_vsota = 0;
			#	$delni_st = 0;
			#	$delni_sifra = $item{'sifraBanke'};
			#}
			#else{
			#	$delni_sifra = $item{'sifraBanke'};
			#}
			#$delni_vsota += $item{'znesek'};
			#$delni_st++;
			$vsota += $item{'znesek'};
			$stTransakcij++;
			$davcnaSt = substr($item{'idZapisa'}, 0, 8);	
			my $stTrans = sprintf("%06d", $stTransakcij);
			
			$it .= "04".$item{'idZapisa'}.$stTrans."0".$item{'datumValute'}.$item{'znesek'}."978".$item{'racunKomitenta'}.
					 $item{'referencnaSt'}.$item{'namen'}.$item{'sifraNakazila'}.$item{'poravnalniRacun'}.$item{'enota'}.
					 $item{'vrstaPosla'}.$item{'partija'}.$item{'sifraPrejemnika'}.$item{'vrstaInformacije'}.$item{'status'}.
					 $item{'sifraKonta'}.$item{'frekvenca'}.$item{'zapStUpn'}.$item{'zapStDol'}.$item{'operater'}."\r\n";
		}	
	}
	
	my $stPaketa = $davcnaSt.$shortYear.$mon.$mday.$s1.$pp;
	#if($delni == 1){
	#	$delni_vsota = sprintf('%015d', $delni_vsota);
	#	$delni_st = sprintf('%06d', $delni_st);
	#	$prazno = sprintf('% 49s', "");
	#	$it .= "94".$stPaketa.$delni_st."0".$datum.$delni_vsota."978".$item{'racunKomitenta'}.
	#			$item{'referencnaSt'}.$item{'namen'}.$item{'sifraNakazila'}.$item{'poravnalniRacun'}.
	#			$prazno."\n";	
	#}
	$prazno = sprintf('%152s', "");
	$file = "90".$stPaketa."0000000".$year.$mon.$mday.$hour.$min.$sec.$prazno."\r\n";
	$file .= $it;
	$vsota = sprintf('%015d', $vsota);
	$znesek = sprintf('%015d',$znesek);
	$prazno = sprintf('%140s', "");
	
	$stTrIzpis = sprintf('%06d', $stTransakcij);
	$file .= "99".$stPaketa.$stTrIzpis."0".$datum.$vsota."978".$prazno."\r\n";
}
sub ZahtevkiPoslji(){
	my $self = shift;
    my $q = $self->query();
	my @items = $q->param('items');
	my $davcnaSt = $q->param('davcna');
	my $file = $q->param('filename');
	my $content = generate(\@items);
	
	if(my $dbh = DntFunkcije->connectDB){
	my $sql = "INSERT INTO datoteke_poslane (datum, stevilka, filename, content)
							VALUES (CURRENT_TIMESTAMP, ?, ?, ?)";
	my $sth = $dbh->prepare($sql);
	
	$sth->execute($davcnaSt, $file, $content);
	}

    $q->header_props("Content-disposition: attachment; filename=$file\n\n");	
	#print "Content-disposition: attachment; filename=$file\n\n";
	return $content;
	
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
		my $davcnaStProjekta = "";
		my $trrBanke = "";
		my $datumValute = "";
		my $sifraBanke;


		my $dbh;
		my $sql;
		my $res;
		my $sth;
		my $res2;
		my $sth2;
		
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
			$sql = "SELECT p.*, a.bank_account2, a.frequency, ".
				   "a.zap_st_dolznika, a.sifra_banke, a.stara_pogodba ".
				   "FROM agreement_pay_installment as p, sfr_agreement as a ".
				   "WHERE p.id_vrstica= ? AND a.id_agreement = p.id_agreement ".
				   "ORDER BY a.sifra_banke";
			$sth = $dbh->prepare($sql);
	        $sth->execute($item);
	        if($res = $sth->fetchrow_hashref) {
				
				my $id_project = $res->{'id_project'} || 0;
				my $stara_pogodba = $res->{'stara_pogodba'} || 0;
				if($stara_pogodba == 1){
					$id_project = 1;
				}

				$sql = "SELECT * FROM sfr_project as p, sfr_project_trr as trr WHERE p.id_project = ? AND trr.id_project = ?";
				my $sth2 = $dbh->prepare($sql);
				$sth2->execute($id_project, $id_project);
				if($res2 = $sth2->fetchrow_hashref){
					
					$davcnaStProjekta = $res2->{'tax_number'};
					$davcnaStProjekta = sprintf('%08d', $davcnaStProjekta);
					$racunKomitenta = DntFunkcije::trim($res2->{'id_trr'});
					$racunKomitenta =~ s/-//g;
					$namen = DntFunkcije::trim($res2->{'opis_storitve'});
					$namen = sprintf('%-35s', $namen);					
					$zapStUpn = $res2->{'zap_st_upnika'} || 0;
					$zapStUpn = sprintf('%05d', $zapStUpn);
				}
				$referencnaSt = $res->{'id_agreement'};
				$referencnaSt = sprintf('%-20s', $referencnaSt);
				
				
				
				
				$sifraNakazila = "000";
				
				#$racunKomitenta = $res->{''};
				$racunKomitenta = sprintf('%-18s', $racunKomitenta);
				
				$poravnalniRacun = $res->{'bank_account2'};
				$poravnalniRacun =~ s/ //g;
				$poravnalniRacun= sprintf('%-15s', $poravnalniRacun);
				
				$enota = sprintf('%03d', $enota);
				
				$vrstaPosla = sprintf('%02d', $vrstaPosla);
			
				$partija = sprintf('%010d', $partija);
				
				$sifraPrejemnika = sprintf('%-5s', $sifraPrejemnika);
				
				$vrstaInformacije = 1;
				$vrstaInformacije = sprintf('%02d', $vrstaInformacije);
				
				$status = 1;
				$status= sprintf('%02d', $status);
				
				$sifraKonta = sprintf('%03d', $sifraKonta);
				
				$frekvenca = $res->{'frequency'};
				$frekvenca = sprintf('%02d', $frekvenca);
				
				
				
				$zapStDol = $res->{'zap_st_dolznika'};
				if(length(DntFunkcije::trim($zapStDol)) != 10){
				    $zapStDol = sprintf('%010d', $zapStDol);
				}
				
				$operater = sprintf('%-5s', $operater);
				
				$davcnaSt = DntFunkcije::trim($res->{'tax_number'});
				$znesek = $res->{'amount'};
				$znesek = sprintf('%013d%02d', int($znesek), substr($znesek, -2, 2));
				
				$sifraBanke = DntFunkcije::trim($res->{'sifra_banke'});
				
				$datumValute = $res->{'date_activate'};
				$datumValute =~ s/-//g;
				$datumValute = substr($datumValute, 0, 8);
				
			}
			
			my $shortYear = substr($year, 2, 2);
			my $s1 = "04";
			my $pp = numOfSentPackeges;
			$idZapisa = $davcnaStProjekta.$shortYear.$mon.$mday.$s1.$pp;
			
			#TRR BANKE:
			
			$sql = "SELECT * FROM sfr_bank WHERE sifra_banke ILIKE '$sifraBanke%'";
			$sth = $dbh->prepare($sql);
			$sth->execute();
			if($res = $sth->fetchrow_hashref){
				$trrBanke = $res->{'bank_tn'};
			}

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
					'trrBanke' => $trrBanke,
					'sifraBanke' => $sifraBanke,
					'datumValute' => $datumValute,
					);
		}
}
1;    # Perl requires this at the end of all modules
