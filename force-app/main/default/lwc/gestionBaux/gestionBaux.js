import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBaux from '@salesforce/apex/BailService.getBaux'; // Correct Apex class reference

export default class GestionBaux extends LightningElement {
    @track baux = [];
    @track isLoading = true;
    @track error;
    @track statutOptions = [];
    @track statutSelectionne = '';
    @track showModal = false;
    @track bailSelectionne = null;

    @wire(getBaux)
    wiredBaux({ error, data }) {
        if (data) {
            this.baux = data;
            this.isLoading = false;
        } else if (error) {
            console.error('Erreur lors de la récupération des baux:', error);
            this.isLoading = false;
        }
    }
    
    connectedCallback() {
        // Initialisation des options de statut
        this.statutOptions = [
            { label: 'Tous', value: '' },
            { label: 'Actif', value: 'Actif' },
            { label: 'En préavis', value: 'En préavis' },
            { label: 'Résilié', value: 'Résilié' }
        ];
        
        // Charger les baux
        this.chargerBaux();
    }
    
    // Méthode pour charger les baux
    chargerBaux() {
        this.isLoading = true;
        
        // Simulation de données pour l'exemple
        setTimeout(() => {
            this.baux = [
                {
                    id: '1',
                    bien: 'Appartement Rue Gallieni',
                    locataire: 'Dupont Jean',
                    dateDebut: '01/01/2023',
                    dateFin: '31/12/2025',
                    loyer: 750,
                    charges: 50,
                    total: 800,
                    statut: 'Actif',
                    classeStatut: 'slds-text-color_success',
                    classeDateFin: ''
                },
                {
                    id: '2',
                    bien: 'Appartement Rue de Metz',
                    locataire: 'Martin Sophie',
                    dateDebut: '01/03/2022',
                    dateFin: '28/02/2025',
                    loyer: 850,
                    charges: 70,
                    total: 920,
                    statut: 'Actif',
                    classeStatut: 'slds-text-color_success',
                    classeDateFin: 'slds-text-color_warning'
                },
                {
                    id: '3',
                    bien: 'Appartement Rue de la Melonnière',
                    locataire: 'Dubois Pierre',
                    dateDebut: '01/06/2021',
                    dateFin: '31/05/2024',
                    loyer: 650,
                    charges: 60,
                    total: 710,
                    statut: 'En préavis',
                    classeStatut: 'slds-text-color_warning',
                    classeDateFin: 'slds-text-color_error slds-theme_alert-texture'
                },
                {
                    id: '4',
                    bien: 'Parking Rue Henri Dunant',
                    locataire: 'Petit Pierre',
                    dateDebut: '01/01/2022',
                    dateFin: '31/12/2024',
                    loyer: 80,
                    charges: 0,
                    total: 80,
                    statut: 'Actif',
                    classeStatut: 'slds-text-color_success',
                    classeDateFin: ''
                }
            ];
            
            // Filtrer les baux si un statut est sélectionné
            if (this.statutSelectionne) {
                this.baux = this.baux.filter(bail => bail.statut === this.statutSelectionne);
            }
            
            this.isLoading = false;
        }, 1000);
    }
    
    // Gestionnaire d'événement pour le changement de statut
    handleStatutChange(event) {
        this.statutSelectionne = event.detail.value;
        this.chargerBaux();
    }
    
    // Méthode pour ouvrir le modal de résiliation
    handleResilierBail(event) {
        const bailId = event.target.dataset.id;
        this.bailSelectionne = this.baux.find(bail => bail.id === bailId);
        this.showModal = true;
    }
    
    // Méthode pour fermer le modal
    handleCloseModal() {
        this.showModal = false;
        this.bailSelectionne = null;
    }
    
    // Méthode pour confirmer la résiliation
    handleConfirmResiliation() {
        if (!this.bailSelectionne) return;
        
        this.isLoading = true;
        
        // Simulation d'appel Apex pour résilier le bail
        setTimeout(() => {
            // Mettre à jour le bail dans la liste
            this.baux = this.baux.map(bail => {
                if (bail.id === this.bailSelectionne.id) {
                    return {
                        ...bail,
                        statut: 'En préavis',
                        classeStatut: 'slds-text-color_warning'
                    };
                }
                return bail;
            });
            
            this.isLoading = false;
            this.showModal = false;
            this.bailSelectionne = null;
            
            // Afficher un message de succès
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Succès',
                    message: 'Le bail a été mis en préavis avec succès.',
                    variant: 'success'
                })
            );
        }, 1000);
    }
    
    // Méthode pour renouveler un bail
    handleRenouvelerBail(event) {
        const bailId = event.target.dataset.id;
        
        this.isLoading = true;
        
        // Simulation d'appel Apex pour renouveler le bail
        setTimeout(() => {
            // Mettre à jour le bail dans la liste
            this.baux = this.baux.map(bail => {
                if (bail.id === bailId) {
                    // Ajouter 3 ans à la date de fin
                    const [jour, mois, annee] = bail.dateFin.split('/');
                    const nouvelleDateFin = `${jour}/${mois}/${parseInt(annee) + 3}`;
                    
                    return {
                        ...bail,
                        dateFin: nouvelleDateFin,
                        classeDateFin: ''
                    };
                }
                return bail;
            });
            
            this.isLoading = false;
            
            // Afficher un message de succès
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Succès',
                    message: 'Le bail a été renouvelé avec succès.',
                    variant: 'success'
                })
            );
        }, 1000);
    }
    
    // Getter pour calculer le nombre de baux actifs
    get nombreBauxActifs() {
        return this.baux.filter(bail => bail.statut === 'Actif').length;
    }
    
    // Getter pour calculer le nombre de baux en préavis
    get nombreBauxPrevis() {
        return this.baux.filter(bail => bail.statut === 'En préavis').length;
    }
    
    // Getter pour calculer le total des loyers
    get totalLoyers() {
        return this.baux.reduce((total, bail) => total + bail.loyer, 0);
    }
    
    // Getter pour calculer le total des charges
    get totalCharges() {
        return this.baux.reduce((total, bail) => total + bail.charges, 0);
    }
    
    // Getter pour calculer le total général
    get totalGeneral() {
        return this.totalLoyers + this.totalCharges;
    }
    
    // Getter pour vérifier si le bail est actif
    get isActif() {
        return this.statut === 'Actif';
    }
}