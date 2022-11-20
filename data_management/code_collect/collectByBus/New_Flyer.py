import requests as rq
import json
from datetime import datetime,timedelta
# import xlsxwriter
# import matplotlib.pyplot as plt
# import matplotlib.dates as mdates
# import numpy as np
# import pandas as pd


url = "https://api-il.traffilog.com/appengine_3/5E1DCD81-5138-4A35-B271-E33D71FFFFD9/1/json"

user_name = "UTAH_API"

password = "H1T54YfberoTFJG76bT2FVjsHT_FisoleYkndy4"


def login( url = url, login_name  = user_name, login_pass = password):
    loginRequestJson = {
        "action": {
            "name": "user_login",
            "parameters": {
                "login_name": login_name,
                "password": login_pass
            }
        }
    }
    loginRequest = rq.post(url, data=json.dumps(loginRequestJson),
                           headers={"Content-Type": "application/x-www-form-urlencoded"})

    sessionToken = ''
    if (loginRequest.ok):
        loginData = json.loads(loginRequest.content)

        sessionToken = loginData["response"]["properties"]["data"][0]["session_token"]

    return sessionToken



def lastvalue(license_nmbr: int, url = url):
    '''

    :param license_nmbr: Take an int or string license number
    :return: return the status of the Bus with the specific license number

    In the background it will call the new flyer API and collect the data and process them into necessary format.
    '''

    sessionToken = login()
    if sessionToken != '':
        vehicleRequestJson = {
        "action": {
            "name": "get_parameters",
            "parameters": [{
                "vehicle_id": "",
                "license_nmbr": str(license_nmbr),
                "version": ""
            }],
            "session_token": sessionToken
        }
    }

    vehicleRequest = rq.post(url, data=json.dumps(vehicleRequestJson),
                             headers={"Content-Type": "application/x-www-form-urlencoded"})

    if (vehicleRequest.ok):

        vehicleData = json.loads(vehicleRequest.content)

        vehicleList = vehicleData["response"]["properties"]["data"]
        for i in range(0, len(vehicleList)):
            # print(vehicleList[i]['parameter_type_description'])

            if vehicleList[i]['parameter_type_description'] == 'NF%20XPAND_SYS_SOC%20(PGN%3A%2065349)':
                SOC = vehicleList[i]['last_input_value']
                time = vehicleList[i]['last_input_time'].replace('%3A', ':')
                time = datetime.strptime(time, "%Y-%m-%dT%H:%M:%S")
    return SOC, time




def lastvaluewithloc(license_nmbr: int, url = url):
    '''

    :param license_nmbr: Take an int or string license number
    :return: return the status of the Bus with the specific license number

    In the background it will call the new flyer API and collect the data and process them into necessary format.
    '''

    sessionToken = login()
    if sessionToken != '':
        vehicleRequestJson = {
        "action": {
            "name": "get_parameters",
            "parameters": [{
                "vehicle_id": "",
                "license_nmbr": str(license_nmbr),
                "version": ""
            }],
            "session_token": sessionToken
        }
    }

    vehicleRequest = rq.post(url, data=json.dumps(vehicleRequestJson),
                             headers={"Content-Type": "application/x-www-form-urlencoded"})

    if (vehicleRequest.ok):

        vehicleData = json.loads(vehicleRequest.content)

        vehicleList = vehicleData["response"]["properties"]["data"]
#        for data in vehicleList:
#            if "GPS" in data['parameter_type_description']:
#                print(data)

        for i in range(0, len(vehicleList)):
            # print('description: ',vehicleList[i]['parameter_type_description'])
            if vehicleList[i]['parameter_type_description'] == 'NF%20XPAND_SYS_SOC%20(PGN%3A%2065349)':#'NF%20XPAND_SYS_SOC%20(PGN%3A%2065350)':
                SOC = vehicleList[i]['last_input_value']
                time = vehicleList[i]['last_input_time'].replace('%3A', ':')
                time = datetime.strptime(time, "%Y-%m-%dT%H:%M:%S")

            elif vehicleList[i]['parameter_type_description'] == 'GPS_Lat': #'GPS%20LAT':
                LAT = vehicleList[i]['last_input_value']

            elif vehicleList[i]['parameter_type_description'] == 'GPS_Lon': #'GPS%20LON':
                LON = vehicleList[i]['last_input_value']

    return SOC, LAT, LON, time


