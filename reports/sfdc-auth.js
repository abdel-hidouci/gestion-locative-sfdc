/**
 * sfdc-auth.js - Module d'authentification OAuth 2.0 PKCE & Synchronisation REST API
 * pour le Tableau de Bord Gestion Locative Immobilière.
 */

const SFDC_AUTH_CONFIG = {
    // Client ID de la Connected App Salesforce N8N / GestionLocative
    clientId: '3MVG9PwZx9R6_UrdrleBoEfwuw9hs.uuDx4HGEjBw4KwURI.PxsWUKYy1ibGUQ7Ha3gUE_2wMyAGhEviYZj51',
    loginUrl: 'https://login.salesforce.com',
    get redirectUri() {
        // Enlève les paramètres de requête et hash pour correspondre exactement à l'URL de callback autorisée
        return window.location.origin + window.location.pathname;
    },
    apiVersion: 'v60.0'
};

const sfdcAuth = {
    // Génère une chaîne aléatoire cryptographiquement sûre
    generateRandomString(length = 64) {
        const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
        const values = new Uint8Array(length);
        crypto.getRandomValues(values);
        let result = '';
        for (let i = 0; i < length; i++) {
            result += charset[values[i] % charset.length];
        }
        return result;
    },

    // Calcule le hash SHA-256
    async sha256(plain) {
        const encoder = new TextEncoder();
        const data = encoder.encode(plain);
        return crypto.subtle.digest('SHA-256', data);
    },

    // Encode en Base64-URL sans padding
    base64UrlEncode(buffer) {
        let str = '';
        const bytes = new Uint8Array(buffer);
        for (let i = 0; i < bytes.byteLength; i++) {
            str += String.fromCharCode(bytes[i]);
        }
        return btoa(str)
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=+$/, '');
    },

    // Lance le flux OAuth 2.0 PKCE
    async login() {
        try {
            const verifier = this.generateRandomString(96);
            const hashed = await this.sha256(verifier);
            const challenge = this.base64UrlEncode(hashed);
            const state = this.generateRandomString(16);

            sessionStorage.setItem('sfdc_pkce_verifier', verifier);
            sessionStorage.setItem('sfdc_oauth_state', state);

            const params = new URLSearchParams({
                response_type: 'code',
                client_id: SFDC_AUTH_CONFIG.clientId,
                redirect_uri: SFDC_AUTH_CONFIG.redirectUri,
                code_challenge: challenge,
                code_challenge_method: 'S256',
                scope: 'full refresh_token',
                state: state,
                prompt: 'login consent'
            });

            const authUrl = `${SFDC_AUTH_CONFIG.loginUrl}/services/oauth2/authorize?${params.toString()}`;
            window.location.href = authUrl;
        } catch (err) {
            console.error("Erreur lors de l'initialisation OAuth PKCE:", err);
            alert("Erreur lors de la connexion à Salesforce: " + err.message);
        }
    },

    // Traite le retour OAuth (?code=...)
    async handleCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        const code = urlParams.get('code');
        const state = urlParams.get('state');
        const error = urlParams.get('error');
        const errorDesc = urlParams.get('error_description');

        if (error) {
            console.error("Erreur renvoyée par Salesforce:", error, errorDesc);
            window.history.replaceState({}, document.title, window.location.pathname);
            alert(`Erreur d'authentification Salesforce : ${errorDesc || error}`);
            return false;
        }

        if (code) {
            const savedState = sessionStorage.getItem('sfdc_oauth_state');
            const verifier = sessionStorage.getItem('sfdc_pkce_verifier');

            if (state && savedState && state !== savedState) {
                console.error("State mismatch: sécurité compromise.");
                window.history.replaceState({}, document.title, window.location.pathname);
                return false;
            }

            // Nettoyage immédiat de l'URL pour garder une interface propre
            window.history.replaceState({}, document.title, window.location.pathname);

            const bodyParams = new URLSearchParams({
                grant_type: 'authorization_code',
                client_id: SFDC_AUTH_CONFIG.clientId,
                redirect_uri: SFDC_AUTH_CONFIG.redirectUri,
                code: code,
                code_verifier: verifier
            });

            try {
                const response = await fetch(`${SFDC_AUTH_CONFIG.loginUrl}/services/oauth2/token`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                        'Accept': 'application/json'
                    },
                    body: bodyParams.toString()
                });

                if (!response.ok) {
                    const errData = await response.json().catch(() => ({}));
                    throw new Error(errData.error_description || errData.error || `HTTP ${response.status}`);
                }

                const tokenData = await response.json();
                sessionStorage.setItem('sfdc_access_token', tokenData.access_token);
                sessionStorage.setItem('sfdc_instance_url', tokenData.instance_url);
                if (tokenData.refresh_token) {
                    sessionStorage.setItem('sfdc_refresh_token', tokenData.refresh_token);
                }
                sessionStorage.removeItem('sfdc_pkce_verifier');
                sessionStorage.removeItem('sfdc_oauth_state');
                return true;
            } catch (e) {
                console.error("Erreur lors de l'échange du token:", e);
                alert(`Erreur lors de l'échange du jeton Salesforce: ${e.message}`);
                return false;
            }
        }
        return false;
    },

    // Vérifie si un token est présent en session
    isLoggedIn() {
        return !!(sessionStorage.getItem('sfdc_access_token') && sessionStorage.getItem('sfdc_instance_url'));
    },

    // Déconnexion
    logout() {
        sessionStorage.removeItem('sfdc_access_token');
        sessionStorage.removeItem('sfdc_instance_url');
        sessionStorage.removeItem('sfdc_refresh_token');
        sessionStorage.removeItem('sfdc_last_sync');
        window.location.reload();
    },

    // Exécute une requête SOQL avec pagination automatique
    async queryAll(soql) {
        const token = sessionStorage.getItem('sfdc_access_token');
        const instanceUrl = sessionStorage.getItem('sfdc_instance_url');
        if (!token || !instanceUrl) {
            throw new Error("Non connecté à Salesforce");
        }

        let records = [];
        let url = `${instanceUrl}/services/data/${SFDC_AUTH_CONFIG.apiVersion}/query?q=${encodeURIComponent(soql)}`;

        while (url) {
            const resp = await fetch(url, {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Accept': 'application/json'
                }
            });

            if (!resp.ok) {
                if (resp.status === 401) {
                    sessionStorage.removeItem('sfdc_access_token');
                    throw new Error("Session Salesforce expirée. Veuillez vous reconnecter.");
                }
                const errJson = await resp.json().catch(() => [{ message: `HTTP ${resp.status}` }]);
                throw new Error((errJson[0] && errJson[0].message) || `Erreur requête Salesforce (${resp.status})`);
            }

            const data = await resp.json();
            records = records.concat(data.records || []);
            url = data.nextRecordsUrl ? `${instanceUrl}${data.nextRecordsUrl}` : null;
        }

        return records;
    },

    // Récupère l'intégralité des données en direct depuis l'org
    async fetchLiveData() {
        const [biensRaw, paiementsRaw, depensesRaw] = await Promise.all([
            this.queryAll(
                "SELECT Id, Name, Type__c, Statut__c, Prix_Acquisition__c, Surface__c, Ville__c, " +
                "NumeroPretImmo__c, NumeroPretTravaux__c FROM Bien_Locatif__c ORDER BY Name ASC"
            ),
            this.queryAll(
                "SELECT Id, Name, Bien_Locatif__c, Locataire__r.Name, Locataire__r.Prenom__c, Locataire__r.Nom__c, " +
                "Mois_Concerne__c, Annee_Concernee__c, Date_Paiement__c, Date_Encaissement__c, " +
                "Montant_Loyer__c, Montant_Charges__c, Montant_Total__c, FraisAgence__c, MontantEncaisse__c, Statut__c " +
                "FROM Paiement__c WHERE CALENDAR_YEAR(Date_Paiement__c) <= 2027 ORDER BY Date_Paiement__c ASC, Name ASC"
            ),
            this.queryAll(
                "SELECT Id, Name, Bien_Locatif__r.Name, RecordType.DeveloperName, Nature__c, Date_Depense__c, Annee_Fiscale__c, " +
                "Description__c, Montant_Total__c, Montant_Capital__c, Montant_Interets__c, Montant_Assurance_Pret__c, " +
                "Montant_Charge_Copro__c, Montant_Fonds_Travaux_loi_Alur__c, Statut__c " +
                "FROM Depense__c WHERE CALENDAR_YEAR(Date_Depense__c) <= 2027 ORDER BY Date_Depense__c ASC, Name ASC"
            )
        ]);

        const biens = biensRaw.map(b => ({
            id: b.Id,
            name: b.Name,
            type: b.Type__c || '',
            statut: b.Statut__c || '',
            prix: b.Prix_Acquisition__c || 0,
            surface: b.Surface__c || 0,
            ville: b.Ville__c || '',
            pret_immo: b.NumeroPretImmo__c || '',
            pret_travaux: b.NumeroPretTravaux__c || ''
        }));

        const paiements = paiementsRaw.map(p => {
            const loc = p.Locataire__r || {};
            const loc_name = loc.Prenom__c || loc.Name || '';
            return {
                id: p.Id,
                name: p.Name,
                bien: p.Bien_Locatif__c || '',
                locataire: loc_name,
                mois: p.Mois_Concerne__c || '',
                annee: p.Annee_Concernee__c || '',
                date_paiement: p.Date_Paiement__c || '',
                date_encaissement: p.Date_Encaissement__c || '',
                loyer: p.Montant_Loyer__c || 0,
                charges: p.Montant_Charges__c || 0,
                total: p.Montant_Total__c || 0,
                frais_agence: p.FraisAgence__c || 0,
                encaisse: p.MontantEncaisse__c || 0,
                statut: p.Statut__c || ''
            };
        });

        const depenses = depensesRaw.map(d => {
            const rec_type = (d.RecordType && d.RecordType.DeveloperName) || '';
            const nature = d.Nature__c || '';
            let categorie = 'Autre';
            if (rec_type === 'Credit_Immobilier_Travaux') categorie = 'Crédit Travaux';
            else if (rec_type === 'Credit_Immobilier') categorie = 'Crédit Immobilier';
            else if (rec_type === 'Charge_Copro') categorie = 'Charges Copropriété & Alur';
            else if (nature === 'Frais de gestion - Agence immobilière' || nature === 'Frais de mise en location') categorie = 'Frais de Gestion Agence';
            else if (nature === 'Assurance PNO') categorie = 'Assurance PNO';
            else if (nature) categorie = nature;

            const annee = d.Annee_Fiscale__c || (d.Date_Depense__c ? d.Date_Depense__c.substring(0, 4) : '');

            return {
                id: d.Id,
                name: d.Name,
                bien: (d.Bien_Locatif__r && d.Bien_Locatif__r.Name) || '',
                categorie: categorie,
                nature: nature,
                date: d.Date_Depense__c || '',
                annee: annee,
                description: d.Description__c || '',
                total: d.Montant_Total__c || 0,
                capital: d.Montant_Capital__c || 0,
                interets: d.Montant_Interets__c || 0,
                assurance: d.Montant_Assurance_Pret__c || 0,
                charge_copro: d.Montant_Charge_Copro__c || 0,
                alur: d.Montant_Fonds_Travaux_loi_Alur__c || 0,
                statut: d.Statut__c || ''
            };
        });

        sessionStorage.setItem('sfdc_last_sync', new Date().toISOString());

        return { biens, paiements, depenses };
    }
};
