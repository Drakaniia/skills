# Code Design Reference

Condensed cheat sheet for function-level code design principles. Load this reference when you need a quick reminder of the rules during implementation or review.

---

## Purity Rules

```
Pure:   f(x) → y          (same input, same output, no side effects)
Impure: f(x) → y + side effects (I/O, DB, mutate state, network, log)
```

### Quick Purity Test

| Symptom                                  | Impure? | Fix                       |
| ---------------------------------------- | ------- | ------------------------- |
| Reads global/module mutable var          | ✅      | Pass as parameter         |
| Modifies param object                    | ✅      | Return new object         |
| Calls `db.save()`                        | ✅      | Push to caller            |
| Calls `console.log()`, `print()`         | ✅      | Push to caller            |
| Calls `random()`, `uuid()`, `Date.now()` | ✅      | Pass as parameter         |
| Calls another impure function            | ✅      | Memoize or push to caller |
| Arithmetic on parameters only            | ❌      | Keep as-is                |

---

## Single Responsibility — The "And" Test

**Can you describe the function in one sentence without "and" or "then"?**

```
❌ "Validates the input AND calculates the total AND saves to DB"
→ Three responsibilities. Split.

✅ "Validates the order input"
✅ "Calculates the order total"
✅ "Saves the order to the database"
```

### Split Signals

| Signal                                                     | What to do                                                   |
| ---------------------------------------------------------- | ------------------------------------------------------------ |
| Comment section headers (`# ─── Validation ───`)           | Extract each section into its own function                   |
| Mixed abstraction levels (DB + formatting + business rule) | Split by level: orchestration calls domain calls persistence |
| Hard-to-name function (`process`, `handle`, `doStuff`)     | The name is vague because responsibility is unclear          |
| Test needs 5+ mocks                                        | Too many dependencies → too many responsibilities            |

---

## Control Flow — Flat > Nested

### Guard Clause Pattern

```python
# ❌ Nested
def process(x):
    if x:
        if x.valid:
            return do_work(x)
    return None

# ✅ Flat guards
def process(x):
    if not x:
        return None
    if not x.valid:
        return None
    return do_work(x)    # happy path, unindented
```

### Max Nesting Depth Targets

| Depth      | Verdict                        |
| ---------- | ------------------------------ |
| 0-1 levels | ✅ Excellent                   |
| 2 levels   | ⚠️ Acceptable for simple cases |
| 3+ levels  | 🔴 BLOCKER — must refactor     |

### Rules for Guard Clauses

1. Check **inverted** conditions (the failure case first)
2. All guards at **same indentation level**
3. Happy path **last**, also at base indent
4. Adding a new precondition = **one new guard**, no restructuring

---

## Imperative Shell Pattern

```
┌──────────────────────────┐
│  Imperative Shell        │  ← side effects live here
│  • Parse request         │
│  • Call pure logic       │
│  • Perform I/O           │
│  • Return response       │
│  ┌────────────────────┐  │
│  │  Pure Core         │  │  ← no side effects
│  │  • Business rules  │  │
│  │  • Calculations    │  │
│  │  • Transformations │  │
│  │  • Validation      │  │
│  └────────────────────┘  │
└──────────────────────────┘
```

### File Structure Heuristic

```
handlers/          ← imperative shell (controllers, routes, CLI)
services/          ← orchestrators (call pure modules, coordinate I/O)
domain/            ← pure core (business logic, calculations)
db/                ← I/O boundary (repositories, DAOs)
```

---

## Cognitive Load Reduction

| Technique                 | Bad                                                                   | Good                                                                                            |
| ------------------------- | --------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| **Explaining variables**  | `if total > 100 and user.tier == "premium"`                           | `is_eligible = total > 100; is_premium = user.tier == "premium"; if is_eligible and is_premium` |
| **Scope-length naming**   | `user_list_filtered_sorted_paginated` (40-line function) → short fine | Same name in 3-line lambda → too long                                                           |
| **Positive conditionals** | `if not user.is_disabled() and not user.is_banned()`                  | `if user.is_active()`                                                                           |
| **Write-once variables**  | `x = 1; x = x + 2; x = x * 3`                                         | `base = 1; added = base + 2; multiplied = added * 3`                                            |
| **No magic numbers**      | `if count > 86400:`                                                   | `SECONDS_IN_DAY = 86400; if count > SECONDS_IN_DAY:`                                            |

---

## Language-Specific Traps

| Language   | Trap                               | Fix                                       |
| ---------- | ---------------------------------- | ----------------------------------------- |
| **Python** | Mutable default args               | `None` + `if x is None: x = []`           |
| **JS/TS**  | Object/array mutation in functions | `{...obj}`, `[...arr]`, immer             |
| **Go**     | Pointer receiver mutates struct    | Value receiver or return new              |
| **Rust**   | Over-using `mut`                   | Ownership model prefers purity — trust it |
| **Java**   | God service classes                | Split by domain boundary                  |
| **C#**     | `ref`/`out` parameter sprawl       | Return record/result object               |
| **Ruby**   | Monkey-patch side effects          | Composition, not modification             |

---

## Quick Smell → Fix Table

| Smell                           | Fix                                    |
| ------------------------------- | -------------------------------------- |
| 3+ levels of indentation        | Guard clauses, extract helper          |
| Function >30 lines              | Extract one section, re-check          |
| "and" in function description   | Split along the "and"                  |
| Parameter list >3 args          | Bundle into config object              |
| Magic number/string             | Named constant                         |
| Function mutates inputs         | Return new value, don't modify         |
| I/O mixed with calculation      | Separate into shell + core             |
| Hard to test (needs DB mock)    | Extract pure logic, mock only at edges |
| `process()` / `handle()` naming | Rename to describe actual behavior     |
