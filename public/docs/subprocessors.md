
# Consider.it Processors

Updated: May 2025

## Hosting Regions and Data Residency

* **US Server:** AWS and Linode services are hosted in the United States, except for database backups, which are in the EU.
* **EU Server:** AWS and Linode services are hosted in the EU.
* **CA Server:** AWS and Linode services are hosted in Canada, except for database backups, which are in the EU.
* **AU Server:** AWS and Linode services are hosted in Australia, except for database backups, which are in the EU.

We aim to minimize cross-border data transfer. For our EU server, data stays within the EU unless optional features (namely Google Translate) are explicitly enabled by the forum host.

In the below subprocessor table, the jurisdiction of the subprocessor is shown for each of our respective regional servers. For example, Consider.it’s EU server is served by a Linode cloud provider residing in the EU.

## Subprocessors

We use third-party subprocessors, such as cloud computing providers and customer support software, to run Consider.it (the service). We have minimized the number of these subprocessors where possible. When we do use a subprocessor, we ensure each has a GDPR-compliant data processing agreement.

### Personal Data Subprocessors (Core Forum Service)

| Name                                                                                                              | Purpose             | US Server | EU Server | CA Server | AU Server |
| ----------------------------------------------------------------------------------------------------------------- | ------------------- | --------- | --------- | --------- | --------- |
| [Linode](https://www.linode.com/legal/)                                                                           | Cloud hosting       | US        | EU        | CA        | AU        |
| [AWS CloudFront](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/data-protection-summary.html) | CDN / Cloud hosting | US        | EU        | CA        | AU        |
| [AWS S3](https://d1.awsstatic.com/legal/aws-dpa/aws-dpa.pdf)                                                      | File storage of assets for Cloudfront        | US        | EU        | CA        | AU        |
| [AWS S3](https://d1.awsstatic.com/legal/aws-dpa/aws-dpa.pdf)                                                      | Database backup storage        | EU        | EU        | EU        | EU        |
| [AWS SES](https://docs.aws.amazon.com/ses/latest/dg/data-protection.html)                                         | Transactional email | US        | EU        | CA        | AU        |
| [Plausible](https://plausible.io/data-policy)                                                                     | Analytics           | EU        | EU        | EU        | EU        |

### Third-Party Services Activated by Forum Hosts (Not Subprocessors)

These optional services process data under their own terms and are not subprocessors of Consider.it. Forum hosts (controllers) can choose to enable or disable them.

| Name               | Purpose                   | Who Controls It?                   | US Server          | EU Server           | CA Server          | AU Server          |
| ------------------ | ------------------------- | ---------------------------------- | ------------------ | ------------------- | ------------------ | ------------------ |
| Google Translate\* | Multi-lingual translation | Forum Host (User Consent Required) | Enabled by default | Disabled by default | Enabled by default | Enabled by default |

\* Google does not provide information about which jurisdictions the servers are that will process the data sent through the Google Translate Widget.

### Personal Data Subprocessors (Customer Payment and Forum Creation)

These subprocessors are only involved when a customer creates or purchases a forum via our product page.

| Name                                     | Purpose             | US Server | EU Server | CA Server | AU Server |
| ---------------------------------------- | ------------------- | --------- | --------- | --------- | --------- |
| [Stripe](https://stripe.com/legal/dpa)   | Billing             | US        | EU        | CA        | AU        |
| [Mailgun](https://www.mailgun.com/gdpr/) | Transactional email | US        | -         | CA        | AU        |

---

## Company Processors

As a company, we use third-party software that may process your information under limited circumstances, such as customer support or voluntary contact.

| Name                                                   | Purpose                       |
| ------------------------------------------------------ | ----------------------------- |
| [Google Suite](https://cloud.google.com/security/gdpr) | Email and document management |
| [LinkedIn](https://privacy.linkedin.com/gdpr)          | Professional networking       |
| [Zoom](https://zoom.us/gdpr)                           | Video conferencing            |
| [Facebook](https://www.facebook.com/business/gdpr)     | Social media                  |

These services are used only when you choose to contact or interact with us via these channels.