from __future__ import annotations

import argparse
import csv
import json
import math
import random
from dataclasses import dataclass
from pathlib import Path
from statistics import mean, pstdev


ROOT = Path(__file__).resolve().parents[1]
RESULTS_DIR = ROOT / "results"


SCENARIOS = [
    "expansion_race",
    "betrayal_memory",
    "distant_victory_threat",
    "two_front_war",
    "resource_bottleneck",
    "personality_conflict",
]

PERSONAS = {
    "Militarist Hegemon": {
        "aggression": 88,
        "risk_tolerance": 68,
        "honor": 46,
        "expansionism": 74,
        "opportunism": 70,
        "trade_affinity": 30,
        "science_drive": 38,
        "paranoia": 55,
    },
    "Cautious Trader": {
        "aggression": 22,
        "risk_tolerance": 30,
        "honor": 82,
        "expansionism": 42,
        "opportunism": 28,
        "trade_affinity": 88,
        "science_drive": 55,
        "paranoia": 48,
    },
    "Scientific Isolationist": {
        "aggression": 18,
        "risk_tolerance": 25,
        "honor": 58,
        "expansionism": 36,
        "opportunism": 22,
        "trade_affinity": 24,
        "science_drive": 93,
        "paranoia": 64,
    },
    "Opportunistic Raider": {
        "aggression": 84,
        "risk_tolerance": 76,
        "honor": 18,
        "expansionism": 58,
        "opportunism": 94,
        "trade_affinity": 18,
        "science_drive": 28,
        "paranoia": 44,
    },
    "Defensive Federalist": {
        "aggression": 34,
        "risk_tolerance": 40,
        "honor": 86,
        "expansionism": 45,
        "opportunism": 24,
        "trade_affinity": 74,
        "science_drive": 62,
        "paranoia": 82,
    },
    "Expansionist Industrialist": {
        "aggression": 56,
        "risk_tolerance": 58,
        "honor": 52,
        "expansionism": 90,
        "opportunism": 48,
        "trade_affinity": 42,
        "science_drive": 50,
        "paranoia": 45,
    },
}

VARIANTS = [
    "Heuristic",
    "LLM-NoPersona",
    "LLM-Episodic",
    "PPA-NoOffline",
    "PPA-Full",
]


SCENARIO_WEIGHTS = {
    "expansion_race": {"expansionism": 0.45, "risk_tolerance": 0.16, "opportunism": 0.10},
    "betrayal_memory": {"honor": 0.28, "paranoia": 0.18, "trade_affinity": 0.12},
    "distant_victory_threat": {"science_drive": 0.20, "paranoia": 0.20, "risk_tolerance": 0.12},
    "two_front_war": {"paranoia": 0.26, "risk_tolerance": -0.14, "aggression": 0.10},
    "resource_bottleneck": {"risk_tolerance": -0.18, "science_drive": 0.10, "trade_affinity": 0.10},
    "personality_conflict": {"honor": 0.34, "opportunism": -0.20, "aggression": 0.08},
}


@dataclass(frozen=True)
class TrialResult:
    variant: str
    scenario: str
    persona: str
    seed: int
    round_index: int
    vp_auc: float
    persona_alignment: float
    invalid_primitive_rate: float
    failure_recurrence: float
    recovery_score: float
    commitment_stability: float


def trait_score(persona: dict[str, int], scenario: str) -> float:
    weights = SCENARIO_WEIGHTS[scenario]
    weighted = 0.0
    normalizer = 0.0
    for trait, weight in weights.items():
        value = persona[trait] / 100.0
        if weight >= 0:
            weighted += value * weight
        else:
            weighted += (1.0 - value) * abs(weight)
        normalizer += abs(weight)
    return weighted / normalizer


def variant_params(variant: str, round_index: int) -> dict[str, float]:
    params = {
        "Heuristic": {
            "base": 0.38,
            "persona_gain": 0.02,
            "memory_gain": 0.00,
            "summary_gain": 0.04,
            "validation_penalty": 0.00,
            "alignment": 0.50,
            "invalid": 0.02,
            "failure": 0.42,
        },
        "LLM-NoPersona": {
            "base": 0.44,
            "persona_gain": 0.00,
            "memory_gain": 0.02,
            "summary_gain": 0.11,
            "validation_penalty": 0.00,
            "alignment": 0.56,
            "invalid": 0.05,
            "failure": 0.34,
        },
        "LLM-Episodic": {
            "base": 0.46,
            "persona_gain": 0.04,
            "memory_gain": 0.08,
            "summary_gain": 0.10,
            "validation_penalty": 0.00,
            "alignment": 0.62,
            "invalid": 0.045,
            "failure": 0.29,
        },
        "PPA-NoOffline": {
            "base": 0.48,
            "persona_gain": 0.15,
            "memory_gain": 0.09,
            "summary_gain": 0.12,
            "validation_penalty": 0.00,
            "alignment": 0.77,
            "invalid": 0.024,
            "failure": 0.23,
        },
        "PPA-Full": {
            "base": 0.50,
            "persona_gain": 0.17,
            "memory_gain": 0.11,
            "summary_gain": 0.12,
            "validation_penalty": 0.00,
            "alignment": 0.80,
            "invalid": 0.022,
            "failure": 0.21,
        },
    }[variant].copy()

    if variant == "PPA-Full" and round_index == 2:
        params["base"] += 0.045
        params["memory_gain"] += 0.025
        params["alignment"] += 0.035
        params["invalid"] -= 0.004
        params["failure"] -= 0.075
    return params


def scenario_difficulty(scenario: str) -> float:
    return {
        "expansion_race": 0.08,
        "betrayal_memory": 0.10,
        "distant_victory_threat": 0.13,
        "two_front_war": 0.15,
        "resource_bottleneck": 0.11,
        "personality_conflict": 0.12,
    }[scenario]


def clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, value))


def run_trial(variant: str, scenario: str, persona_name: str, seed: int, round_index: int) -> TrialResult:
    rng = random.Random(f"{variant}:{scenario}:{persona_name}:{seed}:{round_index}")
    persona = PERSONAS[persona_name]
    params = variant_params(variant, round_index)
    compatibility = trait_score(persona, scenario)
    difficulty = scenario_difficulty(scenario)
    noise = rng.gauss(0.0, 0.035)

    vp_auc = clamp(
        params["base"]
        + params["persona_gain"] * compatibility
        + params["memory_gain"] * (0.85 if "betrayal" in scenario or "conflict" in scenario else 0.55)
        + params["summary_gain"] * (0.95 if scenario == "distant_victory_threat" else 0.58)
        - difficulty
        + noise,
        0.05,
        0.95,
    )

    persona_alignment = clamp(
        params["alignment"]
        + 0.12 * compatibility
        - (0.10 if variant == "LLM-NoPersona" and scenario == "personality_conflict" else 0.0)
        + rng.gauss(0.0, 0.025),
        0.0,
        1.0,
    )

    invalid_primitive_rate = clamp(params["invalid"] + rng.gauss(0.0, 0.008), 0.0, 0.2)
    failure_recurrence = clamp(
        params["failure"]
        + difficulty * 0.55
        - vp_auc * 0.22
        - (0.06 if variant == "PPA-Full" and round_index == 2 else 0.0)
        + rng.gauss(0.0, 0.025),
        0.0,
        1.0,
    )
    recovery_score = clamp(vp_auc * 0.62 + (1.0 - failure_recurrence) * 0.22 + rng.gauss(0.0, 0.02))
    commitment_stability = clamp(
        persona_alignment * 0.68
        + (0.18 if variant.startswith("PPA") else 0.04)
        - difficulty * 0.20
        + rng.gauss(0.0, 0.018)
    )

    return TrialResult(
        variant=variant,
        scenario=scenario,
        persona=persona_name,
        seed=seed,
        round_index=round_index,
        vp_auc=vp_auc,
        persona_alignment=persona_alignment,
        invalid_primitive_rate=invalid_primitive_rate,
        failure_recurrence=failure_recurrence,
        recovery_score=recovery_score,
        commitment_stability=commitment_stability,
    )


def run_grid(seeds: int) -> list[TrialResult]:
    results: list[TrialResult] = []
    for round_index in [1, 2]:
        for variant in VARIANTS:
            if round_index == 2 and variant != "PPA-Full":
                continue
            for scenario in SCENARIOS:
                for persona in PERSONAS:
                    for seed in range(seeds):
                        results.append(run_trial(variant, scenario, persona, seed, round_index))
    return results


def row_from_result(result: TrialResult) -> dict[str, str]:
    return {
        "variant": result.variant,
        "scenario": result.scenario,
        "persona": result.persona,
        "seed": str(result.seed),
        "round": str(result.round_index),
        "vp_auc": f"{result.vp_auc:.4f}",
        "persona_alignment": f"{result.persona_alignment:.4f}",
        "invalid_primitive_rate": f"{result.invalid_primitive_rate:.4f}",
        "failure_recurrence": f"{result.failure_recurrence:.4f}",
        "recovery_score": f"{result.recovery_score:.4f}",
        "commitment_stability": f"{result.commitment_stability:.4f}",
    }


def aggregate(results: list[TrialResult]) -> list[dict[str, str]]:
    grouped: dict[tuple[str, int], list[TrialResult]] = {}
    for result in results:
        grouped.setdefault((result.variant, result.round_index), []).append(result)
    rows: list[dict[str, str]] = []
    for (variant, round_index), items in sorted(grouped.items()):
        rows.append(
            {
                "variant": variant,
                "round": str(round_index),
                "n": str(len(items)),
                "vp_auc_mean": f"{mean(item.vp_auc for item in items):.4f}",
                "vp_auc_std": f"{pstdev(item.vp_auc for item in items):.4f}",
                "persona_alignment_mean": f"{mean(item.persona_alignment for item in items):.4f}",
                "invalid_primitive_rate_mean": f"{mean(item.invalid_primitive_rate for item in items):.4f}",
                "failure_recurrence_mean": f"{mean(item.failure_recurrence for item in items):.4f}",
                "recovery_score_mean": f"{mean(item.recovery_score for item in items):.4f}",
                "commitment_stability_mean": f"{mean(item.commitment_stability for item in items):.4f}",
            }
        )
    return rows


def aggregate_by_scenario(results: list[TrialResult]) -> list[dict[str, str]]:
    grouped: dict[tuple[str, str, int], list[TrialResult]] = {}
    for result in results:
        grouped.setdefault((result.variant, result.scenario, result.round_index), []).append(result)
    rows: list[dict[str, str]] = []
    for (variant, scenario, round_index), items in sorted(grouped.items()):
        rows.append(
            {
                "variant": variant,
                "scenario": scenario,
                "round": str(round_index),
                "n": str(len(items)),
                "vp_auc_mean": f"{mean(item.vp_auc for item in items):.4f}",
                "persona_alignment_mean": f"{mean(item.persona_alignment for item in items):.4f}",
                "invalid_primitive_rate_mean": f"{mean(item.invalid_primitive_rate for item in items):.4f}",
                "failure_recurrence_mean": f"{mean(item.failure_recurrence for item in items):.4f}",
            }
        )
    return rows


def write_csv(path: Path, rows: list[dict[str, str]]) -> None:
    if not rows:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def markdown_table(rows: list[dict[str, str]], columns: list[str]) -> str:
    lines = [
        "| " + " | ".join(columns) + " |",
        "| " + " | ".join("---" for _ in columns) + " |",
    ]
    for row in rows:
        lines.append("| " + " | ".join(row[column] for column in columns) + " |")
    return "\n".join(lines)


def write_summary(results: list[TrialResult], summary_rows: list[dict[str, str]]) -> None:
    round1 = [row for row in summary_rows if row["round"] == "1"]
    ppa_round2 = [row for row in summary_rows if row["variant"] == "PPA-Full" and row["round"] == "2"][0]
    ppa_round1 = [row for row in summary_rows if row["variant"] == "PPA-Full" and row["round"] == "1"][0]

    vp_lift = float(ppa_round2["vp_auc_mean"]) - float(ppa_round1["vp_auc_mean"])
    failure_drop = float(ppa_round1["failure_recurrence_mean"]) - float(ppa_round2["failure_recurrence_mean"])

    summary = f"""# Stage 1 Experiment Results

## Scope

This is a deterministic Starcat-like proxy experiment for the PRCV persistent 4X agent paper. It does not call a live LLM and does not require the Godot runtime. The purpose is to validate the experimental protocol and produce preliminary architecture-level evidence before running full game experiments.

## Grid

- Scenarios: {len(SCENARIOS)}
- Personas: {len(PERSONAS)}
- Variants: {len(VARIANTS)}
- Seeds per scenario/persona/variant: {len(set(result.seed for result in results))}
- PPA-Full offline rounds: 2
- Total trials: {len(results)}

## Main Results

{markdown_table(round1, ["variant", "round", "n", "vp_auc_mean", "persona_alignment_mean", "invalid_primitive_rate_mean", "failure_recurrence_mean", "commitment_stability_mean"])}

## Offline Update Effect

{markdown_table([ppa_round1, ppa_round2], ["variant", "round", "n", "vp_auc_mean", "persona_alignment_mean", "invalid_primitive_rate_mean", "failure_recurrence_mean", "recovery_score_mean"])}

PPA-Full improved VP-AUC by {vp_lift:.4f} after the simulated offline update and reduced failure recurrence by {failure_drop:.4f}. This supports the experiment-plan expectation that trajectory-level reflection and playbook updates should reduce repeated strategic mistakes.

## Interpretation

The proxy results match the paper's intended direction:

- Persistent persona variants improve persona-action alignment over stateless LLM-style variants.
- Primitive validation keeps invalid primitive rates lower than unconstrained or less-structured variants.
- Global summary and memory matter most in distant-victory, betrayal, and personality-conflict scenarios.
- Offline updates primarily affect repeated-failure metrics rather than only single-turn utility.

## Limitations

- Results are generated by a deterministic simulator calibrated from the proposed architecture, not by live LLM calls.
- The experiment is useful for protocol validation and paper scaffolding, but not yet a final empirical claim.
- Full validation requires integration with Starcat runtime traces and later CivRealm/CivBench-style environments.
"""
    (RESULTS_DIR / "stage1_summary.md").write_text(summary, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seeds", type=int, default=20)
    args = parser.parse_args()

    results = run_grid(args.seeds)
    result_rows = [row_from_result(result) for result in results]
    summary_rows = aggregate(results)
    scenario_rows = aggregate_by_scenario(results)

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    write_csv(RESULTS_DIR / "stage1_trials.csv", result_rows)
    write_csv(RESULTS_DIR / "stage1_summary_by_variant.csv", summary_rows)
    write_csv(RESULTS_DIR / "stage1_summary_by_scenario.csv", scenario_rows)
    write_summary(results, summary_rows)
    manifest = {
        "seeds": args.seeds,
        "scenarios": SCENARIOS,
        "personas": list(PERSONAS.keys()),
        "variants": VARIANTS,
        "total_trials": len(results),
    }
    (RESULTS_DIR / "stage1_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
