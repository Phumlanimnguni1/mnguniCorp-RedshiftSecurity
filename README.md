# MnguniCorp Events Serverless Data Warehouse Security

## Overview
This project simulates a real-world enterprise data security implementation for an event management organization, MnguniCorp Events. The objective is to secure an existing Amazon Redshift Serverless data warehouse by implementing enterprise-grade security features, including row-level security, column-level security, dynamic data masking, and comprehensive audit logging.

---
## Problem Statement

MnguniCorp Events successfully centralized its TICKIT data into Amazon Redshift Serverless, but the data warehouse lacks fine-grained access controls. Sensitive data (like user PII and financial metrics PCI) is exposed to all database users, and administrators lack visibility into user queries and connection activities, which is a major compliance and security risk.

---
## Problem Reframing & Requirements

To protect confidential data while maintaining analytical utility, the data warehouse needs:
* Strict role-based access controls to limit data exposure based on the employee's job function.
* Masking of sensitive PII without breaking underlying table structures or analytic workflows.
* Row-level restrictions so certain users only query data relevant to their specific domain.
* Centralized, immutable audit logs for security monitoring, troubleshooting, and compliance reporting.

---
## Solution & Tool Tradeoffs

The chosen solution leverages Amazon Redshift's native security capabilities alongside Amazon CloudWatch and Amazon S3. 

**Tradeoffs Considered:**
* **Native Redshift Security vs. Application-Level Security:** Enforcing Row-Level Security (RLS), Column-Level Security (CLS), and data masking directly at the database engine level ensures that data remains secure regardless of the BI tool or client querying it. This prevents unauthorized access that could occur if security was only handled at the application layer.
* **Amazon CloudWatch vs. Amazon S3 for Auditing:** CloudWatch is utilized for real-time visibility and immediate troubleshooting of user activity and connections. Amazon S3 is used in tandem to provide cost-effective, long-term, immutable storage for historical compliance audits.

---
## Architecture

<img width="1536" height="1024" alt="redshiftSecurityArchitecture" src="https://github.com/user-attachments/assets/e0f8b7de-fc7f-43af-941b-9395d576b5eb" />


- Compute: Amazon Redshift Serverless (Encrypted Endpoint)

- Storage: Amazon S3 (Audit Logs Destination)

- Monitoring & Security: Amazon CloudWatch (Connection & User Activity Logs), AWS IAM

---
## Data Assets & Schemas

The data warehouse utilizes the highly relational TICKIT dataset (users, venues, category, date, events, listings, sales). 
In this project, the schemas are heavily modified with security policies rather than structural changes:
* Specific **sensitive columns** (e.g., within the `users` table) are isolated.
* Confidential and regulated data fields are dynamically masked on the fly.

---
## Pipeline Execution Flow

The security implementation follows a strict progression of layered defenses:

1. **Audit & Encryption:** Enabled Redshift Serverless endpoint encryption and configured database audit logging to securely route logs to Amazon CloudWatch and Amazon S3.

2. **Role Provisioning:** Created and managed specific database roles and users, mapping them to the correct level of baseline access.

3. **Column-Level Security (CLS):** Used `GRANT` and `REVOKE` commands to strictly control permissions on sensitive columns for different users and roles.

4. **Row-Level Security (RLS):** Simplified and applied RLS policies to achieve fine-grained access control on confidential data rows.

5. **Dynamic Data Masking:** Configured masking policies to securely hide regulated data from unauthorized access without altering the underlying data.

6. **Audit Review:** Executed queries against the Redshift Serverless user-activity, user, and connection logs to verify security enforcement.

---
## Security & Roles

- Database Administrator: Full access; responsible for maintaining endpoints, managing IAM roles, and reviewing CloudWatch/S3 audit logs for troubleshooting.

- Restricted Roles/Users: Subject to strictly enforced Column-Level Security (cannot view specific columns), Row-Level Security (can only query specific rows), and Dynamic Data Masking (queries return obfuscated data for restricted fields).

---
## Business Outcomes & Analytical Outputs

<img width="1920" height="1080" alt="mnguniCorp-RedshiftSecurity-CloudWatchLogs" src="https://github.com/user-attachments/assets/cd28d713-6dac-48aa-bfd2-72bc8a806e96" />


- Regulatory Compliance: Successfully protected confidential and regulated data from unauthorized access using dynamic data masking and column-level restrictions, ensuring compliance with data privacy standards.

- Granular Access Control: Enabled fine-grained access controls via row-level security, ensuring that MnguniCorp employees only access the specific data necessary for their job functions.

- Enhanced Visibility: Empowered database administrators with comprehensive, query-able audit trails to instantly monitor user connections and rapidly troubleshoot security events.
