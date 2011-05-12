package DntBranjeDatotek;
use base 'CGI::Application';
#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use strict;


#use HTML::Template;
#use CGI::Session;
#use Data::Dumper;
use DntFunkcije;
use ObjektPogodbaObroki;


#authenticate:
sub cgiapp_prerun {
	
    my $self = shift;
    my $q = $self->query();
	my $nivo='w';
	my $str = $q->param('rm');
	#nastavi write nivo funkcij, ki zapisujejo v bazo:
	#if ($str eq 'btn_brisi_izbrane_datoteke' ||
	#	$str eq 'btn_brisi_izbrane_datoteke_potrjeno' ||){
	#	
	#	$nivo = 'w';
	#	
	#}
	
    my $user = DntFunkcije::AuthenticateSession(41, $nivo);
	# Redirect to login, če uporabnik ni prijavljen
	if($user == 0){    
        $self->prerun_mode('Login');
    }
	# Redirect to error, če nima pravic za ogled strani
	elsif($user == -1){    
        $self->prerun_mode('Error');
    }	
}


sub setup {
    my $self = shift;
    #$self->dbh_config("dbi:PgPP:dbname=donator;host=localhost", "postgres", "ni2mysql");
    $self->start_mode('IzberiDatoteko');
    
    $self->run_modes(
        'IzberiDatoteko' => 'IzberiDatoteko',
		'Precitaj' => 'PrecitajDatoteko',
		'Uvozi' => 'UvoziDatoteko',
        'Nepotrjene_datoteke' => 'NepotrjeneDatoteke',
        'prikazi_vsebino' => 'PrikaziVsebinoDatoteke',
		'potrdi_datoteko' => 'PotrdiDatoteko',
		'zbrisi' => 'BrisiDatoteko',
		'btn_brisi_izbrane_datoteke' => 'BrisiDatotekoVprasaj',
		'btn_brisi_izbrane_datoteke_potrjeno' => 'BrisiDatoteko',
		'uspeh' => 'UspesnoVnesena',
		'Login' => 'Login',
		'Error' => 'Error',
    );
	
}


sub IzberiDatoteko(){
	#forma za prenos datoteke
    my $self = shift;
    my $q = $self->query();
    my $seja  ;
    
    my $html_output;
	my $izberi_gumb;
    my $template;
    
    $template = $self->load_tmpl(	    
			'DntBranjeDatotekIzberiDatoteko.tmpl',
			cache => 1,
		);
	$izberi_gumb = "";
	$izberi_gumb = $q->radio_group(-name=>'vrsta_uvoza_dok',
							-values=>['datoteke z banke','davcni zavezanci','delno davcni zavezanci'],
							-default=>'datoteke z banke',
							-linebreak=>'1');
	
	#$izberi_gumb = $q->radio_group(-name=>'',
	#						-values=>['direktna bremenitev','splosna poloznica','racun'],
	#						-default=>'direktna bremenitev',
	#						-linebreak=>'0')
    $template->param(
			MENU_POT => '',
			MENU => DntFunkcije::BuildMenu(),
			IME_DOKUMENTA => 'Uvoz iz datoteke',
			izberi_gumb => $izberi_gumb,
			POMOC => "<input type='button' value='?' onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		);

    $html_output = $template->output; #.$tabelica;
    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
    return $html_output;
	
}

sub PotrdiDatoteko(){
	#potrdi izbrane vrstice datoteke in vrne uporabnika na seznam datotek
	my $self = shift;
    my $q = $self->query();
    my $seja;
	
	#podatki za zapis:
	my @arr = $q->param("zapis");
	my @raz = $q->param("razreseno");
	my $vrstica;
	my $sporocilo="";
	my $vrsitca;
	my $znesek;
	my $id_pogodbe;
	my $id_datoteke = $q->param("id_datoteka");
	my $zap_st_dolznika;
	
	my $dbh;
    my $res;
    my $sql;
    my $sth;
	
	$dbh = DntFunkcije::connectDB;
	
	if($dbh){
		my $i = 0;
		foreach(@arr){
			my $id_vrstice = $_;
			my $datum;
			my $s1;
			my $s2;			
			my $s4;
			my $s5;
			my $napaka_vnosa = 0;
			$sql = "SELECT * FROM datoteke_vsebina WHERE id_vrstce=?";
			$sth = $dbh->prepare($sql);
			$sth->execute($id_vrstice);
			if($res = $sth->fetchrow_hashref){
				#vrstica:
				$vrstica = $res->{'vsebina_vrstice'};
				#znesek:
				$znesek = substr($vrstica,35,13)+0;
				$znesek .= ".".substr($vrstica,48,2);
				#sx:
				$s1 = $res->{'s1_vrsta_zapisa'} || "-1";
				$s2 = $res->{'s2_vrsta_knjizenja'} || "-1";
				$s4 = $res->{'s4_vrsta_informacije'} || "-1";
				$s5 = $res->{'s5_status'} || "-1";
				#datum:
				$datum = substr($vrstica,27,8);
				$datum = substr($datum,0,4)."-".substr($datum,4,2)."-".substr($datum,6,2);
				#id pogodbe:
				$id_pogodbe = DntFunkcije::trim(substr($vrstica,71,20));
			}
			#my $zap_st_dolz = $val[3];
			#zapis zneska v tabelo:
			if($s1 eq "01"){
				#shranjevanje posebnih poloznic:
				$sql = "UPDATE agreement_pay_installment ".
					   "SET amount_payed=?, id_packet_pp=?, date_due=? ".
					   "WHERE id_vrstica = ".
							"(SELECT id_vrstica FROM agreement_pay_installment ".
							"WHERE id_agreement = ? ".
							"AND storno IS NULL AND obracun IS NULL AND amount_payed IS NULL ".
							"ORDER BY id_vrstica LIMIT 1)";
				$sth = $dbh->prepare($sql);
				#return $sql."$znesek, $id_vrstice, $datum, $id_agreement";
				unless($sth->execute($znesek, $id_vrstice, $datum, $id_pogodbe))
				{
					$napaka_vnosa = 1;
				   #return $sporocilo .= $sth->errstr." ";
				}
			}
			else{
				#shranjevanje direktnih bremenitev:
				
				#zap. st. dolznika:
				$zap_st_dolznika = substr($vrstica, 178, 10);
				
				#-preveri vse pogoje
				if($s4 eq '01' && $s5 eq '02'){
					#zapisi znesek v obroke
					$sql = "UPDATE agreement_pay_installment ".
							"SET amount_payed=?, id_packet_pp=?, date_due=? ".
							"WHERE id_vrstica = ".
								 "(SELECT id_vrstica FROM agreement_pay_installment ".
								 "WHERE id_agreement = ? ".
								 "AND storno IS NULL AND obracun IS NULL AND amount_payed IS NULL ".
								 "ORDER BY id_vrstica LIMIT 1)";
					 $sth = $dbh->prepare($sql);
					 #return $sql."$znesek, $id_vrstice, $datum, $id_agreement";
					 unless($sth->execute($znesek, $id_vrstice, $datum, $id_pogodbe))
					 {
						 $napaka_vnosa = 1;
						#return $sporocilo .= $sth->errstr." ";
					 }
				}
				elsif($s4 eq '02' && $s5 eq '21'){
					#zapisis zap. st. dolznika v agreement tabelo
					
					$sql = "UPDATE sfr_agreement SET zap_st_dolznika = ? WHERE id_agreement=?";
					$sth = $dbh->prepare($sql);
					unless($sth->execute($zap_st_dolznika, $id_pogodbe))
					{
						$napaka_vnosa = 1;
						#return $sporocilo .= $sth->errstr." ";
					}
					
				}
			}
			#oznaci datoteko za prebrano, ce so bila vnesena vsa polja:
			if($napaka_vnosa == 0){
				$sql = "UPDATE datoteke_vsebina ".
						"SET potrjeno='1' WHERE id_vrstce = ?";
				$sth = $dbh->prepare($sql);
				#return $sql."$znesek, $id_vrstice, $datum, $id_agreement";
				unless($sth->execute($id_vrstice)){
					#potrjevanje ni bilo uspesno	
				}
			}
			#preveri ce je pogodba zakljucena:
			my $pogodbaObroki = PogodbaObroki->new();
			$pogodbaObroki->preveri_pogodba_zakljucena($id_pogodbe, $self);
		}
		foreach(@raz){
			my $id_vrstice = $_;
			$sql = "UPDATE datoteke_vsebina ".
							"SET razreseno=1 ".
							"WHERE id_vrstce = ?";
			$sth = $dbh->prepare($sql);
			$sth->execute($id_vrstice);			
		}
		#preveri ce je bila celotna datoteka potrjena in razresena:
		$sql = "SELECT * FROM datoteke_vsebina WHERE id_datoteka = ? AND (razreseno = '0' OR razreseno IS NULL) AND s1_vrsta_zapisa NOT LIKE '9%'";
		$sth = $dbh->prepare($sql);
		$res = $sth->execute($id_datoteke);
		if($res = $sth->fetchrow_hashref){
			#niso vse potrjene, ne zapiraj
		}
		else{
			$sql = "UPDATE datoteke  SET zaprta=? WHERE id_datoteka=?";
			$sth = $dbh->prepare($sql);
			$sth->execute("Z",$id_datoteke);
			
		}
	}
	my $redirect_url = "DntBranjeDatotek.cgi?rm=Nepotrjene_datoteke&sporocilo=$sporocilo";
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;	
}

sub NepotrjeneDatoteke(){
    #Izpise seznam datotek, ki se nimajo dokoncno potrjenih postavk
    my $self = shift;
    my $q = $self->query();
    my $seja  ;
    
    my $datoteka;
    my $datum;
    my $html_output;
	my $id_datoteka;
    my @loop;
    my $rez;
	my $template;
    
    my $dbh;
    my $res;
    my $sql_vprasaj;
    my $sth;
    
    
    #$rez = $q->p("Seznam nepotrjenih datotek:");
    $dbh = DntFunkcije::connectDB;
	$template = $self->load_tmpl(	    
				'DntBranjeDatotekNepotrjene.tmpl',
			    cache => 1,
			    );
    if ($dbh) {
                            
        $sql_vprasaj = "SELECT id_ime_datoteke, datum, id_datoteka
						FROM datoteke
						WHERE zaprta = ?";
        $sth = $dbh->prepare($sql_vprasaj);
        unless($sth->execute('O'))
        {
           $rez .= $sth->errstr;
        }
		$rez .= '<table border = "1px">';
		$rez .= '<tr>';
		$rez .= '<th>Ime datoteke</th>';
		$rez .= '<th>Datum uvoza</th>';

        while ($res = $sth->fetchrow_hashref) 
        {
        
			$datoteka = DntFunkcije::trim($res->{'id_ime_datoteke'});
			$id_datoteka = $res->{'id_datoteka'};
            $datum = substr($res->{'datum'},0,10);
            
#			$rez .= $q->start_Tr;
#				$rez .= $q->td("<input type='checkbox' name='izbrane_datoteke' value='".$datoteka."' -checked  >".$q->a({-href=>"BranjeDatotek.pl?hid_potrdi_datoteko=$datoteka"}, $datoteka));
#				$rez .= $q->td($datum);
#			$rez .= $q->end_Tr;
            #$datoteka = "<input type='checkbox' name='izbrane_datoteke' value='".
			#	$datoteka."' -checked  >".
			$datoteka =  $q->a({-href=>"DntBranjeDatotek.cgi?rm=prikazi_vsebino&
						datoteka=$datoteka&id_datoteka=$id_datoteka"}, $datoteka);
			my %row = (				
                    ime_datoteke => $datoteka,
                    datum_uvoza => $datum,
					id => DntFunkcije::trim($id_datoteka)
                   );
                push(@loop, \%row);	
        }
		#$rez .= $q->end_table;
		#$rez .= $q->submit(-name=>"btn_brisi_izbrane_datoteke", -value=>"brisi izbrane",
		#				 -onClick=>"javascript:dopostback('hid_akcija','btn_brisi_izbrane_datoteke')");
		#
		#$rez .= $q->button(-name=>"btn_nazaj", -value=>"Nazaj", -onClick=>"javascript:window.history.back()");		
        
        
    }
    
    
    $template->param(
		     MENU_POT => '',
			 MENU => DntFunkcije::BuildMenu(),
		    IME_DOKUMENTA => 'Potrditev uvoza datoteke',
			POMOC => "<input type='button' value='?' onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		    datoteke_loop => \@loop,
			hid_brisi_potrjeno => '0'
		     );
	
	$html_output = $template->output; #.$tabelica;
	
    return $html_output;
    
    
}



sub PrecitajDatoteko(){
	my $self = shift;
    my $q = $self->query();
	my $seja  ;
	
	my @datoteka_vsebina;
	my $dovoli_uvoz,
	my $file = $q->param("edb_datoteka");
	my $html_output;
	my $napaka;
	my $nasel_vrstico;
	my $sporocilo;
	my $template;
	
	my $dbh;
	my $sth;
	my $res;
	my $sql;
	$dbh = DntFunkcije->connectDB;
	$sql = "SELECT id_ime_datoteke, zaprta FROM datoteke WHERE 
                     id_ime_datoteke = ?";
	$sth = $dbh->prepare($sql);
	unless($sth->execute($file)){
		$napaka = $q->p($sth->errstr);
	}
	$nasel_vrstico = 0;
	if(my $res = $sth->fetchrow_hashref())	{
		$nasel_vrstico = 1;
		$dovoli_uvoz = '1';
	}
	if($nasel_vrstico == 0)	{
		$sporocilo = $q->p('Uvozi datoteko:<b>'.$file.'<b>');
		$dovoli_uvoz = $q->button(-name=>"btn_nazaj", -value=>"Nazaj", -onClick=>"javascript:window.history.back()")
				.$q->submit(-name=>"rm", -value=>"Uvozi")
	}
	else{
		$sporocilo = $q->p("Izbrana datoteka je ze potrjena");
		$dovoli_uvoz = $q->button(-name=>"btn_nazaj", -value=>"Nazaj", -onClick=>"javascript:window.history.back()");
	}
	
	$template = $self->load_tmpl(	    
				'DntBranjeDatotekPotrdiDatoteko.tmpl',
			    cache => 1,
			    );
	#if ($dovoli_uvoz)
	#return $file;
	@datoteka_vsebina = <$file>;
	my $rez ='x';
	my $vrstica;
	
	foreach $vrstica (@datoteka_vsebina) {
	   $rez .= $vrstica;
	}
	#return $rez;
    $template->param(
		     MENU_POT => '',
			 IME_DOKUMENTA => 'Potrditev uvoza datoteke',
			 MENU => DntFunkcije::BuildMenu(),
			 POMOC => "<input type='button' value='?' onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
			 sporocilo=> $sporocilo,
			 datoteka => $file,
			 datoteka_vsebina => \@datoteka_vsebina,
			 akcija => $dovoli_uvoz,
		     );
	
	$html_output = $template->output; #.$tabelica;
	IzpisiVsebinoDatoteke();
	#$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
    return $html_output;
}
sub PrikaziVsebinoDatoteke(){
	my $self = shift;
    my $q = $self->query();
    my $seja;
	my $ime_datoteke = $q->param('datoteka');
	my $id_datoteke = $q->param('id_datoteka');
	my $napaka;
	my $table;
	
	my $sporocilo = "Ime datoteke: <b>".$ime_datoteke."</b>";
	
	#kontrolne spremenljivke:
	my $delni;
	my $vhodni_paket=1;
	my $vsota_zneska;
	my $vsota_vsot=0;
	my $namen = "";
	my $vodilni_zapis;
	
	my $sql;
	my $res;
	my $sth;
	my $dbh = DntFunkcije::connectDB;
	if($dbh){
		$sql = "SELECT id_vrstce, id_ime_datoteke, vrstica, vsebina_vrstice, s1_vrsta_zapisa, 
						s2_vrsta_knjizenja, s4_vrsta_informacije, s5_status, potrjeno, razreseno,
						trr_projekt, id_datoteka
				FROM datoteke_vsebina WHERE id_datoteka=? AND (razreseno = '0' OR razreseno IS NULL) ORDER BY id_vrstce ASC;";
				
		$sth = $dbh->prepare($sql);
        unless($sth->execute($id_datoteke))
        {
           $napaka .= $sth->errstr;
        }
        while ($res = $sth->fetchrow_hashref) {
			#datoteke_vsebina DB:
			my $datum;
			my $vrstica = $res->{'vsebina_vrstice'};
			my $id_vrstice = $res->{'id_vrstce'};
			my $s1 = $res->{'s1_vrsta_zapisa'};
			my $s2 = $res->{'s2_vrsta_knjizenja'};
			my $s4 = $res->{'s4_vrsta_informacije'};
			my $s5 = $res->{'s5_status'};
			my $trr = $res->{'trr_projekt'} = "";
			my $potrjeno = $res->{'potrjeno'};
			my $razreseno = $res->{'razreseno'};
			my $napaka_vrstice = "";
			my $opozorilo_vrstice = "";
			
			my $s2Opis = SifrantStatusS2($s2);
			#my $s3Opis = SifrantStatusS3($s3);
			my $s4Opis = SifrantStatusS4($s4);
			my $s5Opis = SifrantStatusS5($s5);
			#delitev glede na vrsto zapisa:
			
			if($s1 =~ /^9/){
				#kontrolna vrstica:
				if($s1 =~ /90/){
					#zacetek datoteke:
					$table.="St. transakcij v datoteki: ".substr($vrstica, 20, 6)."<br />".
									  "Datum kreiranja datoteke: ".DntFunkcije::sl_date(substr($vrstica, 27, 4)."-".
																						substr($vrstica, 31, 2)."-".
																						substr($vrstica, 33, 2))."<br />";
					
					$table .= '<table border="1px">';
					$vhodni_paket = 0;
					$delni = 0;
					$vsota_zneska = undef;
				}
				elsif($s1 =~ /99/){
					#konec datoteke:					
					if($delni<1){
						
						$table .= '<tr>';
						$table .= '<td colspan="5" style="border:0px;">' ."Poravnalni racun: <b>".$trr."</b></td>";
						$table .= '<th style="border:0px; align="right">' . DntFunkcije::FormatFinancno($vsota_zneska)."</th>";
						$table .= '<td colspan="3" style="border:0px;">' . "Namen: <b>".$namen."</b></td>";
						$table .= '</tr><tr>';
						$table .= '<td colspan="2" style="border:0px;"></td>';
						$table .= '</tr>';							
					}
					$vsota_vsot += $vsota_zneska;
					#$table .= $q->Tr();
					#$table .= $q->th(['','','','',DntFunkcije::FormatFinancno($vsota_zneska)]);
					$table .= $q->end_table();
				}
				else{
					#delni zbirni zapis:
					$delni = 1;
					$vhodni_paket = 0;
					$namen = substr($vrstica, 91, 35);
					if(defined $vsota_zneska){
						my $id_pogodbe_vodilni = DntFunkcije::trim(substr($vrstica,71,20));
						my $znesek_vodilni = substr($vrstica,35,13)+0;
						$znesek_vodilni .= ".".substr($vrstica,48,2);
						$table .= '<tr>';
						$table .= '<th style="border:0px" colspan="4">' . "St. paketa: ".(substr($vrstica,2,18)).'</th>';
						my @table_header = (						
							'<span title="'.SifrantStatusS1($s1).'">'.$s1.'</span>',
							"St. transakcij: ".DntFunkcije::trim(substr($vrstica,20,6)),
							substr($vrstica,26,1),
							DntFunkcije::raw_date(substr($vrstica,27,8)),
							($znesek_vodilni),
							DntFunkcije::trim(substr($vrstica,50,3)),
							DntFunkcije::trim(substr($vrstica,53,18)),
							$id_pogodbe_vodilni,
							DntFunkcije::trim(substr($vrstica,91,35)),
							DntFunkcije::trim(substr($vrstica,126,3)),
							DntFunkcije::trim(substr($vrstica,129,15)),
							);
						foreach(@table_header){
							$table .= "<th style='border:0px'>$_</th>";
						}
						$table .= '</tr>';
						
						#$table .= $q->td({-colspan=>"4", -style=>"border:0px;"}, ["Poravnalni racun: <b>".$trr."</b>"]);
						#$table .= $q->th({-style=>"border:0px;"},[DntFunkcije::FormatFinancno($vsota_zneska)]);
						#$table .= $q->td({-colspan=>"3", -style=>"border:0px;"}, ["Namen: <b>".$namen."</b>"]);
						#$table .= $q->Tr();
						#$table .= $q->td({-colspan=>"2", -style=>"border:0px;"}, ['']);						
					}
				}
				
			}
			elsif($s1 =~ /00/ || $s1 =~ /11/){
				
				#KONTROLNI ZAPIS:
				my $znesek = substr($vrstica,35,13)+0;
				$znesek .= ".".substr($vrstica,48,2);
				$table .= "<table border='1px'>";
				#return $table;	
				$table .= "<tr>";
				my @table_header = (
						('Vrsta zapisa'),
						('Stevilka paketa'),
						('Stevilo transakcij'),						
						('Oznaka knjizenja'),
						('Datum'),
						('Znesek'),
						('Oznaka valute'),
						('Indikator napak'),
						('Id zapisa (kjer se pojavi napaka)'),							
				);
				foreach (@table_header){
					$table .= '<th>'.$_.'</td>';
				}
				$table .= '</tr><tr>';
				@table_header = (
						'<span title="'. SifrantStatusS1($s1).'">' . $s1 . '</span>',
						(substr($vrstica,2,18)),
						DntFunkcije::trim(substr($vrstica,20,6)),
						DntFunkcije::trim(substr($vrstica,26,1)),
						DntFunkcije::raw_date(substr($vrstica,27,8)),
						($znesek),
						DntFunkcije::trim(substr($vrstica,50,3)),
						SifrantNapakS9(substr($vrstica, 53, 20)),
						DntFunkcije::trim(substr($vrstica,73,24)),
				);
				foreach(@table_header){
					$table .= '<td>' . $_ . '</td>';
				}
				$table .= '</tr>';
				$table .= $q->end_table();
			}
			#PONOVNO POSLJI: elsif($s1 =~ /22/)
			else{
				#osnovni zapis:
				my @table_header;
				$table .= '<tr>';
				if($vhodni_paket == 0){
					#zacetek novega sklopa:					
					@table_header = (
							('Napaka'),
							('Opozorilo'),
							('Izbira'),
							('Razreseno'),
							
							('Vrsta zapisa'),
							('Id zapisa'),
							('Oznaka knjizenja'),
							('Datum'),
							('Znesek'),
							('Oznaka valute'),
							('Racun komitenta ZC'),
							('Referencna stevilka/sklic'),
							('Namen'),
							('Sifra nakazila'),
							('Poravnalni racun'),
							('Enota'),
							('Vrsta posla'),
							
							
					);
					if($s1 == "04"){
						#dodatna polja za direktne bremenitve:
						push(@table_header, (
							('Partija'),
							('Sifra prejemnika/izdatka'),
							('Vrsta informacije'),
							('Status'),
							('Sifra konta'),
							('Frekvenca'),
							('zap. st. DB upnika'),
							('zap. st. DB dolznika'),
							('operater/blagajnik'),
							
						));
					}
					else{
						#dodatna polja za direktne bremenitve:
						push(@table_header, (
							('zap. st. vplacilnega dnevnika'),
							('operater/blagajnik'),
							
							));
					}
					$vhodni_paket = 1;
					if(defined $vsota_zneska){
						$vsota_vsot += $vsota_zneska;
					}
					$vsota_zneska = 0;
					foreach(@table_header){
						
						$table .= '<th>'.$_.'</th>';
					}
					$table .= '</tr>';
				}
				
				
				my $id_pogodbe = DntFunkcije::trim(substr($vrstica,71,20));
				my $znesek = substr($vrstica,35,13)+0;
				$znesek .= ".".substr($vrstica,48,2);
				$datum .= substr($vrstica,27,8);
				$vsota_zneska += $znesek;
				
				#preverjanje podatkov iz datoteke
				
				##preveri, ce je pogodba v bazi:
				$sql = "SELECT id_agreement, zap_st_dolznika, frequency, bank_account2 FROM sfr_agreement WHERE id_agreement = ?";			
				my $sth2 = $dbh->prepare($sql);
				unless($sth2->execute($id_pogodbe))	{
					$napaka .= $sth->errstr;
				}
				my $res2;
				if($res2 = $sth2->fetchrow_hashref){
					my $zaps = DntFunkcije::trim($res2->{'zap_st_dolznika'}) || "";
					my $trs = DntFunkcije::trim($res2->{'bank_account2'}) || "";
					my $frek = DntFunkcije::trim($res2->{'frequency'}) || "";
					$trs =~ s/ //g;
					
					if($s1 eq "04"){
						if($s5 eq "21"){
							if($zaps ne ""){
								if($zaps eq DntFunkcije::trim(substr($vrstica,178,10))){
									$napaka_vrstice = "Ta zap. st. dolznika je ze vnesena\n";
								}
								else{
									$napaka_vrstice = "Zap. st. dolznika je ze vnesena v pogodbi, vendar se razlikuje od zap. st. dolznika v datoteki.\n";
									
								}
								
							}
							if(DntFunkcije::trim(substr($vrstica,129,15)) ne $trs){
								$napaka_vrstice .= "Trr v bazi se ne ujema s trrjem v datoteki";
							}
							if(DntFunkcije::trim(substr($vrstica,171,2)) ne $frek){
								
								$napaka_vrstice .= "Frekvenca v datoteki se ne ujema s frekvenco v bazi.";
							}
						}
						elsif($s5 ne "21" && DntFunkcije::trim(substr($vrstica,178,10)) ne $zaps){
							$napaka_vrstice .= "Zap. st. dolznika v bazi se ne ujema z zap. st. dolznika v datoteki\n";
						}
						elsif(DntFunkcije::trim(substr($vrstica,129,15)) ne $trs){
							$napaka_vrstice .= "Trr v bazi se ne ujema s trrjem v datoteki";
						}			
						else{
							$sql = "SELECT amount, amount_payed, storno, obracun ".
								   "FROM agreement_pay_installment ".
								   "WHERE id_agreement = ? ".
								   "AND date_activate = '$datum' ".
								   "ORDER BY id_vrstica LIMIT 1";
								   #return $sql;
							$sth2 = $dbh->prepare($sql);
							unless($sth2->execute($id_pogodbe)){
								$napaka .= $sth->errstr;
							}
							if($res2 = $sth2->fetchrow_hashref){
								#"AND storno IS NULL AND obracun IS NULL AND date_due IS NULL ".
								#"AND (amount_payed = 0 OR amount_payed IS NULL) ".
								#preverjanje ujemanja zneskov:
								unless(!defined $res2->{amount_payed} || $res2->{amount_payed} == 0 ){
									$napaka_vrstice .= "Obrok je bil ze placan\n";
								}
								if(defined $res2->{storno}){
									$napaka_vrstice .= "Obrok je bil storniran.\n";
								}
								unless($res2->{amount} == $znesek){
									$napaka_vrstice .= "Zneska se ne ujemata.\n";
								}
							}
							else{						
								$napaka_vrstice .= "V pogodbi ni obroka za dani datum.\n";
							}					
						}
						##LOČI VSE RAZLIČNE VRSTE ZA DB!
						if($s4 eq "01"){
							
							if($s5 ne "02"){
								
								$opozorilo_vrstice = "Placilo se ni uspesno izvedlo";
							}
							
						}
						elsif($s4 eq "02"){
							
							if($s5 ne "21"){						
								$opozorilo_vrstice = "Zavrnitev otvoritve DB s strani upnika";
							}
						}
						else{
							
							$opozorilo_vrstice = "Preveri";
						}
					}
					else{
						$sql = "SELECT amount, amount_payed, storno, obracun ".
							   "FROM agreement_pay_installment ".
							   "WHERE id_agreement = ? ".
							   "AND storno IS NULL AND obracun IS NULL AND date_due IS NULL ".
							   "AND (amount_payed = 0 OR amount_payed IS NULL) ".
							   "ORDER BY id_vrstica LIMIT 1";
							   #return $sql;
						$sth2 = $dbh->prepare($sql);
						unless($sth2->execute($id_pogodbe)){
							$napaka .= $sth->errstr;
						}
						if($res2 = $sth2->fetchrow_hashref){
							#preverjanje ujemanja zneskov:
							unless($res2->{amount} == $znesek){
								$napaka_vrstice .= "Zneska se ne ujemata\n";
							}
						}
						else{						
							$napaka_vrstice .= "Zneski so ze placani ali stornirani\n";
						}
					}
					
				}
				else{
					$napaka_vrstice .= "Pogodbe ni v bazi";
				}
				#izpis tabele s podatki:
				$table .= '<tr>';
				
				if(length($napaka_vrstice)<1){
					$table .=  '<td></td>';	
				}
				else{
					$table .= '<td style="color:red;text-align:center;" title= "'.$napaka_vrstice.'">!</td>';
				}
				if(length($opozorilo_vrstice)<1){
					$table .= '<td></td>';	
				}
				else{
					$table .= '<td style="color:blue;text-align:center;" title= "'.$opozorilo_vrstice.'">?</td>';
				}
				if(length($napaka_vrstice) + length($opozorilo_vrstice) < 1){
					if($potrjeno == 1){
						$table .= '<td style="text-align:center;">Ze potrjeno</td>';
					}
					else{
						$table .= '<td style="text-align:center;">'.$q->checkbox(-value=>"$id_vrstice", -checked=>'true', -name=>'zapis', ).'</td>';
					}
					if($s1 eq "04"){
						$table .= '<td style="text-align:center;">'.$q->checkbox(-value=>"$id_vrstice", -checked=>'true', -title=>$s5Opis, -name=>"razreseno",).'</td>';
							
					}
					else{
						$table .= '<td style="text-align:center;">'.$q->checkbox(-value=>"$id_vrstice", -checked=>'true',-name=>"razreseno",).'</td>';
					}
				}
				else{
					if($potrjeno == 1){
							$table .= '<td style="text-align:center;">Ze potrjeno</td>';	
					}
					else{
						$table .= '<td style="text-align:center;">'.$q->checkbox(-value=>"$id_vrstice", -disabled=>'true',-name=>'zapis',).'</td>';
					}
					if($s1 eq "04"){
						$table .= '<td style="text-align:center;">'.$q->checkbox(-value=>"$id_vrstice", -name=>"razreseno", -title=>$s5Opis,).'</td>';
							
					}
					else{
						$table .= '<td style="text-align:center;">'.$q->checkbox(-value=>"$id_vrstice", -name=>"razreseno",).'</td>';
							
					}
				}
				
				my $return_url = $ENV{'REQUEST_URI'};
				$return_url =~ s/&/_amp_/g;
				my @table_content = (
							'<span title="'. SifrantStatusS1($s1) .'">' . ($s1) . '</span>',
							(substr($vrstica,2,24)),
							DntFunkcije::trim(substr($vrstica,26,1)),
							DntFunkcije::raw_date(substr($vrstica,27,8)),
							($znesek),
							DntFunkcije::trim(substr($vrstica,50,3)),
							DntFunkcije::trim(substr($vrstica,53,18)),
							$q->a({-href=>"DntPogodbe.cgi?rm=uredi_pogodbo&id_agreement=$id_pogodbe&seja=&uredi=1&nazaj=nepotrjene&return=$return_url"}, $id_pogodbe),
							DntFunkcije::trim(substr($vrstica,91,35)),
							DntFunkcije::trim(substr($vrstica,126,3)),
							DntFunkcije::trim(substr($vrstica,129,15)),
							DntFunkcije::trim(substr($vrstica,144,3)),
							DntFunkcije::trim(substr($vrstica,147,2)),
				);
				if($s1 eq "04"){
					push(@table_content, (		
							DntFunkcije::trim(substr($vrstica,149,10)),
							DntFunkcije::trim(substr($vrstica,159,5)),
							"<span title='$s4Opis'>".DntFunkcije::trim(substr($vrstica,164,2))."</span>",
							"<span title='$s5Opis'>".DntFunkcije::trim(substr($vrstica,166,2))."</span>",
							DntFunkcije::trim(substr($vrstica,168,3)),
							DntFunkcije::trim(substr($vrstica,171,2)),
							DntFunkcije::trim(substr($vrstica,173,5)),
							DntFunkcije::trim(substr($vrstica,178,10)),
							DntFunkcije::trim(substr($vrstica,188,5)),
					));					
				}
				else{
					push(@table_content, (
							DntFunkcije::trim(substr($vrstica,129,15)), 
							DntFunkcije::trim(substr($vrstica,144,3)),
					));
				}
				foreach(@table_content){
					$table .= '<td style="text-align:center;">'.$_.'</td>';
				}
				$table .= '</tr>';
			}
		}
	}
	$table .= "Celotni znesek: <b>".DntFunkcije::FormatFinancno($vsota_vsot)."</b><br /><br />";
	my $html_output;
    my $potrdi_gumb;
    my $template;
    $template = $self->load_tmpl(	    
		'DntBranjeDatotekPotrdiDatoteko.tmpl',
		 cache => 1,
    );
	$template->param(sporocilo => $sporocilo,
					 napaka => $napaka,
					 tabela => $table,
					 submit => $q->hidden(-name=>'id_datoteka', -value=>$id_datoteke).$q->submit(-name=>"Potrdi", -value=>"Potrdi"),
					 	   IME_DOKUMENTA => 'Uvoz datoteke',
	   POMOC => "<input type='button' value='?' ".
	   "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
	 );
    
    return $template->output; #$izbrana_datoteka;
	
}
sub SifrantStatusS1{
	my $status = shift;
	
	my %types = ( '01' => 'posebna poloznica',
			   '02' => 'posebna nakaznica',
			   '03' => 'direktna odobritev',
			   '04' => 'direktna bremenitev',
			   '05' => 'trajni nalog',
			   '00' => 'kontrolni zapis - uspesen sprejem',
			   '11' => 'kontrolni zapis - zavrnitev paketa',
			   '22' => 'kontrolni zapis - ponovitev prenosa',
			   '90' => 'vodilni zapis',
			   '91' => 'delni zbirni zapis - posebna poloznica',
			   '92' => 'delni zbirni zapis - posebna nakazilnica',
			   '93' => 'delni zbirni zapis - direktna odobritev',
			   '99' => 'zbirni zapis');
	return $types{$status};
}
sub SifrantStatusS2($){
	my $s2 = shift;
	my $s2Opis;
	if(!defined $s2){
		return "";
	}
	if ($s2 eq '0'){
		$s2Opis = "knjizenje";
	}
	elsif($s2 eq '1'){
		$s2Opis = "sotrnacija";
	}
	return $s2Opis;
}
sub SifrantStatusS3($){
	my $s3 = shift;
	my $s3Opis;
	if(!defined $s3){
		return "";
	}
	if ($s3 eq '00'){
		$s3Opis = "TRR rezidenta";
	}
	elsif($s3 eq '01'){
		$s3Opis = "gotovina(uporablja se samo pri poslovanju s PP in PN)";
	}
	elsif($s3 eq '10'){
		$s3Opis = "TRR nerezidenta";
	}
	elsif($s3 eq '11'){
		$s3Opis = "Ziro racun obcanov";
	}
	elsif($s3 eq '12'){
		$s3Opis = "Devizni racun obcanov";
	}
	elsif($s3 eq '13'){
		$s3Opis = "Hranilne vloge obvanov";
	}
	elsif($s3 eq '14'){
		$s3Opis = "Potrosniska posojila obvanov";
	}
	elsif($s3 eq '15'){
		$s3Opis = "Tekoci racuni obcanov";
	}
	elsif($s3 eq '16'){
		$s3Opis = "Stanovanjska posojila za obcane";
	}
	elsif($s3 eq '21'){
		$s3Opis = "Ziro racun neretidenta";
	}
	elsif($s3 eq '25'){
		$s3Opis = "tekoci racun nerezidenta";
	}
	elsif($s3 eq '31'){
		$s3Opis = "Krediti rebubliskega stanovanjskega sklada";
	}
	elsif($s3 eq '32'){
		$s3Opis = "EKO krediti";
	}
	elsif($s3 eq '33'){
		$s3Opis = "Krediti pravnih oseb";
	}
	elsif($s3 eq '52'){
		$s3Opis = "Nacionalna varcevalna stanovanjska shema NSVS";
	}
	elsif($s3 eq '53'){
		$s3Opis = "Rentno varcevanje";
	}
	elsif($s3 eq '54'){
		$s3Opis = "varcevanja";
	}
	elsif($s3 eq '55'){
		$s3Opis = "Plus varcevanje";
	}
	elsif($s3 eq '56'){
		$s3Opis = "Varcevalni racun";
	}
	elsif($s3 eq '57'){
		$s3Opis = "Varcevalna knjizica";
	}
	elsif($s3 eq '58'){
		$s3Opis = "vplacila v investicijske sklade";
	}
	elsif($s3 eq '59'){
		$s3Opis = "BanKredit";
	}
	elsif($s3 eq '80'){
		$s3Opis = "Elektronski zajem - KLIK, ...";
	}
	elsif($s3 eq '81'){
		$s3Opis = "Placilo na bankomatu";
	}
	elsif($s3 eq '88'){
		$s3Opis = "Krediti obvanov";
	}
	return $s3Opis;
	

}
sub SifrantStatusS4($){
	my $s4 = shift;
	my $s4Opis;
	if(!defined $s4){
		return "";
	}
	if ($s4 eq '01'){
		#Promet
		$s4Opis = "Promet";
	}
	elsif($s4 eq '02'){
		$s4Opis = "Otvoritev";
	}
	elsif($s4 eq '03'){
		$s4Opis = "Ukinitev";
	}
	elsif($s4 eq '04'){
		$s4Opis = "Sprememba";
	}
	elsif($s4 eq '05'){
		$s4Opis = "Preverjanje racuna";
	}
	return $s4Opis;
}
sub SifrantStatusS5($){
	my $s5 = shift;
	my $s5Opis;
	if(!defined $s5){
		return "";
	}
	if ($s5 eq '01'){
		#Azuriranje zneska
		$s5Opis = 'Azuriranje zneska';
	}
	elsif ($s5 eq '02'){
		#Placilo uspesno izvedeno
		$s5Opis = 'Placilo uspesno izvedeno';
	}
	elsif ($s5 eq '03'){
		#Placilo se ni uspesno izvedlo
		$s5Opis = 'Placilo se ni uspesno izvedlo';
	}
	elsif($s5 eq '05'){
		$s5Opis = 'DO al TN se ni uspesno izvedel zaradi neskladnosti denarnega in podatkovnega toka (maticna banka ni prejela ustreznega denarnega kritja)';
	}
	elsif ($s5 eq '06'){
		#Odteglaj DB se ni uspesno izvedel - napacna DB dolznika
		$s5Opis = 'Odteglaj DB se ni uspesno izvedel - napacna DB dolznika';
	}
	elsif ($s5 eq '07'){
		#Odteglaj DB se ni uspesno izvedel - neobstojeca oznaka DB upnika
		$s5Opis = 'Odteglaj DB se ni uspesno izvedel - neobstojeca oznaka DB upnika';
	}
	elsif ($s5 eq '10') {
		$s5Opis = 'Preverjanje racuna';
	}
	elsif ($s5 eq '11') {
		$s5Opis = 'Racun je pravilen';
	}
	elsif ($s5 eq '12'){
		#Racun ni pravilen
		$s5Opis = 'Racun ni pravilen';
	}
	elsif ($s5 eq '13'){
		#Racun je zaprt
		$s5Opis = 'Racun je zaprt';
	}
	elsif ($s5 eq '14'){
		#ni tazpolozljivega kritja DB
		$s5Opis = 'ni tazpolozljivega kritja DB';
	}
	elsif ($s5 eq '16'){
		#Enkratni ugovor na placilo DB s strani dolznika oz. placnika.
		#	(nestrinjanje z visino bremenitve)
		$s5Opis = 'Enkratni ugovor na placilo DB s strani dolznika oz. placnika.'.
				'(nestrinjanje z visino bremenitve)';
	}
	#Otvoritev
	elsif ($s5 eq '21'){
		#Banka obvesca upnika, da je dolznik oz. placnik pri banki odprl DB
		$s5Opis = 'Banka obvesca upnika, da je dolznik oz. placnik pri banki odprl DB';
	}
	elsif ($s5 eq '22'){
		#Zavrnitev otvoritve DB s strani upnika - podatki, ki jih je posredovala banka
		#  obvesca upnika, se ne ujemajo s podatki  v INFO tabeli (odgovor na status 20 in 21)
		$s5Opis = 'Zavrnitev otvoritve DB s strani upnika - podatki, ki jih je posredovala banka'.
				'obvesca upnika, se ne ujemajo s podatki  v INFO tabeli (odgovor na status 20 in 21)';
	}
	#Ukinitev
	elsif ($s5 eq '30'){
		#upnik obvesca banko, da je dolznik oz. placnik pri upniku ukinil DB
		$s5Opis = 'upnik obvesca banko, da je dolznik oz. placnik pri upniku ukinil DB';
	}
	elsif ($s5 eq '31'){
		#banka obvesca upnika, da je dolznik oz. placnik pri banki ukinil DB
		$s5Opis = 'banka obvesca upnika, da je dolznik oz. placnik pri banki ukinil DB';
	}
	elsif ($s5 eq '32'){
		#banka obvesca upnika, da je ukinila konkretno DB brez pooblastila placnika
		$s5Opis = 'banka obvesca upnika, da je ukinila konkretno DB brez pooblastila placnika';
	}
	#Sprememba
	elsif ($s5 eq '41'){
		#Sprememba frekvence placila s strani placnika v banki (pri upniku placnik
		#  ne more spremeniti frekvence)
		$s5Opis = 'Sprememba frekvence placila s strani placnika v banki (pri upniku placnik'.
				'ne more spremeniti frekvence)';
	}
	elsif ($s5 eq '52'){
		#placilo uspesno izvedeno - SPREMEMBA: odprt transakcijski racun
		$s5Opis = 'placilo uspesno izvedeno - SPREMEMBA: odprt transakcijski racun'
	}
	elsif ($s5 eq '53'){
		#Placilo se ni uspesno izvedlo. Placnik ima z banko sklenjeno pogodbo oz.
		#  podpisano pooblastilo, z drugacno frekvenco obremenitve (velja pri DB)
		$s5Opis = 'Placilo se ni uspesno izvedlo. Placnik ima z banko sklenjeno pogodbo oz.'.
			"podpisano pooblastilo, z drugacno frekvenco obremenitve (velja pri DB)";
	}
	
	return $s5Opis;

}
sub SifrantNapakS9($){
	
	my $string= shift;
	my @array = split(//, $string);
	my $return = "";
	foreach my $id (@array){
		if($id eq "1"){
			$return .="<span title='Napaka pri pregledu dolzine zapisa in pravilnosti strukture'>".$id." - napacna struktura zapisa</span><br />";	
		}
		elsif($id eq "2"){
			$return .="<span title='Napaka pri pregledu obstoja vodilnega zapisa oz. pregledu pravilnosti oznake vodilnega zapisa'>".$id." - napaka pri vodilnem zapisu</span><br />";		
		}
		elsif($id eq "3"){
			$return .="<span title='Napaka pri pregledu obstoja zbirnega zapisa oz. pregledu pravilnosti oznake zbirnega zapisa'>".$id." - napacna pri zbirnem zapisu</span><br />";		
		}
		elsif($id eq "4"){
			$return .="<span title='Napaka pri pregledu pravilnega posiljatelja podatkov'>".$id." - neustrezen posiljatelj podatkov.</span><br />";		
		}
		elsif($id eq "R"){
			$return .="<span title='Konkretni racun komitenta s konkretno storitvijo ni prisoten v Centralnem registru ZC oz. je le ta blokiran'>".$id." - neustrezen racun komitenta</span><br />";		
		}
		elsif($id eq "T"){
			$return .="<span title='V zbirnem zapisu se mora to polje ujemati s skupnim stevilom transakcij v paketu'>".$id." - napaka pri stevilu transakcij v zbirnem zapisu</span><br />";		
		}
		elsif($id eq "Z"){
			$return .="<span title='V zbirnem zapisu se mora to polje ujemati s skupnim zneskom transakcij v paketu'>".$id." - napaka pri znesku v zbirnem zapisu</span><br />";		
		}
		elsif($id eq "D"){
			$return .="<span title='Pravocasnost poslanih podatkov v ZC - odvisno od vsake storitve posebej'>".$id." - neustrezen datum</span><br />";		
		}
		elsif($id eq "K"){
			$return .="<span title='Kombinacija kljucnih podatkov v paketu in/ali v bazi podatkov ZC ne sme biti podvojena'>".$id." - podvojenost kombinacije podatkov v paketu in/ali bazi ZC</span><br />";		
		}
		elsif($id eq "I"){
			$return .="<span title='Vrednost id zapisa se v bazi ne sme podvojiti'>".$id." - podvojen id zapisa v bazi ZC</span><br />";		
		}
		elsif($id eq "J"){
			$return .="<span title='Vrednost id zapisa se v paketu ne sme podvojiti'>".$id." - podvojen id zapisa v paketu</span><br />";		
		}
		elsif($id eq "P"){
			$return .="<span title='Vrednost st. paketa se v bazi podatkov ZC ne sme podvojiti'>".$id." - podvojena stevilka paketa v bazi</span><br />";		
		}
		elsif($id eq "B"){
			$return .="<span title='V standardiziranem sifrantu bank poravnalni racun banke ne obstaja'>".$id." - neustrezen poravnalni racun</span><br />";		
		}
		elsif($id eq "5"){
			$return .="<span title='V ZC so prisle obdelane transakcije (2. korak), v bazi ZC pa osnovne transakcije (1. korak) ne obstajajo.'>".$id." - ni zapisa s prvim korakom</span><br />";		
		}
		elsif($id eq "6"){
			$return .="<span title='Dolocene vrednosti v transakciji se med procesom ne smejo spremeniti'>".$id." - vrednosti v kljucnih poljih so spremenjene glede na vrednosti iz prvega koraka</span><br />";		
		}
		elsif($id eq "7"){
			$return .="<span title='V paketu se poleg produkcijskih ne smejo nahajati tudi testni zapisi'>".$id." - paket vsebuje produkcijske in testne zapise</span><br />";		
		}
		elsif($id eq "8"){
			$return .="<span title='Ta vrednost se pojavi v naslednjih primerih: \n - v osnovnem zapisu se v polju vrsta informacije nahaja vrednost, ce ta obstaja v sifrantu S4 - Sifrant vrst informacij; \n - V onsovnem zapisu se v polju status nahaja vrednost, ce ta obstaja v sifrantu S5 - Sifrant statusov; \n - za vsako storitev je v naprej doloceno, kaksna kombinacija vrednosti v poljih vrsta informacije - status se lahko pojavi v nekem koraku in v primeru, da je ta kombinacija napacna, se v kontrolnem zapisu nahaja vrednost 8.'>".$id." - napacna kombinacija vrsta informacije - status</span><br />";		
		}
		elsif($id eq "O"){
			$return .="<span title='V paketu niso prisotni podatki, ki so obvezni za neko storitev'>".$id." - obvezni podatki manjkajo</span><br />";		
		}
		elsif($id eq "N"){
			$return .="<span title='Ce se v zapisu na mestu numericnega polja nahajajo presledki in ne nicle'>".$id." - nepravilna struktura zapisa</span><br />";		
		}
		elsif($id eq "S"){
			$return .="<span title='St. paketa in id zapisa sta standardizirana in morata vsebovati tocno dolocene podatke iniciatorja (DS na prvih osmih mestih)'>".$id." - pravilnost generiranje st. paketa oz. id osnovnega zapisa</span><br />";		
		}
	}
	return $return;
}
sub PrikaziVsebinoDatoteke_old(){
    my $self = shift;
    my $q = $self->query();
    my $seja  ;
    
    my $rez_izps;
    #Izpise vsebino datoteke, kjer se potrjujejo vrstice
	my $izbrana_datoteka;
	my $dbh;
	my $dbh_pogodba;
	my $cas;
	my $datum_dogodka;
	my $id_datoteka;
	my $namen;
	my @prijave_donatorjev;	
	
	my @placila_direktnih;
	my @placila_poloznic;
	my @napake_direktnih;
	my @napake_direktnih_neznana;
	my @napake_poloznic;
	my @preverjanje_racuna_direktne;
	my @tb01promet;
	my @tb02otvoritev;
	my @tb03ukinitev;
	my @tb04sprememba;
	my $res;
	my $res_pogodba;
	my $s1 ='';
	my $s4;
	my $s5;
	my @sprememba_direktnih;
	my $sql_vprasaj;
	my $sql_vprasaj_pogodba;
	my $status;
	
	my $sth;
	my $sth_pogodba;
	my $stornirano;
	my @ukinitev_direktnih;
	my $vrstica;
	my $zap_st_dolznika;    
	my $znesek;
	my $znesek_beseda;
	my $id_zapisa;
	
	
	$izbrana_datoteka = $q->param("datoteka");
	$id_datoteka = $q->param("id_datoteka");
	$rez_izps = $q->p("Potrjujem datoteko: <b>".$izbrana_datoteka."</b>");
	$dbh = DntFunkcije::connectDB;
	$dbh_pogodba = DntFunkcije::connectDB;   
	if ($dbh) {
		
		my $le_vrstica;
		my $pogodba;
		my $s5Opis;
		my $napaka_opis;
		my $poravnalni_racun;
		#my $nasel_vrstico;
		my $zap_st_ze_vpisana;
		my $znesek_dolzina;
		my $znesek_celi;
		my $znesek_dec;
		my $query_handle;
		my $rez;
		my @tabelica;
		my $test;
		my $trr_projekt;
		#Precitano is sfr_agreement
		my $db_amount;
		my $db_bank_account;
		my $db_id_agreement;
		my $db_id_donator;
		my $db_id_vrstice;
		my $db_ime;
		my $db_trr_donor;
		my $db_zap_st_dolznika;
		my $db_ulica;
				
		my $nasel_pogodbo; #'1'nasel pogodbo, '0' ni nasel pogodbe
		$trr_projekt = '';
		
		$sql_vprasaj = "SELECT vsebina_vrstice, id_vrstce, trr_projekt, s1_vrsta_zapisa , ".
				" s2_vrsta_knjizenja ,  s4_vrsta_informacije ,  s5_status ,  potrjeno ".
				" FROM datoteke_vsebina WHERE (id_datoteka =? AND potrjeno = ?) ".
				" ORDER BY id_vrstce ASC";
				#" ORDER BY trr_projekt, s4_vrsta_informacije ASC";
			
		#print $q->p($sql_vprasaj);
		$sth = $dbh->prepare($sql_vprasaj);
		$sth->execute($id_datoteka, 0);
		#return $sql_vprasaj."    ".$id_datoteka;
		#   $sth->bind_columns(undef, \$vrstica ); #, \$product, \$quantity);
		#while ($res = $sth->fetchrow_hashref)
		$rez = $sth->fetchall_arrayref ;
		#@tabelica = $sth->fetchall_arrayref ;
		@tabelica = @{$rez};
		#while()
		#$ref = $sth->fetchall_hashref('id');
		#foreach $key ( keys(%{$ref}) ) {
		#print $q->p("@tabelica\n");
		#print $q->p("-----------------konc");
                #return $#tabelica.$izbrana_datoteka;
                $le_vrstica = '';
				
		my $tabela = $q->start_table({-border=>"1"});
			$tabela .=  $q->Tr
			(
				$q->th
				([
					$q->p('Vrsta zapisa'),
					$q->p('Id zapisa'),
					$q->p('Stornirano'),
					$q->p('Datum'),
					$q->p('Znesek'),
					$q->p('Oznaka valute'),
					$q->p('Racun komitenta ZC'),
					$q->p('Referencna stevilka/sklic'),
					$q->p('Namen'),
					$q->p('Sifra nakazila'),
					$q->p('Poravnalni racun'),
					$q->p('enota'),
				])
			);
		foreach $vrstica (@tabelica) #(@{$rez})		
		{
			$s5Opis = '';
			$le_vrstica = join(',',@$vrstica[0]);
			
			#return $le_vrstica." vrstica:".$vrstica;
                        #if (length("@$vrstica")>200){
                        #    $le_vrstica = "@$vrstica";
                        #}
			#print $q->p(@$vrstica[1]);
                    #$db_id_vrstice = @$vrstica[1];
                    #$trr_projekt = substr("@$vrstica",53,18);
                    #$namen = substr("@$vrstica",91,35);
                    #$pogodba = substr("@$vrstica",71,20);
                    #$s1 = substr("@$vrstica",0,2);
                    #$stornirano = substr("@$vrstica",26,1);
                    #$datum_dogodka = substr("@$vrstica",27,8);
                    #$poravnalni_racun = substr("@$vrstica",129,15);
                    #$s4 = substr("@$vrstica",164,2);
                    #$s5 = substr("@$vrstica",166,2);
                    #$zap_st_dolznika = substr("@$vrstica",178,10);
                    #$znesek_beseda  = substr("@$vrstica",35,15);
                    #$znesek_dolzina = length($znesek_beseda);
                    #$znesek = (substr("@$vrstica",35,13).'.'.substr("@$vrstica",48,2)+0);
                    #$poravnalni_racun = DntFunkcije::trim($poravnalni_racun);
                    #$db_trr_donor = DntFunkcije::trim($db_trr_donor);
                    
            $db_id_vrstice = @$vrstica[1];
			
			
			
			
			
			$s1 = substr($le_vrstica,0,2);
			$id_zapisa = substr($le_vrstica,2,24);
			$stornirano = substr($le_vrstica,26,1);
			$datum_dogodka = substr($le_vrstica,27,8);			
			$znesek_beseda  = substr($le_vrstica,35,15);
				$znesek_celi = 	DntFunkcije::trim(substr($le_vrstica,35,13));                        
				$znesek_dec = DntFunkcije::trim(substr($le_vrstica,48,2));
				$znesek = ($znesek_celi.'.'.$znesek_dec+0);
			my $valuta = substr($le_vrstica,50,3);
			$trr_projekt = substr($le_vrstica,53,18);
			$pogodba = substr($le_vrstica,71,20);
			$namen = substr($le_vrstica,91,35);
			$poravnalni_racun = substr($le_vrstica,129,15);
			$s4 = substr($le_vrstica,164,2);
			$s5 = substr($le_vrstica,166,2);
			$zap_st_dolznika = substr($le_vrstica,178,10);
			
			
			$znesek_dolzina = length($znesek_beseda);
			$poravnalni_racun = DntFunkcije::trim($poravnalni_racun);
                        
			#$db_trr_donor = DntFunkcije::trim($db_trr_donor);
                        
			#Dobi komentar k sifri S4
			if ($s4 eq '01'){
				#Promet
				if ($s5 eq '01'){
					#Azuriranje zneska
					$s5Opis = 'Azuriranje zneska';
				}
				elsif ($s5 eq '02'){
					#Placilo uspesno izvedeno
					$s5Opis = 'Placilo uspesno izvedeno';
				}
				elsif ($s5 eq '03'){
					#Placilo se ni uspesno izvedlo
					$s5Opis = 'Placilo se ni uspesno izvedlo';
				}
				elsif($s5 eq '05'){
					$s5Opis = 'DO al TN se ni uspesno izvedel zaradi neskladnosti denarnega in podatkovnega toka (maticna banka ni prejela ustreznega denarnega kritja)';
				}
				elsif ($s5 eq '06'){
					#Odteglaj DB se ni uspesno izvedel - napacna DB dolznika
					$s5Opis = 'Odteglaj DB se ni uspesno izvedel - napacna DB dolznika';
				}
				elsif ($s5 eq '07'){
					#Odteglaj DB se ni uspesno izvedel - neobstojeca oznaka DB upnika
					$s5Opis = 'Odteglaj DB se ni uspesno izvedel - neobstojeca oznaka DB upnika';
				}
				elsif ($s5 eq '10') {
					$s5Opis = 'Preverjanje racuna';
				}
				elsif ($s5 eq '11') {
					$s5Opis = 'Racun je pravilen';
				}
				elsif ($s5 eq '12'){
					#Racun ni pravilen
					$s5Opis = 'Racun ni pravilen';
				}
				elsif ($s5 eq '13'){
					#Racun je zaprt
					$s5Opis = 'Racun je zaprt';
				}
				elsif ($s5 eq '14'){
					#ni tazpolozljivega kritja DB
					$s5Opis = 'ni tazpolozljivega kritja DB';
				}
				elsif ($s5 eq '16'){
					#Enkratni ugovor na placilo DB s strani dolznika oz. placnika.
					#	(nestrinjanje z visino bremenitve)
					$s5Opis = 'Enkratni ugovor na placilo DB s strani dolznika oz. placnika.'.
							'(nestrinjanje z visino bremenitve)';
				}
			}
			elsif ($s4 eq '02'){
				#Otvoritev
				if ($s5 eq '21'){
					#Banka obvesca upnika, da je dolznik oz. placnik pri banki odprl DB
					$s5Opis = 'Banka obvesca upnika, da je dolznik oz. placnik pri banki odprl DB';
				}
				elsif ($s5 eq '22'){
					#Zavrnitev otvoritve DB s strani upnika - podatki, ki jih je posredovala banka
					#  obvesca upnika, se ne ujemajo s podatki  v INFO tabeli (odgovor na status 20 in 21)
					$s5Opis = 'Zavrnitev otvoritve DB s strani upnika - podatki, ki jih je posredovala banka'.
							'obvesca upnika, se ne ujemajo s podatki  v INFO tabeli (odgovor na status 20 in 21)';
				}
			}
			elsif ($s4 eq '03'){
				#Ukinitev
				if ($s5 eq '30'){
					#upnik obvesca banko, da je dolznik oz. placnik pri upniku ukinil DB
					$s5Opis = 'upnik obvesca banko, da je dolznik oz. placnik pri upniku ukinil DB';
				}
				elsif ($s5 eq '31'){
					#banka obvesca upnika, da je dolznik oz. placnik pri banki ukinil DB
					$s5Opis = 'banka obvesca upnika, da je dolznik oz. placnik pri banki ukinil DB';
				}
				elsif ($s5 eq '32'){
					#banka obvesca upnika, da je ukinila konkretno DB brez pooblastila placnika
					$s5Opis = 'banka obvesca upnika, da je ukinila konkretno DB brez pooblastila placnika';
				}
			}
			elsif ($s4 eq '04'){
				#Sprememba
				if ($s5 eq '41'){
					#Sprememba frekvence placila s strani placnika v banki (pri upniku placnik
					#  ne more spremeniti frekvence)
					$s5Opis = 'Sprememba frekvence placila s strani placnika v banki (pri upniku placnik'.
							'ne more spremeniti frekvence)';
				}
				elsif ($s5 eq '52'){
					#placilo uspesno izvedeno - SPREMEMBA: odprt transakcijski racun
					$s5Opis = 'placilo uspesno izvedeno - SPREMEMBA: odprt transakcijski racun'
				}
				elsif ($s5 eq '53'){
					#Placilo se ni uspesno izvedlo. Placnik ima z banko sklenjeno pogodbo oz.
					#  podpisano pooblastilo, z drugacno frekvenco obremenitve (velja pri DB)
					$s5Opis = 'Placilo se ni uspesno izvedlo. Placnik ima z banko sklenjeno pogodbo oz.'.
						"podpisano pooblastilo, z drugacno frekvenco obremenitve (velja pri DB)";
				}
			}
			if($s1 eq "90"){
				#vodilni zapis:
				my $vodilni_zapis="St. transakcij v datoteki: ".substr($le_vrstica, 20, 6)."<br />".
								  "Datum kreiranja datoteke: ".DntFunkcije::sl_date(substr($le_vrstica, 27, 4)."-".
																					substr($le_vrstica, 31, 2)."-".
																					substr($le_vrstica, 33, 2))."<br />";
				$rez_izps .= $vodilni_zapis;			
				
			}
			elsif ($s1 eq "04")
			{
				#Gre za direktne bremenitve
				if ($stornirano =='1')
				{
					#Gre za stornirano knji?bo                    
					push(@napake_direktnih_neznana,{$pogodba, $namen, $zap_st_dolznika, 'Storniranje pogodbe'});
					
				}
				else
				{
					
					#gre za knjizbo
					#Preveri ali pogodba obstaja, ali zap. ?t. dolznika obstaja oz. se ujema
					
					
					$sql_vprasaj_pogodba = "SELECT id_agreement, first_name , zap_st_dolznika,".
							" id_donor , name_company, scnd_name, street,".
							" trr_donor, bank_account2, amount2  FROM sfr_agreement WHERE id_agreement = ?";
					#chomp($sql_vprasaj_pogodba);
                                        
					#$sth_pogodba = $dbh_pogodba->prepare($sql_vprasaj_pogodba);
                                        $sth_pogodba = $dbh->prepare($sql_vprasaj_pogodba);
                                        #return $pogodba.'c'.$sql_vprasaj_pogodba;
					$sth_pogodba->execute($pogodba);
                                        
					$nasel_pogodbo = 0;
					$db_zap_st_dolznika = '';
					#$zap_st_dolznika = 0;
					#$res_pogodba = $sth_pogodba->fetchrow_hashref;
					$db_amount = "";
					$db_bank_account = "";
					$db_trr_donor = "";
					$db_ulica = "";
					$db_ime = "";
					$db_id_donator = "";					
					if($res_pogodba = $sth_pogodba->fetchrow_hashref) {#ce smo dobil vrstico	
						if($res_pogodba->{'id_agreement'}== $pogodba){
							$nasel_pogodbo = '1';
						}
						$test = $res_pogodba->{'id_agreement'}; #$res_pogodba->('id_agreement');						
						#$test = ($res_pogodba->{'id_agreement'});#zap_st_dolznika'};
						if ($res_pogodba->{'zap_st_dolznika'} == undef)	{
							$db_zap_st_dolznika = '';
						}
						else {
							$db_zap_st_dolznika = $res_pogodba->{'zap_st_dolznika'};
						}	
						if ($res_pogodba->{"id_donor"} eq undef)	{
							$db_id_donator = '';
						}
						else {
							$db_id_donator = $res_pogodba->{'id_donor'};
						}
						if ($res_pogodba->{"name_company"} eq undef)	{
							$db_ime = '';
						}
						else {
							$db_ime = $res_pogodba->{'name_company'};
						}
						if ($res_pogodba->{"first_name"} eq undef)	{
							
						}
						else {
							$db_ime .= $res_pogodba->{'first_name'};
						}						
						if ($res_pogodba->{'scnd_name'} eq undef)	{
							
						}
						else {
							$db_ime .= " ".$res_pogodba->{'scnd_name'};
						}
						if ($res_pogodba->{'street'} eq undef)	{
							$db_ulica = '';
						}
						else {
							$db_ulica = $res_pogodba->{'street'};
						}
						if ($res_pogodba->{'trr_donor'} eq undef)	{
							$db_trr_donor = '';
						}
						else {
							$db_trr_donor= $res_pogodba->{'trr_donor'};
							$db_trr_donor = DntFunkcije::trim($db_trr_donor);
						}
						if ($res_pogodba->{'bank_account2'} == undef)	{
							$db_bank_account = '';
						}
						else {
							$db_bank_account= $res_pogodba->{'bank_account2'};
							$db_bank_account = DntFunkcije::trim($db_bank_account);
						}
						if ($res_pogodba->{'amount2'} == undef)	{
							$db_amount = '';
						}
						else {
							$db_amount= $res_pogodba->{'amount2'};
						}
						$db_trr_donor =~ s/-//g;  #Izloci vse '-' iz stevilke
						$db_bank_account =~ s/-//g; #Izloci vse '-' iz stevilke
						#print $q->p((length(DntFunkcije->trim($res_pogodba->('zap_st_dolznika')))))# &&
							#!(DntFunkcije->trim($res_pogodba->('zap_st_dolznika')) eq (DntFunkcije->trim($zap_st_dolznika))));
					}
					else {
						$nasel_pogodbo = '0';
						push(@napake_direktnih_neznana,$vrstica);
					}
					$napaka_opis ='';
					
					if($s4 eq '02'){ #($znesek ==0) && (length($zap_st_dolznika)>0) ) {
						#Prijava donatorja						
						if ($nasel_pogodbo eq '0') {
							#ne najde pogodbe med vpisanimi pogodbami
							$napaka_opis  .= "ne najdem pogodbe<br>";
							#push(@prijave_donatorjev,[$pogodba, $namen, $zap_st_dolznika, "ne najdem pogodbe"]);
						}
						elsif ((length($db_zap_st_dolznika)>0) &&
							   !(($db_zap_st_dolznika) eq ($zap_st_dolznika))) {
							#!(DntFunkcije->trim($db_zap_st_dolznika) eq (DntFunkcije->trim($zap_st_dolznika))))
							$napaka_opis .= "napaka. Zap_st_dolznika se ne ujemta: v bazi zapisana".$db_zap_st_dolznika."<br>";
							#push(@prijave_donatorjev,[$pogodba, $namen, $zap_st_dolznika, "napaka. Zap_st_dolznika se ne ujemta: v bazi zapisana".$db_zap_st_dolznika]); #.$res_pogodba->('zap_st_dolznika')]);
						}
						else {
							#push(@prijave_donatorjev,[$pogodba, $namen, $zap_st_dolznika, 'OK']);
							$napaka_opis = 'OK';
							#push(@napake_direktnih,[$pogodba, $namen, $zap_st_dolznika, '@e vpisana v pogodbo']);
						}
						push(@prijave_donatorjev,[$pogodba, $namen, $zap_st_dolznika, $napaka_opis, $nasel_pogodbo, $trr_projekt, $s4, $s5, $s5Opis, $datum_dogodka, $db_id_vrstice]);
					}
					elsif ($s4 eq '01'){  #($znesek >0) && length($zap_st_dolznika)>0 ){                        
						#Potrjevanje placila	
						if( $nasel_pogodbo eq '1') {							
							if ($zap_st_dolznika eq $db_zap_st_dolznika) {
								if ($poravnalni_racun eq $db_trr_donor &&
										$znesek == $db_amount ){
									#Lahko se obrok oznaci kot placan
									$napaka_opis = 'OK';
									#push(@placila_direktnih,[$pogodba, $namen, $znesek, $zap_st_dolznika, $db_id_donator, $db_ime, $db_ulica, $poravnalni_racun, 'OK']);
								}
								else{
									if (!($poravnalni_racun eq $db_trr_donor)){
										$napaka_opis = "napaka. Poravnalni racun se ne ujema z racunom na pogodbi:".$db_trr_donor."<br>";
									}
									if (!($znesek == $db_amount)){
										$napaka_opis = $napaka_opis."napaka. Znesek na bremenitvi ni enak kot na pogodbi<br>"
									}
									#push(@placila_direktnih,[$pogodba, $namen, $znesek, $zap_st_dolznika, $db_id_donator, $db_ime, $db_ulica, $poravnalni_racun, $napaka_opis]);
								}
								
							}
							else {
								$napaka_opis = 'napaka.  Zap_st_dolznika se ne ujemta: v bazi zapisana '.$db_zap_st_dolznika."<br>";
								#push(@placila_direktnih,[$pogodba, $namen, $znesek, $zap_st_dolznika, $db_id_donator, $db_ime, $db_ulica, $poravnalni_racun, 'napaka.  Zap_st_dolznika se ne ujemta: v bazi zapisana '.$db_zap_st_dolznika]);
							}
						}
						else {
							#ne najde pogodbe
							#push(@placila_direktnih,[$pogodba, $namen,$znesek, $zap_st_dolznika, "", "", "", $poravnalni_racun, 'napaka.  Ne najdem pogodbe']);
							$napaka_opis .= 'napaka.  Ne najdem pogodbe';
						}
						push(@placila_direktnih,[$pogodba, $namen, $znesek, $zap_st_dolznika, $db_id_donator, $db_ime, $db_ulica, $poravnalni_racun, $napaka_opis, $nasel_pogodbo, $trr_projekt, $s4, $s5, $s5Opis, $datum_dogodka, $db_id_vrstice]);
					}
					elsif ($s4 eq '03'){
						#Ukinitev
						#push(@tb03ukinitev,[$pogodba, $namen, $znesek, $zap_st_dolznika, $db_id_donator, $db_ime, $db_ulica, $poravnalni_racun, $napaka_opis, $nasel_pogodbo, $trr_projekt, $s4, $s5, $s5Opis]);
						push(@tb03ukinitev,[$pogodba, $namen, $zap_st_dolznika, $napaka_opis, $nasel_pogodbo, $trr_projekt, $s4, $s5, $s5Opis, $datum_dogodka, $db_id_vrstice]);
					}
					elsif ($s4 eq '04'){
						#Sprememba
						#push(@tb04sprememba,[$pogodba, $namen, $znesek, $zap_st_dolznika, $db_id_donator, $db_ime, $db_ulica, $poravnalni_racun, $napaka_opis, $nasel_pogodbo, $trr_projekt, $s4, $s5, $s5Opis]);
						push(@tb04sprememba,[$pogodba, $namen, $zap_st_dolznika, $napaka_opis, $nasel_pogodbo, $trr_projekt, $s4, $s5, $s5Opis, $datum_dogodka, $db_id_vrstice]);
					}
					else {
						#Napaka
						#push(@napake_direktnih_neznana,{$pogodba, $namen, $zap_st_dolznika, 'neznana napaka'});
					}
				}				
			}
			
			

			
			
			elsif($s1 eq '01')
			{
				$tabela .= $q->Tr
				(
					$q->td
					([
						$q->p('Posebna poloznica'),
						$q->p($id_zapisa),
						$q->p($stornirano),
						$q->p(($datum_dogodka)),
						$q->p($znesek),
						$q->p($valuta),
						$q->p($trr_projekt),
						$q->p($pogodba),
						$q->p($namen),
						$q->p($poravnalni_racun),
						$q->p($zap_st_dolznika),
					])
				);	
				#Gre za posebne poloznice
				#$rez_izps .= $pogodba." $le_vrstica";			
				
			}
			else
			{
				#push(@napake_direktnih_neznana,{$pogodba, $namen, $zap_st_dolznika, 'neznana napaka'});
			}
			
		
		}
		#return "prvi del";
		my $celice;
		my $nov_trr;
		my $s5_nov;
		$tabela .= $q->end_table();
		$rez_izps .= $tabela; 
		
		
		if($#prijave_donatorjev>=0)
		{
			$s5_nov = "";
			$rez_izps .= $q->start_table({-border=>"1"});
			$rez_izps .=  $q->Tr
			(
				$q->th
				([
					$q->p('Pogodba'),
					$q->p('Namen'),
					$q->p('Zap. {t. dol`nika'),
					$q->p('Status'),
				])
			);		
			$rez_izps .=  $q->p("prijave donatorjev ".($#prijave_donatorjev+1)." vrstic");
			$rez_izps .=  $q->start_Tr;
			#DELA foreach $vrstica (sort {$a->[3] cmp $b->[3]} @prijave_donatorjev)
			foreach $vrstica (sort {$a->[6] cmp $b->[6]
									||
									$a->[7] cmp $b->[7]
									} @prijave_donatorjev)
			{
				if (length($s5_nov) == 0){
					$s5_nov = @$vrstica[7];
					$s5 = @$vrstica[7];
					$rez_izps .=  $q->td({-colspan=>5}, "<b><i>"."S5:".$s5." ".@$vrstica[8]);
					$rez_izps .=  $q->end_Tr;
				}
				$pogodba = @$vrstica[0];
				$namen = @$vrstica[1];
				$zap_st_dolznika = @$vrstica[2];
				$status = @$vrstica[3];
				$nasel_pogodbo = @$vrstica[4];
				$s4 = @$vrstica[6];
				$s5 = @$vrstica[7];
				$db_id_vrstice = @$vrstica[10];
				if ($s5 ne $s5_nov){
					$s5_nov = $s5;
					$rez_izps .=  $q->td({-colspan=>5}, "<b><i>"."S5:".$s5." ".@$vrstica[13]);					
					$rez_izps .=  $q->end_Tr;
					
				}
				
				if ($status eq 'OK' and $s4 eq '02' and $s5 eq '21')
				{					
					$rez_izps .=  $q->td("<input type='checkbox' name='izbrane_prijave' value='".$pogodba."#".$zap_st_dolznika."#".$db_id_vrstice."' checked  >".$q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
				}
				elsif(substr($status,0,2) eq 'OK'){
					$rez_izps .=  $q->td($q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
				}
				elsif(substr($status,0,6) eq 'napaka'){
					if ($nasel_pogodbo eq '1'){
						#print $q->td("<input type='checkbox' name='izbrane_prijave' value='".$pogodba."#".$zap_st_dolznika."' -checked  >".$q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
						$rez_izps .=  $q->td($q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
					}
					else{
						$rez_izps .=  $q->td($pogodba);
					}					
				}
				else
				{
					$rez_izps .=  $q->td($pogodba);
				}
				$rez_izps .=  $q->td($namen);
				$rez_izps .=  $q->td($zap_st_dolznika);
				$rez_izps .=  $q->td($status."s4:".$s4."s5:".$s5.$nasel_pogodbo);
				$rez_izps .=  $q->end_Tr;
				
			}
			$rez_izps .=  $q->end_table;			
			$rez_izps .=  $q->submit(-name=>"btn_uvozi_zap_st_dolznika", -value=>"Uvozi");
			#print $q->submit(-name=>"btn_uvozi_zap_st_dolznika", -value=>"Uvozi prijave",
			#			 -onClick=>"javascript:dopostback('hid_akcija','btn_izbrane_prijave')");
			$rez_izps .=  $q->submit(-name=>"nepotrjene_datoteke", -value=>"Prekli~i");
		}
		
		if($#placila_direktnih>=0)
		{
			my $i_postavke;
			my $sum_znesek;
			my $sum_sum_znesek;			
			
			$i_postavke = 0;
			$sum_znesek = 0;
			$sum_sum_znesek = 0;
			$rez_izps .=  $q->start_table({-border=>"1"});
			$rez_izps .=  $q->Tr
			(
				$q->th
				([
					$q->p('Pogodba'),
					$q->p('Namen'),
					$q->p('Znesek'),
					$q->p('Zap. {t. dol`nika'),
					$q->p('TRR projekta'),
					$q->p('id donator'),
					$q->p('ime'),
					$q->p('datum bremenitve'),
					$q->p('poravnalni ra~un dol`nika'),
					$q->p('Status'),
				])
			);		
			$rez_izps .=  $q->p("placila direktnih ".($#placila_direktnih+1)." vrstic");
			$rez_izps .=  $q->start_Tr;			
			#@placila_direktnih = sort {$a->[6] cmp $b->[6]} @placila_direktnih;
			#@placila_direktnih = sort {$a->[10] cmp $b->[10] 
			#						||
			#						$a->[7] cmp $b->[7]
			#						} @placila_direktnih;
			#
			#DELA foreach $vrstica (sort {$a->[10] cmp $b->[10]} @placila_direktnih)
			foreach $vrstica (sort {$a->[10] cmp $b->[10] 
									||
									$a->[12] cmp $b->[12]
									} @placila_direktnih)
			#foreach $vrstica (@placila_direktnih)
			{
				if (length($nov_trr) == 0){
					$nov_trr = @$vrstica[10];
					$sum_znesek = 0;
					$s5_nov = @$vrstica[12];
					$s5 = $s5_nov;
					$rez_izps .=  $q->td({-colspan=>10}, "<b><i>"."S5:".$s5." ".@$vrstica[13]);
					$rez_izps .=  $q->end_Tr;
				}
				$pogodba = @$vrstica[0];
				$namen = @$vrstica[1];
				$znesek = @$vrstica[2];
				$zap_st_dolznika = @$vrstica[3];
				$db_id_donator = @$vrstica[4];
				$db_ime = @$vrstica[5];
				$db_ulica = @$vrstica[6];
				$poravnalni_racun = @$vrstica[7];
				$status = @$vrstica[8];
				$nasel_pogodbo = @$vrstica[9];
				$trr_projekt = @$vrstica[10];
				$s4 = @$vrstica[11];
				$s5 = @$vrstica[12];
				$datum_dogodka = @$vrstica[14];
				$db_id_vrstice = @$vrstica[15];
				if ($trr_projekt ne $nov_trr){
					$nov_trr = $trr_projekt;
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td("<b>".DntFunkcije::FormatFinancno($sum_znesek));
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();					
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->end_Tr;
					$sum_znesek = 0;
				}
				if ($s5 ne $s5_nov){
					$s5_nov = $s5;
					$rez_izps .=  $q->td({-colspan=>10}, "<b><i>"."S5:".$s5." ".@$vrstica[13]);					
					$rez_izps .=  $q->end_Tr;
					
				}
				if ($s5 eq '02'){
					$sum_znesek = $sum_znesek + $znesek;
					$sum_sum_znesek = $sum_sum_znesek +$znesek;
				}
				#print $q->p('1x'.@$vrstica[1]);
				#print $q->td("<input type='checkbox' name=$pogodba value=0>".$pogodba);
				if ($status eq 'OK' and $s5 eq '02')
				{
					$rez_izps .=  $q->td("<input type='checkbox' name='placani_obroki_pogodbe' value='".$pogodba."#".$zap_st_dolznika."#".$datum_dogodka."#".$znesek."#".$db_id_vrstice."' checked  >".$q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
				}
				elsif ($status eq 'OK'){
					$rez_izps .=  $q->td($q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
				}
				elsif(substr($status,0,6) eq 'napaka')
				{
					if ($nasel_pogodbo eq '1'){
						#print $q->td("<input type='checkbox' name='placani_obroki_pogodbe' value='".$pogodba."#".$zap_st_dolznika."#".$datum_dogodka."' -checked  >".$q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
						$rez_izps .=  $q->td($q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
					}
					else{
						$rez_izps .=  $q->td($pogodba);
					}
				}
				else
				{
					$rez_izps .=  $q->td($zap_st_dolznika);
				}
				$rez_izps .= $q->td($namen);
				if ($s5 eq '02'){
					$rez_izps .=  $q->td(DntFunkcije::FormatFinancno($znesek));
				}
				else{
					$rez_izps .=  $q->td("(<i>".DntFunkcije::FormatFinancno($znesek).")");
				}				
				$rez_izps .=  $q->td($zap_st_dolznika);
				$rez_izps .=  $q->td($trr_projekt);
				$rez_izps .=  $q->td($q->a({-href=>"DntDonatorEdit.pl?id_donor=$db_id_donator"},$db_id_donator));
				$rez_izps .=  $q->td($q->a({-href=>"DntDonatorEdit.pl?id_donor=$db_id_donator"}, $db_ime));#$db_ime);
				#print $q->td($q->a({-href=>"naslovi.pl?id=$res->{'street'}"}, $res->{'naslov'}));
				#print $q->td($db_ulica);
				$rez_izps .=  $q->td(DntFunkcije::SToD($datum_dogodka));
				$rez_izps .=  $q->td($poravnalni_racun);
				$rez_izps .=  $q->td($status);
				$rez_izps .=  $q->end_Tr;
				
				if ($i_postavke == $#placila_direktnih ){
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td("<b>".DntFunkcije::FormatFinancno($sum_znesek));
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();					
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->end_Tr;
						
						
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td("<b>".DntFunkcije::FormatFinancno($sum_sum_znesek));
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();					
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->td();
					$rez_izps .=  $q->end_Tr;
				}
				$i_postavke = $i_postavke + 1 ;
				
			}
			$rez_izps .=  $q->end_table;			
			$rez_izps .=  $q->submit(-name=>"btn_uvozi_placila_direktnih", -value=>"Uvozi");
			$rez_izps .=  $q->submit(-name=>"Nepotrjene_datoteke", -value=>"Preklici");
			
			
			
			#print $q->p("placila direktnih");
			#foreach $vrstica (@placila_direktnih)
			#{				
			#	foreach $celice (@$vrstica)
			#	{
			#		print $q->p("celica:".$celice);
			#	}
			#	print $q->p("__");
			#}
		}
		
		if($#tb03ukinitev>=0)
		{
			$rez_izps .=  $q->p("Ukinitev ".($#tb03ukinitev+1)." vrstic");
			$rez_izps .=  $q->start_table({-border=>"1"});
			$rez_izps .=  $q->Tr
			(
				$q->th
				([
					$q->p('Pogodba'),
					$q->p('Namen'),
					$q->p('Zap. {t. dol`nika'),
					$q->p('Status'),
				])
			);		
			
			$s5_nov = "";
			$rez_izps .=  $q->start_Tr;
			#DELA foreach $vrstica (sort {$a->[3] cmp $b->[3]} @prijave_donatorjev)
			foreach $vrstica (sort {$a->[6] cmp $b->[6]
									||
									$a->[7] cmp $b->[7]
									} @tb03ukinitev)
			{
				if (length($s5_nov) == 0){
					$s5_nov = @$vrstica[7];
					$s5 = @$vrstica[7];
					$rez_izps .=  $q->td({-colspan=>5}, "<b><i>"."S5:".$s5." ".@$vrstica[8]);
					$rez_izps .=  $q->end_Tr;
				}
				$pogodba = @$vrstica[0];
				$namen = @$vrstica[1];
				$zap_st_dolznika = @$vrstica[2];
				$status = @$vrstica[3];
				$nasel_pogodbo = @$vrstica[4];
				$s4 = @$vrstica[6];
				$s5 = @$vrstica[7];
				$db_id_vrstice = @$vrstica[10];
				#print $q->p('1x'.@$vrstica[1]);
				#print $q->td("<input type='checkbox' name=$pogodba value=0>".$pogodba);
				if ($status eq 'OK')
				{					
					#print $q->td("<input type='checkbox' name='izbrane_ukinitve' value='".$pogodba."#".$zap_st_dolznika."#".$db_id_vrstice."' checked  >".$q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
					$rez_izps .=  $q->td($q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
				}
				elsif(substr($status,0,6) eq 'napaka')
				{
					if ($nasel_pogodbo eq '1'){
						#print $q->td("<input type='checkbox' name='izbrane_ukinitve' value='".$pogodba."".$zap_st_dolznika."' -checked  >".$q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
						$rez_izps .=  $q->td($q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
					}
					else{
						$rez_izps .=  $q->td($pogodba);
					}					
				}
				else
				{
					$rez_izps .=  $q->td($pogodba);
				}
				$rez_izps .=  $q->td($namen);
				$rez_izps .=  $q->td($zap_st_dolznika);
				$rez_izps .=  $q->td($status."s4:".$s4."s5:".$s5);
				$rez_izps .=  $q->end_Tr;
				
			}
			$rez_izps .=  $q->end_table;			
			$rez_izps .=  $q->submit(-name=>"btn_uvozi_ukinitev", -value=>"Uvozi");
			$rez_izps .=  $q->submit(-name=>"Nepotrjene_datoteke", -value=>"Preklici");
		}
		if($#tb04sprememba>=0)
		{
			$rez_izps .=  $q->p("Sprememba ".($#tb04sprememba+1)." vrstic");
			$rez_izps .=  $q->start_table({-border=>"1"});
			$rez_izps .=  $q->Tr
			(
				$q->th
				([
					$q->p('Pogodba'),
					$q->p('Namen'),
					$q->p('Zap. {t. dol`nika'),
					$q->p('Status'),
				])
			);		
			
			$s5_nov = "";
			$rez_izps .=  $q->start_Tr;
			#DELA foreach $vrstica (sort {$a->[3] cmp $b->[3]} @prijave_donatorjev)
			foreach $vrstica (sort {$a->[6] cmp $b->[6]
									||
									$a->[7] cmp $b->[7]
									} @tb04sprememba)
			{
				if (length($s5_nov) == 0){
					$s5_nov = @$vrstica[7];
					$s5 = @$vrstica[7];
					$rez_izps .=  $q->td({-colspan=>5}, "<b><i>"."S5:".$s5." ".@$vrstica[8]);
					$rez_izps .=  $q->end_Tr;
				}
				$pogodba = @$vrstica[0];
				$namen = @$vrstica[1];
				$zap_st_dolznika = @$vrstica[2];
				$status = @$vrstica[3];
				$nasel_pogodbo = @$vrstica[4];
				$s4 = @$vrstica[6];
				$s5 = @$vrstica[7];
				$db_id_vrstice = @$vrstica[10];
				#print $q->p('1x'.@$vrstica[1]);
				#print $q->td("<input type='checkbox' name=$pogodba value=0>".$pogodba);
				if ($status eq 'OK')
				{					
					#print $q->td("<input type='checkbox' name='izbrane_spremembe' value='".$pogodba."#".$zap_st_dolznika."#".$db_id_vrstice."' checked  >".$q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
					$rez_izps .=  $q->td($q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
				}
				elsif(substr($status,0,6) eq 'napaka')
				{
					if ($nasel_pogodbo eq '1'){
						#print $q->td("<input type='checkbox' name='izbrane_spremembe' value='".$pogodba."".$zap_st_dolznika."' -checked  >".$q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
						$rez_izps .=  $q->td($q->a({-href=>"DntPogodbaEdit.pl?id_agreement=$pogodba"},$pogodba));
						
					}
					else{
						$rez_izps .=  $q->td($pogodba);
					}					
				}
				else
				{
					$rez_izps .=  $q->td($pogodba);
				}
				$rez_izps .=  $q->td($namen);
				$rez_izps .=  $q->td($zap_st_dolznika);
				$rez_izps .=  $q->td($status."s4:".$s4."s5:".$s5);
				$rez_izps .=  $q->end_Tr;
				
			}
			$rez_izps .=  $q->end_table;			
			$rez_izps .=  $q->submit(-name=>"btn_uvozi_spremembe", -value=>"Uvozi");
			$rez_izps .=  $q->submit(-name=>"Nepotrjene_datoteke", -value=>"Preklici");
		}
		
		
		
    }
    
    my $html_output;
    #my $izbrana_datoteka;
    my $potrdi_gumb;
    my $template;
    $template = $self->load_tmpl(	    
		'DntBranjeDatotekPotrdiDatoteko.tmpl',
		 cache => 1,
   );
	$template->param(sporocilo => $rez_izps,
					 	   IME_DOKUMENTA => 'Uvoz datoteke',
	   POMOC => "<input type='button' value='?' ".
	   "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
	 );
    $izbrana_datoteka = $q->param('datoteka');
    return $template->output; #$izbrana_datoteka;
    
    
}

sub BrisiDatotekoVprasaj(){
   #Izpise seznam datotek, ki se nimajo dokoncno potrjenih postavk
    my $self = shift;
    my $q = $self->query();
	my @izbrane_datoteke = $q->param("izbrane_datoteke");
    my $seja  ;
    
    my $datoteka;
    my $datum;
    my $html_output;
	my $id_brisi;
    my @loop;
    my $rez;
	my $vrstica;
	my @tabelca;
    my $template;
    
    
    return "aaa";
    #$rez = $q->p("Seznam nepotrjenih datotek:");
    $template = $self->load_tmpl(	    
				'DntBranjeDatotekNepotrjene.tmpl',
			    cache => 1,
			    );
    $id_brisi ='';           
    foreach $vrstica (@izbrane_datoteke) {
		@tabelca = split(/#/, $vrstica);			
		
		#$vrsta_bremenitve = $tabelca[2];
		#$st_obroka = $tabelca[0];
		$id_brisi .= '#'.$vrstica;
		my %row = (				
				ime_datoteke => $vrstica,
				datum_uvoza => "aa"
			   );
		push(@loop, \%row);
	} 
		
    
    $template->param(
		    MENU_POT => '',
			MENU => DntFunkcije::BuildMenu(),
		    IME_DOKUMENTA => 'Potrditev brisanja izbranih datotek',
			POMOC => "<input type='button' value='?' onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		    datoteke_loop => \@loop,
			hid_id_brisi=> $id_brisi,
			hid_brisi_potrjeno => '1'
		     );
	$html_output = $template->output; #.$tabelica;
    return $html_output;
}

sub UvoziDatoteko(){
#    my $self = shift;
#    my $q = $self->query();
#    my $seja  ;
#	
#	my $datoteka;
#	
#	$datoteka = $q->param('datoteka');
#	return 'uvazam datoteko'.$datoteka;
}

sub BrisiDatoteko(){
    my $self = shift;
	my $q = $self->query();
	
	my $id;
	my @deleteIds = $q->param("izberiId");
	my $html_output;
	my $redirect_url;
	my $template;
	
	
	my $counter=0;
	my $sql;
	my $sql2;
	my $sth;
	my $sth2;
	my $dbh;
	
	
	$sql="DELETE FROM datoteke WHERE ";
	$sql2="DELETE FROM datoteke_vsebina WHERE ";
	
	
	foreach $id (@deleteIds) {
		if ($counter==0){
			$sql.="id_datoteka='$id' ";
			$sql2.="id_datoteka='$id' ";
			$counter++;
		}
		else{
			$sql.="OR id_datoteka='$id' ";
			$sql2.="OR id_datoteka='$id' ";
		}
	}
	
	$redirect_url="?rm=Nepotrjene_datoteke";

	$dbh = DntFunkcije->connectDB;
	if($dbh){
		$sth = $dbh->prepare($sql);
		$sth2 = $dbh->prepare($sql2);
		#Najprej pobrise vsebino datotek
		unless($sth2->execute()){
			
			my $napaka_opis = $sth2->errstr;
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
sub UspesnoVnesena(){
	my $self = shift;
    my $q = $self->query();
    my $seja  ;
    
    my $html_output;
	my $izberi_gumb;
    my $template;
	
	my $napaka = $q->param('napaka');
	my $str = $q->param('str') || "";
	my $napaka_str;
	
	if ($napaka == 0){
		
		$napaka_str = "Datoteka je bila uspesno vnesena.";
	}
	elsif($napaka == 1){
		
		$napaka_str = "Napaka pri branju datoteke - napacno ime datoteke ali napacen format.";
	}
    elsif($napaka == 2){
		
		$napaka_str = "Napaka pri vnosu datoteke v bazo";
		if($str ne ""){
			$napaka_str .= "<br />Naslednji zavezanci se niso vnesli:<br />";
			#$str =~ s/;/<br \/>/g;
			$napaka_str .= $str;
		}
	}
	elsif($napaka == 3){
		
		$napaka_str = "Datoteka s tem imenom je ze bila vnesena!";
	}
    $template = $self->load_tmpl(	    
			'DntBranjeDatotekPrebrana.tmpl',
			cache => 1,
		);
		
	#$izberi_gumb = $q->radio_group(-name=>'',
	#						-values=>['direktna bremenitev','splosna poloznica','racun'],
	#						-default=>'direktna bremenitev',
	#						-linebreak=>'0')
    $template->param(
			MENU_POT => '',
			MENU => DntFunkcije::BuildMenu(),
			IME_DOKUMENTA => 'Uvoz iz datoteke',
			napaka => $napaka_str,
			nazaj => $q->button(-name=>'nazaj',
                          -value=>'Nazaj',
                          -onClick=>"self.location='/DntBranjeDatotek.cgi?rm=IzberiDatoteko'"),
			POMOC => "<input type='button' value='?' onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		);

    $html_output = $template->output; #.$tabelica;
    #$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
    return $html_output;
	
}
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'IzberiDatoteko';
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
	#error tmpl brez menija
	if ($q->param('rm') eq "spremeni" || $q->param('rm') eq "dodaj"){
		$template = $self->load_tmpl(	    
			'DntDodajSpremeni.tmpl',
		cache => 1,
		);
		$template->param(
			#MENU_POT => '',
			IME_DOKUMENTA => 'Napaka!',
			napaka_opis => $napaka_opis,
			akcija => ''
		);
	}
	else{
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
	}
	my $html_output = $template->output; #.$tabelica;
	return $html_output;
}

1;
