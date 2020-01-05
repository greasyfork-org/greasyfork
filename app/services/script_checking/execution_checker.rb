class ScriptChecking::ExecutionChecker
  class << self
    def check(script_version)
      code = script_version.code

      context = MiniRacer::Context.new(timeout: 500, max_memory: 20_000_000)

      sets = Set.new
      function_calls = Set.new
      context.attach('greasyforkSetLogger', ->(property) { sets << property.join(".") })
      context.attach('greasyforkFunctionLogger', ->(property) { function_calls << property.join(".") })

      begin
        context.eval(PROXY_CODE + "\n" + code)
      rescue MiniRacer::Error => e
        return ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_OK)
      end

      return ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_BLOCK, 'Something', "Blocked set - #{sets.first}") if (sets & BLOCKED_SETS).any?
      return ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_BLOCK, 'Something', "Blocked function call - #{sets.first}") if (function_calls & BLOCKED_FUNCTION_CALLS).any?

      ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_OK)
    end
  end

  BLOCKED_SETS = ['window.location', 'window.location.href']
  BLOCKED_FUNCTION_CALLS = ['window.open']

  PROXY_CODE = <<~JS
    function GreasyforkProxy(reference) {
      return new Proxy(function() {}, {
        get: function(obj, prop) {
          return new GreasyforkProxy(reference.concat(prop));
        },
        set: function(obj, prop, val) {
          greasyforkSetLogger(reference.concat(prop));
          return true;
        },
        apply: function(target, thisArg, argumentsList) {
          greasyforkFunctionLogger(reference);
          return new GreasyforkProxy(reference);
        }
      });
    };
    
    var window = new GreasyforkProxy(['window']);
    globalThis = window;
  JS

end