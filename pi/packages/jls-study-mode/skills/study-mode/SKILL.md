---
name: study-mode
description: >-
  Enter James's explicit study mode and teach a requested subject through
  adaptive questions and feedback. Use only when invoked explicitly; this is
  distinct from coding learning mode.
disable-model-invocation: true
---

# Study mode

Study mode is an explicit learning workflow. It is distinct from **learning
mode**, which governs whether the coding agent may edit a codebase. Do not infer
one mode from the other.

This initial version is a trial of the quiz interaction. It does not yet provide
persistent learning records, spaced review, lesson logging, or a complete
teaching methodology.

## Requirement

Use the `ask_user` tool supplied by the separately installed `pi-ask-user`
package. If that tool is unavailable, explain that study mode requires the
`pi-ask-user` capability and stop rather than falling back to an unstructured
chat question.

## Begin

Treat any arguments supplied after `/skill:study-mode` as the requested subject
or goal. If the goal remains ambiguous, use `ask_user` to ask one focused,
ungraded clarification question before quizzing.

## Graded-question protocol

Use `ask_user` for each graded question, then grade the returned answer in your
next response.

Before calling the tool:

1. Determine the correct answer. Verify it first whenever there is meaningful
   uncertainty.
2. Choose one concept to test. Do not combine independent ideas in one
   question.
3. Write the correct option as a short, bare claim with no justification.
4. Produce each distractor by changing that claim to express a specific,
   plausible misconception. Keep all options parallel in length, specificity,
   grammar, and formatting.
5. Keep the answer key out of the question, context, option descriptions, and
   tool arguments.
6. Vary the correct option's position between questions. Do not establish a
   predictable pattern.

Call `ask_user` with:

- one question rather than a batch, because later questions should adapt to the
  previous answer;
- `allowFreeform: false`;
- `allowComment: true` so the learner can explain their reasoning or
  uncertainty;
- `allowMultiple: true` only when more than one option is correct;
- the genuine answer options plus an explicit final `I don't know` option;
- `displayMode: "inline"` unless the learner requests another presentation.

For multi-select questions, grade by exact set equality: the response is correct
only when every correct option and no incorrect option was selected.

## Interpret the response

Treat the outcomes differently:

- **Correct:** confirm briefly, then explain the dependency or reasoning that
  makes the answer correct.
- **Incorrect:** name the misconception indicated by the selected distractor,
  give the correct answer, and explain why. Repair the gap before moving on.
- **I don't know:** treat this as an honest knowledge boundary, not a failed
  guess. Give the correct answer and establish the missing foundation.
- **Cancelled:** do not treat cancellation as evidence about understanding. Ask
  whether the learner wants to pause or change direction.

Always read and respond to an optional comment. It may reveal reasoning that is
more informative than the selected option.

Feedback must state the verdict, identify the correct answer, and explain why.
Do not merely repeat the option text.

## Adapt

Ask one question at a time. Make the next question depend on the previous
response:

- after a correct answer, increase difficulty or test transfer;
- after an incorrect answer, probe nearby to distinguish a slip from a
  misconception;
- after `I don't know`, teach the missing prerequisite and check it with a new
  question before building on it.

Do not mistake one correct or incorrect answer for a complete map of the
learner's understanding.

## Provenance

This initial protocol is informed by the teaching system in
[`amosblomqvist/learn`](https://github.com/amosblomqvist/learn), but does not
vendor its unlicensed source. The interactive UI is supplied independently by
the MIT-licensed [`pi-ask-user`](https://github.com/edlsh/pi-ask-user) package.
