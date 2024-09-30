# onetwothree
An OE tools using the new (12.8) aggregate statement to check how many records an index would return.

While you don't technically need an index over a set of fields to get that information, without an index performance isn't good enough for big databases. To some extent we already limit this by using a do stop-after X: when we query data, but to get a good sample size, you may need to either create an index, or increase the MaxRunTime for that task to allow it enough time to gather data.

## How it works
The tool simply uses the aggregate statement with various queries in order to get some information on the data you have in your DB. Given an index on the Customer table with 3 fields i.e. Country, City, Zip you'll get 3 levels of aggregate statements, each working like a break by.

The first level will aggregate by country i.e. country = 'USA'. The values will be the values you have in your database. The end result will be some data that lets you know that you have 2 customers each with countries x,y,z, and 1000 customers with a country of USA.

The second level will aggregate by country and city, and it will do it for all the values it went through at level 1 i.e.
country = 'USA' and city = 'Waltham'. The end result will be a set of values letting you know that you have N customers with a city of Waltham, and 10 with a city of Burlington. **This is the major caveat of the tool. We can't really keep track of all combinations of values i.e. Country AND City as the number of records would just increase exponentially. To get around that, we only track the value of the current level, in this case the City.**

The third level will aggregate by country, city, and ZIP code. The end result will be a set of data letting you know that ZIP codes x,y,and z have 20 cutomers each.

## How is it useful
There are 2 main ways in which this is useful, and they all rely on you having somewhat weird or otherwise unknown data.

### Finding out how well an index would do
If you need to add a new index, you'll want to know how effective it actually is. While you can have a gut feeling about it, it's better to have actual numbers. Simply edit the config file and add a new "index" to be tested containing all the fields you want. Run the tool and you'll know what to expect from that index. You'll also know what to expect from partial matches i.e. 3 out of 5 fields.

### Finding outliers in your data
You already have some indexes setup, but you might have some outliers lying around that would cause issues. Some customer might have a lot more data compared to everyone else, or you might have some data lying around with default values causing it to get picked up by queries that don't actually need it.

The config generated by this tool is done based on your indexes, so all you need are 3 commands and you'll get to know your indexes a lot better. Keeping in with the Customer example, you might want to look at Orders for a customer by order date and order status i.e. idxCustOrderStatus CustomerId, OrderDate, OrderStatus.

If at some point a batch process went wrong, or a customer did something weird, you might have some records lying around with incorrect dates. Maybe you've got a 10000 orders with a date of 01/01/2099 and a status of 0 because something went wrong. Or maybe the OrderDate field got added at a later date and the process meant to populate it went awry for whatever reason (my bet is on different date formats) and now you've got some weird values in place.

A query that would grab current customer orders might look like CustomerId = 1 and OrderDate >= today. This would then grab all 10000 records, and the ones with a status of 0 might simply not be displayed because they don't make sense, but all the records were fetched.

This tool will let you know that some customer(s) have 10000 orders with a date of 01/01/2099 and you can investigate things further.

Another similar case might happen if you allow for "guest" purchases that don't have a customer associated. In this case you might have a CustomerId of 0 on the Order. This will show that guest customer as having an inordinate amount of orders.

## Requirements
In order to run the code generated by this tool you'll need OE 12.8 and up as it uses the **aggregate** statement. To actually generate the code you won't need any specific OE version, any 11 version will work just fine. While keeping with the OE theme, you'll also need a **./scripts/onetwothree.ini** file so that _progress.exe runs correctly.

Finally you'll want some database that you can run this tool against. By default it's going to copy the sports, sports2000, and sports2020 databases into the build dir and connect to those (see **./scripts/db_conn.pf**).

## Setup

### Python
First install python and add it to the path. This should be straightforward and any installation method (Windows Store, standalone installer, etc.) should work fine.

To make things easier, the python script uses the os and argparse packages to deal with command line arguments and OS paths. These can be installed using pip quite easily.
```
pip install argparse
pip install os
```

### Setting up onetwothree.ini
The easiest way to do this is to copy your **%DLC%/bin/progress.ini** file and rename it. Then you'll also need to make a slight change to the propath so that it includes **onetwothree.pl** which will get created during the build phase. The .pl will be copied into ./scripts so depending on how you plan on running the tool you could add an aboslute path or a relative path i.e.
```
PROPATH=.\DLC128\gui,\DLC128,\DLC128\bin,.\onetwothree.pl
```

### Setting up database connections
By default the script is going to use **./scripts/db_conn.pf** for its database connections. Feel free to change this so it references any database you have that you want to run the tool against. By default it's going to connect to the sports databases that get copied over during the build process in single user mode.

### Building the code
If you've cloned this repository, the next step is to actually build the code. To do this simply run the following command in the root project directory. You'll notice a **build** directory getting created, and **onetwothree.pl** being copied over to your ./scripts dir.
```
gradle build --rerun-tasks
```

## Running the tool
For the sake of this example, the tool will be ran directly from the ./scripts dir. The parameters have some associated help, so if you're not sure what you can do you should just run using the -h flag which will print the help. 
```
python ./onetwothree.py -h
python ./onetwothree.py cfg -h
python ./onetwothree.py gen -h
python ./onetwothree.py run -h
```

### Generating a config file
The config file will contain information on the "indexes" that we will be aggregating against. The end result will be a config.json file in the scripts directory containing information on the indexes that will be checked.
```
python ./onetwothree.py cfg
```

You can also specify some matchers so that only particular indexes or tables will be looked at. For example the command below will only look at tables starting with "C" and indexes with more than 2 and less than 5 fields.
```
python ./onetwothree.py cfg -tm C* -im *:2:5
```

The resulting file will containin something like this:
```json
{
  "ttConfig": [
    {
      "ConfigGuid": "ed0fb3b4-1ea1-fea1-cb14-166c84790451",
      "DatabaseGuid": "umk0hMK2ob+5FGr+uNILKQ",
      "DatabaseName": "Sports2020",
      "TableName": "Customer",
      "IndexName": "CountryPost",
      "ttConfigField": [
        {
          "Order": 1,
          "IndexField": "Country",
          "DataType": "character"
        },
        {
          "Order": 2,
          "IndexField": "PostalCode",
          "DataType": "character"
        }
      ]
    }
  ]
}
```

The format itself is easy to work with, but there is 1 caveat - the DatabaseGuid must actually match the _Db._Db-Guid value so it can't be set to a random value. This means that when editing the config file manually you'll need to copy it over from a generated config value.

**By default each index will be going through data for 20 seconds. If you want to run for more than that, you'll need to add a "MaxRunTime": number_seconds to the ttConfig object. **

### Limiting the scope of queries
While its nice to get data on the entire contents of a table, sometimes it makes more sense to limit it to just a subset of data. Perhaps you don't want info on all orders, but just those that got created in the last year.

To support this we have a QueryString field that can be added to the ttConfig object. This will contain a query that will be used throughout the generated code to limit the scope of what we're reading. Using the order example above, you might do something like this:
```json
{
  ...,
  "QueryString": "&1.OrderDate > today - 365",
  ...
}
```

When referencing to the buffer, you should always use &1 as that will be substituted away to the buffer name that makes sense in the context. If you don't, chances are things won't compile, the results won't make sense, or things will crash at runtime.

### Generating the reports
Now that you have a config file, you'll need to generate the code that actually runs all of those aggregate statements. This can be simply done using
```
python ./onetwothree.py gen
```

If you want to generate code using a different config file, you'll simply need to pass it as a parameter i.e.
```
python ./onetwothree.py gen -cfg custom_config.json
```

You shouldn't need to touch this code, but feel free to take a look at how it actually works.

### Running the reports
To run the reports you'll again need to run a single command. The results will be a set of json files, one for each database that the tool was ran against.
```
python ./onetwothree.py run
```

### Visualizing the resulting data
Right now the visualization part of things is in a dev only state i.e. somewhat usable but not really. To take a look at the results, you'll need to open up **./scripts/DataVisuzlization.html** in the browser, and pass in the results .json file to the file upload field. You'll then be allowed to select the table and index you want to look at, and you'll be presented with a graph showing the number of records returned for a particular value.

Depending on what you are interested in, it might make more sense to simply parse the temp-table output in code to extract the information you are interested in.