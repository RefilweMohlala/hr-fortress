CREATE TABLE IF NOT EXISTS hr_document_audit_log (
    id                         BIGSERIAL PRIMARY KEY,
    document_name              VARCHAR(255) NOT NULL,
    file_path                  TEXT NOT NULL,
    classification              VARCHAR(50) NOT NULL
        CHECK (classification IN (
            'employment_contract', 'id_document', 'payslip',
            'disciplinary_record', 'leave_document', 'general_hr_correspondence'
        )),
    classification_confidence  NUMERIC(3,2),
    pii_categories_detected     TEXT[] NOT NULL DEFAULT '{}',
    pii_instance_count          INTEGER NOT NULL DEFAULT 0,
    risk_score                  VARCHAR(10) NOT NULL
        CHECK (risk_score IN ('low', 'medium', 'high', 'critical')),
    redacted_text_snippet       VARCHAR(500),
    processing_timestamp        TIMESTAMPTZ NOT NULL DEFAULT (now() AT TIME ZONE 'Africa/Johannesburg'),
    triggered_by                 VARCHAR(100) NOT NULL DEFAULT 'system',
    processing_duration_ms       INTEGER,
    created_at                   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_hr_audit_risk_score ON hr_document_audit_log (risk_score);
CREATE INDEX IF NOT EXISTS idx_hr_audit_classification ON hr_document_audit_log (classification);
CREATE INDEX IF NOT EXISTS idx_hr_audit_processing_timestamp ON hr_document_audit_log (processing_timestamp);
CREATE INDEX IF NOT EXISTS idx_hr_audit_document_name ON hr_document_audit_log (document_name);

CREATE TABLE IF NOT EXISTS processed_files (
    id            BIGSERIAL PRIMARY KEY,
    filename      VARCHAR(255) NOT NULL UNIQUE,
    processed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);