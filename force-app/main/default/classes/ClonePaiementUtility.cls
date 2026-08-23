public with sharing class ClonePaiementUtility {

    /* ===== INPUT FLOW ===== */
    public class ClonepaiementsRequest {
        @InvocableVariable(required=true label='Id bail locatif')
        public Id bailLocatifId;

        @InvocableVariable(required=true label='Année à clôner')
        public String sourceYear;

        @InvocableVariable(required=true label='Nouvelle année')
        public String targetYear;
    }

    /* ===== OUTPUT FLOW ===== */
    public class ClonePaiementsResult {
        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String message;
    }

    /* ===== INVOCABLE METHOD ===== */
    @InvocableMethod(
        label='Clôner les paiements'
        description='Clone les paiements d une année vers une autre'
    )
    public static List<ClonePaiementsResult> clonePaiements(
        List<ClonepaiementsRequest> requests
    ) {
        List<ClonePaiementsResult> results = new List<ClonePaiementsResult>();

        for (ClonepaiementsRequest req : requests) {
            ClonePaiementsResult result = new ClonePaiementsResult();

            try {
                Integer sourceYear = Integer.valueOf(req.sourceYear);
                Integer targetYear = Integer.valueOf(req.targetYear);

                /* 1️⃣ Récupération des dépenses */
                List<Paiement__c> paiementsSource = [
                    SELECT Id, Date_Encaissement__c, Date_Paiement__c, Statut__c, Bail__c, Locataire__c, 
                           Montant_Charges__c, Montant_Loyer__c, Moyen_Paiement__c,Notes__c, Periode_Debut__c, Periode_Fin__c, Quittance_Generee__c, Reference_Paiement__c
                    FROM Paiement__c
                    WHERE Bail__c = :req.bailLocatifId
                    AND CALENDAR_YEAR(Date_Paiement__c) = :sourceYear
                ];

                if (paiementsSource.isEmpty()) {
                    result.success = false;
                    result.message =
                        'Aucune paie trouvée pour l\'année ' + sourceYear + '.';
                    results.add(result);
                    continue;
                }

                /* 2️⃣ Duplication */
                List<Paiement__c> paiementsACreer = new List<Paiement__c>();

                for (Paiement__c paie : paiementsSource) {
                    Paiement__c clonePaie = paie.clone(false, true, false, false);

                    Date oldDate = paie.Date_Paiement__c;
                    Date newDate = Date.newInstance(
                        targetYear,
                        oldDate.month(),
                        oldDate.day()
                    );
                    
                    Date oldStartDate = paie.Periode_Debut__c;
                    Date newStartDate = Date.newInstance(
                        targetYear,
                        oldStartDate.month(),
                        oldStartDate.day()
                    );
                    
                    Date oldEndDate = paie.Periode_Fin__c;
                    Date newEndDate = Date.newInstance(
                        targetYear,
                        oldEndDate.month(),
                        oldEndDate.day()
                    );

                    clonePaie.Date_Paiement__c = newDate;
                    clonePaie.Date_Encaissement__c = newDate;
                    clonePaie.Periode_Debut__c = newStartDate;
                    clonePaie.Periode_Fin__c = newEndDate;
                    clonePaie.Statut__c = 'A payer';

                    paiementsACreer.add(clonePaie);
                }

                insert paiementsACreer;

                /* 3️⃣ Succès */
                result.success = true;
                result.message =
                    paiementsACreer.size() +
                    ' paiement(s) clonée(s) avec succès de ' +
                    sourceYear + ' vers ' + targetYear + '.';

            } catch (Exception e) {
                result.success = false;
                result.message =
                    'Erreur lors du clonage des paiements : ' +
                    e.getMessage();
            }

            results.add(result);
        }

        return results;
    }
}