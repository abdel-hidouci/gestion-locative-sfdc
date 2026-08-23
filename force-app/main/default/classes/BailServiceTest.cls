/**
 * @description Classe de test pour BailService
 * @author Manus
 * @date Avril 2025
 */
@isTest
private class BailServiceTest {
    
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
            Email__c = 'test@example.com'
        );
        insert locataire;
        
        // Créer un bail actif
        Bail__c bailActif = new Bail__c(
            Bien_Locatif__c = bien.Id,
            Locataire__c = locataire.Id,
            Date_Debut__c = Date.today().addMonths(-6),
            Date_Fin__c = Date.today().addMonths(6),
            Montant_Loyer__c = 800,
            Montant_Charges__c = 100,
            Depot_Garantie__c = 1600,
            Statut__c = 'Actif'
        );
        insert bailActif;
        
        // Créer un second bien locatif
        Bien_Locatif__c bien2 = new Bien_Locatif__c(
            Name = 'Bien Test 2',
            Type__c = 'Appartement',
            Adresse__c = '456 Rue de Test',
            Code_Postal__c = '75000',
            Ville__c = 'Paris',
            Surface__c = 40,
            Nombre_Pieces__c = 1,
            Statut__c = 'Vacant'
        );
        insert bien2;
        
        // Créer un second locataire
        Locataire__c locataire2 = new Locataire__c(
            Name = 'Locataire Test 2',
            Nom__c = 'Nom Test 2',
            Prenom__c = 'Prénom Test 2',
            Email__c = 'test2@example.com'
        );
        insert locataire2;
        
        // Créer un bail en préavis
        Bail__c bailPrevis = new Bail__c(
            Bien_Locatif__c = bien2.Id,
            Locataire__c = locataire2.Id,
            Date_Debut__c = Date.today().addMonths(-12),
            Date_Fin__c = Date.today().addMonths(1),
            Montant_Loyer__c = 700,
            Montant_Charges__c = 80,
            Depot_Garantie__c = 1400,
            Statut__c = 'En préavis',
            Date_Resiliation__c = Date.today().addMonths(-1),
            Duree_Preavis__c = 3
        );
        insert bailPrevis;
    }
    
    /**
     * Test de la mise à jour du statut d'un bien
     */
    @isTest
    static void testMettreAJourStatutBien() {
        // Récupérer le bien et le bail de test
        Bien_Locatif__c bien = [SELECT Id, Statut__c FROM Bien_Locatif__c WHERE Name = 'Bien Test' LIMIT 1];
        Bail__c bail = [SELECT Id FROM Bail__c LIMIT 1];
        
        // Vérifier que le statut initial du bien est "Vacant"
        System.assertEquals('Vacant', bien.Statut__c, 'Le statut initial du bien devrait être Vacant');
        
        // Exécuter la méthode à tester
        Test.startTest();
        BailService.mettreAJourStatutBien(bien.Id);
        Test.stopTest();
        
        // Vérifier que le statut du bien a été mis à jour à "Loué"
        bien = [SELECT Id, Statut__c FROM Bien_Locatif__c WHERE Id = :bien.Id LIMIT 1];
        System.assertEquals('Loué', bien.Statut__c, 'Le statut du bien devrait être Loué');
        
        // Résilier le bail
        bail.Statut__c = 'Résilié';
        bail.Date_Resiliation__c = Date.today();
        update bail;
        
        // Mettre à jour le statut du bien à nouveau
        BailService.mettreAJourStatutBien(bien.Id);
        
        // Vérifier que le statut du bien a été mis à jour à "Vacant"
        bien = [SELECT Id, Statut__c FROM Bien_Locatif__c WHERE Id = :bien.Id LIMIT 1];
        System.assertEquals('Vacant', bien.Statut__c, 'Le statut du bien devrait être Vacant après résiliation du bail');
    }
    
    /**
     * Test de l'envoi d'alertes de fin de bail
     */
    @isTest
    static void testEnvoyerAlertesFinBail() {
        // Récupérer le bail de test
        Bail__c bail = [SELECT Id, Date_Fin__c FROM Bail__c LIMIT 1];
        
        // Modifier la date de fin pour qu'elle soit dans 30 jours
        bail.Date_Fin__c = Date.today().addDays(30);
        update bail;
        
        // Exécuter la méthode à tester
        Test.startTest();
        Integer emailsEnvoyes = Limits.getEmailInvocations();
        BailService.envoyerAlertesFinBail(30);
        Test.stopTest();
        
        // Vérifier que le bail a été marqué comme ayant reçu une alerte
        bail = [SELECT Id, Alerte_Fin_Bail_Envoyee__c FROM Bail__c WHERE Id = :bail.Id LIMIT 1];
        System.assertEquals(true, bail.Alerte_Fin_Bail_Envoyee__c, 'Le bail n\'a pas été marqué comme ayant reçu une alerte');
    }
    
    /**
     * Test de la vérification des fins de bail
     */
    @isTest
    static void testVerifierFinsBail() {
        // Créer un bail avec une date de fin proche
        Bail__c bail = new Bail__c(
            Date_Fin__c = Date.today().addDays(30),
            Statut__c = 'Actif'
        );
        insert bail;

        // Appeler la méthode
        Test.startTest();
        List<Bail__c> baux = BailService.verifierFinsBail(60);
        Test.stopTest();

        // Vérifier les résultats
        System.assertEquals(1, baux.size(), 'Le bail devrait être identifié comme à échéance.');
    }
    
    /**
     * Test de la résiliation d'un bail
     */
    @isTest
    static void testResilierBail() {
        // Récupérer le bail de test
        Bail__c bail = [SELECT Id FROM Bail__c LIMIT 1];
        
        // Exécuter la méthode à tester
        Test.startTest();
        Date dateResiliation = Date.today();
        Integer dureePrevis = 3;
        BailService.resilierBail(bail.Id, dateResiliation, dureePrevis);
        Test.stopTest();
        
        // Vérifier que le bail a été mis en préavis
        bail = [SELECT Id, Statut__c, Date_Resiliation__c, Duree_Preavis__c FROM Bail__c WHERE Id = :bail.Id LIMIT 1];
        System.assertEquals('En préavis', bail.Statut__c, 'Le statut du bail devrait être En préavis');
        System.assertEquals(dateResiliation, bail.Date_Resiliation__c, 'La date de résiliation est incorrecte');
        System.assertEquals(dureePrevis, bail.Duree_Preavis__c, 'La durée de préavis est incorrecte');
    }
    
    /**
     * Test du renouvellement d'un bail
     */
    @isTest
    static void testRenouvelerBail() {
        // Créer un bail
        Bail__c bail = new Bail__c(
            Date_Fin__c = Date.today(),
            Statut__c = 'Actif'
        );
        insert bail;

        // Appeler la méthode
        Test.startTest();
        BailService.renouvelerBail(bail.Id, 3);
        Test.stopTest();

        // Vérifier la nouvelle date de fin
        bail = [SELECT Date_Fin__c FROM Bail__c WHERE Id = :bail.Id];
        System.assertEquals(Date.today().addYears(3), bail.Date_Fin__c, 'La date de fin devrait être prolongée de 3 ans.');
    }

    /**
     * Test de la méthode calculerRendement.
     */
    @isTest
    static void testCalculerRendement() {
        // Créer un bien locatif
        Bien_Locatif__c bien = new Bien_Locatif__c(
            Name = 'Bien Test Rendement',
            Type__c = 'Appartement',
            Adresse__c = '123 Rue de Test',
            Code_Postal__c = '75000',
            Ville__c = 'Paris',
            Surface__c = 50,
            Nombre_Pieces__c = 2,
            Statut__c = 'Loué'
        );
        insert bien;

        // Créer un rendement
        Rendement__c rendement = new Rendement__c(
            Bien_Locatif__c = bien.Id,
            Annee__c = '2023',
            Total_Loyers__c = 10000,
            Total_Charges_Percues__c = 2000,
            Total_Depenses__c = 5000
        );
        insert rendement;

        // Appeler la méthode
        Test.startTest();
        BailService.calculerRendement(bien.Id, '2023');
        Test.stopTest();

        // Vérifier les résultats
        rendement = [SELECT Rendement_Brut__c, Rendement_Net__c FROM Rendement__c WHERE Bien_Locatif__c = :bien.Id AND Annee__c = '2023' LIMIT 1];
        System.assertNotEquals(null, rendement.Rendement_Brut__c, 'Le rendement brut ne doit pas être nul.');
        System.assertNotEquals(null, rendement.Rendement_Net__c, 'Le rendement net ne doit pas être nul.');
    }

    /**
     * Test de la récupération des baux
     */
    @isTest
    static void testGetBaux() {
        // Les données de test sont déjà créées dans setupTestData
        
        // Test sans filtre
        Test.startTest();
        List<BailService.BailWrapper> tousLesBaux = BailService.getBaux(null);
        Test.stopTest();
        
        // Vérifier les résultats sans filtre
        System.assertEquals(2, tousLesBaux.size(), 'Le nombre total de baux est incorrect');
        
        // Test avec filtre sur le statut
        List<BailService.BailWrapper> bauxActifs = BailService.getBaux('Actif');
        System.assertEquals(1, bauxActifs.size(), 'Le nombre de baux actifs est incorrect');
        
        // Vérifier les détails d'un bail
        BailService.BailWrapper bail = bauxActifs[0];
        System.assertNotEquals(null, bail.id, 'L\'ID du bail ne devrait pas être null');
        System.assertEquals('Bien Test', bail.bien, 'Le nom du bien est incorrect');
        System.assertEquals('Locataire Test', bail.locataire, 'Le nom du locataire est incorrect');
        System.assertEquals(800, bail.loyer, 'Le montant du loyer est incorrect');
        System.assertEquals(100, bail.charges, 'Le montant des charges est incorrect');
        System.assertEquals(900, bail.total, 'Le montant total est incorrect');
        System.assertEquals('Actif', bail.statut, 'Le statut est incorrect');
        System.assertEquals('slds-text-color_success', bail.classeStatut, 'La classe CSS du statut est incorrecte');
    }
}
