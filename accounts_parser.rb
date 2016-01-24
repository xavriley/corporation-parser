require 'parslet'

class AccountsParser < Parslet::Parser
  rule(:space)   { match("\s") }
  rule(:company) { (space.maybe >> match('[A-Z]') >> match('[^\s]').repeat).repeat.as(:company) } 
  rule(:wholly_owned) { ((str("immediate") | str("ultimate")) >> space >> str("parent")).as(:wholly_owned) } 
  rule(:statement) { (wholly_owned.absent? >> any).repeat >> wholly_owned >> (company.absent? >> any).repeat >> company }

  root (:statement)
end

testdoc = <<-TESTDOC
The immediate parent company is Nova Bidco Limited, a company incorporated in England and Wales.

The company's ultimate parent undertaking is Capita plc, a company incorporated in England and Wales. The
ﬁnancial statements of Capita plc are available from the registered ofﬁce at 71 Victoria Street, London SW1H OXA.
TESTDOC

puts AccountsParser.new.parse("The immediate parent is Nova Bidco Limited")
