import sqlite3
from sqlite3 import Error


def create_connection(db_file):
    """ create a database connection to the SQLite database
        specified by db_file
    :param db_file: database file
    :return: Connection object or None
    """
    conn = None
    try:
        conn = sqlite3.connect(db_file)
        return conn
    except Error as e:
        print(e)

    return conn


def create_table(conn, create_table_sql):
    """ create a table from the create_table_sql statement
    :param conn: Connection object
    :param create_table_sql: a CREATE TABLE statement
    :return:
    """
    try:
        c = conn.cursor()
        c.execute(create_table_sql)
    except Error as e:
        print(e)


if __name__ == '__main__':
    database = "UTA_Bus_Tracking/bus_18153.db"

    sql_create_bus_stats_table = """ CREATE TABLE IF NOT EXISTS bus_stats (
                                        id integer PRIMARY KEY,
                                        date text,
                                        time text,
                                        latitude real,
                                        longitude real,
                                        last_gps_fix text,
                                        speed real,
                                        bearing real,
                                        journey_ref integer,
                                        line_ref text,
                                        direction_ref text

                                    ); """

    sql_create_time_at_imh_table = """CREATE TABLE IF NOT EXISTS time_at_imh (
                                    id integer PRIMARY KEY,
                                    bus_id integer,
                                    start_time text,
                                    end_time text,
                                    time_at_station real,
                                    line_ref integer,
                                    journey_ref integer
                                );"""

    conn = create_connection("UTA_Bus_Tracking/bus_18153.db")
    if conn is not None:
        # create projects table
        create_table(conn, sql_create_bus_stats_table)

        # create tasks table
        create_table(conn, sql_create_time_at_imh_table)
    else:
        print("Error! cannot create the database connection.")