# Domain model

The feature is modelled as **Request-to-Pay (R2P)**. A payee (the creditor) sends the user a request. The user, who is always the payer (the debtor), approves or rejects it. Concepts and lifecycle follow **ISO 20022**, the messaging standard behind instant-payment systems (including the UAE's Aani) and the UAE Open Finance APIs. Dart names stay readable. The ISO element each one maps to is noted below and in the doc comments.

## Types

| Type | Kind | ISO 20022 counterpart |
|---|---|---|
| `PaymentRequest` | Entity: a pending request | `pain.013` creditor payment activation request |
| `Payment` | Entity: a decided request and its outcome | `pain.014` status report plus the transaction status |
| `Party` | Entity: payee | `PartyIdentification` (`Nm`) plus account |
| `User` | Entity: the signed-in customer (the debtor) | `Dbtr` |
| `Account` | Entity: the user's account, debited on approval | `DbtrAcct`, balance type `ITAV` (available) |
| `Iban` | Value object, validated (mod-97) | `IBAN2007Identifier` |
| `Money`, `Currency` | Value objects: integer minor units, ISO 4217 | `ActiveOrHistoricCurrencyAndAmount` |
| `PaymentStatus` | Lifecycle | `ExternalPaymentTransactionStatus1Code` |
| `PaymentSummary` | Derived value: monthly totals | none (read model) |

## Fields

| Field | ISO 20022 | Open Banking JSON | Notes |
|---|---|---|---|
| `id` | resource id | `DomesticPaymentId` | Opaque. Never shown to the user. |
| `reference` | `EndToEndId` | `EndToEndIdentification` | Shown to both parties. Safe to display unmasked. |
| `payee.name` | `Cdtr/Nm` | `CreditorAccount.Name` | One field, max 140 characters. No first/last split. |
| `payee.account` | `CdtrAcct/Id/IBAN` | `CreditorAccount.Identification` | Logged as last four only. |
| `amount` | `InstdAmt Ccy="AED"` | `{"Amount": "1200.00", "Currency": "AED"}` | Integer fils in the app, decimal string on the wire. |
| `note` | `RmtInf/Ustrd` | `RemittanceInformation.Unstructured` | Max 140 characters. |
| `createdAt` / `requestedAt` | `CreDtTm` | `CreationDateTime` | UTC. |
| `expiresAt` | `XpryDt` | `ExpirationDateTime` | Approving after this fails. |
| `decidedAt` | `AccptncDtTm` | `StatusUpdateDateTime` | Orders the lists. Buckets the monthly totals. |

## Lifecycle

```
PaymentRequest (PDNG) ──approve──► processing (ACSP) ──► completed (ACSC)
        │                                   └──────────► failed
        ├──approve, balance too low──► refused with AM04 (InsufficientFunds); stays pending
        ├──reject──► rejected (RJCT)
        └──expiry──► removed from pending; deciding now fails
```

- The payer's **decision** and the **settlement** are kept apart. "Totals only reflect money that actually moved" means only `completed` counts.
- The mock bank settles instantly, so an approval goes straight to `completed`, and the available balance is debited in the same step.

## Where the data lives

The app talks to a JSON API through dio. The API isn't part of the app: in the showcase and in tests, `packages/mock_bank` answers requests from inside a dio interceptor. That interceptor is the only thing that changes when a real server exists.

- **Wire format:** JSON, snake_case, amounts as decimal strings (`{"amount": "1200.00", "currency": "AED"}`), timestamps in ISO 8601 UTC.
- **DTOs** (freezed + json_serializable) live in each feature's `data/dto/`. **Mappers** turn them into domain models and validate on the way in: exact fils, IBAN checksum, known statuses. A malformed item is dropped and logged rather than shown wrong.
- **Repositories** keep an in-memory cache that every screen reads. They refetch after each decision, and poll pending requests and balances every 5 s while signed in.
