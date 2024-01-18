local _M = {}

---Merge two tables into a new table. Duplicate keys are overwritten by the second table.
---@param a table
---@param b table
---@return table
function _M.merge(a, b)
  local result = {}

  for k, v in pairs(a) do
    result[k] = v
  end

  for k, v in pairs(b) do
    result[k] = v
  end

  return result
end

---Merge two tables into the first table. Duplicate keys are overwritten by the second table.
---@param a table
---@param b table
function _M.merge_into(a, b)
  for k, v in pairs(b) do
    a[k] = v
  end
end

---Apply defaults to a table. If the table is nil, then the defaults are returned.
---@param opts? table
---@param defaults table
---@return table
function _M.with_defaults(opts, defaults)
  if opts ~= nil then
    _M.merge_into(defaults, opts)
  end

  return defaults
end

return _M
