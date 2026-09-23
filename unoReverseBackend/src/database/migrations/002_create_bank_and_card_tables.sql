CREATE TABLE bank_master (
    bank_id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id              INTEGER NOT NULL,
    bank_name            VARCHAR(150) NOT NULL,
    account_type         VARCHAR(30),
    account_last_4       VARCHAR(20),
    balance              NUMERIC(14, 2),
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_bank_master_user
        FOREIGN KEY (user_id)
        REFERENCES user_master (user_id)
        ON DELETE CASCADE
);

CREATE TABLE card_master (
    card_id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id              INTEGER NOT NULL,
    bank_id              INTEGER,
    card_name            VARCHAR(150) NOT NULL,
    card_type            VARCHAR(30),
    card_last_4          VARCHAR(20),
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_card_master_user
        FOREIGN KEY (user_id)
        REFERENCES user_master (user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_card_master_bank
        FOREIGN KEY (bank_id)
        REFERENCES bank_master (bank_id)
        ON DELETE SET NULL
);




CREATE TABLE user_transaction (
    user_transaction_id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id              INTEGER NOT NULL,
    bank_id              INTEGER NOT NULL,
    card_id              INTEGER,
    transaction_type     VARCHAR(20) NOT NULL,
    amount               NUMERIC(14, 2) NOT NULL,
    previous_balance     NUMERIC(14, 2),
    balance_amount       NUMERIC(14, 2),
    purpose              VARCHAR(255),
    notes                TEXT,
    transaction_date     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_user_transaction_user
        FOREIGN KEY (user_id)
        REFERENCES user_master (user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_user_transaction_bank
        FOREIGN KEY (bank_id)
        REFERENCES bank_master (bank_id)
        ON DELETE SET NULL,

    CONSTRAINT fk_user_transaction_card
        FOREIGN KEY (card_id)
        REFERENCES card_master (card_id)
        ON DELETE SET NULL
);