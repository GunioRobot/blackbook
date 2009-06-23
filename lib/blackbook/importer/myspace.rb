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
    contacts = []
    page = agent.get('http://messaging.myspace.com/index.cfm?fuseaction=adb')

    total_email = page.search("//div[@class='pagingLeft']").inner_html.split().last.to_i
    total_pages = total_email/15 
    total_pages +=1 if (total_email%15 > 0)
    current_page = 1

    while(current_page <= total_pages)
      start_index = page.body.index('hashJsonContacts.add') + 26
      end_index   = page.body.index(');',start_index) - 1
      while(start_index and end_index) do
        name = "" 
        email = ""
        contact_fields = page.body.slice(start_index..end_index).gsub(/[\\\{\"\']/,'').split(',')
        contact_fields.each do |c|
          key,value = c.split(':')
          if key and value
            name << value if key == "FirstName"
            name << " #{value}" if key == "LastName"
            email = value if key == "Email"          
          end       
        end
        contacts << {:email=>email,:name=>name}
        start_index = page.body.index('hashJsonContacts.add',end_index) 
        if start_index         
          start_index += 26
          end_index = page.body.index(');',start_index)
        end 
      end

      # Change to next page
      current_page += 1
      if current_page <= total_pages
        page.forms[1].__EVENTTARGET='ctl00$ctl00$ctl00$cpMain$cpMain$messagingMain$AddressBook$ucAddressBookView$pagerHeader'
        page.forms[1].__EVENTARGUMENT= current_page
        page = agent.submit(page.forms[1])
      end
    end # Iterate page
    contacts.compact
  end

  # Register Myspace with blackbook
  Blackbook.register(:myspace, self)

end
