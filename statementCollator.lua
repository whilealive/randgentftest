-- ==================================================================
-- FILE     statementCollator.lua
-- INFO     
--
-- DATE     29.11.2021
-- OWNER    Bischofberger
-- ==================================================================


-- OS checker
-- reference: https://stackoverflow.com/questions/295052/how-can-i-determine-the-os-of-the-system-from-within-a-lua-script
local function checkOS()
  local sep = package.config:sub(1,1)
  if     sep == "/"  then return "LinuxOrMac"
  elseif sep == "\\" then return "Windows"
  else                    return "Other"
  end
end


-- Fisher-Yates shuffle
-- reference: https://gist.github.com/Uradamus/10323382
local function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  --return tbl
end


-- dirtree iterator
-- reference: http://lua-users.org/wiki/DirTreeIterator
local function dirtree(dir)
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


local function GetFileExtension(filename)
  return filename:match("^.+(%..+)$")
end


local function isValidTexFile(filename)
  --if filename:match("_QuickCompile") then
  --  return false
  --end
  if GetFileExtension(filename) ~= ".tex" then
    return false
  end
  return true
end


local function collectValidFiles(dir)
  local filenames = {}

  for i in dirtree(dir) do
    local filename = i:gsub(".*/([^/]+)$","%1")
    if isValidTexFile(filename) then
      table.insert(filenames, filename)
    end
  end

  return filenames
end


function collateStatements(dir, numberOfTrueStatements, numberOfFalseStatements)
  local trueDir  = dir.."01-wahr/"
  local falseDir = dir.."02-falsch/"

  local filenamesTrue=collectValidFiles(trueDir)
  local filenamesFalse=collectValidFiles(falseDir)

  if numberOfTrueStatements > #filenamesTrue or numberOfFalseStatements > #filenamesFalse then
    tex.error("number of chosen statements is higher than what we have in the folder")
    return {}
  end

  local filenamesMixed = {}

  for i = 1, numberOfTrueStatements do
    local fn = table.remove(filenamesTrue, math.random(#filenamesTrue))
    table.insert(filenamesMixed, {filename = fn, answer = true, dir=trueDir})
  end
  for i = 1, numberOfFalseStatements do
    local fn = table.remove(filenamesFalse, math.random(#filenamesFalse))
    table.insert(filenamesMixed, {filename = fn, answer = false, dir=falseDir})
  end

  shuffle(filenamesMixed)

  return filenamesMixed
end


function printStatements(tbl)
  tex.sprint("\\begin{checklist}\\par")
  for i = 1, #tbl do
    tex.sprint("\\item\\input " .. tbl[i].dir .. tbl[i].filename .. " " .. "\\par")
  end
  tex.sprint("\\end{checklist}\\clearpage")
end


function printSolutions(tbl)
  tex.sprint("\\section*{Lösungen}")
  tex.sprint("\\begin{checklist}\\par")
  for i = 1, #tbl do
    if tbl[i].answer then
      tex.sprint("\\item[\\checkedbox]\\input " .. tbl[i].dir .. tbl[i].filename .. " " .. "\\par")
    else
      tex.sprint("\\item\\input " .. tbl[i].dir .. tbl[i].filename .. " " .. "\\par")
    end
  end
  tex.sprint("\\end{checklist}")
end







-----------------------
-- debugging section --
-----------------------
debug = {}

function debug.printdirtree(dir)
  for fn in dirtree(dir) do
    --fn = fn:gsub(".*/([^/]+)$","%1")
    tex.sprint("\\verb+" .. fn .. "+\\par")
  end
end
