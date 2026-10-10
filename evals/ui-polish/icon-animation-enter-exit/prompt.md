---
name: ui-polish-icon-animation-enter-exit
description: Apply contextual icon animations with opacity, scale, and blur transitions
tags: [ui-polish]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I have a button that shows different status icons based on whether the action is loading, success, or error. The icon swaps abruptly and it feels jarring. Can you apply ui polish principles to smooth the transitions?

Here's the component:

```tsx
// components/SubmitButton.tsx
import { Loader2, CheckCircle, AlertCircle } from 'lucide-react';

export function SubmitButton({ isLoading, status }) {
  return (
    <button className="px-4 py-2 bg-blue-600 text-white rounded-lg font-medium">
      {isLoading && <Loader2 className="inline w-4 h-4 mr-2 animate-spin" />}
      {status === 'success' && <CheckCircle className="inline w-4 h-4 mr-2" />}
      {status === 'error' && <AlertCircle className="inline w-4 h-4 mr-2" />}
      {isLoading ? 'Submitting...' : 'Submit'}
    </button>
  );
}
```

The status icons appear and disappear instantly. How should I polish this?
