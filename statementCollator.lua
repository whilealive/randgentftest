-- ==================================================================
-- FILE     statementCollator.lua
-- INFO     
--
-- DATE     04.07.2022
-- OWNER    Bischofberger
-- ==================================================================


-- TODO: diese müssen von aussen manipulierbar sein
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


function csvsplit(str)
  local strlist = {}
  for token in string.gmatch(str, "([^,]+),%s*") do
    table.insert(strlist, token)
  end
  return strlist
end


function addprepoststring(strlist, prestring, poststring)
  for i = 1, #strlist do
    strlist[i] = prestring .. strlist[i] .. poststring
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


local function GetFileExtension(fn)
  return fn:match("^.+(%..+)$")
end


local function isValidTexFile(fn)
  if GetFileExtension(fn) ~= ".tex" then
    return false
  end
  return true
end


local function changePathsToUnixStyle(tbl)
  for i = 1, #tbl do
    tbl[i] = string.gsub(tbl[i], '\\', '/')
  end
end


local function collectValidFiles(dir, fnlist)
  for fn in dirtree(dir) do
    if isValidTexFile(fn) then
      table.insert(fnlist, fn)
    end
  end

  if currentOS() == "Windows" then 
    changePathsToUnixStyle(fnlist) 
  end
end


-- statt dir, wird dirlist übergeben, dann
-- for dir in dirlist do ...
function collateStatements(dirlist, numberOfTrueStatements, numberOfFalseStatements)
  local fnlistTrue  = {}
  local fnlistFalse = {}

  for i = 1, #dirlist do
    collectValidFiles(dirlist[i] .. trueStatementsDir,  fnlistTrue)
    collectValidFiles(dirlist[i] .. falseStatementsDir, fnlistFalse)
  end

  if numberOfTrueStatements > #fnlistTrue or numberOfFalseStatements > #fnlistFalse then
    tex.error("number of chosen statements is higher than what we have in the folder")
    return {}
  end

  local fnlistMixed = {}

  for i = 1, numberOfTrueStatements do
    local fn = table.remove(fnlistTrue, math.random(#fnlistTrue))
    table.insert(fnlistMixed, fn)
  end
  for i = 1, numberOfFalseStatements do
    local fn = table.remove(fnlistFalse, math.random(#fnlistFalse))
    table.insert(fnlistMixed, fn)
  end

  shuffle(fnlistMixed)

  return fnlistMixed
end


local function getCheckboxtype(fn)
  local boxtype = ""
  if string.find(fn, trueStatementsDir, 1, true) then
    boxtype = "[\\checkedbox]"
  end
  return boxtype
end


function printStatements(tbl)

  tex.sprint("\\begin{checklist}\\par")
  for i = 1, #tbl do
    tex.sprint("\\item\\input{\\dq " .. tbl[i] .. "\\dq} \\par")
  end
  tex.sprint("\\end{checklist}\\clearpage")
end


function printSolutions(--[[required]]tbl, --[[optional]]opt_printpath)
  tex.sprint("\\section*{Lösungen}")  -- TODO: diese Zeile sollte bei Verwendung innerhalb PrintAll() nicht kommen
  tex.sprint("\\begin{checklist}\\par")
  for i = 1, #tbl do
    local boxtype = getCheckboxtype(tbl[i])
    tex.sprint("\\item" .. boxtype .. "\\input{\\dq " .. tbl[i] .. "\\dq} \\par")
    if opt_printpath then
      tex.sprint("\\begin{minipage}{\\linewidth}\\footnotesize\\verb+" .. tbl[i] .. "+\\end{minipage}\\par")
    end
  end
  tex.sprint("\\end{checklist}\\clearpage")
end


function printAll(--[[required]]dir, --[[optional]]opt_printpath)
  local fnlist = {}
  collectValidFiles(dir, fnlist)

  table.sort(fnlist)

  printSolutions(fnlist, opt_printpath)
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


function debug.csvsplit(str)
  local strlist = csvsplit(str);
  for i = 1, #strlist do
    tex.sprint(strlist[i] .. "\\par")
  end
end
