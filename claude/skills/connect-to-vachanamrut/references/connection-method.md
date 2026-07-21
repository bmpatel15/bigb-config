# The connection method

How to get from an ordinary thought to a defensible Vachanamrut reference — and how to know
when to stop short of one.

## 1. The concept profile

Build this **before** searching anything. Matching keywords first is how weak connections get
made: the vocabulary of a modern thought rarely overlaps the vocabulary of a discourse, and
where it does overlap it often means something else.

Work out:

| Field | Question |
|---|---|
| Primary principle | What is this thought actually about, in one clause? |
| Secondary principle | What else is in play underneath it? |
| Human struggle | What difficulty is being described or avoided? |
| Spiritual assumption | What does it take for granted about how life works? |
| Desired response | What change or posture does it point toward? |
| Vachanamrut terminology | Which satsang terms name this? |
| Possible misconception | How could this be misread from the Vachanamrut's view? |
| Vault synonyms | What words would the user's own notes use? |

Categories worth testing the thought against: conviction · ego · attachment · obedience ·
perception · effort · grace · identity · faith · discipline · association · desire ·
service · humility · surrender · discernment.

**Do not print the whole profile.** One distilled sentence becomes `## Core Principle`.

### Worked example

> "Sometimes I become discouraged when seva does not go according to my plan."

- Primary: attachment to personal preference disguised as commitment to the work
- Secondary: the ego's claim to authorship of seva
- Struggle: disappointment curdling into irritation when overruled
- Assumption: that the value of seva is tied to its going *my* way
- Response: dasbhav — serving as the servant, not the author
- Terms: swabhav, dasbhav, mahima, sarva karta, nishtha
- Misconception: that discouragement proves the seva was wrong
- Synonyms: preference, plan, control, disappointment, letting go

Notice how little of this is in the original wording. That is the point.

## 2. Searching

Vault first, always — `vach_lookup.py --variants` gives every spelling to grep for. Then the
index:

```bash
python3 scripts/vach_lookup.py --search "<thought or profile terms>"
```

The scorer reads **titles only**, across 274 rows. It bridges everyday vocabulary to
discourse vocabulary (`control` → karta, doer, maya; `consistency` → resoluteness,
persistence, niyams), and it is deliberately aggressive about stopwords, because a hit on
"cannot" or "become" is noise, and noise at the top of a candidate list is exactly the weak
connection this skill exists to refuse.

Search the profile's terms, not just the raw sentence. A thought about losing peace when
plans fail should also be searched as *preference*, *adverse circumstances*, *hardship*,
*doer*.

## 3. Ranking

At most three candidates: strongest, supporting, possible secondary. **Only as many as
genuinely fit** — presenting three to look thorough is itself a failure. Judge each on:

- **Conceptual fit** — same principle, or merely adjacent?
- **Directness** — does the discourse teach this, or does the reading depend on a chain of
  inference?
- **Evidence** — what can you actually point to: a vault note, fetched text, or a title?
- **Interpretation load** — how much of the connection is yours rather than the text's?
- **Word-only risk** — would this match survive if the shared word were removed?

### Confidence

| Label | Means |
|---|---|
| **High** | Read the teaching in a vault note or fetched text, and it addresses this directly. |
| **Moderate** | The theme is right and the title supports it, but the text is unread, or the application is a step removed. |
| **Tentative** | Plausible thematic link only. Say what would confirm or kill it. |

Confidence describes **evidence**, not enthusiasm. A connection you find compelling but
cannot check is Moderate at best.

### The false-friend problem

`Loya-14` is titled **Personal Preferences**. For the seva thought above it looks perfect.
It is not: the discourse is about which āchārya's doctrinal positions Maharaj favours. A
title-only matcher would have mis-cited it with confidence.

This is why `verified` requires reading the text, and why every unread candidate is labelled
*verification required*. When you cannot check, say what you would check.

## 4. Relationship types

Naming the relationship keeps a connection honest — much of the time the thought is not the
teaching, it is a consequence, an application, or a failure to live it.

| Type | Use when |
|---|---|
| `direct-teaching` | The discourse teaches this principle explicitly. |
| `practical-application` | The principle applied to a situation the discourse does not discuss. |
| `modern-expression` | The same insight in contemporary language. |
| `supporting-analogy` | The thought illustrates the teaching without being it. |
| `partial-alignment` | Agrees in part; diverges in its assumptions. |
| `corrective` | The Vachanamrut corrects the thought. |
| `tension-requiring-qualification` | Both hold something true; the tension needs naming. |
| `shared-struggle` | Same human difficulty, different remedy. |
| `consequence-of-the-teaching` | Follows from the principle rather than stating it. |
| `failing-to-live-the-teaching` | Describes the lapse the teaching addresses. |

Use the kebab-case form in frontmatter; write it naturally in prose.

## 5. When to stop

Stop at `unresolved` when the principle is clear but no discourse can be responsibly named,
when every candidate rests on a shared word, or when the thought is too vague to have a
specific teaching.

> I found a strong thematic relationship to Maharaj's teachings on sarva karta, but I could
> not responsibly identify a specific discourse from the available vault material.

That is a **successful** run. State the principle, name the terrain, offer to research it in
a terminal where the fetch works, and stop. Never round a Tentative up to Moderate because
the answer feels unsatisfying.

## 6. Grep is a hint, not a verdict

The index titles are **editorial labels added by compilers**, not phrases lifted from the
discourse. So a failed search inside the text proves very little.

`Gadhada I-55` is titled *Resoluteness in Worship, Remembrance and Observance of Religious
Vows*. Grepping the fetched text for `resolute` returns **nothing** — because the translation
says *resolve*. The discourse is squarely on the theme: Muktanand Swami asks why a person
cannot maintain a steady resolve, and Maharaj answers with the four factors of desh, kaal,
kriya and sang, and three levels of resolve.

Rule: a failed `--grep` sends you to read the text, never to reject the candidate. Only
conclude a theme is absent after reading. And note what that discourse actually claims — it
explains why steadiness *fails*, which is adjacent to "consistency beats intensity" without
being the same assertion. Report the adjacency rather than collapsing it.
