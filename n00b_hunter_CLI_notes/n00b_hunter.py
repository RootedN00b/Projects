#!/usr/bin/env python3
"""
n00b_hunter.py  —  Red & Blue Team Field Notes
v3.6 — opsec/prerequisites/detection_ref/tuning fields,
        --list and --export-json CLI flags, inline metadata display
"""
import json
import os
import sys
import re
import datetime

# Set up paths relative to script location
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(SCRIPT_DIR, "db_offensive")
DEF_DB_PATH = os.path.join(SCRIPT_DIR, "db_defensive")
METH_OFF_PATH = os.path.join(SCRIPT_DIR, "db_methodology", "offensive")
METH_DEF_PATH = os.path.join(SCRIPT_DIR, "db_methodology", "defensive")
ENG_PATH = os.path.join(SCRIPT_DIR, "engagements")
os.makedirs(ENG_PATH, exist_ok=True)

# color codes variables for terminal output
R, B, G, Y, C, GR, W, M, RS = (
    "\033[1;31m",
    "\033[1;34m",
    "\033[1;32m",
    "\033[1;33m",
    "\033[1;36m",
    "\033[1;90m",
    "\033[1;37m",
    "\033[1;35m",
    "\033[0m",
)

# ENGAGEMENT structure to hold current session data
ENGAGEMENT = {
    "name": None,
    "created": None,
    "notes": {},
    "checklist": {},
    "searches": [],
}


# ── ENGAGEMENT ───────
def eng_file(name):
    return os.path.join(ENG_PATH, re.sub(r"[^a-zA-Z0-9_\-]", "_", name) + ".json")


def save_eng():
    if ENGAGEMENT["name"]:
        with open(eng_file(ENGAGEMENT["name"]), "w") as f:
            json.dump(ENGAGEMENT, f, indent=2)


def load_eng(name):
    fp = eng_file(name)
    if os.path.exists(fp):
        with open(fp) as f:
            ENGAGEMENT.update(json.load(f))
        return True
    return False


def list_engs():
    return [f[:-5] for f in os.listdir(ENG_PATH) if f.endswith(".json")]


# ── UTILS ──────────
def clear():
    os.system("cls" if os.name == "nt" else "clear")


def pause():
    input(f"\n{GR}  Press Enter...{RS}")


def banner():
    clear()
    print(C)
    # fmt: off  # noqa: E501 — ASCII art banner, cannot be shortened
    print(
        "  ███╗   ██╗ ██████╗  ██████╗ ██████╗     ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗ "
    )  # noqa: E501
    print(
        "  ████╗  ██║██╔═████╗██╔═████╗██╔══██╗    ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗"
    )  # noqa: E501
    print(
        "  ██╔██╗ ██║██║██╔██║██║██╔██║██████╔╝    ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝"
    )  # noqa: E501
    print(
        "  ██║╚██╗██║████╔╝██║████╔╝██║██╔══██╗    ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗"
    )  # noqa: E501
    print(
        "  ██║ ╚████║╚██████╔╝╚██████╔╝██████╔╝    ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║"
    )  # noqa: E501
    print(
        "  ╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝"
    )  # noqa: E501
    # fmt: on
    print(RS)
    eng = (
        f"{G}[ Engagement: {ENGAGEMENT['name']} ]{RS}"
        if ENGAGEMENT["name"]
        else f"{GR}[ No Engagement Loaded ]{RS}"
    )
    print(f"  {GR}[ Red & Blue Team Field Notes v3.5 ]{RS}  {eng}\n")


def load_json_dir(path):
    mods = {}
    if not os.path.exists(path):
        os.makedirs(path, exist_ok=True)
        return {}
    for fn in sorted(os.listdir(path)):
        if fn.endswith(".json"):
            nm = fn[:-5].replace("_", " ").upper()
            try:
                with open(os.path.join(path, fn)) as f:
                    mods[nm] = json.load(f)
            except Exception as e:
                print(f"  {R}[-]{RS} {fn}: {e}")
    return mods


def hl(text, term):
    """Highlight one or more space-separated keywords in text."""
    if not term:
        return text
    keywords = term.split() if isinstance(term, str) else [term]
    result = str(text)
    for kw in keywords:
        if kw:
            result = re.compile(re.escape(kw), re.IGNORECASE).sub(
                lambda m: f"{Y}{m.group()}{RS}", result
            )
    return result


# ── SEARCH CORE ───────────────────────────────────────────────────


def _match_keywords(blob, term):
    """Return True if ALL space-separated keywords in term are found in blob (AND logic)."""
    lblob = blob.lower()
    return all(k.lower() in lblob for k in term.split() if k)


def _build_blob(tname, tdata):
    """Build a single searchable text blob from a technique dict."""
    cmds = tdata.get("commands", [])
    return " ".join(
        [
            tname,
            tdata.get("description", ""),
            tdata.get("mitre", ""),
            tdata.get("opsec", ""),
            tdata.get("prerequisites", ""),
            tdata.get("detection_ref", ""),
            tdata.get("tuning", ""),
            *[c.get("description", "") for c in cmds],
            *[c.get("command", "") for c in cmds],
            *[c.get("method", "") for c in cmds],
        ]
    )


def _cmd_hits(tdata, term):
    """Count how many individual commands match the search term."""
    return sum(
        1
        for c in tdata.get("commands", [])
        if _match_keywords(c.get("description", "") + " " + c.get("command", ""), term)
    )


# ── SECTION SEARCH — within a single platform or module ──────────


def section_search(techs_dict, label, col=W, prefix=""):
    """
    Inline keyword search within a single section (one module or one platform file).
    Multi-keyword AND logic: 'lsass sysmon' matches entries containing BOTH words.
    """
    clear()
    print(f"\n{col}── Search within [{label}] ──{RS}\n")
    print(f"  {GR}Tip: space-separated keywords = AND  (e.g.: lsass sysmon){RS}")
    print(f"  {GR}     EventID search works too  (e.g.: 4624  or  EventCode=10){RS}\n")
    term = input(f"  {W}Keyword(s): {RS}").strip()
    if not term or len(term) < 2:
        return

    results = []
    for tname, tdata in techs_dict.items():
        if _match_keywords(_build_blob(tname, tdata), term):
            results.append((tname, tdata, _cmd_hits(tdata, term)))

    clear()
    print(f"\n{col}── '{term}'  [{label}]  {len(results)} match(es) ──{RS}\n")
    if not results:
        print(f"  {GR}No results.{RS}")
        pause()
        return

    for i, (tname, tdata, nhits) in enumerate(results, 1):
        desc = tdata.get("description", "")
        short = (desc[:65] + "..") if len(desc) > 65 else desc
        hit_tag = (
            f" {G}[{nhits} cmd match{'es' if nhits != 1 else ''}]{RS}" if nhits else ""
        )
        print(f"  {col}[{i}]{RS} {W}{tname}{RS}{hit_tag}")
        print(f"       {hl(short, term)}\n")

    print(f"  {GR}[#] drill in  [0] back{RS}\n")
    c = input("  Select: ").strip()
    if c == "0":
        return
    try:
        idx = int(c) - 1
        if 0 <= idx < len(results):
            tname, tdata, _ = results[idx]
            if prefix:
                display_def_ttp(
                    label, tname, tdata, col=col, prefix=prefix, search_term=term
                )
            else:
                display_ttp(tname, tdata, module=label, search_term=term)
    except (ValueError, IndexError):
        pass


# ── CROSS-SECTION SEARCH — across all platforms in a section ─────


def cross_section_search(loader_fn, section_label, col=W, prefix=""):
    """
    Keyword search across ALL platforms/files in a section (e.g. all SOC SIEM platforms).
    Results are grouped by platform and numbered for quick drill-in.
    """
    clear()
    print(f"\n{col}── Search across ALL [{section_label}] ──{RS}\n")
    print(f"  {GR}Tip: space-separated keywords = AND  (e.g.: kerberoast 4769){RS}")
    print(
        f"  {GR}     EventID search works too  (e.g.: EventCode=17  or  Sysmon 25){RS}\n"
    )
    term = input(f"  {W}Keyword(s): {RS}").strip()
    if not term or len(term) < 2:
        return

    all_data = loader_fn()
    results = []
    for platform, ttp_data in all_data.items():
        for tname, tdata in ttp_data.items():
            if _match_keywords(_build_blob(tname, tdata), term):
                results.append((platform, tname, tdata, _cmd_hits(tdata, term)))

    clear()
    print(f"\n{col}── '{term}'  [{section_label}]  {len(results)} match(es) ──{RS}\n")
    if not results:
        print(f"  {GR}No results.{RS}")
        pause()
        return

    for i, (platform, tname, tdata, nhits) in enumerate(results, 1):
        desc = tdata.get("description", "")
        short = (desc[:55] + "..") if len(desc) > 55 else desc
        hit_tag = (
            f" {G}[{nhits} cmd match{'es' if nhits != 1 else ''}]{RS}" if nhits else ""
        )
        print(f"  {col}[{i}]{RS} {GR}[{platform}]{RS} {W}{tname}{RS}{hit_tag}")
        print(f"       {hl(short, term)}\n")

    print(f"  {GR}[#] drill in  [0] back{RS}\n")
    c = input("  Select: ").strip()
    if c == "0":
        return
    try:
        idx = int(c) - 1
        if 0 <= idx < len(results):
            platform, tname, tdata, _ = results[idx]
            if prefix:
                display_def_ttp(
                    platform, tname, tdata, col=col, prefix=prefix, search_term=term
                )
            else:
                display_ttp(tname, tdata, module=platform, search_term=term)
    except (ValueError, IndexError):
        pass


# ── NOTES ────────
def nkey(mod, tech):
    return f"{mod}::{tech}"


def show_notes(mod, tech):
    notes = ENGAGEMENT["notes"].get(nkey(mod, tech), [])
    if notes:
        print(f"\n{M}  ── Notes ({len(notes)}) ──{RS}")
        for i, n in enumerate(notes, 1):
            print(f"  {M}{i}.{RS} {n}")


def add_note(mod, tech):
    if not ENGAGEMENT["name"]:
        print(f"  {Y}[!] Load an engagement first.{RS}")
        pause()
        return
    n = input(f"  {M}Note: {RS}").strip()
    if n:
        ENGAGEMENT["notes"].setdefault(nkey(mod, tech), []).append(n)
        save_eng()
        print(f"  {G}Saved.{RS}")


def del_note(mod, tech):
    notes = ENGAGEMENT["notes"].get(nkey(mod, tech), [])
    if not notes:
        return
    show_notes(mod, tech)
    try:
        i = int(input("  Delete #: ").strip()) - 1
        if 0 <= i < len(notes):
            notes.pop(i)
            ENGAGEMENT["notes"][nkey(mod, tech)] = notes
            save_eng()
            print(f"  {G}Deleted.{RS}")
    except (ValueError, IndexError):
        pass


# ── ENGAGEMENT MANAGER ────────
def eng_menu():
    while True:
        clear()
        print(f"\n{M}=== ENGAGEMENT MANAGER ==={RS}\n")
        print(f"  Active: {G}{ENGAGEMENT['name'] or 'None'}{RS}\n")
        existing = list_engs()
        for i, n in enumerate(existing, 1):
            mk = f" {G}◄ active{RS}" if n == ENGAGEMENT["name"] else ""
            print(f"  {M}{i}){RS} {n}{mk}")
        print(
            f"\n  {M}[n]{RS} New  {M}[l]{RS} Load  {M}[d]{RS} Delete  {GR}[0]{RS} Back\n"
        )
        c = input("  Action: ").strip().lower()
        if c == "0":
            break
        elif c == "n":
            nm = input(f"  {W}Name: {RS}").strip()
            if nm:
                ENGAGEMENT.update(
                    {
                        "name": nm,
                        "created": datetime.datetime.now().isoformat(),
                        "notes": {},
                        "checklist": {},
                        "searches": [],
                    }
                )
                save_eng()
                print(f"  {G}[+] Created '{nm}'{RS}")
                pause()
        elif c == "l":
            nm = input(f"  {W}Name: {RS}").strip()
            print(f"  {G}Loaded '{nm}'{RS}" if load_eng(nm) else f"  {R}Not found.{RS}")
            pause()
        elif c == "d":
            nm = input(f"  {W}Name: {RS}").strip()
            fp = eng_file(nm)
            if os.path.exists(fp):
                if (
                    input(f"  {R}Delete '{nm}'? (yes/no): {RS}").strip().lower()
                    == "yes"
                ):
                    os.remove(fp)
                    if ENGAGEMENT["name"] == nm:
                        ENGAGEMENT["name"] = None
                    print(f"  {G}Deleted.{RS}")
            else:
                print(f"  {R}Not found.{RS}")
            pause()
        else:
            try:
                i = int(c) - 1
                if 0 <= i < len(existing):
                    load_eng(existing[i])
                    print(f"  {G}Loaded.{RS}")
                    pause()
            except ValueError:
                pass


# ── GLOBAL SEARCH ─────────────
def global_search(init_term=None):
    clear()
    print(f"\n{C}=== GLOBAL SEARCH ==={RS}\n")
    print(f"  {GR}Tip: space-separated keywords = AND  (e.g.: lsass sysmon 4769){RS}\n")
    if init_term:
        print(f"  {GR}Term (from CLI): {W}{init_term}{RS}\n")
        term = init_term
    else:
        term = input(f"  {W}Search: {RS}").strip()
    if not term or len(term) < 2:
        return

    if ENGAGEMENT["name"]:
        ENGAGEMENT["searches"].append(
            {"term": term, "time": datetime.datetime.now().isoformat()}
        )
        save_eng()

    results = []

    # Offensive
    for mod, mdata in load_json_dir(DB_PATH).items():
        for tech, tdata in mdata.items():
            if _match_keywords(_build_blob(tech, tdata), term):
                results.append(
                    (
                        "OFFENSIVE",
                        mod,
                        tech,
                        tdata.get("description", ""),
                        tdata.get("commands", []),
                    )
                )

    # Defensive — SOC SIEM
    for plat, pdata in load_json_dir(os.path.join(DEF_DB_PATH, "SOC SIEM")).items():
        for tech, tdata in pdata.items():
            if _match_keywords(_build_blob(tech, tdata), term):
                results.append(
                    (
                        "SOC SIEM",
                        f"SOC SIEM/{plat}",
                        tech,
                        tdata.get("description", ""),
                        tdata.get("commands", []),
                    )
                )

    # Defensive — Threat Hunting
    for plat, pdata in load_json_dir(
        os.path.join(DEF_DB_PATH, "Threat Hunting")
    ).items():
        for tech, tdata in pdata.items():
            if _match_keywords(_build_blob(tech, tdata), term):
                results.append(
                    (
                        "HUNT",
                        f"THREAT HUNT/{plat}",
                        tech,
                        tdata.get("description", ""),
                        tdata.get("commands", []),
                    )
                )

    note_hits = [
        (k, n)
        for k, ns in ENGAGEMENT.get("notes", {}).items()
        for n in ns
        if _match_keywords(n, term)
    ]

    clear()
    print(f"\n{C}=== RESULTS: '{term}' ==={RS}\n")
    if not results and not note_hits:
        print(f"  {GR}No results.{RS}")
        pause()
        return

    cat_colors = {"OFFENSIVE": R, "SOC SIEM": C, "HUNT": G}
    cat_labels = {"OFFENSIVE": "OFF", "SOC SIEM": "SIEM", "HUNT": "HUNT"}
    for i, (cat, mod, tech, desc, cmds) in enumerate(results, 1):
        cc = cat_colors.get(cat, W)
        lbl = cat_labels.get(cat, cat)
        nhits = _cmd_hits({"commands": cmds}, term)
        hit_tag = f" {G}[{nhits}↑]{RS}" if nhits else ""
        print(f"  {cc}[{i}]{RS} {GR}[{lbl}]{RS} {GR}{mod}{RS} → {W}{tech}{RS}{hit_tag}")
        print(f"       {hl((desc[:68] + '..' if len(desc) > 68 else desc), term)}")
    if note_hits:
        print(f"\n  {M}── Notes ──{RS}")
        for k, n in note_hits:
            print(f"  {M}[N]{RS} {GR}{k}{RS}: {hl(n, term)}")
    print(
        f"\n  {GR}{len(results)} TTPs, {len(note_hits)} notes  |  [#] view detail  [0] back{RS}\n"
    )
    c = input("  Select: ").strip()
    if c == "0":
        return
    try:
        i = int(c) - 1
        if 0 <= i < len(results):
            cat, mod, tech, desc, cmds = results[i]
            if cat in ("SOC SIEM", "HUNT"):
                # Extract platform from "SOC SIEM/PLATFORM" or "THREAT HUNT/PLATFORM"
                parts = mod.split("/", 1)
                sec_prefix = parts[0] if len(parts) > 1 else cat
                platform = parts[1] if len(parts) > 1 else mod
                col = C if cat == "SOC SIEM" else G
                display_def_ttp(
                    platform,
                    tech,
                    {"description": desc, "commands": cmds},
                    col=col,
                    prefix=sec_prefix,
                    search_term=term,
                )
            else:
                display_ttp(
                    tech,
                    {"description": desc, "commands": cmds},
                    module=mod,
                    search_term=term,
                )
    except (ValueError, IndexError):
        pass


# ── EXPORT ─────────────
def export_report():
    if not ENGAGEMENT["name"]:
        print(f"  {Y}[!] No engagement loaded.{RS}")
        pause()
        return
    clear()
    print(f"\n{M}=== EXPORT ==={RS}\n")
    print(f"  {M}[1]{RS} Markdown report   {M}[2]{RS} Notes TXT   {GR}[0]{RS} Back\n")
    c = input("  Select: ").strip()
    now = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    safe = re.sub(r"[^a-zA-Z0-9_\-]", "_", ENGAGEMENT["name"])
    if c == "1":
        fn = os.path.join(ENG_PATH, f"{safe}_report_{now}.md")
        lines = [
            f"# Report — {ENGAGEMENT['name']}",
            "",
            f"**Generated:** {datetime.datetime.now().strftime('%Y-%m-%d %H:%M')}  ",
            f"**Created:** {ENGAGEMENT.get('created', 'N/A')}",
            "",
            "---",
            "",
            "## Notes by Technique",
            "",
        ]
        if ENGAGEMENT["notes"]:
            for k, ns in sorted(ENGAGEMENT["notes"].items()):
                if ns:
                    m, t = k.split("::", 1) if "::" in k else ("", k)
                    lines.append(f"### [{m}] {t}")
                    for n in ns:
                        lines.append(f"- {n}")
                    lines.append("")
        else:
            lines.append("_No notes._\n")
        lines += ["---", "", "## Completed Checklist Steps", ""]
        done_steps = [k for k, v in ENGAGEMENT["checklist"].items() if v]
        if done_steps:
            lines.append(f"{len(done_steps)} step(s) marked complete.")
        else:
            lines.append("_None completed._")
        if ENGAGEMENT.get("searches"):
            lines += ["", "---", "", "## Search History", ""]
            for s in ENGAGEMENT["searches"][-20:]:
                lines.append(f"- `{s['term']}`")
        with open(fn, "w") as f:
            f.write("\n".join(lines))
        print(f"\n  {G}[+] Saved: {fn}{RS}")
    elif c == "2":
        fn = os.path.join(ENG_PATH, f"{safe}_notes_{now}.txt")
        lines = [f"Notes — {ENGAGEMENT['name']}", "=" * 60, ""]
        for k, ns in sorted(ENGAGEMENT["notes"].items()):
            if ns:
                lines.append(f"[ {k} ]")
                for n in ns:
                    lines.append(f"  {n}")
                lines.append("")
        with open(fn, "w") as f:
            f.write("\n".join(lines))
        print(f"\n  {G}[+] Saved: {fn}{RS}")
    pause()


# ── MAIN MENU ────────
def mode_select():
    banner()
    print(f"  {W}Select mode:{RS}\n")
    print(f"  {R}[1]{RS}  Offensive  — TTP Modules")
    print(f"  {B}[2]{RS}  Defensive  — SOC SIEM & Threat Hunting")
    print(f"  {Y}[3]{RS}  Methodology — Checklists")
    print(
        f"  {C}[4]{RS}  Search     — Global keyword search"
        f"  {GR}(tip: ./n00b_hunter.py <term>){RS}"
    )
    print(f"  {M}[5]{RS}  Engagement — Manage sessions & notes")
    print(f"  {G}[6]{RS}  Export     — Generate report")
    print(f"  {GR}[0]{RS}  Exit\n")
    while True:
        c = input("  Select: ").strip()
        if c in ("0", "1", "2", "3", "4", "5", "6"):
            return c


# ── OFFENSIVE TTPs ────
def main_menu(mods):
    while True:
        clear()
        print(f"\n{R}=== [ OFFENSIVE ] TTP MODULES ==={RS}\n")
        opts = list(mods.keys())
        for i, nm in enumerate(opts, 1):
            nc = sum(1 for k in ENGAGEMENT["notes"] if k.startswith(f"{nm}::"))
            ns = f" {M}[{nc}n]{RS}" if nc else ""
            ntechs = len(mods[nm])
            print(f"  {R}{i}){RS} {nm:<38} {GR}({ntechs} techniques){RS}{ns}")
        print(f"\n  {Y}[s]{RS} Search Offensive  {GR}[0]{RS} Back\n")
        c = input("  Category / [s]earch: ").strip()
        if c == "0":
            break
        elif c.lower() == "s":
            cross_section_search(lambda: load_json_dir(DB_PATH), "Offensive", col=R)
        else:
            try:
                i = int(c) - 1
                if 0 <= i < len(opts):
                    cat_menu(opts[i], mods[opts[i]])
            except (ValueError, IndexError):
                pass


def cat_menu(mod, ttp_data):
    while True:
        clear()
        print(f"\n{R}=== {mod} TECHNIQUES ==={RS}")
        print(f"  {'#':<4} {'TECHNIQUE':<28} {'N':<3} {'CMDS':<6} DESCRIPTION")
        print(f"  {GR}{'─'*74}{RS}")
        techs = list(ttp_data.keys())
        for i, t in enumerate(techs, 1):
            tdata = ttp_data[t]
            desc = tdata.get("description", "")
            short = desc[:32] + ".." if len(desc) > 32 else desc
            nc = len(ENGAGEMENT["notes"].get(nkey(mod, t), []))
            ns = f"{M}{nc}{RS}" if nc else " "
            mitre = tdata.get("mitre", "")
            ms = f" {GR}[{mitre}]{RS}" if mitre else ""
            ncmds = len(tdata.get("commands", []))
            print(f"  {i:<4} {R}{t:<28}{RS} {ns:<3} {GR}{ncmds:<6}{RS} {short}{ms}")
        print(f"  {GR}{'─'*74}{RS}")
        print(f"\n  {Y}[s]{RS} Search in {mod}  {GR}[0]{RS} Back\n")
        c = input("  TTP / [s]earch: ").strip()
        if c == "0":
            break
        elif c.lower() == "s":
            section_search(ttp_data, mod, col=R)
        else:
            try:
                i = int(c) - 1
                if 0 <= i < len(techs):
                    display_ttp(techs[i], ttp_data[techs[i]], module=mod)
            except (ValueError, IndexError):
                pass


def display_ttp(name, data, module="", search_term=""):
    while True:
        clear()
        mitre = data.get("mitre", "")
        ms = f"  {GR}[{mitre}]{RS}" if mitre else ""
        print(
            f"\n{C}[*] {(module + ' → ') if module else ''}" f"{name.upper()}{RS}{ms}"
        )
        print(f"\n{W}OVERVIEW:{RS} " f"{hl(data.get('description', ''), search_term)}")
        prereq = data.get("prerequisites", "")
        if prereq:
            print(f"\n{B}PREREQS:{RS}  {prereq}")
        opsec = data.get("opsec", "")
        if opsec:
            print(f"{Y}OPSEC:{RS}    {hl(opsec, search_term)}")
        det = data.get("detection_ref", "")
        if det:
            print(f"{G}DETECT:{RS}   → {det}")
        print(f"  {'='*72}")
        for i, cmd in enumerate(data.get("commands", []), 1):
            print(f"\n  {Y}{i}. " f"{hl(cmd.get('description', ''), search_term)}{RS}")
            method = cmd.get("method", "N/A")
            command = hl(cmd.get("command", "N/A"), search_term)
            print(f"     {G}[{method}]{RS} {command}")
        if module:
            show_notes(module, name)
        print(f"\n  {'─'*72}")
        print(
            f"\n  {M}[n]{RS} Add note  {M}[d]{RS} Delete note" f"  {GR}[0]{RS} Back\n"
        )
        a = input("  Action: ").strip().lower()
        if a == "0":
            break
        elif a == "n" and module:
            add_note(module, name)
        elif a == "d" and module:
            del_note(module, name)


# ── DEFENSIVE — PARENT SUBMENU ────
def defensive_menu():
    """Defensive parent menu — SOC SIEM and Threat Hunting as submenus."""
    while True:
        clear()
        print(f"\n{B}╔{'═'*56}╗{RS}")
        print(f"{B}║{RS}  {W}[ DEFENSIVE ] — Blue Team Modules{RS}{'':>21}{B}║{RS}")
        print(f"{B}╠{'═'*56}╣{RS}")
        print(
            f"{B}║{RS}  {C}[1]{RS}  SOC SIEM        Detection & alert queries        {B}║{RS}"
        )
        print(
            f"{B}║{RS}  {G}[2]{RS}  Threat Hunting  Proactive hunt queries           {B}║{RS}"
        )
        print(
            f"{B}║{RS}  {Y}[s]{RS}  Search          Cross all defensive sections     {B}║{RS}"
        )
        print(
            f"{B}║{RS}  {GR}[0]{RS}  Back                                            {B}║{RS}"
        )
        print(f"\n{B}╚{'═'*56}╝{RS}\n")
        c = input("  Select: ").strip()
        if c == "0":
            break
        elif c == "1":
            soc_siem_menu()
        elif c == "2":
            threat_hunting_menu()
        elif c.lower() == "s":
            # Search across ALL defensive sections combined
            _defensive_global_search()


def _defensive_global_search():
    """Search across both SOC SIEM and Threat Hunting in one query."""
    clear()
    print(f"\n{B}── Search across ALL Defensive sections ──{RS}\n")
    print(
        f"  {GR}Tip: space-separated keywords = AND  (e.g.: lsass 4769 kerberoast){RS}\n"
    )
    term = input(f"  {W}Keyword(s): {RS}").strip()
    if not term or len(term) < 2:
        return

    results = []
    for plat, pdata in load_json_dir(os.path.join(DEF_DB_PATH, "SOC SIEM")).items():
        for tname, tdata in pdata.items():
            if _match_keywords(_build_blob(tname, tdata), term):
                results.append(("SOC SIEM", plat, tname, tdata, _cmd_hits(tdata, term)))

    for plat, pdata in load_json_dir(
        os.path.join(DEF_DB_PATH, "Threat Hunting")
    ).items():
        for tname, tdata in pdata.items():
            if _match_keywords(_build_blob(tname, tdata), term):
                results.append(("HUNT", plat, tname, tdata, _cmd_hits(tdata, term)))

    clear()
    print(f"\n{B}── '{term}'  [ALL DEFENSIVE]  {len(results)} match(es) ──{RS}\n")
    if not results:
        print(f"  {GR}No results.{RS}")
        pause()
        return

    for i, (section, plat, tname, tdata, nhits) in enumerate(results, 1):
        col = C if section == "SOC SIEM" else G
        lbl = "SIEM" if section == "SOC SIEM" else "HUNT"
        desc = tdata.get("description", "")
        short = (desc[:55] + "..") if len(desc) > 55 else desc
        hit_tag = f" {G}[{nhits}↑]{RS}" if nhits else ""
        print(f"  {col}[{i}]{RS} {GR}[{lbl}/{plat}]{RS} {W}{tname}{RS}{hit_tag}")
        print(f"       {hl(short, term)}\n")

    print(f"  {GR}[#] drill in  [0] back{RS}\n")
    c = input("  Select: ").strip()
    if c == "0":
        return
    try:
        idx = int(c) - 1
        if 0 <= idx < len(results):
            section, plat, tname, tdata, _ = results[idx]
            col = C if section == "SOC SIEM" else G
            prefix = "SOC SIEM" if section == "SOC SIEM" else "Threat Hunting"
            display_def_ttp(
                plat, tname, tdata, col=col, prefix=prefix, search_term=term
            )
    except (ValueError, IndexError):
        pass


# ── DEFENSIVE — SOC SIEM ──────
def load_soc_siem():
    return load_json_dir(os.path.join(DEF_DB_PATH, "SOC SIEM"))


def soc_siem_menu():
    while True:
        clear()
        print(f"\n{C}╔{'═'*56}╗{RS}")
        print(f"{C}║{RS}  {W}[ DEFENSIVE ] › SOC SIEM{RS}{'':>31}{C}║{RS}")
        print(f"{C}╚{'═'*56}╝{RS}\n")
        data = load_soc_siem()
        tools = list(data.keys())
        for i, t in enumerate(tools, 1):
            cnt = len(data[t])
            st = f"{G}{cnt} techniques{RS}" if cnt else f"{GR}no data{RS}"
            print(f"  {C}{i}){RS} {t:<20} [{st}]")
        print(f"\n  {Y}[s]{RS} Search ALL SOC SIEM  {GR}[0]{RS} Back\n")
        c = input("  Platform / [s]earch: ").strip()
        if c == "0":
            break
        elif c.lower() == "s":
            cross_section_search(load_soc_siem, "SOC SIEM", col=C, prefix="SOC SIEM")
        else:
            try:
                i = int(c) - 1
                if 0 <= i < len(tools):
                    tn = tools[i]
                    qdata = data[tn]
                    if not qdata:
                        input(f"  {Y}[!] No data for {tn}.{RS}  Press Enter...")
                    else:
                        def_tech_menu(tn, qdata, col=C, prefix="SOC SIEM")
            except (ValueError, IndexError):
                pass


# ── DEFENSIVE — THREAT HUNTING ────
def load_threat_hunting():
    return load_json_dir(os.path.join(DEF_DB_PATH, "Threat Hunting"))


def threat_hunting_menu():
    while True:
        clear()
        print(f"\n{G}╔{'═'*56}╗{RS}")
        print(f"{G}║{RS}  {W}[ DEFENSIVE ] › THREAT HUNTING{RS}{'':>25}{G}║{RS}")
        print(f"{G}╚{'═'*56}╝{RS}\n")
        data = load_threat_hunting()
        tools = list(data.keys())
        for i, t in enumerate(tools, 1):
            cnt = len(data[t])
            st = f"{G}{cnt} techniques{RS}" if cnt else f"{GR}no data{RS}"
            print(f"  {G}{i}){RS} {t:<20} [{st}]")
        print(f"\n  {Y}[s]{RS} Search ALL Threat Hunting  {GR}[0]{RS} Back\n")
        c = input("  Platform / [s]earch: ").strip()
        if c == "0":
            break
        elif c.lower() == "s":
            cross_section_search(
                load_threat_hunting, "Threat Hunting", col=G, prefix="Threat Hunting"
            )
        else:
            try:
                i = int(c) - 1
                if 0 <= i < len(tools):
                    tn = tools[i]
                    qdata = data[tn]
                    if not qdata:
                        input(f"  {Y}[!] No data for {tn}.{RS}  Press Enter...")
                    else:
                        def_tech_menu(tn, qdata, col=G, prefix="Threat Hunting")
            except (ValueError, IndexError):
                pass


# ── DEFENSIVE — SHARED TECHNIQUE VIEWS ────
def def_tech_menu(tname, ttp_data, col=B, prefix="DEFENSIVE"):
    while True:
        clear()
        total = len(ttp_data)
        print(
            f"\n{col}=== {prefix.upper()} › {tname.upper()} — {total} techniques ==={RS}"
        )
        print(f"  {'#':<4} {'TECHNIQUE':<38} {'CMDS':<6} DESCRIPTION")
        print(f"  {GR}{'─'*74}{RS}")
        techs = list(ttp_data.keys())
        for i, t in enumerate(techs, 1):
            tdata = ttp_data[t]
            desc = tdata.get("description", "")
            short = desc[:26] + ".." if len(desc) > 26 else desc
            ncmds = len(tdata.get("commands", []))
            mitre = tdata.get("mitre", "")
            ms = f" {GR}[{mitre}]{RS}" if mitre else ""
            print(
                f"  {i:<4} {col}{t:<38}{RS}"
                f" {GR}{ncmds:<6}{RS} {short}{ms}"
            )
        print(f"  {GR}{'─'*74}{RS}")
        print(f"\n  {Y}[s]{RS} Search in {tname}  {GR}[0]{RS} Back\n")
        c = input("  Technique / [s]earch: ").strip()
        if c == "0":
            break
        elif c.lower() == "s":
            section_search(ttp_data, tname, col=col, prefix=prefix)
        else:
            try:
                i = int(c) - 1
                if 0 <= i < len(techs):
                    display_def_ttp(
                        tname, techs[i], ttp_data[techs[i]], col=col, prefix=prefix
                    )
            except (ValueError, IndexError):
                pass


def display_def_ttp(  # noqa: E501
    tname, name, data, col=B, prefix="DEFENSIVE", search_term=""
):
    mod = f"{prefix}/{tname}"
    while True:
        clear()
        mitre = data.get("mitre", "")
        ms = f"  {GR}[{mitre}]{RS}" if mitre else ""
        print(
            f"\n{col}[*] {prefix.upper()} › "
            f"{tname.upper()} | {name.upper()}{RS}{ms}"
        )
        print(f"\n{W}OVERVIEW:{RS} " f"{hl(data.get('description', ''), search_term)}")
        tuning = data.get("tuning", "")
        if tuning:
            print(f"{Y}TUNING:{RS}   {hl(tuning, search_term)}")
        print(f"  {'='*72}")
        cmds = data.get("commands", [])
        for i, cmd in enumerate(cmds, 1):
            print(f"\n  {Y}{i}. " f"{hl(cmd.get('description', ''), search_term)}{RS}")
            print(f"     {col}[{cmd.get('method', 'N/A')}]{RS}")
            for line in hl(cmd.get("command", "N/A"), search_term).split("\n"):
                print(f"       {line}")
        show_notes(mod, name)
        print(f"\n  {'─'*72}")
        print(
            f"\n  {M}[n]{RS} Add note  {M}[d]{RS} Delete note" f"  {GR}[0]{RS} Back\n"
        )
        a = input("  Action: ").strip().lower()
        if a == "0":
            break
        elif a == "n":
            add_note(mod, name)
        elif a == "d":
            del_note(mod, name)


# ── METHODOLOGY ───────
def meth_select():
    while True:
        clear()
        print(f"\n{Y}=== METHODOLOGY CHECKLISTS ==={RS}\n")
        print(f"  {R}[1]{RS} Offensive     — Pentest checklists")
        print(f"  {B}[2]{RS} SOC Tier 1    — Alert triage & escalation")
        print(f"  {C}[3]{RS} SOC Tier 2    — Incident investigation & containment")
        print(f"  {G}[4]{RS} Threat Hunting — Proactive hunt methodology")
        print(
            f"  {M}[5]{RS} Incident Response — IR playbooks and checklists for a proper report"
        )
        print(f"\n  {GR}[0]{RS} Back\n")
        c = input("  Select: ").strip()
        if c == "0":
            break
        elif c == "1":
            meth_menu("offensive", METH_OFF_PATH, R)
        elif c == "2":
            meth_menu_single(
                "soc_tier1", os.path.join(METH_DEF_PATH, "soc_tier1.json"), B
            )
        elif c == "3":
            meth_menu_single(
                "soc_tier2", os.path.join(METH_DEF_PATH, "soc_tier2.json"), C
            )
        elif c == "4":
            meth_menu_single(
                "threat_hunting", os.path.join(METH_DEF_PATH, "threat_hunting.json"), G
            )
        elif c == "5":
            meth_menu_single(
                "incident_response",
                os.path.join(METH_DEF_PATH, "IR_report_template.json"),
                M,
            )


def meth_menu_single(mode, filepath, col):
    if not os.path.exists(filepath):
        input(f"  {R}File not found: {filepath}{RS}  Press Enter...")
        return
    try:
        with open(filepath) as f:
            data = json.load(f)
    except Exception as e:
        input(f"  {R}Error loading: {e}{RS}  Press Enter...")
        return
    name = list(data.keys())[0]
    display_meth(name, {name: data[name]}, col, mode)


def meth_menu(mode, path, col):
    mods = load_json_dir(path)
    if not mods:
        input(f"  {R}No files in {path}{RS}  Press Enter...")
        return
    label = "OFFENSIVE" if mode == "offensive" else "DEFENSIVE"
    while True:
        clear()
        print(f"\n{col}=== [ {label} ] CHECKLISTS ==={RS}\n")
        opts = list(mods.keys())
        for i, nm in enumerate(opts, 1):
            tot, done = _count_prog(mode, nm, mods[nm])
            pg = f"{G}{done}/{tot}{RS}" if tot else f"{GR}0/0{RS}"
            print(f"  {col}{i}){RS} {nm:<42} [{pg}]")
        print(f"\n  {GR}0){RS} Back\n")
        c = input("  Checklist: ").strip()
        if c == "0":
            break
        try:
            i = int(c) - 1
            if 0 <= i < len(opts):
                display_meth(opts[i], mods[opts[i]], col, mode)
        except (ValueError, IndexError):
            pass


def _ck(mode, name, pk, si):
    return f"{mode}::{name}::{pk}::{si}"


def _count_prog(mode, name, data):
    tot = done = 0
    for item in data.values():
        phases = item.get("phases", [])
        if not phases:
            for sec in item.get("sections", {}).values():
                phases += sec.get("phases", [])
        for pi, ph in enumerate(phases):
            for si in range(len(ph.get("steps", []))):
                tot += 1
                if ENGAGEMENT["checklist"].get(_ck(mode, name, f"p{pi}", si), False):
                    done += 1
    return tot, done


def display_meth(name, data, col, mode):
    top = list(data.keys())
    while True:
        clear()
        print(f"\n{col}=== {name} ==={RS}\n")
        blocks = []
        for tk in top:
            item = data[tk]
            if "phases" in item:
                blocks.append((tk, item["phases"], ""))
            elif "sections" in item:
                for sn, sd in item["sections"].items():
                    blocks.append((f"{tk} — {sn}", sd.get("phases", []), sn))
        gmap = {}
        ctr = 1
        for _, (label, phases, prefix) in enumerate(blocks):
            print(f"\n{W}━━━ {label} ━━━{RS}")
            for pi, ph in enumerate(phases):
                pk = f"{prefix}::p{pi}" if prefix else f"p{pi}"
                steps = ph.get("steps", [])
                tot = len(steps)
                done = sum(
                    1
                    for si in range(tot)
                    if ENGAGEMENT["checklist"].get(_ck(mode, name, pk, si), False)
                )
                pc = G if done == tot and tot > 0 else Y
                print(f"\n  {pc}{ph.get('phase', '')}  [{done}/{tot}]{RS}")
                for si, step in enumerate(steps):
                    checked = ENGAGEMENT["checklist"].get(
                        _ck(mode, name, pk, si), False
                    )
                    box = f"{G}[✔]{RS}" if checked else f"{GR}[ ]{RS}"
                    task = step.get("task", "")
                    td = f"{GR}{task}{RS}" if checked else task
                    print(f"    {box} {ctr:>3}. {col}{step.get('step', '')}{RS}  {td}")
                    gmap[ctr] = (pk, si)
                    ctr += 1
        this_done = sum(
            1
            for k, v in ENGAGEMENT["checklist"].items()
            if v and k.startswith(f"{mode}::{name}::")
        )
        print(f"\n{'─'*65}")
        print(f"  {G}Progress: {this_done}/{ctr-1}{RS}")
        if not ENGAGEMENT["name"]:
            print(f"  {Y}[!] Load engagement to persist progress{RS}")
        print(
            f"\n  {Y}[#]{RS} Toggle  {Y}[a]{RS} All done  {Y}[r]{RS} Reset  {GR}[0]{RS} Back\n"
        )
        c = input("  Action: ").strip().lower()
        if c == "0":
            break
        elif c == "a":
            for pk, si in gmap.values():
                ENGAGEMENT["checklist"][_ck(mode, name, pk, si)] = True
            save_eng()
        elif c == "r":
            if input(f"  {R}Reset? (yes/no): {RS}").strip().lower() == "yes":
                for pk, si in gmap.values():
                    ENGAGEMENT["checklist"][_ck(mode, name, pk, si)] = False
                save_eng()
        else:
            try:
                n = int(c)
                if n in gmap:
                    pk, si = gmap[n]
                    k = _ck(mode, name, pk, si)
                    ENGAGEMENT["checklist"][k] = not ENGAGEMENT["checklist"].get(
                        k, False
                    )
                    save_eng()
            except ValueError:
                pass


# ── ENTRY POINT ───────
if __name__ == "__main__":
    args = sys.argv[1:]

    # --list: dump all offensive techniques as TSV (technique | mitre | file)
    if args and args[0] == "--list":
        filter_term = args[1].lower() if len(args) > 1 else ""
        mods = load_json_dir(DB_PATH)
        rows = []
        for mod, mdata in mods.items():
            for tname, tdata in mdata.items():
                mitre = tdata.get("mitre", "")
                cmds = tdata.get("commands", [])
                method = cmds[0].get("method", "") if cmds else ""
                if not filter_term or filter_term in tname.lower() or filter_term in mitre.lower():
                    rows.append(f"{tname}\t{mitre}\t{method}\t{mod}")
        for r in sorted(rows):
            print(r)
        sys.exit(0)

    # --export-json: export current engagement data as JSON
    if args and args[0] == "--export-json":
        out_path = args[1] if len(args) > 1 else "engagement_export.json"
        existing = list_engs()
        if existing:
            most_recent = sorted(
                existing, key=lambda n: os.path.getmtime(eng_file(n)), reverse=True
            )
            load_eng(most_recent[0])
        with open(out_path, "w") as fh:
            json.dump(ENGAGEMENT, fh, indent=2)
        print(f"Exported engagement to: {out_path}")
        sys.exit(0)

    # CLI quick-search: ./n00b_hunter.py <search term>
    cli_term = " ".join(args) if args else None

    existing = list_engs()
    if existing:
        most_recent = sorted(
            existing, key=lambda n: os.path.getmtime(eng_file(n)), reverse=True
        )
        load_eng(most_recent[0])

    # Jump straight into global search if term provided on CLI
    if cli_term:
        global_search(init_term=cli_term)
        save_eng()
        sys.exit(0)

    try:
        while True:
            c = mode_select()
            if c == "0":
                save_eng()
                print(f"\n{GR}  [!] Closed. Progress saved.{RS}\n")
                sys.exit(0)
            elif c == "1":
                mods = load_json_dir(DB_PATH)
                if not mods:
                    input(f"  {R}No db/ files.{RS}  Press Enter...")
                else:
                    main_menu(mods)
            elif c == "2":
                defensive_menu()
            elif c == "3":
                meth_select()
            elif c == "4":
                global_search()
            elif c == "5":
                eng_menu()
            elif c == "6":
                export_report()
    except KeyboardInterrupt:
        save_eng()
        print(f"\n{GR}  [!] Closed. Progress saved.{RS}\n")
