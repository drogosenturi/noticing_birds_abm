import csv
from os import listdir

def clean_csv(file):
    found_patches = False
    cleaned_lines = []

    with open(file, 'r') as f:
        csvFile = csv.reader(f)
        for line in csvFile:
            if line == ['PATCHES']:
                found_patches = True
                print(found_patches)
                continue

            if found_patches:
                if line == ['LINKS']:
                    break
                cleaned_lines.append(line)
    
    index = file.find('/tick')
    name = file[index:100]
    path = file[0:index + 1] + 'clean' + name
    with open(path, 'w') as f:
        writer = csv.writer(f)
        writer.writerows(cleaned_lines)

path = "/home/sokui/netlogo_models/experiments_9-9/results/"

for f in listdir(path):
    if f.endswith('.csv'):
        clean_csv(path + f)
