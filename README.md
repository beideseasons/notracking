# fhem-gardener
Device for FHEM to monitor the status of plants (in combination with a Xiaomi Mi plant sensor).

It checks the moisture and conductivity levels reported by the sensors and send an email i
f the levels are too low. 
It also monitors the battery level of the sensor and sends an email if the battery is low.

# project status

Do not install/update if build status is red!
* [![Build Status](https://travis-ci.org/ChristianKuehnel/fhem-gardener.svg?branch=master)
* [![Coverage Status]()


# Installation

To install the software you will need several Perl modules. The fhem module itself can be 
installed via the fhem online update feature.

## Requirements
On Alpine Linux install these packages to be able to compile the Perl modules:
```
apk add perl-datetime gcc perl-dev musl-dev
```
On other distributions install the similar packages.

Install the required Perl modules via cpan:
```
cpan -T DateTime DateTime::Format::Strptime List::Util
```

A personal comment on the used Perl modules:
I am well aware that this introduces A LOT of dependencies and not everyone wants to 
have the full build tool chain on their home automation system.
But I simply refuse to implement the parsing of time stamps or a max function myself.
If you know any library that can do the same thing as DateTime::Format::Strptime and 
List::Utils and have fewer dependencies, I'm happy to use those...


## Adding update site
For an automatic installation and updates of this project run these commands in fhem:
```
update add http://raw.githubusercontent.com/ChristianKuehnel/fhem-gardener/master/update/controls_gardener.txt
update all
```
Note: the URL must start http, not https.

## Configuration
Define the devie in fhem with:
```
define <some_name> Gardener
```
If there are any problems check the fhem logs, usually some Perl modules are missing.

After that you can configure the modules with several attributes (see fhem command reference after installation). 

# Getting the data

The Xiaomi MI plant sensors are using Bluetooth Low Energy have have a range of about 5 meters.
So if your home automation server is further away than that, you will need some proxy for this.
I'm using a small Linux computer (e.g. C.H.I.P oder Raspberry Pi) to read the data from the sensors 
via Bluetooth Low Engergy and forward them to the fhem server via MQTT.
Once I've cleaned up the code, I will also upload it to github.
