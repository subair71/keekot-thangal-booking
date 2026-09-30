import {DocumentReference, Firestore, Transaction} from 'firebase-admin/firestore';
import {DomainError} from './domain.js';

// A dedicated counter survives cancellations, slot edits and hold cleanup.
// Read every document before the caller performs any transaction writes.
export async function readTokenSequence(db: Firestore, tx: Transaction, slotId: string) {
  const counter = db.doc(`slotTokenCounters/${slotId}`);
  const current = await tx.get(counter);
  const assignments: {ref: DocumentReference; tokenStart: number; tokenEnd: number}[] = [];
  if (current.exists) {
    const nextToken = current.data()!.nextToken;
    if (!Number.isSafeInteger(nextToken) || nextToken < 1) throw new DomainError('failed-precondition', 'Token sequence needs administrator review.');
    return {counter, nextToken, assignments};
  }
  // Existing bookings are assigned in their original confirmation order, including
  // cancelled bookings, so a cancellation never moves another visitor's place.
  const existing = await tx.get(db.collection('bookings').where('slotId', '==', slotId));
  const ordered = [...existing.docs].sort((a, b) => {
    const x = a.data().createdAt, y = b.data().createdAt;
    return (x?.seconds ?? 0) - (y?.seconds ?? 0) ||
      (x?.nanoseconds ?? 0) - (y?.nanoseconds ?? 0) || a.id.localeCompare(b.id);
  });
  let nextToken = 1;
  for (const booking of ordered) {
    const b = booking.data();
    if (!Number.isSafeInteger(b.visitorCount) || b.visitorCount < 1) throw new DomainError('failed-precondition', 'Visitor count needs administrator review.');
    if (b.tokenStart != null || b.tokenEnd != null) {
      // Never silently renumber an issued pass if a counter was removed.
      if (b.tokenStart !== nextToken || b.tokenEnd !== nextToken + b.visitorCount - 1) throw new DomainError('failed-precondition', 'Token sequence needs administrator review.');
    } else {
      assignments.push({ref: booking.ref, tokenStart: nextToken, tokenEnd: nextToken + b.visitorCount - 1});
    }
    nextToken += b.visitorCount;
  }
  return {counter, nextToken, assignments};
}

export function writeLegacyTokens(tx: Transaction, assignments: {ref: DocumentReference; tokenStart: number; tokenEnd: number}[]) {
  for (const {ref, tokenStart, tokenEnd} of assignments) tx.update(ref, {tokenStart, tokenEnd});
}
