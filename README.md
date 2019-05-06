# OSM Sci 

This is environment used for running statistical analysis on an openstreet planet data file.

It is only supported on Linux running docker. You will need to have at least 64 GB of ram.
It has been tested on a 32 thread machine but it should be able to work with less.


## Prequisites 

### Download the planet file 

```
wget https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf
```

### Build osm2orc fork that adds tile location for nodes
```
git clone https://github.com/tlpinney/osm2orc
cd osm2orc 
./gradlew distTar
cd build/distributions
tar xf osm2orc-1.0-SNAPSHOT.tar
cd osm2orc-1.0-SNAPSHOT/bin
```

### Convert the planet file to an orc format 
```
./osm2orc planet-latest.osm.pbf planet-latest.osm.orc
```


### Build the osmsci docker image

Install docker if you don't have it 

```
cd osmsci
docker build -t osmsci . 
```

### Initialize the osmsci docker data volume

This will wipe out any data if it was run previously

```
rm -rf tank && mkdir tank 
docker run -v $PWD/tank:/tank -v $PWD/initialize.sh:/initialize.sh:ro --entrypoint=/initialize.sh osmsci
```

### Run the presto instance 
```
docker run --rm --name osmsci -p 8080:8080 -p 14000:14000 -v $PWD/tank:/tank -v $PWD/entrypoint.sh:/entrypoint.sh:ro --entrypoint=/entrypoint.sh osmsci
```

### Upload the planet orc file to the presto instance 
```
curl -i -X PUT "http://127.0.0.1:14000/webhdfs/v1/user/root/planet-latest.osm.fixedtile.orc?op=CREATE&overwrite=true&user.name=root"
curl -i -X PUT -H "Content-Type: application/octet-stream" -T ../planet-latest.osm.fixedtile.orc "http://127.0.0.1:14000/webhdfs/v1/user/root/planet-latest.osm.fixedtile.orc?op=CREATE&data=true&user.name=root&overwrite=true"
```


### Create the hive external table to use with presto

Start the hive console

```
docker exec -i -t osmsci /apache-hive-3.1.1-bin/bin/hive
```


Run the following in the hive console to create the external table

```
CREATE EXTERNAL TABLE planet (
    id BIGINT,
    type STRING,
    tags MAP<STRING,STRING>,
    lat DECIMAL(9,7),
    lon DECIMAL(10,7),
    nds ARRAY<STRUCT<ref: BIGINT>>,
    members ARRAY<STRUCT<type: STRING, ref: BIGINT, role: STRING>>,
    changeset BIGINT,
    `timestamp` TIMESTAMP,
    uid BIGINT,
    `user` STRING,
    version BIGINT,
    visible BOOLEAN,
    tile BIGINT
)
STORED AS ORCFILE
LOCATION '/user/root/';
```

## Presto 

You will want to install the client version of presto to access the service from commandline for 
debugging purposes. This requires java to be installed.

```
wget https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/0.218/presto-cli-0.218-executable.jar
mv presto-cli-0.218-executable.jar presto
chmod +x presto
```


### Test out a query from the host using the presto client

Connect to the presto client
```
docker exec -i -t osmsci /presto-server-0.218/bin/presto --server localhost:8080 --catalog hive --schema default
```

Run a query
```
presto:default> select count(*) from planet;

   _col0    
------------
 5524519528 
(1 row)

Query 20190428_222559_00009_34sfi, FINISHED, 1 node
Splits: 1,026 total, 1,026 done (100.00%)
0:15 [5.52B rows, 564MB] [380M rows/s, 38.7MB/s]


```

## R-Studio 

Install R-Studio 

### Install packages needed for visualizations

```
install.packages("DBI")
install.packages("ggmap")
install.packages("maps")
install.packages("RPresto")
install.packages("mapproj")
```

### Load helper functions from osmsci.R


### Connect to the Presto service
```
con <- dbConnect(
  RPresto::Presto(),
  host='http://localhost',
  port=8080,
  user=Sys.getenv('USER'),
  schema='default',
  catalog='hive',
  source='planet'
)
```

### Run a density query over the planet
```
planetd <- densityQuery(con, 'select histogram(tile) from planet where type = \'node\'')
```

### Set up the world map
```
world <- map_data("world")
```

### Generate density plot of nodes greater than 10000000
```
ggplot() + geom_polygon(data = world, aes(x=long, y = lat, group = group), fill="grey") + geom_rect(data = noded %>% filter(xtile < 255 & d > 10000000) , aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax, fill=d)) + coord_map("rectangular", par=c(0))
``` 


More examples can be found in viz/osmsci.R












