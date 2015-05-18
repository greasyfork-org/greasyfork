require 'test_helper'

class ScriptVersionAppliesToTest < ActiveSupport::TestCase

	def get_applies_to(includes)
		js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n" + includes.map {|i| '// @include ' + i}.join("\n") + "\n// ==/UserScript==\nvar foo = \"bar\";"
		sv = ScriptVersion.new
		sv.code = js
		return sv.calculate_applies_to_names
	end

	test 'no includes' do
		assert_empty get_applies_to([])
	end

	test 'includes all' do
		assert_empty get_applies_to(['http://*'])
	end

	test 'includes all and specific' do
		assert_empty get_applies_to(['http://*', 'http://example.com/*'])
	end

	test 'includes all only protocol' do
		assert_empty get_applies_to(['http*'])
	end

	test 'one specific' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['http://example.com/*'])
	end

	test 'two specific' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}, {text: 'anotherexample.com', domain: true, tld_extra: false}], get_applies_to(['http://example.com/*', 'http://anotherexample.com/*'])
	end

	test 'repeated specific' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['http://example.com/*', 'http://example.com/*'])
	end

	test 'overlapping' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['http://example.com/*', 'http://example.com/foo/*'])
	end

	test 'wildcard protocol' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['*://example.com/*'])
	end

	test 'invalid URL' do
		assert_equal [{text: 'http://?what', domain: false, tld_extra: false}], get_applies_to(['http://?what'])
	end

	test 'URL with no host' do
		assert_equal [{text: 'abc', domain: false, tld_extra: false}], get_applies_to(['abc'])
	end

	test 'http or https URL' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['http*://example.com'])
	end

	test 'http or https URL skipping colon' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['http*//example.com'])
	end

	test 'http or https URL skipping all puntucation' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['http*example.com'])
	end

	test 'wildcard subdomain with dot' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['http://*.example.com'])
	end

	test 'wildcard subdomain no dot' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['http://*example.com'])
	end

	test 'wildcard subdomain and protocol' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['*example.com'])
	end

	test 'wildcard subdomain and protocol with dot' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['*.example.com'])
	end

	test 'wildcard subdomain and http or https' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['http*.example.com'])
	end

	test '.tld' do
		names = get_applies_to(['http://example.tld'])
		assert names.include?({text: 'example.com', domain: true, tld_extra: false}), names.inspect
	end

	test 'wildcard tld' do
		names = get_applies_to(['http://example.*'])
		assert names.include?({text: 'example.com', domain: true, tld_extra: false}), names.inspect
	end

	test 'wildcard before protocol' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['*http://example.com'])
	end

	test 'trailing dot on hostname' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['*http://example.com.'])
	end

	test 'multiple wildcards in host' do
		assert_equal [{text: 'http://s*.*.example.*/*', domain: false, tld_extra: false}], get_applies_to(['http://s*.*.example.*/*'])
	end

	test 'subdomain' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_to(['http://www.example.com/*'])
	end

	test 'tld' do
		assert_equal [{text: 'example.com', domain: true, tld_extra: false}, {text: 'example.net', domain: true, tld_extra: true}, {text: 'example.org', domain: true, tld_extra: true}, {text: 'example.de', domain: true, tld_extra: true}, {text: 'example.co.uk', domain: true, tld_extra: true}], get_applies_to(['http://www.example.tld/*'])
	end

end
