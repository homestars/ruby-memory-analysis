#!/usr/bin/env ruby

require 'ruby-progressbar'
require 'json'
require 'csv'

def parse_dump(filename, &block)
  lines = open(filename).readlines
  lines.each do |line|
    block.call JSON.parse(line), lines.count
  end
end

def parse_index(filename, &block)
  open(filename).each do |line|
    date, time, dumpname = line.split(/\s+/)
    block.call dumpname, "#{date} #{time}"
  end
end

FIELDS = %w[time type node_type root address value klass name struct file line method generation size length memsize bytesize capacity ivars fd encoding default_address freezed fstring embedded shared flag_wb_protected flag_old flag_long_lived flag_marking flag_marked].freeze
REF_FIELDS = %w[id from_id to_address].freeze

id = 1
ref_id = 1

heap_files = Dir['heap_files/**/*.json']

heap_files.each do |file|
  time_int = file.scan(/\d/).join('').to_i
  time = Time.at(time_int)

  next if ARGV.any? && !ARGV.include?(file)

  progressbar = ProgressBar.create(title: file, format: '%t |%B| %c/%C %E', throttle_rate: 0.5)
  CSV.open(file.gsub(/.json$/i, '') + '.csv', 'w') do |csv|
    csv << FIELDS
    CSV.open(file.gsub(/.json$/i, '') + '.refs.csv', 'w') do |ref_csv|
      ref_csv << REF_FIELDS
      parse_dump(file) do |data, count|
        progressbar.total = count

        data['value'] = data['value'].gsub(/[^[:print:]]/, '.') if data['value'] # allow string database column
        data['klass'] = data.delete('class') if data['class'] # avoid error
        data['freezed'] = data.delete('frozen') if data['frozen'] # idem
        data['default_address'] = data.delete('default') if data['default'] # consistency
        data['time'] = time
        data['id'] = id
        (data.delete('flags') || {}).each { |k, v| data["flag_#{k}"] = v }
        data['default_address'] = data.delete('default') if data['default']
        refs = data.delete('references') || []

        csv << FIELDS.map { |f| data[f] }
        refs.each do |ref|
          ref_csv << [ref_id, id, ref]
          ref_id += 1
        end

        id += 1
        progressbar.increment
      end
    end
  end
end
