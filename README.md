# Beefing IT up for your Investor? Engagement with Open Source Communities, Innovation and Startup Funding: Evidence from GitHub
### Authors: Annamaria Conti, Christian Peukert, Maria P. Roche  
### Forthcoming in *Organization Science*

## Overview  
This repository provides the code necessary to reproduce publicly available data from GitHub and replicate the main results (tables and figures) presented in the paper. Please note that we cannot share the dataset due to the proprietary nature of some of the information from Crunchbase and Product Hunt, which we linked to GitHub data.

---

## Abstract  
We study the engagement of nascent firms with open source communities and its implications for innovation and securing funding. Linking data on 160,065 U.S. startups from Crunchbase to their activities on GitHub, we analyze the impact of GitHub engagement using difference-in-differences models in a matched sample of firms with and without GitHub activities. 

Our findings reveal a substantial increase in the likelihood of being funded following early-stage startups' engagement with open source communities. This effect is less pronounced for firms using GitHub solely for internal development. Startups developing novel technologies benefit more from open source engagement, whereas those in highly competitive environments face a potential trade-off between community engagement and appropriability. 

Using machine learning, we classify startups' GitHub technology use-cases and analyze product launch data to explore mechanisms driving these outcomes. Our findings suggest that access to external knowledge through open source communities supports startups in innovating and developing (minimum) viable products.

## Keywords  
Startups, Technology Strategy, GitHub, Machine Learning, Venture Capital  

The working paper version is available here: [https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3883936](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3883936).

---

## Repository Contents  
This repository includes:  
- SQL scripts for processing GitHub activity data.  
- Stata `.do` files to create tables and figures.  

---

### Description of `1_raw_data_Github.sql`  
This SQL script processes GitHub activity data from the `githubarchive` dataset on Google BigQuery, using a custom login matching table (`cb_match_logins`) to generate summary tables of user interactions, repository activity, and contributions.

#### Outputs  
The following tables are created:  
1. **`event_types_month_login`**: Counts of GitHub event types by month and user login.  
2. **`readme_login`**: Events involving README.md interactions by month and user login.  
3. **`repos_month_login`**: Counts of distinct repositories interacted with by month and user login.  
4. **`repo_activity`**: Repository interaction details, including event types and repository names.  
5. **`external_repo_activity`**: Counts of interactions with external repositories by event type and user login.  
6. **`external_repo_activity_detail`**: Detailed interactions with external repositories, including repository names.  
7. **`internal_repo_activity`**: Counts of interactions with internal repositories by event type and user login.  
8. **`internal_repo_activity_detail`**: Detailed interactions with internal repositories, including repository names.

#### Notes  
- **Internal repositories**: Repositories associated with the user's login or not conforming to standard naming conventions.  
- **External repositories**: Repositories not associated with the user's login and conforming to standard naming conventions.

The output tables can be downloaded as CSV files from Google BigQuery for further processing (e.g. matching with other datasets).

---

### Description of `2_analysis.do`  
This Stata script processes proprietary data, constructs variables, and performs regression analyses. The script generates the main tables and figures presented in the paper.

#### Data Processing  
The script merges and preprocesses data from Crunchbase, GitHub, and Product Hunt, generating:  
- Sectoral and geographic indicators.  
- Key variables such as GitHub engagement, product launches, market competition, and technology novelty.

#### Outputs  
- **Tables**: 1a, 2, 3a, 3b, 4, 5, 6, 7, 8, 9, 10.  
- **Figures**: 2, 3, 4, 5, 6.  

All outputs are saved as:  
- LaTeX tables (`TableX.tex`).  
- PDF figures (`FigureX.pdf`).  
