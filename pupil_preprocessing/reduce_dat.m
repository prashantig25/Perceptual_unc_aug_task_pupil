filename_dat = '4672_m1.EDF.dat';
data = importdata(filename_dat);
[data_table] = conv2table(data);

del = [];
for i = 1:height(data_table)
    if data_table.time_stamp(i) > 5355264 || data_table.time_stamp(i) < 5686010
        del = [del;i];
    end
end

find(data_table.time_stamp > 5355264) || data_table.time_stamp < 5686010 == 1)