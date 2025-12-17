# AWS Real-Time Trading Data Pipeline

Enterprise-grade real-time trading data pipeline built on AWS using Kinesis, ECS (Fargate), Lambda, DynamoDB, Glue, and Athena.
The project demonstrates event-driven processing, serverless analytics, secure networking, and fully automated infrastructure deployment using Terraform.

---

## Architecture Overview

Infrastructure Stages

1. **Foundation**

    - VPC with private subnets

    - Internet Gateway (control-plane access only)

    - VPC Interface & Gateway Endpoints (ECR, S3, Logs, etc.)

2. **Data Streaming**

    - Kinesis Data Stream (real-time ingestion)

    - Kinesis Firehose (batch delivery)

    - S3 data lake bucket (raw streaming data + trading signals)    

3. **Producers (Simulated Producer Application)**

    - ECS Fargate service

    - Containerized application that simulates real-time trading events

    - Images pulled from Amazon ECR

    - No runtime internet access

4. **Consumers**

    - Lambda function triggered by Kinesis

    - Processes trades in near real time

    - Stores active positions in DynamoDB

    - Archives completed trades to S3

5. **Analytics**

    - AWS Glue Data Catalog

    - Glue Crawler for schema discovery

    - Amazon Athena for SQL analytics

    - Dedicated S3 bucket for Athena query results

--- 

### Project Structure
```
├── modules/           # Reusable Terraform modules
│   ├── analytics
│   ├── consumers
│   ├── data-streaming
│   ├── foundation
│   ├── producers
│   └── s3
├── stages/            # 5-stage deployment pipeline with a bootstrap stage
│   ├── 0-bootstrap
│   ├── foundation
│   ├── data-streaming
│   ├── producers
│   ├── consumers
│   └── analytics
├── utils/             # Helper scripts and tools
├── .github/workflows/ # CI/CD automation
│   ├── deploy.yml
│   └── destroy.yml
└── scripts/
    └── deployment-automation-scripts/
        ├── config.sh
        ├── deploy.sh
        ├── destroy.sh
        └── stacks_config.sh

```
---

## Prerequisites (Applies to Both Local & CI/CD)
AWS

✔ AWS account with permissions to create:

IAM (roles, policies, OIDC provider)

VPC, Subnets, Route Tables, VPC Endpoints

ECS (Fargate), ECR

Kinesis Data Streams & Firehose

Lambda, DynamoDB

S3, Glue, Athena

Tools

✔ Terraform ≥ 1.5
✔ AWS CLI
✔ Bash shell

Additional

✔ Docker
(used only to promote the producer image from Docker Hub to ECR)

---

## Deployment Options

You can deploy this project in two ways:

- CI/CD Deployment (recommended)

- Local Deployment (optional)

---

## CI/CD Deployment (Recommended)

This setup uses GitHub Actions + AWS OIDC and follows modern industry standards.

Key Characteristics

- No AWS access keys stored in GitHub

- No long-lived credentials

- Secure, short-lived STS credentials via OIDC

- No manual Terraform commands after bootstrap


🚀 1. Clone the Project

No fork is required:
```bash
git clone https://github.com/QaysAlnajjad/aws-realtime-trading-pipeline.git
cd aws-realtime-trading-pipeline
```

🟦 2. Deploy the Bootstrap Stack (ONE TIME ONLY)

The bootstrap stage enables GitHub Actions → AWS IAM authentication using OIDC.

This allows GitHub to deploy infrastructure without storing any AWS credentials.

✔ What the bootstrap stage creates
Resource	Purpose
AWS IAM OpenID Connect Provider (GitHub)	Allows GitHub Actions to authenticate to AWS
GitHub Actions IAM Role	Assumed by deploy / destroy workflows
Strict trust policy	Restricted to this repository only

⚠️ This stage is executed once per AWS account.

⚠️ IMPORTANT — Update Repository Name Before Running Bootstrap

The IAM trust policy is locked to a single GitHub repository.

If you cloned this project into your own GitHub account, you must update the repository reference.

Open:
```bash
stages/0-bootstrap/main.tf
```

Find:
```bash
"token.actions.githubusercontent.com:sub" = "repo:<usename>/<repo-name>:*"
```

Replace with your repository path:
```bash
repo:<your-github-username>/<repository-name>
```

If you skip this step, GitHub Actions will fail with:
```bash
Not authorized to assume role
```

Step 2.1 — Authenticate to AWS locally (temporary)

This is required only for bootstrap.

Either:
```bash
aws configure
```

Or:
```bash
export AWS_ACCESS_KEY_ID=xxxx
export AWS_SECRET_ACCESS_KEY=xxxx
export AWS_DEFAULT_REGION=us-east-1
```

Step 2.2 — Deploy the Bootstrap Stack
```bash
terraform -chdir=stages/0-bootstrap init
terraform -chdir=stages/0-bootstrap apply
```

Terraform will output:
```bash
github_actions_role_arn = arn:aws:iam::<ACCOUNT-ID>:role/github-actions-terraform-data-streaming-role
```

🟩 3. Configure GitHub Actions (NO SECRETS REQUIRED)

You do not need to add AWS keys or secrets to GitHub.

Open:
```bash
.github/workflows/deploy.yml
.github/workflows/destroy.yml
```

Find:
```bash
role-to-assume: arn:aws:iam::<ACCOUNT-ID>:role/github-actions-terraform-data-streaming-role
```

Replace <ACCOUNT-ID> with your AWS account ID.

✔ No secrets
✔ No PAT tokens
✔ No long-lived credentials
✔ Secure, short-lived STS credentials via OIDC

🟧 4. Configure Deployment Parameters

Open:
```bash
scripts/deployment-automation-scripts/config.sh
```

Edit the values to match your environment:

| Variable                          | Purpose                                              |
|-----------------------------------|------------------------------------------------------|
| AWS_REGION                        | AWS region for the deployment (e.g., us-east-1)      | 
| TF_STATE_BUCKET_NAME              | S3 bucket used for ALL Terraform remote state        |
| TF_STATE_BUCKET_REGION            | Region of the Terraform state bucket                 | 
| DATA_STREAM_S3_BUCKET_NAME        | S3 bucket for Firehose data                          |
| ATHENA_RESULTS_S3_BUCKET_NAME     | S3 bucket for Athena query results                   |
| ECR_REPO_NAME                     | ECR repository for producer image                    |


🐳 5. Docker Image Promotion (Automated)

This project uses Amazon ECR, not Docker Hub, at runtime.

During deployment, the pipeline automatically:

1. Pulls the producer image from Docker Hub

2. Pushes it to Amazon ECR

3. Stores the final ECR image URI in:
```bash
scripts/runtime/producer-ecr-image-uri
```

4. Injects that URI into the ECS task definition

You do not need to manually manage image tags.

🚀 6. Deploy the Full Infrastructure

From GitHub → Actions:

1. Select Deploy Trading Pipeline

2. Click Run workflow

3. Choose the target branch

GitHub Actions will automatically:

✔ Assume the IAM role
✔ Initialize Terraform backends
✔ Deploy stages in dependency order
✔ Promote Docker image → ECR
✔ Deploy ECS producers
✔ Deploy Kinesis, Lambda, DynamoDB
✔ Start the Glue crawler automatically

⏱ Typical deployment time: 10–15 minutes

🔍 7. Validate the Deployment
Real-Time Path
```bash
ECS Producer
 → Kinesis Data Stream
 → Lambda Consumer
 → DynamoDB
 → S3 completed-trades/
```
```bash
Batch Analytics Path
Kinesis Stream
 → Firehose
 → S3 raw-data/
 → Glue Crawler
 → Glue Data Catalog
 → Athena
```
Check Glue Crawler
```bash
aws glue get-crawler \
  --name <crawler-name> \
  --query Crawler.State
```

Wait until the state is READY.

Query with Athena
```bash
SHOW TABLES;

SELECT symbol, AVG(price) AS avg_price, COUNT(*) AS trades
FROM raw_data
GROUP BY symbol;
```

💣 8. Destroy the Infrastructure

From GitHub → Actions:

1. Select Destroy Trading Pipeline

2. Click Run workflow

The destroy workflow:

✔ Destroys stacks in correct dependency order
✔ Cleans up ECS services and Lambda
✔ Deletes DynamoDB tables
✔ Empties S3 buckets
✔ Deletes ECR images and repository
✔ Removes runtime artifacts

This guarantees no orphaned resources.

🧠 Why This Setup Matters

This project demonstrates real production patterns:

Secure CI/CD using OIDC (no secrets)

Bootstrap stage separation

Private, endpoint-only workloads

Immutable infrastructure

Clean teardown and cost safety

A reviewer can deploy and destroy this system confidently and safely, exactly as they would in a real AWS environment.

---

## Local Deployment (optional)
Local deployment is provided for development and experimentation.  
The recommended approach is CI/CD via GitHub Actions.

```bash
# Deploy the entire pipeline
./scripts/deployment-automation-scripts/deploy.sh

# Destroy all resources
./scripts/deployment-automation-scripts/destroy.sh

```

## Data Flow

### Real-Time Processing Path

```bash 
ECS Producer
   ↓
Kinesis Data Stream
   ↓
Lambda Consumer
   ↓
DynamoDB (active positions)
   ↓
S3 completed-trades/
```
- Low latency

- Event-driven

- Fully serverless after ingestion

### Batch Analytics Path

```bash
Kinesis Stream
   ↓
Firehose (buffered batches)
   ↓
S3 raw-data/
   ↓
Glue Crawler
   ↓
Glue Data Catalog
   ↓
Athena SQL Queries
```
- Optimized for cost

- Schema discovered automatically

- SQL-based analytics

## Analytics & Querying

After deployment, the Glue crawler runs automatically to discover schemas.

Verify crawler status
```bash
aws glue get-crawler --name <crawler-name> --query Crawler.State
```
Wait until the state is READY.

## Query with Athena

1. Open Amazon Athena

2. Select the configured workgroup

3. Run queries:
```bash
-- List discovered tables
SHOW TABLES;

-- Analyze raw trading data
SELECT symbol, AVG(price) AS avg_price, COUNT(*) AS trades
FROM raw_data
GROUP BY symbol;
```

## Trading Logic Overview

Producer

- Generates mock real-time trading events

- Sends records to Kinesis

Consumer (Lambda)

- Detects buy/sell signals

- Maintains open positions in DynamoDB

- Writes completed trades to S3

Analytics

- Raw and completed trades are queryable via Athena

- No ETL jobs required


## Security Highlights

- ECS tasks run in private subnets

- No direct internet access at runtime

- AWS services accessed via VPC Endpoints

- S3 buckets:

    -- Public access fully blocked

    -- Versioning configurable

    -- Lifecycle policies defined per stack

- IAM roles follow least privilege

## Monitoring & Observability

- ECS Console – Producer task health

- Kinesis Metrics – Throughput and shard utilization

- Lambda Logs – Consumer execution

- S3 – Raw and processed data

- Athena – Query execution history


## Key Learnings & Design Decisions

- Built a real-time event-driven pipeline using AWS managed services

- Separated infrastructure stages for clean dependency management

- Used Glue Data Catalog as a metadata layer for S3-based analytics

- Removed runtime internet dependency by using ECR + VPC endpoints

- Designed reusable Terraform modules with clear responsibility boundaries

## Final Notes

This project demonstrates:

- Production-grade AWS architecture

- Secure networking

- Clean Terraform module design

- Real-time + batch analytics in one system

It is intentionally structured to reflect how real systems are built, not just how services are connected.

