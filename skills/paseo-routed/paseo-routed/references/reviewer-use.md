# When the reviewer runs

The reviewer role is read-only, and every call starts a fresh agent. The orchestrator calls it in the cases below and in no others. This table is the single source: the steps and the acceptance rules point here and do not restate it.

| Case | The reviewer does | Where the method lives |
| --- | --- | --- |
| An implementation commit about to be delivered | Reviews it on two axes, Standards and Spec. The Spec axis covers the diff against the brief and the acceptance checks on the committed head | The review step; [review method](review.md) |
| A brief that fixes literal values, rests on assumptions about real data, or prescribes CLI commands, before it is sent | Acts as the verifier of the pre-flight | [Pre-flight](brief.md#pre-flight) |
| A new or changed skill that performs writes, before a worker runs it | Checks its request headers and required fields against the calling code | [Stop conditions](brief.md#stop-conditions) |
| The same failure a second time, or two retries that did not help | The committee tests the premise the failed attempts share | The retry step |
| The user asks for it, or a conclusion is disputed (the user questions it, or two reports contradict each other) | Acts as the verifier on that one conclusion | This file |

A **verifier** is a fresh agent on the reviewer role. It gets the claims to test, the commands to run and the artifact paths, and the rule to report evidence per claim and change nothing. It may read source. The orchestrator reads its report and the evidence it quotes, and checks that its worktree shows no changes.

Exploration, research and diagnosis reports are not cases. The orchestrator accepts them from the verdict block and the evidence it cites (see [acceptance](acceptance.md)), and reports a conclusion nobody re-ran as the worker's finding.
