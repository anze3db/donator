#!c:/Perl/bin/perl.exe
package Pogodba;
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

sub id_donor {
    my $self = shift;
    $self->{id_donor} = shift if @_;
    return $self->{id_donor};
}

sub prefix {
    my $self = shift;
    $self->{prefix} = shift if @_;
    return $self->{prefix};
}
sub first_name {
    my $self = shift;
    $self->{first_name} = shift if @_;
    return $self->{first_name};
}

sub scnd_name {
    my $self = shift;
    $self->{scnd_name} = shift if @_;
    return $self->{scnd_name};
}

sub name_company {
    my $self = shift;
    $self->{name_company} = shift if @_;
    return $self->{name_company};
}

sub street {
    my $self = shift;
    $self->{street} = shift if @_;
    return $self->{street};
}

sub street_number {
    my $self = shift;
    $self->{street_number} = shift if @_;
    return $self->{street_number};
}

sub post {
    my $self = shift;
    $self->{post} = shift if @_;
    return $self->{post};
}

sub obrok_sprememba_vrste_bremenitve($$){
    #preveri ce za izbrano pogodbo in obrok ze obstaja
    #zapis za sporocilo v zbirni center o spremembi.
    #'1' Ze obstaja, in se ni bilo poslano na ZC se obvestilo popravi
    #'0' Ne obstaja
    #'2' Ze obstaja in je bilo poslano na ZC - tudi se bo naredilo nov
    #'3' Ze obstaja, datum za posiljanje je prekratko zato se ne bo poslalo
        #ni vec pravocasno da se poslje
    my $id_agreement = shift;
    my $installment_nr = shift;
    
    my $prijavi_odjavi;
    my $poslano;
    my $uspesno_potrjeno;
    my $dbh;	
	my $nasel_zapis;
    my $res;
    my $sql_vprasaj;
    my $sth;
    
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
			$nasel_zapis = "1";
            $prijavi_odjavi = $res->{'prijavi_odjavi'};
            $poslano = $res->{'poslano'};
            $uspesno_potrjeno = $res->{'uspesno_potrjeno'};
            
        }
    }
}

sub prestavi_obrok($$){
    my $stevilka_obroka = shift;
    my $pogodba = shift;
    
    #if ($pogodba eq $self->{id_agreement}){
    #    
    #}
    #else {
    #    
    #}
}

sub citaj_pogodbo(){
    my $self = shift;
	my $id_agreement;
	my $id_donor;
    my $dbh;	
	my $nasel_zapis;
    my $res;
    my $sql_vprasaj;
    my $sth;
	$id_agreement = $self->{id_agreement};
    #$self->{first_name}='Tincek';
    $dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
        $sql_vprasaj = "SELECT first_name, scnd_name, ".
				" street, street_number, id_post FROM sfr_agreement ".
				" WHERE id_agreement = ? ";
		$sth = $dbh->prepare($sql_vprasaj);
		$sth->execute($id_agreement);
		$nasel_zapis = "0";
        if($res = $sth->fetchrow_hashref) {
			$nasel_zapis = "1";
            $self->{first_name} = $res->{'first_name'};
            $self->{scnd_name} = $res->{'scnd_name'};
			$self->{name_company} = $res->{'name_company'};
			$self->{street} = $res->{'street'};
			$self->{street_number} = $res->{'street_number'};
			$self->{post} = $res->{'id_post'};
			
		}
#        
#        $sth->finish;
#        $dbh->disconnect();
   }
}

return 1;
