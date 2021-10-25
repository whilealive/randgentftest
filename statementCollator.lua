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


-- Fisher-Yates shuffle
function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  --return tbl
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


function collateStatements(dir, numberOfTrueStatements, numberOfFalseStatements)
  local trueDir=dir.."01-wahr/"
  local falseDir=dir.."02-falsch/"

  local filenamesTrue=collectValidFiles(trueDir)
  local filenamesFalse=collectValidFiles(falseDir)

  if numberOfTrueStatements > #filenamesTrue or numberOfFalseStatements > #filenamesFalse then
    tex.error("number of chosen statements is higher than what we have in the folder")
  end

  filenamesMixed = {}  -- global

  local counter = 1
  for i = numberOfTrueStatements, 1, -1 do
    local j = math.random(i)
    filenamesMixed[counter] = {filename = filenamesTrue[j], answer = true, dir=trueDir}
    table.remove(filenamesTrue, j)
    counter = counter + 1
  end
  for i = numberOfFalseStatements, 1, -1 do
    local j = math.random(i)
    filenamesMixed[counter] = {filename = filenamesFalse[j], answer = false, dir=falseDir}
    table.remove(filenamesFalse, j)
    counter = counter + 1
  end

--[[
  for i = 1, #filenamesTrue do
    filenamesMixed[i] = {filename = filenamesTrue[i], answer = true, dir=trueDir}
  end
  for i = 1, #filenamesFalse do
    filenamesMixed[#filenamesTrue + i] = {filename = filenamesFalse[i], answer = false, dir=falseDir}
  end
  --]]

  shuffle(filenamesMixed)
end

function printStatements()
  tex.sprint("\\begin{checklist}\\par")
  for i = 1, #filenamesMixed do
    if filenamesMixed[i].answer then
      tex.sprint("\\item\\input " .. filenamesMixed[i].dir .. filenamesMixed[i].filename .. " " .. "\\par")
    else
      tex.sprint("\\item\\input " .. filenamesMixed[i].dir .. filenamesMixed[i].filename .. " " .. "\\par")
    end
  end
  tex.sprint("\\end{checklist}\\clearpage")
end


function printSolutions()
  tex.sprint("\\begin{checklist}\\par")
  for i = 1, #filenamesMixed do
    if filenamesMixed[i].answer then
      tex.sprint("\\item[\\checkedbox]\\input " .. filenamesMixed[i].dir .. filenamesMixed[i].filename .. " " .. "\\par")
    else
      tex.sprint("\\item\\input " .. filenamesMixed[i].dir .. filenamesMixed[i].filename .. " " .. "\\par")
    end
  end
  tex.sprint("\\end{checklist}")
end
