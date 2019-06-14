package DntIzvoziObroke;
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
	#if ($str eq 'generiraj'){
	#	$nivo = 'w';
	#}
	
    my $user = DntFunkcije::AuthenticateSession(23, $nivo);
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
        'zacetek' => 'IzvoziObrokeZacetek',
		'Prikazi' => 'IzvoziObrokePrikazi',
		'login' => 'Login',
		'error' => 'Error'
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub IzvoziObrokeZacetek{

    my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');
	my $html_output;
	my $ime= $q->param('edb_ime');
	my @loop;
	my $menu_pot;
	my $triPike;
	my $poKorenuIme= $q->param('po_korenu_ime');
	my $st= $q->param('edb_st');
	my $uporabnik= $q->param('uporabnik');
    my $template ;
	my $id_IzvoziObroke= $q->param('edb_id');
	my $projekt= $q->param('edb_projekt');
	my $leto= $q->param('edb_leto');
	my $dogodek= $q->param('edb_dogodek');
	my $komercialist= $q->param('edb_komercialist');
	my $samoKomercialist= $q->param('komercialist');
	my $bremenitev= $q->param('bremenitev') || -1;
	my $selected;
	my $zapadlost;
	
	my $poloznica;
	my $racun;
	
	my @donatorji;
	my @pogodbe;
	my @obroki;
	
	my @donatorjiIzbrani;
	my @pogodbeIzbrane;
	my @obrokiIzbrani;
	
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
	(my $sec,my $min,my $hour,my $mday,
	 my $mon,my $year,my $wday,my $yday,my $isdst) =
    localtime(time);
	$mon+=1;
	if($mon<10){
		$mon="0$mon";
	}
	if($mday<10){
		$mday="0$mday";
	}
	if(defined $bremenitev && $bremenitev == 3){
		$poloznica="selected=true";
		$racun = "";
	}
	elsif(defined $bremenitev && $bremenitev == 4){
		$racun = "selected = true";
		$poloznica="";
	}	
	$year+=1900;
	$zapadlost="$mday/$mon/$year";
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntIzvoziObroke.tmpl',
			      cache => 1,
			     );
    $template->param(
		#MENU_POT => $menu_pot,
	   IME_DOKUMENTA => 'Izvozi obroke',
	   POMOC => "<input type='button' value='?' ".
	   "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
	   poloznica => $poloznica,
	   racun => $racun
	);
	#Ce so se parametri za poizvedbo izpise rezultat

	my $dbh;
	my $res;
	my $sql;
	my $sth;
	my $zbrisi;
	my $hid_sort = $q->param("hid_sort");
	$dbh = DntFunkcije->connectDB;
	#povrne shranjeno iskanje
	if ($dbh) {
		$sql = "SELECT * FROM isci WHERE tip='$bremenitev'";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		my @vsi;		
		while($res = $sth->fetchrow_hashref){
			my $para = $res->{param};
			@vsi = split("-", $para);
			#ustvarijo se seznami izbranih
			@donatorjiIzbrani=split(",", $vsi[0]);
			@pogodbeIzbrane=split(",", $vsi[1]);
			@obrokiIzbrani=split(",", $vsi[2]);
			
		}
		#izpis in oznacevanje donatorjev
		$sql = "SELECT * FROM sfr_donor LIMIT 1";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		my $i=0;
		while ($sth->{NAME}[$i]) {
			#izpise vse stolpce
			my %row2 = (	
				column => $sth->{NAME}[$i],
				column_slo => DntFunkcije::SloColumns($sth->{NAME}[$i]),
				selected => "true"
			);
			#ce je stolpec shranjen v izbranih, se ga oznaci
			foreach(@donatorjiIzbrani){
				if($_ eq $sth->{NAME}[$i]){
					$row2{selected}= "selected=true";
				}
			}
			push(@donatorji, \%row2);
			$i++;
		}
		#izpis in oznacevanje pogodb
		$sql = "SELECT * FROM sfr_agreement LIMIT 1";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$i=0;
		while ($sth->{NAME}[$i]) {
			my %row2 = (	
				column => $sth->{NAME}[$i],
				column_slo => DntFunkcije::SloColumns($sth->{NAME}[$i]),
			);
			#ce je stolpec shranjen v izbranih, se ga oznaci
			foreach(@pogodbeIzbrane){
				if($_ eq $sth->{NAME}[$i]){
					$row2{selected}= "selected=true";
				}
			}
			push(@pogodbe, \%row2);
			$i++;
		}
		#izpis in oznacevanje obrokov
		$sql = "SELECT * FROM agreement_pay_installment LIMIT 1";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$i=0;
		while ($sth->{NAME}[$i]) {
			my %row2 = (	
				column => $sth->{NAME}[$i],
				column_slo => DntFunkcije::SloColumns($sth->{NAME}[$i]),
			);
			#ce je stolpec shranjen v izbranih, se ga oznaci
			foreach(@obrokiIzbrani){
				if($_ eq $sth->{NAME}[$i]){
					$row2{selected}= "selected=true";
				}
			}
			push(@obroki, \%row2);
			$i++;
		}
		$sql = "SELECT * FROM sfr_pay_type ORDER BY id_pay_type";			
	
		$sth = $dbh->prepare($sql);
		$sth->execute();
				
		while($res = $sth->fetchrow_hashref){
			
			my %row = (tip => DntFunkcije::trim($res->{'debit_type'}),
					   ime => DntFunkcije::trim($res->{'name_pay_type'}),
					   selected => $selected,
				   
					   );
			push(@loop5, \%row);
			
		}
		#generira select list leta
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
		#generira select list projekti:
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
		#generira select list dogodkek:		
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
		$template->param(
			edb_loop6 => \@loop6,
			edb_loop7 => \@loop7,
			edb_loop8 => \@loop8,
			donatorji => \@donatorji,
			pogodbe => \@pogodbe,
			obroki => \@obroki,
			#zapadlost => $zapadlost
		);
	}
	else{
		return 'Povezava do baze ni uspela';
	}
                
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;    
}

sub IzvoziObrokePrikazi{
	
	my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');	
	my $html_output ;
	my $menu_pot;
	my $uporabnik= $q->param('uporabnik');
    my $template;
	my $projekt= $q->param('edb_projekt');
	my $leto= $q->param('edb_leto');
	my $dogodek= $q->param('edb_dogodek');
	my $bremenitev= $q->param('edb_bremenitev');
	my $zapadlost= $q->param('zapadlost');
	my $datum= $q->param('uporabi_datum');
	my $datum_now= localtime;
	my $stv=0;
	my $a_id_agreement=0;
	my $a_select;
	my $pay_type="";
	my $count_rows=0;
	
	my $shraniPogled;
	
	my @donatorji= $q->param('donatorji');
	my @pogodbe= $q->param('pogodbe');
	my @obroki= $q->param('obroki');
	
	my @naslovi;
	my @vsebina;
	
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	if($zapadlost){
		$zapadlost=substr($zapadlost, 6, 4)."-".substr($zapadlost, 3, 2)."-".
				   substr($zapadlost, 0, 2);
	}
	#nastavi se nacin placila
	if($bremenitev == 4){
		$pay_type='A1';
	}
	elsif($bremenitev == 3){
		$pay_type='01';
	}
	$a_select = "";				
	#dodajo se pogoji iz select listov (Projekti, leto, dogodek, nacin placila)	
	if($projekt){
		$a_select.=" AND a.id_project = $projekt";
	}
	if($dogodek){
		$a_select.=" AND a.id_event ILIKE '$dogodek'";
	}
	if($leto){
		$a_select.=" AND a.id_agreement ILIKE '_$leto%'";
	}
	if($bremenitev){
		$a_select.=" AND b.debit_type = '$pay_type'";
	}
	#generiranje seznama za izvoz:
	$dbh = DntFunkcije->connectDB;
	my $csv;
	my $index;
	if ($dbh) {
		
		my %debit_hash = DntFunkcije::debitNames($dbh);
		
		$sql = "SELECT DISTINCT a.id_agreement, b.id_vrstica";
		
		#socasno se generira sql stavek in stavek za shranjevanje:
		foreach (@donatorji){
			
			$sql.= ", c.$_";
			$shraniPogled.="$_,";
		}
		$shraniPogled.="-";
		foreach (@pogodbe){
			if ($_ eq "id_agreement"){
				$a_id_agreement=1;
			}
			else{
				if($_ eq "amount"){
					$sql .= ", a.$_ as znesek";
				}
				else{
					$sql.= ", a.$_";
				}
			}
			
			$shraniPogled.="$_,";
		}
		$shraniPogled.="-";
		foreach (@obroki){
			$sql.= ", b.$_";
			$shraniPogled.="$_,";

		}
		#izberejo se tabele sfr_agreement, agreement_pay_installment, sfr_donor
		$sql.=" FROM sfr_agreement AS a, agreement_pay_installment AS b".
			  ", sfr_donor AS c";
		#dodajo se povezave med zgornjimi tabelami (da se vrstice ne podvajajo)
		$sql.=" WHERE a.id_agreement = b.id_agreement AND".
			  " a.id_donor = c.id_donor ".
			  " AND b.storno ISNULL AND (b.amount_payed = 0.00 OR".
			  " b.amount_payed ISNULL OR b.debit_type = 'A1') AND b.amount>0 AND b.date_izpis ISNULL";
		if($zapadlost){
			$sql.=" AND b.date_activate = '$zapadlost' ";
		}
		#na koncu se doda še pogoji iz select lista:
		$sql.=$a_select;
		if($a_id_agreement == 1){
		    $sql .= "  ORDER BY a.id_agreement ";
		}
		$sql .= " LIMIT 1200 ";
		$sth = $dbh->prepare($sql);
		#return $sql;
		$sth->execute();
		my $i=0;
		#naslovi stolpcev se zapišejo v @naslovi
		while (defined $sth->{NAME}[$i]){
			if($sth->{NAME}[$i] eq "id_agreement"){
				if($a_id_agreement != 0){
					my %row = ('naslov'=>DntFunkcije::SloColumns($sth->{NAME}[$i]));			
					push (@naslovi, \%row);
					$csv .= DntFunkcije::SloColumns($sth->{NAME}[$i]).";";
				}
			}
			elsif($sth->{NAME}[$i] eq "id_vrstica"){}
			else{
				$csv .= DntFunkcije::SloColumns($sth->{NAME}[$i]).";";
				my %row = ('naslov'=>DntFunkcije::SloColumns($sth->{NAME}[$i]));			
				push (@naslovi, \%row);
			}
			$i++;
		}
		$csv = substr($csv, 0, -1)."\n";
		#vrstice pa v @vsebina - 2d tabela
		while ($res = $sth->fetchrow_hashref) {
			$i=0;
			my @loop;
			my $id_agreement;
			while ($sth->{NAME}[$i]){
				
				if($sth->{NAME}[$i] eq "id_agreement"){
					if($a_id_agreement != 0){
						$csv .= DntFunkcije::trim($res->{$sth->{NAME}[$i]}).";"; 
						my %row = ('vsebina' => $res->{$sth->{NAME}[$i]});				
						push (@loop, \%row);
					}
					$id_agreement = DntFunkcije::trim($res->{$sth->{NAME}[$i]});
					 
				}
				elsif($sth->{NAME}[$i] eq "id_vrstica"){
					$index .= DntFunkcije::trim($res->{$sth->{NAME}[$i]}).", ";					
				}
				
				#PREVEDI DEBIT TYPE:
				elsif($sth->{NAME}[$i] eq "pay_type" || $sth->{NAME}[$i] eq "debit_type" ||
					  $sth->{NAME}[$i] eq "pay_type1" || $sth->{NAME}[$i] eq "pay_type2"){
					
					$csv .= $debit_hash{$res->{$sth->{NAME}[$i]}}.";";
					my %row = ('vsebina' => '<span title="' . $res->{$sth->{NAME}[$i]} . '">' . $debit_hash{$res->{$sth->{NAME}[$i]}} . '</span>');			
					push (@loop, \%row);
					
				}
				#FORMAT DATUMA:
				elsif($sth->{TYPE}[$i] == 11){
					#return DntFunkcije::sl_date($res->{$sth->{NAME}[$i]}) . " " . $res->{$sth->{NAME}[$i]};
					$csv .= DntFunkcije::sl_date($res->{$sth->{NAME}[$i]}).";";
					my %row = ('vsebina' => DntFunkcije::sl_date($res->{$sth->{NAME}[$i]}));			
					push (@loop, \%row);
					
				}
				#PREVEDI FORMATFINANCNO:
				elsif($sth->{TYPE}[$i] == 3){
					$csv .= DntFunkcije::FormatFinancno($res->{$sth->{NAME}[$i]}).";";
					my %row = ('vsebina' => DntFunkcije::FormatFinancno($res->{$sth->{NAME}[$i]}));			
					push (@loop, \%row);
					
				}
				#TAX NUMBER:
				elsif($sth->{NAME}[$i] eq "tax_number"){
					$csv .= DntFunkcije::TaxNumberDb($dbh, $id_agreement).";";
					my %row = ('vsebina' => DntFunkcije::TaxNumber($id_agreement));			
					push (@loop, \%row);					
				}
				else{
					if(defined $res->{$sth->{NAME}[$i]}){
					$csv .= DntFunkcije::trim($res->{$sth->{NAME}[$i]}).";";
					}
					else{
						$csv .= ";";
					}
					my %row = ('vsebina' => ($res->{$sth->{NAME}[$i]}));			
					push (@loop, \%row);
				}
				$i++
			}
			$csv = substr($csv, 0, -1)."\n";
			my $return_url = $ENV{'REQUEST_URI'};
			$return_url =~ s/&/_amp_/g;
			my %row = ('loop' => \@loop,
					   'izbor'=> $res->{'id_vrstica'},
					   'link' => $res->{'id_agreement'},
					   'url' => $return_url);
			push (@vsebina, \%row);
			$count_rows++;
		}
		$sql = "UPDATE isci SET param='$shraniPogled' WHERE tip='$bremenitev'";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		

	}
	else{
		return 'Povezava do baze ni uspela';
	}
	
	$menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntIzvoziObrokeSeznam.tmpl',
						   cache => 1,
	);
    $template->param(
		#MENU_POT => $menu_pot,
	   IME_DOKUMENTA => 'IzvoziObroke',
	   POMOC => "<input type='button' value='?' ".
	   "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
	   	edb_vsebina => \@vsebina,
		edb_naslovi => \@naslovi,
		form => DntFunkcije::output_form($q, $csv, 'obroki', $index),
		edb_stevilo => $count_rows,
	);
	
	$html_output = $template->output; #.$tabelica;
	return $html_output;
	
}
#če uporabnik ni prijavljen:
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'IzvoziObroke';
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
