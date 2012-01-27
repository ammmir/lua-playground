-- tst.lua
-- Ternary search tree
--
-- Translated to Lua by Amir Malik
-- Based on tst.py from https://bitbucket.org/woadwarrior/trie
--
-- API:
--   TernarySearchTree()
--     :add("key", value)
--     :search("key" --> return one value if it exists, otherwise nil
--     :prefix_search("ke") --> returns an "iterator" over the values

module("tst", package.seeall)

local yield = coroutine.yield

local function as_list(p)
  --local list = {}
  local stack = {}
  
  if p == nil then return nil end
  
  while p do
    if p.right then table.insert(stack, p.right) end
    if p.middle then table.insert(stack, p.middle) end
    if p.left then table.insert(stack, p.left) end
    
    --if p.value then table.insert(list, p.value) end
    if p.value then yield(p.value) end
    
    if stack == nil then break end
    
    p = table.remove(stack)
  end
  
  --return list
end

function TernarySearchTree(ch)
  local object = {
    splitchar = ch,
    left = nil,
    middle = nil,
    right = nil,
    value = nil,
    
    add = function(self, key, value)
      return self:insert(self, key, value)
    end,
    
    insert = function(self, p, key, value)
      local c = key:sub(1, 1)
      
      if p == nil then
        p = TernarySearchTree(c)
      elseif p.splitchar == nil then
        p.splitchar = c
      end
      
      if c < p.splitchar then
        p.left = self:insert(p.left, key, value)
      elseif c == p.splitchar then
        key = key:sub(2)
        if key ~= "" then
          p.middle = self:insert(p.middle, key, value)
        else
          p.value = value
        end
      else
        p.right = self:insert(p.right, key, value)
      end
      
      return p
    end,
    
    search = function(self, s)
      local p = self
      
      while p do
        local c = s:sub(1, 1)
        
        if c < p.splitchar then
          p = p.left
        elseif c == p.splitchar then
          s = s:sub(2)
          if s == "" then
            if p.value then return p.value end
            break
          end
          
          p = p.middle
        else
          p = p.right
        end
      end
      
      return nil
    end,
    
    prefix_search = function(self, s)
      local p = self
      
      while p do
        local c = s:sub(1, 1)
        
        if c < p.splitchar then
          p = p.left
        elseif c == p.splitchar then
          s = s:sub(2)
          if s == "" then
            --return as_list(p)
            return coroutine.wrap(function() as_list(p) end)
          end
          
          p = p.middle
        else
          p = p.right
        end
      end
      
      --return {}
      return coroutine.wrap(function() yield(nil) end)
    end,
  }
  
  -- convenience methods
  setmetatable(object, {
    __tostring = function(t)
      stack = {}
      local p = t
      local s = ""
      
      if p == nil then return "<empty table>" end
      
      while p do
        if p.right then table.insert(stack, p.right) end
        if p.middle then table.insert(stack, p.middle) end
        if p.left then table.insert(stack, p.left) end
        
        if p.value then
          if type(p.value) == "table" then
            s = s .. "  table\n"
            for _, v in pairs(p.value) do
              s = s .. "    " .. v .. "\n"
            end
          else
            s = s .. "  " .. p.value .. "\n"
          end
        end
        
        if stack == nil then break end
        
        p = table.remove(stack)
      end
      
      return s
    end,
  })
  
  return object
end
