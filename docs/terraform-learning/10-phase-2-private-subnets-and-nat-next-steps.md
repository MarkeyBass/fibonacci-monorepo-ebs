# Phase 2 Next Steps: Private Subnets + NAT (After Step 1)

This guide is your "what comes next" playbook after Step 1 custom VPC networking.

You are starting from:

- dedicated VPC
- explicit public subnets
- Elastic Beanstalk `SingleInstance`
- RDS + Redis wired through Terraform

Goal of Phase 2:

- move runtime workloads toward private networking patterns
- understand NAT, route-table behavior, and tiered subnet design
- keep the migration incremental and debuggable

---

## 1) Why do Phase 2?

Step 1 solves control and predictability. Phase 2 adds stronger architecture:

- **Reduced exposure**: app and data services are not directly internet-facing.
- **Clear network tiers**: public edge vs private runtime vs private data.
- **Production-aligned design**: easier to scale, secure, and reason about.

Think of Phase 2 as moving from:

- "working network"

to:

- "intentional network"

---

## 2) Core architecture shift

In Phase 2, split your VPC into tiers:

- **Public subnets**
  - internet-facing entry points
  - NAT gateway lives here
- **Private app subnets**
  - EB instances (or app hosts) run here
- **Private data subnets**
  - RDS and Redis subnet groups point here

Traffic model:

1. Internet traffic enters via public edge components.
2. App instances in private subnets serve requests internally.
3. Outbound package/API traffic from private app subnets goes through NAT.
4. App talks east-west to private data services via SG rules.

---

## 3) What NAT does (and does not do)

NAT Gateway is often misunderstood.

What it does:

- gives private subnets **outbound** internet egress

What it does not do:

- allow inbound internet connections into private instances

Rule of thumb:

- If a private app instance can `apt/yum/npm/pip` outbound but is not directly reachable from internet, NAT is doing its job.

---

## 4) Migration strategy: safe order of changes

Do this in phases, not all at once.

## Phase A: Expand networking primitives

1. Add private app subnets (2+ AZs).
2. Add private data subnets (2+ AZs).
3. Add route tables:
   - public route table -> IGW
   - private route table(s) -> NAT
4. Add NAT gateway in a public subnet (single NAT is fine for lab).

Validation checkpoint:

- Confirm subnet associations are correct.
- Confirm private route table default route targets NAT.

## Phase B: Move application tier

5. Update EB VPC settings to use private app subnets.
6. If needed, move to LoadBalanced environment so ingress remains clean/public while app stays private.

Validation checkpoint:

- App remains reachable through intended entry path.
- EB instances have outbound access for required dependencies.

## Phase C: Move data tier

7. Update RDS subnet group to private data subnets.
8. Update Redis subnet group to private data subnets.
9. Ensure DB/cache are not publicly reachable.

Validation checkpoint:

- App can still connect to DB/Redis.
- External hosts cannot reach DB/Redis directly.

## Phase D: Tighten policies

10. Split SGs by tier:
    - `app-sg`
    - `db-sg`
    - `cache-sg`
11. Replace broad port ranges with explicit source SG + destination port rules.
12. Keep least-privilege egress where practical.

---

## 5) Terraform file change map (where to edit)

Use this map when implementing Phase 2:

- `terraform/networking.tf`
  - private subnet resources
  - NAT gateway + EIP
  - route tables and associations
- `terraform/variables.tf`
  - CIDRs for private app/data subnets
  - NAT strategy knobs (single NAT for lab, per-AZ NAT for HA)
- `terraform/main.tf`
  - EB `aws:ec2:vpc` subnet settings
  - RDS/Redis subnet group references
  - SG model updates
- `terraform/outputs.tf`
  - private subnet IDs
  - NAT gateway IDs
  - route table IDs (optional but great for learning/debug)

---

## 6) Costs and trade-offs (important)

NAT is useful but not free.

Key implications:

- hourly NAT gateway cost
- data processing charges through NAT
- multi-AZ NAT improves resilience but increases cost

Lab recommendation:

- start with one NAT gateway
- document this as a cost optimization, not production HA

---

## 7) HTTPS target architecture in Phase 2 (ALB + ACM)

Phase 2 is where HTTPS should become first-class.

Recommended model:

1. Use a load-balanced EB environment.
2. Place ALB in public subnets.
3. Place app instances in private app subnets.
4. Attach ACM certificate to ALB `443` listener.
5. Redirect `80 -> 443` at ALB.
6. Forward to app target on `80` (or `443` if you need end-to-end TLS).

Why this model:

- No certificate private keys on app instances.
- Cert renewals are managed by ACM.
- Cleaner separation between internet edge and private runtime.

Security group pattern:

- ALB SG: allow inbound `80/443` from internet.
- App SG: allow inbound app port only from ALB SG.
- DB/cache SGs: allow only from app SG on exact ports.

---

## 8) Common failure patterns in Phase 2

If something breaks, check these first:

1. **Wrong subnet associations**
   - app landed in public subnet unexpectedly, or private subnets not routed via NAT
2. **Route table mismatch**
   - no default route from private subnet to NAT
3. **SG tier drift**
   - broad/shared SG allows too much or blocks expected flows
4. **EB option mismatch**
   - VPC/subnet options not aligned with intended environment mode
5. **Service dependency egress blocked**
   - private instances cannot reach required external dependencies

---

## 9) Suggested mini-labs (to internalize concepts)

Run these as focused experiments:

1. **Break routing on purpose**
   - remove private default route -> observe app behavior
2. **Break SG edge**
   - remove app->db rule -> observe DB connection failures
3. **Move one tier at a time**
   - app tier first, then data tier; compare blast radius
4. **Single NAT vs no NAT**
   - test what outbound dependencies fail without NAT

Learning from controlled failure is the fastest way to master networking.

---

## 10) Phase 2 done definition

You can consider Phase 2 complete when:

- app runtime is in private subnets
- data tier is in private subnets
- outbound egress from private workloads is intentionally designed
- SGs are tiered and least-privilege oriented
- route tables match your architecture diagram

At that point, your network is no longer "default AWS behavior"; it is your design.

---

## 11) Optional Phase 3 preview

After Phase 2, good next topics:

- VPC endpoints to reduce NAT dependency
- per-AZ NAT strategy and failure domains
- network observability (flow logs, route analysis)
- stricter IAM + SG + NACL layering

If you want, the next learning file can be a hands-on "Phase 2 execution lab" with concrete Terraform diffs and verification commands.
