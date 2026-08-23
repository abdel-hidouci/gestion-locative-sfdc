import { LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Importation des méthodes Apex
import getRendements from '@salesforce/apex/RendementService.getRendements';

export default class RendementLocatif extends LightningElement {
    @track rendements = [];
    @track anneeSelectionnee = '';
    @track isLoading = true;
    @track error;
    @track anneeOptions = [];
    @track bienOptions = [];
    @track bienSelectionne = '';
    @track afficherTous = true;

    @wire(getRendements)
    wiredRendements({ error, data }) {
        if (data) {
            this.rendements = data;
            this.isLoading = false;
        } else if (error) {
            console.error('Erreur lors de la récupération des rendements:', error);
            this.isLoading = false;
        }
    }
    
    connectedCallback() {
        // Générer les options d'années de 2018 à l'année actuelle + 1
        const anneeActuelle = new Date().getFullYear();
        const annees = [];
        for (let i = 2018; i <= anneeActuelle + 1; i++) {
            annees.push({ label: i.toString(), value: i.toString() });
        }
        this.anneeOptions = annees;
        
        // Définir l'année par défaut
        this.anneeSelectionnee = anneeActuelle.toString();
        
        // Charger les biens
        this.chargerBiens();
        
        // Charger les rendements
        this.chargerRendements();
    }
    
    // Méthode pour charger les biens
    chargerBiens() {
        // Simulation de données pour l'exemple
        this.bienOptions = [
            { label: 'Tous les biens', value: '' },
            { label: 'Appartement Rue Gallieni', value: 'bien1' },
            { label: 'Appartement Rue de Metz', value: 'bien2' },
            { label: 'Appartement Rue de la Melonnière', value: 'bien3' },
            { label: 'Appartement Avenue du Président Georges Pompidou', value: 'bien4' },
            { label: 'Appartement Rue Henri Dunant', value: 'bien5' },
            { label: 'Parking Rue de Metz', value: 'bien6' },
            { label: 'Parking Rue Henri Dunant', value: 'bien7' }
        ];
    }
    
    // Méthode pour charger les rendements
    chargerRendements() {
        this.isLoading = true;
        
        // Simulation de données pour l'exemple
        setTimeout(() => {
            this.rendements = [
                {
                    id: 'bien1',
                    bien: 'Appartement Rue Gallieni',
                    totalLoyers: 9000,
                    totalCharges: 600,
                    totalDepenses: 1200,
                    rendementBrut: 5.2,
                    rendementNet: 4.6
                },
                {
                    id: 'bien2',
                    bien: 'Appartement Rue de Metz',
                    totalLoyers: 10200,
                    totalCharges: 840,
                    totalDepenses: 1500,
                    rendementBrut: 6.1,
                    rendementNet: 5.3
                },
                {
                    id: 'bien3',
                    bien: 'Appartement Rue de la Melonnière',
                    totalLoyers: 7800,
                    totalCharges: 720,
                    totalDepenses: 1100,
                    rendementBrut: 4.8,
                    rendementNet: 4.2
                },
                {
                    id: 'bien4',
                    bien: 'Appartement Avenue du Président Georges Pompidou',
                    totalLoyers: 11400,
                    totalCharges: 960,
                    totalDepenses: 1800,
                    rendementBrut: 5.7,
                    rendementNet: 4.9
                },
                {
                    id: 'bien5',
                    bien: 'Appartement Rue Henri Dunant',
                    totalLoyers: 8400,
                    totalCharges: 720,
                    totalDepenses: 1300,
                    rendementBrut: 5.0,
                    rendementNet: 4.3
                },
                {
                    id: 'bien6',
                    bien: 'Parking Rue de Metz',
                    totalLoyers: 960,
                    totalCharges: 0,
                    totalDepenses: 120,
                    rendementBrut: 4.0,
                    rendementNet: 3.5
                },
                {
                    id: 'bien7',
                    bien: 'Parking Rue Henri Dunant',
                    totalLoyers: 840,
                    totalCharges: 0,
                    totalDepenses: 100,
                    rendementBrut: 3.8,
                    rendementNet: 3.4
                }
            ];
            
            // Filtrer les rendements si un bien est sélectionné
            if (this.bienSelectionne) {
                this.rendements = this.rendements.filter(rendement => rendement.id === this.bienSelectionne);
                this.afficherTous = false;
            } else {
                this.afficherTous = true;
            }
            
            this.isLoading = false;
        }, 1000);
    }
    
    // Gestionnaires d'événements pour les changements d'année et de bien
    handleAnneeChange(event) {
        this.anneeSelectionnee = event.detail.value;
        this.chargerRendements();
    }
    
    handleBienChange(event) {
        this.bienSelectionne = event.detail.value;
        this.chargerRendements();
    }
    
    // Méthode pour recalculer le rendement
    handleRecalculerRendement() {
        this.isLoading = true;
        
        // Simulation d'appel Apex pour recalculer le rendement
        setTimeout(() => {
            this.chargerRendements();
            
            // Afficher un message de succès
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Succès',
                    message: 'Le rendement a été recalculé avec succès.',
                    variant: 'success'
                })
            );
        }, 1500);
    }
    
    // Getters pour les totaux
    get totalLoyers() {
        return this.rendements.reduce((total, rendement) => total + rendement.totalLoyers, 0);
    }
    
    get totalCharges() {
        return this.rendements.reduce((total, rendement) => total + rendement.totalCharges, 0);
    }
    
    get totalDepenses() {
        return this.rendements.reduce((total, rendement) => total + rendement.totalDepenses, 0);
    }
    
    get totalRevenuBrut() {
        return this.totalLoyers + this.totalCharges;
    }
    
    get totalRevenuNet() {
        return this.totalRevenuBrut - this.totalDepenses;
    }
    
    // Calcul du rendement moyen
    get rendementBrutMoyen() {
        if (this.rendements.length === 0) return 0;
        const somme = this.rendements.reduce((total, rendement) => total + rendement.rendementBrut, 0);
        return (somme / this.rendements.length).toFixed(2);
    }
    
    get rendementNetMoyen() {
        if (this.rendements.length === 0) return 0;
        const somme = this.rendements.reduce((total, rendement) => total + rendement.rendementNet, 0);
        return (somme / this.rendements.length).toFixed(2);
    }
}
