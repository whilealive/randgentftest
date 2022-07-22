-- ==================================================================
-- FILE     spare.lua
-- INFO     
--
-- DATE     26.11.2021
-- OWNER    Bischofberger
-- ==================================================================


local Folder = { 
  Top = "Fragesammlung", 
  Ausrichtung = { alle = "01-Alle", TALS = "02-TALS", GESO = "03-GESO", DL = "04-DL" },
  Wahrheitsgehalt = { wahr = "01-wahr", falsch = "02-falsch" },
}
--01-Algebra
--02-Potenzrechnen
--03-Lineare-Gleichungen
--04-Lineare-Gleichungssysteme
--05-Quadratische-Gleichungen
--06-Nichtlineare-Gleichungen
--07-Lineare-Funktionen
--08-Quadratische-Funktionen
--09-Potenzfunktionen
--10-Polynomfunktionen
--11-Exponentialfunktionen
--12-Datenanalyse
--13-Wahrscheinlichkeitsrechnen
--14-Planimetrie-I
--15-Planimetrie-II
--16-Trigonometrie-I
--17-Trigonometrie-II
--18-Stereometrie




-- TODO: - «filenames» is unsorted but we must have filesystem order
--       - how to determine if statement is true/false? We need this information for a 
--         checked version
--       - where to save full path of files in order to include it by \input?
--         -> see «collectValidFiles()»
function printAll(dir)
  local filenames = collectValidFiles(dir)  -- collects files recursively, incl. subfolders!
  tex.sprint("\\begin{checklist}\\par")
  for fn in filenames do
    tex.sprint("\\item\\input " .. tbl[i].dir .. fn .. " " .. "\\par")
  end
  tex.sprint("\\end{checklist}")
end




-- Erforderliche Ordnerstruktur: 
-- \Sammlungsordner/01-Algebra/
-- \Sammlungsordner/02-Lineare-Gleichungen/
-- \Sammlungsordner/03-Lineare-Gleichungssysteme/
-- ...




------------------------------------------------------------------------------------------------------------------------------
-- understanding dirtree:
--
-- dirtree iterator
-- reference: http://lua-users.org/wiki/DirTreeIterator
local function dirtree(dir)
  local sep = getfolderpathseparator()

  if string.sub(dir, -1) == sep then
    dir=string.sub(dir, 1, -2)
  end

  local function yieldtree(dir)
    for entry in lfs.dir(dir) do      -- lfs.dir(path): iterator over entries of given directory
      if not entry:match("^%.") then  -- don't follow directories that start with a dot
        entry = dir .. sep .. entry   -- complete path with parent folder(s)
        if lfs.isdir(entry) then
          yieldtree(entry)
        else
          coroutine.yield(entry)      -- suspend coroutine and let coroutine.resume return entry
        end
      end
    end
  end

  return coroutine.wrap(function() yieldtree(dir) end)  -- create coroutine and return a function that resumes it when called
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
------------------------------------------------------------------------------------------------------------------------------
