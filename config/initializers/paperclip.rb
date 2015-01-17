# "file" command doesn't support mime type, this is a work around
Paperclip.options[:content_type_mappings] = {
	png: 'image/png',
	gif: 'image/gif',
	jpg: 'image/jpg'
}
