package DntFunkcije;

use DBI;
use strict;
my ($dbname,$host,$port,$username,$password);

sub makeMenu
{
    my $q = $_[1];

    print
        $q->a({-href=>"/modules/scripts/DntDonatorji.pl"}, "Donatorji")
        . " | "
        . $q->a({-href=>"/modules/scripts/DntPoloznice.pl"}, "Generiraj poloznice")
        . " | "
        . $q->a({-href=>"/modules/scripts/BranjeDatotek.pl"}, "Branje datotek")
        . " | "
		. $q->a({-href=>"/modules/scripts/DntPogodbe.pl"}, "Pogodbe")
		#. $q->a({-href=>"/modules/scripts/DntObrokiSpremembe.pl"}, "Obroki spremembe");
}

sub connectDB
{
	#return DBI->connect("dbi:Pg:dbname=donator_test;host=127.0.0.1;port=5432;", "postgres", "encoding=utf-8");

#    return DBI->connect("dbi:Pg:dbname=donator;host=127.0.0.1;port=5432;", "pgw-www-donator", "14W5f5x7Q");
    return DBI->connect("dbi:Pg:dbname=donator;host=127.0.0.1;port=5432;", "postgres");
}
sub connectDBtest
{
#    return DBI->connect("dbi:Pg:dbname=donator;host=127.0.0.1;port=5432;", "pgw-www-donator", "14W5f5x7Q");

	return DBI->connect("dbi:Pg:dbname=postgres;host=10.1.1.97;port=5432;", "postgres", "pgsql");
    #return DBI->connect("dbi:Pg:dbname=donator_test;host=127.0.0.1;port=5432;", "postgres", "encoding=utf-8");
}
sub statusPogodbe($){
	
	my $id_agreement=$_[0];    
	my $sql;
	my $sth;
	my $dbh;
	my $res;
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {	
	#preveri ce je pogodba zakljucena:
		$sql = "SELECT * FROM agreement_pay_installment WHERE ".
				" id_agreement=? AND (date_due IS NULL OR amount_payed < amount OR storno IS NOT NULL)";
		$sth = $dbh->prepare($sql);
        $sth->execute($id_agreement);
		my $najdena_vrstica = 0;
		if($res = $sth->fetchrow_hashref){
			$najdena_vrstica = 1;
		}
		if($najdena_vrstica == 0){
			#ce ni nasel vrstice so bili vsi obroki placani ali stornirani
			$sql = "UPDATE sfr_agreement SET status = 'P' WHERE id_agreement = ?";
			$sth = $dbh->prepare($sql);
			$sth->execute($id_agreement);			
		}
	}	
}
sub genSqlDonatorji
{
    my $q = $_[1];  #ne vem zakaj je v 1, v 0 je DntFunkcije (pac mogoce zato ker je package).
    my $det = $_[2]; #ce klicem z details moram odstranit order by

    my $edb_first_name  = $q->param("edb_first_name");
    my $edb_scnd_name = $q->param("edb_scnd_name");
    my $edb_street = $q->param("edb_street");
    my $hid_sort = $q->param("hid_sort");
    my $s;

    $s = "select id_donor, first_name, scnd_name, street ";
    $s.= " from sfr_donor ";
    $s.= " where 1=1";

    if($edb_first_name)
    {
        $s .= " and first_name ilike '%$edb_first_name%'";
    }
    if($edb_scnd_name)
    {
        $s .= " and scnd_name ilike '%$edb_scnd_name%'";
    }
    if($edb_street)
    {
        $s .= " and street ilike '%$edb_street%'";
    }

    unless($det)
    {
        if($hid_sort)
        {
            $s .= " order by $hid_sort";
        }
    }

    return $s;
}

return 1;

sub koledar($)
#Koda, ki vstavi javasript za vpis koledarja
{

	"<style type=\"text/css\">\@import url(/koledar/calendar-win2k-1.css);</style>
	<script type=\"text/javascript\" src=\"/koledar/calendar.js\"></script>
	<script type=\"text/javascript\" src=\"/koledar/lang/calendar-en.js\"></script>
	<script type=\"text/javascript\" src=\"/koledar/calendar-setup.js\"></script>
	<script type=\"text/javascript\" src=\"/koledar/lang/calendar-en.js\"></script>

	<input type=\"text\" id=\"data\" name=\"data\"  />
	<button id=\"trigger\">...</button>
	<script type=\"text/javascript\">

	Calendar.setup(
	  {
		inputField  : \"data\",         // ID of the input field
		ifFormat    : \"%d.%m.%Y\",    // the date format
		button      : \"trigger\"       // ID of the button
	  }
	);
	</script>"
}

sub FormatFinancno($){
	my $rez = shift;
	if(!defined $rez){
		return "";
	}
	$rez = sprintf "%.2f", $rez;
	$rez=~s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1x/g;
	$rez=~tr/./,/;
	$rez=~tr/x/./;
	return $rez;
}


sub VzamiIdTransakcije(){
	#preprecuje, da bi se zaradi Refresha (F5) ali Back, neka transakcija dvakrat zapisala
	#funkcija zgenerira nakljucno stevilo, preveri, ce ze ni zapisana v tabeli transakcij
	#print $q->p("FUNKCIJA: VzamiIdTransakcije");
	my $dbh;
	my $id_transakcije;
	my $nasel_zapis;
	my $res;
	my $sql;
	my $sth;
	$dbh = DntFunkcije->connectDB;
    if ($dbh)
    {
		$nasel_zapis = "1";
		while ($nasel_zapis eq "1" ){
			$id_transakcije = int(rand(1000000));
			$sql = "SELECT id_transakcije FROM transakcije WHERE id_transakcije = ?";
			$sth = $dbh->prepare($sql);
			$sth->execute($id_transakcije);
			$nasel_zapis = "0";

			if ($res = $sth->fetchrow_hashref){	#$nasel_zapis eq "0"){
				$nasel_zapis = "0";
			}
			else{
				$nasel_zapis = "0";
			}

		}
		$sth->finish;
		$dbh->disconnect();
		return $id_transakcije;
	}

    $dbh->disconnect();
	return 0;
}

sub Preveri_id_transakcije($){
	#print $q->p("FUNKCIJA: Preveri_id_transakcije");
	#Ce najde id_transakcije vrne vrednost '1', drugace '0'
	my $id_transakcije = shift;
	my $dbh;
	my $nasel_zapis;
	my $res;
	my $sql;
	my $sth;
	$dbh = DntFunkcije->connectDB;
	$nasel_zapis = '1';
    if ($dbh) {
		$nasel_zapis = "1";

		$sql = "SELECT id_transakcije FROM transakcije WHERE id_transakcije = ?";
		$sth = $dbh->prepare($sql);
		$sth->execute($id_transakcije);
		$nasel_zapis = "0";

		if ($res = $sth->fetchrow_hashref){	#$nasel_zapis eq "0"){
			$nasel_zapis = "1";
		}
		else{
			$nasel_zapis = "0";
		}

	}
	$sth->finish;
	$dbh->disconnect();
	return $nasel_zapis;

}
sub Zapisi_id_transakcije($){
	#print $q->p("FUNKCIJA: Zapisi_id_transakcije");
	my $id_transakcije = shift;
	my $cas;
	my $datum;
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		($datum,$cas) = DntFunkcije->time_stamp(); #localtime;
		$sql = "INSERT INTO transakcije (id_transakcije, datum)
            VALUES (?,?)";
        #print $q->p($sql_vprasaj);
        $sth = $dbh->prepare($sql);
        $sth->execute($id_transakcije,$datum);


	}
	$sth->finish;
	$dbh->disconnect();

}
sub DolzTexta($$){
	my $cNiz = shift;
	my $nDolzina = shift;
	#Zapolni s presledki niz na koncu
	my $i;
	my $nVhodDol;
	my $ostanek;
	my $prostor;
	
	$nVhodDol = length($cNiz);
	if ($nVhodDol < $nDolzina){
		$ostanek = $nDolzina - $nVhodDol;
		if ($ostanek > 0){
			for($i =1; $i <= $ostanek; $i++){
				$prostor = $prostor.' ';
			}
		}
		#$prostor = ' 'x$ostanek;
		my $test;
		$test = length($prostor);
		$cNiz = $cNiz.$prostor;
	}
	else{
		$cNiz = substr($cNiz,0, $nDolzina);
	}
	return $cNiz;
	#LOCAL nVhodDol:=0
	#nVhodDol:=Len(cNiz)
	#IF nVhodDol<nDolzina
	#	cNiz:=cNiz+Space(nDolzina-nVhodDol)
	#ELSEIF 	nVhodDol>nDolzina
	#	cNiz:=SubStr(cNiz,1,nDolzina)
	#ENDIF	
	#RETURN cNiz
}
sub EanCheckDigit($$) {
		my $cRez = shift; #13 mestna st.
		my $nMest = shift; #13
		
		
		my @aPolja;
		my $cCheck;
		my $cZnak;
		my $i;
		my $nasledni10;
		my $nRazlika;

		my $nSum=0;
		
		#if ($nMest*1 == 0){
		#		$nMest = len($cRez);
		#}
		#else{
		#		$cRez = DntFunkcije::DolzTexta($cRez,$nMest);
		#}
		for ($i = 0 ; $i <= ($nMest-1); $i++){
				push(@aPolja,substr($cRez, $nMest-$i-1, 1));
		}
		for ($i = 1; $i < $nMest; $i++){
				$cZnak = $aPolja[$i];
				$nSum+=$cZnak*($i+1);
		}
		$nSum%=11;
		$nSum=11-$nSum;
		
		if($nSum==10 || $nSum==11){
			$nSum=0;
		}
		
		return $nSum;
				
		#		if (($i % 2) == 0){
		#				$nSumLiha = $nSumLiha + $cZnak;
		#		}
		#		else{
		#				$nSumSoda = $nSumSoda + $cZnak;
		#		}
		#		
		#		
		#}
		#$nSumSoda = $nSumSoda * 3;
		#$nSumSoda = $nSumSoda + $nSumLiha;
		#$nRazlika = int($nSumSoda / 10);
		#$nasledni10 = 10 * ($nRazlika +1);
		#$nRazlika = $nasledni10 - $nSumSoda;
		#if ($nRazlika == 10){
		#		$cCheck = "0";
		#}
		#else{
		#		$cCheck = substr($nRazlika,0,1);
		#}

	
}

sub trim($)
# Perl trim function to remove whitespace from the start and end of the string
{
	
	my $string = shift;
	if($string){
		$string =~ s/^\s+//;
		$string =~ s/\s+$//;
	}
	return $string;
}

sub ltrim($)
# Left trim function to remove leading whitespace
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

sub rtrim($)
# Right trim function to remove trailing whitespace
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

sub time_stamp {
  my ($d,$t);
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

        $year += 1900;
        $mon++;
        $d = sprintf("%4d-%2.2d-%2.2d",$year,$mon,$mday);
        $t = sprintf("%2.2d:%2.2d:%2.2d",$hour,$min,$sec);
        return($d,$t);
}

sub SToD($){
	#LLLLMMDD spremeni v DD.MM.LLLL
	my $string = shift;
	$string = substr($string,6,2).'.'.substr($string,4,2).'.'.substr($string,0,4);
	return $string;
}

sub Piskotki($){
	my $id = shift;
	my $piskotki = $ENV{'HTTP_COOKIE'};
	
	$piskotki =~ /$id=\w*/;
	$piskotki = substr($&, length($id)+1);
	return $piskotki;
}

sub si_date($){
	#funkcija iz formata za TimeStamp pretvori datum v dd.mm.llll
	my $danes = shift;
	my $cas;
	if(length($danes)>0){
		#vzame datum, ki se poslje
	}
	else {
		#ker ne posljem datuma, vrne trenuti datum
		($danes,$cas) = DntFunkcije->time_stamp();
	}
	$danes = substr($danes,8,2).substr($danes,4,4).substr($danes,0,4);
	return($danes,$cas);
}

sub sl_date($){
	#funkcija iz formata za TimeStamp pretvori datum v dd/mm/llll
	my $danes = shift;
	
	unless($danes){
		return "";
	}
	if($danes =~ m/\d{4}-\d{2}-\d{2}.*/){
		$danes = substr($danes,8,2)."/".substr($danes,5,2)."/".substr($danes,0,4);
	}
	return $danes;
}
sub sl_date_ura($){
	#funkcija iz formata za TimeStamp pretvori datum v dd/mm/llll
	my $danes = shift;
	
	unless($danes){
		return "";
	}
	if($danes =~ m/\d{4}-\d{2}-\d{2}.*/){
		$danes = substr($danes,8,2).".".substr($danes,5,2).".".substr($danes,0,4).
				 substr($danes,10, 6);
	}
	return $danes;
}
sub raw_date($){
	#funkcija iz formata LLLLMMDD pretvori datum v dd/mm/llll
	my $date = shift;
	
	unless($date){
		return "";
	}
	if($date =~ m/\d{4}\d{2}\d{2}/){
		$date = substr($date,6,2)."/".substr($date,4,2)."/".substr($date,0,4);
	}
	return $date;
}
sub debitName{
	my $name = shift;
	my $csv = shift || 0;
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	
	

	$dbh = DntFunkcije->connectDB;
	if ($dbh) {		
		$sql = "select * FROM sfr_pay_type WHERE debit_type=? LIMIT 1";
		$sth = $dbh->prepare($sql);
		$sth->execute($name);
		if($res = $sth->fetchrow_hashref){
			if ($csv == 1){
				return DntFunkcije::trim($res->{'name_pay_type'});
			}
			return "<span title='$name'>".DntFunkcije::trim($res->{'name_pay_type'})."</span>";
		}
	}
	
}
sub debitNames{
	my $dbh = shift;
	my $res;
	my $sql;
	my $sth;
	

	$sql ="SELECT * FROM sfr_pay_type";	
	$sth = $dbh->prepare($sql);
	$sth->execute();
	my %debit_hash = ();
	while($res = $sth->fetchrow_hashref){

		$debit_hash{$res->{debit_type}} = trim($res->{name_pay_type});
	}
	return %debit_hash;
}

#Prevodi stolpcev iz baze:
sub SloColumns($){
	my $tmp=shift;
	my @col = split(/__/, $tmp);
	if(@col > 1){
		$tmp = $col[1];
	}
	if($tmp eq "id_staff"){
		$tmp="id zaposlenega";
	}
	elsif($tmp eq "first_name"){
		$tmp="ime";
	}
	elsif($tmp eq "scnd_name"){
		$tmp="priimek";
	}
	elsif($tmp eq "born_date"){
		$tmp="datum rojstva";
	}
	elsif($tmp eq "tax_number"){
		$tmp="davcna stevilka";
	}
	elsif($tmp eq "liable_for_tax"){
		$tmp="davcni zavezanec";
	}
	elsif($tmp eq "id_donor"){
		$tmp="id donatorja";
	}
	elsif($tmp eq "entity"){
		$tmp="pravna oseba";
	}
	elsif($tmp eq "name_company"){
		$tmp="naziv podjetja";
	}
	elsif($tmp eq "prefix"){
		$tmp="prednaziv";
	}
	elsif($tmp eq "street"){
		$tmp="ulica";
	}
	elsif($tmp eq "street_number"){
		$tmp="ulicna stevilka";
	}
	elsif($tmp eq "post"){
		$tmp="postna st.";
	}
	elsif($tmp eq "prmnt_post_number"){
		$tmp="stalna postna st";
	}		
	elsif($tmp eq "personal_dc"){
		$tmp="osebni dokument";
	}
	elsif($tmp eq "prs_dc_nmbr"){
		$tmp="st. osebnega dokumenta";
	}
	elsif($tmp eq "trr_donor"){
		$tmp="trr";
	}
	elsif($tmp eq "street_mail"){
		$tmp="ulica posiljanja";
	}
	elsif($tmp eq "street_num_mail"){
		$tmp="ulicna st. posiljanja";
	}
	elsif($tmp eq "post_mail"){
		$tmp="posta posiljanja";
	}
	elsif($tmp eq "emailing_alow"){
		$tmp="dovoli email";
	}
	elsif($tmp eq "post_emailing_alow"){
		$tmp="dovoli posto";
	}
	elsif($tmp eq "special_donor"){
		$tmp="posebni donator";
	}
	elsif($tmp eq "active_donor"){
		$tmp="aktivni donator";
	}
	elsif($tmp eq "greting_card"){
		$tmp="voscilnica";
	}
	elsif($tmp eq "special_thanks"){
		$tmp="posebna zahvala";
	}
	elsif($tmp eq "retired"){
		$tmp="upokojen";
	}
	elsif($tmp eq "new_year"){
		$tmp="novo leto";
	}
	elsif($tmp eq "offer"){
		$tmp="ponudba";
	}
	elsif($tmp eq "prmnt_address"){
		$tmp="stalni naslov";
	}
	elsif($tmp eq "prmnt_address_number"){
		$tmp="stalni naslov st";
	}
	elsif($tmp eq "tmp_address"){
		$tmp="zacasni naslov";
	}
	elsif($tmp eq "tmp_address_number"){
		$tmp="zacasni naslov st";
	}
	elsif($tmp eq "tmp_post"){
		$tmp="posta";
	}
	elsif($tmp eq "prs_dc_date"){
		$tmp="datum osebnega dokumenta";
	}
	elsif($tmp eq "prs_dc_valid"){
		$tmp="veljavnost osebnega dokumenta";
	}
	elsif($tmp eq "prs_dc_issuer"){
		$tmp="dokument izdal";
	}
	elsif($tmp eq "trr_bank"){
		$tmp="trr banke";
	}
	elsif($tmp eq "education"){
		$tmp="izobrazba";
	}
	elsif($tmp eq "profession"){
		$tmp="poklic";
	}
	elsif($tmp eq "occupation"){
		$tmp="zaposlitev";
	}
	elsif($tmp eq "type_occupation"){
		$tmp="vrsta zaposlitve";
	}
	elsif($tmp eq "num_wrk_hour"){
		$tmp="st delovnih ur";
	}
	elsif($tmp eq "staff_agreement"){
		$tmp="pogodba";
	}
	elsif($tmp eq "date_assign_agreement"){
		$tmp="zacetek pogodbe";
	}
	elsif($tmp eq "end_agreement"){
		$tmp="konec pogodbe";
	}
	elsif($tmp eq "id_agreement"){
		$tmp="id pogodbe";
	}
	elsif($tmp eq "stara_pogodba"){
		$tmp="stara pogodba";
	}
	elsif($tmp eq "id_staff_enter"){
		$tmp="id vnasalca";
	}
	elsif($tmp eq "id_project"){
		$tmp="id projekta";
	}
	elsif($tmp eq "id_event"){
		$tmp="id dogodka";
	}
	elsif($tmp eq "date_enter"){
		$tmp="datum vnosa";
	}
	elsif($tmp eq "date_agreement"){
		$tmp="datum pogodbe";
	}
	elsif($tmp eq "id_post"){
		$tmp="postna st.";
	}
	elsif($tmp eq "start_date"){
		$tmp="zacetni datum";
	}
	elsif($tmp eq "num_installments"){
		$tmp="st. obrokov";
	}
	elsif($tmp eq "amount"){
		$tmp="celoten znesek";
	}
	elsif($tmp eq "pay_type1"){
		$tmp="vrsta placila - prvi obrok";
	}
	elsif($tmp eq "bank_account1"){
		$tmp="bancni racun - prvi obrok";
	}
	elsif($tmp eq "amount1"){
		$tmp="znesek prvega obroka";
	}
	elsif($tmp eq "pay_type2"){
		$tmp="vrsta placila - ostali obroki";
	}
	elsif($tmp eq "bank_account2"){
		$tmp="banncni racun - ostali obroki";
	}
	elsif($tmp eq "amount2"){
		$tmp="znesek ostalih obrokov";
	}
	elsif($tmp eq "frequency"){
		$tmp="frekvenca";
	}
	elsif($tmp eq "date_1st_amount"){
		$tmp="datum prvega placila";
	}
	elsif($tmp eq "debit_type"){
		$tmp="vrsta placila";
	}
	elsif($tmp eq "id_invoice"){
		$tmp="id invoice";
	}
	elsif($tmp eq "zap_st_dolznika"){
		$tmp="zap st dolznika";
	}
	elsif($tmp eq "create_installments"){
		$tmp="ustvarjeni obroki";
	}
	elsif($tmp eq "id_packet_db"){
		$tmp="id packet db";
	}
	elsif($tmp eq "sifra_banke"){
		$tmp="sifra banke";
	}
	elsif($tmp eq "podaljsanje_pogodbe"){
		$tmp="podaljsanje pogodbe";
	}
	elsif($tmp eq "name_post"){
		$tmp="posta";
	}
	elsif($tmp eq "velik_uporabnik"){
		$tmp="velik uporabnik";
	}
	elsif($tmp eq "series"){
		$tmp="serije";
	}
	elsif($tmp eq "id_creator"){
		$tmp="id ustvarjalca";
	}
	elsif($tmp eq "year"){
		$tmp="leto";
	}
	elsif($tmp eq "date_create"){
		$tmp="datum ustvarjeno";
	}
	elsif($tmp eq "date_delivery"){
		$tmp="datum dostave";
	}
	elsif($tmp eq "closed"){
		$tmp="zaprta";
	}
	elsif($tmp eq "serial_root"){
		$tmp="koren serijske st.";
	}
	elsif($tmp eq "sheets_num_created"){
		$tmp="konec pogodbe";
	}
	elsif($tmp eq "od_stevilke"){
		$tmp="od stevilke";
	}
	elsif($tmp eq "sheets_deleted"){
		$tmp="st izbrisanih";
	}
	elsif($tmp eq "sheets_deleted"){
		$tmp="st izbrisanih";
	}
	elsif($tmp eq "id_vrstica"){
		$tmp="id vrstica";
	}
	elsif($tmp eq "installment_nr"){
		$tmp="st obroka";
	}
	elsif($tmp eq "date_activate"){
		$tmp="datum zapadlosti";
	}
	elsif($tmp eq "date_due"){
		$tmp="datum placila";
	}
	elsif($tmp eq "amount_payed"){
		$tmp="placano";
	}
	elsif($tmp eq "pay_type"){
		$tmp="nacin placila";
	}
	elsif($tmp eq "account_number"){
		$tmp="st racuna";
	}
	elsif($tmp eq "id_bremenitev"){
		$tmp="id bremenitev";
	}
	elsif($tmp eq "id_notice"){
		$tmp="id obvestila";
	}
	elsif($tmp eq "id_bank"){
		$tmp="id banke";
	}
	elsif($tmp eq "bank_name"){
		$tmp="ime banke";
	}
	elsif($tmp eq "bank_tn"){
		$tmp="bank tn";
	}
	elsif($tmp eq "sheets_deleted"){
		$tmp="st izbrisanih";
	}
	elsif($tmp eq "name_event"){
		$tmp="ime dogodka";
	}
	elsif($tmp eq "name_project"){
		$tmp="ime projekta";
	}
	elsif($tmp eq "opis_storitve"){
		$tmp="opis storitve";
	}
	elsif($tmp eq "zap_st_upnika"){
		$tmp="zap st upnika";
	}
	elsif($tmp eq "comment"){
		$tmp="komentar";
	}
	elsif($tmp eq "id_vrstice"){
		$tmp="id vrstice";
	}
	elsif($tmp eq "date"){
		$tmp="datum";
	}
	elsif($tmp eq "alarm_active"){
		$tmp="aktiven alarm";
	}
	elsif($tmp eq "comment_alarm"){
		$tmp="komentar alarma";
	}
	elsif($tmp eq "tip_komentarja"){
		$tmp="tip komentarja";
	}
	elsif($tmp eq "id_phone"){
		$tmp="id telefona";
	}
	elsif($tmp eq "phone_num"){
		$tmp="telefonska stevilka";
	}
	elsif($tmp eq "phone"){
		$tmp="telefon";
	}
	elsif($tmp eq "default_phone"){
		$tmp="primarni telefon";
	}
	elsif($tmp eq "id_prjct_mng"){
		$tmp="id vodje projekta";
	}
	elsif($tmp eq "active_since"){
		$tmp="aktiven od";
	}
	elsif($tmp eq "active_end"){
		$tmp="aktiven do";
	}
	elsif($tmp eq "comment_alarm"){
		$tmp="Komentar alarma";
	}
	elsif($tmp eq "post_name"){
		$tmp="posta";
	}
	elsif($tmp eq "post_name_mail"){
		$tmp="naziv poste posiljanja";
	}
        elsif($tmp eq "znesek"){
                $tmp="celoten znesek pogodbe";
        }

	return $tmp;
}
#prevodi tabel
sub SloTables($){
	
	my $t=shift;

	if($t eq "sfr_donor"){
		return "Donatorji";
	}
	elsif($t eq "sfr_staff"){
		return "Zaposleni";
	}
	elsif($t eq "sfr_agreement"){
		return "Pogodbe";
	}
	elsif($t eq "sheets_series"){
		return "Pole";
	}
	elsif($t eq "sfr_post"){
		return "Poste";
	}
	elsif($t eq "agreement_pay_installment"){
		return "Obroki";
	}
	elsif($t eq "sfr_bank"){
		return "Banke";
	}
	elsif($t eq "sfr_events"){
		return "Dogodki";
	}
	elsif($t eq "sfr_project"){
		return "Projekti";
	}	
	elsif($t eq "sfr_donor_comment"){
		return "Donator - komentarji";
	}
	elsif($t eq "sfr_donor_call"){
		return "Donator - klici";
	}
	elsif($t eq "sfr_donor_phone"){
		return "Donator - telefon";
	}
	elsif($t eq "sfr_staff_comment"){
		return "Zaposleni - komentarji";
	}
	elsif($t eq "sfr_staff_phone"){
		return "Zaposleni - telefon";
	}
	elsif($t eq "sfr_staff_project"){
		return "Zaposleni - projekti";
	}
	elsif($t eq "agreement_notice"){
		return "Pogodba - opomini";
	}
	elsif($t eq "sfr_agreement_comment"){
		return "Pogodba - komentarji";
	}

	
	else{
		return $t;
	}
}
#generiranje menija glede na nastavljene pravice
sub BuildMenu(){
	
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	my $moduli;
	my $sifranti="";
	my $pogodbe="";
	my $placila="";
	my $orodja="";
	my $logged=0;
	my $admin=0;

	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		my $uporabnik = "";
		my $cookie = DntFunkcije::Cookie('id');
		#ce ni cookija se izpise samo meni za prijavo
		if (!defined $cookie){
			$moduli = '<li><a href="#">Uporabniki</a></li>
						<ul>
						<li><a href="/DntPrijava.cgi?rm=prijava">Prijava</a></li>';
			$moduli .= '</ul>
						</ul>';
			return $moduli;
		}
		else{
			my @arr = split(",", $cookie);
			if(defined $arr[0] && defined $arr[1]){
				$sql = "select * FROM uporabniki WHERE id_uporabnik='$arr[0]' AND geslo='$arr[1]'";
				$sth = $dbh->prepare($sql);
				$sth->execute();
	
				if($res = $sth->fetchrow_hashref){
					$logged= $res->{'id_uporabnik'};
					if($res->{'administrator'}==1){
						$admin=1;
					}
				}
				else{
					$moduli = '<li><a href="#">Uporabniki</a></li>
								<ul>
								<li><a href="/DntPrijava.cgi?rm=prijava">Prijava</a></li>';
					$moduli .= '</ul>
								</ul>';
					return $moduli;
				}
			}
			else{
				$moduli = '<li><a href="#">Uporabniki</a></li>
							<ul>
							<li><a href="/DntPrijava.cgi?rm=prijava">Prijava</a></li>';
				$moduli .= '</ul>
							</ul>';
				return $moduli;
				
			}
		
		}
		#generiraj meni za admina ne upošteva nastavljenih pravic
		if($admin == 1){
			$sifranti .= '<li><a href="/DntStart.cgi?rm=Donatorji">Donatorji</a></li>';		
			$sifranti .= ' <li><a href="/DntStart.cgi?rm=Zaposleni">Zaposleni</a></li>';		
			$sifranti .= '<li><a href="/DntStart.cgi?rm=Projekti">Projekti</a></li>';		
			$sifranti .= '<li><a href="/DntStart.cgi?rm=Poste">Poste</a></li>';			
			$sifranti .= '<li><a href="/DntStart.cgi?rm=Dogodki">Dogodki</a></li>';			
			$sifranti .= '<li><a href="/DntStart.cgi?rm=Placila">Placila</a></li>';			
			$sifranti .= '<li><a href="/DntStart.cgi?rm=Banke">Banke</a></li>';			
			$pogodbe .= ' <li><a href="/DntStart.cgi?rm=Pogodbe">Seznam pogodb</a></li>';		
			$pogodbe .= '<li><a href="/DntStart.cgi?rm=Obroki">Generiraj obroke</a></li>';		
			$pogodbe .= '<li><a href="/DntStart.cgi?rm=IzvoziObroke">Izvozi obroke</a></li>';
			$pogodbe .= '<li><a href="/DntStart.cgi?rm=IzvoziRacune">Izvozi racune</a></li>';		
			$pogodbe .= '<li><a href="/DntStart.cgi?rm=Opomini">Seznam opominov</a></li>';			
			$pogodbe .= '<li><a href="/DntPogodbe.cgi?rm=Zahtevki_za_zapiranje">Zahtevki za zapiranje</a></li>';
			$pogodbe .= '<li><a href="/DntStart.cgi?rm=zahtevki">Zahtevki za bremenitve</a></li>';
			$pogodbe .= '<li><a href="/DntStart.cgi?rm=Potrdila">Potrdila o placanih obrokih</a></li>';			
			$pogodbe .= '<li><a href="/DntStart.cgi?rm=Pole">Pole</a></li>';			
			#$placila .= '<li><a href="/DntBranjeDatotek.cgi?rm=IzberiDatoteko"><i>Uvozi datoteke</a></li>';
			$placila .= '<li><a href="/DntStart.cgi?rm=obracun">Obracun</a></li>';	
			$placila .= '<li><a href="/DntBranjeDatotek.cgi?rm=Nepotrjene_datoteke">Nepotrjene datoteke</a></li>';			
			$placila .= '<li><a href="/DntRocniVnosi.cgi?rm=zaporedne_stevilke">Zaporedne stevilke</a></li>';		
			$placila .= '<li><a href="/DntStart.cgi?rm=dbr">Direktne bremenitve</a></li>';	
			$placila .= '<li><a href="/DntRocniVnosi.cgi?rm=Direktne_br_vnos_placil">Rocni vnos</a></li>';
			$orodja .= '<li><a href="/DntBranjeDatotek.cgi?rm=IzberiDatoteko">Uvozi datoteke</a></li>';
			$orodja .= '<li><a href="/DntStart.cgi?rm=IzvozeneDatoteke">Izvozene datoteke</a></li>';	
			$orodja .= '<li><a href="/DntStart.cgi?rm=isci">Isci</a></li>';
			$orodja .= '<li><a href="/DntStart.cgi?rm=opozorila">Opozorila</a></li>';
			$orodja .= '<li><a href="/DntStart.cgi?rm=vzdrzevanje">Vzdrzevanje</a></li>';
			$uporabnik = '<li><a href="/DntStart.cgi?rm=uporabniki">Urejanje uporabnikov</a></li>';
			$uporabnik .= '<li><a href="/DntStart.cgi?rm=uporabnikiLog">Log</a></li>';
			$moduli .= '<li><span><a href="#">Sifranti</a></span><ul>';
			$moduli .= $sifranti;
			$moduli .= '</ul>';		
			$moduli .= '<li><span><a href="#">Pogodbe</a></span><ul>';
			$moduli .= $pogodbe;
			$moduli .= '</ul>';				
			$moduli .= '<li><span><a href="#">Placila</a></span><ul>';
			$moduli .= $placila;
			$moduli .= '</ul>';		
			$moduli .= '<li><span><a href="#">Orodja</a></span><ul>';
			$moduli .= $orodja;
			$moduli .= '</ul>';				
			$moduli .= '<li><a href="#">Uporabniki</a>
						<ul>
						<li><a href="/DntPrijava.cgi?rm=prijava">Prijava</a>';			
			$moduli .= $uporabnik;		
			$moduli .= '</ul></li>
						</ul>';
			return $moduli;
		}
		$sql = "select modul FROM uporabniki_dostop";
		$sql.= " where id_uporabnik='$logged' ORDER BY modul";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		#return $sql;
		while($res = $sth->fetchrow_hashref){
			if(DntFunkcije::trim($res->{'modul'}) eq "11"){
				$sifranti .= '<li><a href="/DntStart.cgi?rm=Donatorji">Donatorji</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "12"){
				$sifranti .= ' <li><a href="/DntStart.cgi?rm=Zaposleni">Zaposleni</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "13"){
				$sifranti .= '<li><a href="/DntStart.cgi?rm=Projekti">Projekti</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "14"){
				$sifranti .= '<li><a href="/DntStart.cgi?rm=Poste">Poste</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "15"){
				$sifranti .= '<li><a href="/DntStart.cgi?rm=Dogodki">Dogodki</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "16"){
				$sifranti .= '<li><a href="/DntStart.cgi?rm=Placila">Placila</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "17"){
				$sifranti .= '<li><a href="/DntStart.cgi?rm=Banke">Banke</a></li>';	
			}
			
			elsif(DntFunkcije::trim($res->{'modul'}) eq "21"){
				$pogodbe .= ' <li><a href="/DntStart.cgi?rm=Pogodbe">Seznam pogodb</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "22"){
				$pogodbe .= '<li><a href="/DntStart.cgi?rm=Obroki">Generiraj obroke</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "23"){
				$pogodbe .= '<li><a href="/DntStart.cgi?rm=IzvoziObroke">Izvozi obroke</a></li>';	
				$pogodbe .= '<li><a href="/DntStart.cgi?rm=IzvoziRacune">Izvozi racune</a></li>';		
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "24"){
				$pogodbe .= '<li><a href="/DntStart.cgi?rm=Opomini">Seznam opominov</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "25"){
				$pogodbe .= '<li><a href="/DntPogodbe.cgi?rm=Zahtevki_za_zapiranje">Zahtevki za zapiranje</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "26"){
				$pogodbe .= '<li><a href="/DntStart.cgi?rm=zahtevki">Zahtevki za bremenitve</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "27"){
				$pogodbe .= '<li><a href="/DntStart.cgi?rm=Potrdila">Potrdila o placanih obrokih</a></li>';	
			}			
			elsif(DntFunkcije::trim($res->{'modul'}) eq "28"){
				$pogodbe .= '<li><a href="/DntStart.cgi?rm=Pole">Pole</a></li>';	
			}
			
			elsif(DntFunkcije::trim($res->{'modul'}) eq "34"){

				$placila .= '<li><a href="/DntStart.cgi?rm=dbr">Direktne bremenitve</a></li>';	
				$placila .= '<li><a href="/DntRocniVnosi.cgi?rm=Direktne_br_vnos_placil">Rocni vnos</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "31"){
				$placila .= '<li><a href="/DntStart.cgi?rm=obracun">Obracun</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "32"){
				$placila .= '<li><a href="/DntBranjeDatotek.cgi?rm=Nepotrjene_datoteke">Nepotrjene datoteke</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "33"){
				$placila .= '<li><a href="/DntRocniVnosi.cgi?rm=zaporedne_stevilke">Zaporedne stevilke</a></li>';	
			}
			
			elsif(DntFunkcije::trim($res->{'modul'}) eq "41"){
				$orodja .= '<li><a href="/DntBranjeDatotek.cgi?rm=IzberiDatoteko">Uvozi datoteke</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "42"){
				$orodja .= '<li><a href="/DntStart.cgi?rm=IzvozeneDatoteke">Izvozene datoteke</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "43"){
				$orodja .= '<li><a href="/DntStart.cgi?rm=isci">Isci</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "44"){
				$orodja .= '<li><a href="/DntStart.cgi?rm=opozorila">Opozorila</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "45"){
				$orodja .= '<li><a href="/DntStart.cgi?rm=vzdrzevanje">Vzdrzevanje</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "51"){
				$uporabnik = '<li><a href="/DntStart.cgi?rm=uporabniki">Urejanje uporabnikov</a></li>';	
			}
			elsif(DntFunkcije::trim($res->{'modul'}) eq "52"){
				$uporabnik = '<li><a href="/DntStart.cgi?rm=uporabnikiLog">Log</a></li>';	
			}
		}
		if($sifranti ne ""){
			$moduli .= '<li><span><a href="#">Sifranti</a></span><ul>';
			$moduli .= $sifranti;
			$moduli .= '</ul>';		
		}
		if($pogodbe ne ""){
			$moduli .= '<li><span><a href="#">Pogodbe</a></span><ul>';
			$moduli .= $pogodbe;
			$moduli .= '</ul>';		
		}
		if($placila ne ""){
			$moduli .= '<li><span><a href="#">Placila</a></span><ul>';
			$moduli .= $placila;
			$moduli .= '</ul>';		
		}
		if($orodja ne ""){
			$moduli .= '<li><span><a href="#">Orodja</a></span><ul>';
			$moduli .= $orodja;
			$moduli .= '</ul>';		
		}
		$moduli .= '<li><a href="#">Uporabniki</a>
					<ul>
					<li><a href="/DntPrijava.cgi?rm=prijava">Prijava</a></li>';
		
		$moduli .= $uporabnik;

		$moduli .= '</ul></li>
					</ul>';
	}
	else{
		return 'Povezava do baze ni uspela';
	}
	
	
	return "$moduli";
}
sub Cookie($){
		
	my $cookie_name=shift;	
	my $cookie_value;
	my @cookies = split(";", $ENV{'HTTP_COOKIE'});
	foreach (@cookies){
		if(DntFunkcije::trim($_) =~ /^$cookie_name=/){
			$cookie_value = $';
		}
	}
	return $cookie_value;
}
sub SetCookie($$$){
	my $name = shift;
	my $value = shift;
	my $expires = shift;
	my $cookie= "Set-Cookie:$name=$value";
	$cookie.="; expires=".$expires;
	$cookie.="\n";
	print $cookie;
	
}
sub AuthenticateSession($$){
	#vrne 0, če uporabnik ni prijavljen, -1 če nima pravic, id_uporabnika drugače
	my $modul = shift;
	my $nivoDostopa = shift;
	
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	my $logged=0;
	my $redirect_url;
	#zabelezi obisk:
	DntFunkcije->log();
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		my $uporabnik;
		my $cookie = DntFunkcije::Cookie('id');

		#ce ni cookija se izpise samo meni za prijavo
		if (!defined $cookie){
			return 0;
		}
		else{
			my @arr = split(",", $cookie);
			if(defined $arr[0] && defined $arr[1]){
				$sql = "select * FROM uporabniki WHERE id_uporabnik='$arr[0]' AND geslo='$arr[1]'";
				$sth = $dbh->prepare($sql);
				$sth->execute();
	
				if($res = $sth->fetchrow_hashref){
					$uporabnik = $res->{'id_uporabnik'};
					if($res->{'administrator'}==1){
						return 1;
					}
				}
				else{
					return 0;
				}
			}
			else{
				return 0;
			}
		}
		$sql = "SELECT * FROM uporabniki_dostop WHERE id_uporabnik='$uporabnik'".
				" AND modul = '$modul'";
		if($nivoDostopa eq 'w'){
			$sql.=" AND nivo_dostopa = '$nivoDostopa'";
		}
		$sth = $dbh->prepare($sql);
		$sth->execute();

		if($res = $sth->fetchrow_hashref){
			return $uporabnik;
		}
		else{
			return -1;
		}
	}
}

sub log(){
	
	my $user_agent = $ENV{'HTTP_USER_AGENT'};
	my $remote_addr = $ENV{'REMOTE_ADDR'};
	my $page = $ENV{'REQUEST_URI'};
	my $time = time;
	my $cookie = $ENV{'HTTP_COOKIE'};
	my $id;
	if ($cookie){
		$cookie = substr ($cookie, index($cookie, 'id=')+3);
	    my @arr = split(",", $cookie);
	    $id = $arr[0];
	}
	else{
		$id=0;
	}
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	
	my $action;
	my $action_id;
	my $action_source;
	
	#if($remote_addr =~ m/rm=dodaj|rm=spremeni/){
		
	#	if($remote_addr =~ m/komId=\d*/){
			
	#	}
	#}
	if($page =~ m/rm=shrani|rm=shrani_pogodbo/){
		if($page =~ m/edb_id=\d*/){
			$action = "u";
			$action_id = $&;
			#edb_id se zapise, prevec
		}
		else{
			$action_source = "d"; 
		}
		if($page =~ m/DntDonatorji.cgi/){
			$action_source = "sfr_donor";
		}
		elsif($page =~ m/DntZaposleni.cgi/){
			$action_source = "sfr_staff";
		}
		else{
			$action_source = "sfr_agreement";
		}
	}
	if(defined $action_id){
    $action_id =~ s/edb_id=//;
	}
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		$sql = "INSERT INTO uporabniki_log ".
					"(id_uporabnik, time, page,".
					" remote_addrs, user_agent,".
					" action, action_id, action_source)".
				"VALUES ".
					"(?, 'now', ?, ".
					" ?, ?, ".
					" ?, ?, ?)";
		$sth = $dbh->prepare($sql);
		$sth->execute($id, $page, $remote_addr, $user_agent, $action, $action_id, $action_source);
	}
	
}
sub TaxNumber{
	my $dbh = DntFunkcije->connectDB;
	my $id = shift;
	if ($dbh) {
		my $sql = "SELECT id_agreement, tax_number, liable_for_tax ".
					" FROM sfr_agreement ".
					" WHERE id_agreement = ? LIMIT 1";
		my $sth = $dbh->prepare($sql);
		$sth->execute($id);
		if(my $res = $sth->fetchrow_hashref){
			if($res->{'liable_for_tax'} == 1){
				return "SI".DntFunkcije::trim($res->{'tax_number'});
			}
			else{
				return DntFunkcije::trim($res->{'tax_number'});
			}
		}
	}
	
}
sub TaxNumberDb{
	my $dbh = shift;
	my $id = shift;
	if ($dbh) {
		my $sql = "SELECT id_agreement, tax_number, liable_for_tax ".
					" FROM sfr_agreement ".
					" WHERE id_agreement = ? LIMIT 1";
		my $sth = $dbh->prepare($sql);
		$sth->execute($id);
		if(my $res = $sth->fetchrow_hashref){
			if($res->{'liable_for_tax'} == 1){
				return "SI".DntFunkcije::trim($res->{'tax_number'});
			}
			else{
				return DntFunkcije::trim($res->{'tax_number'});
			}
		}
	}
	
}
sub ansi_to_437($){
	my $besedilo = shift;
	my $b;
	my @b = split(//, $besedilo);
	$besedilo="";
	foreach (@b){
		if(ord($_) >= 138){
			if($_ eq chr(138)) { $besedilo.=chr(91); } #�(Š)
			elsif($_ eq chr(154)) { $besedilo.=chr(123); } #�(š)
			elsif($_ eq chr(200)) { $besedilo.=chr(94); } #�(Č)
			elsif($_ eq chr(232)) { $besedilo.=chr(126); } #�(č) 	    	
			elsif($_ eq chr(142)) { $besedilo.=chr(64); } #�(Ž)
			elsif($_ eq chr(158)) { $besedilo.=chr(96); } #�(ž)
			
			#A
			elsif($_ eq chr(165)) { $besedilo.="A"; } #�(Ą)
			elsif($_ eq chr(193)) { $besedilo.="A"; } #�(Á)
			elsif($_ eq chr(194)) { $besedilo.="A"; } #�(Â)
			elsif($_ eq chr(195)) { $besedilo.="A"; } #�(Ă)
			elsif($_ eq chr(196)) { $besedilo.="A"; } #�(Ä)
			#a
			elsif($_ eq chr(185)) { $besedilo.="a"; } #�(ą)
			elsif($_ eq chr(225)) { $besedilo.="a"; } #�(á)
			elsif($_ eq chr(226)) { $besedilo.="a"; } #�(â)
			elsif($_ eq chr(227)) { $besedilo.="a"; } #�(ă)
			elsif($_ eq chr(228)) { $besedilo.="a"; } #�(ä)
			
			#C
			elsif($_ eq chr(198)) { $besedilo.="C"; } #�(Ć)
			elsif($_ eq chr(199)) { $besedilo.="C"; } #�(Ç)
			elsif($_ eq chr(200)) { $besedilo.="C"; } #�(Č)
			#c
			elsif($_ eq chr(230)) { $besedilo.="c"; } #�(ć)
			elsif($_ eq chr(231)) { $besedilo.="c"; } #�(ç)
			elsif($_ eq chr(232)) { $besedilo.="c"; } #�(č)
			
			#D
			elsif($_ eq chr(207)) { $besedilo.="D"; } #�(Ď)
			elsif($_ eq chr(208)) { $besedilo.="D"; } #�(Đ)
			#d
			elsif($_ eq chr(239)) { $besedilo.="d"; } #�(ď)
			elsif($_ eq chr(240)) { $besedilo.="d"; } #�(đ)
			
			#E
			elsif($_ eq chr(201)) { $besedilo.="E"; } #�(É)
			elsif($_ eq chr(202)) { $besedilo.="E"; } #�(Ę)
			elsif($_ eq chr(203)) { $besedilo.="E"; } #�(Ë)
			elsif($_ eq chr(204)) { $besedilo.="E"; } #�(Ě)
			#e
			elsif($_ eq chr(233)) { $besedilo.="e"; } #�(é)
			elsif($_ eq chr(234)) { $besedilo.="e"; } #�(ę)
			elsif($_ eq chr(235)) { $besedilo.="e"; } #�(ë)
			elsif($_ eq chr(236)) { $besedilo.="e"; } #�(ě)
			
			#I
			elsif($_ eq chr(205)) { $besedilo.="I"; } #�(Í)
			elsif($_ eq chr(206)) { $besedilo.="I"; } #�(Î)
			#i
			elsif($_ eq chr(237)) { $besedilo.="i"; } #�(í)
			elsif($_ eq chr(238)) { $besedilo.="i"; } #�(î)
			
			#N
			elsif($_ eq chr(209)) { $besedilo.="N"; } #�(Ń)
			elsif($_ eq chr(210)) { $besedilo.="N"; } #�(Ň)
			#n
			elsif($_ eq chr(241)) { $besedilo.="n"; } #�(ń)
			elsif($_ eq chr(242)) { $besedilo.="n"; } #�(ň)
			
			#O
			elsif($_ eq chr(211)) { $besedilo.="O"; } #�(Ó)
			elsif($_ eq chr(212)) { $besedilo.="O"; } #�(Ô)
			elsif($_ eq chr(213)) { $besedilo.="O"; } #�(Ő)
			elsif($_ eq chr(214)) { $besedilo.="O"; } #�(Ö)
			#o
			elsif($_ eq chr(243)) { $besedilo.="o"; } #�(ó)
			elsif($_ eq chr(244)) { $besedilo.="o";  } #�(ô)
			elsif($_ eq chr(245)) { $besedilo.="o";  } #�(ő)
			elsif($_ eq chr(246)) { $besedilo.="o";  } #�(ö)
			
			#R
			elsif($_ eq chr(192)) { $besedilo.="R";  } #�(Ŕ)
			elsif($_ eq chr(216)) { $besedilo.="R";  } #�(Ř)
			#r
			elsif($_ eq chr(224)) { $besedilo.="r";  } #�(ŕ)
			elsif($_ eq chr(248)) { $besedilo.="r";  } #�(ř)
			
			
			#S
			elsif($_ eq chr(140)) { $besedilo.="S"; } #�(Ś)
			elsif($_ eq chr(170)) { $besedilo.="S"; } #�(Ş)
			#s
			elsif($_ eq chr(156)) { $besedilo.="s"; } #�(ś)
			elsif($_ eq chr(186)) { $besedilo.="s"; } #�(ş)
			
			#T
			elsif($_ eq chr(141)) { $besedilo.="T"; } #�(Ť)
			elsif($_ eq chr(222)) { $besedilo.="T"; } #�(Ţ)
			#t
			elsif($_ eq chr(157)) { $besedilo.="t"; } #�(ť)
			elsif($_ eq chr(254)) { $besedilo.="t"; } #�(ţ)
			
			#U
			elsif($_ eq chr(217)) { $besedilo.="U"; } #�(Ů)
			elsif($_ eq chr(218)) { $besedilo.="U"; } #�(Ú)
			elsif($_ eq chr(219)) { $besedilo.="U"; } #�(Ű)
			elsif($_ eq chr(220)) { $besedilo.="U"; } #�(Ü)
			#u
			elsif($_ eq chr(249)) { $besedilo.="u"; } #�(ů)
			elsif($_ eq chr(250)) { $besedilo.="u"; } #�(ú)
			elsif($_ eq chr(251)) { $besedilo.="u"; } #�(ű)
			elsif($_ eq chr(252)) { $besedilo.="u"; } #�(ü)
			
			#Y
			elsif($_ eq chr(221)) { $besedilo.="Y"; } #�(Ý)
			
			#Z
			elsif($_ eq chr(143)) { $besedilo.="Z"; } #�(Ź)
			elsif($_ eq chr(175)) { $besedilo.="Z"; } #�(Ż)
			#z
			elsif($_ eq chr(159)) { $besedilo.="z"; } #�(ź)
			elsif($_ eq chr(191)) { $besedilo.="z"; } #�(ż)
			
			#L
			elsif($_ eq chr(163)) { $besedilo.="L"; } #�(Ł)
			elsif($_ eq chr(188)) { $besedilo.="L"; } #�(Ľ)
			elsif($_ eq chr(197)) { $besedilo.="L"; } #�(Ĺ)
			#l
			elsif($_ eq chr(179)) { $besedilo.="l"; } #�(ł)
			elsif($_ eq chr(190)) { $besedilo.="l"; } #�(ľ)
			elsif($_ eq chr(229)) { $besedilo.="l"; } #�(ĺ)
			
			#u
			elsif($_ eq chr(181)) { $besedilo.="u"; } #�(µ)
			
			elsif($_ eq chr(139)) { $besedilo.=chr(226).chr(128); } #�(�)
			elsif($_ eq chr(161)) { $besedilo.=chr(203).chr(135); } #�(ˇ)
			elsif($_ eq chr(162)) { $besedilo.=chr(203).chr(152); } #�(˘)
			elsif($_ eq chr(164)) { $besedilo.=chr(194).chr(164); } #�(¤)
			elsif($_ eq chr(166)) { $besedilo.=chr(194).chr(166); } #�(¦)
			elsif($_ eq chr(167)) { $besedilo.=chr(194).chr(167); } #�(§)
			elsif($_ eq chr(168)) { $besedilo.=chr(194).chr(168); } #�(¨)
			elsif($_ eq chr(169)) { $besedilo.=chr(194).chr(169); } #�(©)			
			elsif($_ eq chr(171)) { $besedilo.=chr(194).chr(171); } #�(«)
			elsif($_ eq chr(172)) { $besedilo.=chr(194).chr(172); } #�(¬)
			elsif($_ eq chr(173)) { $besedilo.=chr(194).chr(173); } #�(­)
			elsif($_ eq chr(174)) { $besedilo.=chr(194).chr(174); } #�(®)	
			#elsif($_ eq chr(176)) { $besedilo.=chr(194).chr(176); } #�(°)
			elsif($_ eq chr(177)) { $besedilo.=chr(194).chr(177); } #�(±)
			elsif($_ eq chr(178)) { $besedilo.=chr(203).chr(155); } #�(˛)			
			elsif($_ eq chr(180)) { $besedilo.=chr(194).chr(180); } #�(´)			
			elsif($_ eq chr(182)) { $besedilo.=chr(194).chr(182); } #�(¶)
			elsif($_ eq chr(183)) { $besedilo.=chr(194).chr(183); } #�(·)
			elsif($_ eq chr(184)) { $besedilo.=chr(194).chr(184); } #�(¸)			
			elsif($_ eq chr(187)) { $besedilo.=chr(194).chr(187); } #�(»)
			elsif($_ eq chr(189)) { $besedilo.=chr(203).chr(157); } #�(˝)			
			elsif($_ eq chr(215)) { $besedilo.=chr(195).chr(151); } #�(×)	
			elsif($_ eq chr(223)) { $besedilo.=chr(195).chr(159); } #�(ß)
			elsif($_ eq chr(247)) { $besedilo.=chr(195).chr(183); } #�(÷)
			elsif($_ eq chr(255)) { $besedilo.=chr(203).chr(153); } #�(˙)
			else{ $besedilo.="_"; }
		}
		else{ $besedilo.=$_; }
	}
	my $c180a="'"; my $c184a="''"; #´
	my $c180ab='"'; my $c184ab='"'; #´
	$besedilo =~ s/$c180a/$c184a/g; #´(Â´)
	$besedilo =~ s/$c180ab/$c184ab/g; #´(Â´)
	
	return $besedilo;
	
}
sub ansi_to_utf($){
	my $besedilo = shift;
	my $b;
	my @b = split(//, $besedilo);
	$besedilo="";
	
	foreach (@b){
		if(ord($_) >= 138){
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
			
			}
		else{ $besedilo.=$_; }

	}

	my $c180a="'"; my $c184a="''"; #´
	my $c180ab='"'; my $c184ab='"'; #´
	$besedilo =~ s/$c180a/$c184a/g; #´(Â´)
	$besedilo =~ s/$c180ab/$c184ab/g; #´(Â´)
	
	return $besedilo;
}

sub output_form($$$$){
	my $q = shift;
	my $csv = shift;
	my $name = shift;
	my $index = shift;
	my $form;
	(my $datum, my $cas) = DntFunkcije->time_stamp();
	my $date = substr($datum,8,2).".".substr($datum,5,2).".".substr($datum,0,4);
	my $fn = "";
	if($name eq "obroki"){
		$fn = "OB"."_".$datum.".csv";
	}
	else{
		$fn = substr(uc($name), 0, 3)."_".$datum.".csv";
	}
	$form =  $q->start_form(-method=>'post',
							-enctype => 'multipart/form-data',
						   -action=>'/outputHandler.cgi?src=obracun',
						  );
	$csv =~ s/\'//g;
	$form .= '<input type = "hidden" value = \''.$csv.'\' name = "content" />';
	$form .= $q->hidden(-value => $index,
					   -name => 'index',
					   -id => 'indx');
	$form .= $q->hidden(-value => $name,
					-name => 'izvor');
	if($name ne 'iskanje'){
		
		$form .= $q->checkbox(-name=>'datum_chk',
					-checked => 'checked',
					-value => 'ON',
					-label => "zapisi datum: ",
					-onclick => "javascript:click_date(this);");
		$form .= $q->textfield(-name=>'datum',
					-id => 'datum_izvoza',
                    -value=>$date,
                    -maxlength=>80,
					);
		

		$form .= "<br /><br />";
	}
	$form .= $q->textfield(-value => $fn,
					   -name => 'filename');
	$form .= $q->submit(-name=>'izvoz', -value=>'izvoz');
	
			if($name eq 'obroki'){
		
		$form .= $q->checkbox(-name=>'poloznice',
					-value => 'ON',
					-label => "",
					-style => "display:none",
					);
		
		}
	$form .= $q->endform();
	return $form;
}

sub date_sl_to_db($){
	my $date = shift;
	return substr($date, 6, 4)."-".substr($date, 3, 2)."-".
				   substr($date, 0, 2);
}
