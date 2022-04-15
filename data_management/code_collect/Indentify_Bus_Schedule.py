import pandas as pd

SLCstarttime = [(0,13),(4,13),(4,43),(5,13),(5,43),(6,13),(6,28),(6,43),(6,58),(7,13),(7,28),(7,43),(7,58),(8,13),(8,28),(8,43),(8,58),(9,13),(9,28),(9,43),(9,58)
                ,(10,13),(10,28),(10,43),(10,58),(11,13),(11,28),(11,43),(11,58),(12,13),(12,28),(12,43),(12,58),(13,13),(13,28),(13,43),(13,58),(14,13),(14,28),(14,43),(14,58)
                ,(15,13),(15,28),(15,43),(15,58),(16,13),(16,28),(16,43),(16,58),(17,13),(17,28),(17,43),(17,58),(18,13),(18,28),(18,43),(18,58),(19,13),(19,43),(20,13),(20,43)
                ,(21,13),(21,43),(22,13),(22,43),(23,13),(23,43)]


UoUhospitalstarttime = [(0,4),(0,34),(4,29),(4,59),(5,29),(6,0),(6,32),(6,47),(7,2),(7,17),(7,38),(7,53),(8,8),(8,23),(8,38),(8,53),(9,8),(9,23),(9,38),(9,53),(10,8)
                ,(10,23),(10,36),(10,51),(11,6),(11,21),(11,36),(11,51),(12,6),(12,21),(12,36),(12,51),(13,6),(13,21),(13,36),(13,51),(14,6),(14,21),(14,36),(14,51),(15,6)
                ,(15,21),(15,38),(15,53),(16,8),(16,23),(16,38),(16,53),(17,8),(17,23),(17,38),(17,53),(18,8),(18,23),(18,36),(18,51),(19,6),(19,21),(19,34),(20,4),(20,34)
                ,(21,4),(21,34),(22,4),(22,34),(23,4),(23,34)]

def helper(loc, endtime):
    if loc == 'TO U HOSPITAL':
        starttimes = UoUhospitalstarttime
    else:
        starttimes = SLCstarttime


    low = 0
    high = len(starttimes)
    resultindex = -1
    while low <= high:
        mid = low + (high - low)//2

        if endtime - 10 > (starttimes[mid][0]*60 + starttimes[mid][1]):
            resultindex = mid
            low = mid + 1
        else:
            high = mid - 1

    return starttimes[resultindex]

def startSOC(df, time):
    result = 0.0
    for i in range(0,len(df)):
        if df.iloc[i, 0] != 'None':
            date = pd.to_datetime(df.iloc[i, 0])

            if date.hour == time[0] and date.minute == time[1]:
                return df.iloc[i,6]
    return result

df = pd.read_csv('bus_18151.csv')

df = df.fillna('None')
StartLoc = None
Destination = df.iloc[0,2]
for i in range(1,len(df)):

    if df.iloc[i,2] != df.iloc[i - 1,2] :
        date = pd.to_datetime(df.iloc[i,0])
        print('From: ', StartLoc)
        starttime = helper(StartLoc, date.hour*60 + date.minute)
        print('Start time: ', starttime)
        print('Start SOC: ', startSOC(df, starttime))
        print('To : ', Destination)
        print('Reached at Destination: ', (date.hour, date.minute))
        print('End SOC: ',df.iloc[i , 6])
        print()
        StartLoc = Destination
        Destination = df.iloc[i,2]


