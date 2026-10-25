import { useState, FormEvent } from 'react';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';

function DeleteAccountCutInHalf() {
  const [email, setEmail] = useState('');
  const [reason, setReason] = useState('');
  const [status, setStatus] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setStatus('sending');

    try {
      await addDoc(collection(db, 'cut_in_half_deletion_requests'), {
        email,
        reason,
        app: 'cut_in_half',
        status: 'pending',
        createdAt: serverTimestamp(),
      });
      setStatus('sent');
      setEmail('');
      setReason('');
    } catch {
      setStatus('error');
    }
  };

  return (
    <div className="page-container">
      <h1 className="page-title">Cut in Half — Delete Account & Data</h1>
      <div className="page-content">
        <p>
          If you signed in to <strong>Cut in Half</strong> with your Google account and would
          like to permanently delete your account and all associated data (including your level
          progress, scores, and profile information), please fill out the form below.
        </p>
        <p>
          Enter the same email address you used to sign in with Google. We will process your
          request and permanently delete your data within 48 hours, and send a confirmation once
          it is complete.
        </p>
        <p>
          <strong>What gets deleted:</strong> your account record, Google profile details stored
          by the Game, level progress, scores, achievements, and game settings. This action is
          permanent and cannot be undone.
        </p>

        {status === 'sent' ? (
          <div className="delete-success">
            <span className="delete-success-icon">✅</span>
            <h3>Request Submitted</h3>
            <p>
              We have received your account deletion request for Cut in Half. You will receive a
              confirmation email once your data has been deleted.
            </p>
          </div>
        ) : (
          <form className="delete-form" onSubmit={handleSubmit}>
            <div className="form-group">
              <label htmlFor="email">Email Address</label>
              <input
                id="email"
                type="email"
                required
                placeholder="Enter the Google email associated with your account"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>

            <div className="form-group">
              <label htmlFor="reason">Reason for Deletion (optional)</label>
              <textarea
                id="reason"
                rows={4}
                placeholder="Let us know why you'd like to delete your account"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
              />
            </div>

            {status === 'error' && (
              <p className="delete-error">
                Something went wrong. Please try again or email us directly at byteberg18@gmail.com.
              </p>
            )}

            <button
              type="submit"
              className="btn btn-danger"
              disabled={status === 'sending'}
            >
              {status === 'sending' ? 'Submitting...' : 'Submit Deletion Request'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}

export default DeleteAccountCutInHalf;
