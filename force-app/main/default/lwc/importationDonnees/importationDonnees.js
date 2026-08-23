import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import importerDonnees from '@salesforce/apex/ImportDonneesController.importerDonnees';
import genererModeleExcel from '@salesforce/apex/ImportDonneesController.genererModeleExcel';

export default class ImportationDonnees extends LightningElement {
    @track isLoading = false;
    @track etapeActuelle = 1;
    @track fichiersBiens = null;
    @track fichiersLocataires = null;
    @track fichiersBaux = null;
    @track fichiersPaiements = null;
    @track fichiersDepenses = null;
    @track csvBiens = '';
    @track csvLocataires = '';
    @track csvBaux = '';
    @track csvPaiements = '';
    @track csvDepenses = '';
    @track resultatImportation = null;
    
    get etape1Active() {
        return this.etapeActuelle === 1;
    }
    
    get etape2Active() {
        return this.etapeActuelle === 2;
    }
    
    get etape3Active() {
        return this.etapeActuelle === 3;
    }
    
    get etape1Complete() {
        return this.etapeActuelle > 1;
    }
    
    get etape2Complete() {
        return this.etapeActuelle > 2;
    }
    
    get etape3Complete() {
        return this.etapeActuelle > 3;
    }
    
    get fichiersBiensSelectionnes() {
        return this.fichiersBiens !== null;
    }
    
    get fichiersLocatairesSelectionnes() {
        return this.fichiersLocataires !== null;
    }
    
    get fichiersBauxSelectionnes() {
        return this.fichiersBaux !== null;
    }
    
    get fichiersPaiementsSelectionnes() {
        return this.fichiersPaiements !== null;
    }
    
    get fichiersDepensesSelectionnes() {
        return this.fichiersDepenses !== null;
    }
    
    get tousLesFichiersSelectionnes() {
        return this.fichiersBiensSelectionnes && 
               this.fichiersLocatairesSelectionnes && 
               this.fichiersBauxSelectionnes && 
               this.fichiersPaiementsSelectionnes && 
               this.fichiersDepensesSelectionnes;
    }
    
    get disableSuivantButton() {
        return !this.tousLesFichiersSelectionnes;
    }
    
    get importationReussie() {
        return this.resultatImportation && this.resultatImportation.success;
    }
    
    // Getters pour les classes de chemin
    get pathClassEtape1() {
        return this.etape1Active ? 'slds-path__item slds-is-current slds-is-active' 
               : this.etape1Complete ? 'slds-path__item slds-is-complete' 
               : 'slds-path__item';
    }
    
    get pathClassEtape2() {
        return this.etape2Active ? 'slds-path__item slds-is-current slds-is-active' 
               : this.etape2Complete ? 'slds-path__item slds-is-complete' 
               : 'slds-path__item';
    }
    
    get pathClassEtape3() {
        return this.etape3Active ? 'slds-path__item slds-is-current slds-is-active' 
               : this.etape3Complete ? 'slds-path__item slds-is-complete' 
               : 'slds-path__item';
    }
    
    // Add these getters to your component class
    get nomFichierBiens() {
        return this.fichiersBiens && this.fichiersBiens.length > 0 ? this.fichiersBiens[0].name : '';
    }

    get nomFichierLocataires() {
        return this.fichiersLocataires && this.fichiersLocataires.length > 0 ? this.fichiersLocataires[0].name : '';
    }

    get nomFichierBaux() {
        return this.fichiersBaux && this.fichiersBaux.length > 0 ? this.fichiersBaux[0].name : '';
    }

    get nomFichierPaiements() {
        return this.fichiersPaiements && this.fichiersPaiements.length > 0 ? this.fichiersPaiements[0].name : '';
    }

    get nomFichierDepenses() {
        return this.fichiersDepenses && this.fichiersDepenses.length > 0 ? this.fichiersDepenses[0].name : '';
    }
    
    // Gestionnaires d'événements pour les fichiers
    handleFichierBiens(event) {
        this.fichiersBiens = event.target.files;
        this.lireFichierCSV(this.fichiersBiens[0], 'biens');
    }
    
    handleFichierLocataires(event) {
        this.fichiersLocataires = event.target.files;
        this.lireFichierCSV(this.fichiersLocataires[0], 'locataires');
    }
    
    handleFichierBaux(event) {
        this.fichiersBaux = event.target.files;
        this.lireFichierCSV(this.fichiersBaux[0], 'baux');
    }
    
    handleFichierPaiements(event) {
        this.fichiersPaiements = event.target.files;
        this.lireFichierCSV(this.fichiersPaiements[0], 'paiements');
    }
    
    handleFichierDepenses(event) {
        this.fichiersDepenses = event.target.files;
        this.lireFichierCSV(this.fichiersDepenses[0], 'depenses');
    }
    
    // Méthode pour lire le contenu d'un fichier CSV
    lireFichierCSV(file, type) {
        const reader = new FileReader();
        
        reader.onload = () => {
            const contenu = reader.result;
            
            switch (type) {
                case 'biens':
                    this.csvBiens = contenu;
                    break;
                case 'locataires':
                    this.csvLocataires = contenu;
                    break;
                case 'baux':
                    this.csvBaux = contenu;
                    break;
                case 'paiements':
                    this.csvPaiements = contenu;
                    break;
                case 'depenses':
                    this.csvDepenses = contenu;
                    break;
            }
        };
        
        reader.readAsText(file);
    }
    
    // Méthode pour passer à l'étape suivante
    handleSuivant() {
        if (this.etapeActuelle < 3) {
            this.etapeActuelle++;
        }
    }
    
    // Méthode pour revenir à l'étape précédente
    handlePrecedent() {
        if (this.etapeActuelle > 1) {
            this.etapeActuelle--;
        }
    }
    
    // Méthode pour télécharger un modèle Excel
    handleTelechargerModele(event) {
        const type = event.target.dataset.type;
        
        this.isLoading = true;
        
        genererModeleExcel({ objetType: type })
            .then(result => {
                // Créer un élément a pour le téléchargement
                const element = document.createElement('a');
                element.setAttribute('href', 'data:text/csv;charset=utf-8,' + encodeURIComponent(result));
                element.setAttribute('download', `Modele_${type}.csv`);
                element.style.display = 'none';
                document.body.appendChild(element);
                element.click();
                document.body.removeChild(element);
                
                this.isLoading = false;
            })
            .catch(error => {
                this.afficherErreur('Erreur lors de la génération du modèle', error.body.message);
                this.isLoading = false;
            });
    }
    
    // Méthode pour lancer l'importation des données
    handleImporter() {
        if (!this.tousLesFichiersSelectionnes) {
            this.afficherErreur('Fichiers manquants', 'Veuillez sélectionner tous les fichiers requis.');
            return;
        }
        
        this.isLoading = true;
        
        importerDonnees({
            csvBiens: this.csvBiens,
            csvLocataires: this.csvLocataires,
            csvBaux: this.csvBaux,
            csvPaiements: this.csvPaiements,
            csvDepenses: this.csvDepenses
        })
            .then(result => {
                this.resultatImportation = result;
                
                if (result.success) {
                    this.etapeActuelle = 3;
                    this.afficherSucces('Importation réussie', result.message);
                } else {
                    this.afficherErreur('Erreur lors de l\'importation', result.message);
                }
                
                this.isLoading = false;
            })
            .catch(error => {
                this.afficherErreur('Erreur lors de l\'importation', error.body.message);
                this.isLoading = false;
            });
    }
    
    // Méthode pour afficher un message de succès
    afficherSucces(titre, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: titre,
                message: message,
                variant: 'success'
            })
        );
    }
    
    // Méthode pour afficher un message d'erreur
    afficherErreur(titre, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: titre,
                message: message,
                variant: 'error'
            })
        );
    }
    
    // Méthode pour revenir à la page d'accueil
    handleRetourAccueil() {
        // Rediriger vers la page d'accueil de l'application
        window.location.href = '/lightning/n/Gestion_Locative';
    }
}