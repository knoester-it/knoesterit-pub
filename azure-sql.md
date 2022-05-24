---
summary: Er zijn verschillende oplossingen binnen Azure beschikbaar om MsSQL
  databases aan te kunnen bieden. Dit is een vergelijking met een advies wanneer
  je welke oplossing toepast.
draft: false
authors:
  - admin
lastmod: 2020-12-13T00:00:00.000Z
title: Azure SQL onderzoek
subtitle: Welcome 👋
date: 2021-01-30T16:48:09.088Z
featured: true
tags:
  - Azure
categories:
  - MsSQL
projects: [project]
image:
  caption: "Image credit: [**Microsoft**](https://www.microsoft.com/)"
  focal_point: ""
  placement: 2
  preview_only: true
---
## Azure SQL onderzoek

## Doel en aanpak onderzoek
Er zijn verschillende oplossingen binnen Azure beschikbaar om MsSQL databases aan te kunnen bieden.

Om een keuze te maken welke het geïmplementeerd zou kunnen worden is hieronder een tabel met daarin een aantal globale vergelijkingen. Er zijn veel meer opties en keuzes bij het implementeren van een gekozen oplossing, dat is een vervolgstap wanneer je het gaat implementeren.

| Beschikbare opties | SQL databases | SQL managed instances | SQL virtual machines |
|----|----|----|----|
| Best toepasbaar voor | {{<figure library="true" src="azure_sql/sql-db.png" title="Azure SQL Database">}} | {{<figure library="true" src="azure_sql/sql-managed-instance.png" title="Azure SQL Managed Instance">}} | {{<figure library="true" src="azure_sql/sql-vm.png" title="Azure SQL VM">}} |

| Beschikbare opties | SQL databases | SQL managed instances | SQL virtual machines |
|----|----|----|----|
| Sales pitch | De 'evergreen' databaseservice is altijd up-to-date, met AI-aangedreven en geautomatiseerde functies waarmee de prestaties en duurzaamheid voor u worden geoptimaliseerd. Met serverloze berekening en Hyperscale-opslagopties worden resources automatisch op aanvraag geschaald, zodat u zich kunt richten op het bouwen van nieuwe toepassingen zonder dat u zich zorgen hoeft te maken over de opslaggrootte of het resourcebeheer. | <p>'U beschikt altijd over de nieuwste versie van SQL'<br/> Is gebaseerd op de SQL Server-engine. \\ Is een evergreen; Dit betekent dat het altijd up-to-date is met de nieuwste SQL-functies en -functionaliteit. U hoeft zich nooit meer zorgen te maken over updates, upgrades of het einde van de ondersteuning.</p> | Migrate SQL Server workloads to the cloud at the lowest TCO (ten opzichte van andere cloud providers). <BR> <BR>Promise of the cloud & OS control. |
| Functionele vraag/challange | Klant wil moderne apps maken (SaaS applicaties), potentiële multi-tenanted applicaties, met de hoogste uptime en voorspelbare performance. | Klant wil migreren naar de cloud, beheerlast reduceren, maar nog wel de behoefte aan instance-scoped features (SQL Server Agent, Service broker, CLR..). | Klant wil z.s.m. naar de cloud maar met behoud van de OS control en complete SQL server functionaliteit. Ook als er 3rd party applicaties zijn die toegang benodigd hebben tot het OS van de SQL server. |
| Beheerlast | Serverless, DBA beheer nog steeds van toepassing. | Serverless, DBA beheer nog steeds van toepassing. | OS en DBA beheer |
| Versionless* | Yes | Yes | No |
| Soort oplossing | PaaS | SQL instance met PaaS management capability | IaaS |
| Beheer interfaces | SQL Management Studio, Azure Data Studio, Command-line (Azure CLI, Azure Powershell) & REST API | SQL Management Studio, Azure Data Studio, Command-line (Azure CLI, Azure Powershell) & REST API | SQL Management Studio, Azure Data Studio, Command-line (Azure CLI, Azure Powershell) |
| Backup retentie | Policy Driven Default 0-35 dagen (tot 10 jaar met Long-term backup retention) | Policy Driven Default 0-35 dagen (tot 10 jaar met Long-term backup retention (in preview)<BR><BR><font size="1">'You can use SQL Agent jobs to schedule copy-only database backups as an alternative to LTR beyond 35 days.' | Policy Driven Backup retention for years |
| Encrypted Backup | All new databases in Azure SQL are configured with TDE enabled by default. | All new databases in Azure SQL are configured with TDE enabled by default. | Afhankelijk van instellingen |
| Backup command | No, only system-initiated automatic backups | Yes, user initiated copy-only backups to Azure Blob storage (automatic system backups can't be initiated by user) | Yes |
| Restore | point-in-time | point-in-time | point-in-time |
| Storage | Algemene Azure Storage redundantie en locatie van toepassing | Algemene Azure Storage redundantie en locatie van toepassing | Algemene Azure Storage redundantie en locatie van toepassing |
| Performance | vCore based and DTU (Database Transaction Unit) | vCore Based !! Azure SQL Managed Instance does not support a DTU-based purchasing model. | Performance Guidelines |
| SLA | 99,995 % beschikbaarheid | 99,99 % beschikbaarheid | Afhankelijk van inrichting bij geen gebruik van domain joined machines kan er geen always-on worden toegepast) |
| Opmerking | Voor veel leveranciers is dit nog niet van toepassing, maar het is wel de meest schaalbare optie voorzien van de nieuwste technieken en ontzorging van OS beheer. | Lijkt op een reguliere SQL server met alleen geen RDP toegang. | Wanneer je onder druk staat om naar de cloud te gaan (bijvoorbeeld wanneer hardware support afloopt). Of als je zo snel mogelijk naar de cloud wilt en geen grote applicatieve aanpassingen wilt maken. |

<font size="2">Versionless*</font><BR>
<font size="1">Versionless SQL is an additional significant difference between IaaS and PaaS. Unlike IaaS, which is tied to a specific SQL Server version, like SQL Server 2019, SQL Database and SQL Managed Instance are versionless. The main "branch" of the SQL Server engine codebase powers SQL Server 2019, SQL Database, and SQL Managed Instance. Although SQL Server versions come out every few years, PaaS services allow Microsoft to continually update SQL databases/instances. Microsoft rolls out fixes and features as appropriate. As a consumer of the service, you don't have control over these updates, and the result of @@VERSION won't line up to a specific SQL Server version. But versionless SQL allows for worry-free patching for both the underlying OS and SQL Server and for Microsoft to give you the latest bits.</font>


Zie voor meer informatie over het uitrollen en migraties de <a href="/courses/azure_sql/">learn</a> documentatie.
