function data = read_spiral(filename)
data = load(filename);
FieldNames = fieldnames(data);
data = data.(FieldNames{1});
end

