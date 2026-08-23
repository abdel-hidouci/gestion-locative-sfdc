/**
 * @description Classe de test pour ImportDonneesHistoriques
 * @author Manus
 * @date Avril 2025
 */
@isTest
private class ImportDonneesHistoriquesTest {
    
    /**
     * Test de l'importation de données complète
     */
    @isTest
    static void testImporterDonnees() {
        // Préparer les données CSV de test
        String csvBiens = 'Nom,Type,Adresse,CodePostal,Ville,Surface,NombrePieces,Etage,DateAcquisition,PrixAcquisition,Statut,Notes\n' +
                         'Bien Test,Appartement,123 Rue de Test,75000,Paris,50,2,2,01/01/2023,200000,Vacant,Test\n';
        
        String csvLocataires = 'Nom,Nom,Prenom,Email,Telephone,AdresseCorrespondance,DateNaissance,SituationProfessionnelle,RevenuMensuel,Notes\n' +
                             'Locataire Test,Dupont,Jean,test@example.com,0123456789,123 Rue de Test 75000 Paris,01/01/1980,Salarié,3000,Test\n';
        
        String csvBaux = 'Nom,BienLocatif,Locataire,DateDebut,DateFin,MontantLoyer,MontantCharges,DepotGarantie,Statut,TypeBail,PeriodicitePaiement,JourPaiement,DateDerniereRevision,DateResiliation,DureePreavis\n' +
                       'Bail Test,Bien Test,Locataire Test,01/01/2023,31/12/2025,800,100,1600,Actif,Habitation,Mensuel,5,,,\n';
        
        String csvPaiements = 'Nom,Bail,DatePaiement,MoisConcerne,AnneeConcernee,MontantLoyer,MontantCharges,Statut,MoyenPaiement,DateEncaissement,QuittanceGeneree,Notes\n' +
                           'Paiement Test,Bail Test,05/01/2023,Janvier,2023,800,100,Encaissé,Virement,07/01/2023,false,Test\n';
        
        String csvDepenses = 'Nom,BienLocatif,DateDepense,Nature,Montant,Recuperable,AnneeFiscale,Description\n' +
                          'Depense Test,Bien Test,15/01/2023,Taxe foncière,1200,false,2023,Test\n';
        
        // Désactiver les triggers
        Triggers.bypass('PaiementTrigger');
        Triggers.bypass('BailTrigger');
        Triggers.bypass('DepenseTrigger');

        // Exécuter la méthode à tester
        Test.startTest();
        ImportDonneesHistoriques.ImportResult result = ImportDonneesHistoriques.importerDonnees(
            csvBiens, csvLocataires, csvBaux, csvPaiements, csvDepenses
        );
        Test.stopTest();

        // Réactiver les triggers
        Triggers.clearBypass('PaiementTrigger');
        Triggers.clearBypass('BailTrigger');
        Triggers.clearBypass('DepenseTrigger');
        
        // Vérifier que l'importation a réussi
        System.assertEquals(true, result.success, 'L\'importation a échoué : ' + result.message);
        
        // Vérifier que les données ont été importées
        System.assertEquals(1, result.biensImportes, 'Le nombre de biens importés est incorrect');
        System.assertEquals(1, result.locatairesImportes, 'Le nombre de locataires importés est incorrect');
        System.assertEquals(1, result.bauxImportes, 'Le nombre de baux importés est incorrect');
        System.assertEquals(1, result.paiementsImportes, 'Le nombre de paiements importés est incorrect');
        System.assertEquals(1, result.depensesImportees, 'Le nombre de dépenses importées est incorrect');
        
        // Vérifier que les données sont correctement liées
        List<Bien_Locatif__c> biens = [SELECT Id, Name FROM Bien_Locatif__c WHERE Name = 'Bien Test'];
        System.assertEquals(1, biens.size(), 'Le bien n\'a pas été importé');
        
        List<Locataire__c> locataires = [SELECT Id, Name FROM Locataire__c WHERE Name = 'Locataire Test'];
        System.assertEquals(1, locataires.size(), 'Le locataire n\'a pas été importé');
        
        List<Bail__c> baux = [SELECT Id, Name, Bien_Locatif__c, Locataire__c FROM Bail__c WHERE Name = 'Bail Test'];
        System.assertEquals(1, baux.size(), 'Le bail n\'a pas été importé');
        System.assertEquals(biens[0].Id, baux[0].Bien_Locatif__c, 'Le bail n\'est pas lié au bon bien');
        System.assertEquals(locataires[0].Id, baux[0].Locataire__c, 'Le bail n\'est pas lié au bon locataire');
        
        List<Paiement__c> paiements = [SELECT Id, Bail__c FROM Paiement__c WHERE Mois_Concerne__c = 'Janvier' AND Annee_Concernee__c = '2023'];
        System.assertEquals(1, paiements.size(), 'Le paiement n\'a pas été importé');
        System.assertEquals(baux[0].Id, paiements[0].Bail__c, 'Le paiement n\'est pas lié au bon bail');
        
        List<Depense__c> depenses = [SELECT Id, Bien_Locatif__c FROM Depense__c WHERE Nature__c = 'Taxe foncière'];
        System.assertEquals(1, depenses.size(), 'La dépense n\'a pas été importée');
        System.assertEquals(biens[0].Id, depenses[0].Bien_Locatif__c, 'La dépense n\'est pas liée au bon bien');
        
        // Vérifier que le rendement a été calculé
        List<Rendement__c> rendements = [SELECT Id FROM Rendement__c WHERE Bien_Locatif__c = :biens[0].Id AND Annee__c = '2023'];
        System.assertEquals(1, rendements.size(), 'Le rendement n\'a pas été calculé');
    }
    
    /**
     * Test de l'importation avec des données invalides
     */
    @isTest
    static void testImporterDonneesInvalides() {
        // Préparer des données CSV invalides (références inexistantes)
        String csvBiens = 'Nom,Type,Adresse,CodePostal,Ville,Surface,NombrePieces,Etage,DateAcquisition,PrixAcquisition,Statut,Notes\n' +
                         'Bien Test,Appartement,123 Rue de Test,75000,Paris,50,2,2,01/01/2023,200000,Vacant,Test\n';
        
        String csvLocataires = 'Nom,Nom,Prenom,Email,Telephone,AdresseCorrespondance,DateNaissance,SituationProfessionnelle,RevenuMensuel,Notes\n' +
                             'Locataire Test,Dupont,Jean,test@example.com,0123456789,123 Rue de Test 75000 Paris,01/01/1980,Salarié,3000,Test\n';
        
        // Bail avec référence à un bien inexistant
        String csvBaux = 'Nom,BienLocatif,Locataire,DateDebut,DateFin,MontantLoyer,MontantCharges,DepotGarantie,Statut,TypeBail,PeriodicitePaiement,JourPaiement,DateDerniereRevision,DateResiliation,DureePreavis\n' +
                       'Bail Test,Bien Inexistant,Locataire Test,01/01/2023,31/12/2025,800,100,1600,Actif,Habitation,Mensuel,5,,,\n';
        
        // Paiement avec référence à un bail inexistant
        String csvPaiements = 'Nom,Bail,DatePaiement,MoisConcerne,AnneeConcernee,MontantLoyer,MontantCharges,Statut,MoyenPaiement,DateEncaissement,QuittanceGeneree,Notes\n' +
                           'Paiement Test,Bail Inexistant,05/01/2023,Janvier,2023,800,100,Encaissé,Virement,07/01/2023,false,Test\n';
        
        // Dépense avec référence à un bien inexistant
        String csvDepenses = 'Nom,BienLocatif,DateDepense,Nature,Montant,Recuperable,AnneeFiscale,Description\n' +
                          'Depense Test,Bien Inexistant,15/01/2023,Taxe foncière,1200,false,2023,Test\n';
        
        // Exécuter la méthode à tester
        Test.startTest();
        ImportDonneesHistoriques.ImportResult result = ImportDonneesHistoriques.importerDonnees(
            csvBiens, csvLocataires, csvBaux, csvPaiements, csvDepenses
        );
        Test.stopTest();
        
        // Vérifier que l'importation a réussi malgré les références invalides
        // (les enregistrements avec références invalides sont simplement ignorés)
        System.assertEquals(true, result.success, 'L\'importation a échoué : ' + result.message);
        
        // Vérifier que seuls les biens et locataires ont été importés
        System.assertEquals(1, result.biensImportes, 'Le nombre de biens importés est incorrect');
        System.assertEquals(1, result.locatairesImportes, 'Le nombre de locataires importés est incorrect');
        System.assertEquals(0, result.bauxImportes, 'Des baux avec références invalides ont été importés');
        System.assertEquals(0, result.paiementsImportes, 'Des paiements avec références invalides ont été importés');
        System.assertEquals(0, result.depensesImportees, 'Des dépenses avec références invalides ont été importées');
    }
    
    /**
     * Test de la classe utilitaire Triggers
     */
    @isTest
    static void testTriggersUtility() {
        // Tester les méthodes de la classe Triggers
        Test.startTest();
        
        // Vérifier qu'aucun trigger n'est initialement bypassé
        System.assertEquals(false, Triggers.isBypassed('TestTrigger'), 'Le trigger ne devrait pas être bypassé initialement');
        
        // Bypasser un trigger
        Triggers.bypass('TestTrigger');
        System.assertEquals(true, Triggers.isBypassed('TestTrigger'), 'Le trigger devrait être bypassé');
        
        // Annuler le bypass
        Triggers.clearBypass('TestTrigger');
        System.assertEquals(false, Triggers.isBypassed('TestTrigger'), 'Le bypass du trigger devrait être annulé');
        
        Test.stopTest();
    }
    
    /**
     * Test de la méthode parseCsvLine
     */
    @isTest
    static void testParseCsvLine() {
        // Tester la méthode parseCsvLine avec différents formats de ligne CSV
        Test.startTest();
        
        // Ligne simple
        String ligne1 = 'valeur1,valeur2,valeur3';
        List<String> champs1 = ImportDonneesHistoriques.parseCsvLine(ligne1);
        System.assertEquals(3, champs1.size(), 'Le nombre de champs est incorrect');
        System.assertEquals('valeur1', champs1[0], 'Le premier champ est incorrect');
        System.assertEquals('valeur2', champs1[1], 'Le deuxième champ est incorrect');
        System.assertEquals('valeur3', champs1[2], 'Le troisième champ est incorrect');
        
        // Ligne avec guillemets
        String ligne2 = 'valeur1,"valeur2 avec, virgule",valeur3';
        List<String> champs2 = ImportDonneesHistoriques.parseCsvLine(ligne2);
        System.assertEquals(3, champs2.size(), 'Le nombre de champs est incorrect');
        System.assertEquals('valeur1', champs2[0], 'Le premier champ est incorrect');
        System.assertEquals('"valeur2 avec, virgule"', champs2[1], 'Le deuxième champ est incorrect');
        System.assertEquals('valeur3', champs2[2], 'Le troisième champ est incorrect');
        
        Test.stopTest();
    }
}
