from cmath import isnan, nan
import New_Flyer
import uta_bus_info
import numpy as np
from pytz import timezone


class BusDataCollector:
    def __init__(self, bus_id, bus_type):
        self.bus_id = bus_id
        self.n_bus = len(bus_id)
        self.bus_type = bus_type
        self.buses = self.n_bus*[0]
        for iId, (curr_bus_id, curr_type) in enumerate(zip(self.bus_id, self.bus_type)):
            if not self.is_electric(curr_type):
                self.buses[iId] = uta_bus_info.Bus(str(curr_bus_id))

    def collect_data(self):
        n_data = 4
        data = []
        for iId, (curr_bus_id, curr_type) in enumerate(zip(self.bus_id, self.bus_type)):
            if self.is_electric(curr_type):
                soc, lat, lon, time = New_Flyer.lastvaluewithloc(curr_bus_id)

            else:
                vehicle_data = self.buses[iId].get_data_from_uta_api()
                soc = nan 
                if len(vehicle_data) <5:
                    lat = nan
                    lon = nan
                    time = nan
                else:
                    lat = vehicle_data[4]
                    lon = vehicle_data[5]
                    time = vehicle_data[1]

            # format and prepare for export
            if isinstance(lat, str):
                data.append([self.bus_id[iId], soc, lat, lon, time.strftime("%Y-%m-%d %H:%M:%S")])
        
        return data

    @staticmethod
    def is_electric(bus_type):
        return bus_type == 'electric'

