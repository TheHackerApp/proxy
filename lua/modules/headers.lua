local _M = {}

---Get the first header value from a table of headers
---@param headers table<string, string|string[]>
---@param name string
---@return string|nil
function _M.get_first(headers, name)
  local value = headers[name]
  if value == nil then
    return nil
  end

  if type(value) == "table" then
    return value[1]
  end

  return value
end

---Get a subset of headers from a table of headers
---@param headers table<string, string|string[]>
---@param subset string[]
---@return table<string, string>
function _M.get_subset(headers, subset)
  local result = {}
  for _, name in ipairs(subset) do result[name] = _M.get_first(headers, name) end
  return result
end

---Add headers to the requests
---@param headers table<string, string>
function _M.add_to_request(headers)
  for name, value in pairs(headers) do
    ngx.req.set_header(name, value)
  end
end

return _M
