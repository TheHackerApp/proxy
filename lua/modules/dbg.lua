local _M = {}

---Convert any object to a string
---@param o any
---@param shallow? boolean
---@return string
function _M.stringify(o, shallow)
  local stringifier = _M.stringify
  if shallow then
    stringifier = tostring
  end

  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. stringifier(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

---Log the contents of any object
---@param o any
---@param shallow? boolean
function _M.dump(o, shallow)
  print(_M.stringify(o, shallow))
end

return _M
