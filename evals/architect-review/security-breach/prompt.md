---
name: architect-review-security-breach
description: Code with CRITICAL security vulnerabilities that must be fixed
tags: [architect-review]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

Review this API code for security issues. I'm concerned we may have left some sensitive data exposed, and there might be injection vulnerabilities. Please audit and fix any critical security problems.

**config.ts:**
```typescript
// Database configuration
export const DB_CONFIG = {
  host: 'db.example.com',
  port: 5432,
  database: 'production_db',
  user: 'postgres',
  password: 'SuperSecretPassword123!',  // CRITICAL: hardcoded password
  ssl: false
};

export const API_KEYS = {
  stripe: 'sk_live_51234567890abcdef',  // CRITICAL: hardcoded API key
  sendgrid: 'SG.aB12cDeFgHiJkLmNoPqRsT'  // CRITICAL: hardcoded API key
};
```

**routes/users.ts:**
```typescript
import express from 'express';
import { pool } from '../db';
import { API_KEYS } from '../config';

const router = express.Router();

// CRITICAL: SQL injection vulnerability - user input directly concatenated
router.get('/search', async (req, res) => {
  const query = req.query.q || '';
  const sql = `SELECT * FROM users WHERE name LIKE '%${query}%'`;
  const result = await pool.query(sql);
  res.json(result.rows);
});

// CRITICAL: SQL injection in email filter
router.post('/find-by-email', async (req, res) => {
  const email = req.body.email;
  const result = await pool.query(
    `SELECT id, name, email, password_hash FROM users WHERE email = '${email}'`
  );
  res.json(result.rows);
});

// HIGH: Exposing internal error details
router.delete('/users/:id', async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM users WHERE id = $1',
      [req.params.id]
    );
    res.json({ deleted: result.rowCount });
  } catch (error) {
    res.status(500).json({
      error: error.message,  // HIGH: Exposes database error details
      stack: error.stack      // HIGH: Exposes stack trace in production
    });
  }
});

export default router;
```

**services/payment.ts:**
```typescript
import Stripe from 'stripe';
import { API_KEYS } from '../config';

const stripe = new Stripe(API_KEYS.stripe);

// HIGH: No input validation on payment amount
export async function createPayment(amount: any, customerId: string) {
  // User could send negative amounts, very large amounts, or non-numeric values
  const charge = await stripe.charges.create({
    amount: amount,  // HIGH: No validation or bounds checking
    currency: 'usd',
    customer: customerId
  });
  
  return charge;
}

// MEDIUM: Unspecified error handling
export async function refund(chargeId: string) {
  try {
    return await stripe.refunds.create({ charge: chargeId });
  } catch (error) {
    // Silent failure - no logging, no user feedback
    return null;
  }
}
```

**middleware/auth.ts:**
```typescript
import express from 'express';
import jwt from 'jsonwebtoken';

const SECRET = 'dev-secret-key';  // HIGH: Hardcoded secret (should be from env)

export function authMiddleware(req: any, res: any, next: any) {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'No token' });
  }

  try {
    const decoded = jwt.verify(token, SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: error.message });
  }
}

// MEDIUM: No rate limiting on login endpoint
export async function login(req: any, res: any) {
  const { email, password } = req.body;
  
  // An attacker could brute force this endpoint
  const user = await findUserByEmail(email);
  
  if (!user || user.password !== hashPassword(password)) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  const token = jwt.sign({ id: user.id, email: user.email }, SECRET);
  res.json({ token });
}
```

Review this code and fix the critical security issues. What needs immediate attention?
