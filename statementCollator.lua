-- ==================================================================
-- FILE     statementCollator.lua
-- INFO     
--
-- DATE     18.10.2021
-- OWNER    Bischofberger
-- ==================================================================

-- dirtree iterator:
-- to be found at: http://lua-users.org/wiki/DirTreeIterator
function dirtree(dir)
  if string.sub(dir, -1) == "/" then
    dir=string.sub(dir, 1, -2)
  end

  local function yieldtree(dir)
    for entry in lfs.dir(dir) do
      if not entry:match("^%.") then
        entry=dir.."/"..entry
          if lfs.isdir(entry) then
            yieldtree(entry)
          else
            coroutine.yield(entry)
          end
      end
    end
  end

  return coroutine.wrap(function() yieldtree(dir) end)
end


function GetFileExtension(filename)
  return filename:match("^.+(%..+)$")
end


function isValidTexFile(filename)
  --if filename:match("_QuickCompile") then
  --  return false
  --end
  if GetFileExtension(filename) ~= ".tex" then
    return false
  end
  return true
end


function collectValidFiles(dir)
  -- Lua doesn't guarantee any iteration order for the associative part of the table!
  -- Therefore, we must order the entries manually
  local filenames = {}

  for i in dirtree(dir) do
    local filename = i:gsub(".*/([^/]+)$","%1")
    if isValidTexFile(filename) then
      table.insert(filenames, filename)
    end
  end

  table.sort(filenames)

  return filenames
end


function collateStatements(dir)
  local trueDir=dir.."01-wahr/"
  local falseDir=dir.."02-falsch/"

  local filenamesTrue=collectValidFiles(trueDir)
  local filenamesFalse=collectValidFiles(falseDir)

  for i = 1, #filenamesTrue do
    tex.sprint("\\item[\\checkedbox]\\input " .. trueDir .. filenamesTrue[i] .. " " .. "\\par")
  end

  for i = 1, #filenamesFalse do
    tex.sprint("\\item\\input " .. falseDir .. filenamesFalse[i] .. " " .. "\\par")
  end
end
