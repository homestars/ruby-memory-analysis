#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'yaml'
require 'gnuplot'
require_relative 'db'

### Parse arguments

type = ARGV[0]
(type == 'type') && (type = 'type-mem')

case type
when 'type-count'
  ylabel = 'count'
  query = nil
  ycolumn = 'COUNT(id)'
  group = :type
  key_pos = 'left top'
when 'type-mem'
  query = nil
  ycolumn = 'SUM(memsize)'
  group = :type
  ylabel = 'memsize [MB]'
  yscale = 1024 * 1024
  key_pos = 'left top'
when 'string-count'
  ylabel = 'count'
  query = { type: 'STRING' }
  ycolumn = 'COUNT(id)'
  group = :file
when 'string-mem'
  query = { type: 'STRING' }
  ycolumn = 'SUM(memsize)'
  group = :file
  ylabel = 'memsize [MB]'
  yscale = 1024 * 1024
when 'data-count'
  ylabel = 'count'
  query = { type: 'DATA' }
  ycolumn = 'COUNT(id)'
  group = :file
when 'data-mem'
  query = { type: 'DATA' }
  ycolumn = 'SUM(memsize)'
  group = :file
  ylabel = 'memsize [MB]'
  yscale = 1024 * 1024
else
  warn 'Usage: graph <type>'
  exit 1
end

xoffset = 60 * 60 # GMT+1
graph_basename = File.dirname(File.expand_path(__FILE__)) + '/graph-' + type
puts "the #{graph_basename}"

### Read cache or execute query

scope = SpaceObject
scope = scope.where(**query) if query
scope = scope.order(ycolumn + ' DESC NULLS LAST')
scope = scope.group(:time, group)
data = scope.limit(500).pluck(group, :time, ycolumn)

### Then plot

Gnuplot.open(persist: true) do |gp|
  Gnuplot::Plot.new(gp) do |plot|
    plot.terminal 'png large'
    plot.output graph_basename + '.png'

    plot.xdata :time
    plot.timefmt '"%s"'
    plot.format 'x "%H:%M"'

    plot.xlabel 'time'
    plot.ylabel ylabel
    plot.key key_pos if key_pos

    grouped_data = data.group_by(&:first)
    keys = grouped_data.keys.sort_by { |key| -grouped_data[key].reduce(0) { |sum, d| sum + (d[2] || 0) } }
    keys[0, 10].each do |key|
      data = grouped_data[key]
      data.sort_by! { |d| d[1] }
      x = data.map { |d| d[1].to_i + (xoffset || 0) }
      y = data.map { |d| d[2] }
      y = data.map { |d| (d[2] || 0) / (yscale || 1) }
      plot.data << Gnuplot::DataSet.new([x, y]) do |ds|
        ds.using = '1:2'
        ds.with = 'linespoints'
        ds.title = key || '(empty)'
      end
    end
  end
end
