# Read the csv file that contains all overhead value of LITMUS
# Step 1: Read all value from all domU files
# Step 2: Calculate the statistic value
import sys
import numpy as np
debug_mode = 0

oh_data = []
oh_stat = []
input_filenames = []

def wait():
    try:
        if debug_mode >= 10:
            input("Press enter to continue")
    except SyntaxError:
        pass

def append_csv(oh_data, csv_filename):
    print(csv_filename)
    with open(csv_filename,'r') as csv_file:
        for line in csv_file:
            cols = line.split()
            #cols[2] is overhead value
            #print(cols[4])
            if len(cols) < 3:
                continue
            #print cols[2], "\n"
            oh_data.append(float(cols[2]));

def sort_data(oh_data):
    oh_data.sort(key=float);

def remove_outlier(oh_data):
    num_elems = len(oh_data);
    num_to_remove = num_elems / 100
    for i in range(len(oh_data)):
        if i <= num_to_remove:
            del oh_data[0];
            del oh_data[len(oh_data)-1]
    print "size of new_oh_data:", len(oh_data), " size of old_oh_data:", num_elems

def filter_data(oh_datas):
    size_old = [];
    size_new = [];
    size_old.append(len(oh_data));
    remove_outlier(oh_data);
    size_new.append(len(oh_data));
    print size_old[0], "should be >", size_new[0]

def cal_stat(oh_data, oh_stat):
    oh_mean = np.mean(oh_data)
    oh_median = np.median(oh_data)
    oh_stddev = np.std(oh_data)
    oh_max = np.max(oh_data)
    oh_min = np.min(oh_data)
    oh_99percentile = np.percentile(oh_data, 99);
    oh_95percentile = np.percentile(oh_data, 95);
    oh_stat.append(oh_mean);
    oh_stat.append(oh_median);
    oh_stat.append(oh_stddev);
    oh_stat.append(oh_max);
    oh_stat.append(oh_min);
    oh_stat.append(oh_99percentile);
    oh_stat.append(oh_95percentile);
    print oh_stat

def write_stats_to_files(oh_stat, stats_file):
    print >> stats_file, '#mean', '\t', 'median', '\t', 'stddev', '\t', 'max', '\t', 'min', '\t', '99percentile', '\t', '95percentile'
    print >> stats_file, oh_stat[0], '\t', oh_stat[1], '\t', oh_stat[2], '\t', oh_stat[3], '\t', oh_stat[4], '\t', oh_stat[5], '\t', oh_stat[6]

        
def main():
    if len(sys.argv) < 4:
        print "./program num_input_files input_files_name1...input_files_namen output_file_name"
        sys.exit(1);
    num_input_files = int(sys.argv[1]);
    for i in range(num_input_files):
        input_filenames.append(sys.argv[2+i]);
        print input_filenames[i]
    output_filename = sys.argv[1+num_input_files+1]
    output_file = open(output_filename, 'w');
    
    for i in range(num_input_files):
        append_csv(oh_data, input_filenames[i]);
    sort_data(oh_data);
    filter_data(oh_data);
    cal_stat(oh_data, oh_stat);
    write_stats_to_files(oh_stat, output_file);

if __name__ == "__main__":
    main()
