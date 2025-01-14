local Logger = require('soil.logger'):new 'Soil'
local M = {}

local function format_file_name(filename)
  -- Convert to lowercase
  local lower = string.lower(filename)
  -- Replace multiple spaces with a single space
  local single_space = string.gsub(lower, '%s+', ' ')
  -- Replace remaining spaces with dashes
  local dashed = string.gsub(single_space, '%s', '-')
  return dashed
end

local function get_file_name_without_ext(path)
  -- Get the file name from path (handles both forward and backward slashes)
  local fileName = string.match(path, '[\\/]?([^\\/]+)$') or path
  -- Remove the extension
  local nameWithoutExt = string.match(fileName, '(.+)%.[^%.]*$') or fileName
  return nameWithoutExt
end

-- Function to capitalize first letter of each word
local function titleCase(str)
  -- First replace dashes with spaces
  str = str:gsub('-', '\\ ')

  -- Capitalize first letter of each word
  -- %w+ matches one or more word characters
  -- %a matches any letter
  return str:gsub('(%w)(%w*)', function(first, rest)
    return first:upper() .. rest:lower()
  end)
end
local function split_path(path)
  local directory, filename = path:match '(.-)([^/\\]*)$'
  return directory, filename
end

M.DEFAULTS = {
  actions = {
    redraw = false,
    reopen = false,
  },

  image = {
    darkmode = false,
    format = 'svg',
    execute_to_open = function(img)
      return 'open ' .. img
    end,

    source_file_to_absolute_output = function(relative_file, absolute_file, settings)
      local cwd = vim.fn.getcwd()
      local file_name_no_ext = get_file_name_without_ext(relative_file)
      local relative_file_folder = split_path(relative_file)
      local absolute_out_folder = cwd .. '/out/' .. relative_file_folder .. format_file_name(file_name_no_ext)
      local absolute_out_file = absolute_out_folder .. '/' .. titleCase(file_name_no_ext) .. '.' .. settings.image.format
      return absolute_out_folder, absolute_out_file
    end,
  },
}

function M.setup(opts)
  if opts.puml_jar then
    M.DEFAULTS.puml_jar = opts.puml_jar
  end
  if opts.actions then
    local actions = opts.actions
    if actions.redraw ~= nil and type(actions.redraw) == 'boolean' and actions.redraw then
      M.DEFAULTS.actions.redraw = true
    end
    if actions.reopen ~= nil and type(actions.reopen) == 'boolean' and actions.reopen then
      M.DEFAULTS.actions.reopen = true
    end
  end
  if opts.image then
    local img = opts.image

    if img.format then
      if img.format == 'png' or img.format == 'svg' then
        M.DEFAULTS.image.format = img.format
      else
        Logger:error "Setup Error: The values allowed for image.format are 'png' or 'svg'."
      end
    end

    if img.darkmode then
      if type(img.darkmode) == 'boolean' then
        M.DEFAULTS.image.darkmode = img.darkmode
      else
        Logger:error 'Setup Error: image.darkmode must be a boolean value.'
      end
    end

    if img.execute_to_open then
      if type(img.execute_to_open) == 'function' then
        M.DEFAULTS.image.execute_to_open = img.execute_to_open
      else
        Logger:error 'Setup Error: image.execute_to_open must be a function.'
      end
    end

    if img.source_file_to_absolute_output then
      if type(img.source_file_to_absolute_output) == 'function' then
        M.DEFAULTS.image.source_file_to_absolute_output = img.source_file_to_absolute_output
      else
        Logger:error 'Setup Error: image.source_file_to_absolute_output must be a function.'
      end
    end
  end
end

return M
