Security Practices at Consider.it
===================================
Updated: May 2025

* We will never (and have never) sold customer data to third parties. We have a straightforward relationship with Forum Hosts where they may pay us to host a Consider.it forum on their behalf. This allows us to be stringent on minimizing the data we collect from you. 
* We don't run ads, and only use cookie-less privacy-first analytics. This means that intrusive tracking of you is absent in Consider.it. 
* Our services, running on secure cloud-hosted servers, have many security measures in place to protect your data and prevent unauthorized access. We routinely conduct internal security audits.
* We try to minimize access to your data, with the exception of supporting the resolution of a problem with the system. 
* We treat all customer information and data as confidential, except for situations where a customer has explicitly made the information publicly accessible.
* Data is backed up in multiple ways, daily, and stored in multiple locations.
* We have independent regional servers in the United States, European Union, and Canada. Hosts can choose the regional server to use to help reduce cross-border data transfers.
* You can track the status of Consider.it's services at [https://status.consider.it](https://status.consider.it).


The information below gives more details about our technical and organizational security measures. The information is formatted to address the requirements set out by the EU's stringent data protection law, the General Data Protection Regulation (GDPR). Furthermore, this information is incorporated into our [Data Processing Addendum](/docs/legal/data_processing_addendum), which is in effect when the GDPR applies to your use of Consider.it. Even if your use is not covered under the GDPR, we seek to live up to those standards.


<table><tbody>
  <tr>
    <td><strong>Measure</strong></td>
    <td><strong>Description</strong></td>
  </tr><tr>
    <td>Measures of pseudonymisation and encryption of Personal Data</td>
    <td>
      <ul>
        <li>Employee laptops are encrypted using full disk AES-256 encryption.</li>
        <li>HTTPS encryption on every web interface, using industry standard algorithms and certificates.</li>
        <li>Secure transmission of all traffic, internal and external, using by default TLS 1.2 or better.</li>
        <li>Access to operational environments via SSH enabled only with public-private RSA keys.</li>
        <li>Database backups are stored in AWS S3 and encrypted using AES-256 via SSE-S3 (server-side encryption with Amazon S3-managed keys).</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td>Measures for ensuring ongoing confidentiality, integrity, availability and resilience of processing systems and services</td>
    <td>On our Linode servers, Consider.it uses vulnerability assessment, automatic security patching, and threat protection technologies, along with a defense-in-depth approach to harden systems and detect malicious activity. All unnecessary incoming ports are blocked by default, and authentication ports are configured off standard defaults. Suspicious traffic patterns are automatically identified and blocked, with IP banning and alerting based on both anomaly detection and request analysis. Real-time virus and rootkit detection tools are active at all times, and periodic self-audits help maintain configuration integrity and surface potential weaknesses before they become exploitable.
    <p style="margin-top: 12px">Consider.it also uses <a href="https://betteruptime.com/">Better Uptime</a> to track service uptime and alert us if a particular system fails. We also employ Better Uptime’s heartbeat monitors for making sure offline processing services continue to function, like email notification runners and database backups. Anyone can see the current status of Consider.it servers at any time by visiting <a href="https://status.consider.it">status.consider.it</a>. In addition, consider.it generates email alerts for application errors (e.g. if the database connection is dropped).</p>
    </td></tr>
  <tr>    
    <td>Measures for ensuring the ability to restore the availability and access to Personal Data in a timely manner in the event of a physical or technical incident</td>
    <td>
      In the case of a physical or technical incident, Consider.it has multiple sources of backups to restore personal data from. Specifically: <ul style="margin-top: 12px;">
        <li>Consider.it is hosted in the cloud on <a href="https://linode.com">Linode</a> servers. Linode makes backup images of the entire server daily and stores them securely on a different Linode server. These backup images can be used to restore data and services in the case of catastrophic failure.</li> 
        <li>The Consider.it server creates database backups every four hours, stores them on Amazon AWS S3 (encrypted in transit and at rest), and deletes them from the Consider.it server after transmission. These database backups can be used to restore data in the case of database failure or corruption.</li>
      </ul>
    </td></tr>
  <tr>    
    <td>Processes for regularly testing, assessing and evaluating the effectiveness of technical and organisational measures in order to ensure the security of the processing</td>
    <td>
    <ul>
      <li>Internal comprehensive security audits are conducted quarterly.</li>
      <li>System access logs are maintained for at least one year to facilitate investigations if necessary.</li>
      <li>Regular vulnerability scans and configuration scans are run at least quarterly, with any findings addressed within identified timeframes based on severity.</li>
      <li>Static Analysis tools are used to identify security flaws during the development of       software.</li>
    </ul>
    </td></tr>
  <tr>    
    <td>Measures for user identification and authorisation</td>
    <td>
    <ul>
      <li>Access to operational and production servers is only facilitated through the Secure Shell Protocol (SSH) using public-key cryptography. Password-based login is disabled. All access attempts, successful and unsuccessful are logged and examined by automated processes for suspicious patterns.</li>
      <li>Login to cloud service provider accounts is protected by two-factor authentication.</li>
      <li>Authentication of users in Consider.it itself is facilitated through email and password. Only certain accounts are authorized as hosts of Consider.it forums, and those accounts are protected via password.</li>
    </ul>
    </td></tr>
  <tr>    
    <td>Measures for the protection of data during transmission</td>
    <td>Data in transit is protected by Transport Layer Security (“TLS”) 1.2 or greater.</td></tr>
  <tr>    
    <td>Measures for the protection of data during storage</td>
    <td>
    <ul>
      <li>Personal Data retained internally on our Linode servers are protected via the access control measures for our operational and production servers described earlier. All production instances additionally have endpoint security software (e.g. aggressive firewall, malicious actor detection, automated banning of suspicious activity) which is monitored for unusual or problematic activity. Measures are in place to ensure unauthorized actors are not permitted to access unauthorized data. System inputs are recorded via log files.</li>
      <li> Backups of Personal Data stored by our subprocessors (Linode and AWS) are encrypted at rest and covered by their respective certifications. Backups are encrypted during transmission to these subprocessors.</li>
    </ul>
    </td>
    </tr>
  <tr>    
    <td>Measures for ensuring physical security of locations at which Personal Data are processed</td>
    <td>The Processor utilises third party data centres that maintain current ISO 27001 certifications and/or SSAE 16 SOC 1 Type II or SOC 2 Attestation Reports. The Processor will not utilise third party data centres that do not maintain the aforementioned certifications and/or attestations, or other substantially similar or equivalent certifications and/or attestations.</td></tr>
  <tr>    
    <td>Measures for ensuring events logging</td>
    <td>System inputs are recorded in the form of log files therefore it is possible to review retroactively whether and by whom Personal Data was entered, altered or deleted. Logs are rotated and deleted, so there is a limit to how far back in history we can look.</td></tr>
  <tr>    
    <td>Measures for ensuring system configuration, including default configuration</td>
    <td>System configuration is applied and maintained by software tools that ensure the system configurations do not deviate from the specifications.
  </td></tr>
  <tr>    
    <td>Measures for internal IT and IT security governance and management</td>
    <td>Employees are instructed to collect, process and use Personal Data only within the framework and for the purposes of their duties (e.g. service provision). At a technical level, there is appropriate separation of testing and production systems. A quarterly internal security audit is carried out to review code and logs and to validate existing procedures.
    </td></tr>
  <tr>    
    <td>Measures for certification/assurance of processes and products</td>
    <td>The Processor utilises third party data centres and cloud computing services that maintain current ISO 27001 certifications and/or SSAE 16 SOC 1 Type II or SOC 2 Attestation Reports. The Processor will not utilise third party data centres that do not maintain the aforementioned certifications and/or attestations, or other substantially similar or equivalent certifications and/or attestations. 
      <br><br>
      Consider.it itself does not maintain a security certification of its processes and products, but will cooperate with the Controller (upon written request, and no more than once in any 12 month period), to carry out a third-party security audit and/or certification at Controller's expense. Any audit report submitted to the Controller shall be treated as Confidential Information and subject to the confidentiality provisions of the Agreement between the parties</td></tr>
  <tr>    
    <td>Measures for ensuring data minimisation</td>
    <td>
    <ul>
      <li>Data collection is limited to the purposes of processing, or the data that the controller chooses to ask for and which a data subject chooses to provide.</li>
      <li>Security measures are in place to provide only the minimum amount of access necessary to
      perform required functions.</li>
    </ul>
    </td></tr>
  <tr>    
    <td>Measures for ensuring data quality</td>
    <td>
    <ul>
      <li>Consider.it has a process that allows individuals to exercise their privacy rights (including a right to <a href="/docs/legal/deleting_your_data">amend and update information</a>), as described in Consider.it's <a href="/docs/legal/privacy_policy">Privacy Policy</a>.</li>
      <li>Before deploying new application code to production environments, we thoroughly test the new functionality.</li>
      <li>If application errors are identified through further testing or automated error reporting, we address the problem and assess its impact. To the extent possible, we reach out to affected participants to give them an opportunity to address any problems with their data that may have originated from the error.</li>
    </ul>
    </td></tr>
  <tr>    
    <td>Measures for ensuring limited data retention</td>
    <td>
    <p>Controllers may request deletion of all data, including Personal Data, relating to a Consider.it forum, at any time. Data subjects may request deletion of all of their Personal Data, at any time. These data deletion requests are promptly (and usually immediately) honored. It should be noted that with these deletions, Personal Data may remain in the database backups and logs until they are rotated out of storage.</p>
      <p style="margin-top:12px">Database backups are rotated and retained individually for no more than 6 months. System and application log files are rotated and retained individually for no more than one year. Our retention policy with these backups and logs is a balance between security analysis & ensuring data quality, and data retention.</p>
    </ul>
    </td></tr>
  <tr>    
    <td>Measures for ensuring accountability</td>
    <td>
    <ul>
      <li>All employees that handle sensitive data must acknowledge the information security policies.</li>
      <li>Data protection impact assessments are part of any new processing initiative.</li>
      <li>When working with a Controller who wishes to instruct Consider.it to collect potentially sensitive Personal Data, we encourage them to conduct a data protection impact assessment.</li>
    </ul>
    </td></tr>
  <tr>    
    <td>Measures for allowing data portability and ensuring erasure</td>
    <td>Controllers may request deletion of all data relating to a Consider.it forum, including Personal Data, at any time. Data subjects may request deletion of all of their Personal Data, at any time. These data deletion requests are promptly (and usually immediately) honored. The Services have built-in tools that allows a data subject to permanently erase their data. Data subjects may also request an export of their Personal Data. 
    </td></tr>
  <tr>    
    <td>Measures to be taken by the (Sub-) processor to be able to provide assistance to the Controller (and, for transfers from a Processor to a Sub-processor, to the Data Exporter).</td>
    <td>The technical and organizational measures that the data importer will impose on sub-processors are described in the <a href="/docs/legal/data_processing_addendum">Data Processing Addendum</a>.</td></tr>
  </tbody>
</table>
