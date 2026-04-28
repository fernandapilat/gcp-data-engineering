# BigQuery Study Notes

## Official Documentation & Resources
* **Official Google Cloud Documentation:** [BigQuery Docs](https://docs.cloud.google.com/bigquery/docs?hl=pt-br)
* **Recommended Reading:** [Google BigQuery: The Definitive Guide (O'Reilly)](https://www.amazon.com/Google-BigQuery-Definitive-Warehousing-Analytics/dp/1492044466)

---

## Course 4: Google BigQuery - Data Manipulation

### 1. Understanding Datasets

In the BigQuery hierarchy, a **Dataset** is a top-level container that is used to organize and control access to your tables and views.

* **Purpose:** Acts as a logical grouping for your data, allowing you to manage permissions, data location, and lifecycle policies at scale.
* **Scope:** Datasets are project-specific. A single Google Cloud Project can contain multiple datasets.
* **Data Location:** When creating a dataset, you must define a geographical location (e.g., `US`, `EU`, or specific regions). Once set, it cannot be changed, which is critical for compliance and latency optimization.

---

### 1.1 Dataset Creation Requirements and Restrictions

When naming and configuring a dataset in BigQuery, you must adhere to specific rules enforced by Google Cloud:

#### Naming Conventions
* **Uniqueness:** The dataset ID must be unique within the specific project.
* **Character Set:** Must contain letters (a-z, A-Z), numbers (0-9), or underscores (`_`).
* **Starting Character:** The name must start with a letter or an underscore.
* **Length:** Can be up to 1,024 characters long.
* **Case Sensitivity:** Dataset IDs are case-sensitive on some systems, but BigQuery generally treats them as case-sensitive for API calls.

#### Location & Restrictions
* **Immutability:** Once a dataset is created, you **cannot** change its location (e.g., from `US` to `EU`). To move data, you would need to export and re-import it or use Data Transfer Service.
* **Reserved Prefixes:** You cannot start a dataset name with `goog` or `google`, as these are reserved for system use.
* **Region Selection:** The choice of location (Multi-region vs. Region) affects performance, cost, and compliance with data sovereignty laws (like GDPR).

---

### 1.2 Creating a Dataset: Step-by-Step

After ensuring your dataset name and location meet the requirements mentioned above, follow these steps to create it via the Google Cloud Console:

1.  **Navigate to BigQuery:** In the Google Cloud Console, go to the BigQuery page.
2.  **Select your Project:** In the Explorer panel, select the project where you want to create the dataset.
3.  **Open Creation Menu:** Click on the **three dots (View actions)** next to your project ID and select **Create dataset**.
4.  **Configure Dataset ID:** Enter your unique ID (remembering the naming conventions).
5.  **Select Data Location:** Choose between a Multi-region (e.g., US, EU) or a specific Region (e.g., southamerica-east1 for São Paulo). 
    * *Note: Data location affects cost and latency.*
6.  **Set Expiration (Optional):** You can define a **Default table expiration**. This is useful for temporary or staging data, as BigQuery will automatically delete tables after the specified number of days.
7.  **Encryption:** By default, Google manages encryption. You can also choose Customer-Managed Encryption Keys (CMEK) for higher security requirements.
8.  **Finalize:** Click **Create Dataset**. The new dataset will now appear in your project's Explorer side panel.

---

### 1.3 Creating a Dataset via Google Cloud Shell (CLI)
The `bq` command-line tool is a powerful alternative to the Google Cloud Console, allowing for automation and faster resource management.

#### Step-by-Step via CLI:
1. **Open Cloud Shell:** Click the Cloud Shell icon in the top right of the Google Cloud Console.
2. **Execute the Create Command:** Use the `bq mk` command to create the resource.

**Command used in practice:**
```bash
bq --location=europe-west9 mk --dataset --description="conjunto de dados usando SHELL - homologação" belleza_verde_vendas_hom
```


**Parameters Explained:**
* **`bq`**: The BigQuery command-line tool.
* **`--location=europe-west9`**: Explicitly defines the data location (in this case, Paris).
* **`mk`**: Short for "make", the command used to create new resources.
* **`--dataset`**: Specifies that the resource type is a dataset.
* **`--description`**: Adds metadata to the dataset, essential for data governance and team collaboration.
* **`belleza_verde_vendas_hom`**: The unique ID assigned to the new dataset.

**Execution Feedback:**
Upon successful execution, the terminal returns a confirmation message:
`Dataset 'project-id:belleza_verde_vendas_hom' successfully created.`

**Why use the CLI alternative?**
* **Efficiency:** Faster execution for experienced users compared to navigating the GUI.
* **Governance:** Easier to standardize descriptions and locations through scripts.
* **Automation:** This command can be part of a larger bash script to provision entire environments (Dev, Homolog, Prod) automatically.

### 1.4 Inspecting and Managing Datasets via CLI

After creating a dataset, you can inspect its metadata and update its properties directly from the Cloud Shell using the following commands:

**A. Listing Datasets**
To see all datasets within your current project:

```bash
bq ls
```

**B. Viewing Dataset Details**
To see the specific configuration of a dataset (location, creation time, expiration):

```bash
bq show belleza_verde_vendas_hom
```

**C. Viewing Details in JSON Format**
For a more structured view (useful for automation or deep inspection), you can format the output:

```bash
bq show --format="prettyjson" belleza_verde_vendas_hom
```

> **Tip:** The JSON format reveals internal metadata that might be hidden in the standard summary view.

#### D. Updating Dataset Metadata
If you need to change properties like the description without deleting and recreating the dataset, use the update command:

**Command used in practice:**

bq update --description="Conjunto de dados usando SHELL -- Homologação v2" belleza_verde_vendas_hom

**Why use these commands?**
* **Verification:** bq ls and bq show ensure your resource was created with the correct parameters.
* **Flexibility:** bq update allows for adjustments without the risk of deleting data.
* **JSON Analysis:** prettyjson is essential for understanding how Google Cloud structures resource data internally.

## 2. Copying or Transferring Data

When you need to move data between different projects or regions, BigQuery provides a more robust method than a simple copy: the Data Transfer Service.

### 2.1 Cross-Project Data Transfer (`bq mk --transfer_config`)

The following command sets up an automated transfer job. In this specific case, it is configured to pull data from a source project into your local dataset.

**Updated Command:**
```bash
bq mk --transfer_config \
--project_id=curso-bigquery-490113 \
--data_source=cross_region_copy \
--target_dataset=belleza_verde_vendas_hom \
--display_name="Job de copia de conjunto de dados para Belleza Verde Hom" \
--params='{"source_dataset_id":"belleza_verde_vendas","source_project_id":"curso-bigquery-490113","overwrite_destination_table":"true"}'
```

### 2.2 Critical Observation: Source vs. Target
* **Target Project:** `curso-bigquery-490113` (Where the job is created and where the data will land).
* **Source Project:** `curso-bigquery-490113` (Where the original data currently exists).

### 2.3 Why use backslashes (`\`)?
The backslashes at the end of each line are used in the terminal to "escape" the newline character. This allows you to break a very long command into multiple lines, making it much easier to read and edit without breaking the execution.

### 2.4 Lessons Learned: Troubleshooting Data Transfers

The process of setting up a Cross-Region Data Transfer is a "rite of passage" for Data Engineers. Here are the key takeaways from this implementation:

#### 1. Identity & Security (The OAuth Ritual)
* **User Data vs. Application Data:** We learned that automated jobs need an identity. Using "User Data" with a "Desktop App" Client ID is the quickest way to authorize commands directly from the Cloud Shell.
* **Consent is Key:** The Google Cloud terminal provides an authorization URL. You must manually sign in and paste the `version_info` code back to grant the "handshake" between your user and the BigQuery service.

#### 2. The Precision of Project IDs
* **Typo Sensitivity:** A single missing digit in a `project_id` (like the "9" we missed earlier) results in a `Permission Denied` error. Always copy project IDs directly from the Google Cloud Console.

#### 3. Regional Awareness (The "CloudRegion" Error)
* **Cross-Region Logic:** Data cannot move between continents (`us-central1` to `europe-west9`) without explicit instructions. 
* **The Solution:** We must use the `--location` flag pointing to the **target region** (in this case, `europe-west9` for Paris) to orchestrate the transfer successfully.

#### 4. Cost Consciousness
* **Egress Fees:** Moving data across regions incurs small network fees (Data Egress). In student accounts, this is covered by free credits, but in production, it's a critical factor for architectural decisions.

> **Final Result:** The job is now registered and will handle the synchronization between the US source and the European target automatically.

![alt text](data_transfer.png)

### 2.5 Data Transfer via Console (GUI) and Direct Dataset Copy

After exploring the command-line approach, we move to the graphical interface. The BigQuery Console offers a more intuitive way to manage transfers and direct copies without writing code.

#### 2.5.1 Creating Transfers via the "Data Transfer" Tab
The Data Transfer Service (DTS) is accessible via the side menu and allows for highly customizable data pipelines.

* **Marketplace & Connectors:** DTS isn't limited to BigQuery. It supports over 200 sources, including YouTube, Salesforce, Oracle, TikTok, and Facebook.
* **The "Dataset Copy" Option:** To move data between BigQuery environments (like `vendas` to `vendas_dev`), we select "Dataset Copy".
* **Scheduling:** Unlike simple copies, DTS allows for scheduled runs (Daily, Weekly, or Custom). This is ideal for keeping Dev/Hom environments synchronized with Production automatically every 24 hours.
* **Monitoring:** Every job generates an execution log. Through the **Logs Explorer**, you can monitor the status (e.g., "Dispatched run") and verify if the data has successfully moved from the source project to the target project.



#### 2.5.2 Direct Dataset Copy (The "Quick" Method)
For immediate, one-time movements—such as populating the `vendas_prod` dataset—the console offers an even faster route:

1.  **Navigate to Source:** Select the source dataset (`belleza_verde_vendas`).
2.  **Action:** Click the "Copy" button at the top of the dataset panel.
3.  **Target:** Select the destination dataset and decide whether to "Overwrite destination table."
4.  **Result:** This creates a default-named job in the Transfer tab and executes immediately.

#### 2.5.3 Key Comparison: CLI vs. DTS UI vs. Direct Copy

| Feature | Cloud Shell (CLI) | Data Transfer (GUI) | Direct Copy (Button) |
| :--- | :--- | :--- | :--- |
| **Effort** | High (Scripting) | Medium (Forms) | Low (Clicks) |
| **Automation** | Highly Scriptable | Native Scheduling | One-time execution |
| **External Sources** | Limited | 200+ Connectors | BigQuery only |
| **Best For** | CI/CD Pipelines | Scheduled Syncs | Quick Ad-hoc copies |

> **Note on Overwrite:** In all methods, the "Overwrite" option is the safety switch that ensures the target dataset reflects the most current version of the source by replacing existing tables.

#### 2.5.4 Automation & External Integrations
The real power of the Data Transfer Service lies in its ability to act as an automated ETL (Extract, Transform, Load) tool:
* **Scheduled Runs:** Once configured, the job runs on Google's infrastructure independently. Whether set to hourly or daily, it ensures data consistency without manual intervention.
* **External Ecosystems:** By using connectors like **Amazon S3**, **Azure Blob Storage**, or **Salesforce**, BigQuery can automatically ingest data from competing clouds or external SaaS platforms.
* **The Workflow:** Source Data → S3 Bucket → DTS Schedule → BigQuery Dataset. This creates a seamless pipeline where business data is always ready for analysis.

#### 2.5.5 Data Freshness & Latency
When automating transfers (especially from external sources like Amazon S3 or Facebook Ads), it's important to consider:
* **Schedule Alignment:** Ensure the BigQuery job runs *after* the source system has finished its own data processing.
* **On-Demand Runs:** Even with a schedule (e.g., daily), the console allows you to "Schedule a backfill" or "Run now" if you need the data updated immediately for an urgent report.

> **Security Tip:** When connecting external databases (Oracle, Salesforce), always follow the "Principle of Least Privilege": the credentials provided to the Data Transfer Service should only have *read* access to the specific tables needed, never *write* access to the source.

### 2.6 Resource Deletion and Lifecycle Management

After verifying that the data transfer and synchronization were successful, we performed a cleanup of the destination dataset. This is a critical step in the data lifecycle to manage costs and maintain environment organization.

```bash
bq rm -r -d belleza_verde_vendas_hom
```

**Key Components of the Command:**
* **bq rm:** The basic BigQuery command to remove a resource.
* **-r (Recursive):** Instructs the system to delete all tables and data contained within the dataset. Without this flag, BigQuery will block the deletion of any non-empty dataset.
* **-d (Dataset):** Specifically identifies the resource type to be removed as a dataset.

**Why Cleanup Matters:**
1. **Cost Control:** Deleting redundant datasets prevents unnecessary storage charges, especially when data is duplicated across different regions (e.g., US and Europe).
2. **Environment Hygiene:** In professional workflows, temporary or "Homologation" datasets are removed once testing is complete to prevent confusion and ensure only authorized production data remains active.

> **Professional Note:** Deletion via CLI is immediate and permanent. Always double-check the dataset name and project context before executing the `rm` command.