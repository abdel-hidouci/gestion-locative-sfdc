/**
 * @description Classe de test pour les triggers de paiement
 * @author Manus
 * @date Avril 2025
 */
@isTest
private class PaiementTriggerTest {
    
    /**
     * Méthode pour créer les données de test
     */
    @testSetup
    static void setupTestData() {
        // Créer un bien locatif
        Bien_Locatif__c bien = new Bien_Locatif__c(
            Name = 'Bien Test',
            Type__c = 'Appartement',
            Adresse__c = '123 Rue de Test',
            Code_Postal__c = '75000',
            Ville__c = 'Paris',
            Surface__c = 50,
            Nombre_Pieces__c = 2,
            Statut__c = 'Loué',
            Prix_Acquisition__c = 200000
        );
        insert bien;
        
        // Créer un locataire
        Locataire__c locataire = new Locataire__c(
            Name = 'Locataire Test',
            Nom__c = 'Nom Test',
            Prenom__c = 'Prénom Test',
            Email__c = 'test@example.com',
            Telephone__c = '0123456789'
        );
        insert locataire;
        
        // Créer un bail
        Bail__c bail = new Bail__c(
            Bien_Locatif__c = bien.Id,
            Locataire__c = locataire.Id,
            Date_Debut__c = Date.today().addMonths(-6),
            Date_Fin__c = Date.today().addMonths(6),
            Montant_Loyer__c = 800,
            Montant_Charges__c = 100,
            Depot_Garantie__c = 1600,
            Statut__c = 'Actif',
            Type_Bail__c = 'Habitation',
            Periodicite_Paiement__c = 'Mensuel',
            Jour_Paiement__c = 5
        );
        insert bail;
    }
    
    /**
     * Test de la génération automatique de quittance lors du passage d'un paiement à "Encaissé"
     */
    @isTest
    static void testGenerationQuittanceAutomatique() {
        // Récupérer le bail de test
        Bail__c bail = [SELECT Id FROM Bail__c WHERE Name = 'Bail Test' LIMIT 1];
        
        // Créer un paiement en attente
        Paiement__c paiement = new Paiement__c(
            Bail__c = bail.Id,
            Date_Paiement__c = Date.today(),
            Montant_Loyer__c = 800,
            Montant_Charges__c = 100,
            Statut__c = 'En attente',
            Moyen_Paiement__c = 'Virement'
        );
        insert paiement;
        
        // Vérifier qu'aucune quittance n'a été générée
        List<Quittance__c> quittancesAvant = [SELECT Id FROM Quittance__c WHERE Paiement__c = :paiement.Id];
        System.assertEquals(0, quittancesAvant.size(), 'Une quittance a été générée alors que le paiement est en attente');
        
        // Mettre à jour le statut du paiement à "Encaissé"
        Test.startTest();
        paiement.Statut__c = 'Encaissé';
        paiement.Date_Encaissement__c = Date.today();
        update paiement;
        Test.stopTest();
        
        // Vérifier qu'une quittance a été générée
        List<Quittance__c> quittancesApres = [SELECT Id FROM Quittance__c WHERE Paiement__c = :paiement.Id];
        System.assertEquals(1, quittancesApres.size(), 'Aucune quittance n\'a été générée après encaissement du paiement');
        
        // Vérifier que le paiement a été marqué comme ayant généré une quittance
        paiement = [SELECT Id, Quittance_Generee__c FROM Paiement__c WHERE Id = :paiement.Id LIMIT 1];
        System.assertEquals(true, paiement.Quittance_Generee__c, 'Le paiement n\'a pas été marqué comme ayant généré une quittance');
    }
    
    /**
     * Test de la mise à jour du rendement lors de l'insertion d'un paiement
     */
    @isTest
    static void testMiseAJourRendementInsertionPaiement() {
        // Récupérer le bail et le bien de test
        Bail__c bail = [SELECT Id, Bien_Locatif__c FROM Bail__c WHERE Name = 'Bail Test' LIMIT 1];
        Id bienId = bail.Bien_Locatif__c;
        
        // Vérifier qu'aucun rendement n'existe initialement
        List<Rendement__c> rendementsAvant = [SELECT Id FROM Rendement__c WHERE Bien_Locatif__c = :bienId AND Annee__c = :String.valueOf(Date.today().year())];
        System.assertEquals(0, rendementsAvant.size(), 'Un rendement existe déjà avant l\'insertion du paiement');
        
        // Insérer un paiement
        Test.startTest();
        Paiement__c paiement = new Paiement__c(
            Bail__c = bail.Id,
            Date_Paiement__c = Date.today(),
            Montant_Loyer__c = 800,
            Montant_Charges__c = 100,
            Statut__c = 'Encaissé',
            Moyen_Paiement__c = 'Virement',
            Date_Encaissement__c = Date.today()
        );
        insert paiement;
        Test.stopTest();
        
        // Vérifier qu'un rendement a été créé
        List<Rendement__c> rendementsApres = [SELECT Id, Total_Loyers__c, Total_Charges__c FROM Rendement__c WHERE Bien_Locatif__c = :bienId AND Annee__c = :String.valueOf(Date.today().year())];
        System.assertEquals(1, rendementsApres.size(), 'Aucun rendement n\'a été créé après insertion du paiement');
        
        // Vérifier que les montants du rendement sont corrects
        Rendement__c rendement = rendementsApres[0];
        System.assertEquals(800, rendement.Total_Loyers__c, 'Le total des loyers dans le rendement est incorrect');
        System.assertEquals(100, rendement.Total_Charges__c, 'Le total des charges dans le rendement est incorrect');
    }
    
    /**
     * Test de la mise à jour du rendement lors de la modification d'un paiement
     */
    @isTest
    static void testMiseAJourRendementModificationPaiement() {
        // Récupérer le bail et le bien de test
        Bail__c bail = [SELECT Id, Bien_Locatif__c FROM Bail__c WHERE Name = 'Bail Test' LIMIT 1];
        Id bienId = bail.Bien_Locatif__c;
        
        // Insérer un paiement
        Paiement__c paiement = new Paiement__c(
            Bail__c = bail.Id,
            Date_Paiement__c = Date.today(),
            Montant_Loyer__c = 800,
            Montant_Charges__c = 100,
            Statut__c = 'Encaissé',
            Moyen_Paiement__c = 'Virement',
            Date_Encaissement__c = Date.today()
        );
        insert paiement;
        
        // Vérifier qu'un rendement a été créé avec les montants initiaux
        List<Rendement__c> rendementsAvant = [SELECT Id, Total_Loyers__c, Total_Charges__c FROM Rendement__c WHERE Bien_Locatif__c = :bienId AND Annee__c = :String.valueOf(Date.today().year())];
        System.assertEquals(1, rendementsAvant.size(), 'Aucun rendement n\'a été créé après insertion du paiement');
        System.assertEquals(800, rendementsAvant[0].Total_Loyers__c, 'Le total initial des loyers dans le rendement est incorrect');
        System.assertEquals(100, rendementsAvant[0].Total_Charges__c, 'Le total initial des charges dans le rendement est incorrect');
        
        // Modifier le paiement
        Test.startTest();
        paiement.Montant_Loyer__c = 850;
        paiement.Montant_Charges__c = 120;
        update paiement;
        Test.stopTest();
        
        // Vérifier que le rendement a été mis à jour
        List<Rendement__c> rendementsApres = [SELECT Id, Total_Loyers__c, Total_Charges__c FROM Rendement__c WHERE Bien_Locatif__c = :bienId AND Annee__c = :String.valueOf(Date.today().year())];
        System.assertEquals(1, rendementsApres.size(), 'Le rendement a été supprimé après modification du paiement');
        
        // Vérifier que les montants du rendement ont été mis à jour
        Rendement__c rendement = rendementsApres[0];
        System.assertEquals(850, rendement.Total_Loyers__c, 'Le total des loyers dans le rendement n\'a pas été mis à jour');
        System.assertEquals(120, rendement.Total_Charges__c, 'Le total des charges dans le rendement n\'a pas été mis à jour');
    }
}