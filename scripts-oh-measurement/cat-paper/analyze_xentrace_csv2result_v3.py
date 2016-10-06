# Read the csv file that contains all overhead value
# Step 1: Filter out the interesting overhead event, i.e.,
#         do_sched, context_switch, cntext_saved
# Step 2: Sort the overhead value of each event,
#         Filter out the highest and lowest 1 percent data
# Step 3: Compute mean, median and stddev of the filtered data
#         Write statatistical data in one row into a file for each event
# 
import sys
import numpy as np
debug_mode = 0

evts_name = []
evts_name.append('oh_sched_latency')
evts_name.append('oh_context_switch')
evts_name.append('oh_context_saved')

oh_sched_dict = {}
oh_cxt_switch_dict = {}
oh_cxt_saved_dict = {}
oh_datas = []
oh_datas_filtered = []
#oh_lines = []
oh_stats = []
stats_files = [];
# initialize three lists for do_sched, context_switch, context_saved events
oh_datas.append([])
oh_datas.append([])
oh_datas.append([])
oh_datas_filtered.append([])
oh_datas_filtered.append([])
oh_datas_filtered.append([])
#oh_lines.append([])
#oh_lines.append([])
#oh_lines.append([])

def wait():
    try:
        if debug_mode >= 10:
            input("Press enter to continue")
    except SyntaxError:
        pass

def parse_csv(csv_filename):
    print(csv_filename)
    num_lines = 0
    with open(csv_filename,'r') as csv_file:
        for line in csv_file:
            cols = line.split()
            #cols[4] is type of event, cols[8] is event value
            #print(cols[4])
            if len(cols) < 9:
                continue
            if cols[4] == "oh_sched_latency":
                if oh_sched_dict.get(float(cols[8]), -1) == -1:
                    oh_sched_dict[float(cols[8])] = 1;
                else:
                    oh_sched_dict[float(cols[8])] += 1;
            elif cols[4] == "oh_context_switch" :
                if oh_cxt_switch_dict.get(float(cols[8]), -1) == -1:
                    oh_cxt_switch_dict[float(cols[8])] = 1;
                else:
                    oh_cxt_switch_dict[float(cols[8])] += 1;
            elif cols[4] == "oh_context_saved" :
                if oh_cxt_saved_dict.get(float(cols[8]), -1) == -1:
                    oh_cxt_saved_dict[float(cols[8])] = 1;
                else:
                    oh_cxt_saved_dict[float(cols[8])] += 1;
            else:
                continue;

            # map to dictionary
            #oh_lines[index].append(cols);
            #oh_datas[index].append(float(cols[8]));
            num_lines += 1;
            if num_lines % 10000000 == 0:
                print "Processed", num_lines, "lines"

def print_oh_datas(oh_datas):
    #for oh_line in oh_lines:
    #    print oh_line, "\n"
    for oh_data in oh_datas:
        print oh_data, "\n"

def sort_data(oh_datas):
    # oh_sched_latency, oh_context_switch, oh_context_saved
    oh_sched_keys = oh_sched_dict.keys();
    oh_cxt_switch_keys = oh_cxt_switch_dict.keys();
    oh_cxt_saved_keys = oh_cxt_saved_dict.keys();

    oh_sched_keys.sort();
    print "Finish sorting oh_sched keys"
    oh_cxt_switch_keys.sort();
    print "Finish sorting oh_cxt_switch keys"
    oh_cxt_saved_keys.sort();
    print "Finish sorting oh_cxt_saved keys"

    for i in range(len(oh_sched_keys)):
        val = oh_sched_dict.get(oh_sched_keys[i], -1)
        if val < 0:
            print "ERR: oh_sched_dict", oh_sched_keys[i], " should always exit"
            sys.exit(1)
        for j in range(val):
            oh_datas[0].append(oh_sched_keys[i])
    print "Finish sorting oh_sched values"

    for i in range(len(oh_cxt_switch_keys)):
        val = oh_cxt_switch_dict.get(oh_cxt_switch_keys[i], -1)
        if val < 0:
            print "ERR: oh_cxt_switch_dict", oh_cxt_switch_keys[i], " should always exit"
            sys.exit(1)
        for j in range(val):
            oh_datas[1].append(oh_cxt_switch_keys[i])
    print "Finish sorting oh_cxt_switch values"

    for i in range(len(oh_cxt_saved_keys)):
        val = oh_cxt_saved_dict.get(oh_cxt_saved_keys[i], -1)
        if val < 0:
            print "ERR: oh_cxt_saved_dict", oh_cxt_saved_keys[i], " should always exit"
            sys.exit(1)
        for j in range(val):
            oh_datas[2].append(oh_cxt_saved_keys[i])
    print "Finish sorting oh_cxt_saved values"

def remove_outlier(oh_data, oh_data_filtered):
    num_elems = len(oh_data);
    num_to_remove = num_elems / 100
    print "Remove", num_to_remove, "outliers..."
    for i in range(num_elems):
        if i < num_to_remove or i > num_elems - num_to_remove - 1:
            continue;
        oh_data_filtered.append(float(oh_data[i]));
    print "Size of new_oh_data:", len(oh_data), " size of old_oh_data:", num_elems

def filter_data(oh_datas):
    print "Filter_data..."
    size_old = [];
    size_new = [];
    for i in range(len(oh_datas)):
        size_old.append(len(oh_datas[i]));
        remove_outlier(oh_datas[i]);
        size_new.append(len(oh_datas[i]));
    for i in range(len(size_old)):
        print size_old[i], "should be >", size_new[i]

def cal_stat(oh_datas, oh_stats):
    print "Cal stat"
    for i in range(len(oh_datas)):
        print "cal_stat oh type ", i, "starts..."
        oh_data = oh_datas[i];
        oh_mean = np.mean(oh_data)
        oh_median = np.median(oh_data)
        oh_stddev = np.std(oh_data)
        oh_max = np.max(oh_data)
        oh_min = np.min(oh_data)
        oh_99percentile = np.percentile(oh_data, 99);
        oh_95percentile = np.percentile(oh_data, 95);
        oh_stats.append([oh_mean, oh_median, oh_stddev, oh_max, oh_min, oh_99percentile, oh_95percentile]);
        #oh_stats.append([oh_mean, oh_median, oh_max, oh_min, oh_99percentile, oh_95percentile]);
        print oh_stats[i]

def write_stats_to_files(oh_stats, stats_files):
    for i in range(len(oh_stats)):
        print >> stats_files[i], '#mean', '\t', 'median', '\t', 'stddev', '\t', 'max', '\t', 'min', '\t', '99percentile', '\t', '95percentile'
        print >> stats_files[i], oh_stats[i][0], '\t', oh_stats[i][1], '\t', oh_stats[i][2], '\t', oh_stats[i][3], '\t', oh_stats[i][4], '\t', oh_stats[i][5], '\t', oh_stats[i][6]
        #print >> stats_files[i], '#mean', '\t', 'median', '\t', 'max', '\t', 'min', '\t', '99percentile', '\t', '95percentile'
        #print >> stats_files[i], oh_stats[i][0], '\t', oh_stats[i][1], '\t', oh_stats[i][2], '\t', oh_stats[i][3], '\t', oh_stats[i][4], '\t', oh_stats[i][5]

        
def main():
    if len(sys.argv) < 5:
        print "./program csv_file do_sched_stat_filename cxt_switch_stat_filename cxt_saved_stat_filename"
        sys.exit(1);

    csv_filename = sys.argv[1];
    oh_do_sched_filename = sys.argv[2];
    oh_cxt_switch_filename = sys.argv[3];
    oh_cxt_saved_filename = sys.argv[4];
    
    print('csv_filename:', csv_filename)
    print('oh_do_sched_filename:', oh_do_sched_filename)
    print('oh_cxt_switch_filename:', oh_cxt_switch_filename)
    print('oh_cxt_saved_filename:', oh_cxt_saved_filename)
    stats_files.append(open(oh_do_sched_filename, 'w'));
    stats_files.append(open(oh_cxt_switch_filename, 'w'));
    stats_files.append(open(oh_cxt_saved_filename, 'w'));

    parse_csv(csv_filename);
    sort_data(oh_datas);
    #print_oh_datas(oh_datas);

    # filter data
    #filter_data(oh_datas);
    print "Filter_data..."
    size_old = [];
    size_new = [];
    for i in range(len(oh_datas)):
        size_old.append(len(oh_datas[i]));
        remove_outlier(oh_datas[i], oh_datas_filtered[i]);
        size_new.append(len(oh_datas_filtered[i]));
    for i in range(len(size_old)):
        print size_old[i], "should be >", size_new[i]
    oh_datas[0] = [];
    oh_datas[1] = [];
    oh_datas[2] = [];
    cal_stat(oh_datas_filtered, oh_stats);
    write_stats_to_files(oh_stats, stats_files);

if __name__ == "__main__":
    main()
