import { useState, FormEvent } from 'react';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';

function DeleteAccount() {
  const [email, setEmail] = useState('');
  const [reason, setReason] = useState('');
  const [status, setStatus] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setStatus('sending');

    try {
      await addDoc(collection(db, 'deletion_requests'), {
        email,
        reason,
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
      <h1 className="page-title">Delete Account & Data</h1>
      <div className="page-content">
        <p>
          If you would like to request deletion of your account and all associated data,
          please fill out the form below. We will process your request and get back to you
          within 48 hours.
        </p>

        {status === 'sent' ? (
          <div className="delete-success">
            <span className="delete-success-icon">✅</span>
            <h3>Request Submitted</h3>
            <p>
              We have received your account deletion request. You will receive a
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
                placeholder="Enter the email associated with your account"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>

            <div className="form-group">
              <label htmlFor="reason">Reason for Deletion</label>
              <textarea
                id="reason"
                required
                rows={4}
                placeholder="Please let us know why you'd like to delete your account"
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

export default DeleteAccount;
