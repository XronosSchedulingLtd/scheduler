#
#  The documentation for Jbuilder is seriously bad.  One crucial
#  fact which it is really useful to know - methods with an
#  exclamation mark at the end are pre-defined and do something
#  specific.  E.g. json.array! says "Create an array".
#
#  Methods without a ! are created on the fly and create a hash
#  entry with the given name.  E.g. json.array creates {'array': ...}
#
#  I could have saved myself a lot of experimentation if the documentation
#  had mentioned that really basic fact somewhere.
#
json.allow_upload @allow_upload
json.total_size   @total_size
json.allowance    @allowance
json.files do
  json.array!(@user_files) do |user_file|
    json.extract! user_file, :id, :original_file_name, :nanoid
  end
end

