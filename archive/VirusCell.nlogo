;; VirusCell
;; Author: Travis A. Ebesu
;; Date: June 18th 2013
;; Description:
;; Notes: 
;;        Needs refactoring 
;;        Very Complicated, needs simplifying 


; To do
; Migrating to other cells then infecting
; mutation
; Restrict initial cells death?

extensions [array table] ;; extensions for arrays and tables 
;; Global Variables all start with uppercase
globals [ 

   
  CellSize ; size to make cells (actual size = size * 2 + 1)  
  CellXY ;; coordinates of all cells in a nested list [ [ cell [ xy coordinates ] ] ]
  #Cells   ;#Cells ; number of cells to make
  OriginalXY ; Keeps Original xy of cells [ [x y] [x y] ] 
  InfectedCells ; Keep track of infected cells
  MutationSequence
  
  VirusColor
  CellColor
  
  ReplicationProbability ; Restrictive 
  
  ;; Mutation Debugging
  MatchCount
  TestCount
  TestSequence
  
  ;; Debugging Output
  DebugMutation
  Debug
]


; Viruses
breed [viruses virus]
viruses-own [
  cell# ; Cell # it started in 
  sequence ; binary mutation
  targetCell ; Cell to target next
  mutated? ; Virus Mutated?
  targetXY ; Stores coordinates of the 
  
  moving? ; Is virus on the move to another cell?
  replicate? ; Should Virus Replicate?
]


patches-own [ 
  inside? ; is Patch inside a cell
  wall? ; is Patch the wall, remove me?
  num ; Cell number assigned for identification
]


to setup
  ca
  setup-vars
  setup-patches
  setup-viruses
  reset-ticks
end



;; Initialize global variables
to setup-vars
  set CellXY [ ]     ; Coords of each patch in a cell  
  set OriginalXY [ ] ; Center of each cell
  set CellSize 2
  set #Cells 4
  set InfectedCells [ ]
  let i 0
  while [ i < #Cells ] [
    set InfectedCells lput false InfectedCells
    set i i + 1
  ]
  set ReplicationProbability 50 
  set MutationSequence n-values MutationLength [one-of [0 1]]
  set TestSequence n-values GenomeLength [one-of [0 1]]
  ;; Colors
  set VirusColor [195 6 6]
  set CellColor [190 190 190]
  
  set DebugMutation false
  set Debug false
end

;; Where num = container number 
;; ask patches with [num = 2 ] [ ask neighbors4 with [inside? and not wall?] [ set pcolor yellow] ]
to setup-patches
  ask patches [ set inside? false set wall? false set num -1] ;; init vars to false
  
  show "======="
  print "\n\n\n\n\n\n"

  create-cells #Cells
  ask inside [ ask neighbors4 with [not inside?] [set pcolor CellColor set wall? true] ]

end

to setup-viruses
  ;; creates a list of coordinates of all inner cells 
  let i 0
  let l [ ]
  while [ i < #Cells ] [
       ask patches with [num = i ] [ 
         ask neighbors4 with [inside? and not wall?] [
            ; This automatically loops through all patches specified 
            set l lput (list pxcor pycor) l
         ]
       ]
     set CellXY lput l CellXY
     set l [ ]
     set i i + 1 
  ]
  set i 1
  if debug [ foreach CellXY [ print (word "Cell " i ": " ? ) set i i + 1] ];; Show me all my coordinates 

  ;;Create a virus in a cell
  let r random #Cells
  let coord getRandomItem getItem r CellXY ;; gets a random coordinate within a cell
  create-viruses 1 [ 
    set color VirusColor 
    set cell# r ;; set which cell this virus is in 
    setxy getItem 0 coord getItem 1 coord ;; set the coordinates we randomly obtained
    set sequence n-values GenomeLength [one-of [0 1]]
    set mutated? false
    set targetCell -1
    set InfectedCells replace-item cell# InfectedCells true ; Where ever virus starts, cell is considred infected 
  ]
  
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ; replicate cells
  ;    Mutate children
  
  ; Mutated Cells correctly
  ;    Find an uninfected cell
  ;    replicate cells again!
  ask viruses [ 
    ifelse mutated? [
        infect-cell
    ]
    [
       if random 100 < DeathProbability [ die ]
       
     ifelse random 100 < ReplicationProbability [ replicate ][
       let coord getxyInCell cell# CellXY    ; Gets a coordinate within the cell
       facexy getItem 0 coord getItem 1 coord  
       fd 1
      ]
    ]
  ]


  tick

end


to infect-cell
  
  ; If no target, set one
  ifelse targetXY = 0 [
       ifelse allCellsInfected? [ 
            set targetXY findClosestCell (list pxcor pycor) cell#
      ] [
           set targetXY findClosestUninfectedCell (list pxcor pycor) cell# ; target coordinates
      ]
      set targetCell item 2 targetXY ; target cell number
      facexy (item 0 targetXY) (item 1 targetXY)
;      print (word "XY: " (item 0 targetXY) " " (item 1 targetXY))
  ][
  let currentPatch [ ]
      ask patch-here [
         set currentPatch num ; each patch was previously assigned either a cell number or -1
      ]
      ifelse currentPatch = targetCell [ ; Arrived at cell destination
 
          set InfectedCells replace-item targetCell InfectedCells true
          print (word "Arrived at cell # " targetCell)
          set mutated? false
          set targetXY 0
          set cell# targetCell
          
      ][
         fd 1
      ]
  ]  
end

to replicate

    
    let parentGenome sequence 
    hatch-viruses 1  [ 
      let coord getxyInCell cell# CellXY    ; Gets a coordinate within the cell
      facexy getItem 0 coord getItem 1 coord  
      if Debug [ show (word "         " getItem 0 coord  ", " getItem 1 coord) ]
      fd 1
      set sequence (mutateGenome parentGenome)
      set mutated? (isMutated sequence)
    ]
    
    let coord getxyInCell cell# CellXY    ; Gets a coordinate within the cell
    facexy getItem 0 coord getItem 1 coord  
    fd 1
    
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to test-mutation
  setup-vars
  mutation TestSequence
  set TestSequence mutateGenome TestSequence
  tick
end


to mutation [ genome ] 
; simple linear search
  let mutationSum sum sublist MutationSequence 0 MutationLength
  let i 0
  let gLength length genome
  let found? false
  if gLength > MutationLength [
    set gLength gLength - MutationLength + 1
  ]
  while [ i < gLength  ] [
      let sequenceSum sum sublist genome i (i + MutationLength)
      if sequenceSum = mutationSum [ ; We might have a match, same sums
          if DebugMutation [ print (word "Mutation: " MutationSequence "\nGenome:   " sublist genome i (i + MutationLength) "\n") ]
          let j 0
          let temp sublist genome i (i + MutationLength) ; Create a list of the sequence that matched
          while [ j < MutationLength ] [  ; Check each position
              ifelse position (j) temp = position j MutationSequence [
                  set j j + 1 ; Matched, keep checking
              ] [
                  set j MutationLength + 1 ; Not matching, exit
              ]
          ]
          if j = MutationLength [ if DebugMutation [ print "-------MATCH---------\n\n"] set i gLength set MatchCount MatchCount + 1 ]
      ]
      set i i + 1
  ]
  set TestCount TestCount + 1
  if DebugMutation [ print "No Match\n\n"  ]
end

to-report isMutated [ genome ]
; simple linear search
  let mutationSum sum sublist MutationSequence 0 MutationLength
  let i 0
  let gLength length genome
  if gLength > MutationLength [
    set gLength gLength - MutationLength + 1
  ]
  
  while [ i < gLength  ] [
      let sequenceSum sum sublist genome i (i + MutationLength)
;      print (word "SequenceSum: " sequenceSum)
      if sequenceSum = mutationSum [ ; We might have a match, same sums
         if DebugMutation [  print (word "Mutation: " MutationSequence "\nGenome:   " sublist genome i (i + MutationLength) "\n\n") ]
          let j 0
          let temp sublist genome i (i + MutationLength)
          while [ j < MutationLength ] [

              ifelse position (j) temp = position j MutationSequence [
                  set j j + 1 ; Matching keep checking
              ] [
                  set j MutationLength + 1 ; Not matching
              ]
          ]
          if j = MutationLength [ if DebugMutation [ print "-------MATCH---------"] set MatchCount MatchCount + 1 report true ]
      ]
      
      set i i + 1
  ]
    set TestCount TestCount + 1
  report false
  
end

to-report mutateGenome [ genome ]
    let i 0
    while [ i < length genome ] [
        if random 100 > MutationProbability [
            ifelse item i genome = 1 [ set genome replace-item i genome 0 ]
            [ set genome replace-item i genome 1 ]
        ]
        set i i + 1
    ]
    report genome
end



; isInfected? - returns if cell # is infected
to-report isInfected? [ c# ]
    report item c# InfectedCells ; Doesn't allow returns nested in "ask"
end

;to setInfected [ c# ]
;    let infect item c# OriginalXY
;    ask patch (item 0 infect) (item 1 infect) [ set infected? true ]
;end


; allCellsInfected? - returns if all cells are infected 
to-report allCellsInfected?
  ; Iterate over each infected cell
  foreach InfectedCells [
    if not ? [ report false ]  ; if not infected, return false
  ]
  report true
end


; find nearest cell from xy and the current cell it is in
to-report findClosestCell [ xy currentCell ]
    ; iterate through locations of original cell, find closests
    let best max-pxcor * 2
    let bestxy [ ]
    let i 0
    while [ i < length OriginalXY ] [
        if i != currentCell [
            let x (getItem 0 (getItem i OriginalXY))
            let y (getItem 1 (getItem i OriginalXY))
            if getDistance (item 0 xy) (item 1 xy) x y  < best [
                set best getDistance (item 0 xy) (item 1 xy) x y
                set bestxy (list x y i)
            ]
        ]
        set i i + 1
    ]
    report bestxy
end


; Same as above but checks for infections
to-report findClosestUninfectedCell [ xy currentCell ]
    ifelse allCellsInfected? [ print ("ERROR: All Cells Infected, while attempting to find uninfected cells") ][ ; double check
    
    ; iterate through locations of original cell, find closests
    let best max-pxcor * 2
    let bestxy [ ]
    let i 0
    while [ i < length OriginalXY ] [ 
        if i != currentCell and not isInfected? i[
            let x (getItem 0 (getItem i OriginalXY))
            let y (getItem 1 (getItem i OriginalXY))
            if getDistance (item 0 xy) (item 1 xy) x y  < best [
                set best getDistance (item 0 xy) (item 1 xy) x y
                set bestxy (list (round x) (round y) i)
            ]
        ]
        set i i + 1
    ]
    report bestxy
    ]
end






;; Depreciated
;to findCell
;    let x 0
;  let y 0
;  let cx 0
;  let cy 0
;  ;; moves out of cell till near another one
;  ask viruses [
;    set x pxcor
;    set y pxcor
;    let best  max-pxcor * 10
;    ask patches with [wall?] [ 
;      ask neighbors4 with [not inside? and not wall?] [ 
;        if dist x y pxcor pycor < best [ set best dist x y pxcor pycor set cx pxcor set cy pycor ]  
;      ]
;    ]
;    facexy cx cy
;    fd 1
;  ]
;
;end


;; Turtle function 
to-report getxyInCell [ n xy ] 
  let coord randomCellN cell# CellXY
  while [ distancexy getItem 0 coord getItem 1 coord < 1 ] [
    set coord randomCellN cell# CellXY
  ] 
  report coord
end

;; Gets a random xy from the cell n
to-report randomCellN [ n xy ]
  report getRandomItem getItem n xy
end

;; Retrieve an item from a list
to-report getItem [ x l ] ;; Made to call recursively
  report item x l 
end

;; Retrieve random item from a list
to-report getRandomItem [ l ] ;; Made to call recursively
  report item (random length l) l
end





to-report addXY [ add existing ]
  if existing = [ ] [ report (list add) ]
  report lput add existing 
end

;; Helper/Utility Methods

;; returns agentset of all patches inside the container
to-report inside 
  report patches with [inside?] 
end



to create-cells [ n ]
  ; Adjust this for the amount area to use
  let area% 0.82 
  
  ; Vars

  let x (round random-xcor)
  let y (round random-ycor)
  let area (max-pxcor * 2 + 1) * (max-pycor * 2 + 1) ;; L * W, note adding 1 to count (0, 0) as a block
  let csize (cellSize * 2 + 3) ; Size of the cell container including a border (note cellSize is a global)
  let maxN round (area / (getSquare csize))  ; max amount of cells that can be created in given space and cellsize
  ; sterilize input
  if n > maxN  [ print (word "ERROR: create-container  " n " > " maxN " (maximum cells for area) ") stop ] 
  
  while [ length OriginalXY < n ] [
      ; Get xy that is within the border area and has proximity distance between another cell
      while [not isInBorder (list x y) area% or not isOutsideProximity (list x y) OriginalXY csize] [
          set x (round random-xcor)
          set y (round random-ycor)
      ]
      
      ; Draw the cell and set its variables 
      drawCell (list x y) length OriginalXY cellSize ; set the border and other parameters
      set OriginalXY lput (list x y) OriginalXY ; add to list of xy's to cross check for prroximity
      set x random-xcor
      set y random-ycor    ]
end


to drawCell [xy cellNumber containerSize]
  let x item 0 xy - containerSize
  let y item 1 xy + containerSize
  let maxX item 0 xy + containerSize
  let minY item 1 xy - containerSize
  ;; Loops from left to right, starting in the upper left most patch
  while [ y > minY ] [ 
    while [ x < maxX ] [
      setPatch x y cellNumber
      set x x + 1 ;; increment
    ]
    set x item 0 xy - containerSize ;; reset x to start at furthest left patch
    set y y - 1 ;; decrement
  ]
end


to-report getSquare [n]
  report n * n 
end

to-report isOutsideProximity [ coordinates xy2 proximity ]
  foreach xy2 [
      if getDistance (item 0 coordinates) (item 1 coordinates) (item 0 ?) (item 1 ?) < proximity [ report false ]
  ]
  report true
end

to-report isInBorder [ xy size% ]
  report (max-pxcor * size%) > abs item 0 xy and (max-pycor * size%) > abs item 1 xy
end

to-report getDistance [x1 y1 x2 y2]
  report round sqrt ( getSquare (x2 - x1) + getSquare (y2 - y1) )
end

;; Retrieve an item from a list
;to-report getItemList [ x l ] ;; Made to call recursively
;  report item x l 
;end




;; Random number within a range
;; Does not work with negative numbers due to random in API 
to-report ran [minNum maxNum]
  let n random maxNum
    while [n > maxNum or n < minNum ] [ set n random maxNum ]
  report n
end

;; Shorthand method
to setPatch [x y cNumber]
;  let patchColor red ;; color
  ask patch x y [ 
      set inside? true 
      set num cNumber
;    set pcolor patchColor
  ]
end

;;;;;;;;;;;;;;;;;
;; Depreciated ;;
;;;;;;;;;;;;;;;;;

;to-report insideBorder [ x y border ]
;  let bx max-pxcor * border
;  let by max-pycor * border
;  set x abs x
;  set y abs y
;  if bx > x and by > y [ report true ]
;  report false
;end
;; Shorthand method
;to setPatch [x y]
;;  let patchColor red ;; color
;  ask patch x y [ 
;    set inside? true 
;    set num pCount
;;    set pcolor patchColor
;  ]
;end
;
;; Creates cells from patches and assigns them variables inside? and wall? 
;; inside? = patches inside the cell
;; wall? = the border of the cell
;to create-cells [n containerSize]
;  let area (max-pxcor * 2 + 1) * (max-pycor * 2 + 1) ;; L * W, note adding 1 is due to count 0 as a block
;  let maxN round (area / square (containerSize * 2 + 3))
;  if n > maxN  [ print (word "ERROR: create-container  " n " > "maxN " (maximum cells for area) ") stop ]
;  let c 0
;  let x random-xcor
;  let y random-ycor
;  let border 0.82   ;; Adjust this percent for amount of entire board to use
;  
;  while [ c < n ] [    
;    while [not isInBorder (list x y) border or not isOutsideProximity (list x y) OriginalCells (containerSize * 2 + 3)][
;          set x random-xcor
;          set y random-ycor 
;    ]
;;    print (word "Container # " c " position => " x ", " y)
;    createContainer x y containerSize
;    set OriginalCells lput (list x y) OriginalCells
;    set cells lput x cells
;    set cells lput y cells
;    set x random-xcor
;    set y random-ycor 
;    set c c + 1
;    set pCount pCount + 1
;  ]
;end
;
;
;
;;; creates a container where x,y as origin, and double the container size
;;; patches inside the container hold the var inside? as true
;to createContainer [centerx centery containerSize]
;  let x centerx - containerSize
;  let y centery + containerSize
;  let maxX centerx + containerSize
;  let minY centery - containerSize
;  ;; Loops from left to right, starting in the upper left most patch
;  while [ y > minY ] [ 
;    while [ x < maxX ] [
;      setPatch x y 
;      set x x + 1 ;; increment
;    ]
;    set x centerx - containerSize ;; reset x to start at furthest left patch
;    set y y - 1 ;; decrement
;  ]
;end
;; Distance between two xy points, euclid


;to-report dist [x1 y1 x2 y2]
;  report sqrt ( getSquare (x2 - x1) + getSquare (y2 - y1) )
;end
;
;;; Squares a number, does API have this?
;to-report square [n]
;  report n * n 
;end
;
;;; Checks the xy distance from the list and makes sure its greater than proximity
;to-report xyProximity [ x y XYlist proximity ]
;  let i 0
;  while [ i < length XYlist ] [
;    if dist x y item i XYlist item (i + 1) XYlist < proximity [ report false ]
;    set i i + 2
;  ]
;  report true
;end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
649
470
16
16
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
114
23
180
56
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
115
69
178
102
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
20
124
192
157
DeathProbability
DeathProbability
0
100
0
1
1
%
HORIZONTAL

MONITOR
131
312
188
357
# Virus
count viruses
0
1
11

SLIDER
19
167
192
200
GenomeLength
GenomeLength
10
100
10
1
1
bits
HORIZONTAL

SLIDER
19
212
196
245
MutationLength
MutationLength
1
100
10
1
1
bits
HORIZONTAL

MONITOR
24
313
112
358
NIL
MatchCount
0
1
11

BUTTON
10
24
102
57
Test Mutation
test-mutation
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
25
365
87
410
Match %
MatchCount / TestCount * 100
2
1
11

SLIDER
8
263
195
296
MutationProbability
MutationProbability
1
100
8
1
1
 a base
HORIZONTAL

BUTTON
25
73
91
106
Infect
ask viruses with [mutated?] [\ninfect-cell\n]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
