
crumb :root do
  link "Fiddlybits", root_path
end

crumb :charsets do
  link "Character Sets", charsets_path
end

crumb :charset do |charset|
  link charset.human_name, url_for(controller: 'charsets', action: 'show', charset: charset.name)
  parent :charsets
end

crumb :charset_table do |charset|
  link "#{charset.human_name} Mapping Table", url_for(controller: 'charsets', action: 'show_table', charset: charset.name)
  parent :charset, charset
end

crumb :charset_decode do |charset|
  link "Decode #{charset.human_name}", url_for(controller: 'charsets', action: 'decode', charset: charset.name)
  parent :charset, charset
end
