package DntBanke;
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
	if ($str eq 'Shrani'|| $str eq 'zbrisi' || $str eq 'uredi'){
		$nivo = 'w';
	}
	
    my $user = DntFunkcije::AuthenticateSession(17, $nivo);
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
        'seznam' => 'BankeSeznam',
		'Prikazi' => 'BankeSeznam',
		'uredi' => 'BankeUredi',
		'Shrani' => 'BankeShrani',
		'zbrisi' => 'BankeZbrisi',
		'login' => 'Login',
		'error' => 'Error'
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub BankeSeznam{
	
    my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');	
	my $html_output ;
	my $ime= $q->param('edb_ime');
	my $tn= $q->param('edb_tn');
	my $sifra= $q->param('edb_sifra'); 
	my @loop;
	my $menu_pot;
	my $poKorenuIme= $q->param('po_korenu_ime');
	my $id= $q->param('edb_id');
	my $uporabnik= $q->param('uporabnik');
    my $template ;
	my $triPike;
	unless ($uporabnik){
		$uporabnik="";
	}
	$self->param(testiram =>'rez');
	
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=$seja"}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntBankeSeznam.tmpl',
			      cache => 1,
			     );
    $template->param(
		     #MENU_POT => $menu_pot,
			 IME_DOKUMENTA => "Seznam bank".$uporabnik,
			 POMOC => "<input type='button' value='?'".
			 "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
			 MENU => DntFunkcije::BuildMenu()
		     );
	#Ce so se parametri za poizvedbo izpise rezultat
	
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	
	my $hid_sort = $q->param("hid_sort");
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		#if(length($ime)+length($id)+length($tn)+length($sifra)>0){
			$sql = "select * FROM sfr_bank";
			$sql.= " where 1=1";
			if($ime)
			{				
				if ($poKorenuIme==1){					
					$sql .= " and bank_name ilike '%$ime%'";
					$poKorenuIme="checked='checked'";
				}
				else{
					$sql .= " and bank_name ilike '$ime%'";
					$poKorenuIme="";
				}
			}
			
			if($id)
			{
					$sql .= " and id_bank  = $id";
			}
			if($tn)
			{
					$sql .= " and bank_tn  ilike '$tn%'";
			}
			if($sifra)
			{
					$sql .= " and sifra_banke ilike '$sifra%'";
			}
			$sql.=" ORDER BY id_bank DESC";
			unless($ime || $id || $tn || $sifra){
				$sql.=" LIMIT 16";
				$triPike="..."
			}
			
			$sth = $dbh->prepare($sql);
			$sth->execute();
			while ($res = $sth->fetchrow_hashref) {
					
				my %row = (				
					izbor => $q->a({-href=>"DntBanke.cgi?".
						"rm=uredi&id=$res->{'id_bank'}".
						"&seja=$seja&uredi=1"}, 'uredi'),
					ime => DntFunkcije::trim($res->{'bank_name'}),
					tn => DntFunkcije::trim($res->{'bank_tn'}),
					sifra => DntFunkcije::trim($res->{'sifra_banke'}),
					id => DntFunkcije::trim($res->{'id_bank'})					
		  );

					# put this row into the loop by reference             
					push(@loop, \%row);
			}
			$template->param(donator_loop => \@loop,					
					edb_ime => DntFunkcije::trim($ime),
					edb_id => DntFunkcije::trim($id),
					edb_tn => DntFunkcije::trim($tn),
					edb_sifra => DntFunkcije::trim($sifra),
					koren => $poKorenuIme,
					edb_triPike => $triPike);
	}
	else{
		return 'Povezava do baze ni uspela';
	}

    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}
sub BankeShrani{
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id = $q->param('edb_id');
	my $ime = $q->param('edb_ime');
	my $tn = $q->param('edb_tn');
	my $sifra = $q->param('edb_sifra');
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
		
			$sql = "UPDATE sfr_bank SET bank_tn=?, bank_name=?, sifra_banke=? ".
				   "WHERE id_bank=?";
		
			#print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			unless($sth->execute($tn, $ime, $sifra, $id)){
			
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
			
			$sql = "INSERT INTO sfr_bank (bank_tn, bank_name, sifra_banke) ".
				   "VALUES (?, ?, ?)";
			#print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			unless($sth->execute($tn, $ime, $sifra)){
				
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
	

sub BankeUredi{
	my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');	
	my $html_output ;
	my $menu_pot;
	my $id= $q->param('id');
	my $uredi=$q->param('uredi');
	my $ime;
	my $tn;
	my $sifra;
	my $uporabnik= $q->param('uporabnik');
    my $template;
	my $disabled;

    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntBankeUredi.tmpl',
			      cache => 1,
			     );
    $template->param(
			#MENU_POT => $menu_pot,
			IME_DOKUMENTA => 'Banka',
			POMOC => "<input type='button' value='?' ".
			"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),			 
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
		
	my $hid_sort = $q->param("hid_sort");
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		
		$sql = "select * FROM sfr_bank";
		$sql.= " where id_bank=?";
		$sth = $dbh->prepare($sql);
		$sth->execute($id);
		if($res = $sth->fetchrow_hashref) {				
			$ime=DntFunkcije::trim($res->{'bank_name'});
			$tn=DntFunkcije::trim($res->{'bank_tn'});
			$sifra=DntFunkcije::trim($res->{'sifra_banke'});			
		}
	}
	
	else{
		return 'Povezava do baze ni uspela';
	}
	
		$template->param(					
				edb_ime => $ime,
				edb_id => $id,
				edb_tn => $tn,
				edb_sifra => $sifra,
				edb_uredi=> $uredi);
			

    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
}

sub BankeZbrisi(){
	
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
	my $id=$q->param('id_banke');		
		
	$sql="DELETE FROM sfr_bank WHERE ";
			
	foreach $id (@deleteIds){
		if ($counter==0){
			$sql.="id_bank='$id' ";
			$counter++;
		}
		$sql.="OR id_bank='$id' ";
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
	
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
	
}
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'Banke';
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