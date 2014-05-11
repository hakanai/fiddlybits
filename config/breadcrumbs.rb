
crumb :root do
  link "Fiddlybits", root_path
end

crumb :about do
  link "About", url_for(controller: 'welcome', action: 'about')
end

crumb :encodings do
  link "Binary Encodings", url_for(controller: 'encodings', action: 'index')
end

crumb :encoding do |encoding|
  link encoding.human_name, url_for(controller: 'encodings', action: 'show', id: encoding.name)
  parent :encodings
end

crumb :encoding_decode do |encoding|
  link "Decode #{encoding.human_name}"
  parent :encoding, encoding
end

crumb :encoding_encode do |encoding|
  link "Encode #{encoding.human_name}"
  parent :encoding, encoding
end

crumb :charsets do
  link "Character Sets", url_for(controller: 'charsets', action: 'index')
end

crumb :charset do |charset|
  link charset.human_name, url_for(controller: 'charsets', action: 'show', id: charset.name)
  parent :charsets
end

crumb :charset_table do |charset|
  link "#{charset.human_name} Mapping Table", url_for(controller: 'charsets', action: 'show_table', id: charset.name)
  parent :charset, charset
end

crumb :charset_decode do |charset|
  link "Decode #{charset.human_name}", url_for(controller: 'charsets', action: 'decode', id: charset.name)
  parent :charset, charset
end
