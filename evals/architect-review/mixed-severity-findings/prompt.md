---
name: architect-review-mixed-severity-findings
description: Verify CRITICAL/HIGH are fixed while MEDIUM/LOW are only reported
tags: [architect-review]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

Please perform a full architectural review of this e-commerce API codebase. Look for issues across security, performance, error handling, and code quality. Classify severity levels and let me know what you'll fix vs. report.

**Project structure:**

```
src/
  products/
    router.ts
    service.ts
  orders/
    router.ts
    service.ts
  users/
    router.ts
    middleware.ts
  db/
    connection.ts
    schema.ts
```

**src/products/router.ts:**
```typescript
import express from 'express';
import { getProductsByCategory } from './service';

const router = express.Router();

// Public endpoint - no auth required
router.get('/by-category/:categoryId', async (req, res) => {
  const products = await getProductsByCategory(req.params.categoryId);
  res.json(products);
});

export default router;
```

**src/products/service.ts:**
```typescript
import { query } from '../db/connection';

// CRITICAL: N+1 query pattern
export async function getProductsByCategory(categoryId: string) {
  const categories = await query(
    'SELECT * FROM categories WHERE id = $1',
    [categoryId]
  );
  
  const results = [];
  // This loops over each category and runs a separate query per category
  // Should use JOIN instead
  for (const cat of categories) {
    const products = await query(
      'SELECT * FROM products WHERE category_id = $1',
      [cat.id]
    );
    results.push(...products);
  }
  
  return results;
}
```

**src/orders/router.ts:**
```typescript
import express from 'express';
import { createOrder, deleteOrder } from './service';

const router = express.Router();

// HIGH: No authentication check - admin-only operation exposed
router.delete('/orders/:orderId', async (req, res) => {
  await deleteOrder(req.params.orderId);
  res.json({ success: true });
});

// MEDIUM: Inconsistent naming - "fulfillOrder" vs "createOrder"
router.post('/create', async (req, res) => {
  const order = await createOrder(req.body);
  res.json(order);
});

export default router;
```

**src/orders/service.ts:**
```typescript
import { query } from '../db/connection';

export async function createOrder(data: any) {
  // LOW: Typo in comment - "subbmit" instead of "submit"
  // TODO: subbmit order to payment provider
  return query(
    'INSERT INTO orders (user_id, total) VALUES ($1, $2) RETURNING *',
    [data.userId, data.total]
  );
}

export async function deleteOrder(orderId: string) {
  return query('DELETE FROM orders WHERE id = $1', [orderId]);
}
```

**src/users/router.ts:**
```typescript
import express from 'express';
import { requireAuth } from './middleware';
import { updateProfile } from './service';

const router = express.Router();

router.put('/profile', requireAuth, async (req, res) => {
  const updated = await updateProfile(req.user.id, req.body);
  res.json(updated);
});

export default router;
```

**src/users/middleware.ts:**
```typescript
import { Request, Response, NextFunction } from 'express';

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  // Auth token is validated here
  next();
}
```

**src/db/schema.ts:**
```typescript
export const schema = `
  CREATE TABLE categories (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL
  );
  
  CREATE TABLE products (
    id UUID PRIMARY KEY,
    category_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
  );
  
  CREATE TABLE orders (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  
  CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`;
```

**src/db/connection.ts:**
```typescript
import pg from 'pg';

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL
});

export async function query(text: string, params?: any[]) {
  const result = await pool.query(text, params);
  return result.rows;
}
```

Review this codebase. What's CRITICAL? What's HIGH? What's MEDIUM? What's LOW? Which will you fix? Which will you only report?
