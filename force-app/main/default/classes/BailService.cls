/**
 * @description Classe utilitaire pour la gestion des baux et alertes de fin de bail
 * @author Manus
 * @date Avril 2025
 */
public with sharing class BailService {
    
    /**
     * Met à jour le statut d'un bien en fonction des baux actifs
     * @param bienId ID du bien locatif
     * @return Statut mis à jour du bien
     */
    public static String mettreAJourStatutBien(Id bienId) {
        // Récupération du bien
        Bien_Locatif__c bien = [
            SELECT Id, Statut__c
            FROM Bien_Locatif__c 
            WHERE Id = :bienId
        ];
        
        // Recherche de baux actifs pour ce bien
        List<Bail__c> bauxActifs = [
            SELECT Id
            FROM Bail__c
            WHERE Bien_Locatif__c = :bienId
            AND Statut__c = 'Actif'
        ];
        
        // Mise à jour du statut du bien
        String nouveauStatut;
        if (!bauxActifs.isEmpty()) {
            nouveauStatut = 'Loué';
        } else {
            // Recherche de baux en préavis
            List<Bail__c> bauxPrevis = [
                SELECT Id
                FROM Bail__c
                WHERE Bien_Locatif__c = :bienId
                AND Statut__c = 'En préavis'
            ];
            
            if (!bauxPrevis.isEmpty()) {
                nouveauStatut = 'Loué'; // Toujours considéré comme loué pendant le préavis
            } else {
                nouveauStatut = 'Vacant';
            }
        }
        
        // Mise à jour du bien si le statut a changé
        if (bien.Statut__c != nouveauStatut) {
            bien.Statut__c = nouveauStatut;
            update bien;
        }
        
        return nouveauStatut;
    }
    
    /**
     * Identifie les baux qui arrivent à échéance dans un nombre de jours donné
     * @param joursAvantEcheance Nombre de jours avant l'échéance
     * @return Liste des baux qui arrivent à échéance
     */
    public static List<Bail__c> identifierBauxEnFinEcheance(Integer joursAvantEcheance) {
        Date dateReference = Date.today().addDays(joursAvantEcheance);
        
        return [
            SELECT Id, Name, Bien_Locatif__r.Name, Locataire__r.Name, 
                   Date_Debut__c, Date_Fin__c, Montant_Loyer__c, Montant_Charges__c
            FROM Bail__c
            WHERE Date_Fin__c = :dateReference
            AND Statut__c = 'Actif'
        ];
    }
    
    /**
     * Envoie des alertes pour les baux qui arrivent à échéance
     * @param joursAvantEcheance Nombre de jours avant l'échéance
     * @return Nombre d'alertes envoyées
     */
    public static Integer envoyerAlertesFinBail(Integer joursAvantEcheance) {
        List<Bail__c> bauxEnFinEcheance = identifierBauxEnFinEcheance(joursAvantEcheance);
        
        if (bauxEnFinEcheance.isEmpty()) {
            return 0;
        }
        
        // Préparation des emails d'alerte
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // Récupération de l'adresse email de l'utilisateur actuel
        User utilisateurActuel = [
            SELECT Email
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        
        for (Bail__c bail : bauxEnFinEcheance) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { utilisateurActuel.Email });
            email.setSubject('Alerte : Fin de bail dans ' + joursAvantEcheance + ' jours - ' + bail.Bien_Locatif__r.Name);
            
            String corps = 'Bonjour,\n\n';
            corps += 'Le bail suivant arrive à échéance dans ' + joursAvantEcheance + ' jours :\n\n';
            corps += 'Référence du bail : ' + bail.Name + '\n';
            corps += 'Bien : ' + bail.Bien_Locatif__r.Name + '\n';
            corps += 'Locataire : ' + bail.Locataire__r.Name + '\n';
            corps += 'Date de début : ' + formatDateFrancais(bail.Date_Debut__c) + '\n';
            corps += 'Date de fin : ' + formatDateFrancais(bail.Date_Fin__c) + '\n';
            corps += 'Loyer : ' + bail.Montant_Loyer__c + ' €\n';
            corps += 'Charges : ' + bail.Montant_Charges__c + ' €\n\n';
            corps += 'Veuillez contacter le locataire pour discuter du renouvellement du bail.\n\n';
            corps += 'Cordialement,\n';
            corps += 'Votre application Gestion Locative';
            
            email.setPlainTextBody(corps);
            emails.add(email);
        }
        
        // Envoi des emails
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
        
        return emails.size();
    }
    
    /**
     * Résilie un bail
     * @param bailId ID du bail à résilier
     * @param dateResiliation Date de résiliation
     * @param dureePreavis Durée du préavis en mois
     * @return true si la résiliation a réussi, false sinon
     */
    public static Boolean resilierBail(Id bailId, Date dateResiliation, Integer dureePreavis) {
        // Récupération du bail
        Bail__c bail = [
            SELECT Id, Bien_Locatif__c, Statut__c
            FROM Bail__c
            WHERE Id = :bailId
        ];
        
        // Vérification que le bail est actif
        if (bail.Statut__c != 'Actif') {
            throw new BailServiceException('Impossible de résilier un bail qui n\'est pas actif.');
        }
        
        // Mise à jour du bail
        bail.Statut__c = 'En préavis';
        bail.Date_Resiliation__c = dateResiliation;
        bail.Duree_Preavis__c = dureePreavis;
        bail.Date_Fin__c = dateResiliation.addMonths(dureePreavis);
        
        update bail;
        
        return true;
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
     * Classe d'exception personnalisée pour le service de bail
     */
    public class BailServiceException extends Exception {}

    /**
     * Vérifie les fins de bail dans un nombre de jours donné.
     * @param joursAvantEcheance Nombre de jours avant l'échéance.
     * @return Liste des baux à échéance.
     */
    public static List<Bail__c> verifierFinsBail(Integer joursAvantEcheance) {
        Date dateReference = Date.today().addDays(joursAvantEcheance);
        return [
            SELECT Id, Name, Date_Fin__c
            FROM Bail__c
            WHERE Date_Fin__c <= :dateReference
            AND Statut__c = 'Actif'
        ];
    }

    /**
     * Renouvelle un bail pour une durée donnée.
     * @param bailId ID du bail à renouveler.
     * @param dureeRenouvellement Durée du renouvellement en années.
     */
    public static void renouvelerBail(Id bailId, Integer dureeRenouvellement) {
        Bail__c bail = [
            SELECT Id, Date_Fin__c
            FROM Bail__c
            WHERE Id = :bailId
        ];
        bail.Date_Fin__c = bail.Date_Fin__c.addYears(dureeRenouvellement);
        update bail;
    }

    /**
     * Calcule le rendement pour un bien locatif et une année donnée.
     * @param bienId ID du bien locatif.
     * @param annee Année fiscale pour laquelle calculer le rendement.
     */
    public static void calculerRendement(Id bienId, String annee) {
        // Implémentez la logique pour calculer le rendement
        System.debug('Calcul du rendement pour le bien ' + bienId + ' et l\'année ' + annee);
        
        // Exemple de logique (à adapter selon vos besoins)
        Rendement__c rendement = [
            SELECT Id, Total_Loyers__c, Total_Charges_Percues__c, Total_Depenses__c
            FROM Rendement__c
            WHERE Bien_Locatif__c = :bienId AND Annee__c = :annee
            LIMIT 1
        ];
        
        if (rendement != null) {
            // Exemple de calcul de rendement brut et net
            Decimal rendementBrut = (rendement.Total_Loyers__c + rendement.Total_Charges_Percues__c) / rendement.Total_Depenses__c * 100;
            Decimal rendementNet = rendementBrut - 5; // Exemple de déduction
            
            rendement.Rendement_Brut__c = rendementBrut;
            rendement.Rendement_Net__c = rendementNet;
            update rendement;
        } else {
            System.debug('Aucun rendement trouvé pour le bien ' + bienId + ' et l\'année ' + annee);
        }
    }

    /**
     * Récupère la liste des baux avec leurs détails
     * @param statutFiltre Statut optionnel pour filtrer les baux
     * @return Liste des baux formatée pour l'affichage
     */
    @AuraEnabled(cacheable=true)
    public static List<BailWrapper> getBaux(String statutFiltre) {
        List<BailWrapper> baux = new List<BailWrapper>();
        
        String query = 'SELECT Id, Name, Bien_Locatif__r.Name, Locataire__r.Name, ' +
                      'Date_Debut__c, Date_Fin__c, Montant_Loyer__c, Montant_Charges__c, ' +
                      'Statut__c ' +
                      'FROM Bail__c ';
        
        if (String.isNotBlank(statutFiltre)) {
            query += 'WHERE Statut__c = :statutFiltre ';
        }
        
        query += 'ORDER BY Date_Fin__c ASC';
        
        for (Bail__c bail : Database.query(query)) {
            baux.add(new BailWrapper(bail));
        }
        
        return baux;
    }

    /**
     * Classe wrapper pour les baux
     */
    public class BailWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String bien;
        @AuraEnabled public String locataire;
        @AuraEnabled public Date dateDebut;
        @AuraEnabled public Date dateFin;
        @AuraEnabled public Decimal loyer;
        @AuraEnabled public Decimal charges;
        @AuraEnabled public Decimal total;
        @AuraEnabled public String statut;
        @AuraEnabled public String classeStatut;
        @AuraEnabled public String classeDateFin;
        
        public BailWrapper(Bail__c bail) {
            this.id = bail.Id;
            this.bien = bail.Bien_Locatif__r.Name;
            this.locataire = bail.Locataire__r.Name;
            this.dateDebut = bail.Date_Debut__c;
            this.dateFin = bail.Date_Fin__c;
            this.loyer = bail.Montant_Loyer__c;
            this.charges = bail.Montant_Charges__c;
            this.total = (this.loyer != null ? this.loyer : 0) + (this.charges != null ? this.charges : 0);
            this.statut = bail.Statut__c;
            
            // Définir les classes CSS en fonction du statut
            this.classeStatut = getClasseStatut(bail.Statut__c);
            this.classeDateFin = getClasseDateFin(bail.Date_Fin__c);
        }
        
        private String getClasseStatut(String statut) {
            switch on statut {
                when 'Actif' { return 'slds-text-color_success'; }
                when 'En préavis' { return 'slds-text-color_warning'; }
                when 'Résilié' { return 'slds-text-color_error'; }
                when else { return ''; }
            }
        }
        
        private String getClasseDateFin(Date dateFin) {
            if (dateFin == null) return '';
            
            Integer joursRestants = Date.today().daysBetween(dateFin);
            if (joursRestants < 30) {
                return 'slds-text-color_error slds-theme_alert-texture';
            } else if (joursRestants < 90) {
                return 'slds-text-color_warning';
            }
            return '';
        }
    }
}
