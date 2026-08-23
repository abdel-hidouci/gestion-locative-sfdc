# Application Salesforce "Gestion Locative"

## Présentation

L'application "Gestion Locative" est une solution complète développée sur la plateforme Salesforce pour gérer des biens locatifs, leurs locataires, les baux, les paiements de loyers, les dépenses et les quittances. Cette application est spécialement conçue pour les propriétaires de biens immobiliers qui souhaitent suivre efficacement leurs locations et optimiser leur gestion locative.

## Fonctionnalités principales

- **Gestion des biens locatifs** : Appartements, parkings et autres types de biens
- **Gestion des locataires** : Informations complètes et historique par bien
- **Gestion des baux** : Dates de début/fin, loyer, charges, dépôt de garantie
- **Suivi des paiements** : Statut (en attente/encaissé), code couleur, historique
- **Suivi des dépenses** : Par bien, date, nature, montant (récupérable ou non)
- **Génération automatique de quittances** : Au format PDF après paiement complet
- **Envoi de quittances par email** : Directement depuis Salesforce
- **Calcul du rendement locatif** : Par bien et par année
- **Importation de données historiques** : Depuis des fichiers CSV

## Architecture de l'application

### Objets personnalisés

L'application est construite autour de 7 objets personnalisés interconnectés :

1. **Bien_Locatif__c** : Représente les biens immobiliers (appartements, parkings)
   - Champs principaux : Nom, Type, Adresse, Surface, Prix d'acquisition, Statut

2. **Locataire__c** : Stocke les informations sur les locataires
   - Champs principaux : Nom, Prénom, Email, Téléphone, Situation professionnelle

3. **Bail__c** : Gère les contrats de location
   - Champs principaux : Bien locatif (relation), Locataire (relation), Date début, Date fin, Montant loyer, Montant charges, Dépôt de garantie, Statut

4. **Paiement__c** : Suit les paiements de loyers
   - Champs principaux : Bail (relation), Date paiement, Mois concerné, Année concernée, Montant loyer, Montant charges, Statut

5. **Depense__c** : Enregistre les dépenses liées aux biens
   - Champs principaux : Bien locatif (relation), Date dépense, Nature, Montant, Récupérable, Année fiscale

6. **Quittance__c** : Stocke les quittances générées
   - Champs principaux : Paiement (relation), Date génération, Période début, Période fin, Montant loyer, Montant charges, Montant total

7. **Rendement__c** : Calcule le rendement locatif des biens
   - Champs principaux : Bien locatif (relation), Année, Total loyers, Total charges, Total dépenses, Rendement brut, Rendement net

### Relations entre les objets

```
Bien_Locatif__c (1) ──┬── (n) Bail__c (1) ── (n) Paiement__c (1) ── (1) Quittance__c
                      │
                      ├── (n) Depense__c
                      │
                      └── (n) Rendement__c

Locataire__c (1) ─── (n) Bail__c
```

### Automatisations

L'application comprend plusieurs automatisations pour simplifier la gestion :

1. **Génération automatique de quittances** : Lorsqu'un paiement passe au statut "Encaissé", une quittance est automatiquement générée au format PDF.

2. **Calcul du rendement locatif** : Le rendement est automatiquement calculé ou mis à jour lorsqu'un paiement ou une dépense est ajouté, modifié ou supprimé.

3. **Alertes de fin de bail** : Des alertes sont générées lorsqu'un bail approche de sa date de fin.

4. **Mise à jour du statut des biens** : Le statut d'un bien est automatiquement mis à jour en fonction des baux associés.

### Interface utilisateur

L'application propose une interface utilisateur intuitive et responsive, compatible avec l'application mobile Salesforce :

1. **Application Lightning "Gestion Locative"** : Point d'entrée principal avec tous les onglets nécessaires.

2. **Composants Lightning Web (LWC)** :
   - **suiviLoyers** : Pour visualiser et gérer les paiements de loyers avec code couleur
   - **rendementLocatif** : Pour analyser le rendement des biens locatifs
   - **gestionBaux** : Pour gérer les contrats de location
   - **importationDonnees** : Pour importer les données historiques

3. **Tableau de bord** : Visualisation des indicateurs clés (loyers encaissés, rendement, baux actifs, etc.)

## Installation

### Prérequis

- Une organisation Salesforce (Enterprise, Unlimited, Developer ou sandbox)
- Droits d'administrateur pour déployer des composants
- Salesforce CLI installé sur votre machine

### Étapes d'installation

1. **Cloner le dépôt**

```bash
git clone https://github.com/votre-repo/gestion-locative-sfdx.git
cd gestion-locative-sfdx
```

2. **Se connecter à votre organisation Salesforce**

```bash
sfdx auth:web:login -a GestionLocativeOrg
```

3. **Déployer les composants**

```bash
sfdx force:source:deploy -p force-app -u GestionLocativeOrg
```

4. **Attribuer les ensembles d'autorisations**

```bash
sfdx force:user:permset:assign -n Gestion_Locative_Admin -u GestionLocativeOrg
```

5. **Importer les données de base (optionnel)**

```bash
sfdx force:data:tree:import -p data/plan.json -u GestionLocativeOrg
```

## Guide d'utilisation

### Configuration initiale

1. **Accéder à l'application** : Depuis le lanceur d'applications, sélectionnez "Gestion Locative".

2. **Importer vos données existantes** :
   - Accédez à l'onglet "Importation de données"
   - Téléchargez les modèles CSV pour chaque type d'objet
   - Remplissez les modèles avec vos données
   - Importez les fichiers dans l'ordre suivant : Biens, Locataires, Baux, Paiements, Dépenses

### Gestion quotidienne

1. **Ajouter un nouveau bien** :
   - Accédez à l'onglet "Biens locatifs"
   - Cliquez sur "Nouveau"
   - Remplissez les informations requises

2. **Ajouter un nouveau locataire** :
   - Accédez à l'onglet "Locataires"
   - Cliquez sur "Nouveau"
   - Remplissez les informations requises

3. **Créer un nouveau bail** :
   - Accédez à l'onglet "Baux"
   - Cliquez sur "Nouveau"
   - Sélectionnez le bien et le locataire
   - Remplissez les détails du bail

4. **Enregistrer un paiement** :
   - Accédez à l'onglet "Paiements" ou utilisez le composant "Suivi des loyers"
   - Cliquez sur "Nouveau" ou utilisez le bouton "Encaisser"
   - Remplissez les détails du paiement

5. **Générer une quittance** :
   - La quittance est générée automatiquement lorsqu'un paiement est encaissé
   - Vous pouvez également générer manuellement une quittance depuis la page de détail d'un paiement

6. **Envoyer une quittance par email** :
   - Depuis la page de détail d'une quittance, cliquez sur "Envoyer par email"
   - Ou utilisez le bouton "Envoyer par email" dans le composant "Suivi des loyers"

7. **Consulter le rendement** :
   - Accédez à l'onglet "Rendements" ou utilisez le composant "Rendement locatif"
   - Filtrez par année et/ou par bien

### Fonctionnalités mobiles

Toutes les fonctionnalités sont disponibles sur l'application mobile Salesforce :

1. **Installation** : Téléchargez l'application Salesforce Mobile depuis l'App Store ou Google Play

2. **Connexion** : Connectez-vous avec vos identifiants Salesforce

3. **Accès** : Sélectionnez "Gestion Locative" dans le menu des applications

## Personnalisation

### Ajout de champs personnalisés

1. **Accédez à la Configuration** dans Salesforce

2. **Ouvrez le Gestionnaire d'objets**

3. **Sélectionnez l'objet** à modifier

4. **Ajoutez de nouveaux champs** selon vos besoins

### Modification des layouts

1. **Accédez à la Configuration** dans Salesforce

2. **Ouvrez le Gestionnaire d'objets**

3. **Sélectionnez l'objet** à modifier

4. **Accédez à "Présentations de page"**

5. **Modifiez la présentation** selon vos besoins

## Dépannage

### Problèmes courants

1. **Les quittances ne sont pas générées automatiquement**
   - Vérifiez que le statut du paiement est bien "Encaissé"
   - Vérifiez les journaux d'erreurs dans la Configuration > Journaux d'erreurs Apex

2. **Le rendement n'est pas calculé correctement**
   - Vérifiez que toutes les dépenses sont correctement enregistrées
   - Utilisez le bouton "Recalculer le rendement" dans le composant "Rendement locatif"

3. **Problèmes d'importation de données**
   - Vérifiez le format de vos fichiers CSV
   - Assurez-vous que les références entre objets sont correctes

### Support

Pour toute question ou problème, veuillez contacter :
- Email : support@gestionlocative.com
- Téléphone : +33 1 23 45 67 89

## Développement et contribution

### Structure du code

```
force-app/
├── main/
│   └── default/
│       ├── applications/        # Application Lightning
│       ├── classes/             # Classes Apex
│       ├── components/          # Composants Visualforce
│       ├── dashboards/          # Tableaux de bord
│       ├── email/               # Modèles d'email
│       ├── flexipages/          # Pages Lightning
│       ├── layouts/             # Présentations de page
│       ├── lwc/                 # Composants Lightning Web
│       ├── objects/             # Objets personnalisés
│       ├── pages/               # Pages Visualforce
│       ├── tabs/                # Onglets personnalisés
│       └── triggers/            # Triggers Apex
```

### Classes principales

1. **QuittanceService** : Gestion des quittances de loyer
2. **RendementService** : Calcul du rendement locatif
3. **BailService** : Gestion des baux et alertes
4. **UIService** : Gestion des couleurs dans l'interface
5. **ImportDonneesHistoriques** : Importation des données
6. **ImportDonneesController** : Contrôleur pour l'importation

### Composants LWC

1. **suiviLoyers** : Suivi des paiements de loyers
2. **rendementLocatif** : Analyse du rendement
3. **gestionBaux** : Gestion des contrats de location
4. **importationDonnees** : Interface d'importation

## Licence

Cette application est distribuée sous licence propriétaire. Tous droits réservés.

---

Avril 2025
