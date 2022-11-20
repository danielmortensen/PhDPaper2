from datetime import datetime
import xml.etree.ElementTree as ET
import requests
from datetime import datetime
from os.path import join as fullfile
from os.path import abspath
import csv
from operator import itemgetter
import concurrent.futures as thread

def extract(element, tag):
    data = next(element.iter("{http://www.siri.org.uk/siri}" + tag))
    if data is None:
        data = "NaN"
    else:
        data = data.text
    return  data

def responseToVehicleActivity(response):
    root = ET.fromstring(response.content)
    vehicleActivity = next(root.iter("{http://www.siri.org.uk/siri}VehicleActivity"))
    return vehicleActivity

def getRouteDataUtaApi(routeId):

        # request sample from UTA website
        utaApiToken= "UVEMMBLBDZJ"
        uta_api_url = f"http://api.rideuta.com/SIRI/SIRI.svc/VehicleMonitor/ByRoute?route={routeId}&onwardcalls=true&usertoken={utaApiToken}"
        response = requests.get(uta_api_url)

        # parse response and format initial dictionary
        vehicleActivity = responseToVehicleActivity(response)
        vehicleData = dict()

        # for each vehicle, extract the appropriate meta data
        for iElement, element in enumerate(vehicleActivity):
            if isFirst(iElement):
                cVehicleData = dict()
                cVehicleData["RecordTime"]       = extract(element, "RecordedAtTime")
            else:
                cVehicleData["Direction"]        = extract(element,"DirectionRef")
                cVehicleData["VehicleJourneyId"] = extract(element, "DatedVehicleJourneyRef")
                cVehicleData["Line Name"]        = extract(element, "PublishedLineName")
                cVehicleData["originId"]         = extract(element, "OriginRef")
                cVehicleData["destinationId"]    = extract(element, "DestinationRef")
                cVehicleData["longitude"]        = extract(element, "Longitude")
                cVehicleData["latitude"]         = extract(element, "Latitude")
                cVehicleData["journeyCourseId"]  = extract(element, "CourseOfJourneyRef")
                cVehicleData["vehicleId"]        = extract(element, "VehicleRef")
                cVehicleData["GPSFix"]           = extract(element, "LastGPSFix")
                cVehicleData["speed"]            = extract(element, "Speed")
                cVehicleData["DestinationName"]  = extract(element, "DestinationName")

                # save vehicle information in output dictionary
                vehicleKey = "vehicle " + cVehicleData["vehicleId"]
                vehicleData[vehicleKey] = cVehicleData
        
        return vehicleData
#                cVehicleData["stopPointId"] = element[11][0].text
#                print(f"stopPointId: " + cVehicleData["stopPointId"])
#                cVehicleData["vehicleAtStop"] = element[11][2].text
#                print(f"vehicleAtStop: " + cVehicleData["vehicleAtStop"])


def collectBatch(writePath, routeId, nPerBatch=1):

    # create file path
    startTime = datetime.now().strftime("%d-%m-%Y__%H-%M-%S")
    fileId = f"route_{routeId}_{startTime}.csv"
    filePath = fullfile(abspath(writePath), fileId)

    # open file and write one batch of data
    with open(filePath, 'w') as fileHandle:
        writer = csv.writer(fileHandle, delimiter=',')
        for iBatch in range(nPerBatch):
            data = getRouteDataUtaApi(routeId)
            for iVehicle, vehicle in enumerate(data.values()):
                if isFirst(iBatch) & isFirst(iVehicle):
                    header = list(vehicle.keys())
                    writer.writerow(header)
                dataList = itemgetter(*header)(vehicle)
                writer.writerow(dataList)
    print(f"finished file: {filePath}")
            
def isFirst(idx):
    return idx == 0

def collect(writePath, routeId, nPerBatch):
    while True:
        collectBatch(writePath, routeId, nPerBatch=nPerBatch)

def main():
    routeIds = [2, 4, 21]
    nPerBatch = 4320
    saveDir = "data_management/data/raw/"
    with thread.ThreadPoolExecutor(max_workers=len(routeIds)) as exe:
        for routeId in routeIds:
            exe.submit(collect, saveDir, routeId, nPerBatch)





if __name__ == "__main__":
    main()

