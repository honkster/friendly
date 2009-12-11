Friendly
=======

### Short Version

This is an implementation of the ideas found in [this article](http://bret.appspot.com/entry/how-friendfeed-uses-mysql) about how FriendFeed uses MySQL. You should read that article for all the details.

### Long Version

Turn MySQL in to a document db!

Why? Everybody is super excited about NoSQL. Aside from the ridiculous rumour that removing SQL makes things magically scalable, there's a lot of reason to look forward to these new data storage solutions.

One of the biggest improvements is where schema / index changes are concerned. When you have a ton of data, migrating MySQL tables takes forever and locks the table during the process. Document dbs like mongo and couch, on the other hand, are schemaless. You just add and remove fields as you need them.

But, the available document oriented solutions are still young. While many of them show great promise, they've all got their quirks. For all its flaws, MySQL is a rock. It's pretty fast, and battle-hardened. We *never* have problems with MySQL in production.

Fortunately, with a little extra work on the client-side, we can get the flexibility of a doc db in MySQL!

### How it Works

Let's say we had a user model.

    class User
      include Friendly::Document

      attribute :name, String
      attribute :age,  Integer
    end

Friendly always stores your documents in a table with the same schema:

    CREATE TABLE users (
        added_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        id BINARY(16) NOT NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        attributes TEXT,
        UNIQUE KEY (id),
    ) ENGINE=InnoDB;

  - added_id is there because InnoDB stores records on disk in sequential primary key order. Having recently inserted objects together on disk is usually a win.
  - id is a UUID (instance of Friendly::UUID).
  - created_at and updated_at are exactly what they sound like - automatically managed by Friendly.
  - attributes is where all the attributes of your object are stored. They get serialized to json and stored in there.

As is, our user model only supports queries by id.

    User.find(id)
    User.first(:id => id)
    User.all(:id => [1,2,3])

Not great. We'd probably want to be able to query by name, at the very least.

Indexes
=======

To support richer queries, Friendly maintains its own indexes in separate tables. To index our user model on name, we'd create a table like this:

    CREATE TABLE index_users_on_name (
      name varchar(256) NOT NULL,
      id binary(16) NOT NULL,
      PRIMARY KEY (undelivered,actor_id,created_at,id)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1

Then, we'd tell friendly to maintain that index for us:

    class User
      # ... snip ...

      indexes :name
    end

Any time friendly saves a user object, it will update the index as well. That way, we can query by name:

    User.first(:name => "James")
    User.all(:name => ["James", "John", "Jonathan"])

One of the big advantages to this approach is that indexes can be built offline. If you need a new index, you can write a script to generate it in the background without affecting the running application. Then, once it's ready, you can start querying it.

Installation
============

Friendly is available as a gem. Get it with:

    sudo gem install friendly

Setup
=====

First, you need to instantiate a Sequel database object. Sequel has lots of great docs, but for mysql it looks like this:

    $db = Sequel.connect "mysql://user@server/db_name"

Then, setup the friendly datastore object:

    Friendly.datastore = Friendly::DataStore.new($db)

Now, you're ready to rock.

If you're using rails, create a file called config/initializers/friendly.rb and put something like this in it:

    $db = Sequel.connect "mysql://user@server/db_name"
    Friendly.datastore = Friendly::DataStore.new($db)

Of course, you'll want to replace user@server/db_name with values that are appropriate for your system. Ultimately, you'll probably want to add a config file, so that your production environment can differ from development and so forth. I will include something like this in a future version of Friendly.

TODO
====

  - Online migrations. Add a version column to each model and a DSL to update schema from one version to another on read. This facilitates data transformations on the fly. If you want to transform the whole table at once, just iterate over all the objects, and save.
  - Table migrations. Since all the tables follow the same format, it should be pretty easy to create all the necessary tables - maybe even automatically.
  - More convenience API: Document.create, Document#update_attributes, etc.
  - Associations
  - Offline indexer
  - Create tables automatically
  - Write and read through caching (memcache) layer

Credits
=======

Friendly was developed by James Golick & Jonathan Palardy at FetLife (nsfw).

Copyright (c) 2009 James Golick. See LICENSE for details.
