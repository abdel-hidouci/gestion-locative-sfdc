public with sharing class CloneUtility {

    /* ===== INPUT FLOW ===== */
    public class CloneDepensesRequest {
        @InvocableVariable(required=true label='Id Bien locatif')
        public Id bienLocatifId;

        @InvocableVariable(required=true label='Année à clôner')
        public String sourceYear;

        @InvocableVariable(required=true label='Nouvelle année')
        public String targetYear;
    }

    /* ===== OUTPUT FLOW ===== */
    public class CloneDepensesResult {
        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String message;
    }

    /* ===== INVOCABLE METHOD ===== */
    @InvocableMethod(
        label='Clôner les dépenses'
        description='Clone les dépenses d une année vers une autre'
    )
    public static List<CloneDepensesResult> cloneDepenses(
        List<CloneDepensesRequest> requests
    ) {
        List<CloneDepensesResult> results = new List<CloneDepensesResult>();

        for (CloneDepensesRequest req : requests) {
            CloneDepensesResult result = new CloneDepensesResult();

            try {
                Integer sourceYear = Integer.valueOf(req.sourceYear);
                Integer targetYear = Integer.valueOf(req.targetYear);

                /* 1️⃣ Récupération des dépenses */
                List<Depense__c> depensesSource = [
                    SELECT Id, Date_Depense__c, Statut__c, Bien_Locatif__c,
                           Description__c, Nature__c, Frequence__c,
                           Recuperable__c, Montant__c, Montant_Assurance_Pret__c, Montant_Capital__c, Montant_Charge_Copro__c, Montant_Fonds_Travaux_loi_Alur__c, Montant_Interets__c, RecordTypeId 
                    FROM Depense__c
                    WHERE Bien_Locatif__c = :req.bienLocatifId
                    AND CALENDAR_YEAR(Date_Depense__c) = :sourceYear
                ];

                if (depensesSource.isEmpty()) {
                    result.success = false;
                    result.message =
                        'Aucune dépense trouvée pour l\'année ' + sourceYear + '.';
                    results.add(result);
                    continue;
                }

                /* 2️⃣ Duplication */
                List<Depense__c> depensesACreer = new List<Depense__c>();

                for (Depense__c dep : depensesSource) {
                    Depense__c cloneDep = dep.clone(false, true, false, false);

                    Date oldDate = dep.Date_Depense__c;
                    Date newDate = Date.newInstance(
                        targetYear,
                        oldDate.month(),
                        oldDate.day()
                    );

                    cloneDep.Date_Depense__c = newDate;
                    cloneDep.Statut__c = 'A payer';

                    depensesACreer.add(cloneDep);
                }

                insert depensesACreer;

                /* 3️⃣ Succès */
                result.success = true;
                result.message =
                    depensesACreer.size() +
                    ' dépense(s) clonée(s) avec succès de ' +
                    sourceYear + ' vers ' + targetYear + '.';

            } catch (Exception e) {
                result.success = false;
                result.message =
                    'Erreur lors du clonage des dépenses : ' +
                    e.getMessage();
            }

            results.add(result);
        }

        return results;
    }
}