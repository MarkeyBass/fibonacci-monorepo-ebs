# Networking Concepts You Need for AWS + Terraform

This is your deep, practical networking guide for both:

- Understanding this Terraform project
- Building AWS infrastructure confidently in general

This is not a glossary dump. It is a set of mental models + practical "what to check" patterns.

---

## 1) The core mental model: "Where can packets go?"

Every networking question in cloud can be reduced to:

1. **Name resolution**: does the client resolve a hostname/IP?
2. **Route decision**: is there a path to target subnet/network?
3. **Policy gate**: do security controls allow this source/destination/port/protocol?
4. **Service readiness**: is app/service actually listening?

When something "cannot connect", one of these four is usually broken.

In AWS, these layers map roughly to:

- DNS -> Route 53 / private DNS behavior / service endpoints
- Routing -> VPC route tables, IGW, NAT, VPC peering/TGW
- Policy -> Security Groups, NACLs, IAM (sometimes), service-specific auth
- Service -> EC2 process, RDS status, Redis health, container readiness

---

## 2) CIDR and subnetting (your "address geometry")

### CIDR basics

Example: `10.0.0.0/16`

- `/16` means first 16 bits are network prefix.
- Bigger prefix number = smaller address space (`/24` smaller than `/16`).

Why you care:

- You cannot scale or peer cleanly if your CIDRs overlap.
- Subnet sizing mistakes show up later during expansion.

Practical defaults:

- VPC often `/16`.
- Subnets often `/24` or `/20` depending expected scale.

Terraform pattern:

- Use `cidrsubnet()` to carve deterministic subnet ranges from a parent CIDR.

---

## 3) VPC as "network boundary"

Think of a VPC as your isolated L3 network in AWS.

It provides:

- Address space (CIDR)
- Subnets (per-AZ slices)
- Route tables
- Security boundaries (SG + NACL context)

In this project:

- You use default VPC via `data.aws_vpc.default`.
- That is speed-friendly for learning, less ideal for production control.

Production habit:

- Prefer dedicated VPCs with explicit CIDR, subnet tiers, and route architecture.

---

## 4) Subnets: public vs private (and why names can mislead)

A subnet becomes effectively "public" when:

- It has a route to an Internet Gateway (IGW), and
- Instances can have public IPs / reachable entry path.

A subnet is "private" when:

- No direct IGW route for workloads, usually egress via NAT.

Important:

- "Public/private" is a behavior from routing + IP assignment, not a magical subnet flag.

For managed services:

- RDS/ElastiCache subnet groups define placement options.
- A DB may still be non-public even if subnet could route outward, depending service settings and SG.

---

## 5) Route tables and next hops (the network's decision tree)

Route table says:

- "For destination X, forward to Y."

Common next hops:

- `local` (within VPC CIDR)
- Internet Gateway (IGW)
- NAT Gateway
- VPC Peering / Transit Gateway attachment
- Gateway endpoints (S3/DynamoDB)

Troubleshooting trick:

- If SG looks correct but traffic still dies, inspect route tables next.

---

## 6) Internet Gateway vs NAT Gateway

### IGW

- Enables public internet ingress/egress for resources with public addressing.

### NAT Gateway

- Gives private subnets outbound internet access without inbound exposure.

Classic production layout:

- Public subnets: ALB + NAT Gateways
- Private app subnets: ECS/EKS/EC2 apps
- Private data subnets: RDS/Redis

Cost note:

- NAT Gateway is easy but not cheap; architecture should account for this.

---

## 7) Security Groups (stateful allow-lists)

Security Groups are stateful virtual firewalls attached to ENIs/resources.

Key behavior:

- You specify **allow** rules.
- Return traffic for allowed flows is automatically permitted (stateful).
- No explicit deny rules.

In your project:

- One shared SG is attached to EB, RDS, and Redis.
- `self = true` ingress allows members of that SG to reach each other.
- Wide `5432-6379` range is quick for labs, coarse for production.

Production habit:

- Separate SGs by tier: `app-sg`, `db-sg`, `cache-sg`.
- Allow exact source SG + exact destination port.

---

## 8) NACLs (stateless subnet filters)

Network ACLs apply at subnet boundary.

Key behavior:

- Stateless: return traffic must be explicitly allowed.
- Ordered rules with allow/deny.
- Less commonly tuned first in app teams; SGs usually carry most policy logic.

When they matter:

- Additional segmentation, compliance controls, coarse blast-radius boundaries.

---

## 9) Stateful vs stateless: do not mix them mentally

If you forget this distinction, debugging gets painful.

- SG (stateful): allow outbound request implies return path allowed.
- NACL (stateless): must allow both directions explicitly.

Symptom pattern:

- Connection starts then stalls/timeouts -> often NACL ephemeral port rules wrong.

---

## 10) Ports and protocols: map app architecture to traffic

From this stack:

- Postgres: TCP `5432`
- Redis: TCP `6379`
- Web app ingress often HTTP/HTTPS (`80/443`) via EB/ALB depending architecture

Practice:

- Write a tiny "traffic matrix" for any environment:
  - source tier
  - destination tier
  - protocol/port
  - why needed

Then encode only those flows in SG rules.

---

## 11) DNS in VPC: private names are part of networking

Connectivity is not only IP routes. Name resolution often decides whether apps can connect.

In AWS:

- VPC provides internal DNS resolver behavior.
- Managed services (RDS, ElastiCache) expose DNS endpoints that can change underlying IPs.

Guideline:

- Always connect to managed service DNS endpoints, not hard-coded IPs.

Your Terraform already follows this:

- EB env vars use RDS/Redis endpoint attributes.

---

## 12) Load balancers and entry points (north-south traffic)

For internet-facing apps, entry usually should be:

- Route 53 -> ALB/NLB -> app tier

Why:

- Health checks, TLS termination, scaling integration, stable endpoint model.

Single-instance learning setups may shortcut this, but production rarely should.

---

## 13) East-west traffic (service-to-service inside VPC)

Inside your network, app -> DB/cache calls are east-west flows.

Design goals:

- Tight source identity (SG referencing SG)
- Minimal allowed ports
- Clear subnet tier boundaries

This is where over-broad "just make it work" SG rules usually accumulate technical debt.

---

## 14) Publicly accessible databases: what it really means

`publicly_accessible = true` on RDS means AWS can assign public reachability characteristics.

But final reachability still depends on:

- Subnet routing
- SG/NACL rules
- Credentials/auth

Production default:

- Keep data services non-public.
- Reach them from private app tier or through controlled bastion/SSM paths.

---

## 15) Encryption in transit/at rest: networking and data intersect

Networking security is not just "can connect".

For data services:

- In-transit encryption (TLS) protects bytes over the wire.
- At-rest encryption protects storage media.

Your stack:

- Redis transit encryption enabled (`preferred` mode).
- Redis at-rest encryption disabled (lab trade-off).

Production trend:

- Enable both whenever possible.

---

## 16) Multi-AZ and failure domains

Subnets are AZ-scoped. High availability requires thinking in AZ distribution.

Patterns:

- App tier spread across AZs.
- NAT/ALB considerations per AZ.
- RDS Multi-AZ for failover.
- Redis replicas/multi-AZ where needed.

Learning stacks often choose single-instance or single-node to reduce cost and complexity.

---

## 17) VPC endpoints and private AWS API access

Without endpoints, private workloads often use NAT to reach AWS services (S3, ECR, STS, etc.).

VPC endpoints can:

- Reduce NAT dependency/cost in some paths.
- Keep traffic on AWS backbone.
- Improve security posture (private access patterns).

Terraform often models:

- Gateway endpoint for S3
- Interface endpoints for ECR API/DKR, CloudWatch Logs, SSM, STS, etc.

---

## 18) Connectivity debugging flow (use this every time)

When app cannot connect to DB/cache:

1. Confirm endpoint/port in app env vars.
2. Confirm SG rules on both sides (source identity + port).
3. Confirm subnet route tables.
4. Confirm NACL allows forward and return traffic.
5. Confirm service health/listener readiness.
6. Confirm DNS resolves as expected from client environment.

This beats random toggling every time.

---

## 19) Terraform-specific networking patterns you should know

### Pattern A: Reference IDs, avoid hard-coding

- Good: `vpc_id = data.aws_vpc.default.id`
- Good: `security_group_ids = [aws_security_group.app.id]`
- Avoid fixed IDs copied from console.

### Pattern B: Model intent with separate resources

- Separate SG resources by tier makes intent explicit.
- Separate route tables and associations by subnet tier.

### Pattern C: Use outputs for operational handoff

- Output key networking coordinates (endpoints, ports, SG IDs, subnet IDs) for CI and ops tooling.

### Pattern D: Keep "lab mode" flags visible

- Explicitly document settings that are convenience-over-security so future you does not misread them.

---

## 20) "Partials" you should internalize (small reusable truths)

These are compact rules you can reuse in almost every AWS networking design:

1. **Routing decides possibility; SG/NACL decide permission.**
2. **SG reference to SG is stronger than CIDR-based app-tier trust.**
3. **Private data tiers first; controlled entry points second.**
4. **DNS endpoints over IPs for managed services.**
5. **No overlapping CIDRs if you want future peering/TGW sanity.**
6. **Start least privilege on ports; widen only with evidence.**
7. **Stateful vs stateless is not academic; it changes packet outcomes.**
8. **Draw traffic matrix before writing rules.**
9. **Terraform references are your dependency graph documentation.**
10. **Every "temporary" wide rule becomes permanent unless tracked.**

---

## 21) Apply this directly to your current `main.tf`

If you want to harden this exact stack incrementally:

1. Split shared SG into app/db/cache SGs.
2. Narrow ingress rules to exact ports and source SGs.
3. Set RDS `publicly_accessible = false` and validate connectivity path.
4. Consider dedicated VPC with explicit public/private subnet tiers.
5. Revisit Redis at-rest encryption and HA settings.
6. Add comments marking learning defaults vs production defaults.

That gives you a clean "learning -> production" progression without a full rewrite.

---

## 22) Quick self-test

If you can answer these without notes, you are in strong shape:

- Why can two resources in same SG talk when `self = true`?
- Why can a route table break connectivity even when SG allows port?
- Why can DNS endpoint changes break code that hard-codes IPs?
- Why does NAT not provide inbound internet access?
- Why do private data tiers usually avoid public exposure?

If you want, the next learning file can be a diagram-first "traffic matrix + SG rulebook" for this exact monorepo.
