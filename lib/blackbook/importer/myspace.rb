require 'blackbook/importer/page_scraper'

# Imports contacts from Myspace 

class Blackbook::Importer::Myspace < Blackbook::Importer::PageScraper

  def login
    page = agent.get('http://www.myspace.com/')
    form = page.forms[1]
    form['ctl00$ctl00$cpMain$cpMain$LoginBox$Email_Textbox'] = options[:username]
    form['ctl00$ctl00$cpMain$cpMain$LoginBox$Password_Textbox'] = options[:password]
    page = agent.submit(form,form.buttons.first)

    # Check if redirected to homepage 
    raise( Blackbook::BadCredentialsError, "That username and password was not accepted. Please check them and try again." ) if page.uri.to_s!='http://home.myspace.com/index.cfm?fuseaction=home'
  end

 
  def prepare
    agent.user_agent = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008100716 Firefox/3.0.3"
    login
  end 

  def scrape_contacts
    contacts = []
    page = agent.get('http://messaging.myspace.com/index.cfm?fuseaction=mail.addressbookV3')

    # Lets find the hash for the ajax request
    javascripts = page.parser.xpath("//script[@type='text/javascript']")

    js_with_page_hash = (javascripts.select {|j| j.to_s =~ /MySpace.Messaging.pageHash/})[0]

    page_hash = js_with_page_hash.to_s.split()[5].gsub(/"|;/,'')

    # Lets get the contacts Json

    page = agent.post("http://messaging.myspace.com/Modules/Invites/Services/AddressBookService.asmx/GetAddresBookContacts","{'hash':'#{page_hash}', 'jsonParams':{'pageOffset':0, 'fetchLimit':2000}}", 'Content-Type' => 'application/json; charset=utf-8')

    json = Blackbook.json_decode(page.body)

    json["Data"]["items"].each do |c|
      contacts << {:name => c['name']['contactFullName'], 
                   :email => c['email']}
    end
 
#    contacts.compact
    contacts
  end

  # Register Myspace with blackbook
  Blackbook.register(:myspace, self)

end
