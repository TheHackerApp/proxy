local Set = {}
Set.__index = Set

---Create a new set
---@param list table
---@return table
function Set.new(list)
  local set = {}
  setmetatable(set, Set)

  if list ~= nil then
    for _, l in ipairs(list) do set[l] = true end
  end

  return set
end

---Insert a new element into the set
---@param value any
function Set:add(value)
  self[value] = true
end

---Remove an element from the set
---@param value any
function Set:remove(value)
  self[value] = nil
end

---Check if the set contains an element
---@param value any
---@return boolean
function Set:contains(value)
  return self[value] ~= nil
end

return Set
