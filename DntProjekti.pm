package DntProjekti;
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
	if ($str eq 'dodajPlacilo' || $str eq 'shraniTRR' ||
		$str eq 'Shrani'|| $str eq 'zbrisi' || $str eq 'trr'){
		$nivo = 'w';
	}
	
    my $user = DntFunkcije::AuthenticateSession(13, $nivo);
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
        'seznam' => 'ProjektiSeznam',
		'Prikazi' => 'ProjektiSeznam',
		'uredi' => 'ProjektiUredi',
		'Shrani' => 'ProjektiShrani',
		'zbrisi' => 'ProjektiZbrisi',
		'trr' => 'ProjektiTrr',
		'shraniTrr' => 'ShraniTrr',
		'dodajPlacilo' => 'ShraniPlacilo',
		'login' => 'Login',
		'error' => 'Error'
	);
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub ProjektiSeznam{
	
    my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');
	
	my $html_output ;
	my $ime= $q->param('edb_ime');
	my $opis= $q->param('edb_opis');
	my $upnik= $q->param('edb_upnik');
	my $tax= $q->param('edb_tax'); 
	my @loop;
	my $menu_pot;
	my $poKorenuIme= $q->param('po_korenu_ime');
	my $id= $q->param('edb_id');
	my $uporabnik= $q->param('uporabnik');
    my $template ;
	my $readonly;
	
	$self->param(testiram =>'rez');
	    
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntProjektiSeznam.tmpl',
			      cache => 1,
			     );
    $template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'Seznam projektov',
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
		
			$sql = "select * FROM sfr_project";
			$sql.= " where 1=1";
			if($ime)
			{
				
				if ($poKorenuIme==1){
					
					$sql .= " and name_project ilike '%$ime%'";
					$poKorenuIme="checked='checked'";
				}
				else{
					$sql .= " and name_project ilike '$ime%'";
					$poKorenuIme="";
				}
			}
			
			if($id)
			{
					$sql .= " and id_project  ilike '$id%'";
			}
			if($opis)
			{
					$sql .= " and opis_storitve  ilike '$opis%'";
			}
			if($upnik)
			{
					$sql .= " and zap_st_upnika ilike '$upnik%'";
			}
			if($tax)
			{
					$sql .= " and tax_number ilike '$tax%'";
			}
			
			$sql.=" ORDER BY id_project LIMIT 18";
			
			$sth = $dbh->prepare($sql);
			$sth->execute();
			while ($res = $sth->fetchrow_hashref) {
					
				my %row = (				
					izbor => $q->a({-href=>"DntProjekti.cgi?".
						"rm=uredi&id=$res->{'id_project'}".
						"&seja=$seja&uredi=1"}, 'uredi'),
					ime => DntFunkcije::trim($res->{'name_project'}),
					opis => DntFunkcije::trim($res->{'opis_storitve'}),
					upnik => DntFunkcije::trim($res->{'zap_st_upnika'}),
					tax => DntFunkcije::trim($res->{'tax_number'}),
					id => DntFunkcije::trim($res->{'id_project'})
					
		  );

					# put this row into the loop by reference             
					push(@loop, \%row);
			}
			$template->param(donator_loop => \@loop,					
					edb_ime => DntFunkcije::trim($ime),
					edb_id => DntFunkcije::trim($id),
					edb_opis => DntFunkcije::trim($opis),
					edb_tax => DntFunkcije::trim($tax),
					edb_upnik => DntFunkcije::trim($upnik),
					koren => $poKorenuIme);	
		}
		else{
			return 'Povezava do baze ni uspela';
		}
                
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}
sub ProjektiShrani{
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id = $q->param('edb_id');
	my $ime = $q->param('edb_ime');
	my $opis = $q->param('edb_opis');
	my $upnik = $q->param('edb_upnik');
	my $davcna = $q->param('edb_davcna');
	my $uredi = $q->param('uredi');
	my $menu_pot ;
	my $template ;
	
	
	my $dbh;
	my $sql;
	my $sth;
	my $res;

	
	my $redirect_url="?rm=seznam&amp;";

		
		$dbh = DntFunkcije->connectDB;
	
		
		if ($dbh) {
			
			if($uredi==1){
			
			$sql = "UPDATE sfr_project SET".
			" opis_storitve=?, name_project=?, zap_st_upnika=?, tax_number=? ".
			"WHERE id_project=?";
			#print $q->p($sql_vprasaj);
				$sth = $dbh->prepare($sql);
				unless($sth->execute($opis, $ime, $upnik, $davcna, $id)){
				
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
			else{	
				
				$sql = "INSERT INTO sfr_project ".
					   "(opis_storitve, name_project, zap_st_upnika,".
					   " tax_number, id_project) ".
					   "VALUES (?, ?, ?, ?, ?)";
				$sth = $dbh->prepare($sql);
				
				unless($sth->execute($opis, $ime, $upnik, $davcna, $id)){
					
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
		
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
		

}

sub ShraniTrr{
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id = $q->param('edb_id');
	my $id_vrstica = $q->param('edb_id_vrstica');
	my $trr = $q->param('edb_trr');
	my $poobl = $q->param('edb_poobl');
	my $banka = $q->param('banka');
	my $uredi=$q->param('edb_uredi');
	my $menu_pot ;
	my $template ;
	

	my $dbh;
	my $sql;
	my $sth;
	my $res;
	
	
	my $redirect_url="?rm=uredi&amp;id=$id&uredi=1";

		
		$dbh = DntFunkcije->connectDB;
	
		
		if ($dbh) {
			
			if($uredi==1){
			
			$sql = "UPDATE sfr_project_trr SET id_trr=?, id_bank=?, ".
				   "id_project_poobl=? WHERE id_project=?";			
			#print $q->p($sql_vprasaj);
				$sth = $dbh->prepare($sql);
				unless($sth->execute($trr, $banka, $poobl, $id)){
				
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
			else{
			
				
				$sql = "INSERT INTO sfr_project_trr (id_project, id_trr,".
					   " id_bank, id_project_poobl) ".
					   "VALUES (?, ?, ?, ?)";
			#print $q->p($sql_vprasaj);
				$sth = $dbh->prepare($sql);
				unless($sth->execute($id, $trr, $banka, $poobl)){
					
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
		
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
		

}
sub ShraniPlacilo{
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id = $q->param('edb_id');
	my $id_vrstica = $q->param('edb_id_vrstica');
	my $trr = $q->param('edb_trr');
	my $debit = $q->param('debit');
	my $upnik = $q->param('edb_upnik');
	my $davcna = $q->param('edb_davcna');
	my $uredi = $q->param('uredi');
	my $menu_pot ;
	my $template ;
	

	my $dbh;
	my $sql;
	my $sth;
	my $res;

	
	my $redirect_url="?rm=trr&amp;id=$id&id_vrstica=$id_vrstica&uredi=1";
	
		
		$dbh = DntFunkcije->connectDB;
	
		
		if ($dbh) {
			
			if($uredi==1){
			
			return "Kako si prisel sm?";
				
			}
			else{
			
				
				$sql = "INSERT INTO sfr_project_pay_type (id_project, id_trr,".
					   " debit_type) ".
					   "VALUES (?, ?, ?)";
			#print $q->p($sql_vprasaj);
				$sth = $dbh->prepare($sql);
				unless($sth->execute($id, $id_vrstica, $debit)){
					
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
		
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
}

sub ProjektiUredi{
	my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');	
	my $html_output ;
	my $menu_pot;
	my $id= $q->param('id');
	
	my $uredi=$q->param('uredi');
	my $ime;
	my $opis;
	my $upnik;
	my $uporabnik= $q->param('uporabnik');
    my $template;
	my $disabled;
	my $davcna;
	my $tmp;
	my @pId;
	my $selected;
			my @proId;
			my $i=0;
			my $j;

    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntProjektiUredi.tmpl',
			      cache => 1,
			     );
    $template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'Projekt',
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
		IME_DOKUMENTA2 => 'TRR',
	);
	#Ce so se parametri za poizvedbo izpise rezultat
	
	if(defined $uredi && $uredi==1){
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
	my $link;
	my @loop;
		
		my $hid_sort = $q->param("hid_sort");
		$dbh = DntFunkcije->connectDB;
		if ($dbh) {
			$sql = "select * FROM sfr_project";
			$sql.= " where id_project=?";

			$sth = $dbh->prepare($sql);
			$sth->execute($id);
			if($res = $sth->fetchrow_hashref) {
					
				$ime=DntFunkcije::trim($res->{'name_project'});
				$davcna=DntFunkcije::trim($res->{'tax_number'});
				$upnik=DntFunkcije::trim($res->{'zap_st_upnika'});
				$opis=DntFunkcije::trim($res->{'opis_storitve'});
				
			}
			$sql=" SELECT id_trr, id_vrstica, bank_name ".
				 " FROM sfr_project_trr, sfr_bank ".
				 " WHERE id_project=? ".
				 " AND sfr_bank.id_bank=sfr_project_trr.id_bank";
				
				$sth = $dbh->prepare($sql);
				$sth->execute($id);
				while ($res = $sth->fetchrow_hashref) {
					$link="<a href='?rm=trr&id=$id&id_vrstica=".
							$res->{'id_vrstica'}."&uredi=1'>uredi</a>";	
					my %row = (				
						izbor => $link,
						id_trr => DntFunkcije::trim($res->{'id_trr'}),
						bank_name => DntFunkcije::trim($res->{'bank_name'}),
						id_vrstice => DntFunkcije::trim($res->{'id_vrstica'}),

						
			  );
	
						# put this row into the loop by reference             
						push(@loop, \%row);
				}
			$sql="SELECT id_project FROM sfr_project";
			$sth = $dbh->prepare($sql);
			$sth->execute();
			
			while ($res = $sth->fetchrow_hashref) {				
					
				$pId[$i++]=$res->{id_project};
			}
			for($i=1; $i<10; $i++){
				if(defined $id && $id>0){
					my %row = (				
							id => $id,
						);
						push(@proId, \%row);
				}	
				
				else{
					$tmp=1;
					foreach $j (@pId){
						if($i==$j){
							$tmp=0;
						}
					}			
				
					if($tmp==1){
						my %row = (				
								id => $i,
								selected => $selected,
							);
							push(@proId, \%row);
					}
				}
			}
		}	
					
		
		else{
			return 'Povezava do baze ni uspela';
		}
		
			$template->param(					
					edb_ime => $ime,
					edb_id => $id,
					edb_davcna => $davcna,
					edb_upnik => $upnik,
					edb_opis => $opis,
					edb_uredi=> $uredi,
					edb_loop=> \@loop,
					edb_loop2=> \@proId,
					
					
					#edb_readonly=> $readonly,
			);
                
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
}

sub ProjektiTrr{
	my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');	
	my $html_output ;
	my $menu_pot;
	my $id= $q->param('id');
	my $id_vrstica= $q->param('id_vrstica');
	my $uredi=$q->param('uredi');
	my $trr;
	my $opis;
	my $upnik;
	my $uporabnik= $q->param('uporabnik');
    my $template;
	my $disabled;
	my $poobl;
	my $banka;
	my $selected;
	
	my @loop2;

    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntProjektiTrr.tmpl',
			      cache => 1,
			     );
    $template->param(
		     #MENU_POT => $menu_pot,
			 IME_DOKUMENTA => 'Podatki o racunu na projektu',
			  POMOC => "<input type='button' value='?' ".
			  "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
			 IME_DOKUMENTA2 => 'Nacin placila',
			 
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
	my @loop;
	my @loop3;
		
		my $hid_sort = $q->param("hid_sort");
		$dbh = DntFunkcije->connectDB;
		if ($dbh) {
			$sql = "select * FROM sfr_project_trr, sfr_bank";
			$sql.= " where id_vrstica=? AND sfr_bank.id_bank=sfr_project_trr.id_bank";

			$sth = $dbh->prepare($sql);
			$sth->execute($id_vrstica);
			if($res = $sth->fetchrow_hashref) {
					
				$trr=DntFunkcije::trim($res->{'id_trr'});
				$poobl=DntFunkcije::trim($res->{'id_project_poobl'});
				$banka=DntFunkcije::trim($res->{'id_bank'});
				#$opis=DntFunkcije::trim($res->{'opis_storitve'});
				
			}
			$sql="SELECT * ".
				 "FROM sfr_bank";
			
			$sth = $dbh->prepare($sql);
			$sth->execute();
			while ($res = $sth->fetchrow_hashref) {
				if($banka==$res->{'id_bank'}){
					$selected="selected='selected'";
				}
				else{
					$selected="";
				}
				
				my %row = (				
					id_bank => DntFunkcije::trim($res->{'id_bank'}),
					name => DntFunkcije::trim($res->{'bank_name'}),
					selected => $selected,	
					);

					# put this row into the loop by reference             
					push(@loop, \%row);
			}
			$sql="SELECT id_vrstice, sfr_project_pay_type.debit_type,".
				" name_pay_type, id_trr ".
				" FROM sfr_project_pay_type, sfr_pay_type ".
				" WHERE id_project=? AND id_trr='$id_vrstica'".
				" AND sfr_project_pay_type.debit_type=sfr_pay_type.debit_type".
				" ORDER BY debit_type";
			
			$sth = $dbh->prepare($sql);
			$sth->execute($id);
			my $i=0;
			my @debit;
			while ($res = $sth->fetchrow_hashref) {
				
				$debit[$i++]=DntFunkcije::trim($res->{'debit_type'});
				my %row = (				
					debit_type => DntFunkcije::trim($res->{'debit_type'}),
					name => DntFunkcije::trim($res->{'name_pay_type'}),
					id => DntFunkcije::trim($res->{'id_vrstice'}),
					
					);

					# put this row into the loop by reference             
					push(@loop3, \%row);
			}
			$sql="SELECT * ".
			 "FROM sfr_pay_type";
			my $debitTyp=0;
			$sth = $dbh->prepare($sql);
			$sth->execute();
			while ($res = $sth->fetchrow_hashref) {
				$debitTyp=1;
				foreach $i (@debit){
					
					if($i =~ DntFunkcije::trim($res->{'debit_type'})){
						$debitTyp=0; 	
					}
					
				}
				if($debitTyp==1){
					
					my %row = (				
						debit_type => DntFunkcije::trim($res->{'debit_type'}),
						name => DntFunkcije::trim($res->{'name_pay_type'}),
						
						);
	
						# put this row into the loop by reference             
						push(@loop2, \%row);
				}
			}
		}		
		
		else{
			return 'Povezava do baze ni uspela';
		}
		
		$template->param(
				edb_id => $id,
				edb_id_vrstica => $id_vrstica,
				edb_trr => $trr,
				edb_poobl => $poobl,
				#edb_davcna => $davcna,
				#edb_upnik => $upnik,
				#edb_opis => $opis,
				edb_uredi=> $uredi,
				edb_loop=> \@loop,
				edb_loop2=> \@loop2,
				edb_loop3=> \@loop3,
				
				#edb_readonly=> $readonly,
		);
                
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
}

sub ProjektiZbrisi(){
	
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
	my $id=$q->param('id_projekta');
	my $id_vrstica=$q->param('id_vrstica');
	my $sql2;
	my $sql3;
	

	if($source=~"projekt"){	
		
		$sql="DELETE FROM sfr_project WHERE ";
		$sql2="DELETE FROM sfr_project_pay_type WHERE ";
		$sql3="DELETE FROM sfr_project_trr WHERE ";	
		foreach $id (@deleteIds){
			if ($counter==0){
				$sql.="id_project='$id' ";
				$sql2.="id_project='$id' ";
				$sql3.="id_project='$id' ";
				$counter++;
			}
			$sql.="OR id_project='$id' ";
			$sql2.="OR id_project='$id' ";
			$sql3.="OR id_project='$id' ";
		}	
		$redirect_url="?rm=seznam";
	
		$dbh = DntFunkcije->connectDB;
		if($dbh){
			$sth = $dbh->prepare($sql2);
			$sth->execute();
			$sth = $dbh->prepare($sql3);
			$sth->execute();
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
	elsif($source=~"trr"){
		
		
		$sql2="DELETE FROM sfr_project_pay_type WHERE ";
		$sql3="DELETE FROM sfr_project_trr WHERE ";	
		foreach my $i (@deleteIds){
			if ($counter==0){
				
				$sql2.="id_trr='$i' ";
				$sql3.="id_vrstica='$i' ";
				$counter++;
			}
			
			$sql2.="OR id_trr='$i' ";
			$sql3.="OR id_vrstica='$i' ";
		}	
		$redirect_url="?rm=uredi&id=$id&uredi=1";
		
		$dbh = DntFunkcije->connectDB;
		if($dbh){
			$sth = $dbh->prepare($sql2);
			$sth->execute();
			$sth = $dbh->prepare($sql3);
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
	elsif($source=~"placilo"){
	$id=$q->param('edb_id');
	$id_vrstica=$q->param('id_trr');
	
		$sql2="DELETE FROM sfr_project_pay_type WHERE ";

		foreach $id (@deleteIds){
			if ($counter==0){

				$sql2.="id_vrstice='$id' ";
				$counter++;
			}
			$sql2.="OR id_vrstice='$id' ";

		}	
		$redirect_url="?rm=trr&id=$id&id_vrstica=$id_vrstica&uredi=1";
	
		$dbh = DntFunkcije->connectDB;
		if($dbh){
			$sth = $dbh->prepare($sql2);

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
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
	
}
#če uporabnik ni prijavljen:
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'Projekti';
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