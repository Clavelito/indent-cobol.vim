vim9script noclear

# Vim indent file
# Language:         Cobol
# Author:           Clavelito <maromomo@hotmail.com>
# Last Change:      Sat, 24 Dec 2022 18:33:17 +0900
# Version:          0.1
# License:          http://www.apache.org/licenses/LICENSE-2.0
#
# Description:      The current line is often indented at line breaks.
#                   Commands that are not registered will not be indented
#                   correctly. To add commands, follow the example below.
#                   g:cobol_indent_commands = 'ALTER\|ENTER\|NOTE'


if exists('b:did_indent')
  finish
endif
b:did_indent = 1

setlocal indentexpr=g:GetCobolInd()
setlocal indentkeys+=0*,0/,0$,0-,0=~D\ ,0=~THEN,0=~ELSE,0=~WHEN,=~DIVISION
setlocal indentkeys+=0=~AND\ ,0=~OR\ ,=,<<>,<>>
setlocal indentkeys+=00,01,02,03,04,05,06,07,08,09,.,*<CR>,*<NL>
setlocal expandtab
b:undo_indent = 'setlocal indentexpr< indentkeys< expandtab<'

if exists('*g:GetCobolInd')
  finish
endif
var cpo_save = &cpo
set cpo&vim

var c_ind: number
var p_ind: number
var b_ind: number
var f_num: number

def g:GetCobolInd(): number
  var cline = getline(v:lnum)
  SetBaseLevel()
  if &indentkeys =~# '<Space>'
    setlocal indentkeys-=<Space>
  elseif mode() == 'i' && cline =~ '^\s*\d$'
    setlocal indentkeys+=<Space>
    return indent(v:lnum)
  endif
  var lnum = prevnonblank(v:lnum - 1)
  var line = getline(lnum)
  while lnum > 0 && (Comment(line) || Direct(line) || Debug(line))
    lnum = prevnonblank(lnum - 1)
    line = getline(lnum)
  endwhile
  var pnum = prevnonblank(lnum - 1)
  var pline = getline(pnum)
  while pnum > 0 && (Comment(pline) || Direct(pline) || Debug(pline))
    pnum = prevnonblank(pnum - 1)
    pline = getline(pnum)
  endwhile
  line = CleanLine(line)
  pline = CleanLine(pline)
  var ind = GetBaseInd(lnum)
  if (Comment(cline) || Dash(cline)) && !Muth2(line) && !Compute(line) || Debug(cline)
    return c_ind
  elseif cline =~? '^\s*>>\s*SOURCE'
    return cline =~? '\sFREE\%(\s\|$\)' || !lnum ? 7 : ind
  elseif line =~? '^\s*PROCEDURE\s\+DIVISION\%(\s\|[.]\|$\)'
      || line =~? '^\s*\S\+\s\+SECTION\s*[.]\s*$'
      || Para(line) && !Prop(line)
    ind = b_ind
  elseif (Expr(line) || When(line)) && !Dot(line)
    ind = ExprInd(line, cline, ind)
  elseif Expr(line .. cline) && !Dot(line)
    ind += TwoOrOneHalf()
  elseif (Prop2(line) || Prop3(line)) && !Dot(line)
      || Prop(line) && !Dot(line) && (Opt(line) || Prop2(cline) && !Not(cline))
      || (Num(line) || One(line)) && Dot(pline) && !Dot(line)
    ind += shiftwidth()
  elseif Dot(line) && !Prop(line) && !End(line) && pnum > 0 && !Dot(pline) && ind > b_ind
      || !Muth(line) && Muth(pline) || Dash(line) && ind == c_ind
    ind = TurnInd(line, pnum, ind)
  elseif Into(line) && !With(cline) && !Prop(cline)
      || Open(line) && Mode(cline)
      || (Prop(line) || Mode(line))
      && (!Dot(line) && !empty(cline) || Muth(line))
      && !Prop(cline) && !Expr(cline) && !Mode(cline) && !End(cline) && !Prop2(cline)
    ind = GapInd(line, cline, ind)
  elseif !Dot(line) && !Prop(line) && !End(line)
      && (Prop(cline) || Expr(cline) || Mode(cline) || End(cline) || With(cline))
      || Prop2(cline) && !Dot(line)
    ind = TurnInd(cline, lnum, ind)
  endif
  if line =~? '\S\s\+END-\a\+\%(\s\|[.]\|$\)'
    ind = EndInd(line, ind, lnum)
  elseif Dot(line) && !Dot(pline) && ind > b_ind
    ind = b_ind
  elseif Open(line) && empty(cline)
      || !Expr(line) && !Prop(line) && !Prop2(line) && !Prop3(line) && empty(cline) && ind > b_ind
    setlocal indentkeys+=<Space>
  endif
  if Para(cline) && !Prop(cline) && (Dot(line) || !lnum)
      || One(cline) && Dot(line)
      || cline =~? '^\s*\S\+\s\+\%(SECTION\|DIVISION\)\%(\s\|[.]\|$\)'
      || cline =~? '^\s*END\s\+PROGRAM\s'
      || cline !~ '^\d\{6}' && !lnum
    ind = p_ind
  elseif End(cline)
    ind = EndInd(cline, ind)
  elseif Num(cline) && Dot(line)
    ind = LevelInd(line, lnum, cline, ind)
  elseif When(cline) && !Expr(line) && !Prop3(line)
    ind = TurnInd(cline, lnum, ind)
  elseif cline =~? '^\s*\%(ELSE\|THEN\)\%(\s\|$\)'
    ind -= shiftwidth()
  elseif AndOr(cline) && Operator(line)
    ind -= 1
  elseif Operator(cline) && AndOr(line)
    ind += 1
  endif
  return ind
enddef

def SetBaseLevel(): void
  c_ind = 6
  p_ind = 7
  b_ind = 11
  f_num = search('\c>>\s*SOURCE', 'nbW')
  if f_num > 0
    var line = CleanLine(getline(f_num))
    if line !~? '>>\s*SOURCE'
      f_num = 0
    elseif line =~? '\sFREE\%(\s\|$\)'
      c_ind = 0
      p_ind = 0
      b_ind = shiftwidth()
    endif
  endif
enddef
    
def GetBaseInd(lnum: number): number
  var ind = indent(lnum)
  if f_num > 0 && lnum < f_num && f_num < v:lnum
    if !p_ind
      ind -= ind >= 11 ? (11 - shiftwidth()) : 7
    else
      ind += ind > shiftwidth() ? b_ind : p_ind
      ind = ind > p_ind && ind < b_ind ? b_ind : ind
    endif
  endif
  return ind
enddef

def ExprInd(line: string, cline: string, aind: number): number
  var width = GapInd(line, cline, aind)
  if AndOr(cline) && If(line)
    return width - 4 > aind ? width - 4 : aind + TwoOrOneHalf()
  elseif Operator(cline) && If(line)
    var len = strdisplaywidth(substitute(cline, '^\s*\(.\{-}[<>=]\).*$', '\1', ''))
    if width - 4 > aind && width - aind - 3 > len
      return width - len - 2
    elseif width - 4 > aind
      return aind + 2
    endif
    return aind + TwoOrOneHalf()
  elseif cline =~? '^\s*ALSO\s' && line =~? '^\s*EVALUATE\s'
    return width - 5
  endif
  var ind = aind + shiftwidth()
  if !empty(cline) && !Prop(cline) && !Expr(cline)
    if width > ind || If(line) && line =~? '\s\%(AND\|OR\|[=<>]\{1,2}\)\s*$'
      return width
    endif
    return ind + float2nr(round(shiftwidth() * 0.5))
  endif
  return ind
enddef

def GapInd(line: string, cline: string, aind: number): number
  if line =~ '^\s*\S\+$'
    return aind + shiftwidth()
  elseif Open(line) && !Mode(cline) || line =~? '^\s*ELSE\s\+IF\%(\s\|$\)'
    if line =~ '^\s*\S\+\s\+\S\+$'
      return strdisplaywidth(line) + 1
    endif
    return strdisplaywidth(matchstr(line, '^\s*\S\+\s\+\S\+\s\+'))
  endif
  return strdisplaywidth(matchstr(line, '^\s*\S\+\s\+'))
enddef

def TurnInd(aline: string, alnum: number, aind: number): number
  var cline = aline
  var lnum = alnum
  var ind = indent(lnum)
  while lnum > 0 && (aind > p_ind && ind >= aind || ind < p_ind)
    cline =  getline(lnum)
    lnum = prevnonblank(lnum - 1)
    if !AndOr(getline(lnum))
      ind = indent(lnum)
    endif
  endwhile
  var line = getline(lnum)
  if empty(aline) && (Open(line) || Into(line))
    setlocal indentkeys+=<Space>
  endif
  if !lnum
      || With(aline) && !Into(line)
      || !Dot(aline) && (One(line) || Num(line))
      || empty(aline) && (Into(line) || Muth(line))
    return aind
  elseif (With(aline) || Prop2(aline)) && Into(line)
      || (When(aline) || Prop2(aline)) && (When(line) || Prop2(line))
      || One(line)
      || Num(line)
  elseif Mode(aline) && Open(line)
    return GapInd(line, aline, ind)
  elseif Expr(line)
      || Prop(aline) && When(line)
      || Expr(line .. cline)
      || Prop2(aline) && Prop(line)
    return ind + shiftwidth()
  elseif !Prop(line)
    return TurnInd(aline, lnum, ind)
  endif
  return ind
enddef

def LevelInd(aline: string, alnum: number, cline: string, aind: number): number
  var line = aline
  var lnum = alnum
  while lnum > 0 && !Num(line)
    lnum = prevnonblank(lnum - 1)
    line = getline(lnum)
  endwhile
  if !lnum
    return aind
  endif
  var clev = str2nr(matchstr(cline, '\d\=\d\ze\%(\s\|$\)'))
  if clev == str2nr(matchstr(line, '\d\=\d\ze\%(\s\|$\)'))
    return indent(lnum)
  elseif clev > str2nr(matchstr(line, '\d\=\d\ze\%(\s\|$\)'))
    return indent(lnum) + shiftwidth()
  endif
  while lnum > 0 && clev != str2nr(matchstr(line, '\d\=\d\ze\%(\s\|$\)'))
    while lnum > 0
      lnum = prevnonblank(lnum - 1)
      line = getline(lnum)
      if Num(line)
        break
      endif
    endwhile
    if One(line)
      return aind
    endif
  endwhile
  return lnum > 0 ? indent(lnum) : aind
enddef

def EndInd(line: string, aind: number, ...alnum: list<number>): number
  var pos = getpos('.')
  if empty(alnum)
    if line =~ '\s'
      cursor(0, 1)
    else
      search('\s', 'bW')
    endif
    var tail = matchstr(line, '\cEND-\a\+')
    var skip = tail =~? '^END-IF$' ? 'SkipLine(0)' : 'SkipLine(' .. aind .. ')'
    var head = '\c\s' .. strpart(tail, 4) .. '\%(\s\|$\)'
    tail = '\c\s' .. tail .. '\%(\s\|[.]\|$\)'
    var lnum = searchpair(head, '', tail, 'bW', skip)
    setpos('.', pos)
    return lnum > 0 ? indent(lnum) : aind
  endif
  var ind = aind
  var wpos = matchend(line, '\c\S\s\+END-\a\+')
  while wpos > -1
    cursor(alnum[0], wpos)
    ind = EndInd(expand('<cword>'), ind)
    wpos = matchend(line, '\cEND-\a\+', wpos)
  endwhile
  setpos('.', pos)
  return ind
enddef

def TwoOrOneHalf(): number
  return shiftwidth() < 3 ? shiftwidth() * 2 : float2nr(round(shiftwidth() * 1.5))
enddef

def SkipLine(aind: number): bool
  var line = substitute(strpart(getline('.'), 0, col('.')), quote, '', 'g')
  return line =~ '^\s*[*/$-]\|"\|\%o47\|[*]>' || aind > 0 && aind <= indent('.')
enddef

def CleanLine(aline: string): string
  var line = substitute(aline, quote, '\=repeat("x", strlen(submatch(0)))', 'g')
  var tail = match(line, '.[*]>')
  if tail == -1
    return line
  endif
  return strpart(line, 0, tail)
enddef

def Prop(line: string): bool
  if exists('g:cobol_indent_commands') && !empty('g:cobol_indent_commands')
    return line =~? cmds .. '\|^\s*\%(' .. g:cobol_indent_commands .. '\)\%(\s\|$\)'
  endif
  return line =~? cmds
enddef

def Prop2(line: string): bool
  return line =~? prop2
enddef

def Prop3(line: string): bool
  return line =~? prop3
enddef

def Expr(line: string): bool
  return line =~? expr
enddef

def Opt(line: string): bool
  return line =~? opts
enddef

def AndOr(line: string): bool
  return line =~? '^\s*\%(AND\|OR\)\s'
enddef

def Comment(line: string): bool
  return line =~ '^\s*[*/$]'
enddef

def Compute(line: string): bool
  return line =~? '^\s*COMPUTE\s' && !Muth(line) && !Dot(line) && line !~? '\sEND-COMPUTE\>'
enddef

def Dash(line: string): bool
  return line =~ '^\s*-' && c_ind > 0
enddef

def Debug(line: string): bool
  return line =~? '^\s*D\s' && c_ind > 0
enddef

def Direct(line: string): bool
  return line =~ '^\s*>>'
enddef

def Dot(line: string): bool
  return line =~ '[.]\s*$'
enddef

def End(line: string): bool
  return line =~? '^\s*END-\a\+\%(\s\|[.]\|$\)'
enddef

def If(line: string): bool
  return line =~? '^\s*\%(IF\|ELSE\s\+IF\)\s'
enddef

def Into(line: string): bool
  return line =~? '^\s*\%(INTO\|USING\)\%(\s\|$\)'
enddef

def Mode(line: string): bool
  return line =~? '^\s*\%(INPUT\|OUTPUT\|I-O\|EXTEND\)\%(\s\|$\)'
enddef

def Muth(line: string): bool
  return line =~ '\%(^\s*\)\@<!\%([-+*/=]\|[*][*]\)\s*$'
enddef

def Muth2(line: string): bool
  return line =~ '^[ ]\{' .. b_ind .. ',}\%([-+*/=]\|[*][*]\)'
enddef

def Not(line: string): bool
  return line =~? '^\s*NOT\s'
enddef

def Num(line: string): bool
  return line =~ '^\s*\%([1-9]\|\d\d\)\%(\s\|$\)'
enddef

def One(line: string): bool
  return line =~? '^\s*\%(0\=1\|66\|77\|78\|SD\|FD\|RD\|COPY\)\%(\s\|$\)'
enddef

def Open(line: string): bool
  return line =~? '^\s*OPEN\s'
enddef

def Operator(line: string): bool
  return line =~? '^\s*\%(IS\s\+\)\=\%(NOT\s*\)\=[=<>]'
enddef

def Para(line: string): bool
  return line =~ '^\s*[^.[:blank:]]\+\s*[.]\s*$'
enddef

def When(line: string): bool
  return line =~? '^\s*WHEN\%(\s\|$\)'
enddef

def With(line: string): bool
  return line =~? '^\s*\%(WITH\|TALLYING\)\s'
enddef

const quote = "'[^']*'" .. '\|"\%(\\.\|[^"]\)*"'

const opts = '\%(\%(\sNOT\)\@4<!\&\%(^\s*\)\@<!\)\s\+\%(ON\s\+SIZE\s\+ERROR'
      .. '\|ON\s\+OVERFLOW\|ON\s\+EXCEPTION\|INVALID\s\+KEY'
      .. '\|\%(AT\s\+\)\=\%(END\|EOP\|END-OF-PAGE\)\)\%(\s\|$\)'

const prop2 = '^\s*\%(NOT\s\+\)\=\%(AT\s\+\)\=\%(END\|EOP\|END-OF-PAGE\)\%(\s\|$\)'
      .. '\|^\s*\%(NOT\s\+\)\=\%(INVALID\s\+KEY\|ON\s\+SIZE\s\+ERROR\)\%(\s\|$\)'
      .. '\|^\s*\%(NOT\s\+\)\=\%(ON\s\+OVERFLOW\|ON\s\+EXCEPTION\)\%(\s\|$\)'

const prop3 = '^\s*\%(READ\|RETURN'
      .. '\|SEARCH\|SELECT\|STRING\|UNSTRING\)\%(\s\|$\)'

const expr = '^\s*\%(IF\|ELSE\|EVALUATE'
      .. '\|PERFORM\s\+\%(UNTIL\|VARYING\|WITH\s\+TEST\|\S\+\s\+TIMES\)'
      .. '\|THEN\)\%(\s\|$\)'

const cmds = '^\s*\%(ACCEPT\|ADD\|CALL\|CANCEL\|CLOSE\|COMPUTE\|CONTINUE'
      .. '\|COPY\|DELETE\|DISPLAY\|DIVIDE\|EVALUATE\|GO\s\+TO\|IF\|INITIALIZE'
      .. '\|INSPECT\|MERGE\|MOVE\|MULTIPLY\|OPEN\|READ\|REDEFINES'
      .. '\|RELEASE\|RETURN\|REWRITE\|SEARCH\|SELECT\|SET\|SORT\|START\|STOP'
      .. '\|STRING\|SUBTRACT\|UNSTRING\|USE\|WHEN\|WRITE\)\%(\s\|$\)'
      .. '\|^\s*PERFORM\%(\s\+\|$\)\%(UNTIL\|VARYING\|WITH\|\S\+\s\+TIMES\)\@!'
      .. '\|^\s*\%(GOBACK\|EXIT\)\%(\s\|[.]\)'

&cpo = cpo_save
# vim: sw=2 et
