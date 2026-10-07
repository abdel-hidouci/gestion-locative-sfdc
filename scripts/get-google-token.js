const http = require('http');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;
const PORT = 3000;
const REDIRECT_URI = `http://localhost:${PORT}/oauth2callback`;

const SCOPES = [
  'https://www.googleapis.com/auth/gmail.readonly',
  'https://www.googleapis.com/auth/gmail.send',
  'https://www.googleapis.com/auth/gmail.modify',
  'https://www.googleapis.com/auth/drive.readonly',
  'https://www.googleapis.com/auth/drive.file',
  'https://www.googleapis.com/auth/drive',
].join(' ');

const authUrlLocal = `https://accounts.google.com/o/oauth2/v2/auth?client_id=${CLIENT_ID}&redirect_uri=${encodeURIComponent(
  REDIRECT_URI
)}&response_type=code&scope=${encodeURIComponent(SCOPES)}&access_type=offline&prompt=select_account%20consent`;

console.log('\n========================================================================');
console.log('👉 1. Ouvrez ce lien dans votre navigateur (tentative d\'ouverture auto...) :');
console.log('========================================================================\n');
console.log(authUrlLocal);
console.log('\n========================================================================');
console.log('👉 2. Connectez-vous avec votre compte Gmail (ex: abdel.hidouci@gmail.com)');
console.log('========================================================================\n');

// Ouvrir automatiquement le navigateur par défaut sur macOS
exec(`open "${authUrlLocal}"`, (err) => {
  if (!err) {
    console.log('🌐 Navigateur ouvert automatiquement.\n');
  }
});

async function saveTokens(tokenData, email) {
  if (tokenData.refresh_token) {
    console.log('\n🎉 SUCCÈS ! Refresh Token obtenu avec succès !');
    console.log('Compte connecté :', email || 'inconnu');
    console.log('Refresh Token   :', tokenData.refresh_token.substring(0, 15) + '...');

    const envPath = path.resolve(__dirname, '../.env');
    let envContent = fs.existsSync(envPath) ? fs.readFileSync(envPath, 'utf8') : '';

    if (!envContent.includes('GOOGLE_CLIENT_ID')) {
      envContent += `\nGOOGLE_CLIENT_ID=${CLIENT_ID}`;
    }
    if (!envContent.includes('GOOGLE_CLIENT_SECRET')) {
      envContent += `\nGOOGLE_CLIENT_SECRET=${CLIENT_SECRET}`;
    }
    if (email && !envContent.includes('GMAIL_USER_EMAIL')) {
      envContent += `\nGMAIL_USER_EMAIL=${email}`;
    } else if (email) {
      envContent = envContent.replace(/GMAIL_USER_EMAIL=.*/g, `GMAIL_USER_EMAIL=${email}`);
    }

    if (!envContent.includes('GOOGLE_REFRESH_TOKEN')) {
      envContent += `\nGOOGLE_REFRESH_TOKEN=${tokenData.refresh_token}\n`;
    } else {
      envContent = envContent.replace(/GOOGLE_REFRESH_TOKEN=.*/g, `GOOGLE_REFRESH_TOKEN=${tokenData.refresh_token}`);
    }

    fs.writeFileSync(envPath, envContent.trim() + '\n');
    console.log('✅ Configuration enregistrée dans .env !\n');
    return true;
  } else {
    console.error('❌ Erreur : Aucun refresh_token retourné par Google :', tokenData);
    console.log('💡 Astuce : Assurez-vous d\'avoir cliqué sur "Continuer" et validé les autorisations.');
    return false;
  }
}

const server = http.createServer(async (req, res) => {
  if (req.url.startsWith('/oauth2callback')) {
    const url = new URL(req.url, `http://localhost:${PORT}`);
    const code = url.searchParams.get('code');

    if (code) {
      try {
        const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({
            code: code,
            client_id: CLIENT_ID,
            client_secret: CLIENT_SECRET,
            redirect_uri: REDIRECT_URI,
            grant_type: 'authorization_code',
          }),
        });

        const tokenData = await tokenRes.json();
        let connectedEmail = '';

        if (tokenData.access_token) {
          try {
            const profileRes = await fetch('https://gmail.googleapis.com/gmail/v1/users/me/profile', {
              headers: { Authorization: `Bearer ${tokenData.access_token}` },
            });
            const profile = await profileRes.json();
            connectedEmail = profile.emailAddress || '';
            console.log('\n📧 Compte Google connecté :', connectedEmail);
          } catch (e) {
            console.warn('Impossible de récupérer l\'adresse e-mail du profil :', e.message);
          }
        }

        const success = await saveTokens(tokenData, connectedEmail);

        if (success) {
          res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end(`
            <html>
              <head><title>Connexion Réussie</title></head>
              <body style="font-family: -apple-system, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f7f9fc;">
                <div style="background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); text-align: center; max-width: 480px;">
                  <h1 style="color: #2e7d32; margin-bottom: 12px;">Connexion réussie ! 🎉</h1>
                  <p style="color: #444; font-size: 16px;">Votre serveur MCP <strong>abdel-hidouci-gmail</strong> est maintenant configuré pour :</p>
                  <p style="font-weight: bold; color: #1976d2; font-size: 18px; margin: 16px 0;">${connectedEmail || 'votre compte Gmail'}</p>
                  <p style="color: #666; font-size: 14px;">Vous pouvez fermer cet onglet et revenir dans votre IDE.</p>
                </div>
              </body>
            </html>
          `);
          setTimeout(() => process.exit(0), 1000);
        } else {
          res.writeHead(400, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end(`<h1>Erreur de connexion</h1><pre>${JSON.stringify(tokenData, null, 2)}</pre>`);
        }
      } catch (err) {
        console.error('Erreur échange code:', err);
        res.writeHead(500, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end('<h1>Erreur serveur</h1><p>' + err.message + '</p>');
      }
    }
  }
});

server.listen(PORT, () => {
  console.log(`(Serveur d'écoute local actif sur http://localhost:${PORT})`);
});
