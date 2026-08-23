/**
 * @description Classe de test pour les triggers de bail
 * @author Manus
 * @date Avril 2025
 */
@isTest
private class BailTriggerTest {
    
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
            Statut__c = 'Vacant'
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
    }
    
    /**
     * Test de la mise à jour du statut du bien lors de l'insertion d'un bail
     */
    @isTest
    static void testMiseAJourStatutBienInsertionBail() {
        // Récupérer le bien et le locataire de test
        Bien_Locatif__c bien = [SELECT Id, Statut__c FROM Bien_Locatif__c WHERE Name = 'Bien Test' LIMIT 1];
        Locataire__c locataire = [SELECT Id FROM Locataire__c WHERE Name = 'Locataire Test' LIMIT 1];
        
        // Vérifier que le statut initial du bien est "Vacant"
        System.assertEquals('Vacant', bien.Statut__c, 'Le statut initial du bien devrait être Vacant');
        
        // Insérer un bail actif
        Test.startTest();
        Bail__c bail = new Bail__c(
            Bien_Locatif__c = bien.Id,
            Locataire__c = locataire.Id,
            Date_Debut__c = Date.today(),
            Date_Fin__c = Date.today().addYears(3),
            Montant_Loyer__c = 800,
            Montant_Charges__c = 100,
            Depot_Garantie__c = 1600,
            Statut__c = 'Actif',
            Type_Bail__c = 'Habitation',
            Periodicite_Paiement__c = 'Mensuel',
            Jour_Paiement__c = 5
        );
        insert bail;
        Test.stopTest();
        
        // Vérifier que le statut du bien a été mis à jour à "Loué"
        bien = [SELECT Id, Statut__c FROM Bien_Locatif__c WHERE Id = :bien.Id LIMIT 1];
        System.assertEquals('Loué', bien.Statut__c, 'Le statut du bien n\'a pas été mis à jour à Loué après insertion d\'un bail actif');
    }
    
    /**
     * Test de la mise à jour du statut du bien lors de la modification d'un bail
     */
    @isTest
    static void testMiseAJourStatutBienModificationBail() {
        // Récupérer le bien et le locataire de test
        Bien_Locatif__c bien = [SELECT Id, Statut__c FROM Bien_Locatif__c WHERE Name = 'Bien Test' LIMIT 1];
        Locataire__c locataire = [SELECT Id FROM Locataire__c WHERE Name = 'Locataire Test' LIMIT 1];
        
        // Insérer un bail actif
        Bail__c bail = new Bail__c(
            Bien_Locatif__c = bien.Id,
            Locataire__c = locataire.Id,
            Date_Debut__c = Date.today(),
            Date_Fin__c = Date.today().addYears(3),
            Montant_Loyer__c = 800,
            Montant_Charges__c = 100,
            Depot_Garantie__c = 1600,
            Statut__c = 'Actif',
            Type_Bail__c = 'Habitation',
            Periodicite_Paiement__c = 'Mensuel',
            Jour_Paiement__c = 5
        );
        insert bail;
        
        // Vérifier que le statut du bien a été mis à jour à "Loué"
        bien = [SELECT Id, Statut__c FROM Bien_Locatif__c WHERE Id = :bien.Id LIMIT 1];
        System.assertEquals('Loué', bien.Statut__c, 'Le statut du bien n\'a pas été mis à jour à Loué après insertion d\'un bail actif');
        
        // Modifier le bail pour le mettre en préavis
        Test.startTest();
        bail.Statut__c = 'En préavis';
        bail.Date_Resiliation__c = Date.today();
        bail.Duree_Preavis__c = 3;
        update bail;
        Test.stopTest();
        
        // Vérifier que le statut du bien est toujours "Loué" (car le bail est en préavis mais pas encore résilié)
        bien = [SELECT Id, Statut__c FROM Bien_Locatif__c WHERE Id = :bien.Id LIMIT 1];
        System.assertEquals('Loué', bien.Statut__c, 'Le statut du bien ne devrait pas changer quand le bail est en préavis');
        
        // Modifier le bail pour le résilier
        bail.Statut__c = 'Résilié';
        update bail;
        
        // Vérifier que le statut du bien a été mis à jour à "Vacant"
        bien = [SELECT Id, Statut__c FROM Bien_Locatif__c WHERE Id = :bien.Id LIMIT 1];
        System.assertEquals('Vacant', bien.Statut__c, 'Le statut du bien n\'a pas été mis à jour à Vacant après résiliation du bail');
    }
    
    /**
     * Test de la gestion des alertes de fin de bail
     */
    @isTest
    static void testAlertesFinBail() {
        // Récupérer le bien et le locataire de test
        Bien_Locatif__c bien = [SELECT Id FROM Bien_Locatif__c WHERE Name = 'Bien Test' LIMIT 1];
        Locataire__c locataire = [SELECT Id FROM Locataire__c WHERE Name = 'Locataire Test' LIMIT 1];
        
        // Insérer un bail qui se termine dans 30 jours
        Test.startTest();
        Bail__c bail = new Bail__c(
            Bien_Locatif__c = bien.Id,
            Locataire__c = locataire.Id,
            Date_Debut__c = Date.today().addYears(-3),
            Date_Fin__c = Date.today().addDays(30),
            Montant_Loyer__c = 800,
            Montant_Charges__c = 100,
            Depot_Garantie__c = 1600,
            Statut__c = 'Actif',
            Type_Bail__c = 'Habitation',
            Periodicite_Paiement__c = 'Mensuel',
            Jour_Paiement__c = 5
        );
        insert bail;
        Test.stopTest();
        
        // Exécuter le batch d'alertes de fin de bail (simulé par un appel direct)
        BailService.envoyerAlertesFinBail(60);
        
        // Vérifier que le bail a été marqué comme ayant reçu une alerte
        bail = [SELECT Id, Alerte_Fin_Bail_Envoyee__c FROM Bail__c WHERE Id = :bail.Id LIMIT 1];
        System.assertEquals(true, bail.Alerte_Fin_Bail_Envoyee__c, 'Le bail n\'a pas été marqué comme ayant reçu une alerte');
    }
    
    /**
     * Test de la validation des dates de bail
     */
    @isTest
    static void testValidationDatesBail() {
        // Récupérer le bien et le locataire de test
        Bien_Locatif__c bien = [SELECT Id FROM Bien_Locatif__c WHERE Name = 'Bien Test' LIMIT 1];
        Locataire__c locataire = [SELECT Id FROM Locataire__c WHERE Name = 'Locataire Test' LIMIT 1];
        
        // Tenter d'insérer un bail avec une date de fin antérieure à la date de début
        Test.startTest();
        Bail__c bail = new Bail__c(
            Bien_Locatif__c = bien.Id,
            Locataire__c = locataire.Id,
            Date_Debut__c = Date.today(),
            Date_Fin__c = Date.today().addDays(-1), // Date de fin avant date de début
            Montant_Loyer__c = 800,
            Montant_Charges__c = 100,
            Depot_Garantie__c = 1600,
            Statut__c = 'Actif',
            Type_Bail__c = 'Habitation',
            Periodicite_Paiement__c = 'Mensuel',
            Jour_Paiement__c = 5
        );
        
        try {
            insert bail;
            System.assert(false, 'L\'insertion du bail avec des dates invalides aurait dû échouer');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('date de fin'), 'Le message d\'erreur devrait mentionner la date de fin');
        }
        Test.stopTest();
    }
}