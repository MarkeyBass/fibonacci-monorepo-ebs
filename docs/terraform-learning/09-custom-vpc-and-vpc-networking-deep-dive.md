# Custom VPC and VPC Networking Deep Dive (This Project)

This guide explains the Step 1 migration from default VPC lookups to a custom VPC with explicit subnets.

It also teaches the networking concepts behind those changes so you can reason about future architecture decisions.

---

## 1) Why this migration exists

Your earlier setup depended on the account's default VPC and all its default subnets.
That is fast for first-time Terraform work, but it creates unpredictability:

- unknown subnet/AZ combinations
- inherited defaults you did not design
- environment validation issues when instance types are not available in selected subnets/AZs

Custom VPC fixes this by making networking explicit:

- you define the CIDR
- you define which subnets exist
- you define how internet routing works
- you know exactly what resources are connected where

---

## 2) What changed in Terraform

In this migration, networking primitives move to a dedicated file:

- `terraform/networking.tf`

Main application resources then reference those networking resources:

- `aws_vpc.this.id`
- `aws_subnet.public[*].id`

This makes dependencies obvious and keeps `main.tf` focused on compute/data/app integration.

---

## 3) VPC building blocks in this repo

### VPC

- One `aws_vpc` resource with DNS support and hostnames enabled.
- CIDR is configurable through variables.

Concept:

- VPC is your L3 network boundary and address space container.

### Internet Gateway (IGW)

- `aws_internet_gateway` attached to the VPC.

Concept:

- IGW is the path between VPC public routes and the internet.

### Public subnets

- Multiple `aws_subnet.public` resources across explicit AZs.
- `map_public_ip_on_launch = true` for internet-facing/single-instance learning mode.

Concept:

- Subnet is an AZ-scoped slice of VPC CIDR.
- "Public" is behavior from routing + public IP association, not a special subnet type.

### Public route table

- Route `0.0.0.0/0 -> IGW`.
- Associations bind each public subnet to that route table.

Concept:

- Route tables decide possible paths; SG/NACL decide permission.

---

## 4) Why this solves your EB subnet/AZ issue

Your EB failure came from mismatched subnet selection behavior and instance-type availability constraints.

With explicit VPC/subnet control:

- you choose known-good AZs
- EB receives only those subnet IDs
- subnet placement is deterministic

In EB settings, the key options are:

- `aws:ec2:vpc / VPCId`
- `aws:ec2:vpc / Subnets`
- for public single-instance pattern, set `AssociatePublicIpAddress` appropriately

This matches AWS EB VPC option behavior documented in EB docs.

---

## 5) Networking concepts you should internalize here

## A) CIDR planning

Good CIDR planning prevents future pain:

- avoid overlaps with other VPCs/on-prem ranges
- leave room for future subnet tiers (private app, private data, endpoints)
- keep subnet sizes practical (for labs `/24` is usually easy)

## B) AZ strategy

Subnets are tied to AZs, so architecture is AZ design.

For Step 1:

- choose 2+ AZs that support your EB instance type in your account context

For future:

- separate subnets per tier per AZ

## C) Routing vs security policies

Connectivity requires both:

1. routing path exists
2. SG/NACL allow the flow

Common confusion:

- opening SG rule does not help if route table cannot reach destination

## D) Security Groups vs NACLs

- SG: stateful, allow-list, attached to ENIs/resources
- NACL: stateless, subnet boundary, ordered allow/deny

Most application teams encode service-to-service intent in SG first.

## E) East-west vs north-south traffic

- North-south: internet <-> app entrypoint
- East-west: app <-> DB/cache inside VPC

Your design should describe both explicitly.

---

## 6) How resources map to the new network

In this Step 1 custom VPC pattern:

- EB instance: public subnets
- RDS subnet group: currently fed from explicit project subnets
- Redis subnet group: currently fed from explicit project subnets
- Shared SG: all three tiers use one SG (learning simplification)

Important learning note:

- This is intentional for lab simplicity, not a final production security model.

---

## 7) Recommended checks after migration

Run these checks every time you change networking:

1. `terraform plan` review
   - confirm subnet IDs, route resources, and replacements are expected
2. Route verification
   - ensure public subnets associate to public route table
3. EB settings verification
   - `VPCId` and `Subnets` point to new custom resources
4. Connectivity verification
   - app can reach DB/Redis
5. Exposure verification
   - only intended services are internet reachable

---

## 8) Known trade-offs in Step 1

This Step 1 pattern optimizes for speed and clarity:

- no private subnets yet
- no NAT gateways yet
- shared SG for app+db+cache

Pros:

- easy to reason about
- lower initial complexity
- unblocks deployment errors quickly

Cons:

- weaker segmentation than production patterns
- less realistic failure-domain and exposure model

---

## 9) Upgrade path from here (preview)

When you are ready for deeper networking:

1. introduce private app and private data subnets
2. add NAT for outbound internet from private app tier
3. move EB app instances to private app subnets
4. move RDS/Redis subnet groups to private data subnets
5. split SGs by tier (`app-sg`, `db-sg`, `cache-sg`)

This is covered in:

- `docs/terraform-learning/10-phase-2-private-subnets-and-nat-next-steps.md`

---

## 10) Mental model to keep forever

When debugging any AWS networking issue, ask in this order:

1. Does DNS resolve?
2. Does route table provide a path?
3. Do SG/NACL rules allow it?
4. Is the destination service actually healthy/listening?

If you apply this loop consistently, networking becomes much less mysterious.
