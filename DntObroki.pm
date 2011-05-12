package DntObroki;
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
	if ($str eq 'generiraj'){
		$nivo = 'w';
	}
	
    my $user = DntFunkcije::AuthenticateSession(22, $nivo);
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
        'seznam' => 'ObrokiSeznam',
		'generiraj' => 'ObrokiGeneriraj',
		'login' => 'Login',
		'error' => 'Error'


    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub ObrokiSeznam{
	
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
    my $template;
	my $napaka_opis;
	$self->param(testiram =>'rez');	    
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
	                      'DntObrokiSeznam.tmpl',
			      cache => 1,
			     );
    $template->param(
		     #MENU_POT => $menu_pot,
			 IME_DOKUMENTA => 'Generiranje obrokov',
			 POMOC => "<input type='button' value='?' ".
			 "onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",  MENU => DntFunkcije::BuildMenu(),
			 
		     );
	#Ce so se parametri za poizvedbo izpise rezultat
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) =
	localtime(time);
	$mon+=1;
	$year+=1900;
	if($mon<10){
	$mon="0$mon";
	}
	if($mday<10){
		$mday="0$mday"
	}
	my $date="$mday/$mon/$year";
		my $hid_sort = $q->param("hid_sort");
		$dbh = DntFunkcije->connectDB;
		
		if ($dbh) {
			
			#if(length($ime)+length($st)>0){
			$sql = "SELECT   * ".
				   "FROM     sfr_agreement ".
				   "WHERE    status = 'O' ".
				   "AND      (create_installments != '1' OR create_installments ISNULL)".
				   "AND 	 num_installments != 0 ".
				   "ORDER BY debit_type, id_agreement ASC";
			
			$sth = $dbh->prepare($sql);
			$sth->execute();
			
			while ($res = $sth->fetchrow_hashref) {
				$napaka_opis = "";
				my $prviObrok;
				my $aktivirajZDnem = DntFunkcije::trim($res->{'start_date'}) || "";
				my $datumPodpisa = DntFunkcije::trim($res->{'date_agreement'});
				my $datumRacun = DntFunkcije::trim($res->{'date_enter'});
				my $mesec;
				my $leto;
				my $check;
				my $napaka;
				my $zapStDol = DntFunkcije::trim($res->{'zap_st_dolznika'}) || "";
				
				#izpis poloznic in placilnih nalogov BN 02
				if($res->{'debit_type'} eq "01" || $res->{'debit_type'} eq "P1" ){
					
					if($aktivirajZDnem eq ""){					
						#return $datumPodpisa;
						$mesec=substr($datumPodpisa, 5, 2)+1;
						$leto = substr($datumPodpisa, 0, 4);
						if($mesec>12){
							$mesec="01";
							$leto++;
						}						
						elsif($mesec<10){
							$mesec="0".$mesec;
						}	
						$prviObrok = $res->{'frequency'}."/".$mesec."/".$leto;
					}
					else{
						$prviObrok = DntFunkcije::sl_date($aktivirajZDnem);
					}						
				}
				#izpis direktnih bremenitev
				elsif($res->{'debit_type'} eq "04"){
					
					if($zapStDol eq ""){
						$napaka_opis="Ni zap. st. dolznika!";
							
					}					
					if($aktivirajZDnem eq ""){
						
						$mesec=substr($datumPodpisa, 5, 2)+1;
						$leto = substr($datumPodpisa, 0, 4);
						if($mesec>12){
							$mesec="01";
							$leto++;
						}						
						if($mesec<10){
							$mesec="0".$mesec;
						}	
						$prviObrok = $res->{'frequency'}."/".$mesec."/".$leto;
					}						
					else{
						$prviObrok = DntFunkcije::sl_date($aktivirajZDnem);
					}
					
						
				}
				#izpis racunov
				elsif($res->{'debit_type'} eq "A1"){
					
					my $valuta = $res->{'valuta'};
					if($aktivirajZDnem eq ""){
						
						$prviObrok = DntFunkcije::sl_date($datumRacun);					
						my $d= substr($prviObrok, 0, 2);
						my $m= substr($prviObrok, 3, 2);
						my $y= substr($prviObrok, 6, 4);
						
						$prviObrok=POSIX::mktime( 0, 0, 0, $d, $m-1, $y-1900);
						$prviObrok+=$valuta*24*60*60;
						(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) =
						localtime($prviObrok);
						$mon++;
						if($mon<10){
							$mon="0".$mon;
						}
						if($mday<10){
							$mday="0".$mday;
						}	
						$prviObrok= $mday."/".($mon)."/".($year+1900);
					}
					else{
						$prviObrok = DntFunkcije::sl_date($aktivirajZDnem);
					}
					
				}
				
				my $d= substr($prviObrok, 0, 2);
				my $m= substr($prviObrok, 3, 2);
				my $y= substr($prviObrok, 6, 4);
				my $odmik=time;
				$odmik-=POSIX::mktime( 0, 0, 0, $d, $m-1, $y-1900);
				if(time+(8*24*60*60) > POSIX::mktime( 0, 0, 0, $d, $m-1, $y-1900) && $res->{'debit_type'} ne "04"){
					$check=0;
					$napaka=1;
				}
				
				else{
					$check=1;
					$napaka=0;
				}
				if($res->{'debit_type'} eq "04" && $zapStDol eq ""){
					$check =0;
					$napaka_opis = "Ni zap. st. dolznika!";
				}
				#return $odmik." $d, $m, $y";

				my %row = (				
					#izbor => $q->a({-href=>"DntPoste.cgi?".
					#	"rm=uredi&id_agreement=$res->{'id_agreement'}".
					#	"&seja=$seja&uredi=1"}, 'uredi'),
					nacin_placila => DntFunkcije::debitName($res->{'debit_type'}),
					podjetje => DntFunkcije::trim($res->{'name_company'}),
					priimek => DntFunkcije::trim($res->{'scnd_name'}),
					stObrokov => DntFunkcije::trim($res->{'num_installments'}),
					ime => DntFunkcije::trim($res->{'first_name'}),
					id => DntFunkcije::trim($res->{'id_agreement'}),
					datumPodpisa => DntFunkcije::sl_date(DntFunkcije::trim($res->{'date_agreement'})),
					datumVnosa => DntFunkcije::sl_date(DntFunkcije::trim($res->{'date_enter'})),
					startDate => DntFunkcije::sl_date(DntFunkcije::trim($res->{'start_date'})),
					prviObrok => $prviObrok,
					check => $check,
					napaka => $napaka,
					napaka_opis => $napaka_opis,
									
				);

				# put this row into the loop by reference             
				push(@loop, \%row);
			}
			$template->param(donator_loop => \@loop,
							 #edb_datum=>$date,
					#koren => DntFunkcije::trim($poKorenuIme),
			);
		}
		else{
			return 'Povezava do baze ni uspela';
		}
                
	
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}

sub ObrokiGeneriraj(){

    my $self = shift;
    my $q = $self->query();
	my $seja= $q->param('seja');
	my $test = $q->param('test');	
	if(!defined $test){ $test = 0};
	my $html_output;
	my $datum= $q->param('edb_datum');
	my $stDni= $q->param('edb_st');
	my @pogodbe=$q->param('izberiId');

	my $uporabnik= $q->param('uporabnik');
    my $template;	
    my $dbh;
	my $res;
	my $sql;
	my $sth;
	
	my $account_number;
	my $amount;
	my $celoten;
	my $create_installments;
	my $date_activate;
	my $debit_type;
	my $frequency;
	my $id_donor;
	my $id_project;
	my $num_installments;
	my $pay_type;
	my $prvi;
	my $start_date;
	my $tax_number;
	my $valuta;
	
	my $dan_form=substr($datum, 0,2);
	my $mesec_form=substr($datum, 3,2);
	my $leto_form=substr($datum, 6,4);
	
	
	my @loop;
	if($test == 1){
		$dbh = DntFunkcije->connectDBtest;
	}
	else{
		$dbh = DntFunkcije->connectDB;
	}

	if ($dbh) {
		foreach $_ (@pogodbe){
			my @info = split("_", $_);
			my $id=$info[0];
			my $prviObrok=$info[1];
		
			$sql = "select * FROM sfr_agreement ".
				   "WHERE id_agreement=?";
			$sth = $dbh->prepare($sql);
			$sth->execute($id);	   
			if($res = $sth->fetchrow_hashref){
				
				$account_number=DntFunkcije::trim($res->{'bank_account'});
				$amount=DntFunkcije::trim($res->{'amount2'});
				$prvi=DntFunkcije::trim($res->{'amount1'});
				$celoten=DntFunkcije::trim($res->{'amount'});
				$create_installments=DntFunkcije::trim($res->{'create_installments'});
				$debit_type=DntFunkcije::trim($res->{'debit_type'});
				$frequency=DntFunkcije::trim($res->{'frequency'});
				$id_donor=DntFunkcije::trim($res->{'id_donor'});
				$id_project=DntFunkcije::trim($res->{'id_project'});
				$num_installments=DntFunkcije::trim($res->{'num_installments'});
				$pay_type=DntFunkcije::trim($res->{'pay_type2'});
				$start_date=DntFunkcije::trim($res->{'start_date'});
				$tax_number=DntFunkcije::trim($res->{'tax_number'});
				$valuta=DntFunkcije::trim($res->{'valuta'});
				
			}
			if ($create_installments eq "1")
			{
				#Obrok je že zgeneriran
			}
			else{
				my $dan=substr($prviObrok, 0,2);
				my $mesec=substr($prviObrok, 3,2);
				my $leto=substr($prviObrok, 8,2);					

				for(my $i=1; $i<=$num_installments-1; $i++){
					
					
					$date_activate=2000+$leto."-$mesec-$dan";
					#return $date_activate." $leto $mesec $dan";
					#$leto=substr($leto, 2, 2);
					$sql="INSERT INTO agreement_pay_installment".
							"(id_agreement, stara_pogodba, installment_nr, ".
							"date_activate, date_due, amount, amount_payed, ".
							"pay_type, account_number, id_donor, frequency, ".
							"id_bremenitev, mesec, leto, ".
							"tax_number, id_project, debit_type, id_notice, ".
							"id_packet_pp, komentar".
							")";
																
					$sql.="VALUES ($id, NULL, $i, ".
					"'$date_activate', NULL, $amount, NULL, ".
					"'$pay_type', '$account_number', '$id_donor', '$frequency', ".
					"NULL, $mesec, $leto, ".
					"'$tax_number', '$id_project', '$debit_type', NULL, ".
					"NULL, NULL".
					")";
					if($debit_type=~"01" || $debit_type=~"P1" || $debit_type=~"04"){ 
						$mesec++;
						if($mesec==13){
							$mesec=1;
							$leto++;
						}
						$dan=$frequency;
					}
					elsif($debit_type eq "A1"){
						$date_activate = POSIX::mktime( 0, 0, 0, $dan, $mesec-1, $leto+100) + $valuta*24*60*60;
						(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) =
						localtime($date_activate);
						$mesec=$mon+1;
						$dan=$mday;
						$leto=$year+1900;
						if($mesec<10){
							$mesec="0$mesec";
						}
						if($dan<10){
							$dan="0$dan";
						}
						$leto = substr($leto, 2, 2);
						
					}
					
					
					#return $sql;
					$sth = $dbh->prepare($sql);
					unless($sth->execute()){
						my $napaka_opis = $sth->errstr;
						#print $napaka_opis;
						#return;
						$template = $self->load_tmpl(	    
							'DntRocniVnosNapaka.tmpl',
						cache => 1,
						);
						$template->param(
									MENU_POT => '',
									IME_DOKUMENTA => 'Napaka ! INSERT '.$id,
									napaka_opis => $napaka_opis,
									akcija => ''
									 );
					
						$html_output = $template->output; #.$tabelica;
						#$html_output->param(-name=>'xOdDne', -value=>'xx');# $q->param('narocilo'));
						return $html_output;                  
					}
				}
				
				
				$date_activate=2000+$leto."-$mesec-$dan";
				$amount=$celoten-$prvi-(($num_installments-1)*$amount);
				
					$sql="INSERT INTO agreement_pay_installment ".
						"(id_agreement, stara_pogodba, installment_nr, ".
						"date_activate, date_due, amount, amount_payed, ".
						"pay_type, account_number, id_donor, frequency, ".
						"id_bremenitev, mesec, leto, ".
						"tax_number, id_project, debit_type, id_notice, ".
						"id_packet_pp, komentar".
						")";
																
					$sql.="VALUES ('$id', NULL, $num_installments, ".
						"'$date_activate', NULL, $amount, NULL, ".
						"'$pay_type', '$account_number', '$id_donor', '$frequency', ".
						"NULL, $mesec, $leto, ".
						"'$tax_number', '$id_project', '$debit_type', NULL, ".
						"NULL, NULL".
						")";
					#return $sql."<br /> $dan, $mesec, $leto";
					$sth = $dbh->prepare($sql);
					unless($sth->execute()){
						my $napaka_opis = $sth->errstr;
						$template = $self->load_tmpl(	    
							'DntRocniVnosNapaka.tmpl',
						cache => 1,
						);
						$template->param(
									MENU_POT => '',
									IME_DOKUMENTA => 'Napaka ! INSERT '.$id,
									napaka_opis => $napaka_opis,
									akcija => ''
									 );
					
						$html_output = $template->output; #.$tabelica;
						return $html_output;                  
					}
				
				$sql="UPDATE sfr_agreement SET create_installments='1' ".
					"WHERE id_agreement='$id'";
				$sth = $dbh->prepare($sql);
				unless($sth->execute()){
					my $napaka_opis = $sth->errstr;
					$template = $self->load_tmpl(	    
						'DntRocniVnosNapaka.tmpl',
					cache => 1,
					);
					$template->param(
								MENU_POT => '',
								IME_DOKUMENTA => 'Napaka ! UPDATE',
								napaka_opis => $napaka_opis,
								akcija => ''
								 );
				
					$html_output = $template->output; #.$tabelica;
					return $html_output;                  
				}
				
				$mesec++;
				if($mesec==13){
					$mesec=1;
					$leto++;
				}
			}
		}		
	}
	else{
		return 'Povezava do baze ni uspela';
	}              
	
    # Parse the template
	my $redirect_url="?rm=seznam";
    $self->header_type('redirect');
    $self->header_props(-url => $redirect_url);
	if($test == 1){return 1;}
	else {return $redirect_url;}
    
	
}
#če uporabnik ni prijavljen:
sub Login(){
	my $self = shift;	
	my $q = $self->query();
	my $return_url= 'Obroki';
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
