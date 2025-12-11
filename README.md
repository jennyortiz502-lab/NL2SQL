# Chatbot de lenguaje natural a SQL
An interactive application based on Streamlit that converts natural language questions into SQL queries using large language models (LLMs).

---
# Description
This project implements an intelligent chatbot that allows users to query MySQL databases using natural language. The application automatically translates questions into SQL, executes queries, and can return results in both table format and natural language responses.

---
# Key Features
* NL→SQL conversion: Translates natural language questions into valid SQL queries
* Multilingual Support: Supports English, Spanish, Portuguese, and French
* Multiple LLM Models: Compatible with various models from Meta, Cohere, and Mistral
* Query Self-Repair: Automatically detects and corrects SQL errors (up to 3 attempts)
* Natural Language Responses: Turn tabular results into conversational responses
* Chat Interface: Persistent Conversation History
* Schema Selection: Allows you to choose between different database schemas.
* Security: Blocks destructive operations (INSERT, UPDATE, DELETE, DROP, etc.)
* SQL visualization: Option to display generated SQL queries

# Stack to create MySQL DEMO AI

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/jennyortiz502-lab/NL2SQL/archive/refs/heads/main.zip)


### Example Table Definition

| TABLE\_NAME    | COLUMN\_NAME  | COLUMN\_TYPE       | COLUMN\_COMMENT                                                                                                    |
| -------------- | ------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------ |
| airline        | airline\_id   | smallint           | Unique identifier for each airline.                                                                                |
| airline        | iata          | char(2)            | Two-character IATA code assigned to the airline, used globally for identification.                                 |
| airline        | airlinename   | varchar(30)        | The full name of the airline.                                                                                      |
| airline        | base\_airport | smallint           | ID of the base airport for the airline, referring to the primary operational hub.                                  |
| airplane       | airplane\_id  | int                | Unique identifier for each airplane. This is the primary key and is auto-incremented.                              |
| airplane       | capacity      | mediumint unsigned | Maximum number of passengers that the airplane can accommodate.                                                    |
| airplane       | type\_id      | int                | Identifier for the airplane model/type. This is a foreign key referencing the airplane\_type table.                |
| airplane       | airline\_id   | int                | Identifier of the airline that owns or operates the airplane. This is a foreign key referencing the airline table. |
| airplane\_type | type\_id      | int                | Unique identifier for each airplane type or model.                                                                 |
| airplane\_type | identifier    | varchar(50)        | Model identifier or code for the airplane type.                                                                    |
| airplane\_type | description   | text               | Additional details or specifications about the airplane type.                                                      |
| airport        | airport\_id   | smallint           | Unique identifier for each airport.                                                                                |


---

## How the App works:
The flowchart below outlines the full workflow of how natural language queries (in any language) are processed and transformed into SQL queries to retrieve data from a database.

<img width="630" height="622" alt="image" src="https://github.com/user-attachments/assets/d66d6888-986a-4bf9-a31c-aeeac889832d" />

