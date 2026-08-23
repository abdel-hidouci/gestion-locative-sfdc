/**
 * @description Trigger pour les dépenses
 * @author Manus
 * @date Avril 2025
 */
trigger DepenseTrigger on Depense__c (after insert, after update, after delete) {
    // Traitement après insertion, mise à jour ou suppression
    if (Trigger.isAfter) {
        Set<Id> bienIds = new Set<Id>();
        Set<String> annees = new Set<String>();
        
        // Collecter les IDs des biens et les années concernées
        if (Trigger.isInsert || Trigger.isUpdate) {
            for (Depense__c depense : Trigger.new) {
                if (depense.Bien_Locatif__c != null) {
                    bienIds.add(depense.Bien_Locatif__c);
                    annees.add(depense.Annee_Fiscale__c);
                }
            }
        } else if (Trigger.isDelete) {
            for (Depense__c depense : Trigger.old) {
                if (depense.Bien_Locatif__c != null) {
                    bienIds.add(depense.Bien_Locatif__c);
                    annees.add(depense.Annee_Fiscale__c);
                }
            }
        }
        
        // Mettre à jour le rendement pour chaque bien et chaque année
        if (!bienIds.isEmpty() && !annees.isEmpty()) {
            for (Id bienId : bienIds) {
                for (String annee : annees) {
                    try {
                        RendementService.calculerRendement(bienId, annee);
                    } catch (Exception e) {
                        System.debug('Erreur lors du calcul du rendement pour le bien ' + bienId + ' et l\'année ' + annee + ' : ' + e.getMessage());
                    }
                }
            }
        }
    }
}