%This is just a wrapper to solve an issue explained in hfo_annotate.py, will be removed soon.

function process_batch_json()

    fname = 'batch_input.json'; 
    fid = fopen(fname); 
    raw = fread(fid,inf); 
    str = char(raw'); 
    fclose(fid); 
    val = jsondecode(str);
    process_batch(val{1}, val{2}, val{3}, val{4});
end
