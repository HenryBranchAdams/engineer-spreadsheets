#!/usr/bin/env ruby

require "csv"
require "json"
require "time"

root = File.expand_path(__dir__)
records_path = File.join(root, "fixtures", "messy_records.csv")
untrusted_path = File.join(root, "fixtures", "untrusted_text.csv")

records = CSV.read(records_path, headers: false)
headers = records.shift
header_counts = headers.each_with_object(Hash.new(0)) { |value, counts| counts[value] += 1 }
duplicate_headers = header_counts.select { |_name, count| count > 1 }.keys.sort

account_index = headers.index("account_id")
time_index = headers.index("event_time")
amount_index = headers.index("amount")
account_ids = records.map { |row| row[account_index] }

invalid_dates = records.count do |row|
  begin
    Time.iso8601(row[time_index])
    false
  rescue ArgumentError
    true
  end
end

untrusted = CSV.read(untrusted_path, headers: true)
formula_sensitive = untrusted.count { |row| row["submitted_text"].match?(/\A[=+\-@\t\r\n]/) }
originals_preserved = untrusted.all? { |row| row["submitted_text"] == row["canonical_original"] }

result = {
  record_rows: records.length,
  duplicate_headers: duplicate_headers,
  long_identifiers: account_ids.count { |value| value.match?(/\A\d{16,}\z/) },
  leading_zero_identifiers: account_ids.count { |value| value.match?(/\A0\d+/) },
  duplicate_account_groups: account_ids.each_with_object(Hash.new(0)) { |value, counts| counts[value] += 1 }.count { |_value, count| count > 1 },
  invalid_iso_timestamps: invalid_dates,
  blank_amounts: records.count { |row| row[amount_index].nil? || row[amount_index].empty? },
  zero_amounts: records.count { |row| row[amount_index] == "0" },
  not_applicable_amounts: records.count { |row| row[amount_index] == "N/A" },
  locale_sensitive_amounts: records.count { |row| row[amount_index]&.include?(",") },
  formula_sensitive_texts: formula_sensitive,
  canonical_originals_preserved: originals_preserved,
}

expected = {
  record_rows: 6,
  duplicate_headers: ["status"],
  long_identifiers: 5,
  leading_zero_identifiers: 5,
  duplicate_account_groups: 1,
  invalid_iso_timestamps: 1,
  blank_amounts: 1,
  zero_amounts: 1,
  not_applicable_amounts: 1,
  locale_sensitive_amounts: 1,
  formula_sensitive_texts: 4,
  canonical_originals_preserved: true,
}

puts JSON.pretty_generate(result)
abort "Fixture assertions failed" unless result == expected
