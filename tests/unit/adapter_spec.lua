local adapter = require("dap-vscode-js.adapter")

describe("dap-vscode-js.adapter", function()
	describe("__gen_cwd", function()
		describe("with empty user_config", function()
			it("returns current cwd if config doesnt have cwd field", function()
				assert.equal(adapter.__gen_cwd({}, {}), vim.loop.cwd())
			end)

			it("returns config cwd if exists", function()
				local test_str = "test"

				assert.equal(adapter.__gen_cwd({}, { cwd = test_str }), test_str)
			end)
		end)

		describe("with user_config", function()
			it("returns user cwd if string", function()
				local test_str = "test"

				assert.equal(adapter.__gen_cwd({ cwd = test_str }, { cwd = "nonsense" }), test_str)
			end)

			it("returns user cwd if function", function()
				local test_str = "test"
				local eq_str = "testa"

				assert.equal(
					adapter.__gen_cwd({
						cwd = function(config)
							return config.cwd .. "a"
						end,
					}, { cwd = test_str }),
					eq_str
				)
			end)
		end)
	end)
end)
