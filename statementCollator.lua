-- ==================================================================
-- FILE     statementCollator.lua
-- INFO     
--
-- DATE     06.07.2022
-- OWNER    Bischofberger
-- ==================================================================


-- OS checker
-- reference: https://stackoverflow.com/questions/295052/how-can-i-determine-the-os-of-the-system-from-within-a-lua-script
local function currentOS()
  local sep = package.config:sub(1,1)
  if     sep == "/"  then return "LinuxOrMac"
  elseif sep == "\\" then return "Windows"
  else                    return "Other"
  end
end


-- unix like: parentfolder/subfolder
-- windows:   parentfolder\subfolder
local function getfolderpathseparator()
  local sep = "/"
  if currentOS() == "Windows" then
    sep = "\\"
  end
  return sep
end


local function csvsplit(str)
  local strlist = {}
  for token in string.gmatch(str, "([^,]+),%s*") do
    table.insert(strlist, token)
  end
  return strlist
end


-- split key=value pairs
local function keyvaluesplit(pair)
  local key, val = string.match(pair, "([%a%s]+)%s*=%s*([%a%s]+)")
  return key, val
end


local function completePaths(parentdir, subdirstr)
  -- subdirstr is a comma separated list of subfolders of parentdir
  local dirlist = csvsplit(subdirstr)

  -- complete all dir paths with currentdir/parendir to absolute paths
  local sep = getfolderpathseparator()

  for i = 1, #dirlist do
    dirlist[i] = lfs.currentdir() .. sep .. parentdir .. sep .. dirlist[i] .. sep
  end

  return dirlist
end


-- set global true/false subfolders
trueStatementsDir  = "01-wahr/"
falseStatementsDir = "02-falsch/"

local function setTrueFalseDir(nameOfTrueDir, nameOfFalseDir)
  trueStatementsDir  = nameOfTrueDir
  falseStatementsDir = nameOfFalseDir
  -- we really need the "/" at the end here (OS-independent)
  -- since the LaTeX input mechanism uses /-separators only 
  if string.sub(trueStatementsDir, -1) ~= "/" then
    trueStatementsDir = trueStatementsDir .. "/"
  end
  if string.sub(falseStatementsDir, -1) ~= "/" then
    falseStatementsDir = falseStatementsDir .. "/"
  end
end


-- dirtree iterator
-- reference: http://lua-users.org/wiki/DirTreeIterator
local function dirtree(dir)
  local sep = getfolderpathseparator()

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


-- Folders in paths from lua's LuaFileSystem (lfs) library are
-- separated by the OS-specific separator / or \.
-- LaTeX's input macro uses /-separators only, so we have to
-- convert paths from OS-dependent to LaTeX internal style.
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


-- Fisher-Yates shuffle
-- reference: https://gist.github.com/Uradamus/10323382
local function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  --return tbl
end


local function collateStatements(dirlist, numberOfTrueStatements, numberOfFalseStatements)
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


local function printChecklist(tbl)
  tex.sprint("\\begin{checklist}\\par")
  for i = 1, #tbl do
    tex.sprint("\\item\\input{\\dq " .. tbl[i] .. "\\dq} \\par")
  end
  tex.sprint("\\end{checklist}\\clearpage")
end


local function printCheckedChecklist(--[[required]]tbl, --[[optional]]opt_printpath)
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


local function getfilterlist(filterstr)
  local filterlist = {}
  local templist = csvsplit(filterstr)
  for i = 1, #templist do
    local k, v = keyvaluesplit(templist[i])
    table.insert(filterlist, {key=k, value=v})
  end
  return filterlist
end



-- --------------------------------------------
-- global functions - to be called from outside
-- --------------------------------------------

-- global: to be called from outside
-- main routine for printing random generated tests
function createRandGenTest(parentdir, subdirstr, trueDir, falseDir, numberOfTrueStatements, numberOfFalseStatements, filterlist, --[[optional]]bool_printSolutions, --[[optional]]bool_printFilePaths)

  -- fill a list of absolute paths to all subfolders
  local dirlist = completePaths(parentdir, subdirstr)

  -- set names of true/false subfolders
  setTrueFalseDir(trueDir, falseDir)

  -- create a randomly collated statement list
  local mixedstatementlist = collateStatements(dirlist, numberOfTrueStatements, numberOfFalseStatements)

  -- TODO: filter here...

  printChecklist(mixedstatementlist)

  if bool_printSolutions then
    printCheckedChecklist(mixedstatementlist, bool_printFilePaths)
  end
end


-- global: to be called from outside
-- main routine to print the entire library
function printAll(--[[required]]parentdir, --[[optional]]opt_printpath)
  local fnlist = {}

  local sep = getfolderpathseparator()
  collectValidFiles(lfs.currentdir()..sep..parentdir, fnlist)

  table.sort(fnlist)

  printCheckedChecklist(fnlist, opt_printpath)
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

function debug.csvsplit(str)
  local strlist = csvsplit(str);
  for i = 1, #strlist do
    tex.sprint(strlist[i] .. "\\par")
  end
end

function debug.printfilterlist(str)
  local filterlist = getfilterlist(str)
  for i = 1, #filterlist do
    tex.sprint("key= " .. filterlist[i].key .. "\\par")
    tex.sprint("value= " .. filterlist[i].value .. "\\par")
  end
end
