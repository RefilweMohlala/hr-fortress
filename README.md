# HR Document Fortress

**Module 2 of a five-module AI automation engineering portfolio** — a
local, air-gapped document processing pipeline built for South African
HR compliance under POPIA.


---

## The problem

HR departments handle the highest-risk category of personal
information a company holds — employee ID numbers, salary details,
banking information, disciplinary records. Many AI document-processing
tools route this data through cloud APIs, which raises real questions
under South Africa's Protection of Personal Information Act (POPIA) —
specifically Section 72's restrictions on transferring personal
information outside the country.

This project takes a different approach: **every step runs locally.**
No document, and no piece of personal information extracted from it,
ever leaves the machine.

---

## What it does

1. **Watches a local inbox folder** for new HR documents
2. **Extracts text** from the document locally — no cloud OCR
3. **Detects South African–specific PII** — ID numbers (validated with
   a Luhn checksum, not just pattern-matched), phone numbers, email
   addresses, ZAR salary figures, and banking details — and redacts
   them before the document goes anywhere near the LLM
4. **Classifies the document** into one of six HR categories
   (employment contract, ID document, payslip, disciplinary record,
   leave document, general correspondence) using a locally-hosted LLM
   via Ollama — zero external API calls
5. **Logs every step to Postgres** — classification, PII categories
   found, risk score, processing time — as a queryable audit trail
6. **Routes by risk**: critical/high-risk documents trigger an email
   alert and get filed for manual review; medium/low-risk documents
   are logged and archived automatically

---

## Architecture

```
┌─────────────┐     ┌──────┐     ┌─────────────┐
│  Local File  │────▶│  n8n │────▶│  PostgreSQL │
│    Inbox     │     │      │     │ (Audit Log) │
└─────────────┘     │      │     └─────────────┘
                     │      │
                     │      │     ┌─────────────┐
                     │      │────▶│   Ollama    │
                     │      │     │ (Local LLM) │
                     └──────┘     └─────────────┘
```

All three services run in Docker on a single bridge network. No
internet connection is required for the document processing itself —
only the initial Ollama model download needs one.

**Stack:**
- **n8n** — workflow orchestration (self-hosted)
- **PostgreSQL 16** — audit logging and idempotency tracking
- **Ollama** (`llama3.1:8b-instruct-q4_K_M`) — local LLM inference
- **JavaScript** — all pipeline logic (n8n Code Nodes)
- **Docker Compose** — full stack, one command to stand up

---

## Why this satisfies POPIA better than a cloud-based alternative

- **Section 72 (cross-border transfer)** — since inference runs
  entirely on local infrastructure, there's no cross-border data
  transfer to justify in the first place.
- **Section 8 (accountability)** — the Postgres audit log is a
  timestamped, queryable record of every document processed, what PII
  categories were found, and how it was classified — direct evidence
  of lawful processing.
- **Data subject access requests** — because the audit log is
  structured and indexed, answering "what have you processed about me"
  is a single SQL query, not a manual re-scan of original files.

Consent and notification requirements (Section 18) are an
organizational responsibility, not something this pipeline generates on
its own — the audit log supports demonstrating compliance with an
existing HR policy, it doesn't replace having one.

---

## Getting started

```bash
git clone <this-repo-url>
cd hr-fortress
cp .env.example .env
# edit .env — set a real Postgres password and generate two secrets:
openssl rand -hex 32   # → N8N_ENCRYPTION_KEY
openssl rand -hex 32   # → N8N_USER_MANAGEMENT_JWT_SECRET

docker compose up -d
docker exec -it hr_fortress_ollama ollama pull llama3.1:8b-instruct-q4_K_M
```

Then open `http://localhost:5678`, build the workflow (see
`docs/build-instructions.md`), and drop a test document into
`hr_module/inbox/`.

---

## Project structure

```
hr-fortress/
├── docker-compose.yml
├── .env.example
├── sql/
│   └── init.sql              # Audit log + idempotency schema
├── hr_module/
│   ├── inbox/                 # Drop documents here
│   ├── archive/
│   │   ├── clean/             # Low/medium risk, processed
│   │   └── flagged/           # High/critical risk, pending review
│   └── logs/
└── docs/
    ├── build-instructions.md  # Full node-by-node n8n build guide
    └── code-walkthrough.md    # Design rationale + debugging notes
```

---

## Known limitations

Being upfront about what this doesn't do yet:

- **PDF support is currently disabled.** n8n's bundled `pdf-parse`
  dependency conflicts with its Code Node task runner in this
  environment; plain-text documents work end-to-end. Migrating
  extraction to n8n's built-in "Extract from File" node is the planned
  fix.
- **No retry/timeout logic** on the Ollama classification call — a
  slow or unavailable model currently fails that run rather than
  retrying.
- **No human-in-the-loop validation** of classification accuracy against
  a labeled dataset.
- **Regex-based PII detection has contextual blind spots** — it can't
  distinguish a real ID number from one quoted as an example in
  training material. A production version would pair this with a local
  NER model as a second detection pass.

---

## Part of a larger portfolio

This is Module 2 of 5 in an AI automation engineering portfolio:

1. **Lead Qualification Pipeline** — event-driven lead scoring with
   GoHighLevel, Claude, and Google Sheets
2. **HR Document Fortress** *(this module)* — local, air-gapped POPIA
   compliance pipeline
3. *(in progress)*
4. *(in progress)*
5. *(in progress)*

Built by Refilwe Mohlala — [LinkedIn](#) *(add your link)*
