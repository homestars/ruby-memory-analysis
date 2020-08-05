#!/usr/bin/env ruby

require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'postgresql', database: 'mem_analysis')

def connection
  ActiveRecord::Base.connection
end

class SpaceObject < ActiveRecord::Base
  self.inheritance_column = 'zoink' # use type as ordinary column (not STI)
  has_many :references, class_name: 'SpaceObjectReference', foreign_key: 'from_id', inverse_of: 'from', dependent: :destroy
  has_one :default, class_name: 'SpaceObject', foreign_key: 'default', primary_key: 'address'
end

class SpaceObjectReference < ActiveRecord::Base
  belongs_to :from, class_name: 'SpaceObject', optional: false, inverse_of: 'references'
  belongs_to :to, class_name: 'SpaceObject', foreign_key: 'to_address', primary_key: 'address'
end

def init_database(c = connection)
  c.tables.each { |t| c.drop_table(t) }
  c.create_table 'space_objects' do |t|
    t.datetime :time
    t.string :type
    t.string :node_type
    t.string :root
    t.string :address
    t.text :value
    t.string :klass
    t.string :name
    t.string :struct
    t.string :file
    t.string :line
    t.string :method
    t.integer :generation
    t.integer :size
    t.integer :length
    t.integer :memsize
    t.integer :bytesize
    t.integer :capacity
    t.integer :ivars
    t.integer :fd
    t.string :encoding
    t.string :default_address
    t.boolean :freezed
    t.boolean :fstring
    t.boolean :embedded
    t.boolean :shared
    t.boolean :flag_wb_protected
    t.boolean :flag_old
    t.boolean :flag_long_lived
    t.boolean :flag_marking
    t.boolean :flag_marked
  end
  c.create_table 'space_object_references' do |t|
    t.integer :from_id, null: false
    t.string :to_address, null: false
  end
  restore_indexes
  nil
end

def remove_indexes(c = connection)
  c.indexes('space_objects').each { |i| connection.remove_index('space_objects', name: i.name) }
  c.indexes('space_objects_references').each { |i| connection.remove_index('space_objects_references', name: i.name) }
end

def restore_indexes(c = connection)
  c.change_table 'space_objects' do |t|
    t.index :time
    t.index :address
    t.index :type
    t.index %i[klass method]
    t.index %i[file line]
    t.index :size
    t.index :memsize
  end
  c.execute('VACUUM ANALYZE')
end
