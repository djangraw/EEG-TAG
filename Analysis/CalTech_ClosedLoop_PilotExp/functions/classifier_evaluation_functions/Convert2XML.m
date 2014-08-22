%%%
%%%This function takes an XML structure and converts it to an actual XML
%%%file that is compatable with the Python and other software we've been
%%%using for chipping and analyzing images
%%%
%%%Last modified April 2009, EAP

function [output] = Convert2XML(XMLstruct,filename)

output = 0;

%%%
%%%First create the text file to which you will write all the information
[fid] = createTextfile(filename);

%%%
%%%Write the opening line
fprintf(fid,'<object_detection_result>\n');
%%%
%%%Write the header lines
header_names = fieldnames(XMLstruct);
header_names = header_names(1:end-1);
for k=1:size(header_names,1)
    %%%extract the value(s) for this header
    value = getfield(XMLstruct,header_names{k});
    if iscell(value)
        for q=1:size(value,2)
            %%%Opening header label
            fprintf(fid,'<%s>',header_names{k});
            %%%Write the Value
            fprintf(fid,'%s',value{q});
            %%%Closing node label
            fprintf(fid,'</%s>\n',header_names{k});
        end
    else
        %%%Opening header label
        fprintf(fid,'<%s>',header_names{k});
        %%%Write the Value
        fprintf(fid,'%s',value);
        %%%Closing node label
        fprintf(fid,'</%s>\n',header_names{k});
    end
    clear value
end  

%%%
%%%Quantity of data entries/nodes in the XML structure
numNodes = length(XMLstruct.object_info);
%%%These are the values contained in each node
Node_names = fieldnames(XMLstruct.object_info{1});
for q=1:numNodes
    fprintf(fid,'<object_info idx="%s">\n',int2str(q-1));
    for k=1:size(Node_names,1)
        %%%Opening node label
        fprintf(fid,'<%s>',Node_names{k});
        %%%Value
        value = getfield(XMLstruct.object_info{q},Node_names{k});
        fprintf(fid,'%s',value);
        %%%Closing node label
        fprintf(fid,'</%s>\n',Node_names{k});
        %%%
        clear value
    end
    fprintf(fid,'</object_info>\n');
end

%%%Write the closing line
fprintf(fid,'</object_detection_result>\n');

%%%Close the file
fclose(fid);





