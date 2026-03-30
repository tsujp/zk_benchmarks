#!/usr/bin/env ruby

# Load bundle context.
require 'bundler/setup'

require 'csv'

ANSI_RE = /\e\[[0-9;]*m/

def strip_ansi(s) = s.gsub(ANSI_RE, '')

# TODO: Here and peak_rss use BigDecimal instead? Probably fine for now without.
def wall_time_to_s(text)
  m = text.match(/\A([\d.]+)\s*(ms|s)\b/)
  raise "Cannot parse wall_time: #{text.inspect}" unless m
  raw = m[2] == 'ms' ? m[1].to_f / 1000.0 : m[1].to_f
  raw.round(6)
end

# Normalise input to megabytes
def normalise_peak_rss(str)
  # TODO: Or mebibytes? Also improve this logic it's a bit messy right now.
  # Pedantic check on suffixes.
  case
  when str.end_with?('MB') then str.delete_suffix('MB').to_f.round(6)
  when str.end_with?('GB') then (str.delete_suffix('GB').to_f * 1000).round(6)
  else
    raise "Unknown unit suffix for '#{str}"
  end
end

def parse_benchmark_name(name)
  m = name.match(/\A(\w+?)__\d+__(\d+)_bytes_(\d+)\z/)
  raise "Cannot parse name: #{name.inspect}" unless m
  [m[1], m[2].to_i, m[3].to_i]
end

BenchmarkRecord = Struct.new(
  :scenario,
  :category,
  :input_size_bytes,
  :iterations,
  # i.e. execution
  :witness_wall_s,
  :witness_rss_mb,
  #
  :proving_wall_s,
  :proving_rss_mb,
  #
  :verifying_wall_s,
  :verifying_rss_mb,
  #
  :proof_size_bytes,
  :witness_size_bytes,
  :circuit_size,
  :acir_opcodes,
  #
  keyword_init: true,
)

BR_FIELDS = BenchmarkRecord.members

BR_DISPLAY_ALIASES = {
  input_size_bytes: 'in_b',
  witness_wall_s: 'exe_s',
  witness_rss_mb: 'exe_mb',
  proving_wall_s: 'prv_s',
  proving_rss_mb: 'prv_mb',
  verifying_wall_s: 'vfy_s',
  verifying_rss_mb: 'vfy_mb',
  proof_size_bytes: 'prf_b',
  witness_size_bytes: 'wit_b',
}.freeze

input_path  = ARGV[0] || File.join(__dir__, 'fat_output.txt')
output_path = ARGV[1] || File.join(__dir__, 'benchmarks.csv')

# Parsed records
records = []

# Current parse-in-progress record
cur = nil

# Interned from all `==> measure_FOO` output lines:
#   witness, proof_size, proving, verifying
phase = nil

raw_log = File.foreach(input_path)

def next_stripped_line(raw_log_enum) = raw_log_enum.next.gsub(ANSI_RE, '').rstrip

loop do
  # XXX: Pre-strip before feeding to this script? Pedantic.
  # ln = strip_ansi(raw_log.next.rstrip)
  ln = next_stripped_line(raw_log) # TODO: Curry and just call without passing raw_log constantly?

  # `** Benchmarking:` - SCENARIO
  if (m = ln.match(/\*\*\sBenchmarking:\s+(\S+)/))
    records << cur if cur
    hash_fn, input_bytes, iters = parse_benchmark_name(m[1])

    cur = BenchmarkRecord.new(
      scenario: m[1],
      category: hash_fn,
      input_size_bytes: input_bytes,
      iterations: iters,
    )

    phase = nil
    next
  end

  # `==> measure_FOO...` - PHASE of measurement
  if ln.match(/==\> measure_(.+)\.\.\./)
    # FIXME: Technically insecure, double check not a nicer way that's not manually
    #        unrolling a whole bunch of if-else or case with multiple when statements.
    phase = $~[1].to_sym
    next
  end

  # POOP table output detection
  # TODO: Have poop output JSON or ZON or a sequence to mark it's start
  if ln.match?(/\s*measurement\s+mean\s+±/)
    # Extraction here is manual and depends on order (XXX: If/when poop structured
    #   output this becomes simpler, so no major optimisation for now).

    # wall_time
    ln = next_stripped_line(raw_log)
    if ln.match(/\s*wall_time\s+([\d.]+\s*(?:ms|s))/)
      cur["#{phase}_wall_s"] = wall_time_to_s($~[1])
    end

    # peak_rss
    ln = next_stripped_line(raw_log)
    if ln.match(/\s*peak_rss\s+([\d.]+\s*(?:MB|GB))/)
      cur["#{phase}_rss_mb"] = normalise_peak_rss($~[1])
    end
  end

  # {Witness, Proof} Size
  if (ln.match(/\Atarget\/\S+\.gz\s+(\d+)/) || ln.match(/\Aout\/proof\s+(\d+)/))
    cur["#{phase}_bytes"] = $~[1].to_i
    next
  end

  # Circuit size / Acir opcodes
  # XXX: Phase setup doesn't work for these since they are output in the same step.
  if ln.match(/"circuit_size":\s*(\d+)/)
    cur[:circuit_size] = $~[1].to_i
  end

  if ln.match(/"acir_opcodes":\s*(\d+)/)
      cur[:acir_opcodes] = $~[1].to_i
  end
end

# Final benchmark report in log, even if it's only partially filled.
records << cur if cur

CSV.open(output_path, 'w', headers: BR_FIELDS, write_headers: true) do |csv|
  records.each { |r| csv << BR_FIELDS.map { |f| r[f] } }
end

def pretty_print(records)
  return if records.empty?

  # headers = records.first.members.map(&:to_s)
  headers = records.first.members.map { |f| BR_DISPLAY_ALIASES.fetch(f, f.to_s) }
  rows    = records.map { |r| r.to_a.map { |v| v&.to_s || '-' } }
  widths  = headers.zip(*rows).map { |col| col.map(&:length).max }

  fmt = widths.map { |w| "%-#{w}s" }.join('  ')
  puts format(fmt, *headers)
  puts widths.map { |w| '-' * w }.join('  ')
  rows.each { |row| puts format(fmt, *row) }
end

puts "Parsed #{records.size} benchmarks -> #{output_path}"
pretty_print(records)
