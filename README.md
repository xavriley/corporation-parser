# Porting Echelon Corporation Parser to Parslet

Sunlight labs recently built a tool called Echelon to examine companies named in US lobbying forms.

[You can read the blog post here](http://sunlightfoundation.com/blog/2014/09/16/wrangling-messy-political-data-into-usable-information/)

The part that parses company names into normalised forms is actually a very small part of the code.
It uses the Clojure library instaparse which works on the following grammar:

```
beings = <whitespace>* name  (<whitespace>+ splitters <whitespace>+ name)* <whitespace>*
name   = token (<whitespace>+ token)* ["."*]

(*TODO: What to do about missing spaces. How smart can this parser actually get?*)
<token>   = simple | special

(*TODO: why does formers have to included here? It feels odd, perhaps the two negative lookups in simple and then splitters cancel out and formers get lost somehow*) 
<simple>  = !(special | splitters | formers | initials) #"[a-z0-9&!'/]+" ["."]

<special> = &(special-helper whitespace) special-helper
<special-helper> = and | corporates | domain | initials | north-america | number | saint | usa

and = "&" | "and" 

corporates = llc | pllc | llp | lp | incorporated | corporation | limited | company | international | association | foreign 
association = "association" | "assn." | "associations" | "association's" | "associations'"
international = "international"
llc  = "llc" | "lc" | "lcc" | "llc."
pllc = "pllc"
llp  = "llp" | "llp."
lp =   "lp" | "lp." | "l.p."
incorporated  = "incorporated" | "inc" | "inc."
corporation = "corps" | "corporations" | "corporation" | "corp" | "corp."
limited = "ltd" | "ltd." | "ltd.."
company = "company" | "companies" | "co."
foreign = "ltda." 

initials = !(usa | north-america | splitters | corporates) initial+ 
initial = #"[a-z]" "."
domain = #'[a-z0-9]+' <"."> ("com" | "org" | "us" | "net")
north-america = "north america" | "n.a." | "north american"
number = &(number-helper whitespace) number-helper
<number-helper> = <["no." | "#"]> [<whitespace>] some-digits
<some-digits> = (digit | two-digits | three-digits) {"," three-digits} {digit}
<two-digits> = digit digit
<three-digits> = digit digit digit 
<digit> = #"[0-9]"
saint = "st." | "saint" | "saints"
usa = &("u.s." whitespace) "u.s." | &("u.s.a" whitespace) "u.s.a" | &("u.s.a." whitespace) "u.s.a."


splitters = fka  | aka
fka = "fka" | "f.k.a." | "f/k/a/" |  simple-fka  | complex-fka
<simple-fka>  = !complex-fka formers
<complex-fka> = formers <whitespace> fka-verbs [<whitespace> "as"]
<formers> = "formerly" | "formelry" | "formarly" | "frmly" | "frly"
<fka-verbs> = "registered" | "filed" | "reported" | "known" | "know" | "field"

aka = "a/k/a" | "a.k.a." | "also known as"

whitespace = ' ' | ',' | '-' | '(' | ')' | ':' | #'$' | '\"' | '/' | '*' | '=' | '>' | '+' | '[' | ']' | '_' | '$'
```

## Notes on Echelon

The parser works on small specific strings that come from forms like this one

https://github.com/influence-usa/lobbying_federal_domestic/wiki/House-Data-Dictionary

on these fields in particular

```
lobbying/client/name
lobbying/foreign-entity/name
lobbying/registrant/name
lobbying/affiliated-organization/name
```

## Using Ruby's Parslet

I've had a go at porting this grammar to the Ruby library parslet. Some resources to learn parslet:

  * http://kschiess.github.io/parslet/parser.html
  * https://github.com/kschiess/parslet
  * http://florianhanke.com/blog/2011/02/01/parslet-intro.html
  * https://translate.google.co.uk/translate?sl=auto&tl=en&js=y&prev=\_t&hl=en&ie=UTF-8&u=http%3A%2F%2Fseanchas116.hatenablog.com%2Fentry%2F2013%2F08%2F23%2F214424&edit-text=&act=url
  * http://seanchas116.hatenablog.com/entry/2013/08/23/214424

I've not ported every single aspect of the echelon parser so I don't take account of 'USA' or 'saint' or grouping digits in names.

You can run the parser like so:

```bash
$ cd this/folder
$ bundle install
$ bundle exec ruby parser.rb
```

Which shows that "SkyTerra Communications, Inc., formerly Mobile Satellite Ventures" gets turned into

```ruby
{:beings=>
  {:company=>
    [{:simple=>"skyterra"@0},
     {:simple=>"communications"@9},
     {:special=>{:corporates=>"inc."@25}}],
   :splitters=>{:fka=>"formerly"@31},
   :company_alt=>
    [{:simple=>"mobile"@40},
     {:simple=>"satellite"@47},
     {:simple=>"ventures"@57}]}}
```
