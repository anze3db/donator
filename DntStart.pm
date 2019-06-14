#Prijava;
package DntStart;
use strict;
use base 'CGI::Application';
use Digest::MD5 qw(md5_hex);
use DntQuery;
use DntFunkcije;
use Apache::Constants ':response';

sub handler ($$) {
 my ($pkg, $r) = @_;

 #use DntDonatorji;
 # Instantiate and run() your CGI::Application module
 my @pkgs = split('.cgi', $ENV{REQUEST_URI});
 $pkg = substr($pkgs[0], 1);
 
 if($pkg eq "outputHandler"){
	do "outputHandler.pm";
 }
 elsif($pkg eq "fileHandler"){
	do "fileHandler.pm";
 }
 else{
    if($pkg eq "")
    {
      $pkg = "DntStart";
    }
	eval "use $pkg;";	
	my $self = $pkg->new(QUERY => DntQuery->new($r));
	$self->run();
 }

 return OK;
}
sub setup {
	
    my $self = shift;	
	my $seja;
	
	$self->start_mode('index');

    $self->run_modes(
        'index' => 'SfrDonatorji',
		'Donatorji' => 'SfrDonatorji',
		'Pogodbe' => 'SfrPogodbe',
		'Zaposleni' => 'SfrZaposleni',
		'Poste' => 'SfrPoste',
		'Dogodki' => 'SfrDogodki',
		'Placila' => 'SfrPlacila',
		'Banke' => 'SfrBanke',
		'Projekti' => 'SfrProjekti',
		'Pole' => 'SfrPole',
		'uvozi_dz' => 'UvoziDz',
		'Obroki' => 'Obroki',
		'isci' => 'Isci',
		'Opomini' => 'Opomini',
		'IzvoziObroke' => 'IzvoziObroke',
		'uporabniki' => 'Uporabniki',
		'Potrdila' => 'Potrdila',
		'uporabnikiLog' => 'Uporabniki_log',
		'opozorila' => 'Opozorila',
		'obracun' => 'Obracun',
		'zahtevki' => 'Zahtevki',
		'vzdrzevanje' => 'Vzdrzevanje',
		'IzvozeneDatoteke' => 'IzvozeneDatoteke',
		'dbr' => 'DirektneBremenitve',
    );
}

sub index{
	
    my $self = shift;
    my $q = $self->query();
	my $html_output;
	my $menu_pot;
    my $soUporabniki;
	my $template;
	my $uporabnik;
    
	my $seja;
	my $sql;
	my $sth;
	my $res;
	my $dbh;
	
    
    $dbh = DntFunkcije->connectDB;
    if ($dbh) {
		
        $sql = "SELECT * FROM uporabniki";
            $sth = $dbh->prepare($sql);
        
            $sth->execute();
        #    my $session;# = $self->param('session');
        #	my $seja= $q->param('seja');
        #	
        #    $session = new CGI::Session("driver:File", $seja,undef);# {Directory=>'/tmp'});
        #    $session = CGI::Session->load( $seja );
        #	$uporabnik = $session->param('uporabnik');
        #	#$self->param(-name=>'xuporabnik', -value=>'tj je iks');
        #	$q->param('uporabnik', $uporabnik);
        #	$q->param('id_seja', $seja);
        #	$self->param(-name=>'uporabnik', -value=>$session->param('uporabnik'));
        #	#return 'one two'.$seja.' in:'.$session->param('uporabnik').' '.$self->param('id_seja');
        
        if($res = $sth->fetchrow_hashref) #ce smo dobil vrstico
            {
            #ker najde uporabnike, se link za registracijo ne bo pokazal
            $q->param(-name=>'SoUporabniki', -value =>'1');
            $soUporabniki = '1';
        }
            else{
            #Ker v tabeli uporabnikov ni se nihce vpisan se pokaze link za registracijo
            #prvega uporabnika
            $q->param(-name=>'SoUporabniki', -value =>'0');
            $soUporabniki = '0';		
            }
            
            $template = $self->load_tmpl(	    
                                  'DntStart.tmpl',
                                  cache => 1,
                                 );	
        # Fill in some parameters
            
        #$menu_pot = $q->a({-href=>"prijava.cgi?rm=logout"}, "Odjava")  ;
            
        $template->param(
                         MENU_POT => $menu_pot,
                             IME_DOKUMENTA => 'Donator',
                             uporabnik => $uporabnik
        #			 seja => $seja,
                         );
        # Parse the template
            
        $html_output = $template->output;
        return $html_output;
    }
    else{
        return 'Napaka. Povezava do baze ni uspela ';
    }
    
}
sub DirektneBremenitve{
	my $self = shift;
	my $template = $self->load_tmpl('DntBremenitve.tmpl', cache => 1,);
        $template->param(
                POMOC => "<input type='button' value='?' ".
                "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
        );

        return $template->output;
}
sub SfrDonatorji(){
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	my $redirect_url= '/DntDonatorji.cgi?rm=seznam&seja=';
	my $seja;
	my $uporabnik;
	my $result=0;
	my $sql;
	my $sth;
	my $res;
	my $dbh;
	
	#my $uporabnik;
	#my $result=0;
	#my $sql;
	#my $sth;
	#my $res;
	#my $dbh;
	#my $redirect_url="DntPrijava.cgi?rm=prijavi";
	#$seja = DntFunkcije::Piskotki('id');
	#$dbh = DntFunkcije->connectDB;
	#if ($dbh) {
	#	$sql = "SELECT * FROM uporabniki ORDER BY id_uporabnik ASC";
	#	$sth = $dbh->prepare($sql);
	#	$sth->execute();
	#	while($res = $sth->fetchrow_hashref) {
	#		if(md5_hex(DntFunkcije::trim($res->{'uporabnik'}).DntFunkcije::trim($res->{'geslo'})) eq $seja){
	#			$uporabnik=$res->{'uporabnik'};
	#			$result=1;
	#		}
	#		
	#		
	#	}
	#	if($result!=1){
	#		$self->header_type('redirect');
	#		$self->header_props(-url => $redirect_url);
	#		return $redirect_url;
	#	}
	#}
	
	#$uporabnik = $q->param('uporabnik');
	##$redirect_url .= $seja; # .'&uporabnik='.$uporabnik;
	#
	#$session->param();
	#return 'klik na register'.($session->param('uporabnik'));
	#
		
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
}

sub SfrPogodbe(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntPogodbe.cgi?rm=seznam&seja=';
	my $seja;
	my $uporabnik;
	
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja;
	

	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	return $redirect_url;
}

sub SfrZaposleni(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntZaposleni.cgi?rm=seznam&seja=';
	
	my $seja="";
	my $uporabnik;

	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}

sub SfrPoste(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntPoste.cgi?rm=seznam&seja=';
	my $seja;
	my $uporabnik;
	
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}
sub SfrDogodki(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntDogodki.cgi?rm=seznam&seja=';
	
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}
sub SfrPlacila(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntPlacila.cgi?rm=seznam&seja=';
	
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}


sub SfrBanke(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntBanke.cgi?rm=seznam&seja=';
	
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}

sub SfrProjekti(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntProjekti.cgi?rm=seznam&seja=';
	
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}
sub SfrPole(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntPole.cgi?rm=seznam&seja=';
	
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}

sub UvoziDz(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntDavcniZavezanci.cgi?rm=IzberiDatoteko';
	
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}
sub Obroki(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntObroki.cgi?rm=seznam';
	
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
}

sub Isci(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntIsci.cgi?rm=seznam';
	
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}

sub Opomini(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntOpomini.cgi?rm=zacetek';
	
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}

sub IzvoziObroke(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntIzvoziObroke.cgi?rm=zacetek';
	
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}

sub Uporabniki(){
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntUporabniki.cgi?rm=seznam';
	
	my $seja;
	my $uporabnik;
		
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}

sub Potrdila(){
	
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntPotrdila.cgi?rm=zacetek';
	
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}

sub Uporabniki_log(){
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntUporabnikiLog.cgi?rm=seznam';
	
	my $seja;
	my $uporabnik;
		
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}
sub Opozorila(){
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntOpozorila.cgi?rm=seznam';
	
	my $seja;
	my $uporabnik;
		
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}

sub Obracun(){
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntObracun.cgi?rm=seznam';
	
	my $seja;
	my $uporabnik;
		
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}

sub Zahtevki(){
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntZahtevki.cgi?rm=seznam';
	
	my $seja;
	my $uporabnik;
		
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}
sub Vzdrzevanje(){
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntVzdrzevanje.cgi?rm=seznam';
	
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}

sub IzvozeneDatoteke(){
	my $self = shift;
	my $q = $self->query();
	#my $redirect_url= '/cgi-bin/SldPripraviZaProizvodnjo.cgi?seja=';#.$self->param('id_seja');
	#my $redirect_url= '/cgi-bin/DntPogodbe.cgi?rm=seznam&seja=';
	my $redirect_url= '/DntIzvoziDatoteke.cgi?rm=seznam';
	
	my $seja;
	my $uporabnik;
	$seja = $q->param('seja');
	$uporabnik = $q->param('uporabnik');
	#$redirect_url .= $seja; 
	
	$self->header_type('redirect');
	
	$self->header_props(-url => $redirect_url);
	
	
}








1;    # Perl requires this at the end of all modules
