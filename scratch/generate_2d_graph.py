import json
import os

graph_path = 'lib/graphify-out/graph.json'
out_dir = 'lib/graphify-out'

if not os.path.exists(graph_path):
    print(f"File {graph_path} not found.")
    exit(1)

with open(graph_path, 'r', encoding='utf-8') as f:
    graph_data = json.load(f)

nodes = graph_data.get('nodes', [])
links = graph_data.get('links', [])

# 2D Graph HTML
html_2d = """<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8">
<title>Graphify 2D Interactive Map - SQNPI Audit Manager</title>
<script src="https://unpkg.com/force-graph"></script>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #070814; color: #e0e0e0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; overflow: hidden; height: 100vh; width: 100vw; }
  #graph2d { width: 100vw; height: 100vh; position: absolute; top: 0; left: 0; }
  
  #hud { position: absolute; top: 16px; left: 16px; z-index: 10; background: rgba(10, 12, 26, 0.94); backdrop-filter: blur(20px); border: 1px solid rgba(255,255,255,0.16); padding: 18px 22px; border-radius: 16px; color: #fff; width: 380px; box-shadow: 0 16px 56px rgba(0,0,0,0.85); }
  #hud h1 { font-size: 19px; font-weight: 800; color: #64B5F6; margin-bottom: 4px; display: flex; align-items: center; gap: 10px; }
  #hud p { font-size: 12px; color: #9a9ab8; margin-bottom: 14px; }

  #search-wrap { margin-bottom: 12px; }
  #search-input { width: 100%; background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.18); border-radius: 8px; padding: 9px 12px; color: #fff; font-size: 12px; outline: none; }
  #search-input:focus { border-color: #64B5F6; background: rgba(255,255,255,0.14); }

  .btn { background: rgba(100,181,246,0.15); border: 1px solid rgba(100,181,246,0.35); color: #64B5F6; padding: 8px 12px; border-radius: 8px; font-size: 12px; font-weight: 700; cursor: pointer; text-decoration: none; display: inline-block; transition: all 0.2s; }
  .btn:hover { background: #64B5F6; color: #000; }

  #info-box { position: absolute; bottom: 24px; right: 24px; z-index: 10; background: rgba(12, 14, 28, 0.95); backdrop-filter: blur(18px); border: 1px solid rgba(255,255,255,0.2); border-radius: 16px; padding: 20px 22px; width: 380px; color: #e0e0e0; display: none; box-shadow: 0 16px 64px rgba(0,0,0,0.85); }
  #info-box h2 { font-size: 16px; color: #fff; margin-bottom: 8px; word-break: break-all; }
  #info-box .field { font-size: 12px; margin-bottom: 6px; color: #aaa; }
  #info-box .field b { color: #fff; }
</style>
</head>
<body>

<div id="hud">
  <h1>🗺️ Graphify 2D Interactive Map</h1>
  <p>Mappa bidimensionale vettoriale del codice del progetto.</p>
  
  <div id="search-wrap">
    <input type="text" id="search-input" placeholder="🔍 Cerca qualsiasi classe o file...">
  </div>

  <div style="display:flex; gap:8px;">
    <a href="graph_3d.html" class="btn">🚀 Vista 3D</a>
    <a href="dashboard.html" class="btn">📊 Dashboard</a>
    <button class="btn" onclick="Graph.zoomToFit(1000, 50)">🎥 Centra</button>
  </div>
</div>

<div id="info-box">
  <h2 id="info-title">Node Label</h2>
  <div class="field"><b>File Sorgente:</b> <span id="info-file">-</span></div>
  <div class="field"><b>Modulo:</b> <span id="info-community">-</span></div>
</div>

<div id="graph2d"></div>

<script>
const gData = %GRAPH_DATA_JSON%;

const palette = [
  '#4E79A7', '#F28E2B', '#E15759', '#76B7B2', '#59A14F', '#EDC948',
  '#B07AA1', '#FF9DA7', '#9C755F', '#BAB0AC', '#3182bd', '#e6550d'
];

function getCommunityColor(commId) {
  return palette[(parseInt(commId) || 0) % palette.length];
}

gData.nodes.forEach(n => {
  n.color = getCommunityColor(n.community);
  n.val = 3;
});

const Graph = ForceGraph()(document.getElementById('graph2d'))
  .graphData(gData)
  .nodeId('id')
  .nodeLabel(n => `${n.label} (${n.source_file || ''})`)
  .nodeColor('color')
  .nodeRelSize(4)
  .linkOpacity(0.2)
  .onNodeClick(node => {
    Graph.centerAt(node.x, node.y, 1000);
    Graph.zoom(3, 1000);
    document.getElementById('info-title').innerText = node.label;
    document.getElementById('info-file').innerText = node.source_file || '-';
    document.getElementById('info-community').innerText = node.community_name || ('Community ' + node.community);
    document.getElementById('info-box').style.display = 'block';
  });

const searchInput = document.getElementById('search-input');
searchInput.addEventListener('input', (e) => {
  const query = e.target.value.toLowerCase().trim();
  if (!query) return;
  const match = gData.nodes.find(n => n.label.toLowerCase().includes(query));
  if (match) {
    Graph.centerAt(match.x, match.y, 1000);
    Graph.zoom(3.5, 1000);
  }
});
</script>
</body>
</html>
"""

html_2d_final = html_2d.replace('%GRAPH_DATA_JSON%', json.dumps(graph_data, ensure_ascii=False))

with open(os.path.join(out_dir, 'graph_2d.html'), 'w', encoding='utf-8') as f:
    f.write(html_2d_final)

# Index Suite Hub HTML
html_index = """<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8">
<title>Graphify Studio Hub - SQNPI Audit Manager</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #050612; color: #e0e0e0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; display: flex; flex-direction: column; justify-content: center; align-items: center; min-height: 100vh; padding: 20px; }
  .hub-container { max-width: 900px; width: 100%; text-align: center; }
  h1 { font-size: 36px; font-weight: 800; color: #64B5F6; margin-bottom: 10px; letter-spacing: -0.5px; }
  p { color: #889; font-size: 16px; margin-bottom: 40px; }

  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 24px; text-align: left; }
  .card { background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.1); border-radius: 20px; padding: 30px 24px; text-decoration: none; color: #fff; transition: all 0.25s; backdrop-filter: blur(10px); display: flex; flex-direction: column; justify-content: space-between; }
  .card:hover { transform: translateY(-6px); border-color: #64B5F6; background: rgba(100,181,246,0.08); box-shadow: 0 20px 40px rgba(0,0,0,0.6); }
  .card-icon { font-size: 40px; margin-bottom: 16px; }
  .card-title { font-size: 20px; font-weight: 800; color: #fff; margin-bottom: 8px; }
  .card-desc { font-size: 13px; color: #9a9ab8; line-height: 1.5; margin-bottom: 20px; }
  .card-action { font-size: 13px; font-weight: 700; color: #64B5F6; display: flex; align-items: center; gap: 6px; }
</style>
</head>
<body>

<div class="hub-container">
  <h1>🌌 Graphify Studio Portal</h1>
  <p>Centro di controllo architetturale tridimensionale e analitico per SQNPI Audit Manager</p>

  <div class="grid">
    <a href="graph_3d.html" class="card">
      <div>
        <div class="card-icon">🚀</div>
        <div class="card-title">Quantum 3D Engine</div>
        <div class="card-desc">Visualizzatore 3D WebGL con percorsi laser, audio fx sintetico, temi visivi e 2.684 nodi interattivi.</div>
      </div>
      <div class="card-action">Apri Engine 3D →</div>
    </a>

    <a href="dashboard.html" class="card">
      <div>
        <div class="card-icon">📊</div>
        <div class="card-title">Architecture Analytics</div>
        <div class="card-desc">Dashboard di analisi con metriche, lista God Nodes, tabelle di connessione e grafici dei moduli.</div>
      </div>
      <div class="card-action">Apri Dashboard →</div>
    </a>

    <a href="graph_2d.html" class="card">
      <div>
        <div class="card-icon">🗺️</div>
        <div class="card-title">Interactive 2D Map</div>
        <div class="card-desc">Mappa 2D vettoriale ad altissima velocità con zoom, ricerca istantanea ed ispezione dei componenti.</div>
      </div>
      <div class="card-action">Apri Mappa 2D →</div>
    </a>
  </div>
</div>

</body>
</html>
"""

with open(os.path.join(out_dir, 'index.html'), 'w', encoding='utf-8') as f:
    f.write(html_index)

print("Generated 2D Map and Suite Portal Index successfully.")
