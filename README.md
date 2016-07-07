# Rowboat

Rowboat is a lightweight SQLite3 ORM. Features include...

* #### Ruby-wrapped record objects

```ruby
# Retrieve Pokemon 'Pikachu' from database
pikachu = Pokemon.where(name: 'Pikachu')

# Retrieve Pikachu trainer 'Ash Ketchum' from database
ash = pikachu.trainer

# Create new Pokemon, stage for persisting to database
# Note the typing mistake:
snorlax = Pokemon.new(name: 'Snrlax', trainer_id: ash.id)

# Insert row into pokemons table
snorlax.save

# Edit Pokemon Snorlax for updating
snorlax.name = 'Snorlax'

# Update row in pokemons table
snorlax.save
```

* #### Dynamic method creation for database interfacing

```ruby
# Stage Ruby class representation of SQL table.
class Pokemon < SQLObject
end

# Retrieve column names, creating setter and getter instance methods for each.
Pokemon.finalize!
```

* #### Association methods

```ruby
class Gym < SQLObject
  has_many :trainers
end

Gym.finalize!

class Trainer < SQLObject
  belongs_to :gym
  has_many :pokemons
end

Trainer.finalize!

class Pokemon < SQLObject
  has_one_through :home, :trainer, :gym
  belongs_to :trainer
end

Pokemon.finalize!
```

**NB:** The `#has_one_through` association is dependent upon the associations it traverses. Dependent associations must be declared after their dependencies.

For example, the above model code-snippet would throw an error if the association `has_one_through :home, :trainer, :gym` was declared before its dependency, `belongs_to: trainer`:

```ruby
...

class Pokemon < SQLObject
  has_one_through :home, :trainer, :gym
  belongs_to :trainer
end

# => NoMethodError: undefined method `table_name' for nil:NilClass

...
```



## Getting started

0. Clone this repo into your project directory.
0. Create models for all database tables you wish to use this ORM for.
  * Require `SQLObject` at the top of each model file.

#### Persisting to a database

Start by declaring a model class that inherits from `SQLObject`.

```ruby
class Pokemon < SQLObject
end
```

Instantiating a SQLObject stages a record for persisting.

```ruby
pikachu = Pokemon.new
```

Attributes of the instance can be passed in an options hash or set one at a time.

```ruby
starmie = Pokemon.new
starmie.name = 'Starmie'
starmie.trainer_id = 2

# Note the typo!
onyx = Pokemon.new(name: 'Onx', trainer_id: 1)
```

Calling `#save` on a SQLObject instance inserts or updates the database record based on the presence or absence of an `id` attribute.

```ruby
starmie.save # => Inserts a new record.
onyx.save # => Inserts a new record.

onyx.name = 'Onyx'
onyx.save # => Updates the record.
```

#### Search for a record by its attributes

It is possible to pull a record from the database knowing only its attributes (and not its ID).

```ruby
misty = Trainer.where(name: 'Misty')
```

**NB:** An array will be returned regardless of the number of records found.

#### Associations

Inter-record references are declared  via association methods called at the class level.

```ruby
class Gym < SQLObject
  has_many :trainers
end

class Trainer < SQLObject
  belongs_to :gym
  has_many :pokemons
end

class Pokemon < SQLObject
  belongs_to :trainer
  has_one_through :home, :trainer, :gym
end
```

**NB:** Call '::finalize!' on a SQLObject class after it is defined for getter and setter methods.

```ruby
class Pokemon < SQLObject
  belongs_to :trainer
  has_one_through :home, :trainer, :gym
end

Pokemon.finalize! # => Setters, getters available based on column names.
```

## The future of Rowboat

* **Validations** - Methods that prevent protect a database from invalid data entry.
* **Callbacks** - Methods that run at various points in the lifecycle of a SQLObject
* **Convenience methods** - e.g. `#destroy_all`

###### Resources

* [Active Support](https://github.com/rails/rails/tree/master/activesupport): Provides grammatical methods like `#constantize` and `#pluralize`

* [sqlite3](https://github.com/sparklemotion/sqlite3-ruby) Database intefacing gem for Ruby
