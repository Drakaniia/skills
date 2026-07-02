---
name: code-design
description: Use when writing or reviewing functions that are deeply nested, do too many things, have unclear side effects, or are hard to follow linearly. Also when an agent produces code with high cognitive load — nested if-else pyramids, functions mixing validation+business logic+IO, mutable state leaks, or control flow that jumps around. Complements folder-architecture (file/dir level) with function-level design principles.
license: Apache-2.0
compatibility: OpenCode >= 1.0, Claude Code >= 2.0, Codex CLI, Cursor, Gemini CLI
allowed-tools:
  - read
  - grep
  - glob
  - write
  - edit
  - bash
metadata:
  language: language-agnostic
  tags: code-design, code-quality, clean-code, function-design, cognitive-load, single-responsibility, pure-functions, side-effects, guard-clauses
---

# Code Design

Use this skill as a **Code Design Auditor** — enforcing function-level design principles that make code predictable, readable, and maintainable. This skill pairs with `folder-architecture` (file/directory structure) and `audit-codebase` (structural health) to cover the **code quality** dimension those skills don't address.

## Core Principles

### 1. Pure Functions — Predictable by Contract

A pure function:

- Returns the **same output** for the **same input** (referential transparency)
- Has **no side effects** (no mutation of external state, no I/O, no DB, no network)

**Benefit:** Testable without mocks, safe to parallelize, trivial to reason about.

```python
# IMPURE: depends on external state, mutates global
discount_rate = 0.1
def apply_discount(price):
    global discount_rate
    return price * discount_rate

# PURE: output depends only on input, no mutation
def apply_discount(price: float, rate: float) -> float:
    return price * rate
```

**When to violate:** I/O, DB, network, logging — these are inherently impure. The rule is: **push side effects to the edges** (the "imperative shell"), keep the core logic pure.

### 2. Function-Level Single Responsibility

> "A function should have one reason to change." — Robert C. Martin

**Test:** Can you describe what the function does in one sentence without using "and" or "then"? (See the ["And" Test in the reference](references/REFERENCE.md#single-responsibility--the-and-test) for more.)

```python
# BAD: Three responsibilities in one function
def process_order(order):
    # Responsibility 1: Validation
    if not order.get("items"):
        raise ValueError("No items")
    if not order.get("customer"):
        raise ValueError("No customer")

    # Responsibility 2: Business logic
    total = sum(item["price"] * item["qty"] for item in order["items"])
    discount = total * 0.1 if total > 100 else 0
    final = total - discount

    # Responsibility 3: Persistence
    db.save(order)
    email.send(order["customer"], "Order confirmed")

    return final

# GOOD: Each function has one responsibility
def validate_order(order: dict) -> None:
    if not order.get("items"):
        raise ValueError("No items")
    if not order.get("customer"):
        raise ValueError("No customer")

def calculate_total(order: dict) -> float:
    subtotal = sum(item["price"] * item["qty"] for item in order["items"])
    discount = subtotal * 0.1 if subtotal > 100 else 0
    return subtotal - discount

def process_order(order: dict) -> float:
    """Orchestration — coordinates the pure logic, defers side effects."""
    validate_order(order)
    total = calculate_total(order)
    return total

# Side effects handled at the caller level (the imperative shell)
```

### 3. Top-to-Bottom Readability — Linear Control Flow

Code should read like a checklist, not a maze. The happy path should be at the bottom, not buried inside nested braces.

#### Guard Clauses (Fail Fast)

Handle edge cases immediately, then proceed with the happy path unindented:

```python
# BAD: Nested pyramid — happy path buried inside 3 levels of if
def process_user(user):
    if user:
        if user.is_active:
            if user.email:
                return send_email(user.email)
            else:
                return "No email"
        else:
            return "Inactive"
    else:
        return "No user"

# GOOD: Guard clauses — flat, linear, happy path at the bottom
def process_user(user):
    if not user:
        return "No user"
    if not user.is_active:
        return "Inactive"
    if not user.email:
        return "No email"

    return send_email(user.email)  # Happy path — unindented, obvious
```

**Guard clause rules:**

- Check the **invalid/failure case** first (negate the condition)
- Each guard is at the **same indentation level**
- The **happy path runs last**, at the bottom, also at base indent
- Adding a new validation means adding **one more guard** — not restructuring existing code

#### Early Return Pattern

```typescript
// BAD: else-branch nesting
function getUserDisplayName(user: User | null | undefined): string {
  if (user) {
    if (user.firstName) {
      return `${user.firstName} ${user.lastName ?? ""}`.trim();
    } else {
      return user.email;
    }
  } else {
    return "Anonymous";
  }
}

// GOOD: Early returns — flat, each case handled once
function getUserDisplayName(user: User | null | undefined): string {
  if (!user) return "Anonymous";
  if (!user.firstName) return user.email;
  return `${user.firstName} ${user.lastName ?? ""}`.trim();
}
```

### 4. Side Effect Management — The Imperative Shell Pattern

Structure every system as:

```
┌─────────────────────────────────────┐
│  Imperative Shell (side effects)    │
│  - Parse input, call pure logic,    │
│    perform I/O, handle results      │
│  ┌───────────────────────────────┐  │
│  │  Pure Core (no side effects)  │  │
│  │  - Business logic             │  │
│  │  - Calculations               │  │
│  │  - Transformations            │  │
│  │  - Validation                 │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

```python
# BAD: Side effects mixed with logic
def create_user(db, email, name):
    if not email or "@" not in email:
        return {"error": "Invalid email"}  # mixed concern
    user = db.users.insert_one({"email": email, "name": name})  # IO
    send_welcome_email(email)  # side effect
    return {"id": str(user.inserted_id)}

# GOOD: Pure logic separated from side effects
def validate_email(email: str) -> bool:
    return bool(email and "@" in email)

def build_user_doc(email: str, name: str) -> dict:
    return {"email": email, "name": name}

# In the imperative shell (handler/controller):
def create_user_handler(db, email, name):
    if not validate_email(email):
        return {"error": "Invalid email"}
    doc = build_user_doc(email, name)
    result = db.users.insert_one(doc)  # side effect at edge
    send_welcome_email(email)          # side effect at edge
    return {"id": str(result.inserted_id)}
```

### 5. Reduce Cognitive Load — Naming & Variable Management

| Principle                 | Bad                                      | Good                                                                                              |
| ------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------- |
| **Scope-length naming**   | short vars in wide scope                 | short vars in tight scope, descriptive in wide                                                    |
| **Explaining variables**  | `if a > 18 and a < 65 and s == "active"` | `is_working_age = 18 < age < 65; is_active = status == "active"; if is_working_age and is_active` |
| **Write-once variables**  | Reassign same variable 3 times           | Use separate named variables per value                                                            |
| **No magic numbers**      | `if total * 0.1 > 50`                    | `DISCOUNT_THRESHOLD = 500; if total * DISCOUNT_RATE > DISCOUNT_THRESHOLD`                         |
| **Positive conditionals** | `if not user.is_disabled() and not ...`  | `if user.is_enabled() and ...`                                                                    |

## Quick Reference

| Smell                        | Detection                                      | Fix                                          |
| ---------------------------- | ---------------------------------------------- | -------------------------------------------- |
| **Deep nesting (3+ levels)** | Count indentation depth                        | Guard clauses, early returns, extract helper |
| **Mixed responsibilities**   | Function has "and" in its description          | Split into one function per responsibility   |
| **External state read**      | Function reads global/module-level mutable var | Pass as parameter                            |
| **External state write**     | Function modifies param, global, or static     | Return new value instead                     |
| **I/O mixed with logic**     | DB/network/file inside calculation             | Imperative shell pattern                     |
| **Long parameter list (4+)** | Count params at call site                      | Bundle into object/dataclass                 |
| **Magic values**             | Bare numbers/strings in logic                  | Named constants                              |
| **Side effect in name**      | `process_and_save`, `validate_and_notify`      | Split into separate functions                |

## Workflow: Code Design Review Checklist

Before writing every function (or during code review), run through this checklist:

### Step 1: Check Purity

- [ ] Does the function read or write any external state (file, DB, global, network)?
- [ ] If yes — can the side effect be pushed to the caller?
- [ ] If it must stay, is the impure part isolated from the pure logic?

### Step 2: Check Responsibility

- [ ] Can you describe the function in one sentence without "and"?
- [ ] Does the function have distinct sections separated by comments? (That's a split signal)
- [ ] Count the "levels" of abstraction — is it mixing low-level (DB queries) with high-level (business rules)?

### Step 3: Check Control Flow

- [ ] Maximum indentation depth in the function (target: ≤2 levels)
- [ ] Are there guard clauses for all precondition failures?
- [ ] Is the happy path immediately visible (not buried in else)?
- [ ] Can you trace execution from top to bottom without jumping?

### Step 4: Check Side Effects

- [ ] Does the function mutate its input parameters?
- [ ] Does the function modify any variable outside its scope?
- [ ] Does it perform I/O (console, file, network, DB)?
- [ ] Are side effects grouped at the edges (start/end) of the function?

### Step 5: Check Names & Variables

- [ ] Are there magic numbers or strings without named constants?
- [ ] Are any variables reassigned multiple times?
- [ ] Do variable names describe WHAT, not HOW?
- [ ] Is every variable used within a reasonable scope (not 50 lines from declaration)?

## Red Flags — STOP and Refactor

These patterns mean the function needs design work before continuing:

```
"Let me just add one more if statement inside this if block"
    → You're creating nesting. Extract a guard clause.

"I'll handle the edge case in the else branch"
    → Use early return instead.

"I'll just add a parameter for this one extra thing"
    → Your function is accumulating responsibilities.

"I'll write a quick test after the implementation"
    → If it's hard to test, your design is wrong. Fix design first.

"This function is long but it's all related"
    → "Related" != "same responsibility". Find the split points.

"I'll call this function and then do a database save"
    → The function should return data, you save it at the caller.

"It's just one global variable"
    → One global today, five globals next month. Pass it as a parameter.
```

## When This Skill Activates

Activate this skill whenever:

- Writing or reviewing a function that is:
  - > 30 lines long
  - > 2 levels of indentation deep
  - Hard to name (vague verb like `process`, `handle`, `doStuff`)
  - Hard to test (requires mocks for simple logic)
- Refactoring existing code with nesting or mixed concerns
- During code review of any new function
- Before committing code that changes business logic
- When `folder-architecture` warns about an oversized file — this skill decides HOW to split the functions inside

## Interaction with Other Skills

| Skill                             | This skill adds                                                                                                           |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **folder-architecture**           | Handles **file-level** checks (where files go); this handles **function-level** checks (how code is written inside files) |
| **audit-codebase**                | Scans for oversized files (>400 lines); this skill tells you HOW to split the code at function boundaries                 |
| **implement-folder-architecture** | Moves files around; this skill ensures the MOVED code is well-designed before the move                                    |

## Common Mistakes

| Mistake              | Why it happens                              | Fix                                                                        |
| -------------------- | ------------------------------------------- | -------------------------------------------------------------------------- |
| Over-splitting       | "Every function must be tiny!"              | Group closely related steps, use 5-15 line functions as guideline, not law |
| Extreme purity       | "No side effects ever!"                     | Push I/O to edges, don't eliminate it — programs need to do things         |
| Guard clause overuse | 12 guards before the happy path             | The function is doing too much. Split into sub-functions                   |
| Named everything     | `user_age = age; is_adult = user_age >= 18` | Names should add INFORMATION, not rename things                            |

## Language-Specific Notes

While the principles are language-agnostic, here are common traps per language:

| Language          | Common Violation                        | Fix                                                  |
| ----------------- | --------------------------------------- | ---------------------------------------------------- |
| **Python**        | Mutable default args (`def f(x=[])`)    | Use `None` + default factory                         |
| **JavaScript/TS** | Mutating objects passed by reference    | Spread/immutable update patterns                     |
| **Go**            | Pointer receivers that mutate           | Prefer value receivers or return new struct          |
| **Rust**          | Unnecessary `mut`                       | Ownership model already forces purity — lean into it |
| **Java**          | God service classes with injected repos | Split by domain, keep methods focused                |
| **C#**            | `ref`/`out` parameters overused         | Return a result object instead                       |
| **Ruby**          | Monkey-patching + side effects          | Prefer composition over modification                 |

## Verification

After applying code design changes:

- [ ] Every function has a clear single purpose
- [ ] Maximum nesting depth is ≤2 levels
- [ ] Side effects are at the edges (not mixed with logic)
- [ ] Pure functions are testable without mocks
- [ ] The happy path reads top-to-bottom without mental stack-jumping
- [ ] No magic numbers or unexplained values
- [ ] Parameters are stable (3 or fewer, or bundled in a config object)
