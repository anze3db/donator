package DntIsci;
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
	if ($str eq 'Shrani' || $str eq 'zbrisi' || $str eq 'nastavitve' ||
		$str eq 'dodaj' || $str eq 'brisi'){
		$nivo = 'w';
	}
	
    my $user = DntFunkcije::AuthenticateSession(42, $nivo);
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
        'seznam' => 'IsciSeznam',
		'Prikazi' => 'Izpis',
		'uredi' => 'IsciUredi',
		'Shrani' => 'NastavitveShrani',
		'zbrisi' => 'IsciZbrisi',
		'nastavitve' => 'Nastavitve',
		'dodaj' => 'NastavitveShrani',
		'brisi' => 'NastavitveZbrisi',
		'iskanje_shrani' => 'IskanjeShrani',
		'login' => 'Login',
		'error' => 'Error'

    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub IsciSeznam{

    my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');	
	my $html_output ;
	my $ime= $q->param('edb_ime');
	my @loop;
	my $menu_pot;
	my $triPike;
	my $url= $ENV{REQUEST_URI};
	my $poKorenuIme= $q->param('po_korenu_ime');
	my $st= $q->param('edb_st');
	my $uporabnik= $q->param('uporabnik');
    my $template ;
	my $id_pole= $q->param('edb_id');
	my $projekt= $q->param('edb_projekt');
	my $leto= $q->param('edb_leto');
	my $dogodek= $q->param('edb_dogodek');
	my @tabela= $q->param('edb_tabela');
	my @tabela2= $q->param('edb_tabela');
	
	my $tabelaIf;
	my $selected;
	my $komercialist;
	my $odprte;
	my $tab;
	my $id_iskanja = $q->param('id_iskanja') || 0;
	my @loop5;
	my @loop6=$q->param('edb_izbrane');
	my @loop7;
	my @loop8;
	my @loop9;
	my @linki;
	my @pogoji;
	my @povezave;
	my @p;
	my @iss;
	my @iTmp;
	
	my $tmp;
	my $d1tmp;
	my $d2tmp;
	my $now=localtime;
	
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	my $zbrisi;
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		#povrne parametre shranjenega iskanja:
		if($id_iskanja>0){
			my $redirect_url;
			$sql="SELECT * FROM isci WHERE id_isci='$id_iskanja'";
			$sth = $dbh->prepare($sql);
			$sth->execute();
			if ($res = $sth->fetchrow_hashref){
				my $string=$res->{'param'};
				$string=~s/_._/&/g;
				#return $string;
				@tabela=split("tabele=", $string);
				@tabela2=split("tabele=", $string);
				shift(@tabela);
				shift(@tabela2);
				my $stv=0;
				foreach (@tabela){
					$p[$stv]=$_;
					$p[$stv]=/pogoji=.*?&/;
					$p[$stv]=$&;
					$p[$stv]=substr($p[$stv], 7, length($p[$stv])-8);
					$p[$stv]=~s/%3E/>/g;
					$p[$stv]=~s/%3C/</g;
					$p[$stv]=~s/\+/ /g;
					$p[$stv]=~s/%3D/=/g;
					$p[$stv]=~s/\%27/\'/g;
					$p[$stv]=~s/%2C%0D%0A/,\n/g;

					@iTmp=split("izpis=",$_);
					shift(@iTmp);
					my $stv2=0;
					foreach (@iTmp){
						$iss[$stv][$stv2]=$_;
						$iss[$stv][$stv2]=~s/&//g;
						$stv2++;
					}
					$stv++;
					$_ =~ s/&.*//g;
					
				}
				
			}
			
		}
	}
	my $tabNum= @tabela;
	
	$url =~ s/&/_._/g;
	$now=substr($now, -2, 2);
	$self->param(testiram =>'rez');
	#ce tabele se niso bile izbrane se pokaze list tabel
	if(@tabela){
		$tabelaIf=1;
	}
	else{
		$tabelaIf=0;
	}
	
	
	$st=0;
	foreach (DntFunkcije::SloTables(@tabela2)){
		if($st==0){
			$tab.=$_;
			$st++;
		}
		else{
			$tab.=", ".$_;
		}
	}
	    
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntIsciSeznam.tmpl',
			      cache => 1,
			     );
    $template->param(
		     #MENU_POT => $menu_pot,
			IME_DOKUMENTA => 'Iskalnik',
			POMOC => "<input type='button' value='?' ".
			"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),

		     );
	#Ce so se parametri za poizvedbo izpise rezultat
	my $hid_sort = $q->param("hid_sort");
		
	if ($dbh) {
		my $sttt="";
		my $j=0;
		my $l=0;
		my $ta = @tabela;
		my $stv=0;
		#Glede na izbrane tabele se generirajo okna za vstavljanje pogojev
		#generiranje sql stavka:
		foreach my $t (@tabela){			
			$sql = "SELECT * FROM $t";
			$sth = $dbh->prepare($sql);
			$sth->execute();
			my @polja;
			my @polja2;
			my $i=0;
			$sql="S";
			while ($sth->{NAME}[$i]) {
				$sql.="<br />".$i."<br />";
				my $selected = "";
				my $jk = 0;
				while($iss[$stv][$jk]){
					
					if($iss[$stv][$jk] eq "$t.".$sth->{NAME}[$i]){
						$selected="selected=true";
					}
					$jk++;
				}				
				my %row = (column => "$t.".$sth->{NAME}[$i],
						   column_slo => DntFunkcije::SloColumns($sth->{NAME}[$i]),						   
						  );
				
				push(@polja, \%row);
				$i++;
			}
			$i=0;
			$sql="S";
			
			while ($sth->{NAME}[$i]) {
				
				my $selected = "";
				my $jk = 0;
				while($iss[$stv][$jk]){
					$iss[$stv][$jk]=~s/rm=.*//g;
					$iss[$stv][$jk]=~s/povezave=.*//g;
					
					if($iss[$stv][$jk] eq "$t.".$sth->{NAME}[$i]){
						$selected="selected=true";
						
						
						
					}
					$sttt.=$iss[$stv][$jk]." $jk, $stv<br />";
					$jk++;
				}
				#return $jk;
				
				my %row = (column => "$t.".$sth->{NAME}[$i],
						   column_slo => DntFunkcije::SloColumns($sth->{NAME}[$i]),
						   selected => $selected
						  );				
				push(@polja2, \%row);
				$i++;
			}
			my %row2 = (tabela => DntFunkcije::SloTables($t),
						s_pogoji => $p[$stv++],
				    tabela_eng => $t,
					     polja => \@polja,
						 polja2 => \@polja2,
					  id_pogoj => $j++,
					  );
			push(@pogoji, \%row2);
			for(my $k=++$l; $k<$ta; $k++){
				my $t2 = $tabela[$k];
				if(!($t2 eq $t)){						
					$sql = "SELECT * FROM isci WHERE tip = 'P' AND ".
						   "param ilike '%$t%' AND param ilike '%$t2%'";
					$sth = $dbh->prepare($sql);
					$sth->execute();
		
					while ($res = $sth->fetchrow_hashref) {
						
						my %row = (param => DntFunkcije::trim($res->{param}),
						);						
						push(@povezave, \%row);
					}
				}
			}
		}
		my $val;
		my $cl;
		
		foreach my $lp (@loop9){
			$val.="<tr>";
			foreach (@loop5){
				
				$cl = $_->{'column'};
				$val.="<td>".DntFunkcije::trim($lp->{$cl})."</td>";
			}			
			$val.="<td><a href='".NajdiUrl($lp->{'tabela'})."$lp->{'id'}'>uredi</a></td>";
			$val.="</tr>";
			
			
		}
		
		#foreach my $i (@loop6){
		#	$i->{'column_slo'} = DntFunkcije::SloColumns($i->{'column'});
		#}
		foreach(@loop5){
			$_->{'column'} = DntFunkcije::SloColumns($_->{'column'});
		}
		
		
		
		#return $val;
		my %row= (column => "tabela");
		push(@loop5, \%row);
		
		
		$sql = "SELECT * FROM isci WHERE tip='I'";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		while ($res = $sth->fetchrow_hashref) {
				my %row = (				
					#param => DntFunkcije::trim($res->{'param'}),
					naslov => DntFunkcije::trim($res->{'naslov'}),
					id => DntFunkcije::trim($res->{'id_isci'})
					
				);
				push(@linki, \%row);
		}		
		
		$template->param(
		     #MENU_POT => $menu_pot,
			tabele => $tabelaIf,
			pogoji => \@pogoji,
			povezave => \@povezave,
			url => $url,
			#edb_loop7 => \@loop7,
			#tab => $tab,
			#edb_loop8 => \@loop8,
			linki => \@linki,
			 
		     );
	}
	else{
		return 'Povezava do baze ni uspela';
	}
                
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}
sub NajdiId($){	
	
	my $sql;
	
	if($_ eq "sfr_donor"){
		$sql="id_donor";
	}
	elsif($_ eq "sfr_staff"){
		$sql="id_staff"
	}
	elsif($_ eq "sfr_agreement"){
		$sql="id_agreement";
	}
	elsif($_ eq "sfr_agreement"){
		$sql="id_agreement";
	}
	elsif($_ eq "agreement_pay_installment"){
		$sql="id_vrstica";
	}
	elsif($_ eq "sfr_bank"){
		$sql="id_bank";
	}
	elsif($_ eq "sfr_events"){
		$sql="id_event";
	}
	elsif($_ eq "sfr_project"){
		$sql="id_project";
	}
	elsif($_ eq "sheets_series"){
		$sql="series";
	}
	elsif($_ eq "sfr_post"){
		$sql="id_post";
	}
	

	
	return $sql;

}
sub NajdiUrl($){
	
	my $table=shift;
	my $sql;
	if($table eq "sfr_donor"){
		$sql="DntDonatorji.cgi?rm=uredi_donatorja&id_donor=";
	}
	elsif($table eq "sfr_staff"){
		$sql="DntZaposleni.cgi?rm=uredi&id_staff="
	}
	elsif($table eq "sfr_agreement"){
		$sql="DntPogodbe.cgi?rm=uredi_pogodbo&uredi=1&id_agreement=";
	}
	else{
		$sql="NAPAKA"
	}
	
	return $sql;

}
sub Nastavitve{
	
	my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');	
	my $html_output ;
	my $menu_pot;
	my $uporabnik= $q->param('uporabnik');
    my $template;
	my $tabela1= $q->param('edb_tabela1');
	my $tabela2= $q->param('edb_tabela2');
	my @loop1;
	my @loop2;
	my @naslovi1;
	my @naslovi2;
	my $nivo2=0;
	
	$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntIskalnikNastavitve.tmpl',
			      cache => 1,
			     );
    $template->param(
		     #MENU_POT => $menu_pot,
			IME_DOKUMENTA => 'Iskalnik'.$uporabnik,
			POMOC => "<input type='button' value='?' ".
			"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
		     );
	
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	
	$dbh = DntFunkcije->connectDB;	
	if ($dbh) {
		#if(length($ime)+length($st)>0){
		$sql = "select * FROM isci";		
		$sth = $dbh->prepare($sql);
		$sth->execute();
		while ($res = $sth->fetchrow_hashref) {
			if(DntFunkcije::trim($res->{'tip'}) eq "I"){
				my %row = (				
					param => DntFunkcije::trim($res->{'naslov'}),
					id => DntFunkcije::trim($res->{'id_isci'})
					
				);
				
				push(@loop1, \%row);
			}
			elsif(DntFunkcije::trim($res->{'tip'}) eq "P"){
				my %row = (				
					param => DntFunkcije::trim($res->{'param'}),
					id => DntFunkcije::trim($res->{'id_isci'})
					
				);
				push(@loop2, \%row);
			}

				# put this row into the loop by reference             
				
		}
		
		if(!($tabela1 eq "" && $tabela2 eq "")){
			
			$nivo2=1;
			
			$sql = "select * FROM $tabela1";		
			$sth = $dbh->prepare($sql);
			$sth->execute();
			my $i=0;
			while (!($sth->{NAME}[$i] eq "")){
				my %row = ('column_slo' => DntFunkcije::SloColumns($sth->{NAME}[$i]),
						   'column' => $tabela1.".".$sth->{NAME}[$i++]);
				
				push (@naslovi1, \%row);
			}
			$i=0;
			$sql = "select * FROM $tabela2";		
			$sth = $dbh->prepare($sql);
			$sth->execute();
			while (!($sth->{NAME}[$i] eq "")){
				my %row = ('column_slo' => DntFunkcije::SloColumns($sth->{NAME}[$i]),
						   'column' => $tabela2.".".$sth->{NAME}[$i++]);
				push (@naslovi2, \%row);
			}
		}
		$template->param(loop1 => \@loop1,
						 loop2 => \@loop2,
						 column1 => \@naslovi1,
						 column2 => \@naslovi2,
						 nivo2 => $nivo2,
						);

		#}	
	}
	else{
		return 'Povezava do baze ni uspela';
	}

    $html_output = $template->output; #.$tabelica;
	return $html_output;
}


sub NastavitveShrani{
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $tip = $q->param('edb_tip');
	my $now=localtime;
	$now=substr($now, 4);

	my $menu_pot ;
	my $template ;
	
	my $ime = $q->param('ime');
	my $param = $q->param('url');

	my $dbh;
	my $sql;
	my $sth;
	my $res;

	
	my $redirect_url="?rm=nastavitve&amp;";
	if($tip eq "I" || $tip eq "J"){
		$redirect_url="?rm=iskanje_shrani&shranjeno=1";
		$param =~ s/\'/\'\'/g;
		
	}
	else{
		$param = $q->param('edb_column1')." = ".$q->param('edb_column2');
	}
		
		$dbh = DntFunkcije->connectDB;
	
		
		if ($dbh) {
			
			$sql = "INSERT INTO isci (tip, param, naslov, ustvarjeno) VALUES".
				   " ('$tip', '$param', '$ime', '$now')";
			#print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			#return $sql;
			unless($sth->execute()){
				
				my $napaka_opis = $sth->errstr;
				$template = $self->load_tmpl(	    
					'DntRocniVnosNapaka.tmpl',
				cache => 1,
				);
				$template->param(
								
								 );
		
				$html_output = $template->output; #.$tabelica;
				return $html_output;
			}
		
		}
		$sth->finish;
		$dbh->disconnect();
		
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
		

}
sub NastavitveZbrisi(){
	
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
	$id=$q->param('id_placilo');
	

		
		
	$sql="DELETE FROM isci WHERE ";
			
	foreach $id (@deleteIds){
		if ($counter==0){
			$sql.="id_isci='$id' ";
			$counter++;
		}
		$sql.="OR id_isci='$id' ";
	}	
	$redirect_url="?rm=nastavitve";

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
	
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
	
}
sub Izpis(){
	
	my $self = shift;
    my $q = $self->query();
	my $csv;
	my $seja= $q->param('seja');	
	my $html_output ;
	my $menu_pot;
	my $uporabnik= $q->param('uporabnik');
    my $template;
	my $url= $ENV{REQUEST_URI};
	my $ime = $q->param('ime');
	my @izpis = $q->param('izpis');
	my @tabele = $q->param('tabele');
	my @pogoji = $q->param('pogoji');
	my @povezave = $q->param('povezave');
	my @vsebina;
	my @naslovi;


	my $dbh;
	my $res;
	my $sql;
	my $sth;
	my $count_rows = 0;
	
	$dbh = DntFunkcije->connectDB;
		
	if ($dbh) {

		my %debit_hash = DntFunkcije::debitNames($dbh);
		$sql = "SELECT DISTINCT";
		
	
		foreach (@izpis){
			$sql.= " $_,";
		}	
		$sql = substr($sql, 0, length($sql)-1);
		$sql .= " FROM ";
		
		foreach (@tabele){
			$sql.= " $_,";
		}
		$sql = substr($sql, 0, length($sql)-1);	
		$sql.= " WHERE 1=1";
		
		foreach (@pogoji){
			if (!($_ eq "")){
							
				my $nd = s/,/ AND/g;
				if($_ =~ /=/g){	
					my $str = '';
					foreach my $condition (split(/ AND/, $_)){
						my $posOfEq = index($condition, '=');
						$str .= ' CAST (' . substr($condition, 0, $posOfEq) . 'AS text) ' . substr($condition, $posOfEq) . ' AND';
					}
					$str = substr($str, 0 , -4);
					$_ = $str;	
					$_ =~ s/=/ilike/g;
	
					$_ =~ s/'\*/'%/g;
					$_ =~ s/\*'/'/g;
	
	
					$_ =~ s/' /%' /g;
					$_ =~ s/'$/%'/g;
				}			
					
	
				$sql.= " AND $_ ";
				
			}
		}
		#return $sql;
		foreach (@povezave){
			$sql.= " AND $_";
		}
		$sql .= " ORDER BY 1";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		
		my $i=0;
		while (defined $sth->{NAME}[$i]){
			$csv .= DntFunkcije::SloColumns($sth->{NAME}[$i]).";";
			my %row = ('naslov'=>DntFunkcije::SloColumns($sth->{NAME}[$i++]));			
			push (@naslovi, \%row);
		}
		$csv = substr($csv, 0, -1);
		$csv .=  "\n";
		
		
		
		while ($res = $sth->fetchrow_hashref) {
			$i=0;
			my @loop;
			while ($sth->{NAME}[$i]){
				
				my $row;
				#PREVEDI DEBIT TYPE:
				if($sth->{NAME}[$i] eq "pay_type" || $sth->{NAME}[$i] eq "debit_type" ||
					  $sth->{NAME}[$i] eq "pay_type1" || $sth->{NAME}[$i] eq "pay_type2"){
					
					
					$csv .= $debit_hash{$res->{$sth->{NAME}[$i]}}.";";
					my %row = ('vsebina' => $debit_hash{$res->{$sth->{NAME}[$i]}});
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
				$i++;
				
				#$csv .= DntFunkcije::sl_date(DntFunkcije::trim($res->{$sth->{NAME}[$i]})).";"; 
				#my %row = ('vsebina' => DntFunkcije::sl_date($res->{$sth->{NAME}[$i++]}));				
				#push (@loop, \%row);
				
			}
			$csv = substr($csv, 0, -1);
			$csv .= "\n";
			my %row = ('loop'=> \@loop);
			push (@vsebina, \%row);
			$count_rows++;
		}
		
	}
	else{
		return 'Povezava do baze ni uspela';
	}

	$url =~ s/&/_._/g;	
	#return $sql;
	$menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	             'DntIsciIzpis.html',
			      cache => 1,
			     );
    $template->param(
		     #MENU_POT => $menu_pot,
			IME_DOKUMENTA => 'Iskalnik',
			POMOC => "<input type='button' value='?' ".
			"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
			edb_vsebina => \@vsebina,
			edb_naslovi => \@naslovi,
			ime => $ime,
			url => $url,
			num_rows => $count_rows,
			form => DntFunkcije::output_form($q, $csv, 'iskanje', ''),
		     );
	$html_output = $template->output; #.$tabelica;
	return $html_output;
	
}

sub IskanjeShrani(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $url= $q->param('url');
	my $shranjeno = $q->param('shranjeno');
	$url=~ s/_._/&/g;
	#return $url;
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
	if($shranjeno != 1){
		$shranjeno = 0;
	}

	$dbh = DntFunkcije->connectDB;
	$imeDokumenta="Shrani iskanje";

		
	$menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek");
		$template = $self->load_tmpl(	    
							  'DntIsciShrani.tmpl',
					  cache => 1,
					 );
	$template->param(
		IME_DOKUMENTA => $imeDokumenta,
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		url => $url,
		shranjeno => $shranjeno,
		);

	
	$html_output = $template->output; #.$tabelica;
	return $html_output;
}
#če uporabnik ni prijavljen:
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'isci';
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
