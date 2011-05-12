package DntDavcniZavezanci;
use base 'CGI::Application';
#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use strict;
#use HTML::Template;
#use CGI::Session;
#use Data::Dumper;
use DntFunkcije;

#use Text::Iconv;
sub setup {
    my $self = shift;
    #$self->dbh_config("dbi:PgPP:dbname=donator;host=localhost", "postgres", "ni2mysql");
    $self->start_mode('IzberiDatoteko');
    $self->run_modes(
        'IzberiDatoteko' => 'IzberiDatoteko',
		'Precitaj' => 'PrecitajDatoteko',
		'Uvozi' => 'UvoziDatoteko',
        'Nepotrjene_datoteke' => 'NepotrjeneDatoteke',
        'prikazi_vsebino' => 'PrikaziVsebinoDatoteke'
    );
	
}

sub IzberiDatoteko(){
    my $self = shift;
    my $q = $self->query();
    my $seja  ;
    my $html_output;
    my $template;
	my $dodaj="";
    $template = $self->load_tmpl(	    
	'DntBranjeDatotekIzberiDatoteko.tmpl',
	cache => 1,
	);
    $template->param(
	MENU_POT => '',
	IME_DOKUMENTA => "Uvoz iz datoteke", 
	POMOC => "<input type='button' value='?' ".
	"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
    );
	if($q->param('dodano')){
	$dodaj= "<strong>Davcni zavezanci so bili uspesno vneseni!</strong>";
	}
	opendir(FOLDIR, "../../files") || Error('open', 'directory' );
	my @dir=readdir(FOLDIR);
	closedir(FOLDIR);
	
	my @loop;
	my $i=0;
	foreach (@dir){
		if($i>1){
		my %row=(file=>$_,
				 link=>"<a href='?rm=Precitaj&amp;izvor=dz&amp;edb_datoteka=$_'>precitaj</a>"
				 );
		push(@loop, \%row);
		}
		else{
			$i++;
		}
	}
	$template->param(
	MENU_POT => '',
	IME_DOKUMENTA => 'Uvoz iz datoteke',
	POMOC => "<input type='button' value='?' ".
	"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
	DODANO => $dodaj,
	loop => \@loop,
    );
    $html_output = $template->output; #.$tabelica;
    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
    return $html_output;
	
}

sub Znaki(){
	
	my $utf8;
	my $ansi;
	my $i=0;
	my $izpis;
	
	open(FILE1, "../../files/utf8.txt");
	open(FILE2, "../../files/ansi.txt");
	while ($utf8 = <FILE1>){
		$ansi = <FILE2>;
		if($i==0){
			$i++;
		}
		else{
			$izpis.= '
			elsif($_ eq chr('.ord(substr($ansi, 0, 1)).')) {
			$besedilo.=chr('.ord(substr($utf8, 0, 1)).
			').chr('.ord(substr($utf8, 1, 1)).'); } #'.
			chr(ord(substr($ansi, 0, 1)))."(".substr($utf8, 0, 1).
			substr($utf8, 1, 1).")<br />";			
		}
	}
	close(FILE1);
	close(FILE2);
	return $izpis;	
}

sub Sumniki($){
	my $besedilo = shift;
	my $b;
	return length($besedilo);
	my @b = split(//, $besedilo);
	$besedilo="";
	
	foreach (@b){
		if($_ eq chr(138)) { $besedilo.=chr(197).chr(160); } #�(Š)
		elsif($_ eq chr(139)) { $besedilo.=chr(226).chr(128); } #�(�)
		elsif($_ eq chr(140)) { $besedilo.=chr(197).chr(154); } #�(Ś)
		elsif($_ eq chr(141)) { $besedilo.=chr(197).chr(164); } #�(Ť)
		elsif($_ eq chr(142)) { $besedilo.=chr(197).chr(189); } #�(Ž)
		elsif($_ eq chr(143)) { $besedilo.=chr(197).chr(185); } #�(Ź)
		elsif($_ eq chr(154)) { $besedilo.=chr(197).chr(161); } #�(š)
		elsif($_ eq chr(156)) { $besedilo.=chr(197).chr(155); } #�(ś)
		elsif($_ eq chr(157)) { $besedilo.=chr(197).chr(165); } #�(ť)
		elsif($_ eq chr(158)) { $besedilo.=chr(197).chr(190); } #�(ž)
		elsif($_ eq chr(159)) { $besedilo.=chr(197).chr(186); } #�(ź)
		elsif($_ eq chr(161)) { $besedilo.=chr(203).chr(135); } #�(ˇ)
		elsif($_ eq chr(162)) { $besedilo.=chr(203).chr(152); } #�(˘)
		elsif($_ eq chr(163)) { $besedilo.=chr(197).chr(129); } #�(Ł)
		elsif($_ eq chr(164)) { $besedilo.=chr(194).chr(164); } #�(¤)
		elsif($_ eq chr(165)) { $besedilo.=chr(196).chr(132); } #�(Ą)
		elsif($_ eq chr(166)) { $besedilo.=chr(194).chr(166); } #�(¦)
		elsif($_ eq chr(167)) { $besedilo.=chr(194).chr(167); } #�(§)
		elsif($_ eq chr(168)) { $besedilo.=chr(194).chr(168); } #�(¨)
		elsif($_ eq chr(169)) { $besedilo.=chr(194).chr(169); } #�(©)
		elsif($_ eq chr(170)) { $besedilo.=chr(197).chr(158); } #�(Ş)
		elsif($_ eq chr(171)) { $besedilo.=chr(194).chr(171); } #�(«)
		elsif($_ eq chr(172)) { $besedilo.=chr(194).chr(172); } #�(¬)
		elsif($_ eq chr(173)) { $besedilo.=chr(194).chr(173); } #�(­)
		elsif($_ eq chr(174)) { $besedilo.=chr(194).chr(174); } #�(®)
		elsif($_ eq chr(175)) { $besedilo.=chr(197).chr(187); } #�(Ż)
		elsif($_ eq chr(176)) { $besedilo.=chr(194).chr(176); } #�(°)
		elsif($_ eq chr(177)) { $besedilo.=chr(194).chr(177); } #�(±)
		elsif($_ eq chr(178)) { $besedilo.=chr(203).chr(155); } #�(˛)
		elsif($_ eq chr(179)) { $besedilo.=chr(197).chr(130); } #�(ł)
		elsif($_ eq chr(180)) { $besedilo.=chr(194).chr(180); } #�(´)
		elsif($_ eq chr(181)) { $besedilo.=chr(194).chr(181); } #�(µ)
		elsif($_ eq chr(182)) { $besedilo.=chr(194).chr(182); } #�(¶)
		elsif($_ eq chr(183)) { $besedilo.=chr(194).chr(183); } #�(·)
		elsif($_ eq chr(184)) { $besedilo.=chr(194).chr(184); } #�(¸)
		elsif($_ eq chr(185)) { $besedilo.=chr(196).chr(133); } #�(ą)
		elsif($_ eq chr(186)) { $besedilo.=chr(197).chr(159); } #�(ş)
		elsif($_ eq chr(187)) { $besedilo.=chr(194).chr(187); } #�(»)
		elsif($_ eq chr(188)) { $besedilo.=chr(196).chr(189); } #�(Ľ)
		elsif($_ eq chr(189)) { $besedilo.=chr(203).chr(157); } #�(˝)
		elsif($_ eq chr(190)) { $besedilo.=chr(196).chr(190); } #�(ľ)
		elsif($_ eq chr(191)) { $besedilo.=chr(197).chr(188); } #�(ż)
		elsif($_ eq chr(192)) { $besedilo.=chr(197).chr(148); } #�(Ŕ)
		elsif($_ eq chr(193)) { $besedilo.=chr(195).chr(129); } #�(Á)
		elsif($_ eq chr(194)) { $besedilo.=chr(195).chr(130); } #�(Â)
		elsif($_ eq chr(195)) { $besedilo.=chr(196).chr(130); } #�(Ă)
		elsif($_ eq chr(196)) { $besedilo.=chr(195).chr(132); } #�(Ä)
		elsif($_ eq chr(197)) { $besedilo.=chr(196).chr(185); } #�(Ĺ)
		elsif($_ eq chr(198)) { $besedilo.=chr(196).chr(134); } #�(Ć)
		elsif($_ eq chr(199)) { $besedilo.=chr(195).chr(135); } #�(Ç)
		elsif($_ eq chr(200)) { $besedilo.=chr(196).chr(140); } #�(Č)
		elsif($_ eq chr(201)) { $besedilo.=chr(195).chr(137); } #�(É)
		elsif($_ eq chr(202)) { $besedilo.=chr(196).chr(152); } #�(Ę)
		elsif($_ eq chr(203)) { $besedilo.=chr(195).chr(139); } #�(Ë)
		elsif($_ eq chr(204)) { $besedilo.=chr(196).chr(154); } #�(Ě)
		elsif($_ eq chr(205)) { $besedilo.=chr(195).chr(141); } #�(Í)
		elsif($_ eq chr(206)) { $besedilo.=chr(195).chr(142); } #�(Î)
		elsif($_ eq chr(207)) { $besedilo.=chr(196).chr(142); } #�(Ď)
		elsif($_ eq chr(208)) { $besedilo.=chr(196).chr(144); } #�(Đ)
		elsif($_ eq chr(209)) { $besedilo.=chr(197).chr(131); } #�(Ń)
		elsif($_ eq chr(210)) { $besedilo.=chr(197).chr(135); } #�(Ň)
		elsif($_ eq chr(211)) { $besedilo.=chr(195).chr(147); } #�(Ó)
		elsif($_ eq chr(212)) { $besedilo.=chr(195).chr(148); } #�(Ô)
		elsif($_ eq chr(213)) { $besedilo.=chr(197).chr(144); } #�(Ő)
		elsif($_ eq chr(214)) { $besedilo.=chr(195).chr(150); } #�(Ö)
		elsif($_ eq chr(215)) { $besedilo.=chr(195).chr(151); } #�(×)
		elsif($_ eq chr(216)) { $besedilo.=chr(197).chr(152); } #�(Ř)
		elsif($_ eq chr(217)) { $besedilo.=chr(197).chr(174); } #�(Ů)
		elsif($_ eq chr(218)) { $besedilo.=chr(195).chr(154); } #�(Ú)
		elsif($_ eq chr(219)) { $besedilo.=chr(197).chr(176); } #�(Ű)
		elsif($_ eq chr(220)) { $besedilo.=chr(195).chr(156); } #�(Ü)
		elsif($_ eq chr(221)) { $besedilo.=chr(195).chr(157); } #�(Ý)
		elsif($_ eq chr(222)) { $besedilo.=chr(197).chr(162); } #�(Ţ)
		elsif($_ eq chr(223)) { $besedilo.=chr(195).chr(159); } #�(ß)
		elsif($_ eq chr(224)) { $besedilo.=chr(197).chr(149); } #�(ŕ)
		elsif($_ eq chr(225)) { $besedilo.=chr(195).chr(161); } #�(á)
		elsif($_ eq chr(226)) { $besedilo.=chr(195).chr(162); } #�(â)
		elsif($_ eq chr(227)) { $besedilo.=chr(196).chr(131); } #�(ă)
		elsif($_ eq chr(228)) { $besedilo.=chr(195).chr(164); } #�(ä)
		elsif($_ eq chr(229)) { $besedilo.=chr(196).chr(186); } #�(ĺ)
		elsif($_ eq chr(230)) { $besedilo.=chr(196).chr(135); } #�(ć)
		elsif($_ eq chr(231)) { $besedilo.=chr(195).chr(167); } #�(ç)
		elsif($_ eq chr(232)) { $besedilo.=chr(196).chr(141); } #�(č)
		elsif($_ eq chr(233)) { $besedilo.=chr(195).chr(169); } #�(é)
		elsif($_ eq chr(234)) { $besedilo.=chr(196).chr(153); } #�(ę)
		elsif($_ eq chr(235)) { $besedilo.=chr(195).chr(171); } #�(ë)
		elsif($_ eq chr(236)) { $besedilo.=chr(196).chr(155); } #�(ě)
		elsif($_ eq chr(237)) { $besedilo.=chr(195).chr(173); } #�(í)
		elsif($_ eq chr(238)) { $besedilo.=chr(195).chr(174); } #�(î)
		elsif($_ eq chr(239)) { $besedilo.=chr(196).chr(143); } #�(ď)
		elsif($_ eq chr(240)) { $besedilo.=chr(196).chr(145); } #�(đ)
		elsif($_ eq chr(241)) { $besedilo.=chr(197).chr(132); } #�(ń)
		elsif($_ eq chr(242)) { $besedilo.=chr(197).chr(136); } #�(ň)
		elsif($_ eq chr(243)) { $besedilo.=chr(195).chr(179); } #�(ó)
		elsif($_ eq chr(244)) { $besedilo.=chr(195).chr(180); } #�(ô)
		elsif($_ eq chr(245)) { $besedilo.=chr(197).chr(145); } #�(ő)
		elsif($_ eq chr(246)) { $besedilo.=chr(195).chr(182); } #�(ö)
		elsif($_ eq chr(247)) { $besedilo.=chr(195).chr(183); } #�(÷)
		elsif($_ eq chr(248)) { $besedilo.=chr(197).chr(153); } #�(ř)
		elsif($_ eq chr(249)) { $besedilo.=chr(197).chr(175); } #�(ů)
		elsif($_ eq chr(250)) { $besedilo.=chr(195).chr(186); } #�(ú)
		elsif($_ eq chr(251)) { $besedilo.=chr(197).chr(177); } #�(ű)
		elsif($_ eq chr(252)) { $besedilo.=chr(195).chr(188); } #�(ü)
		elsif($_ eq chr(253)) { $besedilo.=chr(195).chr(189); } #�(ý)
		elsif($_ eq chr(254)) { $besedilo.=chr(197).chr(163); } #�(ţ)
		elsif($_ eq chr(255)) { $besedilo.=chr(203).chr(153); } #�(˙)
		else{ $besedilo.=$_; }

	}

	my $c180a="'"; my $c184a="''"; #´
	my $c180ab='"'; my $c184ab='"'; #´
	$besedilo =~ s/$c180a/$c184a/g; #´(Â´)
	$besedilo =~ s/$c180ab/$c184ab/g; #´(Â´)
	
	return $besedilo;
}

sub PrecitajDatoteko(){
	
	my $self = shift;
    my $q = new CGI;
	my $seja;
	#return Znaki();
	
	my @datoteka_vsebina;
	my $dovoli_uvoz;
	my $name;
	my $file = $q->param("edb_datoteka");
	my $izvor = $q->param("izvor");
	my $vrstica;
	my $fileHandler = $q->upload("edb_datoteka");
	#$file=~m/^.*(\\|\/)(.*)/;
	#$name=$2;
	my $davcniZavezanec=0;
	my $tip;
	my $davcnaSt;
	my $maticnaSt;
	my $sifraDejavnosti;
	my $naslov;
	my $ime;
	my $sql;
	my $dbh;
	my $sth;
	
	my $template;
	my $html_output;
	#
	if($izvor eq "dz"){
		if ($dbh = DntFunkcije->connectDB){
			open(FILEH, "../../files/$file");
			if($file =~ /^PO/ || $file =~ /^FOzD/){
				my $i=0;
				if($file =~ /^PO/){
					$tip="D";
				}
				else{
					$tip="S";
				}			
				$sql="DELETE FROM davcni_zavezanci WHERE vrsta_zavezanca='$tip'";
				$sth = $dbh->prepare($sql);
				unless($sth->execute()){
					
					my $napaka_opis = $sth->errstr."<br />$sql";
					$template = $self->load_tmpl(	    
						'DntRocniVnosNapaka.tmpl',
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
				
				$sql="INSERT INTO davcni_zavezanci (vrsta_zavezanca, ".
					 "reg_za_ddv, davcna_st, maticna_st, sifra_dejavnosti,".
					 "ime, naslov) VALUES ";
				my $j=0;
				while ($vrstica = <FILEH>){
					if($vrstica =~ /\**/){
						$davcniZavezanec="1";
					}
					else{
						$davcniZavezanec="0";
					}
					if(substr($vrstica, 1,3) =~ /^[0-9]/){
						$j=0;
					}
					else{
						$j=3;
					}
					$davcnaSt=substr($vrstica,1+$j,8);
					$maticnaSt=substr($vrstica,10+$j,10);
					$sifraDejavnosti=substr($vrstica,21+$j,6);
					$ime=substr($vrstica,28+$j,100);
					$naslov=substr($vrstica,129+$j,100);
					$ime=Sumniki($ime);
					return $ime;
					#return $ime;
					$naslov=Sumniki($naslov);
					if($i==0){
						$sql.="('$tip', '$davcniZavezanec', '$davcnaSt',".
						"'$maticnaSt', '$sifraDejavnosti', '$ime', '$naslov') ";
						$i++;
					}
					else{
						$sql.=", ('$tip', '$davcniZavezanec', '$davcnaSt',".
						"'$maticnaSt', '$sifraDejavnosti', '$ime', '$naslov')";
						
					}
					if($i>500){
						last;
					}
				}
				$sth = $dbh->prepare($sql);
				#return $sql;
				unless($sth->execute()){					
					my $napaka_opis = $sth->errstr."<br />$sql";
					$template = $self->load_tmpl(	    
						'DntRocniVnosNapaka.tmpl',
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
			elsif($file =~ /^FObD/){
				$tip="F";
				$sql="DELETE FROM davcni_zavezanci WHERE vrsta_zavezanca='$tip'";
				$sth = $dbh->prepare($sql);
				unless($sth->execute()){
					
					my $napaka_opis = $sth->errstr."<br />$sql";
					$template = $self->load_tmpl(	    
						'DntRocniVnosNapaka.tmpl',
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
				$sql="INSERT INTO davcni_zavezanci (vrsta_zavezanca, davcna_st)".
					 " VALUES ";
				
				my $i=0;
				while ($vrstica = <FILEH>){
					
					
					$davcnaSt=substr($vrstica,0,8);
					
					if($i==0){
						$sql.="('$tip', '$davcnaSt')";
						$i++;
					}
					else{
						$sql.=", ('$tip', '$davcnaSt')";
					}
				}
			}
			
			close(FILEH);
			$sth = $dbh->prepare($sql);
			unless($sth->execute()){
					
					my $napaka_opis = $sth->errstr."<br />$sql";
					$template = $self->load_tmpl(	    
						'DntRocniVnosNapaka.tmpl',
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
			return "napaka pri povezavi z bazo."
		}
	}
	
	my $redirect_url="?rm=IzberiDatoteko&amp;dodano=true";
			$self->header_type('redirect');
			$self->header_props(-url => $redirect_url);
			return $redirect_url;
	#open(LOCAL, ">/var/www-donator/www-donator/FileTest.cgi") or die $!;
	#return $file;
	
	
}





sub UvoziDatoteko(){
    my $self = shift;
    my $q = $self->query();
    my $seja  ;
	
	my $datoteka;
	
	$datoteka = $q->param('datoteka');
	return 'uvazam datoteko'.$datoteka;
}

1;