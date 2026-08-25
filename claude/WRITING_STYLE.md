# WRITING_STYLE.md

Notes on my writing style, for mimicking it in generic text (blog posts, emails,
docs, longer comments). Based on my Percona community blog posts (2025-2026),
dutow.github.io (2020 C++ posts + newer PostgreSQL series), and my pgsql-hackers
emails. Update as needed.

## Voice, all registers

- Direct and honest. Willing to disagree openly, but always politely and with
  evidence. Answer objections head-on, no flattery, no apology.
- Hedging is scaled to confidence. Speculation gets "seems", "I think",
  "most likely", "my understanding is". Firm conclusions get blunt one-liners:
  "Do not use it in production." "This error is entirely on the client side."
  Never hedge and assert in the same sentence.
- Admit mistakes, uncertainty, and wasted effort freely: "I made some mistakes",
  "I'm not sure if I'll actually use it", "I am not a DBA, so I don't want to
  claim...".
- Explicit anti-dogmatism, often in parentheses: "(I am not saying it has to be
  TOML, it is just the best option I've found so far, but if you have a better
  suggestion, please share!)", "please treat this as a conversation starter".
- Humor is dry, understated, and rare -- ironic juxtaposition or a wry
  parenthetical aside, never jokes for their own sake. Example: "Fortunately for
  our testing, but not so fortunately for production use, keycloak doesn't
  support JWKS caching at all."
- Person usage: "we" for shared technical reasoning and team work, "you" for
  instructions and warnings, "I" for personal narrative, opinions, and
  benchmarks I ran. All three mixed freely in one text.
- Honesty over marketing: mention worst-case numbers, call out what a nice graph
  hides, state simplifications explicitly ("This is again an oversimplification,
  but...").

## Sentence mechanics and punctuation

- One sentence per line in markdown source (semantic line breaks).
- Colon-into-explanation is the signature move: a sentence ends with a colon,
  the explanation continues on the next line, usually lowercase.
  "The reason behind this is quite simple:\nRelation file reads and writes..."
- Comma splices are normal and characteristic: "The caller also checks the
  format, it is redundant." Long sentences chain clauses with commas, not
  semicolons.
- Sentence fragments used as punches: "Probably not worth it." "Except that..."
- Dashes are ASCII: " -- " in blog posts, " - " in emails. Never unicode em dash.
- Parentheses for quick clarifications: "(on every interface)",
  "(relatively simple)".
- Question mark on declaratives as a softener: "This seems to be unnecessary?"
- Slash for alternatives: "hba/ident/hosts", "docker/podman", "tests/examples".
- Trailing ellipsis in open enumerations: "Editors, validators, converters, ..."
- Digits over spelled-out numbers: "the 2 tenants", "3 test scenarios".
- Plain connectives to transition, often sentence-initial: "While",
  "Unfortunately", "But", "Except", "However", "To summarize:".
- Recurring phrases: "I want to note that", "I want to point out",
  "I want to make clear that", "worth considering", "on its own",
  "don't hesitate to".

## Blog posts

- Openings: no throat-clearing. Start mid-thought with context or a dense
  one-sentence abstract, sometimes an imagined voice ("Somebody might tell you,
  'let's configure PostgreSQL 18 with OIDC, it should be simple...'").
  Then state intent explicitly: "In this blog post, I'll...".
- Explicit scoping early: what the post covers, what it skips and why, what is
  deferred to a future post. "I'll leave out the discussion about temporary
  files in this blog post." "out of scope for this already long blog post".
- Headers: short (1-4 words), frequently questions, sometimes colloquial or
  blunt: "Why does it happen?", "Can you keep a secret?", "The catch",
  "That's all!".
- Rhetorical questions as transitions, sometimes self-answered emphatically:
  "Or did we?", "Can we do better?", "...right? Wrong!"
- Anticipate reader objections and answer them, sometimes as a blockquote of
  the hypothetical question.
- Devices used a lot: bulleted lists, comparison tables, numbered scenario
  walkthroughs ("Imagine this: 1. ... 2. ..."), mermaid diagrams, concrete
  numbers as grounding (compile times, GB/s, percentages, port numbers).
- Bold for hard warnings only: "**accidents might mean data corruption**".
- Code blocks get a short contextual sentence ending in a colon, then the block.
  No long preamble.
- Closings: short and unceremonious. Invite feedback/questions, tease future
  posts ("Stay tuned"), link to repo or forums. Older posts sometimes end on
  a single line: "The full example is on github." Never a grand summary
  restating everything.
- "Let's" constructions for moving the reader along: "So let's look into the
  details", "let's say that".

## Mailing list / email (pgsql-hackers style)

- Greeting: "Hello!" / "Hello," / "Hello hackers," when starting a thread or a
  fresh review. No greeting on inline replies.
- No sign-off, ever. End on the last substantive point, a question, or
  footnote links.
- Patch reviews: paste the raw diff hunk, then 1-3 sentences under it, usually
  a question. Terse when trivial: "typo, should be WHERE".
- Criticism softened as question + suggested alternative: "Do we need an
  ExclusiveLock, couldn't this instead use a RowExclusiveLock?" But direct when
  sure, with evidence attached: "I don't think this is the case, we first
  multiply and then cast." + godbolt link.
- Concede gracefully when warranted: "That is certainly an interesting idea...
  On the other hand I worry that...", "I also understand your point, so I
  attached a few examples now".
- Proposal structure: background/motivation first (often referencing conference
  hallway discussions), numbered problem list, alternatives considered and
  rejected with reasons, concrete examples, explicit non-goals, then stacked
  open questions inviting feedback. Footnote-style "[1]:" links at the end.
- Reply inline under "> " quotes, keep attribution lines, work through points
  one by one.

## What NOT to do (AI tells to avoid)

- No unicode punctuation: no em dashes, no curly quotes. ASCII only.
- No "delve", "crucial", "robust", "seamless", "leverage" filler vocabulary.
- No grand intros ("In today's fast-paced world of...") or grand summary
  outros restating the whole text.
- No praise sandwiches in reviews. No "Great question!".
- No perfectly parallel bullet lists where every item is one bolded phrase +
  colon + explanation. My lists are irregular.
- Don't over-polish. My real texts have slightly uneven rhythm, comma splices,
  and casual asides. A text where every sentence is the same length and
  perfectly grammatical reads as AI. (But do not fake typos or grammar errors
  on purpose.)
- Don't inflate confidence. If I measured one setup, say it's one setup.

## Improvements to apply while editing

Things to fix or flag when editing/reviewing my text. These are deliberate
deviations from the observed style -- apply them, but nothing beyond them.

- Proofread pass: fix typos ("tircky", "againts", "convinient") and dropped
  words ("should be able catch it", "But in my initial email specified").
  These are not voice, they cost credibility in posts arguing for rigor.
- Front-load the headline findings in long posts. Per-section "quick summary
  for those only interested in the numbers" already happens -- also put a
  3-bullet "what I found" right after the intro. Agenda should list results,
  not just topics.
- Length apology once per post, in the agenda/intro. Cut repeats like "out of
  scope for this already long blog post" if a length caveat already appeared.
- Simplification caveat once, early: "I simplify throughout, details in future
  posts." Repeat only where acting on the simplified version could hurt the
  reader. Cut the second and third "this is again an oversimplification".
- One reversal per paragraph. When a "However" follows a "But", fold one of
  the clauses into a positive statement.
- Comma splices: keep when both clauses are short and punchy, split into two
  sentences when either clause is long.
- Closings: the strong final line usually already exists a paragraph earlier
  ("let's make PostgreSQL better with our work, not harder to use").
  Promote it to the end, cut trailing pleasantries ("I hope this was useful").
- Reviews: "?" on declaratives only for genuine uncertainty. When sure, state
  it directly with evidence ("I don't think this is the case, we first
  multiply and then cast." + godbolt link).

## Sources

- Percona community blog, authors: zsolt_parragi (content/blog/2025-2026)
- https://dutow.github.io/ (2020 C++ metaprogramming posts, newer OIDC series)
- pgsql-hackers threads via hackorum.dev (TOML config proposal, TDE WAL
  benchmarks, JSON5 proposal, pg_upgrade origin OIDs review, etc.)
