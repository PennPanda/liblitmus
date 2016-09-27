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

oh_datas = []
oh_lines = []
oh_stats = []
stats_files = [];
# initialize three lists for do_sched, context_switch, context_saved events
oh_datas.append([])
oh_datas.append([])
oh_datas.append([])
oh_lines.append([])
oh_lines.append([])
oh_lines.append([])

def wait():
    try:
        if debug_mode >= 10:
            input("Press enter to continue")
    except SyntaxError:
        pass

def parse_csv(csv_filename):
    print(csv_filename)
    with open(csv_filename,'r') as csv_file:
        for line in csv_file:
            cols = line.split()
            #cols[4] is type of event, cols[8] is event value
            #print(cols[4])
            if len(cols) < 9:
                continue
            index = 0
            for evt_name in evts_name:
                #print "cols[4]", cols[4]
                #print evt_name
                if evt_name == cols[4]:
                    #print('Find line:', cols)
                    break;
                index += 1;
            if index == len(evts_name):
                # this line not match any interesting event
                continue;
            oh_lines[index].append(cols);
            oh_datas[index].append(float(cols[8]));
            #print "-", oh_lines[index], "\n"
            #print "=", oh_datas[index], "\n"
            #wait();
            #print(cols[4], cols[8]);

def print_oh_datas(oh_lines, oh_datas):
    #for oh_line in oh_lines:
    #    print oh_line, "\n"
    for oh_data in oh_datas:
        print oh_data, "\n"

def sort_data(oh_datas):
    for i in range(len(oh_datas)):
        oh_datas[i].sort(key=int);

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
    for i in range(len(oh_datas)):
        size_old.append(len(oh_datas[i]));
        remove_outlier(oh_datas[i]);
        size_new.append(len(oh_datas[i]));
    for i in range(len(size_old)):
        print size_old[i], "should be >", size_new[i]

def cal_stat(oh_datas, oh_stats):
    for i in range(len(oh_datas)):
        oh_data = oh_datas[i];
        oh_mean = np.mean(oh_data)
        oh_median = np.median(oh_data)
        oh_stddev = np.std(oh_data)
        oh_max = np.max(oh_data)
        oh_min = np.min(oh_data)
        oh_99percentile = np.percentile(oh_data, 99);
        oh_95percentile = np.percentile(oh_data, 95);
        oh_stats.append([oh_mean, oh_median, oh_stddev, oh_max, oh_min, oh_99percentile, oh_95percentile]);
        print oh_stats[i]

def write_stats_to_files(oh_stats, stats_files):
    for i in range(len(oh_stats)):
        print >> stats_files[i], '#mean', '\t', 'median', '\t', 'stddev', '\t', 'max', '\t', 'min', '\t', '99percentile', '\t', '95percentile'
        print >> stats_files[i], oh_stats[i][0], '\t', oh_stats[i][1], '\t', oh_stats[i][2], '\t', oh_stats[i][3], '\t', oh_stats[i][4], '\t', oh_stats[i][5], '\t', oh_stats[i][6]

        
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
    #print_oh_datas(oh_lines, oh_datas);
    filter_data(oh_datas);
    cal_stat(oh_datas, oh_stats);
    write_stats_to_files(oh_stats, stats_files);

if __name__ == "__main__":
    main()
