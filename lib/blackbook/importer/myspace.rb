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
    raise( Blackbook::BadCredentialsError, "That username and password was not accepted. Please check them and try again." ) if page.uri.to_s!='http://home.myspace.com/index.cfm?fuseaction=user'
  end

 
  def prepare
    agent.user_agent = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008100716 Firefox/3.0.3"
    login
  end 

  def scrape_contacts
    page = agent.get('http://messaging.myspace.com/index.cfm?fuseaction=adb')
    contact_rows = page.search("input[@class='myContacts']/../..")
    script = page.search("//scripts")[35]
    start_index = page.body.index('hashJsonContacts.add') + 26
    end_index   = page.body.index('MySpace.BeaconData') - 1
    contacts = page.body[start_index..end_index].split(/\n/)
    contacts.collect do |contact|
      name = "" 
      email = ""
      contact_fields = contacts[0].gsub(/[\\\{\"\']/,'').split(',')
      contact_fields.each do |c|
        key,value = c.split(':')
        if key and value
          name << value if key == "FirstName"
          name << " #{value}" if key == "LastName"
          email = value if key == "Email"          
        end       
      end
      {:email=>email,:name=>name}
    end.compact
  end

  # Register Myspace with blackbook
  Blackbook.register(:myspace, self)

end
