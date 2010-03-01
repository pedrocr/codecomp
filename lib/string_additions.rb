class String
  def startswith?(str)
    self[0..str.size-1] == str
  end
  def endswith?(str)
    self[-str.size..-1] == str
  end
end

