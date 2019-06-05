module UserFilesHelper

  def usage_summary(total_size, allowance)
    "#{number_to_human_size(total_size)} used out of #{number_to_human_size(allowance)} allowed."
  end

end

