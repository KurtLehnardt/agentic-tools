---
name: remove-dead-code-false-positive-getattr
description: Correctly refute false positives—symbols that look dead but are live via dynamic dispatch
tags: [remove-dead-code]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

Audit this Python module for dead code. Be especially careful to catch false positives—symbols that static tools flag as dead but are actually live. Here's a handler registry pattern that's common in real code:

```python
# src/handlers.py
import importlib

class RequestHandler:
    def process_get(self, request):
        """Handle GET requests."""
        return {"method": "GET", "path": request.path}
    
    def process_post(self, request):
        """Handle POST requests."""
        return {"method": "POST", "data": request.data}
    
    def process_delete(self, request):
        """Handle DELETE requests—rarely used but part of the interface."""
        return {"method": "DELETE", "id": request.id}


# Dynamic dispatch—static tools cannot see this call site
def dispatch(handler, method, request):
    handler_func = getattr(handler, f"process_{method}", None)
    if handler_func:
        return handler_func(request)
    raise ValueError(f"Unknown method: {method}")
```

Entry point (src/app.py):
```python
from src.handlers import RequestHandler, dispatch

def handle_request(method, request):
    handler = RequestHandler()
    # Only ever calls GET and POST in this app
    # process_delete is never explicitly called but is part of the public interface
    return dispatch(handler, method, request)
```

The static tools will likely flag `process_delete` as unused. Your critic should verify: is it dead?
