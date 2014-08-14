require 'rexml/document'

CpdDuplication.delete_all
CpdDuplicationScript.delete_all

doc = REXML::Document.new(File.read('tmp/cpd/results.xml'))
doc.elements.each('//duplication') do |dup|
	lines = dup.attribute('lines').value
	c = CpdDuplication.new({:lines => lines})
	dup.elements.each('file') do |file|
		line = file.attribute('line').value
		script_id = file.attribute('path').value.split('/').last.split('.').first
		c.cpd_duplication_scripts << CpdDuplicationScript.new({:line => line, :script_id => script_id})
	end
	c.save
end
