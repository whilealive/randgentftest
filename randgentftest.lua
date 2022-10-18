-- ==================================================================
-- FILE     randgentftest.lua
-- INFO     
--
-- DATE     18.10.2022
-- OWNER    Bischofberger
-- ==================================================================
--
-- TODO:
-- - Wenn Ordner fehlt (Kapitel/wahr/falsch, dann tex.warning ausgeben aber weitermachen)
-- - setTrueFalseDir() vereinfachen, globale Variablen evtl. eliminieren


-- OS checker
-- reference: https://stackoverflow.com/questions/295052/how-can-i-determine-the-os-of-the-system-from-within-a-lua-script
local function currentOS()
  local sep = package.config:sub(1,1)
  if     sep == "/"  then return "LinuxOrMac"
  elseif sep == "\\" then return "Windows"
  else                    return "Other"
  end
end


--- Check if a file or directory exists in this path
local function exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end


--- Check if a directory exists in this path
local function isdir(dir)
   -- "/" works on both Unix and Windows
   local ok, err = exists(dir.."/")
   if not ok then
    tex.error("randgentftest error: given folder \"" .. dir .. "\" does not exist")
  end
  return ok, err
end


local function tableisempty(tbl)
  return not next(tbl)
end


-- append all elements of tbl2 to the end of tbl1
function concat(tbl1, tbl2)
  for i = 1, #tbl2 do
    table.insert(tbl1, tbl2[i])
  end
  return tbl1
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


local function strtrim(str)
  return string.gsub(str, "^%s*(.-)%s*$", "%1")
end


-- generic string split function
local function strsplit(str, sep)
  local strlist = {}
  for token in string.gmatch(str, sep) do
    table.insert(strlist, token)
  end
  return strlist
end


-- split string on a comma
local function csvsplit(str)
  return strsplit(strtrim(str), "([^,]+),?%s*")
end


-- split string on new lines
local function newlinesplit(str)
  return strsplit(str, "[^\n]+")
end


-- split "key=value" pairs
local function keyvaluesplit(pair)
  local key, val = string.match(pair, "([%a%s]+)%s*=%s*([%a%s]+)")
  return key, val
end


local function parseTeXdirstring(parentdir, subdirstr)
  -- subdirstr is a comma separated list of subfolders of parentdir
  local dirlist = csvsplit(subdirstr)

  -- complete all dir paths with currentdir/parendir to absolute paths
  local sep = getfolderpathseparator()

  for i = 1, #dirlist do
    dirlist[i] = lfs.currentdir() .. sep .. parentdir .. sep .. dirlist[i] .. sep
  end

  return dirlist
end


local function parseTrueFalseDirs(tdir, fdir)
  local tfdirs = { t = tdir, f = fdir }

  -- we really need the "/" at the end here (OS-independent)
  -- since the LaTeX input mechanism uses /-separators only 
  for _, v in pairs(tfdirs) do
    if string.sub(v, -1) ~= "/" then
      v = v .. "/"
    end
  end

  return tfdirs
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


local function getfileextension(fn)
  return fn:match("^.+(%..+)$")
end


-- TODO: this is bad. how do we handle files without extensions?
local function isValidTeXFile(fn)
  return getfileextension(fn) == ".tex"
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


local function listTeXfiles(dir)
  local fnlist = {}

  for fn in dirtree(dir) do
    if isValidTeXFile(fn) then
      table.insert(fnlist, fn)
    end
  end

  if currentOS() == "Windows" then 
    changePathsToUnixStyle(fnlist) 
  end

  return fnlist
end


-- Fisher-Yates shuffle
-- reference: https://gist.github.com/Uradamus/10323382
local function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
end


local function getCheckboxtype(fn, tdir)
  local boxtype = ""
  if string.find(fn, tdir, 1, true) then
    boxtype = "[\\getCheckedbox]"
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


local function printCheckedChecklist(--[[required]]tbl, --[[required]] tdir, --[[optional]]opt_printpath, --[[optional]]opt_solutions)
  if opt_solutions then
    tex.sprint("\\section*{Lösungen}")
  end
  tex.sprint("\\begin{checklist}\\par")
  for i = 1, #tbl do
    local boxtype = getCheckboxtype(tbl[i], tdir)
    tex.sprint("\\item" .. boxtype .. "\\input{\\dq " .. tbl[i] .. "\\dq} \\par")
    if opt_printpath then
      tex.sprint("\\begin{minipage}{\\linewidth}\\footnotesize\\verb+" .. tbl[i] .. "+\\end{minipage}\\par")
    end
  end
  tex.sprint("\\end{checklist}\\clearpage")
end


-- split and save LaTeX string
-- "key1 = value1, key2 = value2, key3 = value3, ..."
-- in a table {{key=k1, value=v1}, {key=k2, value=v2}, {key=k3, value=v3}, ...}
local function parseTeXfilterstring(filterstr)
  if not filterstr then
    return {}
  end

  local tmplist = csvsplit(filterstr)
  local filterlist = {}
  for i = 1, #tmplist do
    local k, v = keyvaluesplit(tmplist[i])
    table.insert(filterlist, {key=k, value=v})
  end
  return filterlist
end


-- read entire file and return as string
local function readfile(path)
  local file = assert(io.open(path, "r"))
  local str = file:read("a")
  -- TODO: if "path" is a folder str is equal to nil
  --       --> error handling?
  file:close()
  return str
end


local function nocase(str)
  local pattern = string.gsub(str, "%a", function(c) 
                    return "[" .. string.lower(c) .. string.upper(c) .. "]"
                  end)
  return pattern
end


local function lineHasKeyValue(str, key, value)
  return string.find(str, key) and string.find(str, nocase(value))
end


local function fileHasKeyValue(file, key, value)
  local linelist = newlinesplit(readfile(file))
  for i = 1, #linelist do
    if lineHasKeyValue(linelist[i], key, value) then
      return true
    end
  end
  return false
end


local function filematchesfilterlist(file, filterlist)
  for i=1, #filterlist do
    if not fileHasKeyValue(file, filterlist[i].key, filterlist[i].value) then
      return false
    end
  end

  return true
end


local function filter(dirlist, filterlist)
  if tableisempty(filterlist) then
    return dirlist
  end

  local dirlist_filtered = {}

  for i=1, #dirlist do
    if filematchesfilterlist(dirlist[i], filterlist) then
      table.insert(dirlist_filtered, dirlist[i])
    end
  end

  return dirlist_filtered
end


local function collateStatements(dirlist, tfdirs, filterlist, numberOfTrueStatements, numberOfFalseStatements)
  local fnlistTrue  = {}
  local fnlistFalse = {}

  for i = 1, #dirlist do
    concat(fnlistTrue,  listTeXfiles(dirlist[i] .. tfdirs.t))
    concat(fnlistFalse, listTeXfiles(dirlist[i] .. tfdirs.f))
  end

  local fnlistTrue_filtered  = filter(fnlistTrue, filterlist)
  local fnlistFalse_filtered = filter(fnlistFalse, filterlist)

  if numberOfTrueStatements > #fnlistTrue_filtered or 
     numberOfFalseStatements > #fnlistFalse_filtered then
    tex.error("randgentftest error: number of chosen statements is higher than what we have in the folder")
    return {}
  end

  local fnlistMixed_filtered = {}

  for i = 1, numberOfTrueStatements do
    local fn = table.remove(fnlistTrue_filtered, math.random(#fnlistTrue_filtered))
    table.insert(fnlistMixed_filtered, fn)
  end
  for i = 1, numberOfFalseStatements do
    local fn = table.remove(fnlistFalse_filtered, math.random(#fnlistFalse_filtered))
    table.insert(fnlistMixed_filtered, fn)
  end

  shuffle(fnlistMixed_filtered)

  return fnlistMixed_filtered
end






-- --------------------------------------------
-- global functions - to be called from outside
-- --------------------------------------------

-- global: to be called from outside
-- main routine for printing random generated tests
function createRandGenTest(parentdir, subdirstr, tdir, fdir, numberOfTrueStatements, numberOfFalseStatements, filterstr, --[[optional]]bool_printSolutions, --[[optional]]bool_printFilePaths)
  if not isdir(parentdir) then
    return false
  end

  -- fill a list of absolute paths to all subfolders
  local dirlist = parseTeXdirstring(parentdir, subdirstr)

  -- set names of true/false subfolders
  local tfdirs = parseTrueFalseDirs(tdir, fdir)

  local filterlist = parseTeXfilterstring(filterstr)

  -- create a randomly collated statement list
  local fnlist_mixed_filtered = collateStatements(dirlist, tfdirs, filterlist, numberOfTrueStatements, numberOfFalseStatements)

  if tableisempty(fnlist_mixed_filtered) then
    return false
  end

  -- TeX output
  printChecklist(fnlist_mixed_filtered)

  if bool_printSolutions then
    printCheckedChecklist(fnlist_mixed_filtered, tfdirs.t, bool_printFilePaths, true)
  end
end


-- global: to be called from outside
-- main routine to print the entire library
function printAll(parentdir, tdir, fdir, filterstr, --[[optional]]opt_printpath)
  if not isdir(parentdir) then
    return false
  end

  local sep = getfolderpathseparator()
  local tfdirs = parseTrueFalseDirs(tdir, fdir)
  local fnlist = listTeXfiles(lfs.currentdir()..sep..parentdir)

  local filterlist = parseTeXfilterstring(filterstr)
  local fnlist_filtered  = filter(fnlist, filterlist)

  table.sort(fnlist_filtered)

  printCheckedChecklist(fnlist_filtered, tfdirs.t, opt_printpath, false)
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
    tex.sprint("|" .. strlist[i] .. "|\\par")
  end
end

function debug.printfilterlist(filterlist)
  if tableisempty(filterlist) then
    tex.sprint("filter list is empty\\par")
  end
  for i = 1, #filterlist do
    tex.sprint("key= " .. "|" .. filterlist[i].key .. "|" .. "\\par")
    tex.sprint("value= " .. "|" .. filterlist[i].value .. "|" .. "\\par")
  end
end

function debug.printfilterstring(str)
  local filterlist = parseTeXfilterstring(str)
  if tableisempty(filterlist) then
    tex.sprint("filter list is empty\\par")
  end
  for i = 1, #filterlist do
    tex.sprint("key: " .. "|" .. filterlist[i].key .. "|" .. "\\par")
    tex.sprint("value: " .. "|" .. filterlist[i].value .. "|" .. "\\par")
  end
end

function debug.testfilechecker(parentdir)
  local sep = getfolderpathseparator()
  local fnlist = {} listTeXfiles(lfs.currentdir()..sep..parentdir)
  table.sort(fnlist)
  for i = 1, #fnlist do
    if fileHasKeyValue(fnlist[i], "VERFASSER", "Bruno Bischofberger") then
      tex.sprint("has it:" .. "\\verb+" .. fnlist[i] .. "+\\par")
    end
  end
end

function debug.printFileLines(strlist)
  for i = 1, #strlist do
    tex.sprint(strlist[i] .. "\\par")
  end
end

