const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');
const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;
function getRefreshToken() {
  try {
    const envPath = path.resolve(__dirname, '../.env');
    if (fs.existsSync(envPath)) {
      const content = fs.readFileSync(envPath, 'utf8');
      const match = content.match(/^GOOGLE_REFRESH_TOKEN=(.+)$/m);
      if (match && match[1]) {
        return match[1].trim();
      }
    }
  } catch (e) {
    // fallback
  }
  return process.env.GOOGLE_REFRESH_TOKEN;
}

let cachedAccessToken = null;
let lastRefreshToken = null;
let tokenExpiresAt = 0;

async function getAccessToken() {
  const refreshToken = getRefreshToken();
  if (!refreshToken) {
    throw new Error("GOOGLE_REFRESH_TOKEN est manquant. Exécutez 'node scripts/get-google-token.js' pour vous connecter.");
  }

  if (cachedAccessToken && lastRefreshToken === refreshToken && Date.now() < tokenExpiresAt - 60000) {
    return cachedAccessToken;
  }

  lastRefreshToken = refreshToken;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: refreshToken,
      grant_type: 'refresh_token',
    }),
  });

  const data = await res.json();
  if (!data.access_token) {
    cachedAccessToken = null;
    tokenExpiresAt = 0;
    throw new Error(`Erreur renouvellement token Google: ${JSON.stringify(data)}`);
  }

  cachedAccessToken = data.access_token;
  tokenExpiresAt = Date.now() + (data.expires_in || 3600) * 1000;
  return cachedAccessToken;
}

async function gmailRequest(endpoint, params = {}, options = {}) {
  const token = await getAccessToken();
  const url = new URL(`https://gmail.googleapis.com/gmail/v1/users/me${endpoint}`);
  Object.keys(params).forEach((key) => {
    if (params[key] !== undefined && params[key] !== null) {
      url.searchParams.append(key, params[key]);
    }
  });

  const fetchOptions = {
    method: options.method || 'GET',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  };

  if (options.body) {
    fetchOptions.body = typeof options.body === 'string' ? options.body : JSON.stringify(options.body);
  }

  const res = await fetch(url.toString(), fetchOptions);

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Erreur Gmail API (${res.status}): ${err}`);
  }

  if (res.status === 204) {
    return { success: true };
  }

  return await res.json();
}

async function driveRequest(endpoint, params = {}, options = {}) {
  const token = await getAccessToken();
  const url = new URL(`https://www.googleapis.com/drive/v3${endpoint}`);
  Object.keys(params).forEach((key) => {
    if (params[key] !== undefined && params[key] !== null) {
      url.searchParams.append(key, params[key]);
    }
  });

  const fetchOptions = {
    method: options.method || 'GET',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  };

  if (options.body) {
    fetchOptions.body = typeof options.body === 'string' ? options.body : JSON.stringify(options.body);
  }

  const res = await fetch(url.toString(), fetchOptions);

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Erreur Drive API (${res.status}): ${err}`);
  }

  return await res.json();
}

function makeRawMessage({ to, subject, body, cc, attachments }) {
  if (!attachments || attachments.length === 0) {
    const headers = [
      `To: ${to}`,
      cc ? `Cc: ${cc}` : null,
      `Subject: =?utf-8?B?${Buffer.from(subject).toString('base64')}?=`,
      'Content-Type: text/plain; charset=utf-8',
      'MIME-Version: 1.0',
    ].filter(Boolean).join('\r\n');

    const rawMessage = `${headers}\r\n\r\n${body}`;

    return Buffer.from(rawMessage)
      .toString('base64')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');
  }

  const mixedBoundary = '000000000000' + Math.random().toString(16).substring(2) + Math.random().toString(16).substring(2);
  const altBoundary = '000000000000' + Math.random().toString(16).substring(2) + Math.random().toString(16).substring(2);

  const headerLines = [
    `To: ${to}`,
    cc ? `Cc: ${cc}` : null,
    `Subject: =?utf-8?B?${Buffer.from(subject).toString('base64')}?=`,
    'MIME-Version: 1.0',
    `Content-Type: multipart/mixed; boundary="${mixedBoundary}"`,
  ].filter(Boolean).join('\r\n');

  const htmlBody = `<div dir="ltr">${body.replace(/\r\n/g, '<br>').replace(/\n/g, '<br>')}</div>`;

  const mimeParts = [
    `--${mixedBoundary}`,
    `Content-Type: multipart/alternative; boundary="${altBoundary}"`,
    '',
    `--${altBoundary}`,
    'Content-Type: text/plain; charset="UTF-8"',
    'Content-Transfer-Encoding: 8bit',
    '',
    body,
    '',
    `--${altBoundary}`,
    'Content-Type: text/html; charset="UTF-8"',
    'Content-Transfer-Encoding: 8bit',
    '',
    htmlBody,
    '',
    `--${altBoundary}--`
  ];

  for (const att of attachments) {
    let contentBuf;
    let filename = att.filename || 'attachment.pdf';
    let contentType = att.contentType || 'application/pdf';

    if (att.path) {
      filename = att.filename || path.basename(att.path);
      contentBuf = fs.readFileSync(att.path);
    } else if (att.contentBase64) {
      contentBuf = Buffer.from(att.contentBase64, 'base64');
    } else if (Buffer.isBuffer(att.content)) {
      contentBuf = att.content;
    }

    if (contentBuf) {
      const base64Content = contentBuf.toString('base64');
      const chunks = [];
      for (let i = 0; i < base64Content.length; i += 76) {
        chunks.push(base64Content.substring(i, i + 76));
      }
      const formattedBase64 = chunks.join('\r\n');
      const attachId = 'f_' + Date.now().toString(36) + Math.random().toString(36).substring(2, 6);

      mimeParts.push(
        `--${mixedBoundary}`,
        `Content-Type: ${contentType}; name="${filename}"`,
        `Content-Disposition: attachment; filename="${filename}"`,
        'Content-Transfer-Encoding: base64',
        `X-Attachment-Id: ${attachId}`,
        `Content-ID: <${attachId}>`,
        '',
        formattedBase64
      );
    }
  }

  mimeParts.push(`--${mixedBoundary}--`, '');

  const fullMime = `${headerLines}\r\n\r\n${mimeParts.join('\r\n')}`;
  return Buffer.from(fullMime)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function extractBody(payload) {
  if (!payload) return '';
  if (payload.body && payload.body.data) {
    return Buffer.from(payload.body.data, 'base64').toString('utf8');
  }
  if (payload.parts) {
    for (const part of payload.parts) {
      if (part.mimeType === 'text/plain' && part.body && part.body.data) {
        return Buffer.from(part.body.data, 'base64').toString('utf8');
      }
      if (part.parts) {
        const nested = extractBody(part);
        if (nested) return nested;
      }
    }
    for (const part of payload.parts) {
      if (part.mimeType === 'text/html' && part.body && part.body.data) {
        return Buffer.from(part.body.data, 'base64').toString('utf8');
      }
    }
  }
  return '';
}

const server = new Server(
  {
    name: 'abdel-hidouci-gmail',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'gmail_list_messages',
        description: 'Recherche et liste les e-mails de la boîte de réception avec filtres (ex: "in:inbox", "from:...", pagination).',
        inputSchema: {
          type: 'object',
          properties: {
            q: { type: 'string', description: 'Requête de recherche Gmail (ex: "in:inbox", "is:unread", "newer_than:7d")' },
            maxResults: { type: 'number', description: 'Nombre de messages à retourner (défaut: 10, max: 50)' },
            pageToken: { type: 'string', description: 'Token de pagination pour la page suivante' },
          },
        },
      },
      {
        name: 'gmail_get_message',
        description: 'Récupère le contenu détaillé d\'un e-mail (expéditeur, destinataires, date, objet, corps du message).',
        inputSchema: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID du message Gmail' },
          },
          required: ['id'],
        },
      },
      {
        name: 'gmail_get_thread',
        description: 'Récupère tous les messages d\'un fil de conversation complet.',
        inputSchema: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID du fil de discussion (threadId)' },
          },
          required: ['id'],
        },
      },
      {
        name: 'gmail_send_message',
        description: 'Envoie un e-mail depuis le compte Gmail professionnel.',
        inputSchema: {
          type: 'object',
          properties: {
            to: { type: 'string', description: 'Adresse e-mail du destinataire' },
            subject: { type: 'string', description: 'Objet de l\'e-mail' },
            body: { type: 'string', description: 'Contenu du message (texte brut)' },
            cc: { type: 'string', description: 'Adresse(s) en copie' },
            attachments: {
              type: 'array',
              description: 'Liste de pièces jointes (objets avec filename, contentType, et soit path local, soit contentBase64)',
              items: {
                type: 'object',
                properties: {
                  filename: { type: 'string', description: 'Nom du fichier' },
                  contentType: { type: 'string', description: 'Type MIME (ex: application/pdf)' },
                  path: { type: 'string', description: 'Chemin local du fichier à joindre' },
                  contentBase64: { type: 'string', description: 'Contenu encodé en base64' }
                }
              }
            }
          },
          required: ['to', 'subject', 'body'],
        },
      },
      {
        name: 'gmail_list_drafts',
        description: 'Liste les brouillons d\'e-mails enregistrés sur le compte.',
        inputSchema: {
          type: 'object',
          properties: {
            maxResults: { type: 'number', description: 'Nombre de brouillons à retourner (défaut: 10, max: 50)' },
            pageToken: { type: 'string', description: 'Token de pagination' },
          },
        },
      },
      {
        name: 'gmail_get_draft',
        description: 'Récupère les détails d\'un brouillon (sujet, destinataire, date, contenu brut).',
        inputSchema: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID du brouillon Gmail' },
          },
          required: ['id'],
        },
      },
      {
        name: 'gmail_create_draft',
        description: 'Crée un nouveau brouillon d\'e-mail dans Gmail (supporte les pièces jointes PDF/fichiers).',
        inputSchema: {
          type: 'object',
          properties: {
            to: { type: 'string', description: 'Adresse e-mail du destinataire' },
            subject: { type: 'string', description: 'Objet de l\'e-mail' },
            body: { type: 'string', description: 'Contenu du message' },
            cc: { type: 'string', description: 'Adresse(s) en copie' },
            attachments: {
              type: 'array',
              description: 'Liste de pièces jointes (objets avec filename, contentType, et soit path local, soit contentBase64)',
              items: {
                type: 'object',
                properties: {
                  filename: { type: 'string', description: 'Nom du fichier' },
                  contentType: { type: 'string', description: 'Type MIME (ex: application/pdf)' },
                  path: { type: 'string', description: 'Chemin local du fichier à joindre' },
                  contentBase64: { type: 'string', description: 'Contenu encodé en base64' }
                }
              }
            }
          },
          required: ['to', 'subject', 'body'],
        },
      },
      {
        name: 'gmail_update_draft',
        description: 'Met à jour un brouillon d\'e-mail existant dans Gmail (supporte les pièces jointes).',
        inputSchema: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID du brouillon à modifier' },
            to: { type: 'string', description: 'Adresse e-mail du destinataire' },
            subject: { type: 'string', description: 'Objet de l\'e-mail' },
            body: { type: 'string', description: 'Nouveau contenu du message' },
            cc: { type: 'string', description: 'Adresse(s) en copie' },
            attachments: {
              type: 'array',
              description: 'Liste de pièces jointes (objets avec filename, contentType, et soit path local, soit contentBase64)',
              items: {
                type: 'object',
                properties: {
                  filename: { type: 'string', description: 'Nom du fichier' },
                  contentType: { type: 'string', description: 'Type MIME (ex: application/pdf)' },
                  path: { type: 'string', description: 'Chemin local du fichier à joindre' },
                  contentBase64: { type: 'string', description: 'Contenu encodé en base64' }
                }
              }
            }
          },
          required: ['id', 'to', 'subject', 'body'],
        },
      },
      {
        name: 'gmail_delete_draft',
        description: 'Supprime un brouillon d\'e-mail.',
        inputSchema: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID du brouillon à supprimer' },
          },
          required: ['id'],
        },
      },
      {
        name: 'gmail_send_draft',
        description: 'Envoie un brouillon d\'e-mail existant dans Gmail.',
        inputSchema: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID du brouillon à envoyer' },
          },
          required: ['id'],
        },
      },
      {
        name: 'gdrive_list_files',
        description: 'Liste les fichiers et dossiers dans Google Drive avec filtres (ex: dossiers à la racine, type de fichier).',
        inputSchema: {
          type: 'object',
          properties: {
            q: { type: 'string', description: 'Requête Drive (ex: "\'root\' in parents and trashed = false")' },
            pageSize: { type: 'number', description: 'Nombre de résultats (défaut: 10, max: 50)' },
            pageToken: { type: 'string', description: 'Token de pagination' },
          },
        },
      },
      {
        name: 'gdrive_get_file_metadata',
        description: 'Récupère les détails et métadonnées d\'un fichier Google Drive (nom, taille, type, lien web).',
        inputSchema: {
          type: 'object',
          properties: {
            fileId: { type: 'string', description: 'ID du fichier Google Drive' },
          },
          required: ['fileId'],
        },
      },
      {
        name: 'gdrive_read_file_content',
        description: 'Lit et télécharge le contenu texte d\'un fichier Google Drive ou exporte un Google Doc en texte ou Google Sheet en CSV.',
        inputSchema: {
          type: 'object',
          properties: {
            fileId: { type: 'string', description: 'ID du fichier' },
            mimeType: { type: 'string', description: 'Type MIME du fichier' },
          },
          required: ['fileId'],
        },
      },
      {
        name: 'gdrive_create_folder',
        description: 'Crée un nouveau dossier dans Google Drive.',
        inputSchema: {
          type: 'object',
          properties: {
            name: { type: 'string', description: 'Nom du dossier' },
            parentId: { type: 'string', description: 'ID du dossier parent (optionnel, "root" par défaut)' },
          },
          required: ['name'],
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'gmail_list_messages': {
        const params = {
          q: (args && args.q) || 'in:inbox',
          maxResults: (args && args.maxResults) || 10,
        };
        if (args && args.pageToken) params.pageToken = args.pageToken;

        const list = await gmailRequest('/messages', params);
        const messages = [];

        if (list.messages && list.messages.length > 0) {
          for (const item of list.messages) {
            try {
              const fullMsg = await gmailRequest(`/messages/${item.id}?format=metadata&metadataHeaders=Subject&metadataHeaders=From&metadataHeaders=To&metadataHeaders=Date`);
              const headers = {};
              (fullMsg.payload.headers || []).forEach(h => {
                headers[h.name.toLowerCase()] = h.value;
              });
              messages.push({
                id: item.id,
                threadId: item.threadId,
                from: headers['from'] || '',
                to: headers['to'] || '',
                subject: headers['subject'] || '(Sans objet)',
                date: headers['date'] || '',
                snippet: fullMsg.snippet || '',
              });
            } catch (e) {
              messages.push({ id: item.id, threadId: item.threadId });
            }
          }
        }

        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              resultSizeEstimate: list.resultSizeEstimate,
              nextPageToken: list.nextPageToken,
              messages: messages
            }, null, 2)
          }],
        };
      }

      case 'gmail_get_message': {
        const { id } = args;
        const msg = await gmailRequest(`/messages/${id}?format=full`);
        const headers = {};
        (msg.payload.headers || []).forEach(h => {
          headers[h.name.toLowerCase()] = h.value;
        });

        const bodyText = extractBody(msg.payload);

        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              id: msg.id,
              threadId: msg.threadId,
              from: headers['from'],
              to: headers['to'],
              subject: headers['subject'],
              date: headers['date'],
              snippet: msg.snippet,
              body: bodyText
            }, null, 2)
          }],
        };
      }

      case 'gmail_get_thread': {
        const { id } = args;
        const thread = await gmailRequest(`/threads/${id}`);
        return {
          content: [{ type: 'text', text: JSON.stringify(thread, null, 2) }],
        };
      }

      case 'gmail_send_message': {
        const { to, subject, body, cc, attachments } = args;
        const raw = makeRawMessage({ to, subject, body, cc, attachments });
        const data = await gmailRequest('/messages/send', {}, {
          method: 'POST',
          body: { raw }
        });

        return {
          content: [{ type: 'text', text: `Message envoyé avec succès ! ID: ${data.id}` }],
        };
      }

      case 'gmail_list_drafts': {
        const params = {
          maxResults: (args && args.maxResults) || 10,
        };
        if (args && args.pageToken) params.pageToken = args.pageToken;

        const list = await gmailRequest('/drafts', params);
        const drafts = [];

        if (list.drafts && list.drafts.length > 0) {
          for (const item of list.drafts) {
            try {
              const fullDraft = await gmailRequest(`/drafts/${item.id}?format=full`);
              const headers = {};
              (fullDraft.message.payload.headers || []).forEach(h => {
                headers[h.name.toLowerCase()] = h.value;
              });
              drafts.push({
                id: item.id,
                messageId: fullDraft.message.id,
                to: headers['to'] || '',
                subject: headers['subject'] || '(Sans objet)',
                date: headers['date'] || '',
                body: extractBody(fullDraft.message.payload),
              });
            } catch (e) {
              drafts.push({ id: item.id });
            }
          }
        }

        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              resultSizeEstimate: list.resultSizeEstimate,
              nextPageToken: list.nextPageToken,
              drafts: drafts
            }, null, 2)
          }],
        };
      }

      case 'gmail_get_draft': {
        const { id } = args;
        const draft = await gmailRequest(`/drafts/${id}?format=full`);
        const headers = {};
        (draft.message.payload.headers || []).forEach(h => {
          headers[h.name.toLowerCase()] = h.value;
        });

        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              id: draft.id,
              messageId: draft.message.id,
              to: headers['to'],
              subject: headers['subject'],
              date: headers['date'],
              body: extractBody(draft.message.payload),
            }, null, 2)
          }],
        };
      }

      case 'gmail_create_draft': {
        const { to, subject, body, cc, attachments } = args;
        const raw = makeRawMessage({ to, subject, body, cc, attachments });
        const data = await gmailRequest('/drafts', {}, {
          method: 'POST',
          body: { message: { raw } }
        });

        return {
          content: [{ type: 'text', text: `Brouillon créé avec succès ! ID: ${data.id}` }],
        };
      }

      case 'gmail_update_draft': {
        const { id, to, subject, body, cc, attachments } = args;
        const raw = makeRawMessage({ to, subject, body, cc, attachments });
        const data = await gmailRequest(`/drafts/${id}`, {}, {
          method: 'PUT',
          body: { message: { raw } }
        });

        return {
          content: [{ type: 'text', text: `Brouillon mis à jour avec succès ! ID: ${data.id}` }],
        };
      }

      case 'gmail_delete_draft': {
        const { id } = args;
        await gmailRequest(`/drafts/${id}`, {}, { method: 'DELETE' });
        return {
          content: [{ type: 'text', text: `Brouillon ${id} supprimé avec succès !` }],
        };
      }

      case 'gmail_send_draft': {
        const { id } = args;
        const data = await gmailRequest('/drafts/send', {}, {
          method: 'POST',
          body: { id }
        });
        return {
          content: [{ type: 'text', text: `Brouillon envoyé avec succès ! ID Message: ${data.id}` }],
        };
      }

      case 'gdrive_list_files': {
        const params = {
          q: (args && args.q) || 'trashed = false',
          pageSize: (args && args.pageSize) || 10,
          fields: 'nextPageToken, files(id, name, mimeType, size, modifiedTime, webViewLink, parents)',
        };
        if (args && args.pageToken) params.pageToken = args.pageToken;

        const data = await driveRequest('/files', params);
        return {
          content: [{ type: 'text', text: JSON.stringify(data.files || data, null, 2) }],
        };
      }

      case 'gdrive_get_file_metadata': {
        const { fileId } = args;
        const data = await driveRequest(`/files/${fileId}`, {
          fields: 'id, name, mimeType, size, createdTime, modifiedTime, webViewLink, parents, owners',
        });
        return {
          content: [{ type: 'text', text: JSON.stringify(data, null, 2) }],
        };
      }

      case 'gdrive_read_file_content': {
        const { fileId, mimeType } = args;
        const token = await getAccessToken();

        let fetchUrl;
        if (mimeType && mimeType.includes('google-apps.document')) {
          fetchUrl = `https://www.googleapis.com/drive/v3/files/${fileId}/export?mimeType=text/plain`;
        } else if (mimeType && mimeType.includes('google-apps.spreadsheet')) {
          fetchUrl = `https://www.googleapis.com/drive/v3/files/${fileId}/export?mimeType=text/csv`;
        } else {
          fetchUrl = `https://www.googleapis.com/drive/v3/files/${fileId}?alt=media`;
        }

        const res = await fetch(fetchUrl, {
          headers: { 'Authorization': `Bearer ${token}` }
        });

        const textContent = await res.text();
        return {
          content: [{ type: 'text', text: textContent }],
        };
      }

      case 'gdrive_create_folder': {
        const { name, parentId } = args;
        const metadata = {
          name: name,
          mimeType: 'application/vnd.google-apps.folder',
        };
        if (parentId && parentId !== 'root') {
          metadata.parents = [parentId];
        }

        const data = await driveRequest('/files', {}, {
          method: 'POST',
          body: metadata,
        });

        return {
          content: [{ type: 'text', text: JSON.stringify(data, null, 2) }],
        };
      }

      default:
        throw new Error(`Outil inconnu : ${name}`);
    }
  } catch (err) {
    return {
      isError: true,
      content: [{ type: 'text', text: `Erreur Google MCP : ${err.message || err}` }],
    };
  }
});

async function run() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

run().catch(() => {
  process.exit(1);
});
