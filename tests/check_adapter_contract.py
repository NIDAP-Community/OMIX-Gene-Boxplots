#!/usr/bin/env python3
"""Audit the Code Ocean adapter against the canonical Gene Boxplots contract."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CANONICAL_COMMIT = "eee4433cd74d0ce9bd1daba1571ca6312cba7ea2"
CANONICAL_SCHEMA_SHA256 = "57f2aee00ad5cdbccbfdb6c78ef6c89d392d0f60506d2d5eacca61c9d3f28033"

# output_dir is the one canonical public control intentionally absent here:
# Code Ocean owns /results and the source record declares that hidden binding.
CONTRACT = [
    {"name": "expression_table", "r_type": "character", "panel_type": "file", "value_type": "string", "default": None},
    {"name": "metadata_table", "r_type": "character", "panel_type": "file", "value_type": "string", "default": None},
    {"name": "deg_table", "r_type": "character", "panel_type": "file", "value_type": "string", "default": ""},
    {"name": "genes", "r_type": "character", "panel_type": "text", "value_type": "string", "default": None},
    {"name": "gene_column", "r_type": "character", "panel_type": "text", "value_type": "string", "default": "GeneName"},
    {"name": "sample_column", "r_type": "character", "panel_type": "text", "value_type": "string", "default": "Sample"},
    {"name": "category_column", "r_type": "character", "panel_type": "text", "value_type": "string", "default": "Group"},
    {"name": "categories", "r_type": "character", "panel_type": "text", "value_type": "string", "default": ""},
    {"name": "statistics_mode", "r_type": "character", "panel_type": "list", "value_type": "string", "default": "precomputed_deg", "choices": ["precomputed_deg", "within_plot", "none"]},
    {"name": "pvalue_type", "r_type": "character", "panel_type": "list", "value_type": "string", "default": "nominal", "choices": ["nominal", "adjusted"]},
    {"name": "statistical_method", "r_type": "character", "panel_type": "list", "value_type": "string", "default": "anova", "choices": ["anova", "t-test", "kruskal"]},
    {"name": "p_adjust_method", "r_type": "character", "panel_type": "list", "value_type": "string", "default": "BH", "choices": ["BH", "none", "bonferroni", "holm", "fdr", "hochberg", "hommel", "BY"]},
    {"name": "duplicate_aggregation", "r_type": "character", "panel_type": "list", "value_type": "string", "default": "mean", "choices": ["mean", "sum", "keep"]},
    {"name": "minimum_samples_per_category", "r_type": "integer", "panel_type": "text", "value_type": "number", "default": 3},
    {"name": "plot_type", "r_type": "character", "panel_type": "list", "value_type": "string", "default": "box", "choices": ["box", "violin"]},
    {"name": "title", "r_type": "character", "panel_type": "text", "value_type": "string", "default": "auto"},
    {"name": "y_axis_label", "r_type": "character", "panel_type": "text", "value_type": "string", "default": "auto"},
    {"name": "colors", "r_type": "character", "panel_type": "text", "value_type": "string", "default": ""},
    {"name": "image_width", "r_type": "double", "panel_type": "text", "value_type": "number", "default": 6},
    {"name": "image_height", "r_type": "double", "panel_type": "text", "value_type": "number", "default": 5},
    {"name": "image_dpi", "r_type": "integer", "panel_type": "text", "value_type": "number", "default": 300},
]


def comparable(value):
    if value is None or value == "":
        return None
    if isinstance(value, (int, float)):
        return float(value)
    text = str(value).strip()
    if re.fullmatch(r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)", text):
        return float(text)
    return text


def balanced_calls(text: str, function_name: str) -> list[str]:
    calls = []
    start_pattern = re.compile(rf"\b{re.escape(function_name)}\s*\(")
    for match in start_pattern.finditer(text):
        depth = 0
        quote = None
        escaped = False
        for index in range(match.end() - 1, len(text)):
            character = text[index]
            if quote:
                if escaped:
                    escaped = False
                elif character == "\\":
                    escaped = True
                elif character == quote:
                    quote = None
                continue
            if character in {'"', "'"}:
                quote = character
            elif character == "(":
                depth += 1
            elif character == ")":
                depth -= 1
                if depth == 0:
                    calls.append(text[match.start(): index + 1])
                    break
    return calls


def named_argument(call: str, name: str) -> str | None:
    match = re.search(
        rf"\b{re.escape(name)}\s*=\s*(NULL|[-+]?\d+(?:\.\d+)?L?|\"(?:\\.|[^\"])*\"|'(?:\\.|[^'])*')",
        call,
    )
    return match.group(1) if match else None


def parse_literal(raw: str | None):
    if raw is None or raw == "NULL":
        return None
    if raw[0] in {'"', "'"}:
        return raw[1:-1]
    return float(raw.rstrip("L"))


def parse_r_options(text: str) -> list[dict]:
    values = []
    for call in balanced_calls(text, "make_option"):
        name = re.search(r"['\"]--([A-Za-z0-9_]+)['\"]", call)
        if not name:
            continue
        values.append({
            "name": name.group(1),
            "type": parse_literal(named_argument(call, "type")),
            "default": parse_literal(named_argument(call, "default")),
        })
    return values


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def audit(panel: dict, main_text: str, source_text: str) -> list[str]:
    findings = []
    expected_names = [item["name"] for item in CONTRACT]
    parameters = panel.get("parameters", [])
    panel_names = [item.get("param_name") for item in parameters]

    if panel.get("named_parameters") is not True:
        findings.append("named_parameters must be true")
    if len(panel_names) != len(set(panel_names)):
        findings.append("duplicate App Panel param_name values")
    missing = [name for name in expected_names if name not in panel_names]
    extra = [name for name in panel_names if name not in expected_names]
    if missing:
        findings.append("missing App Panel controls: " + ", ".join(missing))
    if extra:
        findings.append("extra App Panel controls: " + ", ".join(map(str, extra)))
    if panel_names != expected_names:
        findings.append("App Panel control order differs from the canonical schema")

    panel_by_name = {item.get("param_name"): item for item in parameters}
    for expected in CONTRACT:
        observed = panel_by_name.get(expected["name"])
        if observed is None:
            continue
        if observed.get("type") != expected["panel_type"]:
            findings.append(f"{expected['name']}: App Panel type mismatch")
        if observed.get("value_type") != expected["value_type"]:
            findings.append(f"{expected['name']}: App Panel value_type mismatch")
        if comparable(observed.get("default_value")) != comparable(expected["default"]):
            findings.append(f"{expected['name']}: App Panel default mismatch")
        if observed.get("extra_data", []) != expected.get("choices", []):
            findings.append(f"{expected['name']}: App Panel choices mismatch")

    options = parse_r_options(main_text)
    option_names = [item["name"] for item in options]
    if option_names != expected_names:
        findings.append("adapter CLI controls are missing, extra, or out of canonical order")
    option_by_name = {item["name"]: item for item in options}
    for expected in CONTRACT:
        observed = option_by_name.get(expected["name"])
        if observed is None:
            continue
        if observed["type"] != expected["r_type"]:
            findings.append(f"{expected['name']}: adapter CLI type mismatch")
        if comparable(observed["default"]) != comparable(expected["default"]):
            findings.append(f"{expected['name']}: adapter CLI default mismatch")

    if "deg_gene_column" in panel_names or "--deg_gene_column" in main_text:
        findings.append("internal deg_gene_column must not be a public adapter control")
    if "output_dir" in panel_names or "--output_dir" in main_text:
        findings.append("output_dir must remain a platform-owned hidden binding")
    if '"canonical":"output_dir"' not in source_text.replace(" ", ""):
        findings.append("source record is missing the output_dir hidden binding")
    if 'result_dir <- if (dir.exists("/results")) "/results"' not in main_text:
        findings.append("adapter does not map output_dir to Code Ocean /results")
    if 'pattern = "^DEG_Analysis\\\\.csv$"' not in main_text:
        findings.append("workflow discovery does not bind the stable DEG_Analysis.csv basename")

    expected_scientific_files = {
        "Boxplot_with_Stats.R",
        "OMIX_Gene_Boxplots.R",
    }
    observed_scientific_files = {
        path.name for path in (ROOT / "code" / "functions").glob("*.R")
    }
    if observed_scientific_files != expected_scientific_files:
        findings.append("code/functions is not the complete, exclusive canonical R export")
    for name in sorted(expected_scientific_files):
        digest = sha256(ROOT / "code" / "functions" / name)
        if digest not in source_text:
            findings.append(f"{name}: managed scientific source SHA-256 is absent from OMIX_MODULE_SOURCE.md")
    if CANONICAL_SCHEMA_SHA256 not in source_text:
        findings.append("canonical schema SHA-256 is absent from OMIX_MODULE_SOURCE.md")
    if CANONICAL_COMMIT not in source_text:
        findings.append("canonical source record is not pinned to the reviewed contract commit")
    if 'source(file.path(runtime_root, "code", "functions", "OMIX_Gene_Boxplots.R"))' not in main_text:
        findings.append("adapter does not source the managed scientific export")
    if 'source(file.path(runtime_root, "code", "adapter_io.R"))' not in main_text:
        findings.append("adapter I/O translation is not loaded from adapter-owned code")

    return findings


def audit_repository() -> list[str]:
    panel = json.loads((ROOT / ".codeocean" / "app-panel.json").read_text())
    return audit(
        panel,
        (ROOT / "code" / "main.R").read_text(),
        (ROOT / "OMIX_MODULE_SOURCE.md").read_text(),
    )


if __name__ == "__main__":
    failures = audit_repository()
    if failures:
        for failure in failures:
            print(f"ERROR: {failure}", file=sys.stderr)
        raise SystemExit(1)
    print("Gene Boxplots adapter contract checks passed")
