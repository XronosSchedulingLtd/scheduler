IMPORT_DIR = 'import'

class MIS_Loader

  def prepare(options)
    Nokogiri::XML(File.open(Rails.root.join(IMPORT_DIR, "data.xml")))
  end

end
