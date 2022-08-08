% ==================================================================
% FILE     randgentftestbmzcls.cls
% INFO     
%
% DATE     08.08.2022
% OWNER    Bischofberger
% ==================================================================
% This work may be distributed and/or modified under the
% conditions of the LaTeX Project Public License, either version 1.3
% of this license or (at your option) any later version.
% The latest version of this license is in
%   http://www.latex-project.org/lppl.txt
% and version 1.3 or later is part of all distributions of LaTeX
% version 2005/12/01 or later.

\ProvidesClass{randgentftestbmzcls}

\LoadClass[10pt]{article}
\RequirePackage[a4paper,textwidth=160mm,top=30mm,bottom=40mm]{geometry}
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
\chead[]{Wahr-Falsch-Test}

\RequirePackage{siunitx}
\sisetup{per-mode=symbol,exponent-product=\cdot}

%\RequirePackage{tikz}
%\usetikzlibrary{calc,angles,intersections,arrows.meta}
%\tikzset{>={Latex}}

%\RequirePackage{pgfplots}
%\pgfplotsset{compat=newest}
%\pgfplotsset{axis lines=center,axis line style={-Latex}}

% shortcut for TALS GLF content
\newcommand{\TALSGLF}
{%
  \SetTopicFoldersTo{%
    01-Algebra,
    03-Lineare-Gleichungen,
    04-Lineare-Gleichungssysteme,
    05-Quadratische-Gleichungen,
    07-Lineare-Funktionen,
    08-Quadratische-Funktionen,
    12-Datenanalyse,
    14-Planimetrie-I,
    15-Planimetrie-II,
    16-Trigonometrie-I,
    17-Trigonometrie-II,
  }%
}

% shortcut for TALS SPF content
\newcommand{\TALSSPF}
{%
  \SetTopicFoldersTo{%
    02-Potenzrechnen,
    06-Nichtlineare-Gleichungen,
    09-Potenzfunktionen,
    10-Polynomfunktionen,
    11-Exponentialfunktionen,
    18-Stereometrie,
    19-Vektorgeometrie,
  }%
}


