// Récupérer la dépense source
Depense__c depSource = [SELECT ID, Bien_Locatif__c, Description__c, Frequence__c, RecordTypeId, 
                        Nature__c, Recuperable__c, Montant__c, Statut__c, Date_Depense__c 
                        FROM Depense__c 
                        WHERE ID = 'a05WU00000PyIouYAF'];

// Liste pour stocker les nouvelles dépenses
List<Depense__c> depensesACreer = new List<Depense__c>();

// Date de début et fin
Date dateDebut = Date.newInstance(2025, 5, 25);
Date dateFin = Date.newInstance(2025, 12, 25);

// Cloner la dépense pour chaque mois
while (dateDebut <= dateFin) {
    Depense__c nouvelleDep = depSource.clone(false, true, false, false);
    nouvelleDep.Date_Depense__c = dateDebut;
    nouvelleDep.Statut__c = 'A payer';
    depensesACreer.add(nouvelleDep);
    
    // Passer au mois suivant
    dateDebut = dateDebut.addMonths(1);
}

// Insérer les dépenses clonées
if (!depensesACreer.isEmpty()) {
    insert depensesACreer;
}

