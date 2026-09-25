CREATE TABLE IF NOT EXISTS user_session (
    session_id          UUID PRIMARY KEY,
    user_id             INTEGER NOT NULL,
    token_family_id     UUID NOT NULL,
    platform            VARCHAR(32),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_used_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at          TIMESTAMPTZ NOT NULL,
    revoked_at          TIMESTAMPTZ,
    revocation_reason   VARCHAR(64),

    CONSTRAINT fk_user_session_user
        FOREIGN KEY (user_id)
        REFERENCES user_master (user_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_session_family
    ON user_session (token_family_id);

CREATE TABLE IF NOT EXISTS user_session_refresh (
    refresh_id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    session_id          UUID NOT NULL,
    token_family_id     UUID NOT NULL,
    refresh_token_hash  TEXT NOT NULL UNIQUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    replaced_at         TIMESTAMPTZ,
    expires_at          TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_user_session_refresh_session
        FOREIGN KEY (session_id)
        REFERENCES user_session (session_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_session_refresh_family
    ON user_session_refresh (token_family_id);
