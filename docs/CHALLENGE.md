# Mobile Technical Challenge: Payment approval flow

Source: `mobile-technical-challenge.pdf` (Flutter dev position, Mamo).

## Brief

- The scope is deliberately small: a handful of screens. Build it as a **real feature shipping in a production app**, not a demo.
- Put the effort into quality: **architecture, edge cases, careful data handling**.
- Colors, icons and copy in the wireframes are **placeholders**. Build to a real production quality bar, not to the wireframe's look.
- **No data model is provided.** Designing it well and handling it carefully is part of the exercise.
- The acceptance criteria are **the floor, not the ceiling**. Use your judgment to go beyond them.
- **Handover matters.** Treat the reviewer like a client who wants to try it as quickly as possible. They **shouldn't need to compile or run the project** to experience it. Still provide the source code.

## Screens (wireframes)

1. **Home**: bottom nav (Home | Payments).
   - "THIS MONTH" card: TOTAL `AED 1,540`, PAYMENTS `2`.
   - "RECENT" list: rows with name, status pill and amount, e.g. `Ahmed K. [APPROVED] AED 1,200.00 ›`.
   - Dashed "+" FAB.
2. **Approval**: a bottom sheet over the current screen.
   - Title "Approve this payment?"
   - `To: A•••• K.`, `Amount: AED ••,•••.••`, `Ref: PAY-88213`
   - Hint: "Full amount & recipient reveal only after device auth succeeds"
   - Buttons: Reject | Approve
3. **Payments**: the full list, e.g. Ahmed K. APPROVED 1,200.00; Sara M. APPROVED 340.00; Leo D. REJECTED 900.00 (the rejected row is visually muted). FAB.
4. **Payment details**: back chevron, "Payment details".
   - Name + status pill, large amount `AED 1,200.00`.
   - Rows: Date `Sep 10, 2026`, Reference `PAY-88213`, Note `Design retainer`.
   - **No bottom nav** is shown, but the FAB is still visible.

## Acceptance criteria

### Home
- [ ] See a summary of payment activity for the **current month**.
- [ ] See recent payments.
- [ ] Tap any payment to see its full details.
- [ ] **Rejected payments don't count** toward the summary. Totals reflect only money that actually moved.

### Payments list
- [ ] See all payments, **most recent first**.
- [ ] Each row shows the counterparty, amount and status (approved/rejected).
- [ ] Tap any payment to see its full details.
- [ ] A payment just approved or rejected **appears at the top right away**.

### Payment details
- [ ] Details can only be opened for a **decided** payment, never a pending one.
- [ ] Back returns to **wherever it was opened from**.

### Debug FAB
- [ ] Visible on **every screen**.
- [ ] Draggable anywhere, and **stays where placed for the rest of the session**.
- [ ] Tapping it creates a **new incoming payment request** to review.

### Approval
- [ ] The confirmation appears **over whatever I was doing**, not as a new screen.
- [ ] Amount and counterparty name are **partially hidden**. Only the reference number is shown in full.
- [ ] Can approve or reject.
- [ ] **Approve**: navigates to the Payments list, where the payment now appears.
- [ ] **Reject**: returns to wherever the user was before the request appeared.
- [ ] Either way, the updated state shows **everywhere** the payment appears: the list, the Home summary and the details.
