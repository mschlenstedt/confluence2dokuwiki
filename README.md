# confluence2dokuwiki
Import Confluence HTML Files into DokuWiki

This small script uses pandoc (https://www.pandoc.org) to convert an Atlassian Confluence HTML Export into DokuWiki format. Several additional filters will be used to correct the pandoc output and to create a valid Page/Namespace structure for DokuWiki. 

The following additional filters are currently implemented:

* Correct wiki internal links
* Rename filenames (pages) to valid DokuWiki filenames
* Create (sub-)namespaces according to Confluence subpage structure
* Move media files to correct namespaces
* Correct attachement links (images and other files) - with correct dimensions
* Correct first heading to be correctly recognized as page title
* Remove Confluence Footer
* Remove old "Created by" line from Confluence
* Remove Attachement section from Confluence
* Remove TOCs from Confluence
* Correct page internal anchor links
* Remove Confluence Icons

### Known bugs

General bugs:
* Horrible coding style ;-) This was a script made for my own purposes, I never planed to make it available to the public while coding... :-)
* The script assumes to be run on a Unix/Linux system with bash installed. System commands have to be adjusted if running this script on a Windows machine.
* Always use latest pandoc software - most older versions create broken markup.

Converting bugs:
* Internal anchor links to sections most times are broken (beacuse confluence removed all spaces while DokuWiki uses spaces automatically).
* Most Confluence Makros are missing in the Confluence HTML export - that is why we also cannot import them.
* Nested list elements including code snippets are broken in older pandoc versions - upgrade pandoc to the latest version (2.19.x or above)

### Installation

Install perl on your system using your standard repository. This should be installed mostly on every Linux system. No need for special Modules except the Perl Unidecode Module. You can install it from your repository (on Debian based systems: `apt-get install libtext-unidecode-perl`) or from CPAN.

Next you need pandoc (https://pandoc.org). Do not use the mostly too old version from your repository. Always use latest available version from Pandoc's website: https://pandoc.org/installing.html#linux

Download the precompiled package and install it with the tools provided from your dustribution. On Debian based systems use dpkg, e.g. `dpkg -i pandoc-2.19.2-1-amd64.deb`

### Export your Confluence Space

You need an export of your confluence space. The script only supports to handle one Confluence Space at the time. If you would like to convert more than one space, you need to do it in sequence.

Go to the Confluence admin area and export your space into HTML files. You will receive an ZIP file with the following file structure:

```
Confluence-space-export-202146.html.zip
   |
   --> YOURSPACENAME
          |
          --> attachements
          --> images
          -- styles
          -- page1.html
          -- page2.html
          -- *.html
```

Extract the ZIP file and copy/move the folder with the exported space files (this should be the folder in the root of the ZIP file named in UPPERCASE letters) to your working directory.

### Convert your Wiki

Copy the included script confluence2dokuwiki.pl into your working directory and start the script. The script needs the SPACE-folder from your Confluence export zip as parameter:

`perl ./confluence2dokuwiki.pl YOURSPACENAME`

The script will create two new folders: _pages_ and _media_. These are the folders for your DokuWiki. Just copy the content to your DokuWiki in the data folder and enjoy :-)

### Adjustments

You can slightly adjust the behaviour of the converting script. Open the script in an text editor of your choice and adjust the options at the very beginning of the script.



