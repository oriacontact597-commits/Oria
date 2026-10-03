#!/usr/bin/env python3
"""
seed_from_yaml.py — Ingère les .md du dossier seed/universites_pilote/ vers l'API REST du backend.

Pré-requis :
  - Backend Spring Boot démarré et accessible (par défaut http://localhost:8080)
  - Compte admin existant (ADMIN ou SUPER_ADMIN), défaut : admin@activeducation.tg / abalakata
  - Python 3.10+ avec : requests (installe via `pip install requests pyyaml`)
  - Le serveur doit connaître l'endpoint POST /api/v1/bibliotheque/{etablissements,filieres}

Usage :
  python3 seed_from_yaml.py                    # lit ./universites_pilote/, URL=localhost:8080
  python3 seed_from_yaml.py --dir ./autre/     # autre dossier
  python3 seed_from_yaml.py --url https://api.oria.tg
  ADMIN_EMAIL=admin@x.tg ADMIN_PASS=xxx python3 seed_from_yaml.py

Idempotence :
  - Filières : on checke par domaine, on n'en crée qu'une par domaine manquant
  - Établissements : on checke par titre exact ; si un établissement existe déjà, on logge + skip
"""

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

import requests
import yaml

DEFAULT_URL = "http://localhost:8080"
DEFAULT_DIR = "/home/grace/hackaton/oria-fronted-main/seed/universites_pilote"
DEFAULT_ADMIN_EMAIL = "admin@activeducation.tg"
DEFAULT_ADMIN_PASS = "abalakata"


class SeedStats:
    def __init__(self):
        self.etabs_created = 0
        self.etabs_skipped = 0
        self.etabs_failed = []
        self.filieres_created = 0
        self.filieres_reused = 0
        self.filieres_failed = []

    def report(self):
        print()
        print("=" * 70)
        print(f"Établissements créés : {self.etabs_created}")
        print(f"Établissements déjà existants (skipped) : {self.etabs_skipped}")
        print(f"Établissements en erreur : {len(self.etabs_failed)}")
        for eid, err in self.etabs_failed[:10]:
            print(f"  - {eid}: {err[:200]}")
        print(f"Filières créées : {self.filieres_created}")
        print(f"Filières réutilisées : {self.filieres_reused}")
        print(f"Filières en erreur : {len(self.filieres_failed)}")
        print("=" * 70)


def login(base_url, email, password):
    url = f"{base_url}/api/v1/auth/login"
    r = requests.post(url, json={"email": email, "motDePasse": password}, timeout=30)
    r.raise_for_status()
    body = r.json()
    # Backend renvoie accessToken (Spring Security). On accepte token/access_token par compat.
    token = body.get("accessToken") or body.get("access_token") or body.get("token")
    if not token:
        raise RuntimeError(f"Login OK mais pas de token dans la réponse: {body}")
    return token


def auth_headers(token):
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}


def parse_md(path):
    """Parse un fichier .md avec frontmatter YAML. Retourne (yaml_dict, markdown_body)."""
    txt = path.read_text(encoding="utf-8")
    # Frontmatter delimiters
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n?(.*)$", txt, re.DOTALL)
    if not m:
        raise ValueError(f"{path.name}: pas de frontmatter --- ... ---")
    fm = yaml.safe_load(m.group(1)) or {}
    body = m.group(2).strip()
    return fm, body


def split_frontmatter(path):
    """Variante pour frontmatter qui se termine par --- (sans contenu après)."""
    txt = path.read_text(encoding="utf-8")
    parts = txt.split("---")
    if len(parts) < 3:
        raise ValueError(f"{path.name}: frontmatter mal formé")
    # parts[0] = vide/avant, parts[1] = yaml, parts[2+] = corps
    fm = yaml.safe_load(parts[1]) or {}
    body = "---".join(parts[2:]).strip()
    return fm, body


def list_etablissements(base_url, headers):
    """GET /api/v1/bibliotheque/etablissements paginé. Renvoie {titre: trackingId}."""
    out = {}
    page = 0
    size = 100
    while True:
        r = requests.get(
            f"{base_url}/api/v1/bibliotheque/etablissements",
            params={"page": page, "size": size},
            headers=headers,
            timeout=30,
        )
        r.raise_for_status()
        body = r.json()
        items = body.get("content", body) if isinstance(body, dict) else body
        if not items:
            break
        for it in items:
            titre = it.get("titre", "")
            if titre:
                out[titre] = it.get("trackingId")
        if not isinstance(body, dict) or page + 1 >= body.get("totalPages", 1):
            break
        page += 1
    return out


def sanitize_domaine(domaine):
    """Assainit un nom de domaine pour qu'il passe en URL et évite les collisions.

    - / → ' - ' (les slashes sont légitimement des séparateurs de domaines)
    - ( ) → supprimés
    - – → '-'
    - apostrophes typographiques → '
    - espaces multiples → simple
    """
    s = domaine
    s = s.replace("/", " - ")
    s = s.replace("(", " ").replace(")", " ")
    s = s.replace("–", "-").replace("—", "-")
    s = s.replace("'", "'").replace("'", "'")
    s = " ".join(s.split())
    return s.strip()


def list_filieres_by_domaine(base_url, headers, domaine):
    """Désactivé : ce endpoint plante en 500 sur les domaines avec caractères spéciaux.
    On utilise list_all_filieres_titles() à la place pour la dédup en mémoire.
    """
    return []


def list_all_filieres_titles(base_url, headers):
    """GET /api/v1/bibliotheque/filieres paginé → dict {titre_sanitizé: trackingId}.
    On sanitise les titres lus pour matcher nos domaines normalisés.
    """
    out = {}
    page = 0
    size = 200
    while True:
        r = requests.get(
            f"{base_url}/api/v1/bibliotheque/filieres",
            params={"page": page, "size": size},
            headers=headers,
            timeout=30,
        )
        r.raise_for_status()
        body = r.json()
        items = body.get("content", body) if isinstance(body, dict) else body
        if not items:
            break
        for it in items:
            titre = it.get("titre", "")
            if titre:
                norm = sanitize_domaine(titre)
                if norm:
                    out[norm] = it.get("trackingId")
        if not isinstance(body, dict) or page + 1 >= body.get("totalPages", 1):
            break
        page += 1
    return out


def _post_json_with_relogin(state, url, payload):
    """POST JSON ; si 401, re-login via state['login']() et retente 1 fois.
    state = {"login": callable, "headers_getter": callable, "sleep_after": float}
    """
    last_err = None
    for attempt in range(2):
        try:
            r = requests.post(
                url,
                headers=state["headers_getter"](),
                json=payload,
                timeout=30,
            )
            if r.status_code == 401 and attempt == 0:
                print(f"    ↻ 401 sur {url} → re-login")
                state["login"]()
                continue
            r.raise_for_status()
            time.sleep(state.get("sleep_after", 0.31))
            return r.json()
        except requests.exceptions.HTTPError as he:
            last_err = he
            if he.response.status_code == 401 and attempt == 0:
                continue
            raise
    raise last_err


def create_filiere(state, base_url, domaine):
    """POST /api/v1/bibliotheque/filieres avec champs minimaux requis."""
    payload = {
        "titre": domaine,
        "resume": f"Domaine {domaine} — auto-créé lors du seed.",
        "contenu": f"Domaine d'études : {domaine}.",
        "estPublie": True,
        "duree": "Non précisée",
        "niveauRequis": "Baccalauréat",
        "domaine": domaine,
    }
    return _post_json_with_relogin(state, f"{base_url}/api/v1/bibliotheque/filieres", payload)


def create_etablissement(state, base_url, payload):
    """POST /api/v1/bibliotheque/etablissements."""
    return _post_json_with_relogin(state, f"{base_url}/api/v1/bibliotheque/etablissements", payload)


class ApiClient:
    """Wrapper requests avec auto-refresh JWT et re-login sur 401."""

    def __init__(self, base_url, email, password):
        self.base_url = base_url
        self.email = email
        self.password = password
        self.token = None
        self.token_acquired_at = 0
        self.token_ttl_seconds = 12 * 60  # refresh avant les 15 min
        self._login()

    def _login(self):
        r = requests.post(
            f"{self.base_url}/api/v1/auth/login",
            json={"email": self.email, "motDePasse": self.password},
            timeout=30,
        )
        r.raise_for_status()
        body = r.json()
        token = body.get("accessToken") or body.get("access_token") or body.get("token")
        if not token:
            raise RuntimeError(f"Login OK mais pas de token: {body}")
        self.token = token
        self.token_acquired_at = time.monotonic()
        print(f"[seed_from_yaml] (re)login OK — token acquis")
        # Throttle léger pour rester sous le rate limit 200/1min (≈3.3 req/s)
        time.sleep(0.31)

    def _maybe_refresh(self):
        if time.monotonic() - self.token_acquired_at > self.token_ttl_seconds:
            self._login()

    def _retry_401(self, func, *args, **kwargs):
        """Exécute func() ; si 401, retente 1 fois après re-login."""
        try:
            return func(*args, **kwargs)
        except requests.exceptions.HTTPError as he:
            if he.response.status_code == 401:
                print(f"  ↻ 401 reçu → re-login")
                self._login()
                return func(*args, **kwargs)
            raise

    def headers(self):
        return {"Authorization": f"Bearer {self.token}", "Content-Type": "application/json"}

    def post_json(self, path, payload):
        self._maybe_refresh()
        def do():
            r = requests.post(
                f"{self.base_url}{path}",
                headers=self.headers(),
                json=payload,
                timeout=30,
            )
            if r.status_code == 401:
                r.raise_for_status()
            r.raise_for_status()
            return r.json()
        return self._retry_401(do)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", default=os.environ.get("API_URL", DEFAULT_URL))
    ap.add_argument("--dir", dest="src_dir", default=DEFAULT_DIR)
    ap.add_argument("--email", default=os.environ.get("ADMIN_EMAIL", DEFAULT_ADMIN_EMAIL))
    ap.add_argument("--password", default=os.environ.get("ADMIN_PASS", DEFAULT_ADMIN_PASS))
    ap.add_argument("--dry-run", action="store_true", help="Affiche ce qui serait fait sans POSTer")
    args = ap.parse_args()

    src_dir = Path(args.src_dir)
    if not src_dir.exists():
        sys.exit(f"Dossier source introuvable : {src_dir}")

    md_files = sorted(src_dir.rglob("*.md"))
    if not md_files:
        sys.exit(f"Aucun .md trouvé dans {src_dir}")

    print(f"[seed_from_yaml] {len(md_files)} fichiers .md à traiter depuis {src_dir}")
    print(f"[seed_from_yaml] URL backend : {args.url}")
    if args.dry_run:
        print("[seed_from_yaml] MODE DRY-RUN : aucune requête POST ne sera envoyée")

    # Parse tous les .md
    etabs = []
    all_domaines = set()
    for f in md_files:
        try:
            fm, body = parse_md(f)
        except Exception as e:
            print(f"  ⚠ parse error: {f.relative_to(src_dir)}: {e}")
            continue
        if not fm.get("titre"):
            print(f"  ⚠ pas de titre: {f.relative_to(src_dir)}")
            continue
        etabs.append({"path": f, "fm": fm, "body": body})
        for d in fm.get("filieresProposees", []) or []:
            if d:
                # Sanitize pour éviter les 500 backend (slashes, parenthèses...)
                normalized = sanitize_domaine(d)
                if normalized:
                    all_domaines.add(normalized)

    print(f"[seed_from_yaml] {len(etabs)} établissements parsés, {len(all_domaines)} domaines uniques")

    stats = SeedStats()

    if args.dry_run:
        for e in etabs:
            print(f"  - {e['fm'].get('idSheet')} {e['fm']['titre'][:60]} ({len(e['fm'].get('filieresProposees', []) or [])} filières)")
        return

    # 1. Login + state mutable pour re-login auto
    state = {"token": None, "base_url": args.url, "email": args.email, "password": args.password, "sleep_after": 0.31}

    def do_login():
        try:
            t = login(args.url, args.email, args.password)
            state["token"] = t
            print(f"[seed_from_yaml] Login OK ({args.email})")
        except Exception as e:
            sys.exit(f"Login échoué : {e}")

    def get_headers():
        return auth_headers(state["token"])

    state["login"] = do_login
    state["headers_getter"] = get_headers
    do_login()

    # 2. Lister les établissements existants (pour idempotence)
    print(f"[seed_from_yaml] Listing des établissements existants pour idempotence...")
    try:
        existing_etabs = list_etablissements(args.url, get_headers())
        print(f"[seed_from_yaml] {len(existing_etabs)} établissements déjà en base")
    except Exception as e:
        print(f"[seed_from_yaml] ⚠ Impossible de lister les établissements : {e}")
        existing_etabs = {}

    # 3. Lister TOUTES les filières existantes (cache en mémoire pour dédup)
    filiere_uuid = {}  # domaine (sanitizé) -> trackingId
    print(f"[seed_from_yaml] Listing des filières existantes pour dédup...")
    try:
        existing_filieres = list_all_filieres_titles(args.url, get_headers())
        print(f"[seed_from_yaml] {len(existing_filieres)} titres de filières uniques en base")
    except Exception as e:
        print(f"[seed_from_yaml] ⚠ Impossible de lister les filières : {e}")
        existing_filieres = {}

    # 4. Créer les domaines manquants
    print(f"[seed_from_yaml] Traitement de {len(all_domaines)} domaines uniques (post-sanitize)...")
    for i, domaine in enumerate(sorted(all_domaines), 1):
        # Dédup via cache en mémoire
        if domaine in existing_filieres and existing_filieres[domaine]:
            filiere_uuid[domaine] = existing_filieres[domaine]
            stats.filieres_reused += 1
            continue
        try:
            created = create_filiere(state, args.url, domaine)
            filiere_uuid[domaine] = created.get("trackingId")
            stats.filieres_created += 1
            if stats.filieres_created % 20 == 0:
                print(f"  ... {stats.filieres_created} filières créées")
        except Exception as e:
            stats.filieres_failed.append((domaine, str(e)))
            print(f"  ⚠ Filière {domaine!r} non créée : {str(e)[:120]}")
        time.sleep(0.05)  # throttle léger

    print(f"[seed_from_yaml] Filières prêtes : {stats.filieres_created} créées, {stats.filieres_reused} réutilisées")

    # 5. Pour chaque établissement, résoudre les filièreTrackingIds et POSTer
    print(f"[seed_from_yaml] Création des {len(etabs)} établissements...")
    for i, e in enumerate(etabs, 1):
        fm = e["fm"]
        titre = fm["titre"]

        # Idempotence: si déjà présent, on skip
        if titre in existing_etabs:
            stats.etabs_skipped += 1
            continue

        # Truncate aux limites backend (titre 200, resume 1000)
        titre_safe = titre[:200]
        resume_src = fm.get("resume") or ""
        resume_safe = (resume_src or f"{titre_safe} — établissement d'enseignement supérieur au Togo.")[:1000]

        # Résoudre les filièreTrackingIds
        fids = []
        for d in fm.get("filieresProposees", []) or []:
            if d in filiere_uuid and filiere_uuid[d]:
                fids.append(filiere_uuid[d])

        payload = {
            "titre": titre_safe,
            "resume": resume_safe,
            "contenu": fm.get("contenu") or resume_safe,
            "estPublie": fm.get("estPublie", True),
            "adresse": fm.get("adresse") or "Non précisée",
            "ville": fm.get("ville") or "Lomé",
            "typeEtablissement": fm.get("typeEtablissement") or "AUTRE",
            "niveau": fm.get("niveau"),
            "contacts": fm.get("contacts"),
            "siteWeb": fm.get("siteWeb"),
            "offreFormation": fm.get("offreFormation"),
            "estPublic": fm.get("estPublic", True),
            # latitude/longitude droppées : Jackson 3.x sur le backend renvoie NoClassDefFoundError
            # sur tools.jackson.core.io.NumberInput lors de la désérialisation Double.
            # Les coordonnées restent dans le .md (traçabilité) et dans le store local (front).
            "latitude": None,
            "longitude": None,
            "countryCode": fm.get("countryCode", "TG"),
            "filieresTrackingIds": fids,
        }
        # Drop None valeurs (Spring va crier dessus sur certains)
        payload = {k: v for k, v in payload.items() if v is not None}

        try:
            r = create_etablissement(state, args.url, payload)
            new_id = r.get("trackingId")
            stats.etabs_created += 1
            if i % 10 == 0:
                print(f"  ... {i}/{len(etabs)} établissements traités ({stats.etabs_created} créés, {stats.etabs_skipped} skip)")
        except requests.exceptions.HTTPError as he:
            err_txt = ""
            try:
                err_txt = he.response.text[:200]
            except Exception:
                pass
            stats.etabs_failed.append((fm.get("idSheet", titre), f"{he.response.status_code}: {err_txt}"))
            print(f"  ⚠ {fm.get('idSheet', titre)}: {he.response.status_code} {err_txt[:120]}")
        except Exception as ex:
            stats.etabs_failed.append((fm.get("idSheet", titre), str(ex)))
            print(f"  ⚠ {fm.get('idSheet', titre)}: {str(ex)[:120]}")
        time.sleep(0.05)

    stats.report()


if __name__ == "__main__":
    main()
