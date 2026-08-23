/**
 * @description Classe de test pour les triggers de dépense
 * @author Manus
 * @date Avril 2025
 */
@isTest
private class DepenseTriggerTest {
    
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
    }
    
    /**
     * Test de la mise à jour du rendement lors de l'insertion d'une dépense
     */
    @isTest
    static void testMiseAJourRendementInsertionDepense() {
        // Récupérer le bien de test
        Bien_Locatif__c bien = [SELECT Id FROM Bien_Locatif__c WHERE Name = 'Bien Test' LIMIT 1];
        
        // Vérifier qu'aucun rendement n'existe initialement
        List<Rendement__c> rendementsAvant = [SELECT Id FROM Rendement__c WHERE Bien_Locatif__c = :bien.Id AND Annee__c = :String.valueOf(Date.today().year())];
        System.assertEquals(0, rendementsAvant.size(), 'Un rendement existe déjà avant l\'insertion de la dépense');
        
        // Insérer une dépense
        Test.startTest();
        Depense__c depense = new Depense__c(
            Bien_Locatif__c = bien.Id,
            Date_Depense__c = Date.today(),
            Nature__c = 'Taxe foncière',
            Montant__c = 1200,
            Recuperable__c = false,
            Description__c = 'Taxe foncière annuelle'
        );
        insert depense;
        Test.stopTest();
        
        // Vérifier qu'un rendement a été créé
        List<Rendement__c> rendementsApres = [SELECT Id, Total_Depenses__c FROM Rendement__c WHERE Bien_Locatif__c = :bien.Id AND Annee__c = :String.valueOf(Date.today().year())];
        System.assertEquals(1, rendementsApres.size(), 'Aucun rendement n\'a été créé après insertion de la dépense');
        
        // Vérifier que le montant des dépenses dans le rendement est correct
        Rendement__c rendement = rendementsApres[0];
        System.assertEquals(1200, rendement.Total_Depenses__c, 'Le total des dépenses dans le rendement est incorrect');
    }
    
    /**
     * Test de la mise à jour du rendement lors de la modification d'une dépense
     */
    @isTest
    static void testMiseAJourRendementModificationDepense() {
        // Récupérer le bien de test
        Bien_Locatif__c bien = [SELECT Id FROM Bien_Locatif__c WHERE Name = 'Bien Test' LIMIT 1];
        
        // Insérer une dépense
        Depense__c depense = new Depense__c(
            Bien_Locatif__c = bien.Id,
            Date_Depense__c = Date.today(),
            Nature__c = 'Taxe foncière',
            Montant__c = 1200,
            Recuperable__c = false,
            Description__c = 'Taxe foncière annuelle'
        );
        insert depense;
        
        // Vérifier qu'un rendement a été créé avec le montant initial
        List<Rendement__c> rendementsAvant = [SELECT Id, Total_Depenses__c FROM Rendement__c WHERE Bien_Locatif__c = :bien.Id AND Annee__c = :String.valueOf(Date.today().year())];
        System.assertEquals(1, rendementsAvant.size(), 'Aucun rendement n\'a été créé après insertion de la dépense');
        System.assertEquals(1200, rendementsAvant[0].Total_Depenses__c, 'Le total initial des dépenses dans le rendement est incorrect');
        
        // Modifier la dépense
        Test.startTest();
        depense.Montant__c = 1500;
        update depense;
        Test.stopTest();
        
        // Vérifier que le rendement a été mis à jour
        List<Rendement__c> rendementsApres = [SELECT Id, Total_Depenses__c FROM Rendement__c WHERE Bien_Locatif__c = :bien.Id AND Annee__c = :String.valueOf(Date.today().year())];
        System.assertEquals(1, rendementsApres.size(), 'Le rendement a été supprimé après modification de la dépense');
        
        // Vérifier que le montant des dépenses dans le rendement a été mis à jour
        Rendement__c rendement = rendementsApres[0];
        System.assertEquals(1500, rendement.Total_Depenses__c, 'Le total des dépenses dans le rendement n\'a pas été mis à jour');
    }
    
    /**
     * Test de la mise à jour du rendement lors de la suppression d'une dépense
     */
    @isTest
    static void testMiseAJourRendementSuppressionDepense() {
        // Récupérer le bien de test
        Bien_Locatif__c bien = [SELECT Id FROM Bien_Locatif__c WHERE Name = 'Bien Test' LIMIT 1];
        
        // Insérer une dépense
        Depense__c depense = new Depense__c(
            Bien_Locatif__c = bien.Id,
            Date_Depense__c = Date.today(),
            Nature__c = 'Taxe foncière',
            Montant__c = 1200,
            Recuperable__c = false,
            Description__c = 'Taxe foncière annuelle'
        );
        insert depense;
        
        // Vérifier qu'un rendement a été créé avec le montant initial
        List<Rendement__c> rendementsAvant = [SELECT Id, Total_Depenses__c FROM Rendement__c WHERE Bien_Locatif__c = :bien.Id AND Annee__c = :String.valueOf(Date.today().year())];
        System.assertEquals(1, rendementsAvant.size(), 'Aucun rendement n\'a été créé après insertion de la dépense');
        System.assertEquals(1200, rendementsAvant[0].Total_Depenses__c, 'Le total initial des dépenses dans le rendement est incorrect');
        
        // Supprimer la dépense
        Test.startTest();
        delete depense;
        Test.stopTest();
        
        // Vérifier que le rendement a été mis à jour
        List<Rendement__c> rendementsApres = [SELECT Id, Total_Depenses__c FROM Rendement__c WHERE Bien_Locatif__c = :bien.Id AND Annee__c = :String.valueOf(Date.today().year())];
        System.assertEquals(1, rendementsApres.size(), 'Le rendement a été supprimé après suppression de la dépense');
        
        // Vérifier que le montant des dépenses dans le rendement a été mis à jour à 0
        Rendement__c rendement = rendementsApres[0];
        System.assertEquals(0, rendement.Total_Depenses__c, 'Le total des dépenses dans le rendement n\'a pas été mis à jour à 0');
    }
    
    /**
     * Test de la validation du montant de la dépense
     */
    @isTest
    static void testValidationMontantDepense() {
        // Récupérer le bien de test
        Bien_Locatif__c bien = [SELECT Id FROM Bien_Locatif__c WHERE Name = 'Bien Test' LIMIT 1];
        
        // Tenter d'insérer une dépense avec un montant négatif
        Test.startTest();
        Depense__c depense = new Depense__c(
            Bien_Locatif__c = bien.Id,
            Date_Depense__c = Date.today(),
            Nature__c = 'Taxe foncière',
            Montant__c = -100, // Montant négatif
            Recuperable__c = false,
            Description__c = 'Taxe foncière annuelle'
        );
        
        try {
            insert depense;
            System.assert(false, 'L\'insertion de la dépense avec un montant négatif aurait dû échouer');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('montant'), 'Le message d\'erreur devrait mentionner le montant');
        }
        Test.stopTest();
    }

    /**
     * Test de la mise à jour du rendement après insertion d'une dépense.
     */
    @isTest
    static void testMiseAJourRendement() {
        // Créer une dépense
        Depense__c depense = new Depense__c(
            Bien_Locatif__c = 'BienTestId',
            Montant__c = 500
        );
        insert depense;

        // Vérifier que le rendement a été mis à jour
        // Ajoutez des assertions pour vérifier les résultats attendus
    }
}
