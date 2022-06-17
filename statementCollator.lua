-- ==================================================================
-- FILE     statementCollator.lua
-- INFO     
--
-- DATE     13.06.2022
-- OWNER    Bischofberger
-- ==================================================================


trueStatementsDir  = "01-wahr/"
falseStatementsDir = "02-falsch/"


-- OS checker
-- reference: https://stackoverflow.com/questions/295052/how-can-i-determine-the-os-of-the-system-from-within-a-lua-script
local function currentOS()
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


function getPathSeparator()
  local sep = "/"
  if currentOS() == "Windows" then 
    sep = "\\"
  end
  return sep
end


-- dirtree iterator
-- reference: http://lua-users.org/wiki/DirTreeIterator
local function dirtree(dir)
  local sep = getPathSeparator()
  
  if string.sub(dir, -1) == sep then
    dir=string.sub(dir, 1, -2)
  end

  local function yieldtree(dir)
    for entry in lfs.dir(dir) do
      if not entry:match("^%.") then
        entry = dir .. sep .. entry
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
  if GetFileExtension(filename) ~= ".tex" then
    return false
  end
  return true
end


local function collectValidFiles(dir)
  local regex = ".*/([^/]+)$"
  if currentOS() == "Windows" then 
    regex = ".*\\([^/]+)$"
  end

  local fnlist = {}

  for i in dirtree(dir) do
    local fn = i:gsub(regex,"%1")
    if isValidTexFile(fn) then
      table.insert(fnlist, fn)
    end
  end

  return fnlist
end


function collateStatements(dir, numberOfTrueStatements, numberOfFalseStatements)
  local trueDir  = dir .. trueStatementsDir 
  local falseDir = dir .. falseStatementsDir 

  local fnlistTrue  = collectValidFiles(trueDir)
  local fnlistFalse = collectValidFiles(falseDir)

  if numberOfTrueStatements > #fnlistTrue or numberOfFalseStatements > #fnlistFalse then
    tex.error("number of chosen statements is higher than what we have in the folder")
    return {}
  end

  local fnlistMixed = {}

  for i = 1, numberOfTrueStatements do
    local fn = table.remove(fnlistTrue, math.random(#fnlistTrue))
    table.insert(fnlistMixed, {filename = fn, answer = true, dir=trueDir})
  end
  for i = 1, numberOfFalseStatements do
    local fn = table.remove(fnlistFalse, math.random(#fnlistFalse))
    table.insert(fnlistMixed, {filename = fn, answer = false, dir=falseDir})
  end

  shuffle(fnlistMixed)

  return fnlistMixed
end


local function changePathsToUnixStyle(tbl)
  for i = 1, #tbl do
    tbl[i].dir = string.gsub(tbl[i].dir, '\\', '/')
  end
end


-- TODO: merge printStatements() and printSolutions() - they have too many identical parts
--
function printStatements(tbl)
  if currentOS() == "Windows" then 
    changePathsToUnixStyle(tbl) 
  end

  tex.sprint("\\begin{checklist}\\par")
  for i = 1, #tbl do
    tex.sprint("\\item\\input " .. tbl[i].dir .. tbl[i].filename .. " \\par")
  end
  tex.sprint("\\end{checklist}\\clearpage")
end


function printSolutions(tbl)
  if currentOS() == "Windows" then 
    changePathsToUnixStyle(tbl) 
  end

  tex.sprint("\\section*{Lösungen}")
  tex.sprint("\\begin{checklist}\\par")
  for i = 1, #tbl do
    local boxtype = ""
    if tbl[i].answer then
      boxtype = "[\\checkedbox]"
    end
    tex.sprint("\\item" .. boxtype .. "\\input " .. tbl[i].dir .. tbl[i].filename .. " \\par")
  end
  tex.sprint("\\end{checklist}")
end


--local escape_lua_pattern
--do
--  local matches =
--  {
--    ["^"] = "%^";
--    ["$"] = "%$";
--    ["("] = "%(";
--    [")"] = "%)";
--    ["%"] = "%%";
--    ["."] = "%.";
--    ["["] = "%[";
--    ["]"] = "%]";
--    ["*"] = "%*";
--    ["+"] = "%+";
--    ["-"] = "%-";
--    ["?"] = "%?";
--  }
--
--  escape_lua_pattern = function(s)
--    return (s:gsub(".", matches))
--  end
--end


function printAll(--[[required]]dir, --[[optional]]opt_printpath)
  local opt_printpath = (opt_printpath ~= false)  -- default is true

  local regex = ".*/([^/]+)$"
  if currentOS() == "Windows" then 
    regex = ".*\\([^/]+)$"
  end

  local filenames = {}
  --local currentdir = escape_lua_pattern(lfs.currentdir())

  for fn in dirtree(dir) do
    local fnonly = fn:gsub(regex,"%1")
    if isValidTexFile(fnonly) then
      --local fnnpath = string.gsub(fn, currentdir.."/", "")
      --table.insert(filenames, fnnpath)
      table.insert(filenames, fn)
    end
  end

  table.sort(filenames)

    --tex.sprint("\\input " .. filenames[1] .. " " .. "\\par")
    --tex.sprint("\\input " .. filenames[2] .. " " .. "\\par")
    --tex.sprint("\\input " .. filenames[3] .. " " .. "\\par")
  
    tex.sprint("\\begin{checklist}\\par")
    for i = 1, #filenames do
      local boxtype = ""
      if string.find(filenames[i], trueStatementsDir, 1, true) then
        boxtype = "[\\checkedbox]"
      end
      tex.sprint("\\item" .. boxtype .. "\\input " .. filenames[i] .. " \\vskip 1ex")
      if opt_printpath then
        tex.sprint("\\begin{minipage}{\\linewidth}\\footnotesize\\verb+" .. filenames[i] .. "+\\end{minipage}\\par")
      end
      --tex.sprint("\\verb+" .. string.gsub(filenames[i], currentdir.."/", "") .. "+\\par")
    end
    tex.sprint("\\end{checklist}")

  --for i = 1, #filenames do
  --  tex.sprint("\\verb+" .. filenames[i] .. "+\\par")
  --end
  --tex.sprint("\\verb+" .. lfs.currentdir() .. "+\\par")
  --tex.sprint("\\verb+" .. blah .. "+\\par")
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


function debug.printInputFilenames(tbl)
  if currentOS() == "Windows" then 
    changePathsToUnixStyle(tbl) 
  end
  for i = 1, #tbl do
    tex.sprint("\\verb+" .. tbl[i].dir .. tbl[i].filename .. "+\\par")
  end
end
