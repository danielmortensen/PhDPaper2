import pandas as pd
from dateutil import parser
import folium


# Creates a Folium map given a csv file and file name
def print_map(f, f_name):

    for i in range(0, len(f)):
        if str(f.iloc[i].lat) != "nan" and str(f.iloc[i].lon) != "nan":
            print(f.iloc[i].lat, f.iloc[i].lon)
            coordinates.append([f.iloc[i].lat, f.iloc[i].lon])

    folium.PolyLine(coordinates, color="Blue", weight=2.5, opacity=1).add_to(route_map)
    route_map.save("data/" + f_name + ".html")


file_name = "18151_map"     # Name for html map file
route_map = folium.Map(location=[40.764651501303995, -111.90476732021554], zoom_start=15, tiles="Stamen Toner")
coordinates = []
stop_count = 0
colors = ['red', 'blue', 'green', 'purple', 'orange', 'darkred', 'lightred', 'beige', 'darkblue', 'darkgreen',
          'cadetblue', 'darkpurple', 'white', 'pink', 'lightblue', 'lightgreen', 'gray', 'black', 'lightgray']

# Adds column names to csv and replaces None types with a string None
col_names = ["date", "route", "direction", "speed", "lat", "lon", "soc"]
file = pd.read_csv("data/bus_18151.csv", names=col_names)
file.fillna("None")

times_in_slc = []
in_slc = False          # Is bus at salt lake central?
arrival_time = None
departure_time = None

# Coordinate box around salt lake central
south_east = [40.7616862208843, -111.90804459102064]
north_east = [40.766809948780384, -111.90804459102064]
north_west = [40.766809948780384, -111.91115832194072]
south_west = [40.7616862208843, -111.91115832194072]

# Checks each value in csv
for i in range(0, len(file)):
    # Adds to coordinates list (for mapping lines)
    if str(file.iloc[i].lat) != "nan" and str(file.iloc[i].lon) != "nan":
        # print(file.iloc[i].lat, file.iloc[i].lon)
        coordinates.append([file.iloc[i].lat, file.iloc[i].lon])

    # Checks if bus has a arrived at sl central
    if file.iloc[i].direction == "TO U HOSPITAL" and file.iloc[i - 1].direction == "TO SL CENTRAL":
        print("Stop", stop_count)
        # Plots coordinates of previous route and creates new list
        # if journey_count == 1:
        folium.PolyLine(coordinates, color=colors[0], weight=2.5, opacity=1, popup="STOP" + str(stop_count) + " to STOP" + str(stop_count + 1)).add_to(route_map)
        colors.pop(0)
        coordinates = []

        arrival_time = parser.parse(file.iloc[i].date)
        print("ARRIVAL AT SLC: : " + file.iloc[i].date)
        marker_text_2 = "Stop: " + str(stop_count) + "\nDate/Time: " + str(file.iloc[i].date) + "\nSpeed: " + str(file.iloc[i].speed)
        folium.Marker([file.iloc[i].lat, file.iloc[i].lon], popup=marker_text_2, icon=folium.Icon(color="green")).add_to(route_map)

        in_slc = True
        stop_count += 1

    # Checks if bus has left sl central
    # if in_slc and float(file.iloc[i].lon) > north_east[1]:
    if in_slc and float(file.iloc[i].lon) > north_east[1]:
        print("BEFORE DEPARTURE: " + file.iloc[i-1].date)
        print("DEPARTURE: " + file.iloc[i].date)
        # print(str(file.iloc[i].lat) + "," + str(file.iloc[i].lon))
        departure_time = parser.parse(file.iloc[i].date)
        print("Total Time At Station:", departure_time - arrival_time, "\n")

        marker_text_3 = "Stop: " + str(stop_count) + "\nDate/Time: " + str(file.iloc[i - 2].date) + "\nSpeed: " + str(file.iloc[i - 2].speed)
        folium.Marker([file.iloc[i-2].lat, file.iloc[i-2].lon], popup=marker_text_3, icon=folium.Icon(color="lightred")).add_to(route_map)
        # Marks the previous coordinate just as a reference for accuracy
        marker_text_0 = "Stop: " + str(stop_count) + "\nDate/Time: " + str(file.iloc[i - 1].date) + "\nSpeed: " + str(file.iloc[i - 1].speed)
        folium.Marker([file.iloc[i-1].lat, file.iloc[i-1].lon], popup=marker_text_0, icon=folium.Icon(color="red")).add_to(route_map)
        # marker_text_1 = "Stop: " + str(journey_count) + "\nDate/Time: " + str(file.iloc[i].date) + "\nSpeed: " + str(file.iloc[i].speed)
        # folium.Marker([file.iloc[i].lat, file.iloc[i].lon], popup=marker_text_1, icon=folium.Icon(color="red")).add_to(route_map)

        in_slc = False

# Adds remaining coordinates in case route doesn't end at sl central
folium.PolyLine(coordinates, color=colors[0], weight=2.5, opacity=1, popup="STOP" + str(stop_count) + " to end of data").add_to(route_map)
route_map.save("data/" + file_name + ".html")

