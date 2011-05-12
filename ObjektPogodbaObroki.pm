#!/usr/bin/perl
package PogodbaObroki;
#  !c:/Perl/bin/perl.exe

# package PogodbaObroki;

use strict;
use DBI;

sub new {
    my $type = shift;
    my $self = {};
    
    #$self->{'buz'} = 42;
    bless $self, $type;
}

sub id_agreement {
    my $self = shift;
    $self->{id_agreement} = shift if @_;
    return $self->{id_agreement};
}

sub id_vrstica {
    my $self = shift;
    $self->{id_vrstica} = shift if @_;
    return $self->{id_vrstica};
}

sub installment_nr {
    my $self = shift;
    $self->{installment_nr} = shift if @_;
    return $self->{installment_nr};
}
sub date_activate {
    my $self = shift;
    $self->{date_activate} = shift if @_;
    return $self->{date_activate};
}

sub date_due {
    my $self = shift;
    $self->{date_due} = shift if @_;
    return $self->{date_due};
}

sub amount {
    my $self = shift;
    $self->{amount} = shift if @_;
    return $self->{amount};
}

sub amount_payed {
    my $self = shift;
    $self->{amount_payed} = shift if @_;
    return $self->{amount_payed};
}

sub pay_type {
    my $self = shift;
    $self->{pay_type} = shift if @_;
    return $self->{pay_type};
}

sub frequency {
    my $self = shift;
    $self->{frequency} = shift if @_;
    return $self->{frequency};
}

sub id_bremenitev {
    my $self = shift;
    $self->{id_bremenitev} = shift if @_;
    return $self->{id_bremenitev};
}

sub id_project {
    my $self = shift;
    $self->{id_project} = shift if @_;
    return $self->{id_project};
}

sub debit_type {
    my $self = shift;
    $self->{debit_type} = shift if @_;
    return $self->{debit_type};
}

sub spremembaDB_nasel_zapis {
    my $self = shift;
    $self->{spremembaDB_nasel_zapis} = shift if @_;
    return $self->{spremembaDB_nasel_zapis};
}

sub spremembaDB_prijavi_odjavi {
    my $self = shift;
    $self->{spremembaDB_prijavi_odjavi} = shift if @_;
    return $self->{spremembaDB_prijavi_odjavi};
}

sub spremembaDB_poslano {
    my $self = shift;
    $self->{spremembaDB_poslano} = shift if @_;
    return $self->{spremembaDB_poslano};
}

sub spremembaDB_uspesno_potrjeno {
    my $self = shift;
    $self->{spremembaDB_uspesno_potrjeno} = shift if @_;
    return $self->{spremembaDB_uspesno_potrjeno};
}

sub napaka {
    my $self = shift;
    $self->{napaka} = shift if @_;
    return $self->{napaka};
}


############### METODE


sub stevilo_odprtih_obrokov_kumulativno(){
    my %placila;
    my %placila_sestevki;
    
    %placila_sestevki = (
            st_obrokov => 0,
            znesek_obrokov => 0,
            placano  => 0,
            placanih_obrokov => 0,);
    %placila = self->stevilo_odprtih_obrokov();
    $placila_sestevki{st_obrokov} = $placila{"splosne"}[0]+ $placila{"direktne"}[0]+ $placila{"racuni"}[0];
    $placila_sestevki{znesek_obrokov} = $placila{"splosne"}[1]+ $placila{"direktne"}[1]+ $placila{"racuni"}[1];
    $placila_sestevki{placano} = $placila{"splosne"}[2]+ $placila{"direktne"}[2]+ $placila{"racuni"}[2];
    $placila_sestevki{placanih_obrokov} = $placila{"splosne"}[3]+ $placila{"direktne"}[3]+ $placila{"racuni"}[3];
    
    return %placila_sestevki;
}

sub stevilo_odprtih_obrokov(){
    #Precita koliko obrokov je se odprtih, zaprtih
    #[0] stevilo obrokov
    #[1] Znesek za placilo obrokov
    #[2] Znesek placanih obrokov
    #[3] stevilo placanih obrokov
    my $self = shift;
    
    my $amount;
    my $amount_payed;
    my $debit_type;
    my  %placila = (
						splosne =>[0,0,0,0],
						direktne =>[0,0,0,0],
						racuni =>[0,0,0,0]); #0 - st. obrokov, 1-znesek obroka, 2-placano, 3-st. placanih obrokov
    my $stevilo_odprtih ;
    my $stevilo_zaprtih;
    my $skupaj_obrokov;
    my $znesek_odprto;
    my $znesek_zaprto;    
    
    my $ret;
    
    my $dbh;	
	my $nasel_zapis;
    my $res;
    my $sql_vprasaj;
    my $sth;
    
    $dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
        $sql_vprasaj = "SELECT debit_type, amount, amount_payed ".
				" FROM agreement_pay_installment ".
				" WHERE id_agreement = ? ";

		$sth = $dbh->prepare($sql_vprasaj);
		$sth->execute($self->{id_agreement});
		$nasel_zapis = "0";
        $skupaj_obrokov = 0;
        $stevilo_odprtih = 0;
        $stevilo_zaprtih = 0;
        
        while ($res = $sth->fetchrow_hashref) {
			$nasel_zapis = "1";			
            $amount = $res->{'amount'};	
            $amount_payed = $res->{'amount_payed'}; 
			$debit_type = $res->{'debit_type'};
            if ($debit_type eq '01'){
                if ($amount > 0){
                    $placila{"splosne"}[0] = $placila{"splosne"}[0] +1;                
                    $placila{"splosne"}[1] = $placila{"splosne"}[1] + $amount;
                    $placila{"splosne"}[2] = $placila{"splosne"}[2] + $amount_payed;
                    if ($amount_payed == $amount){
                        $placila{"splosne"}[3] = $placila{"splosne"}[3] +1;
                    }
                }
            }
            elsif ($debit_type eq '04'){
                if ($amount > 0){
                    $placila{"direktne"}[0] = $placila{"direktne"}[0] +1;
                    $placila{"direktne"}[1] = $placila{"direktne"}[1]  + $amount;
                    $placila{"direktne"}[2] = $placila{"direktne"}[2] + $amount_payed;
                    if ($amount_payed == $amount){
                        $placila{"direktne"}[3] = $placila{"direktne"}[3] +1 ;
                    }
                }
            }
            elsif ($debit_type eq 'A1'){
                if ($amount > 0){
                    $placila{"racuni"}[0] = $placila{"racuni"}[0] +1;
                    $placila{"racuni"}[1] = $placila{"racuni"}[1]  + $amount;
                    $placila{"racuni"}[2] = $placila{"racuni"}[2] + $amount_payed;
                    if ($amount_payed == $amount){
                        $placila{"racuni"}[3] = $placila{"racuni"}[3]+1 ;
                    }
                }
            }
            #if ((amount > 0) and (amount == amount_payed) ){
            #    $stevilo_zaprtih = $stevilo_zaprtih +1 ;
            #    $skupaj_obrokov = $skupaj_obrokov +1;
            #}
            #elsif (amount > 0 ){
            #    $stevilo_odprtih = $stevilo_odprtih +1;
            #    $skupaj_obrokov = $skupaj_obrokov +1;
            #}        
        }
        
    }
    return %placila;
}

sub obrok_oznaci_kot_placan($$$){
    #Obrok se oznaci da je placan
    my $self = shift;
    my $id_agreement = shift;
    my $is_OK;
    my $installment_nr = shift;
    my $znesek = shift;
    my $nov_datum;
    my $poslano;
    my $uspesno_potrjeno;
    
    my $dbh;	
	my $nasel_zapis;
    my $res;
    my $sql_vprasaj;
    my $sth;
    
    $self->{napaka} = "";
    $is_OK = '1';
    $poslano = ' ';
    $uspesno_potrjeno = ' ';
    $dbh = DntFunkcije->connectDB;
    
    
    if ($dbh) 
    {
        #najprej precita kater je datum za to bremenitev
        $nov_datum = $self->{date_activate};
        
        
        #ce je vse ok sedaj zapise        
        $sql_vprasaj = "UPDATE agreement_pay_installment SET amount_payed = ? WHERE id_vrstica = ?";
                
        $sth = $dbh->prepare($sql_vprasaj);
        unless ($sth->execute( $znesek, $installment_nr))
        {
            $is_OK = '0';
            # $errstr =
            #print $q->p($sth->errstr);
            $self->{napaka} = $sth->errstr.' SQL:'.$sql_vprasaj.' nov datum '.$nov_datum;
            return $is_OK;
        }
        
       
    }
}

sub obrok_sprememba_shrani_za_posiljanje_v_ZC($$$){
    #Shrani obrok v tabelo, da se poslje v Zbirni center za prijavo ali odjavo
    my $self = shift;
    my $id_agreement = shift;
    my $is_OK;
    my $installment_nr = shift;
    my $prijavi_odjavi = shift;
    my $poslano;
    my $uspesno_potrjeno;
    
    my $dbh;	
	my $nasel_zapis;
    my $res;
    my $sql_vprasaj;
    my $sth;
    
    $self->{napaka} = "";
    $is_OK = '1';
    $poslano = ' ';
    $uspesno_potrjeno = ' ';
    
    if ($prijavi_odjavi eq "Prijava"){
        $prijavi_odjavi = '1';
    }
    else{
        $prijavi_odjavi = '0';
    }
    
    $dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
        #najprej preveri da slucajno ta zapis se ne obstaja
        $nasel_zapis = obrok_sprememba_vrste_bremenitve($self, $id_agreement, $installment_nr);
        if ($nasel_zapis eq '0'){            
            #ce je vse ok sedaj zapise
            $sql_vprasaj = "INSERT INTO bremenitev_sprememba  ".
                    " (id_agreement, installment_nr,".
                    " poslano, uspesno_potrjeno, prijavi_odjavi )".
                    "  VALUES ( ?,?,".
                    " ?,?,?".                
                    " )";
                    
            $sth = $dbh->prepare($sql_vprasaj);
            unless ($sth->execute($id_agreement, $installment_nr,
                        $poslano, $uspesno_potrjeno, $prijavi_odjavi))
            {
                $is_OK = '0';
                # $errstr =
                #print $q->p($sth->errstr);
                $self->{napaka} = $sth->errstr;
                return $is_OK;
            }
        }
        else{
            $is_OK = '0';
            $self->{napaka} = "Prijava za spremembo je ze zapisana!!";
            return $is_OK;
        }
       
    }
    
}
sub obrok_sprememba_frekvence_shrani($$$){
    #Shrani Spremenjeno frekvenco
    #TODO SHRANI V ZAHTEVE KI SE POSLJEJO V ZBIRNI CENTER
    my $self = shift;
    my $id_agreement = shift;
    my $is_OK;
    my $installment_nr = shift;
    my $nova_frekvenca = shift;
    my $nov_datum;
    my $poslano;
    my $uspesno_potrjeno;
    
    my $dbh;	
	my $nasel_zapis;
    my $res;
    my $sql_vprasaj;
    my $sth;
    
    $self->{napaka} = "";
    $is_OK = '1';
    $poslano = ' ';
    $uspesno_potrjeno = ' ';
    $dbh = DntFunkcije->connectDB;
    
    
    if ($dbh) 
    {
        #najprej precita kater je datum za to bremenitev
        $nov_datum = $self->{date_activate};
        
        $nov_datum = substr($nov_datum,0,8).$nova_frekvenca;
        #ce je vse ok sedaj zapise        
        $sql_vprasaj = "UPDATE agreement_pay_installment  ".
                " SET frequency = ? , date_activate = ? ".
                "  WHERE id_agreement = ? AND installment_nr = ?";
                
        $sth = $dbh->prepare($sql_vprasaj);
        unless ($sth->execute( $nova_frekvenca, $nov_datum, 
                    $id_agreement, $installment_nr
                    ))
        {
            $is_OK = '0';
            # $errstr =
            #print $q->p($sth->errstr);
            $self->{napaka} = $sth->errstr.' SQL:'.$sql_vprasaj.' nov datum '.$nov_datum;
            return $is_OK;
        }
        
       
    }
    
}

sub obrok_sprememba_shrani($$$){
    #Shrani obrok v tabelo, da se poslje v Zbirni center za prijavo ali odjavo
    #TODO: SHRANI V TABELO ZAHTEV ZA ZC (TOLE JE SPREMEMBA NACINA PLACILA)
    my $self = shift;
    my $id_agreement = shift;
    my $is_OK;
    my $installment_nr = shift;
    my $nova_vrsta_bremenitve = shift;
    my $poslano;
    my $uspesno_potrjeno;
    
    my $dbh;	
	my $nasel_zapis;
    my $res;
    my $sql_vprasaj;
    my $sth;
    
    $self->{napaka} = "";
    $is_OK = '1';
    $poslano = ' ';
    $uspesno_potrjeno = ' ';
    $dbh = DntFunkcije->connectDB;
    
    
    if ($dbh) 
    {
        #ce je vse ok sedaj zapise
        $sql_vprasaj = "UPDATE agreement_pay_installment  ".
                " SET debit_type = ? ".
                "  WHERE id_agreement = ? AND installment_nr = ?";
                
        $sth = $dbh->prepare($sql_vprasaj);
        unless ($sth->execute( $nova_vrsta_bremenitve, 
                    $id_agreement, $installment_nr
                    ))
        {
            $is_OK = '0';
            # $errstr =
            #print $q->p($sth->errstr);
            $self->{napaka} = $sth->errstr;
            return $is_OK;
        }
        
       
    }
    
}

sub obrok_brisi_iz_bremenitev_sprememba($$){
    #Izbrise izbran obrok pogodbe iz tabele za poslijanje v Zbirni center za spremembo bremenitve
    #Dovoli brisati le tiste obroke, ki se niso bili poslani v zbirni center v prijavo
    my $self = shift;
    my $id_agreement = shift;
    my $installment_nr = shift;
    my $is_OK;    
    my $ret;
    
    my $dbh;	
	my $nasel_zapis;
    my $res;
    my $sql_vprasaj;
    my $sth;
    
    $ret = "1";
    $is_OK = '0';
    $dbh = DntFunkcije->connectDB;
    
    if ($dbh) 
    {
        $sql_vprasaj = "DELETE FROM bremenitev_sprememba ".
				" WHERE id_agreement = ? and installment_nr = ?";
		$sth = $dbh->prepare($sql_vprasaj);
		$res = $sth->execute($id_agreement, $installment_nr);
        unless ($res)
        {
            $is_OK = "0";
            # $errstr =
            #print $q->p($sth->errstr);
            $self->{napaka} = $sth->errstr;
            return $is_OK;
        }
        $self->{napaka} = $res;
    }
    return $ret;
}

sub obrok_sprememba_vrste_bremenitve($$){
    #preveri ce za izbrano pogodbo in obrok ze obstaja
    #zapis za sporocilo v zbirni center o spremembi.
    #'1' Ze obstaja, in se ni bilo poslano na ZC se obvestilo popravi
    #'0' Ne obstaja
    #'2' Ze obstaja in je bilo poslano na ZC - tudi se bo naredilo nov
    #'3' Ze obstaja, datum za posiljanje je prekratko zato se ne bo poslalo
        #ni vec pravocasno da se poslje
	my $self = shift;
    my $id_agreement = shift;
    my $installment_nr = shift;
    
    my $prijavi_odjavi;
    my $poslano;
    my $ret;
    my $uspesno_potrjeno;
    
    my $dbh;	
	my $nasel_zapis;
    my $res;
    my $sql_vprasaj;
    my $sth;
    
    $ret = "0";
    
    $dbh = DntFunkcije->connectDB;
    
    if ($dbh) 
    {
        $sql_vprasaj = "SELECT poslano, uspesno_potrjeno, prijavi_odjavi ".
				"  FROM bremenitev_sprememba ".
				" WHERE id_agreement = ? and installment_nr = ?";
		$sth = $dbh->prepare($sql_vprasaj);
		$sth->execute($id_agreement, $installment_nr);
		$nasel_zapis = "0";
        if($res = $sth->fetchrow_hashref) {
			$self->{spremembaDB_nasel_zapis} = "1";
            $self->{spremembaDB_prijavi_odjavi} = $res->{'prijavi_odjavi'};
            $self->{spremembaDB_poslano} = $res->{'poslano'};
            $self->{spremembaDB_uspesno_potrjeno} = $res->{'uspesno_potrjeno'};
            $ret = "1";
        }
        else{
            #zapis ne obstaja
            $ret = "0";
        }
    }
    return $ret;
}

sub prestavi_obrok($$){
    my $self = shift;
    #my $stevilka_obroka = shift;
    #my $pogodba = shift;    
    my $id_vrstica = shift;
	#my $znesek = shift;
	my $id_agreement = shift;
	
    #my $id_transakcije = shift;
	#my $datum_knjizenja = shift;
	
	my $da_leto;
	my $da_mesec;
	my $da_dan;
	my $installment_nr;
	my $stara_pogodba;
	my $date_activate;
	my $amount;
	my $pay_type;
	my $account_number;
	my $id_donor;
	my $frequency;
	my $id_bremenitev;
	my $mesec;
	my $leto;
	my $tax_number;
	my $id_project;
	my $debit_type;
	my $id_notice;
	my $id_packet_pp;
	
	
	my $dbh;
	my $errstr ;
	my $is_ok;
    my $nasel_zapis;
	my $res;
    my $sql;
    my $sth;
	$dbh = DntFunkcije->connectDB;
	
    if ($dbh) {
		
			#CarpeDiem::Zapisi_id_transakcije($id_transakcije);
            #Preveri, ce obrok, ki se prenasa sploh ima znesek za bremenitev. Drugace ga
            #ne prenese
            $sql = "SELECT id_vrstica, installment_nr,".
				" installment_nr, stara_pogodba, date_activate, amount, pay_type, ".
				" account_number, id_donor, frequency, id_bremenitev, mesec, ".
				" leto, tax_number, id_project, debit_type, id_notice, id_packet_pp ".
				" FROM agreement_pay_installment ".
				" WHERE  id_agreement = ? and id_vrstica = ?";
			$sth = $dbh->prepare($sql);
			$sth->execute($id_agreement, $id_vrstica);
            $nasel_zapis = "0";
            if($res = $sth->fetchrow_hashref) {                
                $installment_nr = $res->{'installment_nr'};			
				$stara_pogodba = $res->{'stara_pogodba'};
				$date_activate = $res->{'date_activate'};
				$amount = $res->{'amount'};
				$pay_type = $res->{'pay_type'};
				$account_number = $res->{'account_number'};
				$id_donor = $res->{'id_donor'};
				$frequency = $res->{'frequency'};
				$id_bremenitev = $res->{'id_bremenitev'};
				$mesec = $res->{'mesec'};
				$leto = $res->{'leto'};
				$tax_number = $res->{'tax_number'};
				$id_project = $res->{'id_project'};
				$debit_type = $res->{'debit_type'};
				$id_notice = $res->{'id_notice'};
				$id_packet_pp = $res->{'id_packet_pp'};
                $nasel_zapis = '1';
            }
            if ($nasel_zapis eq '1' && $amount > 0){
                #poisce zadnjo stevilko obroka
                $sql = "SELECT id_vrstica, installment_nr,".
                    " installment_nr, stara_pogodba, date_activate, amount, pay_type, ".
                    " account_number, id_donor, frequency, id_bremenitev, mesec, ".
                    " leto, tax_number, id_project, debit_type, id_notice, id_packet_pp ".
                    " FROM agreement_pay_installment ".
                    " WHERE  id_agreement = ? ORDER BY installment_nr";
                $sth = $dbh->prepare($sql);
                $sth->execute($id_agreement);
               
                while ($res = $sth->fetchrow_hashref) {				
                    $installment_nr = $res->{'installment_nr'};			
                    #$stara_pogodba = $res->{'stara_pogodba'};
                    #$date_activate = $res->{'date_activate'};
                    #$amount = $res->{'amount'};
                    #$pay_type = $res->{'pay_type'};
                    #$account_number = $res->{'account_number'};
                    #$id_donor = $res->{'id_donor'};
                    #$frequency = $res->{'frequency'};
                    #$id_bremenitev = $res->{'id_bremenitev'};
                    $mesec = $res->{'mesec'};
                    $leto = $res->{'leto'};
                    #$tax_number = $res->{'tax_number'};
                    #$id_project = $res->{'id_project'};
                    #$debit_type = $res->{'debit_type'};
                    #$id_notice = $res->{'id_notice'};
                    #$id_packet_pp = $res->{'id_packet_pp'};
                }
                $mesec = $mesec +1;
                if ($mesec == 13 || $mesec == 0){
                    $mesec = 1;
                    $leto = $leto +1;
                }
                if ($leto < 10){
                    $leto = '0'.($leto*1);
                }
                if ($mesec lt '10'){
                    $mesec = '0'.$mesec
                }
                
                $da_leto = '20'.$leto;
                $da_mesec = $mesec;
                #print $q->p("leto:".$da_leto." mesec:".$mesec." ");
                $is_ok = 1;
                # doda nov obrok
                $sql = "INSERT INTO agreement_pay_installment ".
                    "( id_agreement, stara_pogodba , installment_nr, ".
                    " date_activate , amount , pay_type , ".
                    " account_number , id_donor , frequency , id_bremenitev , ".
                    " mesec , leto , tax_number , id_project , debit_type , ".
                    "id_notice , id_packet_pp ) ".
                    " VALUES (?,?,?,".
                    " ?, ?, ?,".
                    " ?, ?, ?, ?, ".
                    " ?, ?, ?, ?, ?, ".
                    " ?, ?) ";
                $sth = $dbh->prepare( $sql);
                
                unless($sth->execute($id_agreement, $stara_pogodba , $installment_nr+1, 
                                     $da_leto.'-'.$da_mesec.'-'.$frequency , $amount , $pay_type ,
                                     $account_number , $id_donor , $frequency , $id_bremenitev ,
                                     $mesec , $leto , $tax_number , $id_project , $debit_type ,
                                     $id_notice , $id_packet_pp ))
                {
                    $is_ok = 0;
                    # $errstr =
                    #print $q->p($sth->errstr);
                }
                #print $q->p("ok".$is_ok);
                if ($is_ok == 1){
                    #Obroku, ki je prestavljen na nov obrok postavi zneske na 0
                    $sql = "UPDATE agreement_pay_installment ".
                                         " SET amount ='0', amount_payed = '0' ".
                                         " WHERE id_vrstica = ?";
                    $sth = $dbh->prepare($sql);
                    unless($sth->execute( $id_vrstica)){
                        #print $q->p('Postavitev zneskov na 0 na orig. dok.'.$sth->errstr);
                    }
                }
            }
		
		#$sql = "";
		
	}
	$sth->finish;
    $dbh->disconnect();
    return $id_agreement;
	#$q->param(-name=>'hid_akcija',-value=>'');
	#print $q->a({-href=>"DntRocniVnosi.pl?hid_menu=placila_direktnih_db&edb_datum=$datum_knjizenja"}, "Vnos zaporednih {tevilk");
}



sub Podaj_zahtevek_za_zaprtje(){
    my $self = shift;
    my $datum;
    my $cas;
    my $id_agreement;
    my %placila;
    my $sporocilo;
    my $is_OK;
    #Ker se zapre zadnji obrok direktne bremenitve se zapise v tabelo za zaprtje
    
    $is_OK = '1';
    $sporocilo = "";
    $id_agreement = $self->{id_agreement} ;
    
    my $danes;
    
    my $dbh;	
    my $nasel_zapis;
    my $res;
    my $sql_vprasaj;
    my $sth;
    #Preveri da zahtevek se ni bil poslan
    $dbh = DntFunkcije->connectDB;
    if ($dbh) {
        $sql_vprasaj = "SELECT id_agreement, potrjeno ".
                " FROM direktne_zahtevek_za_zapri ".
                " WHERE id_agreement = ? ";
        $sth = $dbh->prepare($sql_vprasaj);
        
        $sporocilo = $sth->execute($id_agreement );
        $nasel_zapis = "0";
       #$self->{napaka} = $sporocilo;  
       #return '1';
        if($res = $sth->fetchrow_hashref) {
            $sporocilo = "Zahtevek za bremenitev je bil ze poslan";
            $is_OK = '0';
        }
        else{
            #Ce je vse OK shrani pogodbo v tabelo za obvestilo za zaprtje
            #$danes = CarpeDiem->
            
            ($datum,$cas) = DntFunkcije::time_stamp(); #localtime;
            $sql_vprasaj = "INSERT INTO direktne_zahtevek_za_zapri ".
                " (id_agreement, datum_prijave, potrjeno )".
                " VALUES (?, CURRENT_TIMESTAMP, ?)";
            $sth = $dbh->prepare($sql_vprasaj);
            $sporocilo = $sth->execute($id_agreement, ' ' );
            if ($sporocilo){
                $is_OK = '1';
                
            }
            else{
                $is_OK = '0';
            }
            
        }
        $sth->finish;
        $dbh->disconnect();
        }
    

    $self->{napaka} = $sporocilo; 
    return $is_OK;
     
}

sub Podaj_zahtevek_za_sporocilo_Vse_zaprto(){
    #Vsi obroki pogodbe so plačani
    #Pogodba se shrani in da na seznam, da se poslje sporocilo donatorju
    #o placilu vseh obrokov
    my $self = shift;
    
    my $amount;
    my $amount_payed;
    my $amount_sum;
    my $datum;
    my $cas;
    my $id_agreement;
    my $id_event;
    my $id_project;
    my $id_staff;
    my $last_debit_type;
    my $must_be_payed;
    my $installments_num;
    my $installments_num_real;
    my $installments_payed;
    my $installment_last_date;
    my %placila;
    
    my $sporocilo;
    
    my $is_OK;
    #Ker se zapre zadnji obrok direktne bremenitve se zapise v tabelo za zaprtje
    
    $is_OK = '1';
    $sporocilo = "";
    $id_agreement = $self->{id_agreement} ;
    #Najprej preveri da ni vec nobenega odprtega obroka za direktno bremenitev
    %placila = $self->stevilo_odprtih_obrokov();
    
    if (($placila{"splosne"}[0] == $placila{"splosne"}[3])
			 && ($placila{"racuni"}[0] == $placila{"racuni"}[3])
			 && ($placila{"direktne"}[0] == $placila{"direktne"}[3]))
        {
        #Ker je stevilo vseh bremenitev enako placanih, pomeni da so vse zaprte
        
        my $danes;
        
        my $dbh;	
        my $nasel_zapis;
        my $res;
        my $sql_vprasaj;
        my $sth;
        #Preveri da zahtevek se ni bil poslan
        $dbh = DntFunkcije->connectDB;
        if ($dbh) {
            $sql_vprasaj = "SELECT id_agreement ".
                    " FROM agreement_close ".
                    " WHERE id_agreement = ? ";
            $sth = $dbh->prepare($sql_vprasaj);
            
            $sporocilo = $sth->execute($id_agreement );
            $nasel_zapis = "0";
           #$self->{napaka} = $sporocilo;  
           #return '1';
            if($res = $sth->fetchrow_hashref) {
                $sporocilo = "Zahtevek za zaprtje je bil ze poslan";
                $is_OK = '0';
            }
            else{
                #Ce je vse OK shrani pogodbo v tabelo za obvestilo za zaprtje
                $sql_vprasaj = "SELECT num_installments, amount2, id_project, ".
                    " id_staff, id_event".
                    " FROM sfr_agreement ".
                    " WHERE id_agreement = ? ";
                $sth = $dbh->prepare($sql_vprasaj);
                $sth->execute($self->{id_agreement});
                if($res = $sth->fetchrow_hashref) {
                    $installments_num = $res->{'num_installments'};
                    $id_project = $res->{'id_project'};
                    $id_staff = $res->{'id_staff'};
                    $id_event = $res->{'id_event'};
                    $must_be_payed = $res->{'amount2'};
                    $must_be_payed = $must_be_payed * $installments_num;
                }
                else{
                    $id_project = '';
                    $id_staff = '';
                    $id_event = '';
                    $installments_num = 0;
                    $must_be_payed = 0
                }
                #Potegne podatke iz obrokov
                $sql_vprasaj = "SELECT amount, amount_payed, date_activate, ".
                    " debit_type ".
                    " FROM agreement_pay_installment ".
                    " WHERE id_agreement = ? ORDER BY date_activate";
        
                $sth = $dbh->prepare($sql_vprasaj);
                $sth->execute($self->{id_agreement});
                $nasel_zapis = "0";
                
                #$installments_num = 0;
                $installments_num_real = 0;
                $installments_payed = 0;
                $amount = 0;
                $amount_payed = 0;
                $amount_sum = 0;
                while ($res = $sth->fetchrow_hashref) {
                    $nasel_zapis = "1";
                    $installments_num = $installments_num +1;
                    $amount = $res->{'amount'};	
                    $amount_payed = $res->{'amount_payed'}; 
                    if (($amount + $amount_payed)>0){
                        $installments_num_real = $installments_num_real +1;
                        $installment_last_date = $res->{'date_activate'};
                        $last_debit_type  = $res->{'debit_type'};
                        $amount_sum = $amount_sum + $amount_payed
                    }
                    #else{
                    #}
                }
                ($datum,$cas) = DntFunkcije::time_stamp(); #localtime;
                $sql_vprasaj = "INSERT INTO agreement_close ".
                    " (id_agreement, last_installment,".
                    " num_installments, payed, must_be_payed,".
                    " storno_installments,".
                    " id_project, id_event, id_staff, debit_type)".
                    " VALUES (?, ?, ".
                    " ?, ?, ?, ".
                    " ?, ".
                    " ?, ?, ?, ? )";
                $sth = $dbh->prepare($sql_vprasaj);
                $sporocilo = $sth->execute($id_agreement, $installment_last_date,
                        $installments_num_real, $amount_sum, $must_be_payed,
                        ($installments_num-$installments_num_real),
                        $id_project, $id_event, $id_staff, $last_debit_type);
                if ($sporocilo){
                    $is_OK = '1';
                    $sporocilo = "Zapisal";
                    
                }
                else{
                    $is_OK = '0';
                    $sporocilo = "Zapis ni uspel ".$sth->errstr;
                }
                
            }
            $sth->finish;
            $dbh->disconnect();
        }
    }
    else{
        #Ne poda zahtevka za zaprtje, ker niso vsi obroki zaprti
        $is_OK = '0';
        $sporocilo = 'Vsi obroki niso zaprti. Zato zahtvek za zaprtje ni podan';
    }
    $self->{napaka} = $sporocilo; 
    return $is_OK;
     
}

sub storniraj_obrok($$){
    #se v delu
    my $self = shift;
    my $id_agreement = shift;
	my $id_vrstica = shift;
    my %placila;
    my $st_odprtih_obrokov;
    
	my $dbh;
	my $errstr ;
	my $is_ok;
    my $sql;
    my $sth;
	$dbh = DntFunkcije->connectDB;
	
    my $timeStorno = localtime;
    if ($dbh) {
		#Izbran obrok označi kot  brezpredmeten
        $sql = "UPDATE agreement_pay_installment ".
                " SET storno = '$timeStorno', amount_payed = 0 ".
                " WHERE  id_agreement = ? and installment_nr = ?";
		$sth = $dbh->prepare($sql);
		
        unless ($sth->execute($id_agreement, $id_vrstica))
        {
            $is_ok = '0'.$sth->errstr;
            # $errstr =
            #print $q->p($sth->errstr);
            $self->{napaka} = $sth->errstr;
            #return $is_ok;
        }
    }
    preveri_pogodba_zakljucena($self, $id_agreement);
	$sth->finish;
    $dbh->disconnect();
    return ;#'bb'.$id_agreement.$id_vrstica.'cc';
}

sub preveri_pogodba_zakljucena($$){
    #preveri ce je v pogodbi se kak neplacan in nestorniran obrok
    my $self = shift;
    my $id_agreement = shift;
  
	my $sql;
	my $sth;
	my $dbh;
	my $res;
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {	
	#preveri ce je pogodba zakljucena:
        my $najdena_vrstica = 0;
        $sql = "SELECT * FROM sfr_agreement WHERE id_agreement = ? AND create_installments IS NULL";
        $sth = $dbh->prepare($sql);
        $sth->execute($id_agreement);
		if($res = $sth->fetchrow_hashref){
			$najdena_vrstica = 1;
		}
        
		$sql = "SELECT * FROM agreement_pay_installment WHERE ".
				" id_agreement=? AND (amount_payed IS NULL OR amount_payed < amount) AND storno IS NULL";
		$sth = $dbh->prepare($sql);
        $sth->execute($id_agreement);
		

		if($res = $sth->fetchrow_hashref){
			$najdena_vrstica = 1;
		}
		if($najdena_vrstica == 0){
            my $status = 'P';
            #ce ni nasel vrstice so bili vsi obroki placani ali stornirani
            #poglej, ce je bil kater izmed obrokov storniran:
            $sql = "SELECT id_agreement, storno FROM agreement_pay_installment WHERE ".
				" id_agreement=? AND storno IS NOT NULL";
            $sth = $dbh->prepare($sql);
            $sth->execute($id_agreement);
            if($res = $sth->fetchrow_hashref){
                $status = 'S';
            }
 			
			$sql = "UPDATE sfr_agreement SET status = ? WHERE id_agreement = ?";
			$sth = $dbh->prepare($sql);
			$sth->execute($status, $id_agreement);
            
            $sql = "SELECT pay_type2 FROM sfr_agreement WHERE id_agreement = ? AND pay_type2 = '04'";
            $sth = $dbh->prepare($sql);
            $sth->execute($id_agreement);
    
            if($res = $sth->fetchrow_hashref){
                $sql = "INSERT INTO direktne_zahtevek_za_zapri ".
                    " (id_agreement, datum_prijave) ".
                    "  VALUES (?, CURRENT_TIMESTAMP)";
                $sth = $dbh->prepare($sql);
                $sth->execute($id_agreement);
            }

            
                    
		}
	}    
	$sth->finish;
    $dbh->disconnect();
    
    return ;
    
}

sub citaj_pogodbo_obrok(){
    my $self = shift;
	my $installment_nr;
	my $id_agreement;
	my $id_donor;
	
	
    my $dbh;	
	my $nasel_zapis;
    my $res;
    my $sql_vprasaj;
    my $sth;
	$id_agreement = $self->{id_agreement};
	$installment_nr = $self->{installment_nr};
    #$self->{first_name}='Tincek';
    $dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
        $sql_vprasaj = "SELECT id_vrstica, date_activate, ".
				" date_due, amount, amount_payed, pay_type, ".
				" id_donor, frequency, id_bremenitev, ".
				" id_project, debit_type ".
				" FROM agreement_pay_installment ".
				" WHERE id_agreement = ? AND installment_nr = ?";
		$sth = $dbh->prepare($sql_vprasaj);
		$sth->execute($id_agreement, $installment_nr);
		$nasel_zapis = "0";
        if($res = $sth->fetchrow_hashref) {
			$nasel_zapis = "1";
            $self->{id_vrstica} = $res->{'id_vrstica'};
            $self->{date_activate} = $res->{'date_activate'};
			$self->{date_due} = $res->{'date_due'};
			$self->{amount} = $res->{'amount'};
			$self->{amount_payed} = $res->{'amount_payed'};
			$self->{pay_type} = $res->{'pay_type'};
			$self->{id_donor} = $res->{'id_donor'};
			$self->{frequency} = $res->{'frequency'};
			$self->{id_bremenitev} = $res->{'id_bremenitev'};
			$self->{id_project} = $res->{'id_project'};
			$self->{debit_type} = $res->{'debit_type'};
		}
#        
#        $sth->finish;
#        $dbh->disconnect();
   }
}

return 1;
