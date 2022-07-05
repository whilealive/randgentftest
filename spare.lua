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

