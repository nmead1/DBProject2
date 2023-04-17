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
cur.execute('DEALLOCATE ALL;')
conn.rollback()
conn.autocommit = True

csv_path = 'C:\\Users\\mcrae\\Documents\\repos\\DB\\DBProject2\\data\\MUP_IHP_RY22_P02_V10_DY20_PrvSvc.csv'
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

    insert_states_sql = """
        PREPARE states_insert (INT, TEXT) AS
        INSERT INTO States (Rndrng_Prvdr_State_FIPS, Rndrng_Prvdr_State_Abrvtn) VALUES ($1, $2);
    """
    cur.execute(insert_states_sql)

    insert_rucas_sql = """
        PREPARE rucas_insert (FLOAT, TEXT) AS
        INSERT INTO RUCAs (Rndrng_Prvdr_RUCA, Rndrng_Prvdr_RUCA_Desc) VALUES ($1, $2);
    """
    cur.execute(insert_rucas_sql)

    insert_diagnoses_sql = """
        PREPARE diagnoses_insert (INT, TEXT) AS
        INSERT INTO Diagnoses (DRG_Cd, DRG_Desc) VALUES ($1, $2);
    """
    cur.execute(insert_diagnoses_sql)

    insert_cities_sql = """
        PREPARE cities_insert (TEXT, INT, FLOAT, INT) AS
        INSERT INTO Cities (Rndrng_Prvdr_City, Rndrng_Prvdr_Zip5, Rndrng_Prvdr_RUCA, Rndrng_Prvdr_State_FIPS) VALUES ($1, $2, $3, $4);
    """
    cur.execute(insert_cities_sql)

    insert_providers_sql = """
        PREPARE providers_insert (INT, TEXT, TEXT, TEXT, INT) AS
        INSERT INTO Providers (Rndrng_Prvdr_CCN, Rndrng_Prvdr_Org_Name, Rndrng_Prvdr_St, Rndrng_Prvdr_City, Rndrng_Prvdr_Zip5) VALUES ($1, $2, $3, $4, $5);
    """
    cur.execute(insert_providers_sql)

    insert_providerservices_sql = """
        PREPARE providerservices_insert (INT, TEXT, TEXT, INT, INT, FLOAT, FLOAT, FLOAT) AS
        INSERT INTO ProviderServices (Rndrng_Prvdr_CCN, Rndrng_Prvdr_Org_Name, Rndrng_Prvdr_St, DRG_Cd, Tot_Dschrgs, Avg_Submtd_Cvrd_Chrg, Avg_Tot_Pymt_Amt, Avg_Mdcr_Pymt_Amt)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8);
    """
    cur.execute(insert_providerservices_sql)

    cur.execute("SELECT DISTINCT CAST(Rndrng_Prvdr_State_FIPS AS INT), Rndrng_Prvdr_State_Abrvtn FROM temp_table;")
    for state_fips, state_abrv in cur.fetchall():
        cur.execute("EXECUTE states_insert (%s, %s);", (state_fips, state_abrv))

    cur.execute("SELECT DISTINCT CAST(Rndrng_Prvdr_RUCA AS FLOAT), Rndrng_Prvdr_RUCA_Desc FROM temp_table;")
    for ruca, ruca_desc in cur.fetchall():
        cur.execute("EXECUTE rucas_insert (%s, %s);", (ruca, ruca_desc))

    cur.execute("SELECT DISTINCT CAST(DRG_Cd AS INT), DRG_Desc FROM temp_table;")
    for drg_cd, drg_desc in cur.fetchall():
        cur.execute("EXECUTE diagnoses_insert (%s, %s);", (drg_cd, drg_desc))

    cur.execute("SELECT DISTINCT Rndrng_Prvdr_City, CAST(Rndrng_Prvdr_Zip5 AS INT), CAST(Rndrng_Prvdr_RUCA AS FLOAT), CAST(Rndrng_Prvdr_State_FIPS AS INT) FROM temp_table;")
    for city, zip5, ruca, state_fips in cur.fetchall():
        cur.execute("EXECUTE cities_insert (%s, %s, %s, %s);", (city, zip5, ruca, state_fips))

    cur.execute("SELECT DISTINCT CAST(Rndrng_Prvdr_CCN AS INT), Rndrng_Prvdr_Org_Name, Rndrng_Prvdr_St, Rndrng_Prvdr_City, CAST(Rndrng_Prvdr_Zip5 AS INT) FROM temp_table;")
    for ccn, org_name, st, city, zip5 in cur.fetchall():
        cur.execute("EXECUTE providers_insert (%s, %s, %s, %s, %s);", (ccn, org_name, st, city, zip5))

    cur.execute("SELECT CAST(Rndrng_Prvdr_CCN AS INT), Rndrng_Prvdr_Org_Name, Rndrng_Prvdr_St, CAST(DRG_Cd AS INT), CAST(Tot_Dschrgs AS INT), CAST(Avg_Submtd_Cvrd_Chrg AS FLOAT), CAST(Avg_Tot_Pymt_Amt AS FLOAT), CAST(Avg_Mdcr_Pymt_Amt AS FLOAT) FROM temp_table;")
    for ccn, org_name, st, drg_cd, tot_dschrgs, avg_submtd_cvrd_chrg, avg_tot_pymt_amt, avg_mdcr_pymt_amt in cur.fetchall():
        cur.execute("EXECUTE providerservices_insert (%s, %s, %s, %s, %s, %s, %s, %s);", (ccn, org_name, st, drg_cd, tot_dschrgs, avg_submtd_cvrd_chrg, avg_tot_pymt_amt, avg_mdcr_pymt_amt))

    print('Bye!')
    conn.commit()
    cur.close()
    conn.close()
