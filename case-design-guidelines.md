# Case Design Guidelines

## Core Principle

The player should not simply find the answer. They should earn the right to understand the answer.

The case should unfold through investigation, conversation, and contradiction. Physical evidence should matter most at the end, but it should not make the solution obvious immediately. The satisfying moment is when the player can connect the object, the testimony, the motive, and the opportunity into one clear accusation.

## Desired Player Experience

The player should feel like a detective moving from uncertainty to confidence.

At the start of a case:

- several suspects should seem plausible
- the physical clues should raise questions, not answer everything
- people should withhold, distort, or understate information
- the player should have reasons to revisit suspects after finding evidence

By the end of a case:

- the correct suspect should feel provable, not guessed
- the key physical evidence should close the case
- witness statements should explain why that evidence matters
- the player should be able to explain the motive, opportunity, and cover-up

## Case Structure

Each case should be designed as a small chain of authored truths.

Recommended structure:

1. Victim
2. Killer
3. Motive
4. Opportunity
5. Key physical evidence
6. Supporting testimony
7. Contradiction or lie
8. Cover-up or misdirection

The answer should not rest on one clue alone. A single clue can point in the right direction, but the player should need at least one conversation reveal or contradiction to feel certain.

## Information Layers

Case information should be divided into layers.

### Public Facts

These are facts available immediately or through basic conversation.

Examples:

- who died
- where the body was found
- who was present
- obvious visible facts about the scene
- broad suspect relationships

Public facts create the mystery but should not solve it.

### Physical Evidence

Physical evidence is reliable. It should be authored by the game and should not lie.

Examples:

- a monogrammed glove
- a broken window latch
- a torn letter
- a stopped clock
- a footprint
- a stain or missing object

Physical evidence should usually do one of three things:

- place someone somewhere
- disprove a story
- reveal that the scene was staged

The key evidence should be necessary for the final accusation, but it should not be fully meaningful until the player has gathered supporting context.

### Conversation-Gated Facts

Some information should only become available through conversation.

Examples:

- a witness saw someone near the room
- a suspect heard an argument
- someone knew about a motive
- someone is reluctant to accuse their employer
- someone changes their story after being confronted

These facts should be unlocked by player behavior, not exposed all at once.

Possible unlock triggers:

- the player has inspected a specific clue
- the player mentions a clue in dialogue
- the player asks about a person, time, place, or object
- another suspect has already revealed a related statement
- the player has reached a later stage of the case

### Contradictions

Contradictions are the heart of the mystery.

A contradiction happens when a statement and a piece of evidence cannot both be true.

Examples:

- a suspect says the window was broken from outside, but the latch damage is on the inside
- a suspect claims they never entered the room, but their glove is found near the body
- one witness gives a timeline that conflicts with another witness
- a suspect says they did not know about the will, but another witness overheard them discussing it

The player should be rewarded for confronting suspects with contradictions.

## LLM Role

The LLM should make conversations feel alive, but it should not define the truth of the case.

The game should author:

- the killer
- the motive
- the clue meanings
- the witness statements
- the reveal conditions
- the final verdict logic

The LLM should provide:

- voice
- personality
- natural phrasing
- emotional reactions
- evasions, denials, and partial admissions

The safest design is to give the LLM only the information it is currently allowed to use. Do not rely only on asking the LLM to hide important truth. If a suspect is not allowed to reveal a fact yet, that fact should not be included in that suspect's active prompt.

## Prompt And Reveal Workflow

Suspect prompts should be assembled from the current game state.

Each suspect can have:

- baseline identity and personality
- facts they always know
- facts they know but should hide
- facts they may reveal only after an unlock condition
- facts already revealed to the player
- topics the player has mentioned

The game should track reveal state separately from the raw conversation transcript.

For example:

```text
fact_id: james_saw_victoria_9pm
known_by: James
truth: James saw Victoria leave the drawing room quickly around 9pm.
unlock_conditions:
- player has asked James about Victoria
- OR player has asked James about 9pm
- OR player has inspected the Silk Glove and asks about it
reveal_style: cautious, reluctant, avoids directly saying "murderer"
```

When Fred talks to James, the game should check which facts are unlocked and include only those facts in the LLM request.

## Topic Tracking

The game should recognize important topics from player dialogue.

Useful topic types:

- suspect names
- clue names
- rooms or locations
- times
- relationships
- motive words, such as will, money, jealousy, inheritance, debt
- action words, such as saw, heard, left, entered, argued, broke, hid

Topic tracking does not need to be perfect. Even simple keyword matching can make the case feel more responsive.

The goal is for suspects to reveal more when the player asks pointed questions instead of when the conversation merely starts.

## Notebook And Case Memory

Conversation reveals should become structured case notes.

The player should not have to scroll through old chat to remember important facts. When a useful statement is revealed, the game should store it as a discovered statement.

Notebook entries can include:

- inspected clues
- suspect statements
- contradictions
- unlocked topics
- accusation requirements

A small notebook is enough. The important part is that the game remembers meaningful discoveries as gameplay state.

## Accusation Requirements

The accusation should feel deliberate.

A good accusation should require:

- choosing the suspect
- choosing the key physical evidence
- explaining the connection
- ideally naming a contradiction, motive, or supporting witness statement

The player should not win by choosing the correct suspect alone. They should win because they can explain why the suspect is guilty.

The final verifier should check for:

- correct suspect
- correct key evidence
- coherent explanation
- motive or opportunity
- no major contradiction with the authored truth

Failure should teach the player what kind of reasoning was missing without dumping the entire solution too early.

## What To Avoid

Avoid cases where:

- the murderer is obvious from the first clue
- suspects reveal decisive facts immediately
- the player can solve the case by exhausting dialogue menus
- clues are collectibles with no reasoning attached
- the LLM invents new case facts
- the LLM knows the whole truth before the game state allows it
- the final accusation accepts a lucky guess
- every clue points at the same suspect with no uncertainty

## Current Prototype Direction

The current prototype already has a basic loop:

- inspect clues
- question suspects
- make an accusation
- verify the suspect, evidence, and explanation

The next design step is to make information unlock more gradually.

The target loop should become:

```text
Inspect clue
-> unlock topic
-> ask suspect about topic
-> reveal statement
-> compare statement against evidence
-> unlock contradiction
-> accuse with suspect + key evidence + explanation
```

This is the version of the game that should feel satisfying: the player is not just collecting facts, but actively turning partial information into proof.
