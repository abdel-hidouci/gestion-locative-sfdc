/**
 * @description Trigger pour les baux
 * @author Manus
 * @date Avril 2025
 */
trigger BailTrigger on Bail__c (after insert, after update, after delete) {
    // Traitement après insertion, mise à jour ou suppression
    if (Trigger.isAfter) {
        Set<Id> bienIds = new Set<Id>();
        
        // Collecter les IDs des biens concernés
        if (Trigger.isInsert || Trigger.isUpdate) {
            for (Bail__c bail : Trigger.new) {
                if (bail.Bien_Locatif__c != null) {
                    bienIds.add(bail.Bien_Locatif__c);
                }
            }
        } else if (Trigger.isDelete) {
            for (Bail__c bail : Trigger.old) {
                bienIds.add(bail.Bien_Locatif__c);
            }
        }
        
        // Mettre à jour le statut des biens concernés
        if (!bienIds.isEmpty()) {
            for (Id bienId : bienIds) {
                try {
                    BailService.mettreAJourStatutBien(bienId);
                } catch (Exception e) {
                    System.debug('Erreur lors de la mise à jour du statut du bien ' + bienId + ' : ' + e.getMessage());
                }
            }
        }
        
        // Vérifier les fins de bail pour les mises à jour
        if (Trigger.isUpdate) {
            for (Bail__c bail : Trigger.new) {
                Bail__c oldBail = Trigger.oldMap.get(bail.Id);
                
                // Si la date de fin a été modifiée et que le bail est actif
                if (bail.Date_Fin__c != oldBail.Date_Fin__c && bail.Statut__c == 'Actif') {
                    // Calculer le nombre de jours avant l'échéance
                    Integer joursAvantEcheance = bail.Date_Fin__c.daysBetween(Date.today());
                    
                    // Si l'échéance est dans moins de 90 jours, envoyer une alerte
                    if (joursAvantEcheance <= 90 && joursAvantEcheance > 0) {
                        try {
                            BailService.envoyerAlertesFinBail(joursAvantEcheance);
                        } catch (Exception e) {
                            System.debug('Erreur lors de l\'envoi de l\'alerte de fin de bail pour ' + bail.Id + ' : ' + e.getMessage());
                        }
                    }
                }
            }
        }
    }
}
