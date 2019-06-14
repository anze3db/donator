package DntOpozorila;
use base 'CGI::Application';
#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use strict;
use DBI;
#use HTML::Template;
#use CGI::Session;
#use Data::Dumper;
use DntFunkcije;
use Digest::MD5 qw(md5_hex);

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
        'seznam' => 'OpozorilaSeznam',
		'Prikazi' => 'OpozorilaSeznam',
		'uredi' => 'OpozorilaUredi',
		'Shrani' => 'OpozorilaShrani',
		'zbrisi' => 'OpozorilaZbrisi',
		'Preusmeri' => 'Preusmeri',
		'login' => 'Login',
		'error' => 'Error'
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub OpozorilaSeznam{
	
    my $self = shift;
    my $q = $self->query();	
	my $seja= $q->param('seja');	
	my $html_output ;
	my $don_klic = $q->param('don_klic');
	my $don_kom = $q->param('don_kom');
	my $zaposleni = $q->param('zaposleni');
	my $pogodba = $q->param('pogodba');
	my $datum = $q->param('date');
	my $mode = $q->param('mode');
	my @loop;
	my @loop2;
	my @loop3;
	my @loop4;
	my $menu_pot;
	my $triPike;
	my $uporabnik= $q->param('uporabnik');
    my $template ;
	$self->param(testiram =>'rez');
	my $datum_sl;
	my $dbh;
	my $res;
	my $sql;
	my $sth;   
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
		'DntOpozorilaSeznam.tmpl',
		 cache => 1,
   );
	if(!defined $mode){
		$don_klic = 1;
		$don_kom = 1;
		$zaposleni = 1;
		$pogodba = 1;
		
	}
	if(defined $datum && $datum =~ m/\d{2}\/\d{2}\/\d{4}.*/){
		$datum_sl = $datum;
		$datum = substr($datum,6,4)."-".substr($datum, 3, 2)."-".substr($datum, 0, 2);
	}
	else{
		
		($datum, my $cas) = DntFunkcije->time_stamp();
		$datum_sl = substr($datum,8,2)."/".substr($datum,5,2)."/".substr($datum,0,4);

	}

    $template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'Seznam opozoril',
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		MENU => DntFunkcije::BuildMenu(),
		kli_chk => $don_klic,
		kom_chk => $don_kom,
		zap_chk => $zaposleni,
		pog_chk => $pogodba,
		today => $datum_sl,
	);
	#Ce so se parametri za poizvedbo izpise rezultat


		
		my $hid_sort = $q->param("hid_sort");
		$dbh = DntFunkcije->connectDB;
		
		if ($dbh) {
			#if(length($ime)+length($st)>0){
			if($don_klic == 1){
				$sql = "SELECT * FROM sfr_donor_call as a, sfr_donor_phone as b ".
					   "WHERE a.id_phone = b.id_vrstice";
				if(!(defined $mode && $mode eq "Prikazi vse")){
					$sql .=" AND date='$datum'";
				}

				$sth = $dbh->prepare($sql);
				$sth->execute();

				my $crt = 0;
				while ($res = $sth->fetchrow_hashref) {
					my $naslov;
					my %row = (				
						povezava => $q->a({-href=>"DntDonatorji.cgi?".
							"rm=uredi_donatorja&id_donor=$res->{'id_donor'}"}, 'povezava'),
						alarm => DntFunkcije::sl_date($res->{'date'}),
						comment_alarm => DntFunkcije::trim($res->{'comment'}),
						phone_num => DntFunkcije::trim($res->{'phone_num'}),
							);
					# put this row into the loop by reference             
					push(@loop, \%row);
				}
				my $loop = @loop;
				if($loop == 0){
					my %row = (				
						sporocilo => "<td colspan=4>Ni opozoril.</td>"
					);
					# put this row into the loop by reference           
					push(@loop, \%row);
					
				}
			}
			if($don_kom == 1){
			
				$sql = "SELECT * FROM sfr_donor_comment ".
					   "WHERE alarm_active='1' ";
				if(!(defined $mode && $mode eq "Prikazi vse")){
					$sql .=" AND alarm='$datum'";
				}

				
				$sth = $dbh->prepare($sql);
				$sth->execute();
				my $crt = 0;
				while ($res = $sth->fetchrow_hashref) {

					my %row = (				
						povezava => $q->a({-href=>"DntDonatorji.cgi?".
							"rm=uredi_donatorja&id_donor=$res->{'id_donor'}"}, 'povezava'),
						alarm => DntFunkcije::sl_date($res->{'alarm'}),
						comment_alarm => DntFunkcije::trim($res->{'comment_alarm'}),

					);
					# put this row into the loop by reference             
					push(@loop2, \%row);
				}
				my $loop2 = @loop2;
				if($loop2 == 0){
					my %row = (				
						sporocilo => "<td colspan=3>Ni opozoril.</td>"
					);
					# put this row into the loop by reference           
					push(@loop2, \%row);
					
				}
			}
			if($zaposleni == 1){
			
				$sql = "SELECT * FROM sfr_staff_comment ".
					   "WHERE alarm_active='1' ";
				if(defined $mode && $mode ne "Prikazi vse"){
					$sql .=" AND alarm='$datum'";
				}

				
				$sth = $dbh->prepare($sql);
				$sth->execute();
				my $crt = 0;
				while ($res = $sth->fetchrow_hashref) {

					my %row = (				
						povezava => $q->a({-href=>"DntZaposleni.cgi?".
							"rm=uredi&id_staff=18&seja=&uredi=$res->{'id_staff'}"}, 'povezava'),
						alarm => DntFunkcije::sl_date($res->{'alarm'}),
						comment_alarm => DntFunkcije::trim($res->{'comment_alarm'}),
					);
					# put this row into the loop by reference             
					push(@loop3, \%row);
				}
				my $loop3 = @loop3;
				if($loop3 == 0){
					my %row = (				
						sporocilo => "<td colspan=3>Ni opozoril.</td>"
					);
					# put this row into the loop by reference           
					push(@loop3, \%row);
					
				}
			}
			if($pogodba == 1){
			
				$sql = "SELECT * FROM sfr_agreement_comment ".
					   "WHERE alarm_active='1' ";
				if(!(defined $mode && $mode eq "Prikazi vse")){
					$sql .=" AND alarm='$datum'";
				}

				
				$sth = $dbh->prepare($sql);
				$sth->execute();
				my $crt = 0;
				while ($res = $sth->fetchrow_hashref) {
					my %row = (				
						povezava => $q->a({-href=>"DntPogodbe.cgi?".
							"rm=uredi_pogodbo&seja=&uredi=1&id_agreement=$res->{'id_agreement'}"}, 'povezava'),
						alarm => DntFunkcije::sl_date($res->{'alarm'}),
						comment_alarm => DntFunkcije::trim($res->{'comment_alarm'}),
					);
					# put this row into the loop by reference             
					push(@loop4, \%row);
				}
				my $loop4 = @loop4;
				if($loop4 == 0){
					my %row = (				
						sporocilo => "<td colspan=3>Ni opozoril.</td>"
					);
					# put this row into the loop by reference             
					push(@loop4, \%row);
					
				}
			}
			$template->param(donator_loop => \@loop,
							 donator_loop2 => \@loop2,
							 donator_loop3 => \@loop3,
							 donator_loop4 => \@loop4,);

			#}	
		}
		else{
			return 'Povezava do baze ni uspela';
		}
                
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}
1;    # Perl requires this at the end of all modules