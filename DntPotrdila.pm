package DntPotrdila;
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
	
    my $user = DntFunkcije::AuthenticateSession(26, $nivo);
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
        'zacetek' => 'PotrdilaZacetek',
		'Prikazi' => 'PotrdilaPrikazi',
		'login' => 'Login',
		'error' => 'Error'

    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub PotrdilaZacetek{

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
	my $id_Opomini= $q->param('edb_id');
	my $projekt= $q->param('edb_projekt');
	my $leto= $q->param('edb_leto');
	my $dogodek= $q->param('edb_dogodek');
	my $bremenitev = $q->param('bremenitev') || -1;
	my $racun;
	my $poloznica;
	my $komercialist= $q->param('edb_komercialist');
	my $samoKomercialist= $q->param('komercialist');
	my $odprte= $q->param('odprte');
	my $selected;
	my $zapadlost;
	
	if(defined $bremenitev && $bremenitev == 5){
		$poloznica="selected=true";
		$racun = "";
	}
	elsif(defined $bremenitev && $bremenitev == 6){
		$racun = "selected = true";
		$poloznica="";
	}	
	my @donatorji;
	my @pogodbe;
	my @obroki;
	
	my @donatorjiIzbrani;
	my @pogodbeIzbrane;

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
		$mday="0$mday"
	}
	$year+=1900;
	$zapadlost="$mday/$mon/$year";
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntPotrdila.tmpl',
			      cache => 1,
			     );
    $template->param(
		#MENU_POT => $menu_pot,
	   IME_DOKUMENTA => 'Potrdila',
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
	
	if ($dbh) {
		#if(length($ime)+length($st)>0){
		$sql = "SELECT * FROM isci WHERE tip='$bremenitev'";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		my @vsi;		
		while($res = $sth->fetchrow_hashref){
			my $para = $res->{param};
			@vsi = split("-", $para);
			@donatorjiIzbrani=split(",", $vsi[0]);
			@pogodbeIzbrane=split(",", $vsi[1]);
			
		}
		
		$sql = "SELECT * FROM sfr_donor LIMIT 1";		
		$sth = $dbh->prepare($sql);
		$sth->execute();
		my $i=0;
		while ($sth->{NAME}[$i]) {
			my %row2 = (	
				column => $sth->{NAME}[$i],
				column_slo => DntFunkcije::SloColumns($sth->{NAME}[$i]),
			);
			foreach(@donatorjiIzbrani){
				if($_ eq $sth->{NAME}[$i]){
					$row2{selected}= "selected=true";
				}
			}
			push(@donatorji, \%row2);
			$i++;
		}
		$sql = "SELECT * FROM sfr_agreement LIMIT 1";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$i=0;
		while ($sth->{NAME}[$i]) {
			my %row2 = (	
				column => $sth->{NAME}[$i],
				column_slo => DntFunkcije::SloColumns($sth->{NAME}[$i]),
			);
			foreach(@pogodbeIzbrane){
				if($_ eq $sth->{NAME}[$i]){
					$row2{selected}= "selected=true";
				}
			}
			push(@pogodbe, \%row2);
			$i++;
		}
		$sql = "SELECT * FROM agreement_pay_installment LIMIT 1";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$i=0;
		while ($sth->{NAME}[$i]) {
			my %row2 = (	
				column => $sth->{NAME}[$i],
				column_slo => DntFunkcije::SloColumns($sth->{NAME}[$i]),
			);
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
		$template->param(
			edb_loop6 => \@loop6,
			edb_loop7 => \@loop7,
			edb_loop8 => \@loop8,
			#edb_loop9 => \@loop9,
			#edb_loop10 => \@loop10,
			donatorji => \@donatorji,
			pogodbe => \@pogodbe,
			obroki => \@obroki,
			zapadlost => $zapadlost
		);
	}
	else{
		return 'Povezava do baze ni uspela';
	}
                
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}

sub PotrdilaPrikazi{

	my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');	
	my $html_output ;
	my $menu_pot;
	my $csv;
	my $index;
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
	my $b_id_donor=0;
	my $a_id_agreement=0;
	my $a_amount1 = 0;
	my $a_select;
	my $count_rows;
	my $aktivenDonator = $q->param('aktivenDonator');
	my @donatorji= $q->param('donatorji');
	my @pogodbe= $q->param('pogodbe');
	my @obroki= $q->param('obroki');
	
	my @naslovi;
	my @vsebina;

	my $shraniPogled;
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	if($zapadlost){
		$zapadlost=substr($zapadlost, 6, 4)."-".substr($zapadlost, 3, 2)."-".
				   substr($zapadlost, 0, 2);
	}
	$a_select = "";				
		
	if($projekt){
		$a_select.=" AND a.id_project = $projekt";
	}
	if($dogodek){
		$a_select.=" AND a.id_event ILIKE '$dogodek'";
	}
	if($leto){
		$a_select.=" AND a.id_agreement ILIKE '_$leto%'";
	}
	#return $bremenitev;
	#if($bremenitev eq "6"){
	#	$a_select.=" AND ag.debit_type = 'A1'";
	#}
	#elsif($bremenitev eq "5"){
	#	$a_select.=" AND ag.debit_type = '01'";
	#}
	if($zapadlost){
	    # Issue 80
		$a_select.=" AND ((SELECT ag1.date_due FROM agreement_pay_installment as ag1 WHERE ag1.date_due IS NOT NULL AND ag1.id_agreement = a.id_agreement ORDER BY ag1.date_due DESC LIMIT 1) <= '$zapadlost' OR ag.id_agreement IS NULL OR (a.status = 'S' AND (SELECT COUNT(ag1.date_due) FROM agreement_pay_installment as ag1 WHERE ag1.date_due IS NOT NULL AND ag1.id_agreement = a.id_agreement) = 0 AND a.date_1st_amount <= '$zapadlost'))";
	}
	#return $a_select;
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		my %debit_hash = DntFunkcije::debitNames($dbh);
		$sql = "SELECT DISTINCT a.id_agreement, b.id_donor, a.amount1 ";
		#izbere stolpce za izpis
		foreach (@donatorji){
			if ($_ eq "id_donor"){
				$b_id_donor=1;
				
			}
			else{
				$sql.= ", b.$_";
			}
			$shraniPogled.="$_,";
		}
		$shraniPogled.="-";
		foreach (@pogodbe){
			if ($_ eq "id_agreement"){
				$a_id_agreement=1;
			}
			elsif ($_ eq "amount1"){
				$a_amount1=1;
			}
			elsif($_ eq "amount"){
                                 $sql .= ", a.$_ as znesek";
                        }
			else{
				$sql.= ", a.$_";
			}
			$shraniPogled.="$_,";
		}
		#izracuna vsoto (sum) - sesteje amount vseh placanih + prvi obrok:
		#$sql.=", (SELECT sum(c.amount)".
		#	  " FROM agreement_pay_installment AS c".
		#	  " WHERE c.id_agreement = a.id_agreement AND".
		#	  " c.id_agreement = b.id_agreement AND c.storno ISNULL".
		#	  " AND c.amount_payed = c.amount".
		#	  " AND c.amount>0 ";
			  
		#if($zapadlost){
		#	$sql.=" AND c.date_due < '$zapadlost' ";
		#}
		#$sql.="$a_select ) AS sum";
		#izbere id_obroka
		#$sql.=", (SELECT c.id_vrstica". 
		#	  " FROM agreement_pay_installment AS c".
		#	  " WHERE c.id_agreement = a.id_agreement AND".
		#	  " c.id_agreement = b.id_agreement AND c.storno ISNULL".
		#	  " AND c.amount_payed = c.amount".
		#	  " AND c.amount>0 ";
			  
		#if($zapadlost){
		#	$sql.=" AND c.date_due  < '$zapadlost' ";
		#}
		#$sql.="$a_select ORDER BY c.id_vrstica DESC LIMIT 1) AS id_obroka";
	
		#izbor tabel iz katerih stavek crpa podatke:
		$sql.=" FROM sfr_agreement AS a LEFT OUTER JOIN agreement_pay_installment as ag ON a.id_agreement = ag.id_agreement".
			  ", sfr_donor AS b";
		#povezave med tabelami, da se vrstice ne podvajajo:	  
		$sql.=" WHERE ".
			  " a.id_donor = b.id_donor ";
		$sql .= " AND (a.status = 'P' OR a.status = 'S')"; #a.status = 'S' OR
		$sql.=$a_select;
		#izpis za aktivne donatorje (manjka sestevanje pogodb za donatorja)
		if(defined $aktivenDonator && $aktivenDonator > 0){
			$sql .= " AND b.active_donor = '1'";
		}
		else{
		    $sql .= " AND b.active_donor = '0'";
		}
		$sql .= " ORDER BY id_agreement";
		$sth = $dbh->prepare($sql);
		#print "\n\n";
		#print $sql;
		#return;
		$sth->execute();
		my $i=0;
		#priprava naslovov za izpis:
		while (defined $sth->{NAME}[$i]){
			if($sth->{NAME}[$i] eq "id_agreement"){
				if($a_id_agreement != 0){
					my %row = ('naslov' => DntFunkcije::SloColumns($sth->{NAME}[$i]));			
					push (@naslovi, \%row);
					$csv .= DntFunkcije::SloColumns($sth->{NAME}[$i]).";";
					
				}				
			}
			elsif($sth->{NAME}[$i] eq "id_donor"){
				if($b_id_donor != 0){
					my %row = ('naslov' => DntFunkcije::SloColumns($sth->{NAME}[$i]));			
					push (@naslovi, \%row);
					$csv .= DntFunkcije::SloColumns($sth->{NAME}[$i]).";";					
				}
			}
			elsif($sth->{NAME}[$i] eq "amount1"){
				if($a_amount1 != 0){
					my %row = ('naslov' => DntFunkcije::SloColumns($sth->{NAME}[$i]));			
					push (@naslovi, \%row);
					$csv .= DntFunkcije::SloColumns($sth->{NAME}[$i]).";";					
				}
			}
			elsif($sth->{NAME}[$i] eq "id_obroka"){}
			else{
				my %row = ('naslov'=>DntFunkcije::SloColumns($sth->{NAME}[$i]));			
				push (@naslovi, \%row);
				$csv .= DntFunkcije::SloColumns($sth->{NAME}[$i]).";";
			}
			$i++;
		}
		$csv .= "Vsota\n";
		my %row3 = ('naslov'=>"Vsota");			
				push (@naslovi, \%row3);
		$count_rows = 0;
		#priprava dejanskih vrstic za izpis:
		my $vsota=0.00;
		while ($res = $sth->fetchrow_hashref) {
			$vsota=0.00;
			#IZRAČUNAJ VSOTO:
			my $res2;
			my $sql2;
			my $sth2;
			$sql2="SELECT amount_payed, date_due, debit_type FROM agreement_pay_installment WHERE id_agreement=? ";
			if($bremenitev eq "6"){
				$a_select.=" AND debit_type = 'A1'";
			}
			elsif($bremenitev eq "5"){
				$a_select.=" AND debit_type = '01'";
			}
			$sth2 = $dbh->prepare($sql2);
			$sth2->execute($res->{id_agreement});
			#IZRAČUNAJ VSOTO OBROKOV:
			while($res2 = $sth2->fetchrow_hashref){
				
				if(defined $res2->{'amount_payed'}){
					$vsota += $res2->{'amount_payed'};
				}
			}
			#IZRAČUNAJ PRVI OBROK:
			if(defined $res->{amount1}){
				$vsota += $res->{amount1};
			}
			if($vsota == 0){
				next;
			}
			$i=0;
			my @loop;
			my $id_agreement;
			while ($sth->{NAME}[$i]){
				
				if($sth->{NAME}[$i] eq "id_agreement"){
					if($a_id_agreement != 0){
						my %row = ('vsebina' => $res->{$sth->{NAME}[$i]});				
						push (@loop, \%row);
						
						$csv .= $res->{$sth->{NAME}[$i]}.";";
						
					}
					$index .= $res->{$sth->{NAME}[$i]}.", ";
					$id_agreement = $res->{$sth->{NAME}[$i]};
					
				}
				elsif($sth->{NAME}[$i] eq "id_donor"){
					if($b_id_donor != 0){
						my %row = ('vsebina' => $res->{$sth->{NAME}[$i]});				
						push (@loop, \%row);
						$csv .= $res->{$sth->{NAME}[$i]}.";";
						
					}
				}
				elsif($sth->{NAME}[$i] eq "id_obroka"){		
				}
				elsif($sth->{NAME}[$i] eq "amount1"){
					
					if($a_amount1 != 0){
						my %row = ('vsebina' => DntFunkcije::FormatFinancno($res->{$sth->{NAME}[$i]}));				
						push (@loop, \%row);
						$csv .= DntFunkcije::FormatFinancno($res->{$sth->{NAME}[$i]}).";";
						
					}
				}
				#PREVEDI DEBIT TYPE:
				elsif($sth->{NAME}[$i] eq "pay_type" || $sth->{NAME}[$i] eq "debit_type" ||
					  $sth->{NAME}[$i] eq "pay_type1" || $sth->{NAME}[$i] eq "pay_type2"){
					
					$csv .= $debit_hash{$res->{$sth->{NAME}[$i]}}.";";
					my %row = ('vsebina' => '<span title="' . $res->{$sth->{NAME}[$i]} . '">' . $debit_hash{$res->{$sth->{NAME}[$i]}} . '</span>');			
					push (@loop, \%row);
					
				}
				#PREVEDI FORMATFINANCNO:
				elsif($sth->{TYPE}[$i] == 3){
					$csv .= DntFunkcije::FormatFinancno($res->{$sth->{NAME}[$i]}).";";
					my %row = ('vsebina' => DntFunkcije::FormatFinancno($res->{$sth->{NAME}[$i]}));			
					push (@loop, \%row);
					
				}
				#FORMAT DATUMA:
				elsif($sth->{TYPE}[$i] == 11){
					$csv .= DntFunkcije::sl_date($res->{$sth->{NAME}[$i]}).";";
					my %row = ('vsebina' => DntFunkcije::sl_date($res->{$sth->{NAME}[$i]}));			
					push (@loop, \%row);
					
				}
				#TAX NUMBER:
				elsif($sth->{NAME}[$i] eq "tax_number"){
					$csv .= DntFunkcije::TaxNumberDb($dbh, $id_agreement).";";
					my %row = ('vsebina' => DntFunkcije::TaxNumber($id_agreement));			
					push (@loop, \%row);					
				}
				else{
					my %row = ('vsebina' => ($res->{$sth->{NAME}[$i]}));				
					push (@loop, \%row);
					if(defined DntFunkcije::trim($res->{$sth->{NAME}[$i]})){
						$csv .= DntFunkcije::trim($res->{$sth->{NAME}[$i]});
					}
					$csv .= ";";
				}
				
				$i++;
			}
			$csv .= DntFunkcije::FormatFinancno($vsota)."\n";
			my %row2 = ('vsebina' => DntFunkcije::FormatFinancno($vsota));				
			push (@loop, \%row2);
			my $return_url = $ENV{'REQUEST_URI'};
			$return_url =~ s/&/_amp_/g;
			my %row = ('loop' => \@loop,
					   'izbor'=> $res->{'id_agreement'},
					   'link' => $res->{'id_agreement'},
					   'url' => $return_url);
			push (@vsebina, \%row);
			$count_rows++;
		}
		$index = substr($index, 0, -2);
		#shrani izbor zadnjega iskanja v bazo:
		$sql = "UPDATE isci SET param='$shraniPogled' WHERE tip='$bremenitev'";
		$sth = $dbh->prepare($sql);
		$sth->execute();

	}
	else{
		return 'Povezava do baze ni uspela';
	}
	
	$menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntPotrdilaSeznam.tmpl',
						   cache => 1,
	);
    $template->param(
		#MENU_POT => $menu_pot,
	   IME_DOKUMENTA => 'Potrdila',
	   POMOC => "<input type='button' value='?' ".
	   "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
	   	edb_vsebina => \@vsebina,
		edb_naslovi => \@naslovi,
		edb_stevilo => $count_rows,
		form => DntFunkcije::output_form($q, $csv, 'potrdila', $index),
	);
	
	$html_output = $template->output; #.$tabelica;
	return $html_output;
	
}

#če uporabnik ni prijavljen:
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'Potrdila';
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
