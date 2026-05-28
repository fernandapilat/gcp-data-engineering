# Cloud Engineering & Foundations

This repository documents my progression through foundational and advanced infrastructure layers on Google Cloud Platform (GCP), covering virtualized environments, automated scaling, and cloud data analytics.

---

## Core Cloud Pillars

* **Taxonomy & Layering:** Understanding operational responsibilities across IaaS (Compute Engine), PaaS (Cloud Storage), and SaaS (BigQuery) environments.
* **Immutability & SRE:** Eliminating configuration drift using custom *Golden Images* and Managed Instance Groups (MIG) with automated horizontal auto-scaling and self-healing.
* **Decoupled Architecture:** Isolation of storage layers via Google Cloud Storage (GCS) and global traffic routing using Layer-7 HTTP Application Load Balancing.

---

## Directory Structure & Curriculum

| Directory | Course / Topic | Core Implementation Objectives |
| :--- | :--- | :--- |
| **`01-gcp-vms-scaling-lb/`** | Google Cloud: Virtual Machines, Scaling & Load Balancing | • Compute Engine VM configuration & deployment<br>• Custom image creation & Auto-scaling testing<br>• Automated content updates via cron/rsync<br>• Layer-7 Application Load Balancing<br>• Content Delivery Network (CDN) integration |
| **`02-cloud-fundamentals-data/`** | Cloud Fundamentals: Building the Foundation | • Cloud computing principles and paradigms<br>• IaaS, PaaS, and SaaS differentiation<br>• Platform comparison (AWS, GCP, Azure)<br>• Object storage via Google Cloud Storage<br>• Cloud analytics with BigQuery & Colab<br>• Cost models and shared security matrices |

---

## Projects Overview

### 1. High-Availability Web Fleet (`01-gcp-vms-scaling-lb/`)
* **Objective:** Deploy a fault-tolerant, auto-scaling web server array.
* **Implementation:** Configured automated asset synchronization between GCS buckets and local paths via `crontab`. Baked the environment state into a custom disk image deployed across a multi-zone MIG. Secured the fleet behind a Global Layer-7 HTTP Load Balancer with a static Anycast IP and active Health Checks, validating scalability up to 10 nodes using **Locust**.

### 2. Cloud Data Pipeline Base (`02-cloud-fundamentals-data/`)
* **Objective:** Ingest and analyze unstructured and structured datasets in the cloud.
* **Implementation:** Structured secure object storage buckets inside GCS with cost-effective lifecycle rules. Evaluated the trade-offs between AWS, Azure, and GCP, and managed cloud-native data warehousing capabilities using **Google BigQuery** to run distributed analytical SQL queries integrated with **Google Colab** notebooks.

---

## Technical Competencies Summary

| Category | Technologies & Tools |
| :--- | :--- |
| **Compute & Networking** | Compute Engine (VMs), Managed Instance Groups (MIG), Global HTTP Application Load Balancer, Anycast IP, Health Checks |
| **Data & Analytics** | BigQuery Data Warehouse, Google Cloud Storage (GCS), Google Colab |
| **Automation & Testing** | Locust Concurrency Framework, Gcloud SDK CLI, Bash Scripting, Crontab Engines |
| **Cloud Governance** | Cloud Deployment Models (IaaS, PaaS, SaaS), Billing Models, Cost Management, IAM Controls |

## References 

- **Infrastructure Performance Testing:** [Locust Framework](https://docs.locust.io/)
- **Vendor Cloud Documentation:** [Google Cloud Enterprise Documentation](https://cloud.google.com/docs)
```