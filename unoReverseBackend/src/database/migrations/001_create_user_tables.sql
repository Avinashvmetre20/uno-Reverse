CREATE TABLE user_master (
    user_id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100),
    role                VARCHAR(30) NOT NULL DEFAULT 'user',
    email               VARCHAR(255) NOT NULL,
    mobile_number       VARCHAR(20),
    date_of_birth       DATE,
    gender              VARCHAR(20),
    avatar_url          TEXT,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    is_email_verified   BOOLEAN NOT NULL DEFAULT FALSE,
    is_mobile_verified  BOOLEAN NOT NULL DEFAULT FALSE,
    last_login_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_credentials (
    user_credential_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id               INTEGER NOT NULL,
    login_password        TEXT NOT NULL,
    vault_password        TEXT,
    password_changed_at   TIMESTAMPTZ,
    failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until          TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_user_credentials_user
        FOREIGN KEY (user_id)
        REFERENCES user_master (user_id)
        ON DELETE CASCADE
);
