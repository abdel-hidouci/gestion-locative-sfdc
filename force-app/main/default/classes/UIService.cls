/**
 * @description Classe utilitaire pour la gestion des couleurs dans l'interface utilisateur
 * @author Manus
 * @date Avril 2025
 */
public with sharing class UIService {
    
    /**
     * Retourne la classe CSS à utiliser pour un paiement en fonction de son statut
     * @param statut Statut du paiement
     * @return Classe CSS à appliquer
     */
    @AuraEnabled
    public static String getClasseCouleurPaiement(String statut) {
        if (statut == 'En attente') {
            return 'slds-text-color_error slds-theme_alert-texture';
        } else if (statut == 'Encaissé') {
            return 'slds-text-color_success';
        } else {
            return '';
        }
    }
    
    /**
     * Retourne la classe CSS à utiliser pour un bien en fonction de son statut
     * @param statut Statut du bien
     * @return Classe CSS à appliquer
     */
    @AuraEnabled
    public static String getClasseCouleurBien(String statut) {
        if (statut == 'Vacant') {
            return 'slds-text-color_error';
        } else if (statut == 'Loué') {
            return 'slds-text-color_success';
        } else {
            return '';
        }
    }
    
    /**
     * Retourne la classe CSS à utiliser pour un bail en fonction de son statut
     * @param statut Statut du bail
     * @return Classe CSS à appliquer
     */
    @AuraEnabled
    public static String getClasseCouleurBail(String statut) {
        if (statut == 'Actif') {
            return 'slds-text-color_success';
        } else if (statut == 'En préavis') {
            return 'slds-text-color_warning';
        } else if (statut == 'Résilié') {
            return 'slds-text-color_error';
        } else {
            return '';
        }
    }
    
    /**
     * Retourne la classe CSS à utiliser pour une date de fin de bail en fonction de sa proximité
     * @param dateFin Date de fin du bail
     * @return Classe CSS à appliquer
     */
    @AuraEnabled
    public static String getClasseCouleurDateFinBail(Date dateFin) {
        if (dateFin == null) {
            return '';
        }
        
        Integer joursRestants = Date.today().daysBetween(dateFin);
        
        if (joursRestants <= 30) {
            return 'slds-text-color_error slds-theme_alert-texture';
        } else if (joursRestants <= 90) {
            return 'slds-text-color_warning';
        } else {
            return '';
        }
    }
}