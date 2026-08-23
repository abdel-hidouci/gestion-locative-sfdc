/**
 * @description Classe de test pour QuittanceService
 * @author Manus
 * @date Avril 2025
 */
@isTest
private class QuittanceServiceTest {
    
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
            Statut__c = 'Loué'
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
        
        // Créer un paiement
        Paiement__c paiement = new Paiement__c(
            Bail__c = bail.Id,
            Date_Paiement__c = Date.today(),
            Montant_Loyer__c = 800,
            Montant_Charges__c = 100,
            Statut__c = 'En attente',
            Moyen_Paiement__c = 'Virement'
        );
        insert paiement;
    }
    
    /**
     * Test de la génération d'une quittance
     */
    @isTest
    static void testGenererQuittance() {
        // Récupérer le paiement de test
        Paiement__c paiement = [SELECT Id, Statut__c FROM Paiement__c WHERE Mois_Concerne__c = 'Avril' LIMIT 1];
        
        // Mettre à jour le statut du paiement à "Encaissé"
        paiement.Statut__c = 'Encaissé';
        paiement.Date_Encaissement__c = Date.today();
        update paiement;
        
        // Exécuter la méthode à tester
        Test.startTest();
        Id quittanceId = QuittanceService.genererQuittance(paiement.Id);
        Test.stopTest();
        
        // Vérifier que la quittance a été créée
        System.assertNotEquals(null, quittanceId, 'La quittance n\'a pas été créée');
        
        // Vérifier les détails de la quittance
        Quittance__c quittance = [SELECT Id, Paiement__c, Montant_Loyer__c, Montant_Charges__c, Montant_Total__c, Periode_Debut__c, Periode_Fin__c 
                                 FROM Quittance__c WHERE Id = :quittanceId LIMIT 1];
        
        System.assertEquals(paiement.Id, quittance.Paiement__c, 'Le paiement associé à la quittance est incorrect');
        System.assertEquals(800, quittance.Montant_Loyer__c, 'Le montant du loyer est incorrect');
        System.assertEquals(100, quittance.Montant_Charges__c, 'Le montant des charges est incorrect');
        System.assertEquals(900, quittance.Montant_Total__c, 'Le montant total est incorrect');
        
        // Vérifier que le paiement a été marqué comme ayant généré une quittance
        paiement = [SELECT Id, Quittance_Generee__c FROM Paiement__c WHERE Id = :paiement.Id LIMIT 1];
        System.assertEquals(true, paiement.Quittance_Generee__c, 'Le paiement n\'a pas été marqué comme ayant généré une quittance');
    }
    
    /**
     * Test de l'envoi d'une quittance par email
     */
    @isTest
    static void testEnvoyerQuittanceParEmail() {
        // Récupérer le paiement de test
        Paiement__c paiement = [SELECT Id, Statut__c FROM Paiement__c WHERE Mois_Concerne__c = 'Avril' LIMIT 1];
        
        // Mettre à jour le statut du paiement à "Encaissé"
        paiement.Statut__c = 'Encaissé';
        paiement.Date_Encaissement__c = Date.today();
        update paiement;
        
        // Générer une quittance
        Id quittanceId = QuittanceService.genererQuittance(paiement.Id);
        
        // Exécuter la méthode à tester
        Test.startTest();
        Integer emailsEnvoyes = Limits.getEmailInvocations();
        Boolean resultat = QuittanceService.envoyerQuittanceParEmail(quittanceId, 'test@example.com');
        Test.stopTest();
        
        // Vérifier que l'email a été envoyé
        System.assertEquals(true, resultat, 'L\'envoi de l\'email a échoué');
        
        // Vérifier que la quittance a été marquée comme envoyée
        Quittance__c quittance = [SELECT Id, Envoyee_Par_Email__c, Date_Envoi_Email__c FROM Quittance__c WHERE Id = :quittanceId LIMIT 1];
        System.assertEquals(true, quittance.Envoyee_Par_Email__c, 'La quittance n\'a pas été marquée comme envoyée par email');
        System.assertNotEquals(null, quittance.Date_Envoi_Email__c, 'La date d\'envoi de l\'email n\'a pas été définie');
    }
    
    /**
     * Test de la génération d'une quittance avec un paiement inexistant
     */
    @isTest
    static void testGenererQuittancePaiementInexistant() {
        // Exécuter la méthode à tester avec un ID invalide
        Test.startTest();
        try {
            Id quittanceId = QuittanceService.genererQuittance('a0A000000000000');
            System.assert(false, 'Une exception aurait dû être levée');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Paiement introuvable'), 'Message d\'erreur incorrect : ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * Test de la génération d'une quittance pour un paiement non encaissé
     */
    @isTest
    static void testGenererQuittancePaiementNonEncaisse() {
        // Récupérer le paiement de test (statut "En attente")
        Paiement__c paiement = [SELECT Id, Statut__c FROM Paiement__c WHERE Mois_Concerne__c = 'Avril' LIMIT 1];
        
        // Exécuter la méthode à tester
        Test.startTest();
        try {
            Id quittanceId = QuittanceService.genererQuittance(paiement.Id);
            System.assert(false, 'Une exception aurait dû être levée');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('non encaissé'), 'Message d\'erreur incorrect : ' + e.getMessage());
        }
        Test.stopTest();
    }
}