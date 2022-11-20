from uta_bus_info import Bus
import csv
from time import sleep
import New_Flyer
import datetime



def main():

    bus_id = "18151"

    cur_datetime = datetime.datetime.now()
    time_fmt = r'%Y-%m-%d_%Hh%Mm%Ss'
    cur_datetime_str = cur_datetime.strftime(time_fmt)
    outfile_name = f'data/bus_{bus_id}_{cur_datetime_str}.csv'
    with open(outfile_name, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        while True:
                bus_18153 = Bus(bus_id)
                bus_18153.get_data_from_uta_api()
                bus_soc, time = New_Flyer.lastvalue("18151")
                print(bus_18153.gps_fix_time, bus_18153.line_reference, bus_18153.direction_reference, bus_18153.speed, bus_18153.latitude, bus_18153.longitude, bus_soc)
                if bus_18153.gps_fix_time is not None:
                    writer.writerow([bus_18153.gps_fix_time, bus_18153.line_reference, bus_18153.direction_reference, bus_18153.speed, bus_18153.latitude, bus_18153.longitude, bus_soc])
                    csvfile.flush()
                sleep_seconds = 5
                print(f'sleeping for {sleep_seconds}s')
                sleep(sleep_seconds)



main()

