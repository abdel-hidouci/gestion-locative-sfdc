#!/usr/bin/env python3
"""
Script de synchronisation automatique du Dashboard HTML Gestion Locative avec Salesforce.
Extrait les données en temps réel de l'org 'gestion-locative' et met à jour reports/index.html,
reports/rapport_annuel_2026.html ainsi que reports/data.json.
"""

import json
import os
import subprocess
import ssl
import urllib.parse
import urllib.request
import sys

def sync_dashboard(target_org='gestion-locative'):
    print(f"Connexion à l'org Salesforce '{target_org}'...")
    try:
        cmd = ['sf', 'org', 'display', '--target-org', target_org, '--json']
        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        data = json.loads(res.stdout)['result']
        token = data['accessToken']
        instance_url = data['instanceUrl']
    except Exception as e:
        print(f"Erreur lors de la récupération du token Salesforce: {e}")
        sys.exit(1)

    ctx = ssl._create_unverified_context()

    def run_query(soql):
        records = []
        url = f'{instance_url}/services/data/v67.0/query?q=' + urllib.parse.quote(soql)
        while url:
            req = urllib.request.Request(url, headers={'Authorization': f'Bearer {token}'})
            with urllib.request.urlopen(req, context=ctx) as r:
                res = json.loads(r.read().decode('utf-8'))
                records.extend(res['records'])
                next_records = res.get('nextRecordsUrl')
                url = f'{instance_url}{next_records}' if next_records else None
        return records

    print("Extraction des Biens Immobiliers...")
    biens_raw = run_query(
        "SELECT Id, Name, Type__c, Statut__c, Prix_Acquisition__c, Surface__c, Ville__c, "
        "NumeroPretImmo__c, NumeroPretTravaux__c FROM Bien_Locatif__c ORDER BY Name ASC"
    )
    biens_data = [
        {
            'id': b.get('Id'),
            'name': b.get('Name'),
            'type': b.get('Type__c') or '',
            'statut': b.get('Statut__c') or '',
            'prix': b.get('Prix_Acquisition__c') or 0,
            'surface': b.get('Surface__c') or 0,
            'ville': b.get('Ville__c') or '',
            'pret_immo': b.get('NumeroPretImmo__c') or '',
            'pret_travaux': b.get('NumeroPretTravaux__c') or ''
        }
        for b in biens_raw
    ]

    print("Extraction des Paiements (Échéances de Loyers)...")
    paiements_raw = run_query(
        "SELECT Id, Name, Bien_Locatif__c, Locataire__r.Name, Locataire__r.Prenom__c, Locataire__r.Nom__c, "
        "Mois_Concerne__c, Annee_Concernee__c, Date_Paiement__c, Date_Encaissement__c, "
        "Montant_Loyer__c, Montant_Charges__c, Montant_Total__c, FraisAgence__c, MontantEncaisse__c, Statut__c "
        "FROM Paiement__c WHERE CALENDAR_YEAR(Date_Paiement__c) <= 2027 ORDER BY Date_Paiement__c ASC, Name ASC"
    )
    paiements_data = []
    for p in paiements_raw:
        loc = p.get('Locataire__r') or {}
        loc_name = loc.get('Prenom__c') or loc.get('Name') or ''
        paiements_data.append({
            'id': p.get('Id'),
            'name': p.get('Name'),
            'bien': p.get('Bien_Locatif__c') or '',
            'locataire': loc_name,
            'mois': p.get('Mois_Concerne__c') or '',
            'annee': p.get('Annee_Concernee__c') or '',
            'date_paiement': p.get('Date_Paiement__c') or '',
            'date_encaissement': p.get('Date_Encaissement__c') or '',
            'loyer': p.get('Montant_Loyer__c') or 0,
            'charges': p.get('Montant_Charges__c') or 0,
            'total': p.get('Montant_Total__c') or 0,
            'frais_agence': p.get('FraisAgence__c') or 0,
            'encaisse': p.get('MontantEncaisse__c') or 0,
            'statut': p.get('Statut__c') or ''
        })

    print("Extraction des Dépenses & Charges...")
    depenses_raw = run_query(
        "SELECT Id, Name, Bien_Locatif__r.Name, RecordType.DeveloperName, Nature__c, Date_Depense__c, Annee_Fiscale__c, "
        "Description__c, Montant_Total__c, Montant_Capital__c, Montant_Interets__c, Montant_Assurance_Pret__c, "
        "Montant_Charge_Copro__c, Montant_Fonds_Travaux_loi_Alur__c, Statut__c "
        "FROM Depense__c WHERE CALENDAR_YEAR(Date_Depense__c) <= 2027 ORDER BY Date_Depense__c ASC, Name ASC"
    )
    depenses_data = []
    for d in depenses_raw:
        rec_type = (d.get('RecordType') or {}).get('DeveloperName', '')
        nature = d.get('Nature__c') or ''
        if rec_type == 'Credit_Immobilier_Travaux':
            categorie = 'Crédit Travaux'
        elif rec_type == 'Credit_Immobilier':
            categorie = 'Crédit Immobilier'
        elif rec_type == 'Charge_Copro':
            categorie = 'Charges Copropriété & Alur'
        elif nature in ('Frais de gestion - Agence immobilière', 'Frais de mise en location'):
            categorie = 'Frais de Gestion Agence'
        elif nature == 'Assurance PNO':
            categorie = 'Assurance PNO'
        elif nature:
            categorie = nature
        else:
            categorie = 'Autre'

        annee = d.get('Annee_Fiscale__c') or (d.get('Date_Depense__c')[:4] if d.get('Date_Depense__c') else '')

        depenses_data.append({
            'id': d.get('Id'),
            'name': d.get('Name'),
            'bien': (d.get('Bien_Locatif__r') or {}).get('Name', ''),
            'categorie': categorie,
            'nature': nature,
            'date': d.get('Date_Depense__c') or '',
            'annee': annee,
            'description': d.get('Description__c') or '',
            'total': d.get('Montant_Total__c') or 0,
            'capital': d.get('Montant_Capital__c') or 0,
            'interets': d.get('Montant_Interets__c') or 0,
            'assurance': d.get('Montant_Assurance_Pret__c') or 0,
            'charge_copro': d.get('Montant_Charge_Copro__c') or 0,
            'alur': d.get('Montant_Fonds_Travaux_loi_Alur__c') or 0,
            'statut': d.get('Statut__c') or ''
        })

    full_data = {
        'biens': biens_data,
        'paiements': paiements_data,
        'depenses': depenses_data
    }

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    reports_dir = os.path.join(base_dir, 'reports')
    os.makedirs(reports_dir, exist_ok=True)

    json_path = os.path.join(reports_dir, 'data.json')
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(full_data, f, ensure_ascii=False, indent=2)
    print(f"Fichier exporté : {json_path}")

    new_json_str = json.dumps(full_data, ensure_ascii=False)
    replacement_line = f'        const SFDC_DATA = {new_json_str};\n'

    for filename in ['rapport_annuel_2026.html']:
        html_path = os.path.join(reports_dir, filename)
        if not os.path.exists(html_path):
            continue
        with open(html_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        for i, line in enumerate(lines):
            if 'const SFDC_DATA = ' in line:
                lines[i] = replacement_line
                break
        with open(html_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"Rapport statique synchronisé : {html_path}")

    print("\nSynchronisation terminée avec succès !")

if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else 'gestion-locative'
    sync_dashboard(target)
