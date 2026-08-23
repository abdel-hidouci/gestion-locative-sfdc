Paiement__c pai = [Select Id, Bail__c, Date_Encaissement__c, Date_Paiement__c, Locataire__c, Montant_Charges__c, Montant_Loyer__c, Moyen_Paiement__c, Notes__c, Periode_Debut__c, Periode_Fin__c, Quittance_Generee__c, Reference_Paiement__c, Statut__c From Paiement__c 
Where Id = 'a07WU00000PDkxLYAT'];
List<Paiement__c> newPaiements = new List<Paiement__c>();
Date startDate = Date.newInstance(2025, 4, 1);
Date endDate = Date.newInstance(2025, 12, 31);

Map<Integer, String> monthMap = new Map<Integer, String>{
1 => 'Janvier', 2 => 'Février', 3 => 'Mars', 4 => 'Avril',
5 => 'Mai', 6 => 'Juin', 7 => 'Juillet', 8 => 'Août',
9 => 'Septembre', 10 => 'Octobre', 11 => 'Novembre', 12 => 'Décembre'
};

Date currentDate = startDate;
while (currentDate <= endDate) {
Paiement__c newPai = pai.clone(false, true, false, false);

// Set the dates
newPai.Periode_Debut__c = currentDate;
newPai.Date_Encaissement__c = currentDate;
newPai.Date_Paiement__c = currentDate;

// Set the end date of the month
Integer lastDayOfMonth = Date.daysInMonth(currentDate.year(), currentDate.month());
newPai.Periode_Fin__c = Date.newInstance(currentDate.year(), currentDate.month(), lastDayOfMonth);

// Set status
newPai.Statut__c = 'Encaissé';

newPaiements.add(newPai);

// Move to next month
currentDate = currentDate.addMonths(1);
}

insert newPaiements;
