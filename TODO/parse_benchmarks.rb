#!/usr/bin/env ruby
# Parse fat_output.txt benchmark data into CSV for GNUPlot.
# Usage: ruby parse_benchmarks.rb [input] [output]
#   input  defaults to fat_output.txt (same dir as this script)
#   output defaults to benchmarks.csv (same dir as this script)

require 'csv'

ANSI_RE = /\e\[[0-9;]*m/

def strip_ansi(s) = s.gsub(ANSI_RE, '')

def wall_time_to_s(text)
  m = text.match(/\A([\d.]+)\s*(ms|s)\b/)
  raise "Cannot parse wall_time: #{text.inspect}" unless m
  raw = m[2] == 'ms' ? m[1].to_f / 1000.0 : m[1].to_f
  raw.round(6)
end

def parse_benchmark_name(name)
  m = name.match(/\A(\w+?)__\d+__(\d+)_bytes_(\d+)\z/)
  raise "Cannot parse name: #{name.inspect}" unless m
  [m[1], m[2].to_i, m[3].to_i]
end

FIELDS = %w[
  benchmark hash_fn input_bytes repetitions
  exec_time_s prove_time_s verify_time_s
  proof_size_bytes witness_size_bytes
  circuit_size acir_opcodes
].freeze

input_path  = ARGV[0] || File.join(__dir__, 'fat_output.txt')
output_path = ARGV[1] || File.join(__dir__, 'benchmarks.csv')

records = []
cur     = nil
phase   = nil  # :witness | :proving | :verifying
in_meas = false

File.foreach(input_path) do |raw|
  line = strip_ansi(raw.rstrip)

  # New benchmark block
  if (m = line.match(/Benchmarking:\s+(\S+)/))
    records << cur if cur
    hash_fn, input_bytes, reps = parse_benchmark_name(m[1])
    cur     = { benchmark: m[1], hash_fn:, input_bytes:, repetitions: reps }
    phase   = nil
    in_meas = false
    next
  end

  # Phase detection (lines like "==> measure_witness...")
  if    line.include?('measure_witness...')   then phase = :witness;  in_meas = false; next
  elsif line.include?('measure_proving...')   then phase = :proving;  in_meas = false; next
  elsif line.include?('measure_verifying...') then phase = :verifying; in_meas = false; next
  end

  # Table header → next wall_time row is the one we want
  if line.match?(/\s*measurement\s+mean/)
    in_meas = true
    next
  end

  # wall_time row (mean is the first value after the label)
  if in_meas && (m = line.match(/\s*wall_time\s+([\d.]+\s*(?:ms|s))/))
    key = { witness: :exec_time_s, proving: :prove_time_s, verifying: :verify_time_s }[phase]
    cur[key] = wall_time_to_s(m[1]) if key && cur
    in_meas  = false
    next
  end

  # Witness size: "target/foo.gz 3906"
  if (m = line.match(/\Atarget\/\S+\.gz\s+(\d+)/))
    cur[:witness_size_bytes] = m[1].to_i if cur
    next
  end

  # Proof size: "out/proof 16256"
  if (m = line.match(/\Aout\/proof\s+(\d+)/))
    cur[:proof_size_bytes] = m[1].to_i if cur
    next
  end

  # Circuit metadata (JSON inline)
  if (m = line.match(/"acir_opcodes":\s*(\d+)/))
    cur[:acir_opcodes] = m[1].to_i if cur
  end
  if (m = line.match(/"circuit_size":\s*(\d+)/))
    cur[:circuit_size] = m[1].to_i if cur
  end
end
records << cur if cur

CSV.open(output_path, 'w', headers: FIELDS, write_headers: true) do |csv|
  records.each { |r| csv << FIELDS.map { |f| r[f.to_sym] } }
end

puts "Parsed #{records.size} benchmarks -> #{output_path}"
records.each do |r|
  puts "  %-45s exec=%-8s prove=%-8s verify=%-8s proof=%s B" % [
    r[:benchmark],
    r[:exec_time_s]   &.then { |v| "#{v.round(4)}s" },
    r[:prove_time_s]  &.then { |v| "#{v.round(4)}s" },
    r[:verify_time_s] &.then { |v| "#{v.round(4)}s" },
    r[:proof_size_bytes],
  ]
end
