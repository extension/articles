class Factiod
  def self.find_random
    factoid = "The Cooperative Extension Service was formalized in 1914."
    f = Regexp.new('<li>(.*?)</li>', Regexp::MULTILINE)
    facts_article = Article.find_by_title_url("Cooperative_Extension_Factoids")
    facts = Array.new
    facts_article.content.gsub(f) { |m| facts.push($1)} if facts_article
    factoid = facts[(facts.length*rand).to_i] if not facts.empty?
    return factoid
  end
end