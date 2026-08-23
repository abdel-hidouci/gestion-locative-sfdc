import { LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getClasseCouleurPaiement from '@salesforce/apex/UIService.getClasseCouleurPaiement';

// Importation des objets et champs
import PAIEMENT_OBJECT from '@salesforce/schema/Paiement__c';
import BAIL_FIELD from '@salesforce/schema/Paiement__c.Bail__c';
import MOIS_FIELD from '@salesforce/schema/Paiement__c.Mois_Concerne__c';
import ANNEE_FIELD from '@salesforce/schema/Paiement__c.Annee_Concernee__c';
import MONTANT_LOYER_FIELD from '@salesforce/schema/Paiement__c.Montant_Loyer__c';
import MONTANT_CHARGES_FIELD from '@salesforce/schema/Paiement__c.Montant_Charges__c';
import STATUT_FIELD from '@salesforce/schema/Paiement__c.Statut__c';
import DATE_PAIEMENT_FIELD from '@salesforce/schema/Paiement__c.Date_Paiement__c';

export default class SuiviLoyers extends LightningElement {
    @track paiements = [];
    @track moisSelectionne = '';
    @track anneeSelectionnee = '';
    @track isLoading = true;
    @track error;
    @track moisOptions = [];
    @track anneeOptions = [];
    
    // Récupération des informations sur l'objet Paiement__c
    @wire(getObjectInfo, { objectApiName: PAIEMENT_OBJECT })
    objectInfo;
    
    connectedCallback() {
        // Initialisation des options de mois et d'années
        this.moisOptions = [
            { label: 'Janvier', value: 'Janvier' },
            { label: 'Février', value: 'Février' },
            { label: 'Mars', value: 'Mars' },
            { label: 'Avril', value: 'Avril' },
            { label: 'Mai', value: 'Mai' },
            { label: 'Juin', value: 'Juin' },
            { label: 'Juillet', value: 'Juillet' },
            { label: 'Août', value: 'Août' },
            { label: 'Septembre', value: 'Septembre' },
            { label: 'Octobre', value: 'Octobre' },
            { label: 'Novembre', value: 'Novembre' },
            { label: 'Décembre', value: 'Décembre' }
        ];
        
        // Générer les options d'années de 2018 à l'année actuelle + 1
        const anneeActuelle = new Date().getFullYear();
        const annees = [];
        for (let i = 2018; i <= anneeActuelle + 1; i++) {
            annees.push({ label: i.toString(), value: i.toString() });
        }
        this.anneeOptions = annees;
        
        // Définir les valeurs par défaut
        const dateActuelle = new Date();
        this.moisSelectionne = this.moisOptions[dateActuelle.getMonth()].value;
        this.anneeSelectionnee = dateActuelle.getFullYear().toString();
        
        // Charger les paiements
        this.chargerPaiements();
    }
    
    // Méthode pour charger les paiements
    chargerPaiements() {
        this.isLoading = true;
        
        // Appel Apex pour récupérer les paiements
        // Note: Dans une implémentation réelle, cela serait un appel à une méthode Apex
        // Ici, nous simulons les données pour l'exemple
        setTimeout(() => {
            this.paiements = [
                {
                    id: '1',
                    bien: 'Appartement Rue Gallieni',
                    locataire: 'Dupont Jean',
                    montantLoyer: 750,
                    montantCharges: 50,
                    montantTotal: 800,
                    statut: 'Encaissé',
                    datePaiement: '05/04/2025',
                    classeStatut: 'slds-text-color_success'
                },
                {
                    id: '2',
                    bien: 'Appartement Rue de Metz',
                    locataire: 'Martin Sophie',
                    montantLoyer: 850,
                    montantCharges: 70,
                    montantTotal: 920,
                    statut: 'En attente',
                    datePaiement: null,
                    classeStatut: 'slds-text-color_error slds-theme_alert-texture'
                },
                {
                    id: '3',
                    bien: 'Parking Rue Henri Dunant',
                    locataire: 'Petit Pierre',
                    montantLoyer: 80,
                    montantCharges: 0,
                    montantTotal: 80,
                    statut: 'Encaissé',
                    datePaiement: '03/04/2025',
                    classeStatut: 'slds-text-color_success'
                }
            ];
            this.isLoading = false;
        }, 1000);
    }
    
    // Gestionnaires d'événements pour les changements de mois et d'année
    handleMoisChange(event) {
        this.moisSelectionne = event.detail.value;
        this.chargerPaiements();
    }
    
    handleAnneeChange(event) {
        this.anneeSelectionnee = event.detail.value;
        this.chargerPaiements();
    }
    
    // Méthode pour marquer un paiement comme encaissé
    handleEncaisserPaiement(event) {
        const paiementId = event.target.dataset.id;
        
        // Appel Apex pour mettre à jour le statut du paiement
        // Note: Dans une implémentation réelle, cela serait un appel à une méthode Apex
        // Ici, nous simulons la mise à jour pour l'exemple
        this.isLoading = true;
        setTimeout(() => {
            // Mettre à jour le paiement dans la liste
            this.paiements = this.paiements.map(paiement => {
                if (paiement.id === paiementId) {
                    const dateActuelle = new Date();
                    const jour = dateActuelle.getDate().toString().padStart(2, '0');
                    const mois = (dateActuelle.getMonth() + 1).toString().padStart(2, '0');
                    const annee = dateActuelle.getFullYear();
                    
                    return {
                        ...paiement,
                        statut: 'Encaissé',
                        datePaiement: `${jour}/${mois}/${annee}`,
                        classeStatut: 'slds-text-color_success'
                    };
                }
                return paiement;
            });
            
            this.isLoading = false;
            
            // Afficher un message de succès
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Succès',
                    message: 'Le paiement a été encaissé avec succès.',
                    variant: 'success'
                })
            );
        }, 1000);
    }
    
    // Méthode pour générer une quittance
    handleGenererQuittance(event) {
        const paiementId = event.target.dataset.id;
        
        // Appel Apex pour générer la quittance
        // Note: Dans une implémentation réelle, cela serait un appel à une méthode Apex
        // Ici, nous simulons la génération pour l'exemple
        this.isLoading = true;
        setTimeout(() => {
            this.isLoading = false;
            
            // Afficher un message de succès
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Succès',
                    message: 'La quittance a été générée avec succès.',
                    variant: 'success'
                })
            );
        }, 1000);
    }
    
    // Méthode pour envoyer une quittance par email
    handleEnvoyerQuittance(event) {
        const paiementId = event.target.dataset.id;
        
        // Appel Apex pour envoyer la quittance
        // Note: Dans une implémentation réelle, cela serait un appel à une méthode Apex
        // Ici, nous simulons l'envoi pour l'exemple
        this.isLoading = true;
        setTimeout(() => {
            this.isLoading = false;
            
            // Afficher un message de succès
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Succès',
                    message: 'La quittance a été envoyée par email avec succès.',
                    variant: 'success'
                })
            );
        }, 1000);
    }
    
    // Getter pour calculer le total des loyers
    get totalLoyers() {
        return this.paiements.reduce((total, paiement) => total + paiement.montantLoyer, 0);
    }
    
    // Getter pour calculer le total des charges
    get totalCharges() {
        return this.paiements.reduce((total, paiement) => total + paiement.montantCharges, 0);
    }
    
    // Getter pour calculer le total général
    get totalGeneral() {
        return this.totalLoyers + this.totalCharges;
    }
    
    // Getter pour déterminer si tous les paiements sont encaissés
    get tousEncaisses() {
        return this.paiements.every(paiement => paiement.statut === 'Encaissé');
    }
    
    // Getters pour les conditions de statut
    get isEnAttente() {
        return this.statut === 'En attente';
    }
    
    get isEncaisse() {
        return this.statut === 'Encaissé';
    }
}