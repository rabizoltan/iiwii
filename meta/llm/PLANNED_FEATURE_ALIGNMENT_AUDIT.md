\# Planned Feature Industry Alignment Audit



\## Purpose



This audit evaluates a planned (not yet implemented) feature against:



\- Known industry implementations

\- Established design patterns

\- Performance constraints

\- Multiplayer models

\- Sustainability expectations



This is a strategic design comparison.

No code generation.



---



\# When To Use



\- Before building a major system

\- Before rewriting architecture

\- When unsure about direction

\- When inventing a new mechanic

\- Before committing to multiplayer models

\- Before implementing economic systems



---



\# Required Evaluation Structure



\## 1. Planned Feature Summary



LLM must restate clearly:



\- Intended behavior

\- Player experience goal

\- Target scale

\- Interaction model

\- Technical assumptions



If unclear → request clarification.



---



\## 2. Comparable Implementations



List similar features in:



\- RTS

\- City builders

\- Simulation games

\- Multiplayer hybrids

\- MMO-lite systems



For each example:



\- How it works

\- Update model (tick/delta/event-driven)

\- Ownership model

\- Persistence model

\- Known constraints



If unknown → state "Not documented".



---



\## 3. Industry Pattern Extraction



Identify relevant patterns:



\- Fixed tick vs delta time

\- Lockstep vs authoritative server

\- Escrow trade systems

\- Order book vs request board

\- Deterministic seeds

\- Chunk streaming

\- Snapshot reconciliation

\- Economic sinks/sources balance



---



\## 4. Alignment Classification



Classify planned feature as:



\- Industry-aligned

\- Slightly divergent but viable

\- Experimental but promising

\- High-risk divergence

\- Reinventing solved problem



Explain why.



---



\## 5. Sustainability Risk Projection



Evaluate:



\- Performance ceiling

\- Player scaling

\- Economic inflation

\- State explosion

\- Debug complexity

\- Coupling growth

\- Determinism sensitivity



Classify risk horizon:



\- Immediate risk

\- 1-year risk

\- 3-year risk

\- Low risk



---



\## 6. Questions To Clarify Long-Term Vision



Must ask about:



\- Multiplayer future?

\- Mod support?

\- Persistence length?

\- Save size growth?

\- Target hardware?

\- Player count scaling?

\- Competitive vs cooperative?



---



\## 7. Strategic Options



Provide:



\- Minimal viable implementation

\- Industry-aligned safe path

\- Scalable but complex path

\- Experimental path



Include trade-offs.



---



\# Output Classification



End with one of:



\- Strongly aligned

\- Aligned with minor adjustments

\- Viable but risky

\- Not recommended without redesign



---



\# Constraints



\- Do not fabricate internal details of commercial games.

\- Avoid overconfidence.

\- Clearly mark assumptions.

\- No code generation.

