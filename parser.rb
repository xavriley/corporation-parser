require 'parslet'
require 'pp'

class CorporationParser < Parslet::Parser

  rule(:whitespace) { match('[\s\r\n]') | str(',') | str('-') | str('(') | str(')') | str(':') | str('\"') | str('/') | str('*') | str('=') | str('>') | str('+') | str('[') | str(']') | str('_') | str('$') }
  rule(:whitespace?) { whitespace.repeat }

  rule(:special) { (special_helper >> (whitespace? >> special_helper).repeat).as(:special) }
  rule(:special_helper) { aand | corporates | initials | number }

  # and is a Ruby keyword
  rule(:aand) { str("&") | str("and") }

  rule(:number) { (number_helper >> (whitespace? >> number_helper).repeat).as(:number) }
  rule(:number_helper) { (str('no.') | str('#')).maybe >> match('[0-9]').repeat(1)  }

  rule(:initials) { ( match("[a-z]") >> str(".") ).repeat(1).as(:initials) }

  rule(:corporates) { (llc | pllc | llp | lp | incorporated | corporation | limited | company | international | association | foreign).as(:corporates) }
  rule(:association) { str("association") | str("assn.") | str("associations") | str("association's") | str("associations'") }
  rule(:international) { str("international") }
  rule(:llc)  { str("llc") | str("lc") | str("lcc") | str("llc.") }
  rule(:pllc) { str("pllc") }
  rule(:llp)  { str("llp") | str("llp.") }
  rule(:lp) {   str("lp") | str("lp.") | str("l.p.") }
  # Order is dependent in the following. The full stop version needs to be matched first
  rule(:incorporated)  { str("incorporated") | str("inc.") | str("inc") }
  rule(:corporation) { str("corps") | str("corporations") | str("corporation") | str("corp") | str("corp.") }
  rule(:limited) { str("ltd") | str("ltd.") | str("ltd..") }
  rule(:company) { str("company") | str("companies") | str("co.") }
  rule(:foreign) { str("ltda.")  }

  rule(:simple_fka) { complex_fka.absent? >> formers }
  rule(:complex_fka) { formers >> whitespace? >> fka_verbs >> (whitespace? | str("as")).maybe }
  rule(:fka_verbs) { str("registered") | str("filed") | str("reported") | str("known") | str("know") | str("field") }
  rule(:formers) { str("formerly") | str("formelry") | str("formarly") | str("frmly") | str("frly") }

  rule(:aka) { str('aka') | str('a/k/a') | str('a.k.a.') | str('also known as') }
  rule(:fka) { str('fka') | str('f/k/a') | str('f.k.a.') | str('formerly known as') | simple_fka | complex_fka }

  rule(:splitters) { fka.as(:fka) | aka.as(:aka) }

  rule(:simple) { (special | splitters | formers | initials).absent? >> match("[a-z0-9&!']").repeat(1).as(:simple) >> str('.').maybe }

  rule(:token) { simple | special }

  rule(:name) { (whitespace? >> token >> (whitespace? >> token).repeat) }

  rule(:beings) { (name.as(:company) >> (whitespace? >> splitters).maybe.as(:splitters) >> ((whitespace? >> name).maybe).as(:company_alt) ).as(:beings) }

  root(:beings)

end

pp CorporationParser.new.parse("SkyTerra Communications, Inc., formerly Mobile Satellite Ventures".downcase.strip)
