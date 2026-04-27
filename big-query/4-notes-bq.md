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