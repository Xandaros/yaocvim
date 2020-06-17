syn keyword luaFunction function
syn keyword luaCond if then end elseif else
syn keyword luaStatement do end
syn keyword luaRepeat repeat until while do for

syn keyword luaIn contained in

syn keyword luaStatement return local break
syn keyword luaStatement goto
syn keyword luaOperator and or not
syn keyword luaConstant nil
syn keyword luaConstant true false

syn keyword luaFunc assert collectgarbage dofile error next
syn keyword luaFunc print rawget rawset tonumber tostring type _VERSION

syn keyword luaFunc getmetatable setmetatable
syn keyword luaFunc ipairs pairs
syn keyword luaFunc pcall xpcall
syn keyword luaFunc _G loadfile rawequal require
syn keyword luaFunc load select
syn keyword luaFunc package.cpath
syn keyword luaFunc package.loaded
syn keyword luaFunc package.loadlib
syn keyword luaFunc package.path
syn keyword luaFunc _ENV rawlen
syn keyword luaFunc package.config
syn keyword luaFunc package.preload
syn keyword luaFunc package.searchers
syn keyword luaFunc package.searchpath
syn keyword luaFunc bit32.arshift
syn keyword luaFunc bit32.band
syn keyword luaFunc bit32.bnot
syn keyword luaFunc bit32.bor
syn keyword luaFunc bit32.btest
syn keyword luaFunc bit32.bxor
syn keyword luaFunc bit32.extract
syn keyword luaFunc bit32.lrotate
syn keyword luaFunc bit32.lshift
syn keyword luaFunc bit32.replace
syn keyword luaFunc bit32.rrotate
syn keyword luaFunc bit32.rshift
syn keyword luaFunc coroutine.running
syn keyword luaFunc coroutine.create
syn keyword luaFunc coroutine.resume
syn keyword luaFunc coroutine.status
syn keyword luaFunc coroutine.wrap
syn keyword luaFunc coroutine.yield
syn keyword luaFunc string.byte
syn keyword luaFunc string.char
syn keyword luaFunc string.dump
syn keyword luaFunc string.find
syn keyword luaFunc string.format
syn keyword luaFunc string.gsub
syn keyword luaFunc string.len
syn keyword luaFunc string.lower
syn keyword luaFunc string.rep
syn keyword luaFunc string.sub
syn keyword luaFunc string.upper
syn keyword luaFunc string.gmatch
syn keyword luaFunc string.match
syn keyword luaFunc string.reverse
syn keyword luaFunc table.pack
syn keyword luaFunc table.unpack
syn keyword luaFunc table.concat
syn keyword luaFunc table.sort
syn keyword luaFunc table.insert
syn keyword luaFunc table.remove
syn keyword luaFunc math.abs
syn keyword luaFunc math.acos
syn keyword luaFunc math.asin
syn keyword luaFunc math.atan
syn keyword luaFunc math.atan2
syn keyword luaFunc math.ceil
syn keyword luaFunc math.sin
syn keyword luaFunc math.cos
syn keyword luaFunc math.tan
syn keyword luaFunc math.deg
syn keyword luaFunc math.exp
syn keyword luaFunc math.floor
syn keyword luaFunc math.log
syn keyword luaFunc math.max
syn keyword luaFunc math.min
syn keyword luaFunc math.huge
syn keyword luaFunc math.fmod
syn keyword luaFunc math.modf
syn keyword luaFunc math.cosh
syn keyword luaFunc math.sinh
syn keyword luaFunc math.tanh
syn keyword luaFunc math.pow
syn keyword luaFunc math.rad
syn keyword luaFunc math.sqrt
syn keyword luaFunc math.frexp
syn keyword luaFunc math.ldexp
syn keyword luaFunc math.random
syn keyword luaFunc math.randomseed
syn keyword luaFunc math.pi
syn keyword luaFunc io.close
syn keyword luaFunc io.flush
syn keyword luaFunc io.input
syn keyword luaFunc io.lines
syn keyword luaFunc io.open
syn keyword luaFunc io.output
syn keyword luaFunc io.popen
syn keyword luaFunc io.read
syn keyword luaFunc io.stderr
syn keyword luaFunc io.stdin
syn keyword luaFunc io.stdout
syn keyword luaFunc io.tmpfile
syn keyword luaFunc io.type
syn keyword luaFunc io.write
syn keyword luaFunc os.clock
syn keyword luaFunc os.date
syn keyword luaFunc os.difftime
syn keyword luaFunc os.execute
syn keyword luaFunc os.exit
syn keyword luaFunc os.getenv
syn keyword luaFunc os.remove
syn keyword luaFunc os.rename
syn keyword luaFunc os.setlocale
syn keyword luaFunc os.time
syn keyword luaFunc os.tmpname
syn keyword luaFunc debug.debug
syn keyword luaFunc debug.gethook
syn keyword luaFunc debug.getinfo
syn keyword luaFunc debug.getlocal
syn keyword luaFunc debug.getupvalue
syn keyword luaFunc debug.setlocal
syn keyword luaFunc debug.setupvalue
syn keyword luaFunc debug.sethook
syn keyword luaFunc debug.traceback
syn keyword luaFunc debug.getmetatable
syn keyword luaFunc debug.setmetatable
syn keyword luaFunc debug.getregistry
syn keyword luaFunc debug.getuservalue
syn keyword luaFunc debug.setuservalue
syn keyword luaFunc debug.upvalueid
syn keyword luaFunc debug.upvaluejoin

hi link luaStatement  Statement
hi link luaRepeat  Repeat
hi link luaFor   Repeat
hi link luaString  String
hi link luaString2  String
hi link luaNumber  Number
hi link luaOperator  Operator
hi link luaIn   Operator
hi link luaConstant  Constant
hi link luaCond  Conditional
hi link luaElse  Conditional
hi link luaFunction  Function
hi link luaComment  Comment
hi link luaTodo  Todo
hi link luaTable  Structure
hi link luaError  Error
hi link luaParenError  Error
hi link luaBraceError  Error
hi link luaSpecial  SpecialChar
hi link luaFunc  Identifier
hi link luaLabel  Label
