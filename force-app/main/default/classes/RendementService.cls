/**
 * @description Classe utilitaire pour le calcul du rendement locatif
 * @author Manus
 * @date Avril 2025
 */
public with sharing class RendementService {
    
    /**
     * Calcule le rendement locatif pour un bien et une année donnés
     * @param bienId ID du bien locatif
     * @param annee Année concernée
     * @return ID de l'enregistrement de rendement créé ou mis à jour
     */
    public static Id calculerRendement(Id bienId, String annee) {
        // Récupération du bien
        Bien_Locatif__c bien = [
            SELECT Id, Prix_Acquisition__c
            FROM Bien_Locatif__c 
            WHERE Id = :bienId
        ];
        
        // Vérification que le bien a un prix d'acquisition
        if (bien.Prix_Acquisition__c == null || bien.Prix_Acquisition__c == 0) {
            throw new RendementServiceException('Le bien doit avoir un prix d\'acquisition pour calculer le rendement.');
        }
        
        // Calcul des totaux des loyers et charges perçus
        AggregateResult paiementsResult = [
            SELECT SUM(Montant_Loyer__c) totalLoyers, SUM(Montant_Charges__c) totalCharges
            FROM Paiement__c
            WHERE Bail__r.Bien_Locatif__c = :bienId
            AND Annee_Concernee__c = :annee
            AND Statut__c = 'Encaissé'
        ];
        
        Decimal totalLoyers = (Decimal)paiementsResult.get('totalLoyers');
        Decimal totalCharges = (Decimal)paiementsResult.get('totalCharges');
        
        // Si aucun paiement n'a été trouvé, initialiser à 0
        totalLoyers = totalLoyers != null ? totalLoyers : 0;
        totalCharges = totalCharges != null ? totalCharges : 0;
        
        // Calcul du total des dépenses
        AggregateResult depensesResult = [
            SELECT SUM(Montant__c) totalDepenses
            FROM Depense__c
            WHERE Bien_Locatif__c = :bienId
            AND Annee_Fiscale__c = :annee
        ];
        
        Decimal totalDepenses = (Decimal)depensesResult.get('totalDepenses');
        totalDepenses = totalDepenses != null ? totalDepenses : 0;
        
        // Recherche d'un enregistrement de rendement existant
        List<Rendement__c> rendements = [
            SELECT Id
            FROM Rendement__c
            WHERE Bien_Locatif__c = :bienId
            AND Annee__c = :annee
        ];
        
        Rendement__c rendement;
        
        if (!rendements.isEmpty()) {
            // Mise à jour de l'enregistrement existant
            rendement = rendements[0];
            rendement.Total_Loyers__c = totalLoyers;
            rendement.Total_Charges_Percues__c = totalCharges;
            rendement.Total_Depenses__c = totalDepenses;
            update rendement;
        } else {
            // Création d'un nouvel enregistrement
            rendement = new Rendement__c(
                Bien_Locatif__c = bienId,
                Annee__c = annee,
                Total_Loyers__c = totalLoyers,
                Total_Charges_Percues__c = totalCharges,
                Total_Depenses__c = totalDepenses
            );
            insert rendement;
        }
        
        return rendement.Id;
    }
    
    /**
     * Calcule le rendement locatif pour tous les biens pour une année donnée
     * @param annee Année concernée
     * @return Nombre d'enregistrements de rendement créés ou mis à jour
     */
    public static List<Id> calculerRendementTousBiens(String annee) {
        // Récupération de tous les biens
        List<Bien_Locatif__c> biens = [
            SELECT Id
            FROM Bien_Locatif__c
            WHERE Prix_Acquisition__c > 0
        ];
        
        Integer compteur = 0;
        List<Id> rendementIds = new List<Id>();
        for (Bien_Locatif__c bien : biens) {
            try {
                rendementIds.add(calculerRendement(bien.Id, annee));
                compteur++;
            } catch (Exception e) {
                // Gestion des erreurs pour continuer le traitement des autres biens
                System.debug('Erreur lors du calcul du rendement pour le bien ' + bien.Id + ' : ' + e.getMessage());
            }
        }
        
        return rendementIds;
    }
    
    /**
     * @description Récupère la liste des rendements
     * @return Liste des rendements avec leurs détails
     */
    @AuraEnabled(cacheable=true)
    public static List<RendementWrapper> getRendements() {
        List<RendementWrapper> rendements = new List<RendementWrapper>();
        
        List<Rendement__c> rendementsRecords = [
            SELECT Id, 
                   Bien_Locatif__r.Name,
                   Annee__c,
                   Total_Loyers__c,
                   Total_Charges_Percues__c,
                   Total_Depenses__c,
                   Rendement_Brut__c,
                   Rendement_Net__c
            FROM Rendement__c
            ORDER BY Bien_Locatif__r.Name, Annee__c DESC
        ];
        
        for(Rendement__c r : rendementsRecords) {
            rendements.add(new RendementWrapper(r));
        }
        
        return rendements;
    }

    /**
     * Classe wrapper pour les rendements
     */
    public class RendementWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String bien;
        @AuraEnabled public Decimal totalLoyers;
        @AuraEnabled public Decimal totalCharges;
        @AuraEnabled public Decimal totalDepenses;
        @AuraEnabled public Decimal rendementBrut;
        @AuraEnabled public Decimal rendementNet;
        
        public RendementWrapper(Rendement__c r) {
            this.id = r.Id;
            this.bien = r.Bien_Locatif__r.Name;
            this.totalLoyers = r.Total_Loyers__c;
            this.totalCharges = r.Total_Charges_Percues__c;
            this.totalDepenses = r.Total_Depenses__c;
            this.rendementBrut = r.Rendement_Brut__c;
            this.rendementNet = r.Rendement_Net__c;
        }
    }

    /**
     * Classe d'exception personnalisée pour le service de rendement
     */
    public class RendementServiceException extends Exception {}
}