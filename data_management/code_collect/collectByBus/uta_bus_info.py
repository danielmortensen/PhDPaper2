import xml.etree.ElementTree as ET
import requests
from datetime import datetime

class Bus:
    id = None
    is_active = None

    recorded_time = None
    
    line_reference = None
    line_name = None
    direction_reference = None
    journey_reference = None

    gps_fix_time = None
    latitude = None
    longitude = None
    speed = None
    bearing = None

    def __init__(self, bus_id):
        self.id = bus_id

    def get_data_from_uta_api(self):
        uta_api_token = "UVEMMBLBDZJ"
        uta_api_url = "http://api.rideuta.com/SIRI/SIRI.svc/VehicleMonitor/ByVehicle?vehicle=" + self.id + "&onwardcalls=true&usertoken=" + uta_api_token
        response = requests.get(uta_api_url)
        root = ET.fromstring(response.content)
        vehicle_monitoring_delivery = root.find("{http://www.siri.org.uk/siri}VehicleMonitoringDelivery")
        if vehicle_monitoring_delivery is not None:
            vehicle_activity = vehicle_monitoring_delivery.find("{http://www.siri.org.uk/siri}VehicleActivity")
            if vehicle_activity is not None:
                monitored_vehicle_journey = vehicle_activity.find("{http://www.siri.org.uk/siri}MonitoredVehicleJourney")
                if monitored_vehicle_journey is not None:

                    self.is_active = "Scheduled"
                    vehicle_data = root[1][2][1]
                    # print(vehicle_data[7][1].tag, ":", vehicle_data[7][1].text)
                    self.latitude = vehicle_data[7][1].text
                    # print(vehicle_data[7][0].tag, ":", vehicle_data[7][0].text)
                    self.longitude = vehicle_data[7][0].text
                    # print(vehicle_data[0].tag, ":", vehicle_data[0].text)
                    self.line_reference = vehicle_data[0].text
                    # print(vehicle_data[3].tag, ":", vehicle_data[3].text)
                    self.line_name = vehicle_data[3].text
                    # print(vehicle_data[1].tag, ":", vehicle_data[1].text)
                    self.direction_reference = vehicle_data[1].text

                    extensions = vehicle_data.find("{http://www.siri.org.uk/siri}Extensions")
                    speed = extensions.find("{http://www.siri.org.uk/siri}Speed")
                    if speed is not None:
                        self.speed = speed.text
                    # print(speed.tag, ":", speed.text)

                    gps_time = extensions.find("{http://www.siri.org.uk/siri}LastGPSFix")
                    if gps_time is not None:
                        self.gps_fix_time = gps_time.text
                        if not '.' in self.gps_fix_time:
                            self.gps_fix_time = self.gps_fix_time + ".00"
                        self.gps_fix_time = datetime.strptime(self.gps_fix_time,"%Y-%m-%dT%H:%M:%S.%f")
                    # print(gps_time.tag, ":", gps_time.text)

                    bus_info = [self.is_active, self.gps_fix_time, self.line_reference, self.direction_reference, self.latitude, self.longitude, self.speed]
                    return bus_info

                else:
                    self.is_active = "Not scheduled"
                    return [self.is_active]
            else:
                self.is_active = "Not scheduled"
                return [self.is_active]
        else:
            self.is_active = "Not scheduled"
            return [self.is_active]







