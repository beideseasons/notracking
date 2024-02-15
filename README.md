# fhem-gardener
Device for FHEM to monitor the status of plants (in combination with a Xiaomi Mi plant sensor)

# Installation

## Requirements
On Alpine Linux install these packages:
```
apk add perl-datetime gcc perl-dev musl-dev
```

Install the required Perl modules via cpan:
```
cpan -T DateTime DateTime::Format::Strptime
```


## Adding update site
For an automatic installation and updates of this project run these commands in fhem:
```
update add http://raw.githubusercontent.com/ChristianKuehnel/fhem-gardener/master/update/controls_gardener.txt
update all
```
Note: the URL must be http, not https.