print(jit.status())

he_log_info("CC_TARGET_PLATFORM=" .. CC_TARGET_PLATFORM)

local k_run_render_test = 1
local k_run_engine_test = 2
local k_run_animal = 3
local k_run_ui_test = 4
local k_run_armature_test = 5

local start_app_index = 3

local function run_render_test()
  kDirectorTestEnable = false
	require "test.test_class"
	require "test.test_events"

	if kDirectorTestEnable then
		require "test.test_director"
	else
		require "test.test_object"
	end
end

local function run_engine_test()
  he_log_info("--------------run_engine_test--------------")
  --require "test.test_game_default"
  --require "test.test_mem_holder"
  --require "test.test_log"
  --require "test.test_metainfo"
  --require "test.test_startup_config"
	if __ANDROID then
		--require "test.test_luajava"
    --require "test.test_facebook"
	end
  if __IOS or __MAC then
    --require "test.test_wax"
    --TestWax:wax_test()
    --TestWax:wax_callback_test(33, 55)
    require "test.test_facebook"
  end
  --require "test.test_localization"
  --require "test.test_json"
  --require "test.test_res_loader"
  --require "test.test_qzone"
  --require "test.test_http"
  --require "test.test_cc_notification"
  --require "test.test_rpc"
  --require "test.test_dc"
  if __ANDROID then
    require "test.test_gsp"
  end
end

local function run_animal()
  require "animal.MainApplication"
end

local function run_ui_test()
  	--require "test.test_group_view"
  
  	--require "test.test_ui"
    --require "test.test_layout"
    require "test.test_animation"
end

local function run_armature_test()
	require "test.test_armature"
end


local apps = {run_render_test, run_engine_test, run_animal, run_ui_test, run_armature_test}
apps[start_app_index]()

