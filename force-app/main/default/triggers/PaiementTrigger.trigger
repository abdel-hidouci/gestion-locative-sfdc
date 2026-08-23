/**
 * @description Trigger pour les paiements
 * @author Manus
 * @date Avril 2025
 */
trigger PaiementTrigger on Paiement__c (after insert, after update) {
    // Traitement après insertion ou mise à jour
    if (Trigger.isAfter) {
        // Génération automatique de quittance lorsqu'un paiement passe à "Encaissé"
        if (Trigger.isUpdate) {
            List<Paiement__c> paiementsEncaisses = new List<Paiement__c>();
            
            for (Paiement__c paiement : Trigger.new) {
                Paiement__c oldPaiement = Trigger.oldMap.get(paiement.Id);
                
                // Vérifier si le statut est passé à "Encaissé"
                if (paiement.Statut__c == 'Encaissé' && oldPaiement.Statut__c != 'Encaissé' && !paiement.Quittance_Generee__c) {
                    paiementsEncaisses.add(paiement);
                }
            }
            
            // Générer les quittances pour les paiements encaissés
            if (!paiementsEncaisses.isEmpty()) {
                for (Paiement__c paiement : paiementsEncaisses) {
                    try {
                        QuittanceService.genererQuittance(paiement.Id);
                    } catch (Exception e) {
                        paiement.addError('Erreur lors de la génération de la quittance : ' + e.getMessage());
                    }
                }
            }
        }
        
        // Mise à jour du rendement pour les paiements insérés ou mis à jour
        Set<Id> bienIds = new Set<Id>();
        Set<String> annees = new Set<String>();
        
        for (Paiement__c paiement : Trigger.new) {
            // Récupérer l'ID du bien et l'année concernée
            if (paiement.Bail__c != null) {
                // Récupérer l'ID du bien via une requête SOQL
                List<Bail__c> baux = [SELECT Bien_Locatif__c FROM Bail__c WHERE Id = :paiement.Bail__c LIMIT 1];
                if (!baux.isEmpty()) {
                    bienIds.add(baux[0].Bien_Locatif__c);
                    annees.add(paiement.Annee_Concernee__c);
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
