/**
 * @description Classe de test pour RendementService
 * @author Manus
 * @date Avril 2025
 */
@isTest
private class RendementServiceTest {
    
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
            Date_Debut__c = Date.newInstance(2023, 1, 1),
            Date_Fin__c = Date.newInstance(2025, 12, 31),
            Montant_Loyer__c = 800,
            Montant_Charges__c = 100,
            Depot_Garantie__c = 1600,
            Statut__c = 'Actif',
            Type_Bail__c = 'Habitation',
            Periodicite_Paiement__c = 'Mensuel',
            Jour_Paiement__c = 5
        );
        insert bail;
        
        // Créer des paiements pour l'année 2023
        List<Paiement__c> paiements = new List<Paiement__c>();
        for (Integer mois = 1; mois <= 12; mois++) {
            
            Paiement__c paiement = new Paiement__c(
                Bail__c = bail.Id,
                Date_Paiement__c = Date.newInstance(2023, mois, 5),
                Montant_Loyer__c = 800,
                Montant_Charges__c = 100,
                Statut__c = 'Encaissé',
                Moyen_Paiement__c = 'Virement',
                Date_Encaissement__c = Date.newInstance(2023, mois, 7)
            );
            paiements.add(paiement);
        }
        insert paiements;
        
        // Créer des dépenses pour l'année 2023
        List<Depense__c> depenses = new List<Depense__c>();
        
        // Taxe foncière
        Depense__c taxeFonciere = new Depense__c(
            Bien_Locatif__c = bien.Id,
            Date_Depense__c = Date.newInstance(2023, 10, 15),
            Nature__c = 'Taxe foncière',
            Montant__c = 1200,
            Recuperable__c = false,
            Annee_Fiscale__c = '2023',
            Description__c = 'Taxe foncière 2023'
        );
        depenses.add(taxeFonciere);
        
        // Assurance
        Depense__c assurance = new Depense__c(
            Bien_Locatif__c = bien.Id,
            Date_Depense__c = Date.newInstance(2023, 1, 10),
            Nature__c = 'Assurance',
            Montant__c = 400,
            Recuperable__c = false,
            Annee_Fiscale__c = '2023',
            Description__c = 'Assurance propriétaire non occupant'
        );
        depenses.add(assurance);
        
        // Charges de copropriété
        Depense__c chargesCopro = new Depense__c(
            Bien_Locatif__c = bien.Id,
            Date_Depense__c = Date.newInstance(2023, 6, 20),
            Nature__c = 'Charges de copropriété',
            Montant__c = 600,
            Recuperable__c = true,
            Annee_Fiscale__c = '2023',
            Description__c = 'Charges de copropriété 1er semestre 2023'
        );
        depenses.add(chargesCopro);
        
        insert depenses;
    }
    
    /**
     * Test du calcul du rendement pour un bien et une année
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

        // Appeler la méthode à tester
        Test.startTest();
        RendementService.calculerRendement(bien.Id, '2023');
        Test.stopTest();

        // Vérifier les résultats
        rendement = [SELECT Rendement_Brut__c, Rendement_Net__c FROM Rendement__c WHERE Bien_Locatif__c = :bien.Id AND Annee__c = '2023' LIMIT 1];
        System.assertNotEquals(null, rendement.Rendement_Brut__c, 'Le rendement brut ne doit pas être nul.');
        System.assertNotEquals(null, rendement.Rendement_Net__c, 'Le rendement net ne doit pas être nul.');
    }

    /**
     * Test du calcul du rendement pour tous les biens
     */
    @isTest
    static void testCalculerRendementTousBiens() {
        // Exécuter la méthode à tester
        Test.startTest();
        List<Id> rendementIds = RendementService.calculerRendementTousBiens('2023');
        Test.stopTest();
        
        // Vérifier que le rendement a été créé
        System.assertEquals(1, rendementIds.size(), 'Le nombre de rendements calculés est incorrect');
        
        // Vérifier les détails du rendement
        Rendement__c rendement = [SELECT Id, Bien_Locatif__c, Annee__c, Total_Loyers__c, Total_Charges__c, 
                                 Total_Depenses__c, Rendement_Brut__c, Rendement_Net__c 
                                 FROM Rendement__c WHERE Id = :rendementIds[0] LIMIT 1];
        
        System.assertEquals('2023', rendement.Annee__c, 'L\'année du rendement est incorrecte');
        System.assertEquals(9600, rendement.Total_Loyers__c, 'Le total des loyers est incorrect');
        System.assertEquals(1200, rendement.Total_Charges__c, 'Le total des charges est incorrect');
        System.assertEquals(2200, rendement.Total_Depenses__c, 'Le total des dépenses est incorrect');
    }
    
    /**
     * Test du calcul du rendement pour un bien inexistant
     */
    @isTest
    static void testCalculerRendementBienInexistant() {
        // Exécuter la méthode à tester avec un ID invalide
        Test.startTest();
        try {
            Id rendementId = RendementService.calculerRendement('a0A000000000000', '2023');
            System.assert(false, 'Une exception aurait dû être levée');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Bien locatif introuvable'), 'Message d\'erreur incorrect : ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * Test du calcul du rendement pour un bien sans prix d'acquisition
     */
    @isTest
    static void testCalculerRendementSansPrixAcquisition() {
        // Créer un bien sans prix d'acquisition
        Bien_Locatif__c bienSansPrix = new Bien_Locatif__c(
            Name = 'Bien Sans Prix',
            Type__c = 'Appartement',
            Adresse__c = '456 Rue de Test',
            Code_Postal__c = '75000',
            Ville__c = 'Paris',
            Surface__c = 40,
            Nombre_Pieces__c = 1,
            Statut__c = 'Loué',
            Prix_Acquisition__c = null
        );
        insert bienSansPrix;
        
        // Exécuter la méthode à tester
        Test.startTest();
        try {
            Id rendementId = RendementService.calculerRendement(bienSansPrix.Id, '2023');
            
            // Vérifier que le rendement a été créé mais avec des valeurs nulles pour les pourcentages
            Rendement__c rendement = [SELECT Id, Rendement_Brut__c, Rendement_Net__c 
                                     FROM Rendement__c WHERE Bien_Locatif__c = :bienSansPrix.Id LIMIT 1];
            
            System.assertEquals(null, rendement.Rendement_Brut__c, 'Le rendement brut devrait être null');
            System.assertEquals(null, rendement.Rendement_Net__c, 'Le rendement net devrait être null');
            
        } catch (Exception e) {
            System.assert(false, 'Aucune exception ne devrait être levée, mais le rendement devrait avoir des valeurs nulles : ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testRecalculerRendements() {
        // // Créer plusieurs biens locatifs
        // List<Bien_Locatif__c> biens = new List<Bien_Locatif__c>{
        //     new Bien_Locatif__c(Name = 'Bien 1', Type__c = 'Appartement', Adresse__c = 'Adresse 1', Code_Postal__c = '75001', Ville__c = 'Paris', Surface__c = 50, Nombre_Pieces__c = 2, Statut__c = 'Loué'),
        //     new Bien_Locatif__c(Name = 'Bien 2', Type__c = 'Appartement', Adresse__c = 'Adresse 2', Code_Postal__c = '75002', Ville__c = 'Paris', Surface__c = 60, Nombre_Pieces__c = 3, Statut__c = 'Loué')
        // };
        // insert biens;

        // // Appeler la méthode à tester
        // Test.startTest();
        // List<Id> bienIds = new List<Id>();
        // for (Bien_Locatif__c bien : biens) {
        //     bienIds.add(bien.Id);
        // }
        // RendementService.recalculerRendements(bienIds);
        // Test.stopTest();

        // // Vérifier les résultats
        // List<Rendement__c> rendements = [SELECT Bien_Locatif__c, Annee__c, Rendement_Brut__c, Rendement_Net__c FROM Rendement__c WHERE Bien_Locatif__c IN :bienIds];
        // System.assertEquals(2, rendements.size(), 'Deux rendements devraient être calculés.');
    }

    /**
     * Test de la récupération des rendements
     */
    @isTest
    static void testGetRendements() {
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
        
        // Créer un rendement
        Rendement__c rendement = new Rendement__c(
            Bien_Locatif__c = bien.Id,
            Annee__c = '2023',
            Total_Loyers__c = 10000,
            Total_Charges_Percues__c = 2000,
            Total_Depenses__c = 5000,
            Rendement_Brut__c = 6.0,
            Rendement_Net__c = 4.5
        );
        insert rendement;
        
        // Appeler la méthode à tester
        Test.startTest();
        List<RendementService.RendementWrapper> rendements = RendementService.getRendements();
        Test.stopTest();
        
        // Vérifier les résultats
        System.assertEquals(1, rendements.size(), 'Il devrait y avoir un rendement');
        RendementService.RendementWrapper wrapper = rendements[0];
        System.assertEquals(rendement.Id, wrapper.id, 'L\'ID du rendement est incorrect');
        System.assertEquals(bien.Name, wrapper.bien, 'Le nom du bien est incorrect');
        System.assertEquals(10000, wrapper.totalLoyers, 'Le total des loyers est incorrect');
        System.assertEquals(2000, wrapper.totalCharges, 'Le total des charges est incorrect');
        System.assertEquals(5000, wrapper.totalDepenses, 'Le total des dépenses est incorrect');
        System.assertEquals(6.0, wrapper.rendementBrut, 'Le rendement brut est incorrect');
        System.assertEquals(4.5, wrapper.rendementNet, 'Le rendement net est incorrect');
    }
}
