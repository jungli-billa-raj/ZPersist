> **“If your reader enforces this, it is correct.”**

I will **remove rules that no longer apply**, **add the missing ones**, and **tighten language** where append-only semantics matter.

---

# ✅ TODOS STORE — FILE VALIDITY RULES (v1, append-only log)

This section defines when a file is **valid**, **invalid**, or **must be rejected**.

The file is **untrusted input**.
The reader must assume corruption unless proven otherwise.

The file is a **single append-only log** consisting of:

* a fixed-size header
* a sequence of record entries
* a sequence of string payloads

“Record table” is a **logical concept**, not a physical region.

---

## 1️⃣ Basic file existence rules

### Rule 1.1 — Minimum size

The file **must** be large enough to contain the minimal fixed header.

Let:

```
MIN_HEADER = 32 bytes
```

**Validity condition:**

```
file_size ≥ MIN_HEADER
```

If false → **reject file**.

---

## 2️⃣ Header validity rules

### Rule 2.1 — Magic bytes

The first 4 bytes **must exactly equal** the expected magic.

```
bytes[0..4) == "TDOS"
```

If false → **reject file**.

---

### Rule 2.2 — Version support

The version field **must be recognized** by the reader.

```
version == 1
```

If version is unknown → **reject file**.

No guessing. No fallback.

---

### Rule 2.3 — Header size sanity

Let:

```
header_size = u16 read from header
```

**Validity conditions:**

```
header_size ≥ MIN_HEADER
header_size ≤ file_size
```

If false → **reject file**.

The reader must skip exactly `header_size` bytes before parsing log entries.

---

## 3️⃣ Log structure rules (core change)

### Rule 3.1 — Log start

The append-only log **begins immediately after the header**.

```
log_start = header_size
```

All records and string data live **after** this offset.

---

### Rule 3.2 — Forward-only growth

All data in the log must be laid out in **strictly increasing offsets**.

For every append:

```
new_entry_offset ≥ previous_end_offset
```

Backward pointers are forbidden.

---

## 4️⃣ Record entry rules (logical record table)

Each record entry has a **fixed-size metadata prefix** followed by a string payload elsewhere in the file.

### Rule 4.1 — Record entry size

Let:

```
RECORD_META_SIZE = 16 bytes
```

This is a **format constant**.

---

### Rule 4.2 — Record count consistency

Let:

* `record_count` = value stored in header
* `parsed_records` = number of valid record entries successfully parsed

**Validity condition:**

```
parsed_records == record_count
```

If mismatch → **reject file**.

This prevents trusting corrupted headers.

---

## 5️⃣ Per-record validity rules

These rules apply to **every parsed record entry**.

Each record entry contains:

* `string_offset : u64`
* `string_length : u32`
* `flags : u32`

---

### Rule 5.1 — String offset bounds

```
string_offset ≥ header_size
```

If false → **reject file**.

Strings must live inside the append-only log region.

---

### Rule 5.2 — String length bounds

```
string_offset + string_length ≤ file_size
```

If false → **reject file**.

This is the **most important corruption check**.

---

### Rule 5.3 — Zero-length strings

```
string_length ≥ 0
```

Zero-length strings are **valid**.

---

### Rule 5.4 — No overlap requirement

String payloads:

* **may overlap**
* **may duplicate**
* **may be shared across records**

The format makes **no uniqueness guarantees**.

This enables:

* deduplication later
* repeated todos
* immutable storage

---

## 6️⃣ UTF-8 validity rule (interpretation boundary)

The file stores **bytes**, not text.

UTF-8 is validated **only at read time**.

### Rule 6.1 — UTF-8 handling

* Valid UTF-8 → return string
* Invalid UTF-8 → return error or replacement
* Reader must NOT crash

Invalid UTF-8 **does not invalidate file structure**.

---

## 7️⃣ Flags validity rules

Flags are a 32-bit bitfield.

### Rule 7.1 — Unknown flags

* Unknown bits must be ignored by reader
* Unknown bits must be preserved by writer

This allows forward compatibility.

---

### Rule 7.2 — Deleted records

If `DELETED` flag is set:

* record remains on disk
* string payload remains intact
* reader must exclude it from logical views

Deletion is **semantic only**.

---

## 8️⃣ Append-only integrity rules

### Rule 8.1 — Immutability

Once written:

* record metadata is immutable
* string payloads are immutable

---

### Rule 8.2 — Allowed mutations

Only the following changes are permitted:

* appending new record entries
* appending new string payloads
* updating header fields:

  * `record_count`
  * `file_size`

Any other mutation → **format violation**.

---

## 9️⃣ Crash consistency rules

A reader must assume:

* the last append may be incomplete

### Rule 9.1 — Partial trailing data

If EOF occurs:

* mid-record
* mid-string

The reader must:

* stop parsing
* reject the file **unless** partial data is explicitly allowed (v1: it is not)

This avoids silent truncation bugs.

---

## 🔟 Failure behavior (non-negotiable)

If **any** rule above fails:

> The reader **must reject the file**.

The reader must:

* not partially load
* not guess intent
* not recover implicitly

Silent acceptance is a bug.

---

## 1️⃣1️⃣ Summary invariant (final form)

A file is valid **if and only if**:

```
The header is sane,
The version is known,
Every record is fully parseable,
Every string lies within file bounds,
And the log grows strictly forward.
```

---

## Why this version is stronger

* Growth collisions are impossible
* No region overlap assumptions
* No preallocation requirements
* Crash behavior is well-defined
* Reader logic is linear and defensive

This is **log-structured storage**, done cleanly.


