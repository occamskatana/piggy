require 'webrick'
require 'webrick/httpproxy'
require 'nokogiri'
require 'open-uri'

root = File.expand_path('../test/index.html')


server = WEBrick::HTTPProxyServer.new(Port: 3000, DocumentRoot: root)

def translate(sent)
  sent = sent.downcase
  vowels = ['a', 'e', 'i', 'o', 'u']
  words = sent.split(' ')
  result = []

  words.each_with_index do |word, i|
    translation = ''
    qu = false
    if vowels.include? word[0]
      translation = word + 'ay'
      result.push(translation)
    else
      word = word.split('')
      count = 0
      word.each_with_index do |char, index|
        if vowels.include? char
          if char == 'u' and translation[-1] == 'q'
            qu = true
            translation = words[i][count + 1..words[i].length] + translation + 'uay'
            result.push(translation)
            next
          end
          break
        else
          if char == 'q' and word[i+1] == 'u'
            qu = true
            translation = words[i][count + 2..words[i].length] + 'quay'
            result.push(translation)
            next
          else
            translation += char
          end
          count += 1
        end
      end
      if not qu
        translation = words[i][count..words[i].length] + translation + 'ay'
        result.push(translation)
      end
    end

  end
  result.join(' ')
end

server.mount_proc '/' do |req, res|
  query = req.query["target"].to_s

  html_doc = Nokogiri::HTML(open("http://#{query}"))

  html_doc.at_css("body").traverse do |node|
    if node.text?
      node.content = translate(node.content)
    end
  end

  links = html_doc.css("a")
  links.each do |link|
    href = link["href"]
    new_href = "http://localhost:3000/?target=#{href}"
    link.attributes["href"].value = new_href
  end

  res.body = "#{html_doc}"

end


trap 'INT' do server.shutdown end

server.start
