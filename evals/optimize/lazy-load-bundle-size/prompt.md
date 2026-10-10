---
name: optimize-lazy-load-bundle-size
description: Lazy-load heavy components with dynamic imports to reduce initial bundle size
tags: [optimize]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

My Next.js app has a performance issue: all users download a 500KB chart library on page load, even though only admin users ever see the dashboard analytics view. Here's the code:

```typescript
// src/app/dashboard/page.tsx
import { AnalyticsChart } from '@/components/AnalyticsChart'; // 500KB library (Recharts + lodash)
import { DataTable } from '@/components/DataTable';
import { useUser } from '@/lib/auth';

export default function DashboardPage() {
  const { user } = useUser();

  return (
    <div className="dashboard">
      <h1>Dashboard</h1>
      <DataTable />
      {user?.role === 'admin' && (
        <AnalyticsChart data={chartData} />
      )}
    </div>
  );
}
```

The AnalyticsChart component is large and only needed for admin users (about 10% of users). The other 90% are downloading the component code unnecessarily, adding 500KB to the bundle. How would you optimize this?
