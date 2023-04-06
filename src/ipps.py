"""
CS3810: Principles of Database Systems
Instructor: Thyago Mota
Student(s): Nathan Mead and Mitchell Thompson
Description: A data load script for the IPPS database
"""
import csv
import psycopg2
import configparser as cp

config = cp.RawConfigParser()
config.read('ConfigFile.properties')
params = dict(config.items('db'))

conn = psycopg2.connect(**params)
cur = conn.cursor()
conn.autocommit = True

csv_path = 'C:\\Users\\mcrae\\Documents\\repos\\DB\\DBProject2\\build\\data\\MUP_IHP_RY22_P02_V10_DY20_PrvSvc.csv'
temp_table_name = 'temp_table'

if conn: 
    print('Connection to Postgres database ' + params['dbname'] + ' was successful!')

    with open(csv_path, "r") as f:
        reader = csv.reader(f)
        headers = next(reader)  # get column headers
        columns = [f"{header} text" for header in headers]  # create column definitions
        create_table_sql = f"CREATE TEMPORARY TABLE {temp_table_name} ({', '.join(columns)});"
        cur.execute(create_table_sql)

    with open(csv_path, "r") as f:
        cur.copy_expert(f"COPY {temp_table_name} FROM STDIN WITH (FORMAT csv, HEADER true)", f)

    cur.execute("""
        INSERT INTO States (Rndrng_Prvdr_State_FIPS, Rndrng_Prvdr_State_Abrvtn)
        SELECT DISTINCT CAST(Rndrng_Prvdr_State_FIPS AS INT), Rndrng_Prvdr_State_Abrvtn
        FROM temp_table;
    """)

    cur.execute("""
        INSERT INTO RUCAs (Rndrng_Prvdr_RUCA, Rndrng_Prvdr_RUCA_Desc)
        SELECT DISTINCT CAST(Rndrng_Prvdr_RUCA AS FLOAT), Rndrng_Prvdr_RUCA_Desc
        FROM temp_table;
    """)

    cur.execute("""
        INSERT INTO Diagnoses (DRG_Cd, DRG_Desc)
        SELECT DISTINCT CAST(DRG_Cd AS INT), DRG_Desc
        FROM temp_table;
    """)

    cur.execute("""
        INSERT INTO Cities (Rndrng_Prvdr_City, Rndrng_Prvdr_Zip5, Rndrng_Prvdr_RUCA, Rndrng_Prvdr_State_FIPS)
        SELECT DISTINCT Rndrng_Prvdr_City, CAST(Rndrng_Prvdr_Zip5 AS INT), CAST(Rndrng_Prvdr_RUCA AS FLOAT), CAST(Rndrng_Prvdr_State_FIPS AS INT)
        FROM temp_table;
    """)

    cur.execute("""
        INSERT INTO Providers (Rndrng_Prvdr_CCN, Rndrng_Prvdr_Org_Name, Rndrng_Prvdr_St, Rndrng_Prvdr_City, Rndrng_Prvdr_Zip5)
        SELECT DISTINCT CAST(Rndrng_Prvdr_CCN AS INT), Rndrng_Prvdr_Org_Name, Rndrng_Prvdr_St, Rndrng_Prvdr_City, CAST(Rndrng_Prvdr_Zip5 AS INT)
        FROM temp_table;
    """)

    cur.execute("""
        INSERT INTO ProviderServices (Rndrng_Prvdr_CCN, Rndrng_Prvdr_Org_Name, Rndrng_Prvdr_St, DRG_Cd, Tot_Dschrgs, Avg_Submtd_Cvrd_Chrg, Avg_Tot_Pymt_Amt, Avg_Mdcr_Pymt_Amt)
        SELECT DISTINCT CAST(Rndrng_Prvdr_CCN AS INT), Rndrng_Prvdr_Org_Name, Rndrng_Prvdr_St, CAST(DRG_Cd AS INT), CAST(Tot_Dschrgs AS INT), CAST(Avg_Submtd_Cvrd_Chrg AS FLOAT), CAST(Avg_Tot_Pymt_Amt AS FLOAT), CAST(Avg_Mdcr_Pymt_Amt AS FLOAT)
        FROM temp_table;
    """)

    print('Bye!')
    conn.commit()
    cur.close()
    conn.close()