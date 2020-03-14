ScriptVersion.record_timestamps = false
# Load them one by one. They can pull in a lot of memory.
start = ScriptVersion.last.id
start.downto(1).each do |id|
  sv = ScriptVersion.find(id)
  puts sv.id.to_s
  sv.save(validate: false)
end
ScriptVersion.record_timestamps = true
