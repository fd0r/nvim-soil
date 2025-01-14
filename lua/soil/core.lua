local Logger = require('soil.logger'):new 'Soil'
local settings = require('soil').DEFAULTS
local M = {}

-- Validate local setup
local function validate()
  local function validate_image_function()
    return string.find(settings.image.execute_to_open '', 'nsxiv')
  end

  if vim.bo.filetype ~= 'plantuml' then
    Logger:warn 'This is not a Plant UML file.'
    return false
  end
  if vim.fn.executable 'java' == 0 then
    Logger:warn 'java is required. Install it to use this plugin.'
    return false
  end
  if vim.fn.executable 'nsxiv' == 0 and validate_image_function() then
    Logger:warn 'nsxiv is required. Install it to use this plugin.'
    return false
  end
  return true
end

local function open_image_command(image_file)
  -- vim.cmd 'redraw'
  if image_file == nil then
    do
      return
    end
  end
  return string.format("sh -c '%s & disown;'", settings.image.execute_to_open(image_file))
end

-- Util to execute commands
local function execute_command(command, error_msg)
  Logger:info(command)
  error_msg = (error_msg or 'Execution error!') .. '\n' .. command
  local result = vim.fn.system(command)

  -- If error code is different from 0 -> error
  if not (result == nil or result == 0 or result == '') then
    -- vim.cmd 'redraw'
    Logger:error('Command: ' .. command .. 'failed with error:' .. '\n' .. (result or ''))
    do
      return
    end
  end
end

-- Kill application opening image
local function redraw()
  local img = string.format('%s.%s', vim.fn.expand '%:r', settings.image.format)
  local kill_cmd = string.format("ps aux | grep -m 1 %s | awk '{print $2}' | xargs kill -9", img)
  os.execute(kill_cmd)
end

function M.run()
  if not validate() then
    return
  end

  local cli_puml = vim.fn.executable 'plantuml'
  local puml_jar = settings.puml_jar

  if cli_puml ~= 0 or puml_jar then
    -- Path settings
    local source_file_with_extension = vim.fn.expand '%:p'
    local source_file_relative = vim.fn.expand '%:p:.:r'
    local source_file_absolute = vim.fn.expand '%:p:r'
    -- Open file in append mode ('a')

    local absolute_out_folder, absolute_out_file = settings.image.source_file_to_absolute_output(source_file_relative, source_file_absolute, settings)

    -- Formatting settings
    local format = settings.image.format
    local darkmode = settings.image.darkmode and '-darkmode' or ''

    Logger:info(string.format('Compiling: %s', source_file_relative))
    Logger:info 'Building...'

    -- Define puml command to generate file and run it
    local puml_command
    if cli_puml ~= 0 then
      -- No custom plantuml executable
      puml_command = string.format('plantuml %s -t%s %s -o %s', source_file_with_extension, format, darkmode, absolute_out_folder)
    else
      -- Custom plantuml executable
      puml_command = string.format('java -jar %s %s -t%s %s -o %s; echo $?', puml_jar, source_file_with_extension, format, darkmode, absolute_out_folder)
    end
    execute_command(puml_command)

    -- Open image file
    if settings.actions.redraw then
      redraw()
    end
    if settings.actions.reopen then
      execute_command(open_image_command(absolute_out_file))
    end
  else
    Logger:warn "Install plantuml or download it from the official page and set it up with 'puml_jar' option."
  end
end

function M.open_image()
  local file = vim.fn.expand '%:p:r'
  execute_command(open_image_command(file), 'Image not found. Run :Soil command to generate it.')
end

return M
