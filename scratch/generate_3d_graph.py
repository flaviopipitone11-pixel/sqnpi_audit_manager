import json
import os

graph_path = 'lib/graphify-out/graph.json'
out_path = 'lib/graphify-out/graph_3d.html'

if not os.path.exists(graph_path):
    print(f"File {graph_path} not found.")
    exit(1)

with open(graph_path, 'r', encoding='utf-8') as f:
    graph_data = json.load(f)

nodes = graph_data.get('nodes', [])
links = graph_data.get('links', [])
print(f"Loaded {len(nodes)} nodes and {len(links)} links.")

html_template = """<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8">
<title>Graphify 3D VR Engine - Ultimate Architecture Galaxy</title>
<script src="https://unpkg.com/3d-force-graph@1.73.3/dist/3d-force-graph.min.js"></script>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #04040c; color: #e0e0e0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; overflow: hidden; height: 100vh; width: 100vw; transition: background 0.4s; }
  #graph3d { width: 100vw; height: 100vh; position: absolute; top: 0; left: 0; }
  
  #hud { position: absolute; top: 16px; left: 16px; z-index: 10; background: rgba(8, 8, 20, 0.93); backdrop-filter: blur(22px); border: 1px solid rgba(255,255,255,0.18); padding: 18px 22px; border-radius: 16px; color: #fff; width: 420px; box-shadow: 0 16px 56px rgba(0,0,0,0.85); max-height: calc(100vh - 32px); overflow-y: auto; }
  #hud h1 { font-size: 19px; font-weight: 800; color: #64B5F6; margin-bottom: 4px; display: flex; align-items: center; gap: 10px; letter-spacing: -0.4px; }
  #hud p { font-size: 12px; color: #9a9ab8; margin-bottom: 14px; line-height: 1.4; }

  .stats-bar { display: flex; justify-content: space-between; background: rgba(255,255,255,0.05); border-radius: 10px; padding: 8px 12px; margin-bottom: 14px; border: 1px solid rgba(255,255,255,0.08); }
  .stat-item { text-align: center; }
  .stat-val { font-size: 14px; font-weight: 800; color: #64B5F6; }
  .stat-lbl { font-size: 9px; color: #7a7a9a; text-transform: uppercase; letter-spacing: 0.5px; }

  .view-presets { display: flex; gap: 6px; margin-bottom: 12px; flex-wrap: wrap; }
  .preset-btn { flex: 1; min-width: 110px; background: rgba(100,181,246,0.14); border: 1px solid rgba(100,181,246,0.35); color: #64B5F6; padding: 8px 10px; border-radius: 8px; font-size: 11px; font-weight: 700; cursor: pointer; text-align: center; transition: all 0.2s; }
  .preset-btn:hover { background: #64B5F6; color: #000; border-color: #64B5F6; transform: translateY(-1px); }

  .tool-section { margin-bottom: 12px; background: rgba(255,255,255,0.04); border-radius: 10px; padding: 10px 12px; border: 1px solid rgba(255,255,255,0.08); }
  .tool-title { font-size: 11px; font-weight: 800; color: #64B5F6; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 8px; display: flex; align-items: center; justify-content: space-between; }

  #search-wrap { position: relative; margin-bottom: 8px; }
  #search-input { width: 100%; background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.18); border-radius: 8px; padding: 9px 12px; color: #fff; font-size: 12px; outline: none; transition: all 0.2s; }
  #search-input:focus { border-color: #64B5F6; background: rgba(255,255,255,0.14); box-shadow: 0 0 14px rgba(100,181,246,0.4); }
  #search-results { max-height: 200px; overflow-y: auto; background: #101024; border: 1px solid #334; border-radius: 10px; position: absolute; width: 100%; top: 42px; left: 0; z-index: 30; display: none; box-shadow: 0 10px 30px rgba(0,0,0,0.8); }
  .search-item { padding: 8px 12px; font-size: 12px; cursor: pointer; border-bottom: 1px solid #1a1a34; display: flex; justify-content: space-between; align-items: center; }
  .search-item:hover { background: #2a2a5e; color: #64B5F6; }

  .path-selects { display: flex; gap: 6px; margin-bottom: 8px; }
  .path-selects select { flex: 1; background: rgba(0,0,0,0.4); border: 1px solid rgba(255,255,255,0.2); color: #fff; padding: 6px; border-radius: 6px; font-size: 11px; outline: none; }

  #controls-wrap { display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 12px; }
  .btn { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.18); color: #fff; padding: 7px 11px; border-radius: 8px; font-size: 11px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
  .btn:hover { background: #64B5F6; color: #000; border-color: #64B5F6; }
  .btn.active { background: #64B5F6; color: #000; font-weight: 800; }

  .theme-bar { display: flex; gap: 6px; }
  .theme-dot { flex: 1; height: 24px; border-radius: 6px; cursor: pointer; border: 2px solid transparent; transition: transform 0.2s; font-size: 10px; font-weight: 700; display: flex; align-items: center; justify-content: center; color: #fff; text-shadow: 0 1px 2px #000; }
  .theme-dot:hover { transform: scale(1.05); }
  .theme-dot.active { border-color: #fff; }

  .god-list { max-height: 110px; overflow-y: auto; display: flex; flex-direction: column; gap: 4px; }
  .god-item { display: flex; justify-content: space-between; align-items: center; background: rgba(255,255,255,0.04); padding: 5px 10px; border-radius: 6px; font-size: 11px; cursor: pointer; transition: background 0.15s; }
  .god-item:hover { background: rgba(100,181,246,0.2); color: #64B5F6; }

  #info-box { position: absolute; bottom: 24px; right: 24px; z-index: 10; background: rgba(12, 12, 24, 0.95); backdrop-filter: blur(18px); border: 1px solid rgba(255,255,255,0.2); border-radius: 16px; padding: 20px 22px; width: 430px; color: #e0e0e0; display: none; box-shadow: 0 16px 64px rgba(0,0,0,0.85); }
  #info-box h2 { font-size: 17px; color: #fff; margin-bottom: 10px; word-break: break-all; font-weight: 700; }
  #info-box .badge { display: inline-block; padding: 4px 10px; border-radius: 6px; font-size: 11px; font-weight: 800; margin-bottom: 14px; text-transform: uppercase; letter-spacing: 0.5px; }
  #info-box .field { font-size: 12px; margin-bottom: 8px; color: #aaa; line-height: 1.4; }
  #info-box .field b { color: #fff; font-weight: 600; }
  #info-box .close-btn { position: absolute; top: 14px; right: 16px; background: none; border: none; color: #888; font-size: 18px; cursor: pointer; }
  #info-box .close-btn:hover { color: #fff; }
  #neighbors-list { max-height: 130px; overflow-y: auto; margin-top: 6px; background: rgba(0,0,0,0.3); border-radius: 6px; padding: 6px; }
  .neighbor-chip { display: inline-block; background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.12); padding: 3px 8px; border-radius: 4px; font-size: 10px; margin: 2px; cursor: pointer; }
  .neighbor-chip:hover { background: #64B5F6; color: #000; }

  #legend { position: absolute; top: 16px; right: 16px; z-index: 10; background: rgba(12, 12, 24, 0.9); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.14); padding: 16px; border-radius: 16px; max-height: 380px; overflow-y: auto; width: 280px; box-shadow: 0 12px 40px rgba(0,0,0,0.6); }
  #legend h3 { font-size: 11px; color: #7a7a9a; text-transform: uppercase; letter-spacing: 0.8px; margin-bottom: 12px; font-weight: 800; display: flex; justify-content: space-between; }
  .legend-row { display: flex; align-items: center; gap: 10px; font-size: 11px; margin-bottom: 6px; cursor: pointer; padding: 5px 8px; border-radius: 6px; transition: background 0.15s; }
  .legend-row:hover { background: rgba(255,255,255,0.12); }
  .legend-color { width: 12px; height: 12px; border-radius: 50%; flex-shrink: 0; box-shadow: 0 0 8px currentColor; }
  .legend-name { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-weight: 500; }
  .legend-count { color: #667; font-size: 10px; font-weight: 700; }

  .toast { position: absolute; bottom: 20px; left: 50%; transform: translateX(-50%); background: rgba(100,181,246,0.9); color: #000; font-weight: 800; padding: 8px 18px; border-radius: 20px; font-size: 12px; z-index: 200; pointer-events: none; opacity: 0; transition: opacity 0.3s; box-shadow: 0 4px 20px rgba(100,181,246,0.5); }

  .loading-overlay { position: absolute; top: 0; left: 0; width: 100vw; height: 100vh; background: #04040c; display: flex; flex-direction: column; justify-content: center; align-items: center; z-index: 100; color: #fff; transition: opacity 0.5s; }
  .spinner { width: 50px; height: 50px; border: 4px solid rgba(255,255,255,0.1); border-top-color: #64B5F6; border-radius: 50%; animation: spin 0.8s infinite linear; margin-bottom: 20px; }
  @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
</style>
</head>
<body>

<div id="loading" class="loading-overlay">
  <div class="spinner"></div>
  <h2 style="font-weight: 800; font-size: 22px; color: #64B5F6;">Inizializzazione Graphify VR Studio...</h2>
  <p style="color: #889; margin-top: 8px; font-size: 14px;">Caricamento della galassia di codice e forze 3D dinamiche</p>
</div>

<div id="hud">
  <h1>🌌 Graphify VR Studio 3D</h1>
  <p>Motore tridimensionale ad alte prestazioni per SQNPI Audit Manager.</p>
  
  <div class="stats-bar">
    <div class="stat-item"><div class="stat-val" id="stat-nodes">2,684</div><div class="stat-lbl">Nodi</div></div>
    <div class="stat-item"><div class="stat-val" id="stat-links">3,890</div><div class="stat-lbl">Relazioni</div></div>
    <div class="stat-item"><div class="stat-val" id="stat-modules">0</div><div class="stat-lbl">Galassie</div></div>
  </div>

  <div class="view-presets">
    <button class="preset-btn" onclick="presetOverview()">🌌 Panorama</button>
    <button class="preset-btn" onclick="presetGodNodes()">⭐ Top Hubs</button>
    <button class="preset-btn" onclick="presetClusters()">🪐 Galassie</button>
  </div>

  <div class="tool-section">
    <div class="tool-title">⚡ Dynamics 3D Force Control</div>
    <div class="view-presets" style="margin-bottom:0;">
      <button class="preset-btn" style="font-size:10px;" onclick="setForceLayout('spacious')">🌌 Spazioso</button>
      <button class="preset-btn" style="font-size:10px;" onclick="setForceLayout('compact')">🕸️ Compatto</button>
      <button class="preset-btn" style="font-size:10px;" onclick="setForceLayout('loose')">🎈 Espanso</button>
    </div>
  </div>

  <div class="tool-section">
    <div class="tool-title">📐 Calcolatore Percorso 3D (Laser Beam)</div>
    <div class="path-selects">
      <select id="path-start"><option value="">Origine Nodo A...</option></select>
      <select id="path-end"><option value="">Destinazione Nodo B...</option></select>
    </div>
    <button class="btn" style="width: 100%; font-weight: 700;" onclick="calculate3DPath()">⚡ Traccia Laser 3D</button>
  </div>

  <div id="search-wrap">
    <input type="text" id="search-input" placeholder="🔍 Cerca qualsiasi classe, file o modulo...">
    <div id="search-results"></div>
  </div>

  <div id="controls-wrap">
    <button class="btn" onclick="resetCamera()">🎥 Centra Vista</button>
    <button class="btn" onclick="toggleParticles()">✨ Flussi Dati</button>
    <button class="btn" onclick="rotateGraph()">🔄 Orbita 360°</button>
    <button class="btn" onclick="takeScreenshot()">📸 Screenshot 3D</button>
    <button class="btn" onclick="toggleSound()" id="sound-btn">🔊 Audio FX</button>
  </div>

  <div class="tool-section">
    <div class="tool-title">🎨 Temi Visivi 3D</div>
    <div class="theme-bar">
      <div class="theme-dot active" style="background: #0b0e1e;" onclick="setTheme('cyber', this)">Cyber Neon</div>
      <div class="theme-dot" style="background: #021a0c;" onclick="setTheme('matrix', this)">Matrix</div>
      <div class="theme-dot" style="background: #1a0808;" onclick="setTheme('volcanic', this)">Volcano</div>
    </div>
  </div>

  <div class="tool-section">
    <div class="tool-title">⭐ Hub Architetturali (God Nodes)</div>
    <div class="god-list" id="god-list"></div>
  </div>
</div>

<div id="legend">
  <h3>Galassie & Moduli <span id="legend-total" style="color: #64B5F6;"></span></h3>
  <div id="legend-items"></div>
</div>

<div id="info-box">
  <button class="close-btn" onclick="closeInfo()">✕</button>
  <span id="info-type-badge" class="badge" style="background: #4E79A7; color: #fff;">CODE</span>
  <h2 id="info-title">Node Label</h2>
  <div class="field"><b>File Sorgente:</b> <span id="info-file">-</span></div>
  <div class="field"><b>Modulo / Community:</b> <span id="info-community">-</span></div>
  <div class="field"><b>Connessioni Totali:</b> <span id="info-degree">0</span></div>
  <div class="field"><b>Vicini Collegati Direttamente (Clicca per saltare):</b></div>
  <div id="neighbors-list"></div>
</div>

<div id="toast" class="toast">Screenshot salvato!</div>

<div id="graph3d"></div>

<script>
const gData = %GRAPH_DATA_JSON%;

let audioCtx = null;
let soundEnabled = true;

function playSound(freq = 440, type = 'sine', duration = 0.1) {
  if (!soundEnabled) return;
  try {
    if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, audioCtx.currentTime);
    gain.gain.setValueAtTime(0.08, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + duration);
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    osc.start();
    osc.stop(audioCtx.currentTime + duration);
  } catch (e) {}
}

function showToast(msg) {
  const t = document.getElementById('toast');
  t.innerText = msg;
  t.style.opacity = '1';
  setTimeout(() => t.style.opacity = '0', 2500);
}

function toggleSound() {
  soundEnabled = !soundEnabled;
  const btn = document.getElementById('sound-btn');
  btn.innerText = soundEnabled ? '🔊 Audio FX' : '🔇 Muto';
  btn.classList.toggle('active', soundEnabled);
  if (soundEnabled) playSound(880, 'sine', 0.15);
}

const palette = [
  '#4E79A7', '#F28E2B', '#E15759', '#76B7B2', '#59A14F', '#EDC948',
  '#B07AA1', '#FF9DA7', '#9C755F', '#BAB0AC', '#3182bd', '#e6550d',
  '#31a354', '#756bb1', '#636363', '#9c9e5e', '#d6616b', '#ce6dbd'
];

function getCommunityColor(commId) {
  const id = parseInt(commId) || 0;
  return palette[id % palette.length];
}

const degrees = {};
const neighborMap = {};
const graphAdj = {};

gData.links.forEach(l => {
  const s = typeof l.source === 'object' ? l.source.id : l.source;
  const t = typeof l.target === 'object' ? l.target.id : l.target;
  degrees[s] = (degrees[s] || 0) + 1;
  degrees[t] = (degrees[t] || 0) + 1;
  
  if (!neighborMap[s]) neighborMap[s] = new Set();
  if (!neighborMap[t]) neighborMap[t] = new Set();
  neighborMap[s].add(t);
  neighborMap[t].add(s);

  if (!graphAdj[s]) graphAdj[s] = [];
  if (!graphAdj[t]) graphAdj[t] = [];
  graphAdj[s].push(t);
  graphAdj[t].push(s);
});

document.getElementById('stat-nodes').innerText = gData.nodes.length.toLocaleString();
document.getElementById('stat-links').innerText = gData.links.length.toLocaleString();

const nodeById = {};
gData.nodes.forEach(n => { nodeById[n.id] = n; });

const sortedNodes = [...gData.nodes].sort((a,b) => (degrees[b.id]||0) - (degrees[a.id]||0));
const godNodes = sortedNodes.slice(0, 15);
const godNodeIds = new Set(godNodes.map(n => n.id));

gData.nodes.forEach(n => {
  const deg = degrees[n.id] || 1;
  const isGod = godNodeIds.has(n.id);
  n.val = isGod ? Math.max(9, Math.sqrt(deg) * 3.8) : Math.max(2.2, Math.sqrt(deg) * 2.2);
  n.color = getCommunityColor(n.community);
  n.isGod = isGod;
});

const selectA = document.getElementById('path-start');
const selectB = document.getElementById('path-end');
godNodes.forEach(n => {
  const optA = document.createElement('option'); optA.value = n.id; optA.innerText = n.label; selectA.appendChild(optA);
  const optB = document.createElement('option'); optB.value = n.id; optB.innerText = n.label; selectB.appendChild(optB);
});

const godListEl = document.getElementById('god-list');
godNodes.forEach(n => {
  const item = document.createElement('div');
  item.className = 'god-item';
  item.innerHTML = `<span><b>${n.label}</b></span> <small style="color:#64B5F6;">${degrees[n.id]||0} conn.</small>`;
  item.onclick = () => { selectNode(n); focusNode(n); showNodeInfo(n); playSound(520, 'sine', 0.08); };
  godListEl.appendChild(item);
});

const communitiesMap = {};
gData.nodes.forEach(n => {
  const commId = n.community ?? 0;
  const commName = n.community_name || ('Community ' + commId);
  if (!communitiesMap[commId]) {
    communitiesMap[commId] = { name: commName, count: 0, color: getCommunityColor(commId) };
  }
  communitiesMap[commId].count++;
});

document.getElementById('stat-modules').innerText = Object.keys(communitiesMap).length;

const legendEl = document.getElementById('legend-items');
Object.keys(communitiesMap).sort((a,b) => communitiesMap[b].count - communitiesMap[a].count).forEach(cid => {
  const comm = communitiesMap[cid];
  const row = document.createElement('div');
  row.className = 'legend-row';
  row.innerHTML = `<div class="legend-color" style="background: ${comm.color};"></div><span class="legend-name">${comm.name}</span><span class="legend-count">(${comm.count})</span>`;
  row.onclick = () => filterCommunity(cid);
  legendEl.appendChild(row);
});

let highlightNodes = new Set();
let highlightLinks = new Set();
let laserPathLinks = new Set();
let selectedNode = null;
let showParticles = true;
let isAutoRotating = false;
let rotationInterval = null;
let currentTheme = 'cyber';

const elem = document.getElementById('graph3d');
const Graph = ForceGraph3D({
  rendererConfig: { preserveDrawingBuffer: true }
})(elem)
    .graphData(gData)
    .nodeId('id')
    .nodeLabel(node => `<div style="background: rgba(10,10,24,0.95); padding: 10px 14px; border-radius: 10px; color: #fff; font-family: sans-serif; font-size: 13px; border: 1.5px solid ${node.color}; box-shadow: 0 6px 24px rgba(0,0,0,0.6);"><b>${node.label}</b> ${node.isGod ? '⭐ [God Node]' : ''}<br><span style="color:#aaa; font-size: 11px;">${node.source_file || ''}</span><br><span style="color:#64B5F6; font-size: 11px;">Connessioni: ${degrees[node.id]||0}</span></div>`)
    .nodeColor(node => highlightNodes.size > 0 ? (highlightNodes.has(node.id) ? node.color : 'rgba(255,255,255,0.06)') : node.color)
    .nodeVal('val')
    .nodeRelSize(3.5)
    .linkOpacity(0.2)
    .linkColor(link => {
      if (laserPathLinks.has(link)) return '#00E676';
      const s = typeof link.source === 'object' ? link.source.id : link.source;
      const t = typeof link.target === 'object' ? link.target.id : link.target;
      if (highlightLinks.size > 0) {
        return (highlightLinks.has(link)) ? '#64B5F6' : 'rgba(255,255,255,0.02)';
      }
      return (godNodeIds.has(s) || godNodeIds.has(t)) ? '#64B5F6' : '#3a3a6e';
    })
    .linkWidth(link => laserPathLinks.has(link) ? 4 : (highlightLinks.has(link) ? 2.5 : 1))
    .linkDirectionalParticles(link => laserPathLinks.has(link) ? 5 : (highlightLinks.size > 0 ? (highlightLinks.has(link) ? 3 : 0) : (showParticles ? 2 : 0)))
    .linkDirectionalParticleSpeed(link => laserPathLinks.has(link) ? 0.012 : 0.006)
    .linkDirectionalParticleWidth(link => laserPathLinks.has(link) ? 4 : 2.5)
    .linkDirectionalParticleColor(link => laserPathLinks.has(link) ? '#00E676' : '#64B5F6')
    .onNodeClick(node => {
      playSound(600, 'sine', 0.1);
      selectNode(node);
      focusNode(node);
      showNodeInfo(node);
    })
    .onBackgroundClick(() => {
      playSound(300, 'sine', 0.05);
      clearHighlight();
      closeInfo();
    });

setTimeout(() => {
  const loadingEl = document.getElementById('loading');
  loadingEl.style.opacity = '0';
  setTimeout(() => {
    loadingEl.style.display = 'none';
    presetOverview();
  }, 400);
}, 600);

function setForceLayout(mode) {
  playSound(720, 'sine', 0.08);
  if (mode === 'spacious') {
    Graph.d3Force('charge').strength(-200);
    Graph.d3Force('link').distance(70);
    showToast('🌌 Layout Spazioso applicato');
  } else if (mode === 'compact') {
    Graph.d3Force('charge').strength(-50);
    Graph.d3Force('link').distance(25);
    showToast('🕸️ Layout Compatto applicato');
  } else if (mode === 'loose') {
    Graph.d3Force('charge').strength(-350);
    Graph.d3Force('link').distance(120);
    showToast('🎈 Layout Espanso applicato');
  }
  Graph.numDimensions(3);
}

function selectNode(node) {
  selectedNode = node;
  highlightNodes.clear();
  highlightLinks.clear();
  laserPathLinks.clear();
  
  if (node) {
    highlightNodes.add(node.id);
    const neighbors = neighborMap[node.id] || new Set();
    neighbors.forEach(nId => highlightNodes.add(nId));
    
    gData.links.forEach(link => {
      const s = typeof link.source === 'object' ? link.source.id : link.source;
      const t = typeof link.target === 'object' ? link.target.id : link.target;
      if (s === node.id || t === node.id) {
        highlightLinks.add(link);
      }
    });
  }
  
  refreshGraphStyle();
}

function calculate3DPath() {
  const startId = selectA.value;
  const endId = selectB.value;
  if (!startId || !endId || startId === endId) return;

  playSound(900, 'triangle', 0.2);

  const queue = [[startId]];
  const visited = new Set([startId]);
  let path = null;

  while (queue.length > 0) {
    const p = queue.shift();
    const curr = p[p.length - 1];
    if (curr === endId) { path = p; break; }
    for (const next of (graphAdj[curr] || [])) {
      if (!visited.has(next)) {
        visited.add(next);
        queue.push([...p, next]);
      }
    }
  }

  if (path) {
    highlightNodes.clear();
    highlightLinks.clear();
    laserPathLinks.clear();

    path.forEach(nid => highlightNodes.add(nid));
    for (let i = 0; i < path.length - 1; i++) {
      const u = path[i], v = path[i+1];
      gData.links.forEach(l => {
        const s = typeof l.source === 'object' ? l.source.id : l.source;
        const t = typeof l.target === 'object' ? l.target.id : l.target;
        if ((s === u && t === v) || (s === v && t === u)) {
          laserPathLinks.add(l);
        }
      });
    }

    refreshGraphStyle();
    focusNode(nodeById[path[0]]);
    showNodeInfo(nodeById[path[0]]);
    showToast('⚡ Traccia Laser 3D generata: ' + path.length + ' passaggi!');
  }
}

function takeScreenshot() {
  playSound(1200, 'sine', 0.15);
  setTimeout(() => {
    try {
      const canvas = elem.querySelector('canvas');
      if (canvas) {
        const link = document.createElement('a');
        link.download = 'graphify_3d_screenshot.png';
        link.href = canvas.toDataURL('image/png');
        link.click();
        showToast('📸 Screenshot 3D salvato!');
      }
    } catch (e) {
      showToast('⚠️ Impossibile salvare screenshot');
    }
  }, 100);
}

function setTheme(themeName, el) {
  currentTheme = themeName;
  playSound(750, 'sine', 0.08);
  document.querySelectorAll('.theme-dot').forEach(d => d.classList.remove('active'));
  if (el) el.classList.add('active');

  if (themeName === 'matrix') {
    document.body.style.background = '#021208';
    Graph.backgroundColor('#021208');
  } else if (themeName === 'volcanic') {
    document.body.style.background = '#120404';
    Graph.backgroundColor('#120404');
  } else {
    document.body.style.background = '#04040c';
    Graph.backgroundColor('#04040c');
  }
}

function clearHighlight() {
  selectedNode = null;
  highlightNodes.clear();
  highlightLinks.clear();
  laserPathLinks.clear();
  refreshGraphStyle();
}

function refreshGraphStyle() {
  Graph.nodeColor(Graph.nodeColor())
       .linkColor(Graph.linkColor())
       .linkWidth(Graph.linkWidth())
       .linkDirectionalParticles(Graph.linkDirectionalParticles());
}

function focusNode(node) {
  const distance = 160;
  const distRatio = 1 + distance / Math.hypot(node.x || 1, node.y || 1, node.z || 1);

  Graph.cameraPosition(
    { x: node.x * distRatio, y: node.y * distRatio, z: node.z * distRatio },
    node,
    2000
  );
}

function resetCamera() {
  playSound(500, 'sine', 0.1);
  clearHighlight();
  presetOverview();
}

function presetOverview() {
  stopRotation();
  Graph.zoomToFit(2000, 160);
  closeInfo();
}

function presetGodNodes() {
  stopRotation();
  const topGod = sortedNodes[0];
  if (topGod) {
    selectNode(topGod);
    focusNode(topGod);
    showNodeInfo(topGod);
  }
}

function presetClusters() {
  stopRotation();
  Graph.cameraPosition({ x: 0, y: 700, z: 900 }, { x: 0, y: 0, z: 0 }, 2500);
}

function showNodeInfo(node) {
  const box = document.getElementById('info-box');
  document.getElementById('info-title').innerText = node.label + (node.isGod ? ' ⭐' : '');
  document.getElementById('info-file').innerText = node.source_file || 'Non specificato';
  document.getElementById('info-community').innerText = node.community_name || ('Community ' + (node.community ?? '-'));
  document.getElementById('info-degree').innerText = degrees[node.id] || 0;
  
  const badge = document.getElementById('info-type-badge');
  badge.innerText = (node.file_type || 'CODE').toUpperCase();
  badge.style.background = node.color;
  
  const nList = document.getElementById('neighbors-list');
  nList.innerHTML = '';
  const neighbors = neighborMap[node.id] || new Set();
  neighbors.forEach(nId => {
    const neighborNode = nodeById[nId];
    if (neighborNode) {
      const chip = document.createElement('span');
      chip.className = 'neighbor-chip';
      chip.innerText = neighborNode.label;
      chip.onclick = (e) => {
        e.stopPropagation();
        playSound(650, 'sine', 0.06);
        selectNode(neighborNode);
        focusNode(neighborNode);
        showNodeInfo(neighborNode);
      };
      nList.appendChild(chip);
    }
  });

  box.style.display = 'block';
}

function closeInfo() {
  document.getElementById('info-box').style.display = 'none';
  clearHighlight();
}

function toggleParticles() {
  playSound(550, 'sine', 0.08);
  showParticles = !showParticles;
  Graph.linkDirectionalParticles(showParticles ? 2 : 0);
}

function rotateGraph() {
  playSound(700, 'sine', 0.1);
  if (isAutoRotating) {
    stopRotation();
  } else {
    isAutoRotating = true;
    let distance = 1000;
    let angle = 0;
    rotationInterval = setInterval(() => {
      angle += 0.004;
      Graph.cameraPosition({
        x: distance * Math.sin(angle),
        z: distance * Math.cos(angle),
        y: 300 * Math.sin(angle * 0.5)
      });
    }, 20);
  }
}

function stopRotation() {
  isAutoRotating = false;
  if (rotationInterval) {
    clearInterval(rotationInterval);
    rotationInterval = null;
  }
}

const searchInput = document.getElementById('search-input');
const searchResults = document.getElementById('search-results');

searchInput.addEventListener('input', (e) => {
  const query = e.target.value.toLowerCase().trim();
  if (!query) {
    searchResults.style.display = 'none';
    return;
  }
  
  const matches = gData.nodes.filter(n => 
    (n.label && n.label.toLowerCase().includes(query)) ||
    (n.source_file && n.source_file.toLowerCase().includes(query))
  ).slice(0, 15);
  
  if (matches.length === 0) {
    searchResults.style.display = 'none';
    return;
  }
  
  searchResults.innerHTML = '';
  matches.forEach(node => {
    const div = document.createElement('div');
    div.className = 'search-item';
    div.innerHTML = `<span><b>${node.label}</b> <small style="color:#889;">(${node.source_file || ''})</small></span> <small style="color:#64B5F6;">${degrees[node.id]||0} conn.</small>`;
    div.onclick = () => {
      playSound(750, 'sine', 0.08);
      selectNode(node);
      focusNode(node);
      showNodeInfo(node);
      searchResults.style.display = 'none';
      searchInput.value = node.label;
    };
    searchResults.appendChild(div);
  });
  searchResults.style.display = 'block';
});

function filterCommunity(cid) {
  playSound(800, 'sine', 0.1);
  const nodesInComm = gData.nodes.filter(n => n.community == cid);
  if (nodesInComm.length > 0) {
    const mainNode = nodesInComm.sort((a,b) => (degrees[b.id]||0) - (degrees[a.id]||0))[0];
    selectNode(mainNode);
    focusNode(mainNode);
    showNodeInfo(mainNode);
  }
}
</script>
</body>
</html>
"""

final_html = html_template.replace('%GRAPH_DATA_JSON%', json.dumps(graph_data, ensure_ascii=False))

with open(out_path, 'w', encoding='utf-8') as f:
    f.write(final_html)

print(f"Generated Graphify VR Studio at {out_path} ({len(final_html)} bytes)")
