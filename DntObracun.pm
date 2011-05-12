package DntObracun;
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
	# Redirect to login, ce uporabnik ni prijavljen
	if($user == 0){    
        $self->prerun_mode('login');
    }
	# Redirect to error, ce nima pravic za ogled strani
	elsif($user == -1){    
        $self->prerun_mode('error');
    }	
}

sub setup {

    my $self = shift;
    #$self->dbh_config("dbi:PgPP:dbname=donator;host=localhost", "uporabnikgres", "ni2mysql");

    
    $self->run_modes(
        'seznam' => 'ObracunSeznam',
		'prikazi' => 'ObracunSeznam',
		'uredi' => 'ObracunUredi',
		'Shrani' => 'ObracunShrani',
		'zbrisi' => 'ObracunZbrisi',
		'Preusmeri' => 'Preusmeri',
		'login' => 'Login',
		'error' => 'Error'
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub ObracunSeznam{
	
    my $self = shift;
    my $q = $self->query();	
	my $seja= $q->param('seja');	
	my $html_output ;
	my $don_klic = $q->param('don_klic');
	my $don_kom = $q->param('don_kom');
	my $izberi_vse = $q->param('izberi_vse');
	my $zaposleni = $q->param('zaposleni');
	my $pogodba = $q->param('pogodba');
	my $datum = $q->param('date');
	my $mode = $q->param('mode');
	my $izpis = $q->param('vrsta_izpisa');
	my $opcije = $q->param('opcije');
	my $od_dne = $q->param('od_dne');
	my $do_dne = $q->param('do_dne');
	my @loop;
	my @loop2;
	my @loop3;
	my @loop4;
	my @selected = $q->param('staff');
	my %staff_name;
	my @staff_id;
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
	my $op1="checked=\"true\""; 
	my $op2="";
	my $table2="";
	my $table;
	
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
		'DntObracun.tmpl',
		 cache => 1,
   );
	
	if (defined $izberi_vse && $izberi_vse != 1){		
		$izberi_vse = 0;
	}
	if(!defined $mode){
		$don_klic = 1;
		$don_kom = 1;
		$zaposleni = 1;
		$pogodba = 1;
		
	}
	
	($datum, my $cas) = DntFunkcije->time_stamp();
	my $mesec = substr($datum,5,2);
	$mesec = $mesec-1;
	if($mesec == 0){
		$mesec = 12;
	}
	elsif($mesec<10){
		
		$mesec="0".$mesec;
	}
	
	$datum_sl = "01/".$mesec."/".substr($datum,0,4);
	
	($datum, $cas) = DntFunkcije->time_stamp();
	my $datum_sl_2 = "01/".substr($datum,5,2)."/".substr($datum,0,4);
	
	if($od_dne){
		$datum_sl = $od_dne;
	}
	if($do_dne){
		$datum_sl_2 = $do_dne;		
	}
	
    $template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'Obracun',
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		MENU => DntFunkcije::BuildMenu(),);
	#Ce so se parametri za poizvedbo izpise rezultat


		
	my $hid_sort = $q->param("hid_sort");
	$dbh = DntFunkcije->connectDB;
	
	if ($dbh) {
		#if(length($ime)+length($st)>0){
		$sql = "SELECT id_staff, first_name, scnd_name FROM sfr_staff ORDER BY id_staff";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		my $scrollingList = '<select multiple = "multiple" name="staff" size="15" id="seznam_zaposlenih" >';
		my $crt = 0;
		while ($res = $sth->fetchrow_hashref) {
			my $name = DntFunkcije::trim($res->{'first_name'}) || "";
			my $sname = DntFunkcije::trim($res->{'scnd_name'}) || "";
			my $sel = '';
			foreach(@selected){
				if($_ eq $res->{'id_staff'}){
					$sel = 'selected = "seleted"';
				}
			}
			$scrollingList .= "<option value='$res->{'id_staff'}' $sel>$name $sname</option>";		  
			#$staff_name{$res->{'id_staff'}} = DntFunkcije::trim($res->{'first_name'} || "")." ".DntFunkcije::trim($res->{'scnd_name'} || "");
			#push(@staff_id, $res->{'id_staff'});
		}
		$scrollingList .= "</select>";
		#izpis forme za iskanje:
		$template->param(izberi_vse => $q->checkbox(-name=>'izberi_vse',
							-checked=>$izberi_vse,
							-value=>'1',
							-label=>'Izberi vse',
							-onClick=>'izberiVseSez(this)'),
						zaposleni_seznam => $scrollingList,
						od_dne => $q->textfield(-name=>'od_dne',
							-value=> $datum_sl,
							-size=>20,
							-maxlength=>80,
							-id=>'od_dne',
							-onblur=>'DatumVnos(this.id)'),
						do_dne => $q->textfield(-name=>'do_dne',
							-value=> $datum_sl_2,
							-size=>20,
							-maxlength=>80,
							-id=>'do_dne',
							-onblur=>'DatumVnos(this.id)'),
						);
		#izpis tabele:
		
		my $disply=0;
		my $izbira;
		my $result;
		my $csv="";
		my $index;
		my $id_pogodbe_label = "Id pogodbe";

		if(defined $od_dne){
		$od_dne = substr($od_dne,6,4)."-".substr($od_dne,3,2)."-".substr($od_dne,0,2);
		}
		if(defined $do_dne){
		$do_dne = substr($do_dne,6,4)."-".substr($do_dne,3,2)."-".substr($do_dne,0,2);
		}
			
		
		foreach (@selected){
			my $staff;	
			my @trs;
			my @vsota_obroki;
			my @vsota_dogodki_pogodb=0;
			my @vsota_dogodki_znesek=0.0;
			my @vsota_dogodki_nakazilo=0.0;
			my @vsota_dogodki_gotovine=0.0;
			$sql = "SELECT first_name, scnd_name FROM sfr_staff WHERE 1=1 ";
			$sql.="AND id_staff = $_ ";
		
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$csv .= "\n";

		while ($res = $sth->fetchrow_hashref) {
			$staff .= DntFunkcije::trim($res->{'first_name'} || "").
						" ".DntFunkcije::trim($res->{'scnd_name'} || "").", ";
			$csv .= DntFunkcije::trim($res->{'first_name'} || "").
						";".DntFunkcije::trim($res->{'scnd_name'} || "")."\n";
		}
		$staff = "<br /><br />".substr($staff, 0, -2);
		

		if($opcije == 1){
			#SKLENJENE POGODBE
			
			$izbira = "<div style='text-align:left;'>$staff</div>";
			$result = "<th>$id_pogodbe_label</th>".
						'<th>status</th>'.
						'<th>datum pogodbe</th>'.
						'<th>priimek ime/podjetje</th>'.
						'<th>nacin placila</th>' .
						'<th>znesek pogodbe</th>' .
						'<th>gotovina</th>' .
						'<th>nakazilo</th>';
			$result .= '</tr>';
			#$trs[0] = $q->th([$id_pogodbe_label, 'status', 'datum pogodbe',
			#				  'priimek ime/podjetje', 'nacin placila',
			#				  'znesek pogodbe', 'gotovina', 'nakazilo']);
			
			$csv .= "id pogodbe;status;datum pogodbe;priimek ime/podjetje;".
					"nacin placila;znesek pogodbe;gotovina;nakazilo\n";
			
			$sql = "SELECT * FROM sfr_agreement WHERE ";
			$sql .= " date_agreement >= '$od_dne' AND obracun IS NULL ";
			$sql .= "AND date_agreement <= '$do_dne' AND ( 1=1 ";

				$sql.="AND id_staff = $_ ";
			
			$sql .= ") ORDER BY id_agreement ASC LIMIT 1000";
			#$sql.="AND date_enter < $od"
			#return $sql;
			$sth = $dbh->prepare($sql);
			$sth->execute();
			my $vsota_pogodb=0;
			my $st_nakazil=0;
			my $st_gotovin=0;
			my $vsota_znesek = 0.00;
			my $vsota_nakazilo=0.0;
			my $vsota_gotovine=0.0;
			my $vsota_pogodb_storno=0;
			my $vsota_znesek_storno = 0.00;
			my $vsota_nakazilo_storno=0.0;
			my $vsota_gotovine_storno=0.0;
			while ($res = $sth->fetchrow_hashref) {
				
				my $ime;
				my $gotovina;
				my $nakazilo;
				my $status = $res->{'status'};			
				my $znesek = $res->{'amount'};
				my $dogodek = $res->{'id_event'};
				my $payType = $res->{'pay_type1'} || "";
				$disply = 1;
				if($status eq "S"){
					
					$vsota_znesek_storno += StornoZnesek($dbh, $res->{id_agreement});
					$vsota_pogodb_storno++;
					
					if($payType eq 'G1'){
						$gotovina = $res->{'amount1'};
						#$vsota_gotovine_storno = $vsota_gotovine + $gotovina;
						
					}
					elsif($payType eq 'C1'){
						$nakazilo = $res->{'amount1'};
						$vsota_nakazilo_storno += $nakazilo;						
					}
				}
				else{					
					
					if($payType eq 'G1'){												
						$gotovina = $res->{'amount1'};
						if($gotovina>0){
							$st_gotovin++;
						}
						$vsota_gotovine += $gotovina;
						$vsota_dogodki_gotovine[$dogodek] += $gotovina;
						
						
					}
					if($payType eq 'C1'){
						$nakazilo = $res->{'amount1'};
						$vsota_nakazilo += $nakazilo;
						$st_nakazil ++;
						$vsota_dogodki_nakazilo[$dogodek] += $nakazilo;
					}
					else{
						$vsota_pogodb++;
						$vsota_znesek += $znesek;
					}					
					$vsota_dogodki_znesek[$dogodek] += $znesek;
					$vsota_dogodki_pogodb[$dogodek]++;
				}
				if($res->{'entity'}==1){
					$ime = DntFunkcije::trim($res->{'name_company'});
				}
				else{
					$ime = DntFunkcije::trim($res->{'scnd_name'})." ".DntFunkcije::trim($res->{'first_name'});	
				}
				$result .= '<tr>';
				$result .= '<td>' . $res->{'id_agreement'} . '</td>' .
						   '<td>' . DntFunkcije::trim($res->{'status'}) . '</td>' .
						   '<td>' . DntFunkcije::sl_date($res->{'date_agreement'}) . '</td>' .
						   '<td>' . $ime . '</td>' .
						   '<td>' . DntFunkcije::debitName($res->{'pay_type2'}) . '</td>' .
						   '<td align="right">' .  DntFunkcije::FormatFinancno($res->{'amount'}) . '</td>' .
						   '<td align="right">' .  DntFunkcije::FormatFinancno($gotovina) . '</td>' .
						   '<td align="right">' .  DntFunkcije::FormatFinancno($nakazilo) . '</td>';
		  		$result .= '</tr>';
				#push(@trs, $tmp);
				$csv .=  $res->{'id_agreement'}.";".
							$res->{'status'}.";".
							DntFunkcije::sl_date($res->{'date_agreement'}).";".
							$ime.";".
							DntFunkcije::debitName($res->{'pay_type2'},1).";".
							DntFunkcije::FormatFinancno($res->{'amount'}).";".
							DntFunkcije::FormatFinancno($gotovina).";".
							DntFunkcije::FormatFinancno($nakazilo)."\n";
				$index .= $res->{'id_agreement'}.", ";
			}		
			$result .= "<tr>";
			$result .= "<th colspan='5' align='left'>Skupaj: ".$vsota_pogodb." (G: ".$st_gotovin.", N: ".$st_nakazil.")</th> " . 
					   '<th align="right">'.DntFunkcije::FormatFinancno($vsota_znesek). "</th> " . 
					   '<th align="right">'.DntFunkcije::FormatFinancno($vsota_gotovine). "</th> " .
					   '<th align="right">'.DntFunkcije::FormatFinancno($vsota_nakazilo). "</th> ";
			$result .= "</tr><tr>";
			$result .= "<th colspan = '5' align='left'>Storno: ".$vsota_pogodb_storno . '</th>' .
					    '<th align="right">'.DntFunkcije::FormatFinancno($vsota_znesek_storno). "</th> " .
					    '<th align="right">'.DntFunkcije::FormatFinancno($vsota_gotovine_storno). "</th> " .
					    '<th align="right">'.DntFunkcije::FormatFinancno($vsota_nakazilo_storno). "</th> ";
			$result .= "</tr>";
			$csv .= "Skupaj: ".$vsota_pogodb." (G: ".$st_gotovin.", N: ".$st_nakazil.");;;;;".DntFunkcije::FormatFinancno($vsota_znesek).";".
							   "".DntFunkcije::FormatFinancno($vsota_gotovine).";".
							   "".DntFunkcije::FormatFinancno($vsota_nakazilo)."\n";
			$csv .= "Storno: ".$vsota_pogodb_storno.";;;;;".DntFunkcije::FormatFinancno($vsota_znesek_storno).";".
							   "".DntFunkcije::FormatFinancno($vsota_gotovine_storno).";".
							   "".DntFunkcije::FormatFinancno($vsota_nakazilo_storno)."\n";
			
			my $dogodki_vsota;
			for (my $i = 0; $i<9;$i++){
				if($vsota_dogodki_pogodb[$i]){
					$result .= "<tr>";
					$result .= "<th colspan='5' align='left'>Dogodek 0$i: ".$vsota_dogodki_pogodb[$i] ."</th>" .
							    '<th align="right">' .DntFunkcije::FormatFinancno($vsota_dogodki_znesek[$i])."</th>" .
							   '<th align="right">' .DntFunkcije::FormatFinancno($vsota_dogodki_gotovine[$i])."</th>".
							    '<th align="right">' .DntFunkcije::FormatFinancno($vsota_dogodki_nakazilo[$i])."</th>";
					$result .= "</tr>";
					$csv .= "Dogodek 0$i: ".$vsota_dogodki_pogodb[$i].";;;;;".DntFunkcije::FormatFinancno($vsota_dogodki_znesek[$i]).";".
							   DntFunkcije::FormatFinancno($vsota_dogodki_gotovine[$i]).";".
							   DntFunkcije::FormatFinancno($vsota_dogodki_nakazilo[$i])."\n";
				}
			}
			
		}
		elsif($opcije == 2){
			#PLACANI OBROKI
			$op1="";
			$op2="checked=\"true\"";
			#nacini placila:
			my @placila;
			$sql = "SELECT debit_type FROM sfr_pay_type";
			$sth = $dbh->prepare($sql);
			$sth->execute();
			my $stv=0;
			while($res = $sth->fetchrow_hashref){
				$placila[$stv++] = $res->{'debit_type'};
			}
			$izbira = "<div style='text-align:left;'>$staff</div>";
			$result = '<tr>';
			$result .= '<th>' . $id_pogodbe_label . '</th>' .
					   '<th>' .	'datum placila' . '</th>' .
					   '<th>' .	'storno' . '</th>' .
					   '<th>' .'priimek ime/podjetje'. '</th>' . 
					   '<th>' .'nacin placila'. '</th>' . 
					   '<th>' .'obrok'. '</th>' .
					   '<th>' .'znesek obrok'. '</th>' .
					   '<th>' .'opomin'. '</th>';
			$result .= '</tr>';
			$csv .= "id pogodbe;datum pogodbe;priimek ime/podjetje;nacin placila;obrok;znesek obrok\n";
			$sql = "SELECT a.amount as obrok, a.storno, * FROM agreement_pay_installment AS a, sfr_agreement AS b WHERE ";
			$sql .= " a.obracun IS NULL AND ".
				    "((a.amount_payed IS NOT NULL AND a.date_due <= '$do_dne' AND a.date_due >= '$od_dne' AND a.date_due IS NOT NULL AND a.amount = a.amount_payed AND a.amount != 0) ".
					" OR (storno IS NOT NULL AND date_trunc('day', a.storno) <= '$do_dne' AND date_trunc('day', a.storno) >= '$od_dne')) ".
					" AND a.id_agreement = b.id_agreement AND ( 1=1 ";

			$sql.="AND b.id_staff = $_ ";

			$sql .= ") ORDER BY a.id_agreement, a.id_vrstica ASC";
			
			#$sql.="AND date_enter < $od"
			$sth = $dbh->prepare($sql);
			$sth->execute();
			my @vsota_nacini_placila;
			my $vsota_pogodb=0;
			my $vsota_znesek += 0.00;
			my $vsota_nakazilo=0.0;
			my $vsota_gotovine=0.0;
			my $vsota_pogodb_storno=0;
			my $vsota_znesek_storno = 0.00;
			my $vsota_nakazilo_storno=0.0;
			my $vsota_gotovine_storno=0.0;
			my $vsota_opominov=0.0;
			my $st_opominov=0;
			while ($res = $sth->fetchrow_hashref) {				
				my $ime;
				my $gotovina;
				my $nakazilo;
				my $znesek = $res->{'amount_payed'} || 0;
				my $storno = $res->{'storno'};
				my $notice;
				my $pay_type_num=@placila;
				$disply = 1;
				
				for (my $i = 0; $i<$pay_type_num; $i++){
					if($placila[$i] eq DntFunkcije::trim($res->{'pay_type'})){
						$pay_type_num = $i;
					}
				}
				
				#return $sql;
				
				if(defined $storno){
					$vsota_znesek_storno += $res->{obrok};
					$vsota_pogodb_storno++;
				}
				#elsif(defined $res->{id_notice} && $res->{id_notice}>0){
				elsif(defined $res->{id_notice}){					
					$vsota_opominov += $znesek;
					$st_opominov++;
					$notice = "1";
				}
				else{					
					$vsota_obroki[$res->{'installment_nr'}]+=$znesek;
					$vsota_nacini_placila[$pay_type_num] += $znesek;
					$vsota_znesek += $znesek;
					$vsota_pogodb++;
				}
				
				if($res->{'entity'}==1){
					$ime = DntFunkcije::trim($res->{'name_company'});
				}
				else{
					$ime = DntFunkcije::trim($res->{'scnd_name'})." ".DntFunkcije::trim($res->{'first_name'});	
				}
				$result .= '<tr>';
				$result .= '<td>'.$res->{'id_agreement'} . '</td>' .
							'<td>'.DntFunkcije::sl_date($res->{'date_due'}) . '</td>' .
							'<td>'.DntFunkcije::sl_date($res->{'storno'}) . '</td>' .
							'<td>'.$ime . '</td>' .
							'<td>'.DntFunkcije::debitName($res->{'pay_type'}) . '</td>' .
							'<td>'.$res->{'installment_nr'} . '</td>';
				$csv .=  $res->{'id_agreement'}.";".
						DntFunkcije::sl_date($res->{'date_due'}).";".
						$ime.";".
						DntFunkcije::debitName($res->{'pay_type'},1).";".
						$res->{'installment_nr'}.";";
				if($notice eq "1"){
					$result .= '<td></td>' .
							   '<td align="right">'. DntFunkcije::FormatFinancno($res->{'obrok'}) . '</td>';
					$csv .= ';'.DntFunkcije::FormatFinancno($res->{'obrok'})."\n";
				}
				else{
					$result .= '<td align="right">'. DntFunkcije::FormatFinancno($res->{'obrok'}) . '</td>'.
							   '<td></td>';
					$csv .= DntFunkcije::FormatFinancno($res->{'obrok'}).";\n";
							   	
				}								  
				$result .= '</tr>';
				$index .= $res->{'id_vrstica'}.", ";
				
			}
			$result .= '<tr>';
			$result .= '<th colspan="6" align="left"> Skupaj: '.$vsota_pogodb . ' (Opominov: '.$st_opominov.')</th>' .
						'<th align="right">'.DntFunkcije::FormatFinancno($vsota_znesek). '</th>'.
						'<th>'.DntFunkcije::FormatFinancno($vsota_opominov).'</th>';
			$result .= '</tr>';
			$csv .= "Skupaj: ".$vsota_pogodb." (Opominov: " . $st_opominov . ");;;;;".
							   "".DntFunkcije::FormatFinancno($vsota_znesek).";".DntFunkcije::FormatFinancno($vsota_opominov)."\n";
			$result .= '<tr>';
			$result .= '<th colspan="6" align="left">'. "Storno: ".$vsota_pogodb_storno . '</th>' .
						'<th align="right">'.DntFunkcije::FormatFinancno($vsota_znesek_storno).'</th>';
			$result .= '</tr>';
			$csv .= "Storno: ".$vsota_pogodb_storno.";;;;;".
							   "".DntFunkcije::FormatFinancno($vsota_znesek_storno)."\n";
			my $vsota_izpis = "<b>Vsota obrokov:</b><br />";
			$csv .= "Vsota obrokov:\n";
			my $x = @vsota_obroki;
			for (my $i=0; $i<$x; $i++){
				if($vsota_obroki[$i]){
					$vsota_izpis .= "<b>".$i."</b>.: ".DntFunkcije::FormatFinancno($vsota_obroki[$i])."<br />";
					$csv .= $i.";;;;;".DntFunkcije::FormatFinancno($vsota_obroki[$i])."\n";
				}
			}
			$csv .= "Nacini placila:\n";
			my $vsota_izpis_placila = "<b>Nacini placila:</b><br />";
			$x = @vsota_nacini_placila;
			for (my $i=0; $i<$x; $i++){
				if($vsota_nacini_placila[$i]){
					$vsota_izpis_placila .= "<b>".$placila[$i]."</b>: ".DntFunkcije::FormatFinancno($vsota_nacini_placila[$i])."<br />";
					$csv .= $placila[$i].";;;;;".DntFunkcije::FormatFinancno($vsota_nacini_placila[$i])."\n";
				}
			}
			
			#my $vsota_izpis_op = "<b>Opomini:</b><br />";
			#$csv .= "Opomini:\n";
			#if($st_opominov>0){
			#	$vsota_izpis_op .= "St. opominov: $st_opominov<br/>";
			#	$vsota_izpis_op .= "Vsota opominov: ".DntFunkcije::FormatFinancno($vsota_opominov);
			#	$csv .=$st_opominov."\n";
			#	$csv .=DntFunkcije::FormatFinancno($vsota_opominov)."\n";
			#}
			$table2 .= '<div style="padding:10px 2px;padding-right:10px;float:left;"> '. $vsota_izpis . '</div>';
			$table2 .= '<div style="padding:10px 2px;float:left;">'. $vsota_izpis_placila . '</div>';
			#$table2 .= '<div style="padding:10px 2px;float:left;">'. $vsota_izpis_op .'</div>';
			$table2 .= '<div style="clear:left"></div>';
		}

		if($q->param('rm') eq "prikazi"){
			
			$table .= '<table border="1px">' .
					  "<caption>$izbira</caption>";
					 
			$table .= $result;
			$table .= "</table>";
				#$q->caption($izbira),
				#$q->Tr({-align=>'center',-valign=>'TOP'},
				#\@trs
				#)
			#);
			$table .= $table2;
			$template->param(table => $table);
			$table2 ="";
		}
		}	
		
		$template->param(op1 => $op1,
						 op2 => $op2,
						 ,
						 );
		if ($disply>0){
			$template->param(form => DntFunkcije::output_form($q,$csv, "obracun_$opcije", $index));
		}
	}

	else{
		return 'Povezava do baze ni uspela';
	}
                
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}
sub StornoZnesek{
	my $dbh = shift;
	my $id_agreement = shift;
	my $res;
	my $sth;
	my $sql = "SELECT SUM(amount)AS storno FROM agreement_pay_installment WHERE storno IS NOT NULL and id_agreement = '$id_agreement'";
	if($dbh){
		$sth = $dbh->prepare($sql);
		$sth->execute();
		if ($res = $sth->fetchrow_hashref) {
			return $res->{storno};
		}
	}
	
	
}
1;    # Perl requires this at the end of all modules
