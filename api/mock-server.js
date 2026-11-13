#!/usr/bin/env node
/**
 * Мок-сервер учебного API «Хоккейная лига».
 *
 * Контракт: КОНТРАКТ-API.md
 * Данные: seed.json (сброс — POST /api/__reset)
 *
 *   node mock-server.js
 *   node mock-server.js --port 8080 --origin http://localhost:5555
 *
 * Учебные параметры: ?__delay=1500  ?__fail=500
 */

'use strict';

const http = require('node:http');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const args = process.argv.slice(2);
function arg(name, fallback) {
  const i = args.indexOf('--' + name);
  return i !== -1 && args[i + 1] ? args[i + 1] : fallback;
}

const PORT = Number(arg('port', 8080));
const ORIGIN = arg('origin', '*');
const SECRET = 'учебный-ключ-не-для-продакшена';
const ACCESS_TTL = Number(arg('ttl', 900));
const REFRESH_TTL = 60 * 60 * 24 * 7;
const SEED_FILE = path.join(__dirname, 'seed.json');

const COLLECTIONS = ['players', 'teams', 'arenas', 'achievements'];
const PLAYER_CATEGORIES = [
  'Нападающий',
  'Защитник',
  'Вратарь',
  'Тренер',
  'Спортивный директор',
];

let db;

// ─────────────────────────────── токены ───────────────────────────────

function b64url(buf) {
  return Buffer.from(buf).toString('base64url');
}

function sign(payload) {
  const withId = { ...payload, jti: crypto.randomUUID() };
  const body = b64url(JSON.stringify(withId));
  const mac = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  return body + '.' + mac;
}

function verify(token) {
  if (typeof token !== 'string' || !token.includes('.')) return null;
  const [body, mac] = token.split('.');
  const expected = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  if (mac !== expected) return null;
  let payload;
  try {
    payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
  if (payload.exp && payload.exp * 1000 < Date.now()) return null;
  return payload;
}

function hash(password) {
  return crypto.createHash('sha256').update(password + SECRET).digest('hex');
}

// ─────────────────────────────── данные ───────────────────────────────

function push(collection, obj) {
  db.seq[collection] = (db.seq[collection] || 0) + 1;
  const id = db.seq[collection];
  db[collection].push({ id, ...obj, createdAt: new Date().toISOString(), deletedAt: null });
  return id;
}

function loadSeed() {
  const raw = JSON.parse(fs.readFileSync(SEED_FILE, 'utf8'));
  db = {
    seq: {},
    arenas: [],
    achievements: [],
    teams: [],
    players: [],
    users: [],
    refreshTokens: new Set(),
  };

  for (const col of COLLECTIONS) {
    for (const row of raw[col] || []) {
      db.seq[col] = Math.max(db.seq[col] || 0, row.id);
      const item = {
        ...row,
        createdAt: row.createdAt || new Date().toISOString(),
        deletedAt: row.deletedAt ?? null,
      };
      if (col === 'players') item.achievementIds = row.achievementIds || [];
      db[col].push(item);
    }
  }

  db.users = [
    {
      id: 1,
      username: 'admin',
      passwordHash: hash('admin123'),
      fullName: 'Администратор',
      email: 'admin@hockey.local',
      role: 'admin',
      createdAt: new Date().toISOString(),
      deletedAt: null,
    },
    {
      id: 2,
      username: 'librarian',
      passwordHash: hash('librarian123'),
      fullName: 'Менеджер лиги',
      email: 'manager@hockey.local',
      role: 'librarian',
      createdAt: new Date().toISOString(),
      deletedAt: null,
    },
    {
      id: 3,
      username: 'reader',
      passwordHash: hash('reader123'),
      fullName: 'Наблюдатель',
      email: 'reader@hockey.local',
      role: 'reader',
      createdAt: new Date().toISOString(),
      deletedAt: null,
    },
  ];
  db.seq.users = 3;
}

function teamNameById(id) {
  const t = db.teams.find((x) => x.id === id);
  return t ? t.name : '';
}

function arenaNameById(id) {
  const a = db.arenas.find((x) => x.id === id);
  return a ? a.name : '';
}

function activePlayerCount(teamId) {
  return db.players.filter((p) => p.teamId === teamId && !p.deletedAt).length;
}

function teamCountForArena(arenaId) {
  return db.teams.filter((t) => t.arenaId === arenaId && !t.deletedAt).length;
}

function holderCountForAchievement(achievementId) {
  return db.players.filter(
    (p) => !p.deletedAt && (p.achievementIds || []).includes(achievementId),
  ).length;
}

function nextContractId() {
  let max = 0;
  for (const p of db.players) {
    const id = p.contract?.id ?? 0;
    if (id > max) max = id;
  }
  return max + 1;
}

function contractEntries() {
  const rows = [];
  for (const player of db.players) {
    if (!player.contract) continue;
    const c = player.contract;
    rows.push({
      id: c.id,
      playerId: player.id,
      playerName: player.name,
      number: c.number,
      email: c.email,
      salary: c.salary,
      signedAt: c.signedAt,
      expiresAt: c.expiresAt ?? null,
      deletedAt: player.deletedAt,
    });
  }
  return rows;
}

function findPlayerByContractId(contractId) {
  return db.players.find((p) => p.contract?.id === contractId);
}

// ──────────────────────── развёртывание объектов ────────────────────────

function expandPlayer(p) {
  const team = db.teams.find((t) => t.id === p.teamId);
  const achievements = (p.achievementIds || [])
    .map((id) => db.achievements.find((a) => a.id === id))
    .filter(Boolean)
    .map((a) => ({ id: a.id, name: a.name }));
  return {
    id: p.id,
    name: p.name,
    description: p.description,
    price: p.price,
    category: p.category,
    teamId: p.teamId,
    team: team ? { id: team.id, name: team.name } : null,
    achievementIds: p.achievementIds || [],
    achievements,
    jerseyNumber: p.jerseyNumber ?? null,
    contract: p.contract ? { ...p.contract } : null,
    createdAt: p.createdAt,
    deletedAt: p.deletedAt,
  };
}

function expandTeam(t) {
  return {
    id: t.id,
    name: t.name,
    city: t.city,
    foundedYear: t.foundedYear,
    arenaId: t.arenaId,
    arenaName: arenaNameById(t.arenaId),
    rosterSize: activePlayerCount(t.id),
    createdAt: t.createdAt,
    deletedAt: t.deletedAt,
  };
}

function expandArena(a) {
  return {
    id: a.id,
    name: a.name,
    city: a.city,
    capacity: a.capacity,
    teamCount: teamCountForArena(a.id),
    createdAt: a.createdAt,
    deletedAt: a.deletedAt,
  };
}

function expandAchievement(a) {
  return {
    id: a.id,
    name: a.name,
    description: a.description,
    year: a.year,
    holderCount: holderCountForAchievement(a.id),
    createdAt: a.createdAt,
    deletedAt: a.deletedAt,
  };
}

function expandContract(e) {
  return { ...e };
}

function expandUser(u) {
  return {
    id: u.id,
    username: u.username,
    fullName: u.fullName,
    email: u.email,
    role: u.role,
  };
}

const EXPANDERS = {
  players: expandPlayer,
  teams: expandTeam,
  arenas: expandArena,
  achievements: expandAchievement,
  contracts: expandContract,
};

// ─────────────────────────── фильтры и сортировка ───────────────────────────

function searchableText(collection, item) {
  switch (collection) {
    case 'players':
      return [
        item.name,
        item.description,
        item.category,
        item.jerseyNumber ?? '',
        item.contract?.email ?? '',
      ].join(' ');
    case 'teams':
      return [item.name, item.city].join(' ');
    case 'arenas':
      return [item.name, item.city].join(' ');
    case 'achievements':
      return [item.name, item.description].join(' ');
    case 'contracts':
      return [item.email, item.playerName, item.number].join(' ');
    default:
      return '';
  }
}

function applyFilters(collection, rows, q) {
  let result = rows;

  if (q.search) {
    const needle = String(q.search).toLowerCase();
    result = result.filter((x) =>
      searchableText(collection, x).toLowerCase().includes(needle),
    );
  }

  if (collection === 'players') {
    if (q.category) result = result.filter((p) => p.category === q.category);
    if (q.teamId) result = result.filter((p) => p.teamId === Number(q.teamId));
    if (q.achievementId) {
      const aid = Number(q.achievementId);
      result = result.filter((p) => (p.achievementIds || []).includes(aid));
    }
    if (q.priceFrom) result = result.filter((p) => p.price >= Number(q.priceFrom));
    if (q.priceTo) result = result.filter((p) => p.price <= Number(q.priceTo));
  }

  if (collection === 'teams') {
    if (q.city) result = result.filter((t) => t.city === q.city);
    if (q.arenaId) result = result.filter((t) => t.arenaId === Number(q.arenaId));
    const rosters = Object.fromEntries(result.map((t) => [t.id, activePlayerCount(t.id)]));
    if (q.playersFrom) {
      result = result.filter((t) => rosters[t.id] >= Number(q.playersFrom));
    }
    if (q.playersTo) {
      result = result.filter((t) => rosters[t.id] <= Number(q.playersTo));
    }
  }

  if (collection === 'arenas') {
    if (q.city) result = result.filter((a) => a.city === q.city);
    if (q.capacityFrom) result = result.filter((a) => a.capacity >= Number(q.capacityFrom));
    if (q.capacityTo) result = result.filter((a) => a.capacity <= Number(q.capacityTo));
  }

  if (collection === 'achievements') {
    if (q.yearFrom) result = result.filter((a) => a.year >= Number(q.yearFrom));
    if (q.yearTo) result = result.filter((a) => a.year <= Number(q.yearTo));
  }

  if (collection === 'contracts') {
    const expiring =
      q.expiringSoon === 'true' || q.expiring === 'true';
    if (expiring) {
      const limit = Date.now() + 180 * 86400000;
      result = result.filter(
        (e) => e.expiresAt && new Date(e.expiresAt).getTime() < limit,
      );
    }
    if (q.minSalary) result = result.filter((e) => e.salary >= Number(q.minSalary));
    if (q.maxSalary) result = result.filter((e) => e.salary <= Number(q.maxSalary));
  }

  return result;
}

function compareRows(collection, a, b, field) {
  switch (collection) {
    case 'players':
      if (field === 'price') return a.price - b.price;
      if (field === 'jerseyNumber') return (a.jerseyNumber ?? 0) - (b.jerseyNumber ?? 0);
      if (field === 'team') {
        return teamNameById(a.teamId)
          .toLowerCase()
          .localeCompare(teamNameById(b.teamId).toLowerCase(), 'ru');
      }
      if (field === 'category') return String(a.category).localeCompare(String(b.category), 'ru');
      if (field === 'achievements') {
        return (a.achievementIds?.length ?? 0) - (b.achievementIds?.length ?? 0);
      }
      if (field === 'contract') {
        return (a.contract?.salary ?? 0) - (b.contract?.salary ?? 0);
      }
      if (field === 'id') return a.id - b.id;
      return String(a.name).toLowerCase().localeCompare(String(b.name).toLowerCase(), 'ru');
  case 'teams':
      if (field === 'city') return String(a.city).localeCompare(String(b.city), 'ru');
      if (field === 'foundedYear') return a.foundedYear - b.foundedYear;
      if (field === 'players') return activePlayerCount(a.id) - activePlayerCount(b.id);
      if (field === 'id') return a.id - b.id;
      return String(a.name).toLowerCase().localeCompare(String(b.name).toLowerCase(), 'ru');
    case 'arenas':
      if (field === 'city') return String(a.city).localeCompare(String(b.city), 'ru');
      if (field === 'capacity') return a.capacity - b.capacity;
      if (field === 'teams') return teamCountForArena(a.id) - teamCountForArena(b.id);
      if (field === 'id') return a.id - b.id;
      return String(a.name).toLowerCase().localeCompare(String(b.name).toLowerCase(), 'ru');
    case 'achievements':
      if (field === 'year') return a.year - b.year;
      if (field === 'holders') {
        return holderCountForAchievement(a.id) - holderCountForAchievement(b.id);
      }
      if (field === 'id') return a.id - b.id;
      return String(a.name).toLowerCase().localeCompare(String(b.name).toLowerCase(), 'ru');
    case 'contracts':
      if (field === 'player') {
        return String(a.playerName).toLowerCase().localeCompare(String(b.playerName).toLowerCase(), 'ru');
      }
      if (field === 'number') return a.number - b.number;
      if (field === 'salary') return a.salary - b.salary;
      if (field === 'signedAt') {
        return new Date(a.signedAt) - new Date(b.signedAt);
      }
      if (field === 'expiresAt') {
        const ae = a.expiresAt ? new Date(a.expiresAt) : new Date(9999, 0, 1);
        const be = b.expiresAt ? new Date(b.expiresAt) : new Date(9999, 0, 1);
        return ae - be;
      }
      if (field === 'id') return a.id - b.id;
      return String(a.email).toLowerCase().localeCompare(String(b.email).toLowerCase(), 'ru');
    default:
      return 0;
  }
}

function applySort(collection, rows, sort, fallback = 'name') {
  if (!sort) {
    const [field, dirRaw] = [fallback, 'asc'];
    const dir = dirRaw === 'desc' ? -1 : 1;
    return [...rows].sort((a, b) => compareRows(collection, a, b, field) * dir);
  }
  const [field, dirRaw] = String(sort).split(',');
  const dir = (dirRaw || 'asc').toLowerCase() === 'desc' ? -1 : 1;
  return [...rows].sort((a, b) => compareRows(collection, a, b, field || fallback) * dir);
}

function paginate(rows, q) {
  const page = Math.max(1, Number(q.page) || 1);
  const size = Math.min(100, Math.max(1, Number(q.size) || 10));
  const total = rows.length;
  const totalPages = Math.max(1, Math.ceil(total / size));
  const safePage = Math.min(page, totalPages);
  return {
    items: rows.slice((safePage - 1) * size, safePage * size),
    page: safePage,
    size,
    total,
    totalPages,
  };
}

// ─────────────────────────────── валидация ───────────────────────────────

function jerseyTaken(number, exceptId = null) {
  return db.players.some(
    (p) => p.id !== exceptId && p.jerseyNumber === number,
  );
}

function contractEmailTaken(email, exceptPlayerId = null) {
  const needle = String(email).trim().toLowerCase();
  return db.players.some(
    (p) =>
      p.id !== exceptPlayerId &&
      p.contract &&
      p.contract.email.trim().toLowerCase() === needle,
  );
}

function validate(collection, body, id = null) {
  const e = {};
  const str = (v) => (typeof v === 'string' ? v.trim() : v == null ? '' : String(v).trim());

  if (collection === 'players') {
    if (!str(body.name)) e.name = 'Укажите имя игрока';
    else if (str(body.name).length > 120) e.name = 'Не длиннее 120 символов';
    if (!str(body.category)) e.category = 'Укажите амплуа';
    else if (!PLAYER_CATEGORIES.includes(str(body.category))) {
      e.category = 'Недопустимое амплуа';
    }
    const teamId = Number(body.teamId);
    if (!Number.isInteger(teamId) || teamId < 1) e.teamId = 'Укажите команду';
    else if (!db.teams.find((t) => t.id === teamId && !t.deletedAt)) {
      e.teamId = 'Команда не найдена';
    }
    const price = Number(body.price);
    if (body.price == null || Number.isNaN(price) || price < 0) {
      e.price = 'Цена — неотрицательное число';
    }
    if (body.jerseyNumber != null && body.jerseyNumber !== '') {
      const jersey = Number(body.jerseyNumber);
      if (!Number.isInteger(jersey) || jersey < 1 || jersey > 99) {
        e.jerseyNumber = 'Номер на свитере — целое от 1 до 99';
      } else if (jerseyTaken(jersey, id)) {
        e.jerseyNumber = 'Этот номер уже занят в лиге';
      }
    }
    if (body.contract) {
      const c = body.contract;
      if (!str(c.email)) e['contract.email'] = 'Укажите email контракта';
      else if (!/^[\w.+-]+@[\w-]+(\.[\w-]+)+$/.test(str(c.email))) {
        e['contract.email'] = 'Некорректный адрес почты';
      } else if (contractEmailTaken(str(c.email), id)) {
        e['contract.email'] = 'Этот адрес уже указан у другого игрока';
      }
      const salary = Number(c.salary);
      if (Number.isNaN(salary) || salary < 0) e['contract.salary'] = 'Укажите оклад';
      if (!c.signedAt) e['contract.signedAt'] = 'Укажите дату подписания';
    }
  }

  if (collection === 'teams') {
    if (!str(body.name)) e.name = 'Укажите название команды';
    if (!str(body.city)) e.city = 'Укажите город';
    const arenaId = Number(body.arenaId);
    if (!Number.isInteger(arenaId) || arenaId < 1) e.arenaId = 'Укажите арену';
    else if (!db.arenas.find((a) => a.id === arenaId && !a.deletedAt)) {
      e.arenaId = 'Арена не найдена';
    }
    const fy = Number(body.foundedYear);
    if (body.foundedYear != null && (!Number.isInteger(fy) || fy < 1800 || fy > new Date().getFullYear())) {
      e.foundedYear = 'Некорректный год основания';
    }
  }

  if (collection === 'arenas') {
    if (!str(body.name)) e.name = 'Укажите название арены';
    if (!str(body.city)) e.city = 'Укажите город';
    const cap = Number(body.capacity);
    if (!Number.isInteger(cap) || cap < 1) e.capacity = 'Вместимость — положительное целое';
  }

  if (collection === 'achievements') {
    if (!str(body.name)) e.name = 'Укажите название награды';
    const year = Number(body.year);
    if (!Number.isInteger(year)) e.year = 'Год — целое число';
    else if (year < 1900 || year > new Date().getFullYear() + 1) {
      e.year = 'Некорректный год';
    }
  }

  if (collection === 'contracts') {
    if (!str(body.email)) e.email = 'Укажите email';
    else if (contractEmailTaken(str(body.email), body.playerId ?? findPlayerByContractId(id)?.id)) {
      e.email = 'Этот адрес уже указан у другого игрока';
    }
    const salary = Number(body.salary);
    if (Number.isNaN(salary) || salary < 0) e.salary = 'Укажите оклад';
    if (!body.signedAt) e.signedAt = 'Укажите дату подписания';
  }

  return e;
}

function normalize(collection, body) {
  const num = (v) => (v == null || v === '' ? null : Number(v));
  const str = (v) => (v == null ? '' : String(v).trim());
  const ids = (v) => (Array.isArray(v) ? v.map(Number).filter((n) => Number.isInteger(n)) : []);

  switch (collection) {
    case 'players': {
      let contract = null;
      if (body.contract && typeof body.contract === 'object') {
        contract = {
          id: num(body.contract.id) || nextContractId(),
          number: num(body.contract.number) || nextContractId(),
          email: str(body.contract.email),
          salary: num(body.contract.salary) ?? 0,
          signedAt: body.contract.signedAt || new Date().toISOString(),
          expiresAt: body.contract.expiresAt ?? null,
        };
      } else if (body.clearContract === true) {
        contract = null;
      }
      return {
        name: str(body.name),
        description: str(body.description),
        price: num(body.price) ?? 0,
        category: str(body.category),
        teamId: num(body.teamId),
        achievementIds: ids(body.achievementIds),
        jerseyNumber:
          body.jerseyNumber == null || body.jerseyNumber === ''
            ? null
            : num(body.jerseyNumber),
        contract,
      };
    }
    case 'teams':
      return {
        name: str(body.name),
        city: str(body.city),
        foundedYear: num(body.foundedYear) ?? 0,
        arenaId: num(body.arenaId),
      };
    case 'arenas':
      return {
        name: str(body.name),
        city: str(body.city),
        capacity: num(body.capacity),
      };
    case 'achievements':
      return {
        name: str(body.name),
        description: str(body.description),
        year: num(body.year),
      };
    default:
      return { ...body };
  }
}

// ──────────────────────────── HTTP-обвязка ────────────────────────────

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
  res.setHeader('Vary', 'Origin');
}

function send(res, status, payload) {
  cors(res);
  if (payload === undefined || status === 204) {
    res.writeHead(status === 204 ? 204 : status);
    res.end();
    return;
  }
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function fail(res, status, message) {
  send(res, status, { message });
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null;
  }
}

function resolveUser(req) {
  const header = req.headers['authorization'] || '';
  if (header.startsWith('Bearer ')) {
    const payload = verify(header.slice(7));
    if (!payload || payload.type !== 'access') return null;
    return db.users.find((u) => u.id === payload.sub && !u.deletedAt) || null;
  }
  if (!header) {
    return {
      id: -1,
      username: '_anonymous',
      fullName: 'Аноним (учебный режим)',
      role: 'librarian',
      _implicit: true,
    };
  }
  return null;
}

const ROLE_LEVEL = { reader: 1, librarian: 2, admin: 3 };

function requireRole(res, user, minRole) {
  if (!user) {
    fail(res, 401, 'Требуется аутентификация');
    return false;
  }
  if (user._implicit && minRole === 'admin') {
    fail(res, 403, 'Операция доступна начиная с роли «admin» (нужен Bearer-токен)');
    return false;
  }
  if (ROLE_LEVEL[user.role] < ROLE_LEVEL[minRole]) {
    fail(res, 403, `Операция доступна начиная с роли «${minRole}»`);
    return false;
  }
  return true;
}

function hardDeleteRow(collection, id) {
  if (collection === 'arenas') {
    const linked = db.teams.filter((t) => t.arenaId === id && !t.deletedAt).length;
    if (linked > 0) {
      return {
        error: true,
        status: 409,
        body: {
          message:
            `На арену ссылаются команды: ${linked}. Сначала перенесите их на другую арену или удалите.`,
          count: linked,
        },
      };
    }
  }
  if (collection === 'teams') {
    const active = activePlayerCount(id);
    if (active > 0) {
      return {
        error: true,
        status: 409,
        body: {
          message: `В команде ${active} активных игроков. Сначала переведите или удалите игроков.`,
          count: active,
        },
      };
    }
  }
  const index = db[collection].findIndex((x) => x.id === id);
  if (index === -1) return { error: true, status: 404, body: { message: 'Объект не найден' } };
  db[collection].splice(index, 1);
  return { error: false };
}

async function handleContracts(req, res, url, method, user, q) {
  const path = url.pathname.replace(/\/+$/, '') || '/';
  if (!path.startsWith('/api/contracts')) return false;

  let m = path.match(/^\/api\/contracts\/bulk-delete$/);
  if (m && method === 'POST') {
    if (!requireRole(res, user, 'librarian')) return;
    const body = await readBody(req);
    const ids = Array.isArray(body?.ids) ? body.ids.map(Number) : [];
    const physical = body?.physical === true;
    if (!ids.length) {
      return send(res, 422, {
        message: 'Ошибка валидации',
        errors: { ids: 'Передайте непустой список идентификаторов' },
      });
    }
    if (physical && !requireRole(res, user, 'admin')) return;

    let deleted = 0;
    for (const cid of ids) {
      const player = findPlayerByContractId(cid);
      if (!player) continue;
      if (physical) {
        if (!player.contract) continue;
        player.contract = null;
      } else if (!player.deletedAt) {
        player.deletedAt = new Date().toISOString();
      } else continue;
      deleted += 1;
    }
    return send(res, 200, { deleted });
  }

  m = path.match(/^\/api\/contracts\/(\d+)(?:\/(restore))?$/);
  if (m) {
    const contractId = Number(m[1]);
    const action = m[2] || null;
    const player = findPlayerByContractId(contractId);
    if (!player || !player.contract) return fail(res, 404, 'Контракт не найден');

    if (action === 'restore' && method === 'POST') {
      if (!requireRole(res, user, 'admin')) return;
      player.deletedAt = null;
      const entry = contractEntries().find((e) => e.id === contractId);
      return send(res, 200, expandContract(entry));
    }

    if (method === 'GET') {
      const entry = contractEntries().find(
        (e) => e.id === contractId && (q.includeDeleted === 'true' || !e.deletedAt),
      );
      if (!entry) return fail(res, 404, 'Контракт не найден');
      return send(res, 200, expandContract(entry));
    }

    if (method === 'PUT' || method === 'PATCH') {
      if (!requireRole(res, user, 'librarian')) return;
      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
      const merged = {
        ...expandContract(contractEntries().find((e) => e.id === contractId)),
        ...body,
        playerId: player.id,
        id: contractId,
      };
      const errors = validate('contracts', merged, contractId);
      if (Object.keys(errors).length) {
        return send(res, 422, { message: 'Ошибка валидации', errors });
      }
      player.contract = {
        id: contractId,
        number: Number(body.number ?? player.contract.number),
        email: String(body.email ?? player.contract.email).trim(),
        salary: Number(body.salary ?? player.contract.salary),
        signedAt: body.signedAt ?? player.contract.signedAt,
        expiresAt: body.expiresAt !== undefined ? body.expiresAt : player.contract.expiresAt,
      };
      const entry = contractEntries().find((e) => e.id === contractId);
      return send(res, 200, expandContract(entry));
    }

    if (method === 'DELETE') {
      const hard = q.hard === 'true';
      if (!requireRole(res, user, hard ? 'admin' : 'librarian')) return;
      if (hard) {
        player.contract = null;
      } else {
        player.deletedAt = new Date().toISOString();
      }
      return send(res, 204);
    }
  }

  if (path === '/api/contracts' && method === 'GET') {
    let rows = contractEntries();
    if (q.includeDeleted !== 'true') rows = rows.filter((e) => !e.deletedAt);
    rows = applyFilters('contracts', rows, q);
    const fallback = 'email';
    rows = applySort('contracts', rows, q.sort, fallback);
    const page = paginate(rows, q);
    return send(res, 200, { ...page, items: page.items.map(expandContract) });
  }

  return fail(res, 404, `Адрес ${method} ${path} не обслуживается`);
}

async function handle(req, res, url) {
  const q = Object.fromEntries(url.searchParams.entries());
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = req.method.toUpperCase();
  const user = resolveUser(req);

  if (q.__fail) {
    return fail(res, Number(q.__fail), 'Ошибка вызвана намеренно параметром __fail');
  }

  if (path === '/api/__reset' && method === 'POST') {
    loadSeed();
    return send(res, 200, { message: 'Данные восстановлены в исходное состояние' });
  }

  if (path === '/api/__health' && method === 'GET') {
    return send(res, 200, { status: 'ok', time: new Date().toISOString() });
  }

  if (path === '/api/auth/register' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    const errors = {};
    const username = String(body.username || '').trim();
    const password = String(body.password || '');
    if (username.length < 3) errors.username = 'Логин не короче трёх символов';
    else if (db.users.find((u) => u.username === username)) errors.username = 'Такой логин уже занят';
    if (password.length < 8) errors.password = 'Пароль не короче восьми символов';
    else if (!/\d/.test(password)) errors.password = 'Пароль должен содержать цифру';
    if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });
    const id = push('users', {
      username,
      passwordHash: hash(password),
      fullName: String(body.fullName || username),
      email: String(body.email || ''),
      role: 'reader',
    });
    return send(res, 201, expandUser(db.users.find((u) => u.id === id)));
  }

  if (path === '/api/auth/login' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    const found = db.users.find(
      (u) => u.username === String(body.username || '').trim() && !u.deletedAt,
    );
    if (!found || found.passwordHash !== hash(String(body.password || ''))) {
      return fail(res, 401, 'Неверный логин или пароль');
    }
    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({ sub: found.id, role: found.role, type: 'access', exp: now + ACCESS_TTL });
    const refreshToken = sign({ sub: found.id, type: 'refresh', exp: now + REFRESH_TTL });
    db.refreshTokens.add(refreshToken);
    return send(res, 200, {
      accessToken,
      refreshToken,
      expiresIn: ACCESS_TTL,
      user: expandUser(found),
    });
  }

  if (path === '/api/auth/refresh' && method === 'POST') {
    const body = await readBody(req);
    const token = body && body.refreshToken;
    const payload = verify(token);
    if (!payload || payload.type !== 'refresh' || !db.refreshTokens.has(token)) {
      return fail(res, 401, 'Токен обновления недействителен');
    }
    const found = db.users.find((u) => u.id === payload.sub);
    if (!found) return fail(res, 401, 'Пользователь не найден');
    db.refreshTokens.delete(token);
    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({ sub: found.id, role: found.role, type: 'access', exp: now + ACCESS_TTL });
    const refreshToken = sign({ sub: found.id, type: 'refresh', exp: now + REFRESH_TTL });
    db.refreshTokens.add(refreshToken);
    return send(res, 200, { accessToken, refreshToken, expiresIn: ACCESS_TTL, user: expandUser(found) });
  }

  if (path === '/api/auth/me' && method === 'GET') {
    if (!user || user._implicit) return fail(res, 401, 'Требуется аутентификация');
    return send(res, 200, expandUser(user));
  }

  if (path === '/api/auth/logout' && method === 'POST') {
    const body = await readBody(req);
    if (body?.refreshToken) db.refreshTokens.delete(body.refreshToken);
    return send(res, 204);
  }

  const contractHandled = await handleContracts(req, res, url, method, user, q);
  if (contractHandled !== false) return;

  const bulk = path.match(/^\/api\/([a-z]+)\/bulk-delete$/);
  if (bulk && method === 'POST') {
    const collection = bulk[1];
    if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
    if (!requireRole(res, user, 'librarian')) return;
    const body = await readBody(req);
    const ids = Array.isArray(body?.ids) ? body.ids.map(Number) : [];
    const physical = body?.physical === true;
    if (!ids.length) {
      return send(res, 422, {
        message: 'Ошибка валидации',
        errors: { ids: 'Передайте непустой список идентификаторов' },
      });
    }
    if (physical && !requireRole(res, user, 'admin')) return;

    let deleted = 0;
    for (const rowId of ids) {
      if (physical) {
        const result = hardDeleteRow(collection, rowId);
        if (!result.error) deleted += 1;
      } else {
        const row = db[collection].find((x) => x.id === rowId && !x.deletedAt);
        if (row) {
          row.deletedAt = new Date().toISOString();
          deleted += 1;
        }
      }
    }
    return send(res, 200, { deleted });
  }

  const m = path.match(/^\/api\/([a-z]+)(?:\/(\d+))?(?:\/(restore))?$/);
  if (m) {
    const collection = m[1];
    const id = m[2] ? Number(m[2]) : null;
    const action = m[3] || null;

    if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
    const expand = EXPANDERS[collection];
    const sortFallback = collection === 'players' ? 'name' : 'name';

    if (action === 'restore' && method === 'POST') {
      if (!requireRole(res, user, 'admin')) return;
      const row = db[collection].find((x) => x.id === id);
      if (!row) return fail(res, 404, 'Объект не найден');
      row.deletedAt = null;
      return send(res, 200, expand(row));
    }

    if (id === null && method === 'GET') {
      let rows = db[collection];
      if (q.includeDeleted !== 'true') rows = rows.filter((x) => !x.deletedAt);
      rows = applyFilters(collection, rows, q);
      rows = applySort(collection, rows, q.sort, sortFallback);
      const page = paginate(rows, q);
      return send(res, 200, { ...page, items: page.items.map(expand) });
    }

    if (id !== null && method === 'GET') {
      const row = db[collection].find(
        (x) => x.id === id && (q.includeDeleted === 'true' || !x.deletedAt),
      );
      if (!row) return fail(res, 404, 'Объект не найден');
      return send(res, 200, expand(row));
    }

    if (id === null && method === 'POST') {
      if (!requireRole(res, user, 'librarian')) return;
      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
      const errors = validate(collection, body);
      if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });
      const data = normalize(collection, body);
      if (collection === 'players' && data.contract && !data.contract.id) {
        data.contract.id = nextContractId();
      }
      const newId = push(collection, data);
      const row = db[collection].find((x) => x.id === newId);
      return send(res, 201, expand(row));
    }

    if (id !== null && (method === 'PUT' || method === 'PATCH')) {
      if (!requireRole(res, user, 'librarian')) return;
      const row = db[collection].find((x) => x.id === id && !x.deletedAt);
      if (!row) return fail(res, 404, 'Объект не найден');
      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
      const merged =
        method === 'PATCH'
          ? { ...row, ...body, contract: body.contract ?? row.contract }
          : body;
      if (body.clearContract) merged.contract = null;
      const errors = validate(collection, merged, id);
      if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });
      const normalized = normalize(collection, { ...merged, id });
      if (normalized.contract && row.contract) {
        normalized.contract.id = row.contract.id;
      }
      Object.assign(row, normalized);
      return send(res, 200, expand(row));
    }

    if (id !== null && method === 'DELETE') {
      const hard = q.hard === 'true';
      if (!requireRole(res, user, hard ? 'admin' : 'librarian')) return;
      if (hard) {
        const result = hardDeleteRow(collection, id);
        if (result.error) return send(res, result.status, result.body);
      } else {
        const row = db[collection].find((x) => x.id === id);
        if (!row) return fail(res, 404, 'Объект не найден');
        row.deletedAt = new Date().toISOString();
      }
      return send(res, 204);
    }
  }

  return fail(res, 404, `Адрес ${method} ${path} не обслуживается`);
}

// ─────────────────────────────── запуск ───────────────────────────────

loadSeed();

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  if (req.method === 'OPTIONS') {
    cors(res);
    res.writeHead(204);
    return res.end();
  }

  const delay = Number(url.searchParams.get('__delay') || 0);
  if (delay > 0) await new Promise((r) => setTimeout(r, Math.min(delay, 10000)));

  const started = Date.now();
  try {
    await handle(req, res, url);
  } catch (err) {
    console.error(err);
    if (!res.headersSent) fail(res, 500, 'Внутренняя ошибка сервера: ' + err.message);
  }
  console.log(
    `${req.method.padEnd(6)} ${url.pathname}${url.search}  → ${res.statusCode}  ${Date.now() - started} мс`,
  );
});

server.listen(PORT, () => {
  console.log('');
  console.log('  Учебное API «Хоккейная лига»');
  console.log(`  Адрес:                http://localhost:${PORT}/api`);
  console.log(`  Разрешённый источник: ${ORIGIN}`);
  console.log(`  Данные:               ${SEED_FILE}`);
  console.log('');
  console.log('  Учётные записи:  admin/admin123   librarian/librarian123   reader/reader123');
  console.log('  Без Authorization заголовка запись разрешена как librarian (учебный режим).');
  console.log('  Сброс данных:    POST /api/__reset');
  console.log('  Здоровье:        GET /api/__health');
  console.log('');
});
