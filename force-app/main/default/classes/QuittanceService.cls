/**
 * @description Classe utilitaire pour la génération et l'envoi de quittances de loyer
 * @author Manus
 * @date Avril 2025
 */
public with sharing class QuittanceService {
    
    /**
     * Génère une quittance de loyer à partir d'un paiement
     * @param paiementId ID du paiement pour lequel générer la quittance
     * @return ID de la quittance générée
     */
    public static Id genererQuittance(Id paiementId) {
        // Récupération du paiement
        Paiement__c paiement = [
            SELECT Id, Bail__c, Bail__r.Bien_Locatif__c, Bail__r.Locataire__c, 
                   Montant_Loyer__c, 
                   Montant_Charges__c, 
                   Mois_Concerne__c, 
                   Annee_Concernee__c, Date_Encaissement__c, Statut__c
            FROM Paiement__c 
            WHERE Id = :paiementId
        ];
        
        // Vérification que le paiement est encaissé
        if (paiement.Statut__c != 'Encaissé') {
            throw new QuittanceServiceException('Impossible de générer une quittance pour un paiement non encaissé.');
        }
        
        // Calcul des dates de période
        Date periodeDebut = calculerDateDebut(paiement.Mois_Concerne__c, paiement.Annee_Concernee__c);
        Date periodeFin = calculerDateFin(paiement.Mois_Concerne__c, paiement.Annee_Concernee__c);
        
        // Création de la quittance
        Quittance__c quittance = new Quittance__c(
            Paiement__c = paiement.Id,
            Date_Generation__c = Date.today(),
            Periode_Debut__c = periodeDebut,
            Periode_Fin__c = periodeFin,
            Montant_Loyer__c = paiement.Montant_Loyer__c,
            Montant_Charges__c = paiement.Montant_Charges__c,
            Statut_Envoi__c = 'Non envoyée'
        );
        
        insert quittance;
        
        // Mise à jour du paiement
        paiement.Quittance_Generee__c = true;
        update paiement;
        
        return quittance.Id;
    }
    
    /**
     * Envoie une quittance par email
     * @param quittanceId ID de la quittance à envoyer
     * @param emailDestinataire Email du destinataire
     * @return true si l'envoi a réussi, false sinon
     */
    public static Boolean envoyerQuittanceParEmail(Id quittanceId, String emailDestinataire) {
        // Récupération de la quittance
        Quittance__c quittance = [
            SELECT Id, Paiement__r.Bail__r.Locataire__r.Name, 
                   Paiement__r.Bail__r.Bien_Locatif__r.Name,
                   Periode_Debut__c, Periode_Fin__c, 
                   Montant_Loyer__c, Montant_Charges__c,
                   Fichier_PDF__c
            FROM Quittance__c 
            WHERE Id = :quittanceId
        ];
        
        // Vérification que la quittance a un fichier PDF
        if (quittance.Fichier_PDF__c == null) {
            throw new QuittanceServiceException('Aucun fichier PDF n\'est associé à cette quittance.');
        }
        
        try {
            // Préparation de l'email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { emailDestinataire });
            email.setSubject('Quittance de loyer - ' + 
                             quittance.Paiement__r.Bail__r.Bien_Locatif__r.Name + ' - ' + 
                             formatDateFrancais(quittance.Periode_Debut__c) + ' à ' + 
                             formatDateFrancais(quittance.Periode_Fin__c));
            
            // Corps de l'email
            String corps = 'Bonjour ' + quittance.Paiement__r.Bail__r.Locataire__r.Name + ',\n\n';
            corps += 'Veuillez trouver ci-joint votre quittance de loyer pour la période du ';
            corps += formatDateFrancais(quittance.Periode_Debut__c) + ' au ' + formatDateFrancais(quittance.Periode_Fin__c);
            corps += ' concernant le bien situé à ' + quittance.Paiement__r.Bail__r.Bien_Locatif__r.Name + '.\n\n';
            corps += 'Cordialement,\n';
            corps += 'Votre gestionnaire locatif';
            
            email.setPlainTextBody(corps);
            
            // Envoi de l'email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
            // Mise à jour de la quittance
            quittance.Statut_Envoi__c = 'Envoyée par email';
            quittance.Date_Envoi__c = Datetime.now();
            update quittance;
            
            return true;
        } catch (Exception e) {
            throw new QuittanceServiceException('Erreur lors de l\'envoi de l\'email : ' + e.getMessage());
        }
    }
    
    /**
     * Calcule la date de début de période pour un mois et une année donnés
     * @param mois Mois concerné
     * @param annee Année concernée
     * @return Date de début de période
     */
    private static Date calculerDateDebut(String mois, String annee) {
        Integer anneeInt = Integer.valueOf(annee);
        Integer moisInt = getMoisInt(mois);
        return Date.newInstance(anneeInt, moisInt, 1);
    }
    
    /**
     * Calcule la date de fin de période pour un mois et une année donnés
     * @param mois Mois concerné
     * @param annee Année concernée
     * @return Date de fin de période
     */
    private static Date calculerDateFin(String mois, String annee) {
        Integer anneeInt = Integer.valueOf(annee);
        Integer moisInt = getMoisInt(mois);
        
        // Calcul du dernier jour du mois
        Date premierJourMois = Date.newInstance(anneeInt, moisInt, 1);
        Date premierJourMoisSuivant;
        
        if (moisInt == 12) {
            premierJourMoisSuivant = Date.newInstance(anneeInt + 1, 1, 1);
        } else {
            premierJourMoisSuivant = Date.newInstance(anneeInt, moisInt + 1, 1);
        }
        
        return premierJourMoisSuivant.addDays(-1);
    }
    
    /**
     * Convertit un nom de mois en français en numéro de mois
     * @param mois Nom du mois en français
     * @return Numéro du mois (1-12)
     */
    private static Integer getMoisInt(String mois) {
        Map<String, Integer> moisMap = new Map<String, Integer>{
            'Janvier' => 1,
            'Février' => 2,
            'Mars' => 3,
            'Avril' => 4,
            'Mai' => 5,
            'Juin' => 6,
            'Juillet' => 7,
            'Août' => 8,
            'Septembre' => 9,
            'Octobre' => 10,
            'Novembre' => 11,
            'Décembre' => 12
        };
        
        return moisMap.get(mois);
    }
    
    /**
     * Formate une date au format français (JJ/MM/AAAA)
     * @param dateAFormater Date à formater
     * @return Date formatée
     */
    private static String formatDateFrancais(Date dateAFormater) {
        return dateAFormater.day() + '/' + dateAFormater.month() + '/' + dateAFormater.year();
    }
    
    /**
     * Classe d'exception personnalisée pour le service de quittance
     */
    public class QuittanceServiceException extends Exception {}
}
