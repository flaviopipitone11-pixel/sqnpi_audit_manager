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

# Calculate node degrees
degrees = {}
for l in links:
    s = l.get('source')
    t = l.get('target')
    degrees[s] = degrees.get(s, 0) + 1
    degrees[t] = degrees.get(t, 0) + 1

sorted_nodes = sorted(nodes, key=lambda n: degrees.get(n['id'], 0), reverse=True)
god_nodes = sorted_nodes[:20]

# Group by community
communities = {}
for n in nodes:
    comm_id = n.get('community', 0)
    comm_name = n.get('community_name', f'Modulo {comm_id}')
    if comm_id not in communities:
        communities[comm_id] = {'name': comm_name, 'count': 0, 'gods': []}
    communities[comm_id]['count'] += 1
    if n['id'] in [g['id'] for g in god_nodes]:
        communities[comm_id]['gods'].append(n['label'])

# Generate Dashboard HTML
dashboard_html = f"""<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8">
<title>SQNPI Audit Manager - Dashboard Architetturale Graphify</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<style>
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{ background: #080914; color: #e0e0e0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 30px; line-height: 1.6; }}
  .header {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; border-bottom: 1px solid rgba(255,255,255,0.1); padding-bottom: 20px; }}
  .header h1 {{ font-size: 26px; font-weight: 800; color: #64B5F6; display: flex; align-items: center; gap: 12px; }}
  .nav-btn {{ background: rgba(100,181,246,0.15); border: 1px solid #64B5F6; color: #64B5F6; padding: 9px 18px; border-radius: 10px; font-size: 13px; font-weight: 700; text-decoration: none; transition: all 0.2s; }}
  .nav-btn:hover {{ background: #64B5F6; color: #000; }}

  .grid-4 {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 20px; margin-bottom: 30px; }}
  .card {{ background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.08); border-radius: 16px; padding: 22px; backdrop-filter: blur(10px); box-shadow: 0 10px 30px rgba(0,0,0,0.5); }}
  .card-val {{ font-size: 32px; font-weight: 800; color: #64B5F6; margin-top: 4px; }}
  .card-lbl {{ font-size: 11px; text-transform: uppercase; color: #889; letter-spacing: 0.8px; font-weight: 700; }}

  .grid-2 {{ display: grid; grid-template-columns: 2fr 1fr; gap: 20px; margin-bottom: 30px; }}
  .table-title {{ font-size: 16px; font-weight: 700; color: #fff; margin-bottom: 16px; }}
  
  table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
  th, td {{ text-align: left; padding: 12px 14px; border-bottom: 1px solid rgba(255,255,255,0.06); }}
  th {{ background: rgba(255,255,255,0.03); color: #889; font-weight: 700; text-transform: uppercase; font-size: 11px; }}
  tr:hover {{ background: rgba(255,255,255,0.04); }}
  .badge {{ background: rgba(100,181,246,0.2); color: #64B5F6; padding: 3px 8px; border-radius: 6px; font-size: 11px; font-weight: 700; }}

  canvas {{ max-height: 280px; }}
</style>
</head>
<body>

<div class="header">
  <h1>📊 Graphify Architecture Analytics</h1>
  <div style="display:flex; gap:10px;">
    <a href="graph_3d.html" class="nav-btn">🚀 Apri Visualizzatore 3D</a>
  </div>
</div>

<div class="grid-4">
  <div class="card">
    <div class="card-lbl">Totale Nodi & Classi</div>
    <div class="card-val">{len(nodes):,}</div>
  </div>
  <div class="card">
    <div class="card-lbl">Totale Relazioni & Import</div>
    <div class="card-val">{len(links):,}</div>
  </div>
  <div class="card">
    <div class="card-lbl">Galassie / Moduli Rilevati</div>
    <div class="card-val">{len(communities)}</div>
  </div>
  <div class="card">
    <div class="card-lbl">Hub Principali (God Nodes)</div>
    <div class="card-val">{len(god_nodes)}</div>
  </div>
</div>

<div class="grid-2">
  <div class="card">
    <div class="table-title">⭐ Top 15 Classi & Hub Architetturali (Connessioni)</div>
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Nome Classe / Entità</th>
          <th>File Sorgente</th>
          <th>Connessioni</th>
        </tr>
      </thead>
      <tbody>
"""

for i, g in enumerate(god_nodes[:15], 1):
    deg = degrees.get(g['id'], 0)
    dashboard_html += f"""
        <tr>
          <td><span class="badge">#{i}</span></td>
          <td><b>{g['label']}</b></td>
          <td style="color:#889;">{g.get('source_file', '-')}</td>
          <td><b style="color:#64B5F6;">{deg}</b></td>
        </tr>
    """

dashboard_html += f"""
      </tbody>
    </table>
  </div>

  <div class="card">
    <div class="table-title">🪐 Distribuzione Moduli</div>
    <canvas id="chart-comm"></canvas>
  </div>
</div>

<script>
const commData = {json.dumps([{'name': c['name'], 'count': c['count']} for c in sorted(communities.values(), key=lambda x: x['count'], reverse=True)[:8]])};

new Chart(document.getElementById('chart-comm'), {{
  type: 'doughnut',
  data: {{
    labels: commData.map(c => c.name),
    datasets: [{{
      data: commData.map(c => c.count),
      backgroundColor: ['#64B5F6', '#81C784', '#FFB74D', '#BA68C8', '#4DD0E1', '#FF8A65', '#A1887F', '#90A4AE']
    }}]
  }},
  options: {{
    responsive: true,
    plugins: {{
      legend: {{ position: 'bottom', labels: {{ color: '#aaa', font: {{ size: 11 }} }} }}
    }}
  }}
}});
</script>

</body>
</html>
"""

dashboard_path = os.path.join(out_dir, 'dashboard.html')
with open(dashboard_path, 'w', encoding='utf-8') as f:
    f.write(dashboard_html)

print(f"Generated Dashboard at {dashboard_path}")
