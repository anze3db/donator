package DntDogodki;
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
	
    my $user = DntFunkcije::AuthenticateSession(15, $nivo);
	
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
        'seznam' => 'DogodkiSeznam',
		'Prikazi' => 'DogodkiSeznam',
		'uredi' => 'DogodkiUredi',
		'Shrani' => 'DogodkiShrani',
		'zbrisi' => 'DogodkiZbrisi',
		'login' => 'Login',
		'error' => 'Error'
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub DogodkiSeznam{
	
    my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');
	
	my $html_output ;
	my $ime= $q->param('edb_ime');
	my @loop;
	my $menu_pot;
	my $poKorenuIme= $q->param('po_korenu_ime');
	my $id_event= $q->param('edb_id');
	my $uporabnik= $q->param('uporabnik');
    my $template ;
	my $triPike;
	
	$self->param(testiram =>'rez');
	    
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntDogodkiSeznam.tmpl',
			      cache => 1,
			     );
    $template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'Seznam dogodkov',
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
			#if(length($ime)+length($id_event)>0){
			$sql = "select * FROM sfr_events";
			$sql.= " where 1=1";
			if($ime)
			{				
				if ($poKorenuIme==1){
					
					$sql .= " and name_event ilike '%$ime%'";
					$poKorenuIme="checked='checked'";
				}
				else{
					$sql .= " and name_event ilike '$ime%'";
					$poKorenuIme="";
				}
			}
			
			if($id_event)
			{
				$sql .= " and id_event ilike '$id_event%'";
			}
			$sql.=" ORDER BY id_event ";
			unless($ime || $id_event){
				$sql.=" LIMIT 17";
			}
			$sth = $dbh->prepare($sql);
			$sth->execute();
			while ($res = $sth->fetchrow_hashref) {
					
				my %row = (				
					izbor => $q->a({-href=>"DntDogodki.cgi?".
						"rm=uredi&id_event=$res->{'id_event'}".
						"&seja=$seja&uredi=1"}, 'uredi'),
					ime => DntFunkcije::trim($res->{'name_event'}),
					id => DntFunkcije::trim($res->{'id_event'})					
				);
				# put this row into the loop by reference             
				push(@loop, \%row);
			}
			$template->param(donator_loop => \@loop,					
					edb_ime => DntFunkcije::trim($ime),
					edb_id => DntFunkcije::trim($id_event),
					koren => $poKorenuIme,
					edb_triPike=> $triPike);
		#}	
		}
		else{
			return 'Povezava do baze ni uspela';
		}
                
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}
sub DogodkiShrani{
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id_event = $q->param('edb_id');
	my $ime = $q->param('edb_ime');
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
		$sql = "UPDATE sfr_events SET name_event=?".
				   "WHERE id_event=?";
		#print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			unless($sth->execute($ime, $id_event)){
			
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
		
			
			$sql = "INSERT INTO sfr_events (id_event, name_event) ".
				   "VALUES (?, ?)";
		#print $q->p($sql_vprasaj);
			$sth = $dbh->prepare($sql);
			unless($sth->execute($id_event, $ime)){
				
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
	

sub DogodkiUredi{
	my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');	
	my $html_output ;
	my $menu_pot;
	my $id_event= $q->param('id_event');
	my $uredi=$q->param('uredi');
	my $ime;
	my $uporabnik= $q->param('uporabnik');
    my $template;
	my $disabled;

    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntDogodkiUredi.tmpl',
			      cache => 1,
			     );
    $template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'Dogodek',
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
		$sql = "select * FROM sfr_events";
		$sql.= " where id_event=?";

		$sth = $dbh->prepare($sql);
		$sth->execute($id_event);
		if($res = $sth->fetchrow_hashref) {
				
			$ime=DntFunkcije::trim($res->{'name_event'});
			
		}
	}	
	else{
		return 'Povezava do baze ni uspela';
	}	
	$template->param(					
		edb_ime => $ime,
		edb_id => $id_event,
		edb_disabled => $disabled,
		edb_uredi=> $uredi
	);
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
}

sub DogodkiZbrisi(){
	
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
	my $id=$q->param('id_placilo');	

	$sql="DELETE FROM sfr_events WHERE ";

	foreach $id (@deleteIds){
		if ($counter==0){
			$sql.="id_event='$id' ";
			$counter++;
		}
		$sql.="OR id_event='$id' ";
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

#če uporabnik ni prijavljen:
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'Dogodki';
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