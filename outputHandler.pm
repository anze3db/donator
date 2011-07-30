eval {

my @parts;
my $content;
my $content2;
my $datum;
my $datumChk;
my $poloznice;
my $datZapis=0;
my $filename;
my $izvor;
my $pogoj;
my $multiCon = "";
my $tmpStr;
my $variable;
my $value;
(my $danes, my $cas) = DntFunkcije::si_date("");



read( STDIN, $tmpStr, $ENV{ "CONTENT_LENGTH" } );



@parts = split( /-----------------------------/, $tmpStr );
foreach my $pr (@parts){

		my $str = $pr;

		$pr =~ /name="(.*?)"/;
		$variable = $1;
		$value = DntFunkcije::trim($');
		if($variable eq "content"){
			if(!defined $content){
				$content=$value;
			}
			else{
				$content2=$value;
			}
		}
		elsif($variable eq "multi-con"){
			$multiCon .= $value.",";
		}
		elsif($variable eq "filename"){
			$filename = $value;
		}
		elsif($variable eq "datum_chk"){
			$datumChk=$value;
		}
		elsif($variable eq "poloznice"){
		    $poloznice=$value;
		}
		elsif($variable eq "datum"){				
			$datum=substr($value, 6, 10)."-".substr($value, 3, 2)."-".substr($value, 0, 2);
		
		}
		elsif($variable eq "izvor"){				
			$izvor=$value;
		}
		elsif($variable eq "index"){
			$pogoj=$value;
		}
}

if($izvor eq "sheet_print"){

	
	my $num = $content2 - $content;
	if(my $dbh = DntFunkcije->connectDB){
		my $sql = "SELECT * FROM sheets WHERE serial_root = '$pogoj' order by id_vrstce  LIMIT $num OFFSET $content";
		my $sth = $dbh->prepare($sql);
		$sth->execute();
		my $res;
		$content = "";
		while($res = $sth->fetchrow_hashref){
			$content .= $res->{'serial_id'}."\n";
		}
	}
}
elsif($izvor eq "zahtevki"){

	my $dbh;
	my $res;
	my $sql;
	my $sth;
	my @pogodbe = split(',', substr($multiCon, 0 , -1));
	my $file = "";
	my $pogodbe ="";
	$dbh = DntFunkcije::connectDB;
	my ($date, $cas) = DntFunkcije::si_date("");
	my $fileName;
	if($dbh){
		
		$sql = "SELECT sfr_agreement.*, sfr_donor.post_name, sfr_donor.id_donor FROM sfr_agreement, sfr_donor ".
				"WHERE sfr_agreement.id_donor = sfr_donor.id_donor AND id_agreement IN (";
		foreach my $pogodba (@pogodbe){
			$pogodbe .= "'".$pogodba."', ";
		}
		$pogodbe = substr($pogodbe, 0, -2);
		$sql .= $pogodbe.")";			
		$sth = $dbh->prepare($sql);
		$res = $sth->execute();
		
		while ($res = $sth->fetchrow_hashref) {
			$file .= DntFunkcije::trim($res->{'id_agreement'}).";".
					 DntFunkcije::trim($res->{'first_name'}).";".
					 DntFunkcije::trim($res->{'scnd_name'}).";".
					 DntFunkcije::trim($res->{'street'}).";".
					 DntFunkcije::trim($res->{'street_number'}).";".
					 DntFunkcije::trim($res->{'id_post'}).";".
					 DntFunkcije::trim($res->{'post_name'}).";";					 
					 #DntFunkcije::trim($res->{'id_donor'}).";";			
			$file .= "\n";
		}
		$sql = "UPDATE direktne_zahtevek_za_zapri SET datum_potrditve=CURRENT_TIMESTAMP, potrjeno=1".
				"WHERE id_agreement IN ($pogodbe)";
		$sth = $dbh->prepare($sql);
		$res = $sth->execute();
	}
	$content = $file;
}

if(defined $datumChk && $datumChk eq "ON"){
	#SQL:
	if(my $dbh = DntFunkcije->connectDB){
		my $sql;
		my $sth;
		my $id;
		if($izvor eq "opomini"){
			
			my $res;

			my @arr = split(/,/, $pogoj);
			foreach (@arr){
				s/\'//g;
				my @id = split(/;/, DntFunkcije::trim($_));
				$sql = "INSERT INTO agreement_notice (id_agreement, id_vrstica, datum)
						VALUES (?, ?, ?)";
				$sth = $dbh->prepare($sql);
				unless($sth->execute($id[0], $id[1], $datum)){
					print "Content-type: text/plain;\n\n";
					print "Napaka pri zapisu podatkov v bazo - nepravilen format datuma?";
					print "\n$sql $id[0], $id[1], $datum, $_";
					exit();
				}
				$sql = "SELECT id FROM agreement_notice ORDER BY id DESC LIMIT 1";
				$sth = $dbh->prepare($sql);
				$sth->execute();
				if($res = $sth->fetchrow_hashref){				
					my $tmpId = $res->{id};
					$sql = "UPDATE agreement_pay_installment SET id_notice=? ".
						   "WHERE id_agreement = '".$id[0]."' AND date_activate < '" . $datum . "' AND (amount != amount_payed OR amount_payed IS NULL) ";
					$sth = $dbh->prepare($sql);
					unless($sth->execute($tmpId)){
						print "Content-type: text/plain;\n\n";
						print "Napaka pri zapisu podatkov v bazo";
						exit();
					}
				}
			}
		}
		else{

			if($izvor eq "obroki"){
				$sql = "UPDATE agreement_pay_installment SET date_izpis=? ".
					   "WHERE 1=0";
				$id = "id_vrstica";
			}
			elsif($izvor eq "potrdila"){
				$sql = "UPDATE sfr_agreement SET potrdilo=?, status='Z' ".
					   "WHERE 1=0";
				$id = "id_agreement";
				
			}
			elsif($izvor eq "obracun_1"){
				$sql = "UPDATE sfr_agreement SET obracun=? ".
					   "WHERE 1=0";
				$id = "id_agreement";
				
			}
			elsif($izvor eq "obracun_2"){
				$sql = "UPDATE agreement_pay_installment SET obracun=? ".
					   "WHERE 1=0";
				$id = "id_vrstica";
			}
			my @pogoji = split(",", $pogoj);
			foreach (@pogoji){
			
			    my $input_string = DntFunkcije::trim($_);
			    
			    $input_string =~ s/'//g;

				if($id eq "id_agreement"){
                	$sql .= " OR $id = '".$input_string."'";
                }
    			else{
        			$sql .= " OR $id = ".$input_string;
    			}	
			}
			$sql =~ s/,'$/'/;
			
		    
			$sth = $dbh->prepare($sql);
			unless($sth->execute($datum)){
				print "Content-type: text/plain;\n\n";
				print "Napaka pri zapisu podatkov v bazo - nepravilen format datuma?";
				print "\nPrebrani datum: $datum";
				exit();
			}
		}
	}	
}



#ZAPII V BAZO TO DATOTEKO!
if(my $dbh = DntFunkcije->connectDB){
my $sql = "INSERT INTO datoteke_izvozene (filename, content)
						VALUES (?, ?)";
my $sth = $dbh->prepare($sql);
$sth->execute($filename, $content);
}

print "Content-disposition: attachment; filename=$filename;";
print "Content-type:text/plain\n\n";
if($izvor eq "obroki" && $poloznice eq "ON"){
    my $NEWLINE = "\r\n";

    @polja = ("Tip dokumenta", "IBAN v breme", "Model v breme","Sklic v breme", 
              "Ime v breme", "IBAN v dobro", "Model v dobro", 
              "Sklic v dobro", "Ime v dobro","BIC banke prejemnika", 
              "Znesek", "Datum plačila", "Namen", 
              "Koda namena", "Nujno", "Izjava");


    print join("\t", @polja) . $NEWLINE;

    if(substr($pogoj, length($pogoj)-1, 1) eq ","){
        $pogoj = substr($pogoj, 0, -1);
    }

    if(my $dbh = DntFunkcije->connectDB){
        
        $sql = "SELECT * FROM sfr_project as p LEFT JOIN sfr_project_trr as pt ON CAST(p.id_project as INTEGER) = pt.id_project LEFT JOIN sfr_bank as b ON b.id_bank = pt.id_bank  WHERE p.id_project = '2';";
        my $sth = $dbh->prepare($sql);
	    $sth->execute();
	    my $res;   
	       
	    my $project = $sth->fetchrow_hashref;
        
        $sql = "SELECT a.first_name, a.scnd_name, a.street, a.street_number, a.id_post, a.post_name, a.id_agreement, p.amount, p.date_activate FROM agreement_pay_installment as p LEFT JOIN sfr_agreement as a ON p.id_agreement = a.id_agreement WHERE id_vrstica IN ($pogoj) ORDER BY a.id_agreement";

        $sth = $dbh->prepare($sql);
	    $sth->execute();
	    
	    while($res = $sth->fetchrow_hashref){
	        $res->{'amount'} =~ s/\./,/;
	        $project->{'id_trr'} =~ s/-//;
	        $res->{'date_activate'} = substr($res->{'date_activate'}, 8, 2) . "." . substr($res->{'date_activate'}, 5, 2) . "." . substr($res->{'date_activate'}, 0, 4);
	        my @address = (
	            DntFunkcije::trim($res->{'first_name'}) . " " . DntFunkcije::trim($res->{'scnd_name'}),
	            DntFunkcije::trim($res->{'street'}) . " " . DntFunkcije::trim($res->{'street_number'}),
	            DntFunkcije::trim($res->{'id_post'}) . " " . DntFunkcije::trim($res->{'post_name'}), 
	        );
	        
	        my @vrstica = (
	            "Negotovinsko nakazilo", "", "", "", 
                join(',', @address),  'SI12' . DntFunkcije::trim($project->{'id_trr'}), "",
                DntFunkcije::trim($res->{'id_agreement'}), DntFunkcije::trim($project->{'name_project'}), 'ABANSI2X',
                $res->{'amount'}, $res->{'date_activate'}, 'Pogodbena donacija', 
                'CHAR', '', ''
                
                    	            
	        );
		    print join("\t", @vrstica) . $NEWLINE;
	    }
    }

}
else{
    my @vrstice = split(/\n/,$content);
    my $strazar = 0;
    foreach (@vrstice){
	    if(($_ !~ /^#/)){
		    if($strazar == 0){
			    print $_;
			    $strazar = 1;
		    }
		    else{
			    print "\n".$_;
		    }
	    }
    }
}
};
exit;
