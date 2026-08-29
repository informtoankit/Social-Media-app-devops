# InstaClone — End-to-End DevOps Pipeline

A production-style, cloud-native social media application built as a comprehensive reference implementation of the modern DevOps lifecycle — from application development through containerization, cloud infrastructure provisioning, Kubernetes orchestration, and public traffic routing.

> **Status:** Actively in development. Core infrastructure, containerization, and Kubernetes deployment with public ALB routing are complete. CI/CD, Helm packaging, GitOps, observability, and security hardening are in progress.

---

## Table of Contents

- [Project Goal](#project-goal)
- [Architecture Overview](#architecture-overview)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Application Features](#application-features)
- [Infrastructure Design](#infrastructure-design)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Environment Strategy](#environment-strategy)
- [Security Practices](#security-practices)
- [Cost Management Strategy](#cost-management-strategy)
- [Local Development](#local-development)
- [Deploying to AWS](#deploying-to-aws)
- [Roadmap](#roadmap)
- [Key Engineering Decisions](#key-engineering-decisions)
- [Debugging Highlights](#debugging-highlights)

---

## Project Goal

InstaClone is an Instagram-style social media application (user auth, posts, likes, comments, follows) built primarily as a **vehicle to design and implement a complete, production-grade DevOps lifecycle** — not as a feature-complete social product. The application layer is intentionally kept lean so that the majority of engineering effort goes into infrastructure, security, automation, and operational practices that mirror real production environments.

**The core belief driving this project:** a DevOps portfolio project is only valuable if the infrastructure decisions are defensible, the architecture reflects genuine production trade-offs, and every component was actually debugged and understood — not copy-pasted from a tutorial.

---

## Architecture Overview

```text
                              Internet
                                 │
                          Route 53 (planned)
                                 │
                        ACM TLS Cert (planned)
                                 │
                  AWS Application Load Balancer (ALB)
                    (provisioned by AWS Load Balancer
                     Controller via Kubernetes Ingress)
                                 │
                  ┌──────────────┴──────────────┐
                  │                              │
            Path: /api/*                    Path: / (default)
                  │                              │
                  ▼                              ▼
         backend-service                  frontend-service
          (ClusterIP)                       (ClusterIP)
                  │                              │
                  ▼                              ▼
        ┌─────────────────┐            ┌─────────────────┐
        │  Backend Pods   │            │ Frontend Pods   │
        │  (FastAPI, x2)  │            │ (Nginx+React,x2)│
        └────────┬────────┘            └─────────────────┘
                  │
    ┌─────────────┼──────────────┐
    │             │              │
    ▼             ▼              ▼
 RDS PostgreSQL  S3 Bucket   Secrets Manager
 (Multi-AZ opt.) (Images)    (DB credentials)


Networking Layer (VPC):
─────────────────────────────────────────────────────────
  Multi-AZ VPC (3 Availability Zones)
    ├── 3× Public Subnets   → ALB, NAT Gateways
    ├── 3× Private Subnets  → EKS Worker Nodes, RDS
    ├── 3× NAT Gateways     → outbound internet for private subnets
    ├── Internet Gateway    → inbound/outbound for public subnets
    └── VPC Flow Logs       → CloudWatch (network audit trail)

Access Control:
─────────────────────────────────────────────────────────
  IAM Roles for Service Accounts (IRSA) via EKS OIDC provider
    ├── ALB Controller role → manages ALB/Security Groups/Target Groups
    └── (planned) App pod roles → scoped S3/Secrets Manager access

  Security Groups (least privilege):
    ALB SG  → allows 80/443 from internet
    EKS SG  → allows traffic from ALB SG + inter-node traffic
    RDS SG  → allows port 5432 from EKS SG only
```

### Request Flow

1. User hits the ALB's public DNS name (Route 53 domain planned).
2. ALB (created automatically by the AWS Load Balancer Controller reading Kubernetes `Ingress` rules) routes by path:
   - `/api/*` → `backend-service` → FastAPI backend pods
   - `/` (everything else) → `frontend-service` → Nginx-served React app
3. Backend pods connect to RDS PostgreSQL over the private subnet using credentials pulled from environment configuration (Secrets Manager integration in progress).
4. Image uploads use **presigned S3 URLs** — the client (browser) uploads directly to S3; backend pods never handle raw image bytes, keeping them stateless.

---

## Tech Stack

### Application
| Layer | Technology |
|---|---|
| Backend | FastAPI (Python), SQLAlchemy, JWT auth (`python-jose`, `passlib`/`bcrypt`) |
| Frontend | React (Vite) |
| Database | PostgreSQL |
| Object Storage | Amazon S3 (MinIO for local dev parity) |

### Infrastructure & Cloud
| Category | Technology |
|---|---|
| Cloud Provider | AWS |
| IaC | Terraform (modular, remote state) |
| Container Orchestration | Amazon EKS (Kubernetes) |
| Container Registry | Amazon ECR |
| Database | Amazon RDS (PostgreSQL) |
| Object Storage | Amazon S3 |
| Networking | Amazon VPC (multi-AZ), NAT Gateway, Internet Gateway |
| Load Balancing | AWS Application Load Balancer (via AWS Load Balancer Controller) |
| Secrets | AWS Secrets Manager |
| IAM | IAM Roles, OIDC Federation (IRSA) |
| Observability (infra) | CloudWatch, VPC Flow Logs |

### DevOps Tooling
| Category | Technology |
|---|---|
| Containerization | Docker (multi-stage builds) |
| Local Orchestration | Docker Compose |
| Kubernetes Package Management | Helm *(in progress)* |
| CI/CD | GitHub Actions *(planned)* |
| GitOps | Argo CD *(planned)* |
| Code Quality | SonarQube *(planned)* |
| Security Scanning | Trivy *(planned)* |
| Monitoring | Prometheus, Grafana *(planned)* |
| Logging | Loki *(planned)* |

### Explicitly Deferred
| Technology | Status | Reasoning |
|---|---|---|
| Istio (Service Mesh) | Deferred to a bonus phase | Evaluated early; service count (2–3 services) doesn't justify service mesh complexity/overhead during core build. Will be added as **Ambient Mesh** once the core 31-phase roadmap is complete, as a deliberate, documented architectural decision rather than default tooling. |

---

## Repository Structure

```text
Devops-instagram/
├── application/
│   ├── backend/                 # FastAPI application
│   │   ├── app/
│   │   │   ├── main.py
│   │   │   ├── config.py
│   │   │   ├── database.py
│   │   │   ├── models.py
│   │   │   ├── schemas.py
│   │   │   ├── storage.py       # S3 presigned URL logic
│   │   │   └── routers/         # users, posts, comments, follows
│   │   ├── Dockerfile           # multi-stage, non-root
│   │   ├── requirements.txt
│   │   └── tests/
│   └── frontend/                # React (Vite) application
│       ├── src/
│       ├── Dockerfile           # multi-stage: Node build → Nginx serve
│       └── nginx.conf
│
├── terraform/
│   ├── main.tf                  # root module orchestration
│   ├── variables.tf / outputs.tf / providers.tf / backend.tf
│   ├── environments/
│   │   ├── dev/terraform.tfvars     # applied environment
│   │   ├── qa/terraform.tfvars      # code-ready, not applied
│   │   └── prod/terraform.tfvars    # code-ready, not applied
│   └── modules/
│       ├── vpc/                 # VPC, subnets, IGW, flow logs
│       ├── networking/          # NAT gateways, route tables
│       ├── security/            # security groups (ALB/EKS/RDS)
│       ├── rds/                 # PostgreSQL + Secrets Manager
│       ├── s3/                  # image storage bucket
│       ├── eks/                 # EKS cluster, node group, OIDC
│       └── alb-controller/      # IAM role/policy for IRSA
│
├── kubernetes/
│   └── base/
│       ├── namespace.yaml
│       ├── backend/             # Deployment, Service, ConfigMap, Secret
│       ├── frontend/            # Deployment, Service
│       └── ingress/             # ALB Ingress (path-based routing)
│
├── docker-compose.yml           # local dev stack (Postgres + MinIO + app)
├── scripts/
│   └── setup-ecr.sh
└── .github/
    └── PULL_REQUEST_TEMPLATE.md
```

---

## Application Features

- User registration and JWT-based authentication
- User profiles
- Image post creation with **direct-to-S3 presigned upload**
- Feed of posts
- Likes and comments
- Follow / unfollow
- REST API (`/api/*`) with `/health` and `/ready` endpoints for Kubernetes probes

The application is intentionally kept at moderate complexity — enough to require a real relational schema, object storage, and stateless auth, without the app logic distracting from the infrastructure and operations work that is the actual focus of this project.

---

## Infrastructure Design

### Networking (Terraform: `modules/vpc`, `modules/networking`, `modules/security`)

- **Multi-AZ VPC** spanning 3 Availability Zones for high availability
- **Public / private subnet separation**: load balancers and NAT gateways live in public subnets; EKS worker nodes and RDS live in private subnets with no direct internet exposure
- **3 NAT Gateways** (one per AZ) — deliberately kept at production HA spec even in the dev environment, since NAT count is an architectural decision, not a cost lever
- **VPC Flow Logs** shipped to CloudWatch for network-level audit and troubleshooting
- **Security Groups** follow least privilege in a strict chain: `Internet → ALB SG → EKS SG → RDS SG`, with no direct path from the internet to the database

### Compute (Terraform: `modules/eks`)

- **Amazon EKS** cluster with a managed node group
- Dedicated **IAM roles** for the EKS control plane and worker nodes, each scoped to only the AWS-managed policies they require
- **OIDC provider** configured on the cluster to enable **IRSA (IAM Roles for Service Accounts)** — allowing specific Kubernetes ServiceAccounts (e.g. the AWS Load Balancer Controller) to assume narrowly-scoped IAM roles with temporary, auto-rotating credentials instead of static keys

### Data Layer (Terraform: `modules/rds`, `modules/s3`)

- **RDS PostgreSQL** with:
  - Randomly generated password (Terraform `random_password`, never hardcoded)
  - Credentials stored in **AWS Secrets Manager**
  - Storage encryption enabled
  - Multi-AZ support built into the module (enabled per-environment via `tfvars`)
- **S3 bucket** for image storage with:
  - Server-side encryption (AES256)
  - Versioning enabled
  - Public access fully blocked (uploads happen via short-lived presigned URLs only)
  - CORS configured for direct browser-to-S3 uploads
  - Lifecycle rule to clean up incomplete multipart uploads after 7 days

### Container Registry (Terraform + `scripts/setup-ecr.sh`)

- **Amazon ECR** repositories for backend and frontend images
- Vulnerability scanning enabled on every image push
- Encryption at rest enabled

### State Management (`terraform/backend.tf`)

- **Remote state** in a versioned, encrypted, public-access-blocked S3 bucket
- **DynamoDB table** for state locking, preventing concurrent `apply` conflicts — critical for any team (or future-self) working against the same infrastructure

---

## Kubernetes Deployment

- **Namespace-scoped** deployment (`instaclone` namespace)
- **Deployments** for backend (2 replicas) and frontend (2 replicas), each with:
  - CPU/memory `requests` and `limits`
  - **Liveness and readiness probes** wired to the application's `/health` and `/ready` endpoints
  - Configuration injected via `ConfigMap` (non-sensitive) and `Secret` (JWT signing key)
- **ClusterIP Services** providing stable internal networking to pods with ephemeral IPs
- **Ingress** (AWS ALB Ingress Class) providing path-based routing:
  - `/api/*` → backend
  - `/` → frontend
- **AWS Load Balancer Controller**, installed via Helm and authenticated through IRSA, watches Ingress resources and automatically provisions/manages the real AWS ALB, target groups, and security groups

### Notable implementation detail: non-root containers and privileged ports

Both Dockerfiles run as **non-root users** as a security baseline. This surfaced a real, instructive issue: Nginx could not bind to port 80 as a non-root user (Linux restricts ports <1024 to root). Rather than run the container as root, the fix was to move Nginx to listen on port 8080 inside the container, with the Kubernetes Service mapping external port 80 → container port 8080 — preserving the non-root security posture without giving up the standard external port.

---

## Environment Strategy

The project follows an **environment parity** model: `dev`, `qa`, and `prod` share identical Terraform module code and architecture (multi-AZ, 3 NAT gateways, encryption, flow logs). Only environment-specific **scale** differs, controlled entirely through `terraform.tfvars`:

| Setting | Dev (applied) | QA (code-ready) | Prod (code-ready) |
|---|---|---|---|
| EKS node count | 1 | 2 | 3 |
| EKS node instance type | t3.small | t3.medium | t3.large |
| RDS instance class | db.t3.micro | — | db.t3.medium |
| RDS Multi-AZ | false | — | true |

**Only the `dev` environment is actually provisioned in AWS.** This is a deliberate cost-management decision, not a shortcut in architecture quality — the `qa` and `prod` Terraform configurations are fully written and validated (`terraform plan`), ready to apply against a real budget/account when needed.

---

## Security Practices

- No hardcoded secrets anywhere in the codebase — `.env` files are git-ignored; Kubernetes `Secret` manifests are git-ignored; database credentials live in AWS Secrets Manager
- Multi-stage Docker builds strip build-time toolchains (compilers, dev headers) from final runtime images
- Non-root container users enforced on both backend and frontend images
- IAM least-privilege throughout: EKS control plane, worker nodes, and the ALB controller each have narrowly scoped IAM policies rather than broad permissions
- IRSA (OIDC federation) used instead of static AWS credentials inside pods
- S3 bucket fully blocks public access; all image access is via time-limited presigned URLs
- Security groups enforce a strict access chain (internet → ALB → EKS → RDS), with the database never directly reachable from outside the VPC
- Terraform state encrypted at rest in S3 with DynamoDB-based locking

---

## Cost Management Strategy

This project runs against a personal AWS free-tier budget, so cost discipline is treated as an engineering constraint, not an afterthought:

- **Only the `dev` environment is deployed** at any given time
- Infrastructure is **destroyed (`terraform destroy`) after each working session** rather than left running continuously
- Kubernetes/Helm-managed AWS resources (ALB, security groups created by the AWS Load Balancer Controller) are cleaned up **before** running `terraform destroy`, since Terraform has no knowledge of resources it didn't create — skipping this step causes `DependencyViolation` errors when Terraform tries to tear down subnets/VPC that still have attached ALB/ENI resources
- Low-cost, storage-billed services (ECR, S3) are left running between sessions since their cost is negligible (fractions of a cent/month for this project's data volume) — only compute-heavy, hourly-billed resources (EKS control plane, NAT Gateways, RDS) are torn down

---

## Local Development

```bash
# Clone and start the full local stack (Postgres + MinIO + backend + frontend)
docker compose up --build

# Backend:  http://localhost:8000
# Frontend: http://localhost:3000
# MinIO console: http://localhost:9001
```

Local development uses **MinIO** as an S3-compatible object store, so the application code (`storage.py`) requires zero changes when pointed at real AWS S3 — only the `S3_ENDPOINT_URL` environment variable differs between environments.

---

## Deploying to AWS

```bash
# 1. Provision infrastructure (VPC, EKS, RDS, S3, ECR)
cd terraform
terraform init
terraform plan  -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"

# 2. Connect kubectl to the new cluster
aws eks update-kubeconfig --region ap-south-1 --name instaclone-dev-cluster

# 3. Build and push images to ECR
docker build -t <ecr-repo-url>/instaclone-backend:latest ./application/backend
docker push <ecr-repo-url>/instaclone-backend:latest
# (repeat for frontend)

# 4. Install the AWS Load Balancer Controller (IRSA-authenticated)
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system --set clusterName=instaclone-dev-cluster ...

# 5. Deploy the application
kubectl apply -f kubernetes/base/namespace.yaml
kubectl apply -f kubernetes/base/backend/
kubectl apply -f kubernetes/base/frontend/
kubectl apply -f kubernetes/base/ingress/

# 6. Get the public URL
kubectl get ingress -n instaclone

# 7. Tear down when done (cost control)
kubectl delete ingress instaclone-ingress -n instaclone
helm uninstall aws-load-balancer-controller -n kube-system
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

---

## Roadmap

This project follows a 31-phase build plan (+ 1 bonus phase), moving sequentially from application development through full production hardening.

| # | Phase | Status |
|---|---|---|
| 1 | Architecture & requirements planning | ✅ Complete |
| 2 | Application development (FastAPI + React) | ✅ Complete |
| 3 | Git strategy (branching, PR workflow, protection) | ✅ Complete |
| 4 | Dockerization (multi-stage, non-root, health checks) | ✅ Complete |
| 5 | Local integration testing (Docker Compose) | ✅ Complete |
| 6 | AWS VPC architecture (Terraform) | ✅ Complete |
| 7 | Terraform remote state (S3 + DynamoDB) | ✅ Complete |
| 8 | Amazon ECR | ✅ Complete |
| 9 | Amazon RDS (PostgreSQL + Secrets Manager) | ✅ Complete |
| 10 | Amazon S3 (image storage) | ✅ Complete |
| 11 | EKS cluster (IAM, node groups, OIDC) | ✅ Complete |
| 12 | Kubernetes Deployments (backend + frontend) | ✅ Complete |
| 13 | Services & Ingress (ALB, public routing) | ✅ Complete |
| 14 | Helm | 🔄 In progress |
| 15–18 | CI/CD (GitHub Actions, SonarQube, Trivy, Argo CD) | ⏳ Planned |
| 19–21 | Observability (Prometheus, Grafana, Loki) | ⏳ Planned |
| 22–26 | Security hardening, autoscaling, HA, deployment strategies, DR | ⏳ Planned |
| 27–31 | Testing, final architecture docs, README, resume prep, interview prep | ⏳ Planned |
| 32 | *(Bonus)* Istio Ambient Mesh | ⏳ Deferred by design |

---

## Key Engineering Decisions

**Why RDS instead of self-hosted PostgreSQL in Kubernetes?**
Running a database inside Kubernetes means owning backups, patching, and failover recovery manually. RDS provides managed backups, Multi-AZ failover, and patching — letting the project focus on application/infra concerns rather than database administration, which mirrors how most real teams operate.

**Why presigned S3 URLs instead of routing uploads through the backend?**
Keeps backend pods stateless and avoids the API becoming a bottleneck for large binary payloads — the client uploads directly to S3, and the backend only ever stores the resulting URL.

**Why defer Istio?**
A service mesh's value scales with service-to-service complexity. At 2–3 services, NGINX/ALB Ingress fully covers north-south traffic needs, and adopting Istio now would add operational overhead (sidecar injection, mTLS cert rotation, extra resource consumption) without proportional benefit. This was evaluated deliberately in Phase 1 and revisited as a conscious bonus phase rather than skipped by omission.

**Why environment parity with only `dev` applied?**
Demonstrates production-grade IaC discipline (identical architecture across environments) while respecting a real budget constraint — architecture decisions (NAT count, Multi-AZ, encryption) are never compromised for cost; only compute scale is.

---

## Debugging Highlights

A selection of real issues found and resolved during this build — kept here because working through them (not just having a working end-state) is a core part of this project's value:

- **`bcrypt`/`passlib` version incompatibility** — `passlib`'s internal self-test crashed against newer `bcrypt` releases; resolved by pinning `bcrypt==4.0.1`
- **Vite build producing a blank page** (`React is not defined`) — root cause was a missing `vite.config.js` / `@vitejs/plugin-react` registration, so JSX wasn't being transformed correctly
- **Non-root Nginx container failing to bind port 80** — resolved by moving the container to listen on 8080 internally, with the Kubernetes Service remapping to port 80 externally
- **EKS node group AMI incompatibility** — explicit `ami_type` had to be set on the node group to resolve an AWS-side AMI/version mismatch
- **ALB Controller `DescribeRouteTables: UnauthorizedOperation`** — the IAM policy fetched via Terraform's `http` data source was stale/incomplete; resolved by refreshing the policy from AWS's official source and creating a new policy version
- **Ingress `unable to find port` errors (both directions)** — a real service/Ingress port mismatch between the backend's actual listening port (8000) and what the Service/Ingress declared (8080, then 80) — walked through systematically using `kubectl logs`, `describe`, and ALB target group health checks until backend, Service, and Ingress ports were fully consistent
- **`terraform destroy` failing with `DependencyViolation`** — Kubernetes/Helm had created AWS resources (ALB, security groups) that Terraform had no knowledge of; resolved by deleting the Ingress and uninstalling the Helm release *before* running `terraform destroy`, establishing a clear teardown order for future sessions

---

## Author's Note

This project is built and maintained as a personal, self-directed learning initiative to transition into DevOps/Platform Engineering, combining hands-on infrastructure work with prior professional experience in AWS support and software development. Every phase is implemented, tested, and debugged directly — including the failures documented above — rather than following a tutorial passively.