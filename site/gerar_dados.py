#!/usr/bin/env python3
"""Agrega os lotes oficiais em site/dados/resultados.json.

O site não guarda número digitado à mão: cada valor exibido sai daqui, e
daqui sai de data/runs/<lote>/resumo.csv — os mesmos arquivos que
docs/resultados_finais.md e tools/analise_estatistica.gd leem.

Uso: python3 site/gerar_dados.py
"""

import csv
import json
from datetime import datetime, timezone
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
RUNS = RAIZ / "data" / "runs"
SAIDA = RAIZ / "site" / "dados" / "resultados.json"

# As mesmas execuções analisadas em tools/analise_estatistica.gd.
LOTES = {
    "confronto_triplo": "2026-07-25_19-50-46_benchmark_1000",
    "vs_2_heuristicas": "2026-07-25_20-06-57_benchmark_1000",
    "vs_2_reativas": "2026-07-25_20-26-19_benchmark_1000",
    "self_aleatoria": "2026-07-25_20-44-08_benchmark_1000",
    "self_reativa": "2026-07-25_22-02-46_benchmark_1000",
    "self_heuristica": "2026-07-25_22-21-47_benchmark_1000",
    "self_art3miz": "2026-07-25_22-46-49_benchmark_1000",
}

NUMERICAS = {
    "partidas": int,
    "pontos_total": int,
    "pontos_media": float,
    "win_rate": float,
    "damage_ratio_media": float,
    "damage_ratio_dp": float,
    "cover_usage_media": float,
    "cover_usage_dp": float,
    "turns_to_victory_media": float,
    "efficiency": float,
    "custo_medio": float,
    "custo_dp": float,
    "strategic_score": float,
}


def ler_manifest(pasta):
    """Configuração da execução: modelos por jogador, duração, constantes."""
    dados = {"modelos": {}, "constantes": {}}
    secao = None
    for linha in (pasta / "manifest.txt").read_text(encoding="utf-8").splitlines():
        linha = linha.strip()
        if not linha:
            continue
        if linha.startswith("[") and linha.endswith("]"):
            secao = linha[1:-1]
            continue
        if ":" not in linha:
            continue
        chave, valor = (parte.strip() for parte in linha.split(":", 1))
        if secao == "modelos":
            dados["modelos"][chave] = valor
        elif secao == "constantes_de_jogo":
            dados["constantes"][chave] = valor
        elif secao is None:
            dados[chave] = valor
    return dados


def ler_resumo(pasta):
    with (pasta / "resumo.csv").open(encoding="utf-8", newline="") as arquivo:
        linhas = []
        for bruta in csv.DictReader(arquivo):
            linha = {}
            for chave, valor in bruta.items():
                conversor = NUMERICAS.get(chave)
                linha[chave] = conversor(valor) if conversor else valor
            linhas.append(linha)
    return linhas


def media(valores):
    return sum(valores) / len(valores) if valores else 0.0


def main():
    lotes = {}
    for chave, nome in LOTES.items():
        pasta = RUNS / nome
        if not pasta.is_dir():
            raise SystemExit(f"lote ausente: {pasta}")
        manifest = ler_manifest(pasta)
        linhas = ler_resumo(pasta)
        lotes[chave] = {
            "pasta": nome,
            "modelos": manifest["modelos"],
            "partidas": int(manifest.get("partidas", len(linhas) and linhas[0]["partidas"])),
            "duracao_segundos": float(manifest.get("duracao_segundos", 0)),
            "linhas": linhas,
        }

    # Autoconfronto: três instâncias do mesmo modelo por partida, então a
    # linha do modelo é a média dos três jogadores. Em condições simétricas
    # a taxa de vitória converge para ~1/3 em qualquer modelo que funcione —
    # o que a comparação revela é o preço pago por esse desempenho.
    autoconfronto = []
    for chave in ("self_aleatoria", "self_reativa", "self_heuristica", "self_art3miz"):
        lote = lotes[chave]
        linhas = lote["linhas"]
        autoconfronto.append({
            "modelo": linhas[0]["modelo_ia"],
            "lote": lote["pasta"],
            "win_rate": media([l["win_rate"] for l in linhas]),
            "damage_ratio": media([l["damage_ratio_media"] for l in linhas]),
            "cover_usage": media([l["cover_usage_media"] for l in linhas]),
            "turnos_para_vitoria": media([l["turns_to_victory_media"] for l in linhas]),
            "custo": media([l["custo_medio"] for l in linhas]),
            "eficiencia": media([l["efficiency"] for l in linhas]),
            "strategic_score": media([l["strategic_score"] for l in linhas]),
        })

    # Neutralidade: três IAs idênticas devem repartir as vitórias por igual.
    # É a validação que sustenta toda comparação feita sobre o ambiente.
    neutralidade = {
        "lote": lotes["self_reativa"]["pasta"],
        "modelo": lotes["self_reativa"]["linhas"][0]["modelo_ia"],
        "partidas": lotes["self_reativa"]["partidas"],
        "win_rates": [
            {"jogador": l["jogador"], "win_rate": l["win_rate"]}
            for l in lotes["self_reativa"]["linhas"]
        ],
    }

    SAIDA.parent.mkdir(parents=True, exist_ok=True)
    SAIDA.write_text(
        json.dumps(
            {
                "gerado_em": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                "lotes": lotes,
                "autoconfronto": autoconfronto,
                "neutralidade": neutralidade,
            },
            ensure_ascii=False,
            indent=1,
        ),
        encoding="utf-8",
    )
    print(f"{len(lotes)} lotes -> {SAIDA.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
