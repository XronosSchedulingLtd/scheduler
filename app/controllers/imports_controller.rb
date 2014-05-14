class ImportsController < ApplicationController

  IMPORT_DIR = 'staging'

  #
  #  Provide an index of the stuff currently uploaded and the option
  #  to upload something else.
  #
  def index
    @files = Dir.entries(Rails.root.join(IMPORT_DIR)) - [".", ".."]
  end

  #
  #  Receive an incoming file.
  #
  def upload
    uploaded_io = params[:incoming]
    if uploaded_io
      File.open(Rails.root.join(IMPORT_DIR,
                                uploaded_io.original_filename), 'wb') do |file|
        file.write(uploaded_io.read)
      end
    end
    redirect_to imports_path
  end

  #
  #  Delete an individual file.
  #
  def destroy
#    raise params.inspect
    name = params[:name]
    #
    #  Although we only provide links to valid files, it's possible someone
    #  could spoof a request to include directory navigation.  Strip the
    #  name down to its leaf part only.
    #
    if name
      name = File.basename(name)
      File.unlink(Rails.root.join(IMPORT_DIR, name))
    end
    redirect_to imports_path
  end
end
