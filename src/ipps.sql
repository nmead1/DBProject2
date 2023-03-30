-- CS3810: Principles of Database Systems
-- Instructor: Thyago Mota
-- Student(s): 
-- Description: IPPS database

DROP DATABASE ipps;

CREATE DATABASE ipps;

\c ipps

-- create tables

CREATE TABLE ProviderServices (
    Rndrng_Prvdr_CCN INT(6),
    DRG_Cd INT,
    FOREIGN KEY (Rndrng_Prvdr_CCN) REFERENCES Services(Rndrng_Prvdr_CCN),
    FOREIGN KEY (DRG_Cd) REFERENCES Services(DRG_Cd),
    PRIMARY KEY(Rndrng_Prvdr_CCN, DRG_Cd)
);

CREATE TABLE Providers (
    Rndrng_Prvdr_CCN INT PRIMARY KEY,
    Rndrng_Prvdr_Org_Name VARCHAR(55) NOT NULL,
    Rndrng_Prvdr_St VARCHAR(45),
    Rndrng_Prvdr_City VARCHAR(20),
    Rndrng_Prvdr_Zip5 INT,
    Rndrng_Prvdr_RUCA INT,
    FOREIGN KEY (Rndrng_Prvdr_City) REFERENCES Cities(Rndrng_Prvdr_City),
    FOREIGN KEY (Rndrng_Prvdr_Zip5) REFERENCES Cities(Rndrng_Prvdr_Zip5),
    FOREIGN KEY (Rndrng_Prvdr_RUCA) REFERENCES RUCAs(Rndrng_Prvdr_RUCA)
);

CREATE TABLE Cities (
    Rndrng_Prvdr_City VARCHAR(20),
    Rndrng_Prvdr_Zip5 INT,
    Rndrng_Prvdr_State_FIPS INT,
    PRIMARY KEY(Rndrng_Prvdr_City, Rndrng_Prvdr_Zip5),
    FOREIGN KEY (Rndrng_Prvdr_State_FIPS) REFERENCES States(Rndrng_Prvdr_State_FIPS)
);

CREATE TABLE States (
    Rndrng_Prvdr_State_FIPS INT PRIMARY KEY,
    Rndrng_Prvdr_State_Abrvtn CHAR(2) NOT NULL
);

CREATE TABLE RUCAs (
    Rndrng_Prvdr_RUCA INT PRIMARY KEY,
    Rndrng_Prvdr_RUCA_Desc VARCHAR(100) NOT NULL
);

CREATE TABLE Services (
    DRG_Cd INT PRIMARY KEY,
    DRG_Desc VARCHAR(100) NOT NULL,
    Tot_Dschrgs INT,
    Avg_Submtd_Cvrd_Chrg FLOAT,
    Avg_Tot_Pymt_Amt FLOAT,
    Avg_Mdcr_Pymt_Amt FLOAT
);

-- create user with appropriate access to the tables

-- queries

-- a) List all diagnosis in alphabetical order.    

-- b) List the names and correspondent states (including Washington D.C.) of all of the providers in alphabetical order (state first, provider name next, no repetition). 

-- c) List the total number of providers.

-- d) List the total number of providers per state (including Washington D.C.) in alphabetical order (also printing out the state).  

-- e) List the providers names in Denver (CO) or in Lakewood (CO) in alphabetical order  

-- f) List the number of providers per RUCA code (showing the code and description)

-- g) Show the DRG description for code 308 

-- h) List the top 10 providers (with their correspondent state) that charged (as described in Avg_Submtd_Cvrd_Chrg) the most for the DRG code 308. Output should display the provider name, their city, state, and the average charged amount in descending order.   

-- i) List the average charges (as described in Avg_Submtd_Cvrd_Chrg) of all providers per state for the DRG code 308. Output should display the state and the average charged amount per state in descending order (of the charged amount) using only two decimals. 

-- j) Which provider and clinical condition pair had the highest difference between the amount charged (as described in Avg_Submtd_Cvrd_Chrg) and the amount covered by Medicare only (as described in Avg_Mdcr_Pymt_Amt)?
