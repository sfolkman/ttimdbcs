drop table database;
create table database (
    id	           varchar2(255),
    dbUniqueName   char(64) not null primary key ,
    lifecycleState char(16),
    timeCreated    timestamp,
    dbParamId      varchar2(255)
);


drop table dbcredentials;
create table dbcredentials (
  id             tt_integer not null primary key,
  adminPassword  varchar2(32),
  sshPublicKeys  varchar2(4096) 
);

drop table dbparameters;
create table dbparameters (
-- A set of parameters which describe the database. This is a subset of parematers needed to create the database.
    id                       not null primary key,
    availabilityDomain       varchar2(32),
    compartmentId	     varchar2(255),
    cpuCoreCount	     tt_smallint,
    dbVersion		     varchar2(32),
    dbName		     varchar2(32),
    permSizeMB               tt_integer,
    tempSizeMB	             tt_integer,
    databaseCharacterSet     varchar2(16),
    diskRedundancy	     varchar2(16),
    displayName		     varchar2(32),
    domain		     varchar2(255),
    hostname	             varchar2(32),
    shapeId		     tt_smallint,
    subnetId	             varchar2(255),
);

drop table dbshape;
create table dbshape (
 -- The shape of the database. The shape determines the number of CPU cores, 
 -- locally attached NVMe drives, and 
 -- the amount of memory allocated to the database. 
 -- To get a list of shapes, use the ListDbSystemShapes operation.
  id                 tt_smallint not null primary key,
  availableCoreCount tt_smallint,
  memoryGB           tt_integer,
  shape              varchar2(32)
);

drop table dbversion;
create table dbversion (
  id             varchar2(255) not null primary key,
  dbUniqueName   varchar2(32),
  lifecycleState varchar2(32),
  timeCreated    timestamp,
  dbParamId      tt_smallint
);

drop table error;
create table error (
  id      tt_integer not null primary key,
  code    varchar(32),
  message varchar(4096)
);


