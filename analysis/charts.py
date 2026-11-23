"""Export the analytics marts from BigQuery to data/marts (CSV) and draw the charts in docs/img.

    python analysis/charts.py            # export + charts (needs GCP_PROJECT_ID and gcloud login)
    python analysis/charts.py --offline  # charts only, from the CSVs already in data/marts
"""

import json
import os
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.collections import PatchCollection
from matplotlib.patches import Polygon

ROOT = Path(__file__).resolve().parents[1]
MARTS, IMG, REF = ROOT / "data" / "marts", ROOT / "docs" / "img", ROOT / "data" / "reference"
TABLES = ["agg_emprego_ano", "agg_emprego_municipio", "agg_remuneracao_divisao",
          "agg_disparidade_regiao", "comparacao_extracao_v1"]

SURFACE, INK, MUTED, GRID = "#fcfcfb", "#0b0b0b", "#52514e", "#e4e3df"
S1, S2, S3 = "#2a78d6", "#eb6834", "#1baf7a"
SEQ = ["#e3edf9", "#b7d0f0", "#86b0e6", "#4f8ddb", "#2a78d6", "#1d58a3", "#123a6e"]
plt.rcParams.update({
    "figure.facecolor": SURFACE, "axes.facecolor": SURFACE, "axes.edgecolor": GRID, "axes.labelcolor": MUTED,
    "xtick.color": MUTED, "ytick.color": MUTED, "text.color": INK, "font.size": 11,
    "axes.spines.top": False, "axes.spines.right": False, "axes.grid": True, "grid.color": GRID,
})


def export() -> None:
    from google.cloud import bigquery
    project = os.environ["GCP_PROJECT_ID"]
    client = bigquery.Client(project=project, location="US")
    MARTS.mkdir(parents=True, exist_ok=True)
    for t in TABLES:
        df = client.query(f"select * from `{project}.rais_sc_analytics.{t}` order by 1, 2").to_dataframe()
        df.to_csv(MARTS / f"{t}.csv", index=False)
        print(f"  {t}: {len(df)} rows")


def br(v: float, dec: int = 0) -> str:
    return f"{v:,.{dec}f}".replace(",", "X").replace(".", ",").replace("X", ".")


def chart_series() -> None:
    y = pd.read_csv(MARTS / "agg_emprego_ano.csv").sort_values("ano")
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.2), gridspec_kw={"wspace": 0.28})
    ax = axes[0]
    for col, color, label in [("ativos_3112", S1, "Vínculos ativos em 31/12"),
                              ("mediana_remuneracao_real", S2, "Salário mediano real")]:
        idx = 100 * y[col] / y[col].iloc[0]
        ax.plot(y.ano, idx, color=color, linewidth=2, marker="o", markersize=5, markeredgecolor=SURFACE)
        ax.annotate(f"{idx.iloc[-1]:.0f}", (y.ano.iloc[-1], idx.iloc[-1]), xytext=(6, 0),
                    textcoords="offset points", va="center", fontsize=10, fontweight="bold")
        ax.plot([], [], color=color, linewidth=2, label=label)
    ax.axhline(100, color=MUTED, linewidth=1, linestyle=(0, (3, 3)))
    ax.set_title("Emprego e salário real, índice 2019 = 100", loc="left", fontsize=12)
    ax.legend(frameon=False, loc="upper left", fontsize=9)
    ax = axes[1]
    for col, color, label in [("rotatividade", S1, "Rotatividade"), ("rotatividade_descontada", S3, "Rotatividade descontada")]:
        ax.plot(y.ano, 100 * y[col], color=color, linewidth=2, marker="o", markersize=5, markeredgecolor=SURFACE)
        ax.annotate(f"{100*y[col].iloc[-1]:.0f}%", (y.ano.iloc[-1], 100 * y[col].iloc[-1]), xytext=(6, 0),
                    textcoords="offset points", va="center", fontsize=10, fontweight="bold")
        ax.plot([], [], color=color, linewidth=2, label=label)
    ax.set_ylim(0, 80)
    ax.set_title("Rotatividade (DIEESE), % do estoque médio", loc="left", fontsize=12)
    ax.legend(frameon=False, loc="lower left", fontsize=9)
    for a in axes:
        a.set_xticks(y.ano)
    fig.savefig(IMG / "series.png", dpi=150, bbox_inches="tight")


def _polygons(geom: dict) -> list:
    rings = [geom["coordinates"]] if geom["type"] == "Polygon" else geom["coordinates"]
    return [Polygon(poly[0], closed=True) for poly in rings]


def chart_map(year: int) -> None:
    m = pd.read_csv(MARTS / "agg_emprego_municipio.csv", dtype={"id_municipio": str})
    m = m[m.ano == year].set_index("id_municipio")
    gj = json.loads((REF / "sc_municipios.geojson").read_text())
    q = pd.qcut(m["mediana_remuneracao_real"], len(SEQ), labels=False)
    edges = m["mediana_remuneracao_real"].quantile([i / len(SEQ) for i in range(len(SEQ) + 1)]).values
    fig, ax = plt.subplots(figsize=(11, 7.5))
    patches, colors = [], []
    for f in gj["features"]:
        code = f["properties"]["CD_MUN"]
        for p in _polygons(f["geometry"]):
            patches.append(p)
            colors.append(SEQ[int(q[code])] if code in q.index else GRID)
    ax.add_collection(PatchCollection(patches, facecolor=colors, edgecolor=SURFACE, linewidth=0.4))
    rg = json.loads((REF / "sc_rg_intermediarias.geojson").read_text())
    ax.add_collection(PatchCollection([p for f in rg["features"] for p in _polygons(f["geometry"])],
                                      facecolor="none", edgecolor=INK, linewidth=0.9))
    ax.autoscale_view(); ax.set_aspect(1 / 0.88); ax.set_axis_off()
    for i, c in enumerate(SEQ):
        ax.scatter([], [], color=c, s=60, marker="s", label=f"R$ {br(edges[i])} – {br(edges[i+1])}")
    ax.legend(frameon=False, loc="lower left", fontsize=9, title="Salário mediano real (dez/2025)", title_fontsize=9)
    ax.set_title(f"Salário mediano por município, {year} (vínculos ativos em 31/12)", loc="left", fontsize=12)
    fig.savefig(IMG / "mapa_salario_municipio.png", dpi=150, bbox_inches="tight")


def chart_gaps(year: int) -> None:
    d = pd.read_csv(MARTS / "agg_disparidade_regiao.csv")
    d = d[d.ano == year].sort_values("razao_pretos_pardos_brancos")
    fig, ax = plt.subplots(figsize=(9, 4.2))
    yy = range(len(d))
    ax.hlines(yy, 0.6, 1.0, color=GRID, linewidth=1)
    ax.scatter(d.razao_mulheres_homens, yy, color=S1, s=70, zorder=3, edgecolor=SURFACE, linewidth=1.5, label="Mulheres / homens")
    ax.scatter(d.razao_pretos_pardos_brancos, yy, color=S2, s=70, zorder=3, edgecolor=SURFACE, linewidth=1.5, label="Pretos e pardos / brancos")
    ax.axvline(1, color=MUTED, linewidth=1, linestyle=(0, (3, 3)))
    ax.set_yticks(list(yy), d.regiao_intermediaria)
    ax.set_xlim(0.6, 1.02)
    ax.xaxis.set_major_formatter(lambda v, _: f"{v:.0%}")
    ax.set_title(f"Salário mediano de um grupo em relação ao outro, {year}", loc="left", fontsize=12)
    ax.legend(frameon=False, loc="upper center", bbox_to_anchor=(0.5, -0.1), ncols=2, fontsize=9)
    ax.grid(axis="y", visible=False)
    fig.savefig(IMG / "disparidades_regiao.png", dpi=150, bbox_inches="tight")


if __name__ == "__main__":
    if "--offline" not in sys.argv:
        export()
    IMG.mkdir(parents=True, exist_ok=True)
    last = int(pd.read_csv(MARTS / "agg_emprego_ano.csv").ano.max())
    chart_series()
    chart_map(last)
    chart_gaps(last)
