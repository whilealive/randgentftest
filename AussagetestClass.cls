% ==================================================================
% FILE     AussagetestClass.cls
% INFO     
%
% DATE     01.11.2021
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
\setlist[checklist,1,2]{label=\checkbox,leftmargin=*,nosep,align=left,itemsep=1ex}

\RequirePackage{pgfplots}
\pgfplotsset{compat=newest}
\pgfplotsset{axis lines=center,axis line style={-Latex}}

%\RequirePackage{luacode}

