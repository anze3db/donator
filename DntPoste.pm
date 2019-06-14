package DntPoste;
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
	
    my $user = DntFunkcije::AuthenticateSession(14, $nivo);
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
    #
	
	   
    $self->run_modes(
        'seznam' => 'PosteSeznam',
		'Prikazi' => 'PosteSeznam',
		'uredi' => 'PosteUredi',
		'Shrani' => 'PosteShrani',
		'zbrisi' => 'PosteZbrisi',
		'Preusmeri' => 'Preusmeri',
		'login' => 'Login',
		'error' => 'Error'

    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}



sub PosteSeznam{
	
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
	$self->param(testiram =>'rez');
	    
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntPosteSeznam.tmpl',
			      cache => 1,
			     );
    $template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'Seznam post',
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
			#if(length($ime)+length($st)>0){
			$sql = "select * FROM sfr_post";
			$sql.= " where 1=1";
			if($ime)
			{
				if ($poKorenuIme){
					$sql .= " and name_post ilike '%$ime%'";
					$poKorenuIme="checked='checked'";
				}
				else{
					$sql .= " and name_post ilike '$ime%'";
					$poKorenuIme="";
				}
			}
			
			if($st)
			{
					$sql .= " and CAST(id_post AS varchar) ilike '$st%'";
			}
			$sql.=" ORDER BY id_post";
			unless($ime || $st){
				$sql.=" LIMIT 18";
				$triPike="..."
			}
			$sth = $dbh->prepare($sql);
			$sth->execute();
			while ($res = $sth->fetchrow_hashref) {
					
				my %row = (				
					izbor => $q->a({-href=>"DntPoste.cgi?".
						"rm=uredi&id_poste=$res->{'id_post'}".
						"&seja=$seja&uredi=1"}, 'uredi'),
					ime => DntFunkcije::trim($res->{'name_post'}),
					id => DntFunkcije::trim($res->{'id_post'})
					
		  );

					# put this row into the loop by reference             
					push(@loop, \%row);
			}
			$template->param(donator_loop => \@loop,
					koren => DntFunkcije::trim($poKorenuIme),
					edb_ime => DntFunkcije::trim($ime),
					edb_triPike => $triPike,
					edb_st => DntFunkcije::trim($st));

			#}	
		}
		else{
			return 'Povezava do baze ni uspela';
		}
                
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}
sub PosteShrani{
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $html_output ;
	my $id_post = $q->param('edb_id');
	my $ime = $q->param('edb_ime');
	my $uporabnik = $q->param('edb_uporabnik');
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
			$sql = "UPDATE sfr_post SET name_post=?, velik_uporabnik=?".
					   "WHERE id_post=?";
			#print $q->p($sql_vprasaj);
				$sth = $dbh->prepare($sql);
				unless($sth->execute($ime, $uporabnik, $id_post)){
				
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
			
				
				$sql = "INSERT INTO sfr_post (id_post, name_post, velik_uporabnik) ".
					   "VALUES (?, ?, ?)";
			#print $q->p($sql_vprasaj);
				$sth = $dbh->prepare($sql);
				unless($sth->execute($id_post, $ime, $uporabnik)){
					
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
	

sub PosteUredi{
	my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');	
	my $html_output ;
	my $menu_pot;
	my $id_post= $q->param('id_poste');
	my $uredi=$q->param('uredi');
	my $imePoste;
	my $Vuporabnik;
	my $uporabnik= $q->param('uporabnik');
    my $template;
	my $disabled;

    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja=".$seja}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntPosteUredi.tmpl',
			      cache => 1,
			     );
    $template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'Posta',
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
			$sql = "select * FROM sfr_post";
			$sql.= " where id_post=?";

			$sth = $dbh->prepare($sql);
			$sth->execute($id_post);
			if($res = $sth->fetchrow_hashref) {
					
				$imePoste=DntFunkcije::trim($res->{'name_post'});
				$Vuporabnik=DntFunkcije::trim($res->{'velik_uporabnik'});
			}
		}	
					
		
		else{
			return 'Povezava do baze ni uspela';
		}
		
			$template->param(					
					edb_ime => $imePoste,
					edb_id => $id_post,
					edb_uporabnik => $Vuporabnik,
					edb_disabled => $disabled,
					edb_uredi=> $uredi);
                
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
}

sub PosteZbrisi(){
	
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $redirect_url;
	my @deleteIds=$q->param('izberiId');
	my $source=$q->param('brisi');
	my $template;
	my $html_output;
	my $counter=0;
	my $sql;
	my $sth;
	my $dbh;
	my $id=$q->param('id_placilo');
	

		
		
	$sql="DELETE FROM sfr_post WHERE ";
			
	foreach $id (@deleteIds){
		if ($counter==0){
			$sql.=" id_post='$id' ";
			$counter++;
		}
		else{
		$sql.=" OR id_post='$id' ";
		}
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
						#$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
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
	my $return_url= 'Poste';
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