/**
 * @description Script d'importation des données historiques depuis les fichiers Excel
 * @author Manus
 * @date Avril 2025
 */
public class ImportDonneesHistoriques {
    
    /**
     * Méthode principale pour importer toutes les données historiques
     * @param csvBiens Contenu CSV des biens locatifs
     * @param csvLocataires Contenu CSV des locataires
     * @param csvBaux Contenu CSV des baux
     * @param csvPaiements Contenu CSV des paiements
     * @param csvDepenses Contenu CSV des dépenses
     * @return Résultat de l'importation
     */
    public static ImportResult importerDonnees(String csvBiens, String csvLocataires, String csvBaux, String csvPaiements, String csvDepenses) {
        ImportResult result = new ImportResult();
        
        try {
            // Désactiver les triggers pendant l'importation
            Triggers.bypass('PaiementTrigger');
            Triggers.bypass('BailTrigger');
            Triggers.bypass('DepenseTrigger');
            
            // Importer les données dans l'ordre des dépendances
            Map<String, Id> mapBiens = importerBiens(csvBiens, result);
            Map<String, Id> mapLocataires = importerLocataires(csvLocataires, result);
            Map<String, Id> mapBaux = importerBaux(csvBaux, mapBiens, mapLocataires, result);
            importerPaiements(csvPaiements, mapBaux, result);
            importerDepenses(csvDepenses, mapBiens, result);
            
            // Réactiver les triggers
            Triggers.clearBypass('PaiementTrigger');
            Triggers.clearBypass('BailTrigger');
            Triggers.clearBypass('DepenseTrigger');
            
            // Recalculer les rendements pour tous les biens
            recalculerRendements(mapBiens.values());
            
            result.success = true;
            result.message = 'Importation réussie. ' + 
                             result.biensImportes + ' biens, ' + 
                             result.locatairesImportes + ' locataires, ' + 
                             result.bauxImportes + ' baux, ' + 
                             result.paiementsImportes + ' paiements et ' + 
                             result.depensesImportees + ' dépenses ont été importés.';
        } catch (Exception e) {
            result.success = false;
            result.message = 'Erreur lors de l\'importation : ' + e.getMessage();
            System.debug('Erreur lors de l\'importation : ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * Importe les biens locatifs
     * @param csvContent Contenu CSV des biens
     * @param result Résultat de l'importation
     * @return Map des identifiants externes vers les IDs Salesforce
     */
    private static Map<String, Id> importerBiens(String csvContent, ImportResult result) {
        Map<String, Id> mapBiens = new Map<String, Id>();
        List<Bien_Locatif__c> biensAInserer = new List<Bien_Locatif__c>();
        
        List<String> lines = csvContent.split('\n');
        // Ignorer la ligne d'en-tête
        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i];
            if (String.isBlank(line)) continue;
            
            List<String> fields = parseCsvLine(line);
            
            // Créer le bien locatif
            Bien_Locatif__c bien = new Bien_Locatif__c(
                Name = fields[0],
                Type__c = fields[1],
                Adresse__c = fields[2],
                Code_Postal__c = fields[3],
                Ville__c = fields[4],
                Surface__c = fields[5] != '' ? Decimal.valueOf(fields[5]) : null,
                Nombre_Pieces__c = fields[6] != '' ? Decimal.valueOf(fields[6]) : null,
                Etage__c = fields[7],
                Date_Acquisition__c = fields[8] != '' ? Date.parse(fields[8]) : null,
                Prix_Acquisition__c = fields[9] != '' ? Decimal.valueOf(fields[9]) : null,
                Statut__c = fields[10],
                Notes__c = fields[11]
            );
            
            biensAInserer.add(bien);
        }
        
        if (!biensAInserer.isEmpty()) {
            insert biensAInserer;
            result.biensImportes = biensAInserer.size();
            
            // Construire le map des identifiants
            for (Bien_Locatif__c bien : biensAInserer) {
                mapBiens.put(bien.Name, bien.Id);
            }
        }
        
        return mapBiens;
    }
    
    /**
     * Importe les locataires
     * @param csvContent Contenu CSV des locataires
     * @param result Résultat de l'importation
     * @return Map des identifiants externes vers les IDs Salesforce
     */
    private static Map<String, Id> importerLocataires(String csvContent, ImportResult result) {
        Map<String, Id> mapLocataires = new Map<String, Id>();
        List<Locataire__c> locatairesAInserer = new List<Locataire__c>();
        
        List<String> lines = csvContent.split('\n');
        // Ignorer la ligne d'en-tête
        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i];
            if (String.isBlank(line)) continue;
            
            List<String> fields = parseCsvLine(line);
            
            // Créer le locataire
            Locataire__c locataire = new Locataire__c(
                Name = fields[0],
                Nom__c = fields[1],
                Prenom__c = fields[2],
                Email__c = fields[3],
                Telephone__c = fields[4],
                Adresse_Correspondance__c = fields[5],
                Date_Naissance__c = fields[6] != '' ? Date.parse(fields[6]) : null,
                Situation_Professionnelle__c = fields[7],
                Revenu_Mensuel__c = fields[8] != '' ? Decimal.valueOf(fields[8]) : null,
                Notes__c = fields[9]
            );
            
            locatairesAInserer.add(locataire);
        }
        
        if (!locatairesAInserer.isEmpty()) {
            insert locatairesAInserer;
            result.locatairesImportes = locatairesAInserer.size();
            
            // Construire le map des identifiants
            for (Locataire__c locataire : locatairesAInserer) {
                mapLocataires.put(locataire.Name, locataire.Id);
            }
        }
        
        return mapLocataires;
    }
    
    /**
     * Importe les baux
     * @param csvContent Contenu CSV des baux
     * @param mapBiens Map des identifiants externes des biens vers les IDs Salesforce
     * @param mapLocataires Map des identifiants externes des locataires vers les IDs Salesforce
     * @param result Résultat de l'importation
     * @return Map des identifiants externes vers les IDs Salesforce
     */
    private static Map<String, Id> importerBaux(String csvContent, Map<String, Id> mapBiens, Map<String, Id> mapLocataires, ImportResult result) {
        Map<String, Id> mapBaux = new Map<String, Id>();
        List<Bail__c> bauxAInserer = new List<Bail__c>();
        
        List<String> lines = csvContent.split('\n');
        // Ignorer la ligne d'en-tête
        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i];
            if (String.isBlank(line)) continue;
            
            List<String> fields = parseCsvLine(line);
            
            // Vérifier que les références existent
            if (!mapBiens.containsKey(fields[1]) || !mapLocataires.containsKey(fields[2])) {
                System.debug('Référence manquante pour le bail : ' + fields[0] + ', Bien : ' + fields[1] + ', Locataire : ' + fields[2]);
                continue;
            }
            
            // Créer le bail
            Bail__c bail = new Bail__c(
                Bien_Locatif__c = mapBiens.get(fields[1]),
                Locataire__c = mapLocataires.get(fields[2]),
                Date_Debut__c = fields[3] != '' ? Date.parse(fields[3]) : null,
                Date_Fin__c = fields[4] != '' ? Date.parse(fields[4]) : null,
                Montant_Loyer__c = fields[5] != '' ? Decimal.valueOf(fields[5]) : null,
                Montant_Charges__c = fields[6] != '' ? Decimal.valueOf(fields[6]) : null,
                Depot_Garantie__c = fields[7] != '' ? Decimal.valueOf(fields[7]) : null,
                Statut__c = fields[8],
                Type_Bail__c = fields[9],
                Periodicite_Paiement__c = fields[10],
                Jour_Paiement__c = fields[11] != '' ? Integer.valueOf(fields[11]) : null,
                Date_Derniere_Revision__c = fields[12] != '' ? Date.parse(fields[12]) : null,
                Date_Resiliation__c = fields[13] != '' ? Date.parse(fields[13]) : null,
                Duree_Preavis__c = fields[14] != '' ? Integer.valueOf(fields[14]) : null
            );
            
            bauxAInserer.add(bail);
        }
        
        if (!bauxAInserer.isEmpty()) {
            insert bauxAInserer;
            result.bauxImportes = bauxAInserer.size();
            
            // Construire le map des identifiants
            for (Bail__c bail : bauxAInserer) {
                mapBaux.put(bail.Name, bail.Id);
            }
        }
        
        return mapBaux;
    }
    
    /**
     * Importe les paiements
     * @param csvContent Contenu CSV des paiements
     * @param mapBaux Map des identifiants externes des baux vers les IDs Salesforce
     * @param result Résultat de l'importation
     */
    private static void importerPaiements(String csvContent, Map<String, Id> mapBaux, ImportResult result) {
        List<Paiement__c> paiementsAInserer = new List<Paiement__c>();
        
        List<String> lines = csvContent.split('\n');
        // Ignorer la ligne d'en-tête
        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i];
            if (String.isBlank(line)) continue;
            
            List<String> fields = parseCsvLine(line);
            
            // Vérifier que la référence existe
            if (!mapBaux.containsKey(fields[1])) {
                System.debug('Référence manquante pour le paiement : ' + fields[0] + ', Bail : ' + fields[1]);
                continue;
            }
            
            // Créer le paiement
            Paiement__c paiement = new Paiement__c(
                Bail__c = mapBaux.get(fields[1]),
                Date_Paiement__c = fields[2] != '' ? Date.parse(fields[2]) : null,
                Montant_Loyer__c = fields[5] != '' ? Decimal.valueOf(fields[5]) : null,
                Montant_Charges__c = fields[6] != '' ? Decimal.valueOf(fields[6]) : null,
                Statut__c = fields[7],
                Moyen_Paiement__c = fields[8],
                Date_Encaissement__c = fields[9] != '' ? Date.parse(fields[9]) : null,
                Quittance_Generee__c = fields[10] == 'true',
                Notes__c = fields[11]
            );
            
            paiementsAInserer.add(paiement);
        }
        
        if (!paiementsAInserer.isEmpty()) {
            insert paiementsAInserer;
            result.paiementsImportes = paiementsAInserer.size();
        }
    }
    
    /**
     * Importe les dépenses
     * @param csvContent Contenu CSV des dépenses
     * @param mapBiens Map des identifiants externes des biens vers les IDs Salesforce
     * @param result Résultat de l'importation
     */
    private static void importerDepenses(String csvContent, Map<String, Id> mapBiens, ImportResult result) {
        List<Depense__c> depensesAInserer = new List<Depense__c>();
        
        List<String> lines = csvContent.split('\n');
        // Ignorer la ligne d'en-tête
        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i];
            if (String.isBlank(line)) continue;
            
            List<String> fields = parseCsvLine(line);
            
            // Vérifier que la référence existe
            if (!mapBiens.containsKey(fields[1])) {
                System.debug('Référence manquante pour la dépense : ' + fields[0] + ', Bien : ' + fields[1]);
                continue;
            }
            
            // Créer la dépense
            Depense__c depense = new Depense__c(
                Bien_Locatif__c = mapBiens.get(fields[1]),
                Date_Depense__c = fields[2] != '' ? Date.parse(fields[2]) : null,
                Nature__c = fields[3],
                Montant__c = fields[4] != '' ? Decimal.valueOf(fields[4]) : null,
                Recuperable__c = fields[5] == 'true',
                Description__c = fields[7]
            );
            
            depensesAInserer.add(depense);
        }
        
        if (!depensesAInserer.isEmpty()) {
            insert depensesAInserer;
            result.depensesImportees = depensesAInserer.size();
        }
    }
    
    /**
     * Recalcule les rendements pour tous les biens
     * @param bienIds Liste des IDs des biens
     */
    private static void recalculerRendements(List<Id> bienIds) {
        Set<String> annees = new Set<String>();
        for (Integer annee = 2018; annee <= Date.today().year(); annee++) {
            annees.add(String.valueOf(annee));
        }
        
        for (Id bienId : bienIds) {
            for (String annee : annees) {
                try {
                    RendementService.calculerRendement(bienId, annee);
                } catch (Exception e) {
                    System.debug('Erreur lors du calcul du rendement pour le bien ' + bienId + ' et l\'année ' + annee + ' : ' + e.getMessage());
                }
            }
        }
    }
    
    /**
     * Parse une ligne CSV en tenant compte des guillemets
     * @param line Ligne CSV à parser
     * @return Liste des champs
     */
    public static List<String> parseCsvLine(String line) {
        List<String> fields = new List<String>();
        Boolean inQuotes = false;
        String field = '';
        
        for (Integer i = 0; i < line.length(); i++) {
            String c = line.substring(i, i + 1);
            
            if (c == '"') {
                inQuotes = !inQuotes;
            } else if (c == ',' && !inQuotes) {
                fields.add(field);
                field = '';
            } else {
                field += c;
            }
        }
        
        fields.add(field);
        return fields;
    }
    
    /**
     * Classe pour stocker le résultat de l'importation
     */
    public class ImportResult {
        public Boolean success { get; set; }
        public String message { get; set; }
        public Integer biensImportes { get; set; }
        public Integer locatairesImportes { get; set; }
        public Integer bauxImportes { get; set; }
        public Integer paiementsImportes { get; set; }
        public Integer depensesImportees { get; set; }
        
        public ImportResult() {
            this.success = false;
            this.message = '';
            this.biensImportes = 0;
            this.locatairesImportes = 0;
            this.bauxImportes = 0;
            this.paiementsImportes = 0;
            this.depensesImportees = 0;
        }
    }
}
