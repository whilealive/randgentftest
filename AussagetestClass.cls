% ==================================================================
% FILE     AussagetestClass.cls
% INFO     
%
% DATE     15.06.2022
% OWNER    Bischofberger
% ==================================================================
% This work may be distributed and/or modified under the
% conditions of the LaTeX Project Public License, either version 1.3
% of this license or (at your option) any later version.
% The latest version of this license is in
%   http://www.latex-project.org/lppl.txt
% and version 1.3 or later is part of all distributions of LaTeX
% version 2005/12/01 or later.

\ProvidesClass{AussagetestClass}

\LoadClass[10pt]{article}
\RequirePackage[a4paper,textwidth=160mm,top=30mm,bottom=40mm]{geometry}  % extra wide
\RequirePackage[ngerman]{babel}
\RequirePackage[babel=true]{microtype}

\RequirePackage{amsfonts}
\RequirePackage{mathtools}
\RequirePackage[makeroom]{cancel}

\setlength{\parindent}{0pt}
\allowdisplaybreaks
\raggedbottom

\RequirePackage{fancyhdr}
\pagestyle{fancy}
\lhead{B\kern0.10em M\kern0.07em S Zürich}
\rhead{\thepage}
\cfoot{}
\chead[]{Aussagetest}

\RequirePackage{siunitx}
\sisetup{per-mode=symbol,exponent-product=\cdot}

\RequirePackage{tikz}
\usetikzlibrary{calc,angles,intersections,arrows.meta}
\tikzset{>={Latex}}

\RequirePackage[inline]{enumitem}
\newcommand*{\checkbox}{\tikz\draw (0,0) rectangle (.25,.25);}
\newcommand*{\checkedbox}{%
  \begin{tikzpicture}%
  \draw (0,0) rectangle (.25,.25);%
  \draw (0,0) -- (.25,.25);%
  \draw (.25,0) -- (0,.25);%
  \end{tikzpicture}%
  }%
\newlist{checklist}{itemize}{2}
\setlist[checklist,1,2]{label=\checkbox,leftmargin=*,nosep,align=left,itemsep=4ex}

\RequirePackage{pgfplots}
\pgfplotsset{compat=newest}
\pgfplotsset{axis lines=center,axis line style={-Latex}}




% ------------------------------------------------------------------
% variables
\newcommand*{\Sammlungsordner}{Fragesammlung}
\newcommand*{\Themenliste}{%
  01-Algebra,
  02-Potenzrechnen,
  03-Lineare-Gleichungen,
  04-Lineare-Gleichungssysteme,
  05-Quadratische-Gleichungen,
  06-Nichtlineare-Gleichungen,
  07-Lineare-Funktionen,
  08-Quadratische-Funktionen,
  09-Potenzfunktionen,
  10-Polynomfunktionen,
  11-Exponentialfunktionen,
  12-Datenanalyse,
  13-Wahrscheinlichkeitsrechnen,
  14-Planimetrie-I,
  15-Planimetrie-II,
  16-Trigonometrie-I,
  17-Trigonometrie-II,
  18-Stereometrie,
  19-Vektorgeometrie,
}%

% ------------------------------------------------------------------

\newif\ifPrintSolutions

\pgfkeys
{%
  aussagetest/.is family, /aussagetest,
  default/.style={solutions=true},
  solutions/.is if=PrintSolutions,
}%


% args: #1: options, #2: number of true statements, #3: number of false statements
% possible options: solutions=false (default: true)
%                    ...
% TODO: write more compact, how to pass boolean to lua? (luakeys package?)
\newcommand*{\CreateStatementTest}[3][]
{%
  \pgfkeys{/aussagetest, default, #1}%
  \ifPrintSolutions
    \directlua{%
      require('statementCollator.lua')
      local sep = getPathSeparator()
      local dirlist = csvsplit('\Themenliste')
      addprepoststring(dirlist, lfs.currentdir() .. sep .. '\Sammlungsordner' .. sep, sep)
      local mixedstatements = collateStatements(dirlist, #2, #3)
      printStatements(mixedstatements)
      printSolutions(mixedstatements, true)
    }%
  \else
    \directlua{%
      require('statementCollator.lua')
      local sep = getPathSeparator()
      local dirlist = csvsplit('\Themenliste')
      addprepoststring(dirlist, lfs.currentdir() .. sep .. '\Sammlungsordner' .. sep, sep)
      local mixedstatements = collateStatements(dirlist, #2, #3)
      printStatements(mixedstatements)
    }%
  \fi
}%

\newcommand*{\PrintEntireLibrary}
{%
  \directlua{%
    require('statementCollator.lua')
    local sep = getPathSeparator()
    printAll(lfs.currentdir() .. sep .. '\Sammlungsordner', true)
  }%
}%
