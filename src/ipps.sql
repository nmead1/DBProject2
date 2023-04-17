-- CS3810: Principles of Database Systems
-- Instructor: Thyago Mota
-- Student(s): Nathan Mead and Mitchell Thompson
-- Description: IPPS database

DROP DATABASE ipps;

CREATE DATABASE ipps;

\c ipps

-- create tables

CREATE TABLE States (
    Rndrng_Prvdr_State_FIPS INT PRIMARY KEY,
    Rndrng_Prvdr_State_Abrvtn CHAR(2) NOT NULL
);

CREATE TABLE RUCAs (
    Rndrng_Prvdr_RUCA FLOAT PRIMARY KEY,
    Rndrng_Prvdr_RUCA_Desc VARCHAR(100) NOT NULL
);

CREATE TABLE Diagnoses (
    DRG_Cd INT PRIMARY KEY,
    DRG_Desc VARCHAR(100) NOT NULL
);

CREATE TABLE Cities (
    Rndrng_Prvdr_City VARCHAR(20),
    Rndrng_Prvdr_Zip5 INT,
    Rndrng_Prvdr_RUCA FLOAT,
    Rndrng_Prvdr_State_FIPS INT,
    PRIMARY KEY(Rndrng_Prvdr_City, Rndrng_Prvdr_Zip5),
    FOREIGN KEY (Rndrng_Prvdr_RUCA) REFERENCES RUCAs(Rndrng_Prvdr_RUCA),
    FOREIGN KEY (Rndrng_Prvdr_State_FIPS) REFERENCES States(Rndrng_Prvdr_State_FIPS)
);

CREATE TABLE Providers (
    Rndrng_Prvdr_CCN INT,
    Rndrng_Prvdr_Org_Name VARCHAR(55) NOT NULL,
    Rndrng_Prvdr_St VARCHAR(45),
    Rndrng_Prvdr_City VARCHAR(20),
    Rndrng_Prvdr_Zip5 INT,
    FOREIGN KEY (Rndrng_Prvdr_City, Rndrng_Prvdr_Zip5) REFERENCES Cities(Rndrng_Prvdr_City, Rndrng_Prvdr_Zip5),
    PRIMARY KEY(Rndrng_Prvdr_CCN, Rndrng_Prvdr_Org_Name, Rndrng_Prvdr_St)
);

CREATE TABLE ProviderServices (
    Rndrng_Prvdr_CCN INT,
    Rndrng_Prvdr_Org_Name VARCHAR(55) NOT NULL,
    Rndrng_Prvdr_St VARCHAR(45),
    DRG_Cd INT,
    Tot_Dschrgs INT,
    Avg_Submtd_Cvrd_Chrg FLOAT,
    Avg_Tot_Pymt_Amt FLOAT,
    Avg_Mdcr_Pymt_Amt FLOAT,
    FOREIGN KEY (Rndrng_Prvdr_CCN, Rndrng_Prvdr_Org_Name, Rndrng_Prvdr_St) REFERENCES Providers(Rndrng_Prvdr_CCN, Rndrng_Prvdr_Org_Name, Rndrng_Prvdr_St),
    FOREIGN KEY (DRG_Cd) REFERENCES Diagnoses(DRG_Cd),
    PRIMARY KEY(Rndrng_Prvdr_CCN, DRG_Cd, Tot_Dschrgs)
);

-- create user with appropriate access to the tables

CREATE USER "ipps" PASSWORD '135791';

GRANT ALL ON TABLE States TO "ipps";
GRANT ALL ON TABLE RUCAs TO "ipps";
GRANT ALL ON TABLE Diagnoses TO "ipps";
GRANT ALL ON TABLE Cities TO "ipps";
GRANT ALL ON TABLE Providers TO "ipps";
GRANT ALL ON TABLE ProviderServices TO "ipps";

-- queries

-- a) List all diagnosis in alphabetical order.   

SELECT * FROM Diagnoses
ORDER BY DRG_Desc;

-- b) List the names and correspondent states (including Washington D.C.) of all of the providers in alphabetical order (state first, provider name next, no repetition). 

SELECT Rndrng_Prvdr_State_Abrvtn, Rndrng_Prvdr_Org_Name FROM Providers
NATURAL JOIN CITIES
NATURAL JOIN States
ORDER BY Rndrng_Prvdr_Org_Name;

-- c) List the total number of providers.

SELECT COUNT(*) FROM Providers;

-- d) List the total number of providers per state (including Washington D.C.) in alphabetical order (also printing out the state).  

SELECT Rndrng_Prvdr_State_Abrvtn, COUNT(Rndrng_Prvdr_Org_Name) as providerCount FROM Providers
NATURAL JOIN Cities
NATURAL JOIN States
GROUP BY Rndrng_Prvdr_State_Abrvtn
ORDER BY Rndrng_Prvdr_State_Abrvtn;

-- e) List the providers names in Denver (CO) or in Lakewood (CO) in alphabetical order  

SELECT Rndrng_Prvdr_Org_Name FROM Providers
NATURAL JOIN Cities
WHERE Rndrng_Prvdr_City IN ('Denver', 'Lakewood')
ORDER BY Rndrng_Prvdr_Org_Name;

-- f) List the number of providers per RUCA code (showing the code and description)

SELECT Rndrng_Prvdr_RUCA, Rndrng_Prvdr_RUCA_Desc, COUNT(Rndrng_Prvdr_Org_Name) as providerCount FROM RUCAs
NATURAL JOIN CITIES
NATURAL JOIN Providers
GROUP BY Rndrng_Prvdr_RUCA, Rndrng_Prvdr_RUCA_Desc
ORDER BY Rndrng_Prvdr_RUCA;

-- g) Show the DRG description for code 308 

SELECT DRG_Desc FROM Diagnoses
WHERE DRG_Cd = 308;

-- h) List the top 10 providers (with their correspondent state) that charged (as described in Avg_Submtd_Cvrd_Chrg) the most for the DRG code 308. Output should display the provider name, their city, state, and the average charged amount in descending order.   

SELECT Rndrng_Prvdr_Org_Name, Rndrng_Prvdr_City, Rndrng_Prvdr_State_Abrvtn, Avg_Submtd_Cvrd_Chrg FROM Providers
NATURAL JOIN Cities
NATURAL JOIN states
NATURAL JOIN ProviderServices
WHERE DRG_Cd = 308
ORDER BY Avg_Submtd_Cvrd_Chrg DESC
LIMIT 10;

-- i) List the average charges (as described in Avg_Submtd_Cvrd_Chrg) of all providers per state for the DRG code 308. Output should display the state and the average charged amount per state in descending order (of the charged amount) using only two decimals. 

SELECT Rndrng_Prvdr_State_Abrvtn, ROUND(CAST(AVG(Avg_Submtd_Cvrd_Chrg) AS NUMERIC), 2) AS AverageCharges FROM Providers
NATURAL JOIN States
NATURAL JOIN ProviderServices
WHERE DRG_Cd = 308
GROUP BY Rndrng_Prvdr_State_Abrvtn
ORDER BY AverageCharges DESC;

-- j) Which provider and clinical condition pair had the highest difference between the amount charged (as described in Avg_Submtd_Cvrd_Chrg) and the amount covered by Medicare only (as described in Avg_Mdcr_Pymt_Amt)?

SELECT Rndrng_Prvdr_Org_Name, DRG_Desc FROM Providers
NATURAL JOIN ProviderServices
NATURAL JOIN Diagnoses
ORDER BY (Avg_Submtd_Cvrd_Chrg - Avg_Mdcr_Pymt_Amt) DESC
LIMIT 1;