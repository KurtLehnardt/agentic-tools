---
name: architect-review-sound-nextjs-app
description: Well-designed Next.js app where the correct answer is finding minimal issues
tags: [architect-review]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

Please perform a full architectural review of this Next.js SaaS dashboard. Look for any architectural issues, performance problems, security gaps, or code quality concerns.

**Project structure:**

```
app/
  layout.tsx
  page.tsx
  dashboard/
    page.tsx
    layout.tsx
  api/
    auth/
      route.ts
    users/
      [id]/
        route.ts
lib/
  auth.ts
  db.ts
  types.ts
components/
  auth/
    LoginForm.tsx
  dashboard/
    UserCard.tsx
  shared/
    ErrorBoundary.tsx
```

**app/layout.tsx:**
```typescript
import type { Metadata } from 'next';
import { Providers } from './providers';

export const metadata: Metadata = {
  title: 'Dashboard',
  description: 'User dashboard'
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
```

**app/page.tsx:**
```typescript
'use client';

import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { useSession } from '@/lib/auth';
import LoginForm from '@/components/auth/LoginForm';

export default function Home() {
  const { session, loading } = useSession();
  const router = useRouter();

  useEffect(() => {
    if (session) {
      router.push('/dashboard');
    }
  }, [session, router]);

  if (loading) {
    return <div>Loading...</div>;
  }

  return session ? null : <LoginForm />;
}
```

**app/dashboard/page.tsx:**
```typescript
import { getSession } from '@/lib/auth';
import { getUsers } from '@/lib/db';
import UserCard from '@/components/dashboard/UserCard';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function DashboardPage() {
  const session = await getSession();
  
  if (!session) {
    throw new Error('Unauthorized');
  }

  const users = await getUsers();

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Dashboard</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {users.map((user) => (
          <UserCard key={user.id} user={user} />
        ))}
      </div>
    </div>
  );
}
```

**app/api/auth/route.ts:**
```typescript
import { NextRequest, NextResponse } from 'next/server';
import { verifyPassword, createSession } from '@/lib/auth';

export async function POST(req: NextRequest) {
  try {
    const { email, password } = await req.json();

    if (!email || !password) {
      return NextResponse.json(
        { error: 'Missing email or password' },
        { status: 400 }
      );
    }

    const valid = await verifyPassword(email, password);
    
    if (!valid) {
      return NextResponse.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      );
    }

    const session = await createSession(email);
    return NextResponse.json({ session }, { status: 200 });
  } catch (error) {
    console.error('Auth error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

**app/api/users/[id]/route.ts:**
```typescript
import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getUserById, updateUser } from '@/lib/db';

async function requireAuth(req: NextRequest) {
  const session = await getSession();
  if (!session) {
    throw new Error('Unauthorized');
  }
  return session;
}

export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    await requireAuth(req);
    const user = await getUserById(params.id);
    
    if (!user) {
      return NextResponse.json({ error: 'Not found' }, { status: 404 });
    }

    return NextResponse.json(user);
  } catch (error) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    );
  }
}

export async function PUT(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const session = await requireAuth(req);
    
    // Ensure user can only update their own profile
    if (session.userId !== params.id) {
      return NextResponse.json(
        { error: 'Forbidden' },
        { status: 403 }
      );
    }

    const data = await req.json();
    const updated = await updateUser(params.id, data);
    
    return NextResponse.json(updated);
  } catch (error) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    );
  }
}
```

**lib/auth.ts:**
```typescript
import { jwtVerify, SignJWT } from 'jose';

const SECRET = new TextEncoder().encode(process.env.JWT_SECRET || 'dev-secret');

export async function verifyPassword(email: string, password: string): Promise<boolean> {
  // In production, use bcrypt to compare hashed password
  // This is a placeholder
  return true;
}

export async function createSession(email: string) {
  const token = await new SignJWT({ email })
    .setProtectedHeader({ alg: 'HS256' })
    .setExpirationTime('24h')
    .sign(SECRET);

  return { token, email };
}

export async function getSession() {
  // In a real app, extract and verify token from request
  return null;
}
```

**lib/db.ts:**
```typescript
import { db } from '@/lib/database-client';

export async function getUsers() {
  return db.query('SELECT id, email, name FROM users ORDER BY created_at DESC');
}

export async function getUserById(id: string) {
  return db.query('SELECT id, email, name FROM users WHERE id = $1', [id]);
}

export async function updateUser(id: string, data: any) {
  return db.query(
    'UPDATE users SET email = $1, name = $2 WHERE id = $3 RETURNING *',
    [data.email, data.name, id]
  );
}
```

**components/dashboard/UserCard.tsx:**
```typescript
import { User } from '@/lib/types';

interface UserCardProps {
  user: User;
}

export default function UserCard({ user }: UserCardProps) {
  return (
    <div className="border rounded-lg p-4 shadow-md hover:shadow-lg transition">
      <h2 className="font-bold text-lg">{user.name}</h2>
      <p className="text-gray-600">{user.email}</p>
    </div>
  );
}
```

Review this codebase for architectural issues. I'm confident in the structure - just want a fresh set of eyes to catch anything I might have missed.
