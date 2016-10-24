require 'yaml'

namespace :duplicate_check do

	BIN_DIRECTORY = Rails.root.join('bin')
	TMP_DIRECTORY = Rails.root.join('tmp')
	DUMP_DIRECTORY = TMP_DIRECTORY.join('jsdump')
	RESULTS_FILE = TMP_DIRECTORY.join('simian.yml')

	desc "Dump the latest version of all scripts to a temporary location."
	task dump_code: :environment do
		Script.find_each do |script|
			# use rewritten code as that's what we can link to to show the user
			code = script.get_newest_saved_script_version.rewritten_code
			if code.length < Rails.configuration.duplicate_check_size_limit
				File.open(DUMP_DIRECTORY.join("#{script.id}.js"), 'w') { |file| file.write(code) }
			end
		end
  end

	desc "Run the duplicate checker"
	task run_checker: :environment do
		system "#{BIN_DIRECTORY.join('java')} -jar #{BIN_DIRECTORY.join('simian.jar')} -language=js -formatter=yaml -failOnDuplication- -threshold=#{Rails.configuration.duplicate_check_line_threshold} #{DUMP_DIRECTORY.join('*.js')} | tail -n +4 > #{RESULTS_FILE}"
	end

	desc "Parse the results of the duplicate checker and save to the DB."
	task parse_results: :environment do
		CpdDuplication.transaction do
			CpdDuplication.delete_all
			CpdDuplicationScript.delete_all

			results = YAML.load_file(RESULTS_FILE)
			results['simian']['checks'].first['sets'].each do |set|
				c = CpdDuplication.new(lines: set['lineCount'])
				set['blocks'].each do |d|
					script_id = d['sourceFile'].split('/').last.split('.').first
					c.cpd_duplication_scripts << CpdDuplicationScript.new(line: d['startLineNumber'], script_id: script_id)
				end
				c.save!
			end
		end
	end

	desc "Run and load duplicate check"
	task run: [:dump_code, :run_checker, :parse_results] do
	end

end
