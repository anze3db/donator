-- Mail pog: e-mail naslov, vnesen na pogodbi
ALTER TABLE sfr_agreement ADD COLUMN IF NOT EXISTS mail_pog varchar(255);
