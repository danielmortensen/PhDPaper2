from gc import collect
import BusDataCollector as BDC
import csv
import concurrent.futures as thread
from os.path import join as fullfile

def collect_data(bus_id, bus_type, basename, n_collect_per_file, n_collect=None):
    data_gen = BDC.BusDataCollector(bus_id, bus_type)

    if n_collect:
        for iFile  in range(n_collect):
            single_collect(data_gen, basename, iFile, n_collect_per_file)
    else:
        iFile = 0
        while True:
            single_collect(data_gen, basename, iFile, n_collect_per_file)    
            iFile = iFile + 1

def single_collect(data_gen, basename, iFile, n_collect_per_file):
    file_name = basename + "_" + str(iFile) + '.csv' 
    print("starting file: " + file_name)
    with open(file_name, 'w') as csv_file:
        writer = csv.writer(csv_file, delimiter=',')
        writer.writerow(['Bus ID','SOC','Lat','Lon','Time'])
        file_data = []
        for iCollect in range(int(n_collect_per_file)):
            data = data_gen.collect_data()
            file_data = file_data + data
            print('collect number: ',iCollect)
        print("finished collect, writing file: " + file_name)
        writer.writerows(file_data)


def main():
    bus_ids = [
        [18151],
        [18152],
        [18153],
        [18151, 18152, 18153, 15023],
        [15002, 15003, 15004, 15005, 15006], [15007, 15008, 15009, 15010, 15011], 
        [15012, 15013, 15014, 15015, 15016], [15017, 15018, 15019, 15020, 15021]
        ]
    bus_types = [
        1*['electric'] + 0*['diesal'],
        1*['electric'] + 0*['diesal'],
        1*['electric'] + 0*['diesal'],
        0*['electric'] + 4*['diesal'],
        0*['electric'] + 5*['diesal'], 0*['electric'] + 5*['diesal'],
        0*['electric'] + 5*['diesal'], 0*['electric'] + 5*['diesal']
        ]
    base_path = '../data/collects/bus_data_22'
    basenames = [
        fullfile(base_path,'18151_New_Flyer'),
        fullfile(base_path,'18152_New_Flyer'),
        fullfile(base_path,'18153_New_Flyer'),
        fullfile(base_path,'18151_18152_18153_15023'),
        fullfile(base_path,'15002_15003_15004_15005_15006'), fullfile(base_path,'15007_15008_15009_15010_15011'),
        fullfile(base_path,'15012_15013_15014_15015_15016'), fullfile(base_path,'15017_15018_15019_15020_15021')
        ]
    n_collect_per_file = 4320
    #for bus_id, bus_type, basename in zip(bus_ids, bus_types, basenames):
    #    collect_data(bus_id, bus_type, basename, n_collect_per_file, 1) 
    with thread.ThreadPoolExecutor(max_workers=len(bus_ids)) as exe:
        for bus_id, bus_type, basename in zip(bus_ids, bus_types, basenames):
            exe.submit(collect_data,bus_id, bus_type, basename, n_collect_per_file)

if __name__ == '__main__':
    main()

