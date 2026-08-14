# PMB Solutions – Database Schema

Entity relationship diagram for the PMB Solutions pharmacy benefit management database. `CLAIMS` is the central transactional table, linked by foreign key to `MEMBERS`, `DRUGS`, and `PRESCRIBERS`.

```mermaid
erDiagram
    MEMBERS ||--o{ CLAIMS : submits
    DRUGS ||--o{ CLAIMS : appears_in
    PRESCRIBERS ||--o{ CLAIMS : writes

    MEMBERS {
        int member_id PK
        string first_name
        string last_name
        date dob
        string plan_id
        date enrollment_date
    }

    DRUGS {
        int drug_id PK
        string drug_name
        string ndc_code
        string tier
        string manufacturer
        boolean is_generic
    }

    PRESCRIBERS {
        int prescriber_id PK
        string first_name
        string last_name
        string npi_number
        string specialty
    }

    CLAIMS {
        int claim_id PK
        int member_id FK
        int drug_id FK
        int prescriber_id FK
        date fill_date
        int quantity
        int days_supply
        decimal copay_amount
        decimal plan_paid_amount
        string pharmacy_name
    }
```

## Relationships

| Relationship | Cardinality | Description |
|---|---|---|
| Members → Claims | 1 : ∞ | One member can submit many claims |
| Drugs → Claims | 1 : ∞ | One drug can appear on many claims |
| Prescribers → Claims | 1 : ∞ | One prescriber can write many claims |

**Notation:** `PK` = primary key, `FK` = foreign key. `||--o{` indicates a one-to-many relationship (exactly one on the left, zero or more on the right).
