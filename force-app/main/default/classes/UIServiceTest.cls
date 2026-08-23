/**
 * @description Classe de test pour UIService
 * @author Manus
 * @date Avril 2025
 */
@isTest
private class UIServiceTest {
    
    /**
     * Test de la méthode getClasseCouleurPaiement
     */
    @isTest
    static void testGetClasseCouleurPaiement() {
        // Exécuter la méthode à tester avec différents statuts
        Test.startTest();
        String classeEnAttente = UIService.getClasseCouleurPaiement('En attente');
        String classeEncaisse = UIService.getClasseCouleurPaiement('Encaissé');
        String classeAutre = UIService.getClasseCouleurPaiement('Autre');
        Test.stopTest();
        
        // Vérifier les résultats
        System.assertEquals('slds-text-color_error slds-theme_alert-texture', classeEnAttente, 'La classe CSS pour le statut En attente est incorrecte');
        System.assertEquals('slds-text-color_success', classeEncaisse, 'La classe CSS pour le statut Encaissé est incorrecte');
        System.assertEquals('', classeAutre, 'La classe CSS pour un statut inconnu devrait être vide');
    }
    
    /**
     * Test de la méthode getClasseCouleurBien
     */
    @isTest
    static void testGetClasseCouleurBien() {
        // Exécuter la méthode à tester avec différents statuts
        Test.startTest();
        String classeVacant = UIService.getClasseCouleurBien('Vacant');
        String classeLoue = UIService.getClasseCouleurBien('Loué');
        String classeAutre = UIService.getClasseCouleurBien('Autre');
        Test.stopTest();
        
        // Vérifier les résultats
        System.assertEquals('slds-text-color_error', classeVacant, 'La classe CSS pour le statut Vacant est incorrecte');
        System.assertEquals('slds-text-color_success', classeLoue, 'La classe CSS pour le statut Loué est incorrecte');
        System.assertEquals('', classeAutre, 'La classe CSS pour un statut inconnu devrait être vide');
    }
    
    /**
     * Test de la méthode getClasseCouleurBail
     */
    @isTest
    static void testGetClasseCouleurBail() {
        // Exécuter la méthode à tester avec différents statuts
        Test.startTest();
        String classeActif = UIService.getClasseCouleurBail('Actif');
        String classePrevis = UIService.getClasseCouleurBail('En préavis');
        String classeResilie = UIService.getClasseCouleurBail('Résilié');
        String classeAutre = UIService.getClasseCouleurBail('Autre');
        Test.stopTest();
        
        // Vérifier les résultats
        System.assertEquals('slds-text-color_success', classeActif, 'La classe CSS pour le statut Actif est incorrecte');
        System.assertEquals('slds-text-color_warning', classePrevis, 'La classe CSS pour le statut En préavis est incorrecte');
        System.assertEquals('slds-text-color_error', classeResilie, 'La classe CSS pour le statut Résilié est incorrecte');
        System.assertEquals('', classeAutre, 'La classe CSS pour un statut inconnu devrait être vide');
    }
    
    /**
     * Test de la méthode getClasseCouleurDateFinBail
     */
    @isTest
    static void testGetClasseCouleurDateFinBail() {
        // Exécuter la méthode à tester avec différentes dates
        Test.startTest();
        String classeProche = UIService.getClasseCouleurDateFinBail(Date.today().addDays(15));
        String classeAttention = UIService.getClasseCouleurDateFinBail(Date.today().addDays(60));
        String classeLointaine = UIService.getClasseCouleurDateFinBail(Date.today().addDays(120));
        String classeNull = UIService.getClasseCouleurDateFinBail(null);
        Test.stopTest();
        
        // Vérifier les résultats
        System.assertEquals('slds-text-color_error slds-theme_alert-texture', classeProche, 'La classe CSS pour une date proche est incorrecte');
        System.assertEquals('slds-text-color_warning', classeAttention, 'La classe CSS pour une date d\'attention est incorrecte');
        System.assertEquals('', classeLointaine, 'La classe CSS pour une date lointaine devrait être vide');
        System.assertEquals('', classeNull, 'La classe CSS pour une date null devrait être vide');
    }
}
