package DntIzvoziDatoteke;
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
        'seznam' => 'IzvoziDatotekeSeznam',
		'Prikazi' => 'IzvoziDatotekeSeznam',
		'uredi' => 'IzvoziDatotekeUredi',
		'Shrani' => 'IzvoziDatotekeShrani',
		'zbrisi' => 'IzvoziDatotekeZbrisi',
		'output' => 'IzvoziDatotekeOutput',
		'login' => 'Login',
		'error' => 'Error'
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub IzvoziDatotekeSeznam{
	
    my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');
	my $prikazi = $q->param('prikazi') || "";
	my $html_output ;
	my @loop;
	my $menu_pot;
    my $template ;

    $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntIzvoziDatoteke.tmpl',
			      cache => 1,
			     );
    $template->param(
		     #MENU_POT => $menu_pot,
			 IME_DOKUMENTA => "Seznam izvozenih datotek",
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
		$sql = "select id, filename, date FROM datoteke_izvozene";
		$sql.=" ORDER BY date DESC ";
		if($prikazi ne "vse"){
			$prikazi = "(".$q->a({-href=>"?rm=seznam&prikazi=vse",
							  -title=>"Prikazi vse"}, "Prikazi vse").")";
			$sql.= " LIMIT 10";
		}
		else{
			
			$prikazi = "";
		}
		
		
		$sth = $dbh->prepare($sql);
		$sth->execute();
		while ($res = $sth->fetchrow_hashref) {
				
			my %row = (				
								ime => $q->a({-href=>"?rm=output&id=$res->{'id'}"},
							 $res->{'filename'}),
				
				datum => DntFunkcije::sl_date_ura($res->{'date'}),
				id => DntFunkcije::trim($res->{'id'})	
				);

				# put this row into the loop by reference             
				push(@loop, \%row);
		}
		$template->param(donator_loop => \@loop,
						 prikazi => $prikazi,
						 )

	}
	else{
		return 'Povezava do baze ni uspela';
	}

    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}

sub IzvoziDatotekeZbrisi(){
	
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
	my $id=$q->param('id_IzvoziDatoteke');		
	$sql="DELETE FROM datoteke_izvozene WHERE ";
			
	foreach $id (@deleteIds){
		if ($counter==0){
			$sql.="id='$id' ";
			$counter++;
		}
		$sql.="OR id='$id' ";
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
sub IzvoziDatotekeOutput(){
	my $self = shift;
	my $q = $self->query();
	my $seja = $q->param('seja');
	my $redirect_url;
	my $id=$q->param('id');
	my $template;
	my $html_output;
	my $counter=0;
	my $sql;
	my $sth;
	my $res;
	my $dbh;
	my $filename;
	my $content;
	$sql="SELECT * FROM datoteke_izvozene WHERE id=?";
	$dbh = DntFunkcije->connectDB;
	if($dbh){
		$sth = $dbh->prepare($sql);
		$sth->execute($id);
		while ($res = $sth->fetchrow_hashref) {
			
			$filename = $res->{filename};
			$content = $res->{content};
		}
	}
	
	#$q->header(-type=>'application/octet-stream', -attachment=>$filename);	
	print "Content-Disposition: attachment; filename=$filename\n\n";
	my @vrstice = split(/\n/,$content);
	foreach (@vrstice){
		if(($_ !~ /^#/)){
			print $_."\n";
		}
	}
	$self->header_type('none');
	return "";
}
	
}
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'IzvoziDatoteke';
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
