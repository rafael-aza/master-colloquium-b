# Speaker Notes — IaC vs Manual AWS Provisioning
### Master Colloquium B · 15-minute presentation · Rafael Aza

**Total budget: 15 minutes.** Aim for ~1 minute per slide. Times below are cumulative targets — glance at a clock at the checkpoints (⏱).

---

### Slide 1 — Title *(0:00–0:30)*
- Greet the room. "Good morning — my project compares two ways of building cloud infrastructure: doing it by hand versus writing it as code."
- One sentence on why you picked it: it's a real, practical DevOps question.

### Slide 2 — Agenda *(0:30–1:00)*
- Walk the six points quickly.
- Set expectation: "Today I focus on the context, design, and outlook — the full measured results come in the report after your feedback."

### Slide 3 — Context: IaC vs Click-Ops *(1:00–2:30)*
- Define **Click-Ops**: clicking through the AWS console for every resource.
- Define **IaC**: the same infrastructure written as version-controlled code, provisioned with one command.
- Name-drop **Terraform** as the industry standard. Keep it plain — assume the professor knows, but frame it for anyone who doesn't.

### Slide 4 — Why it matters + resources *(2:30–3:30)*
- The three pains: doesn't scale, environments drift, no audit trail.
- Motivation: "I wanted to *measure* the difference, not just repeat vendor claims."
- Briefly list resources: AWS, Terraform, WSL2, credits, GitHub.

### Slide 5 — Problem & Research Question *(3:30–5:00)* ⏱ *~1/3 done*
- State the problem: provisioning a realistic multi-tier stack by hand is slow, inconsistent, hard to reproduce.
- **Read the research question aloud, slowly.** This is the anchor of the whole talk.
- Emphasize the two measurable dimensions: speed and consistency.

### Slide 6 — Requirements & criteria *(5:00–6:30)*
- Describe the target system in one breath: production-shaped, 2 AZs, least-privilege, real app, torn down after.
- Walk the criteria table — this is where you show rigor. Each criterion has a concrete measurement method. Linger here.

### Slide 7 — Architecture *(6:30–8:00)*
- Talk through the diagram top to bottom: Internet → Load Balancer → auto-scaling app servers → Multi-AZ database.
- Stress it spans **two Availability Zones** for fault tolerance.
- "This is deliberately realistic — not a toy — so the comparison means something."

### Slide 8 — Design highlights *(8:00–9:00)*
- Hit the four tiers briefly, then the **security chain**: traffic only flows Internet → ALB → EC2 → RDS, nothing else reaches the database.
- The payload: a small app that actually queries the DB, proving the whole chain works end to end.

### Slide 9 — Terraform approach + testing *(9:00–10:00)*
- Four reusable modules; one command builds everything in dependency order.
- **Testing is a differentiator**: validate + 14 automated plan-based tests + app unit tests — all before touching the cloud. "The infrastructure is tested like software."

### Slide 10 — Methodology *(10:00–11:00)* ⏱ *~2/3 done*
- Three steps: manual run (stopwatch + log errors), Terraform run (timed apply + drift check), compare.
- Note the cost discipline: both environments destroyed the same day.

### Slide 11 — Preliminary results *(11:00–12:30)*
- Be honest: this is the **Phase-1 pilot** (a simplified stack) used to validate the method.
- The headline: **~3.8× faster** even at small scale (1h17 vs 20 min).
- "I expect the full 3-tier experiment to widen this gap, because manual complexity grows faster than code complexity."

### Slide 12 — Status / what's next *(12:30–13:00)*
- The full code and app are **written, tested, version-controlled** — ready to deploy.
- What remains: run the full 3-tier experiment and capture the numbers for the report.

### Slide 13 — Outlook *(13:00–14:00)*
- Pick 2–3 to actually say aloud (don't read all): CI/CD, remote state for teams, policy-as-code, cost analysis.
- Frame these as natural extensions of the same idea.

### Slide 14 — Summary *(14:00–14:30)*
- Four crisp takeaways. This is the sentence they'll remember — deliver it with energy.

### Slide 15 — Thank you / Q&A *(14:30–15:00)*
- "Thank you — I'd welcome your feedback, which I'll use to shape the final experiment and report."
- Invite questions. This is the point of the mid-project talk.

---

## Delivery tips
- **Rehearse twice** with a timer; the danger zones for overrun are slides 6, 7, and 11.
- If running long, compress slide 8 and slide 13 — they're the most cuttable.
- Have the architecture slide (7) and the results slide (11) rock-solid; those are what a supervisor probes.
- Keep answers short in Q&A; it's fine to say "that's exactly what the next phase measures."
