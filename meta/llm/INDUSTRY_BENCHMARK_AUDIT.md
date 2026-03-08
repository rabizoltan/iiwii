\# Industry Benchmark \& Sustainability Audit



\## Purpose



This document defines a rare-use evaluation mode where the LLM must:



\- Compare the current feature/system against similar known games or applications

\- Identify industry-standard approaches

\- Highlight long-term sustainability risks

\- Provide strategic warnings before technical debt solidifies



This is NOT an implementation mode.

This is a strategic architecture audit mode.



Use sparingly.



---



\# When To Use This



\- Before committing to a core architectural direction

\- When introducing multiplayer, economy, or scaling systems

\- When performance becomes a concern

\- When implementing features known to be complex historically (RTS tick loop, trading markets, async systems, mapgen pipelines)

\- When unsure if the chosen direction is sustainable



---



\# Required Evaluation Structure



The LLM must output:



\## 1. Comparable Systems



List known similar systems from:



\- RTS games

\- City builders

\- Simulation games

\- MMO-lite systems

\- Strategy hybrids



For each comparable example:



\- How it works

\- Tick/update model

\- Multiplayer model

\- Data ownership model

\- Performance characteristics (if known)

\- Known limitations



Examples may include:

\- StarCraft (24Hz fixed step)

\- Factorio (deterministic lockstep)

\- Banished (single-player deterministic sim)

\- Anno series (economic scaling patterns)

\- RimWorld (job assignment patterns)

\- MMO trading systems

\- Steam Inventory patterns



---



\## 2. Industry Patterns Identified



Extract patterns such as:



\- Fixed tick vs delta time

\- Lockstep vs authoritative host

\- Escrow trade systems

\- Order book vs request board markets

\- Chunk-based rendering

\- Deterministic map seeds

\- Two-phase commit in trading

\- Idempotent command queues



---



\## 3. Sustainability Risks



Evaluate:



\- Performance ceiling

\- Multiplayer scalability

\- Economic inflation drift

\- State explosion

\- Coupling growth

\- Debuggability

\- Desync risk

\- Data persistence complexity



Classify risks:

\- Short-term

\- Mid-term

\- Long-term



---



\## 4. Performance Comparison



If relevant, provide rough industry numbers:



\- Typical RTS tick rates

\- Simulation update ranges

\- Player count ceilings

\- Map size ranges

\- Economic throughput patterns



If uncertain → clearly state uncertainty.



---



\## 5. Questions To Clarify Intent



LLM must ask:



\- Is multiplayer planned?

\- Expected max player count?

\- Expected simulation length?

\- Mod support planned?

\- Save size expectations?

\- Performance target hardware?

\- Is determinism mandatory long-term?



---



\## 6. Strategic Recommendations



Provide:



\- Safe direction

\- Risky but scalable direction

\- Overkill direction

\- Minimal viable path



Must not force change.

Must provide tradeoffs.



---



\# Constraints



\- Do not hallucinate unknown numbers.

\- If unsure, say “Unknown / Not documented”.

\- Avoid overgeneralization.

\- Keep output under 800–1200 lines.

\- No code generation in this mode.



---



\# Output Classification



End with:



\- Sustainable as-is

\- Sustainable with adjustments

\- Risky long-term

\- Requires redesign

