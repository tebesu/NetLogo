;; Filename: VirusContainer_Memory
;; Author: Travis A. Ebesu
;; Description: Memory efficient, no breeds. Could easily be done in other languages


__includes [ "VirusGenotypes.nls" ]

extensions [graphics table array]

globals [
   WorldLength
   GridCount
   
   MutationCount
   ContainerSequence       ;; Mutation sequence for each container, [list]
   AdjacentContainers      ;; Container Xs adjacent containers, [list]
   
   DrugSequence 
   DrugContainers
   
   MutationLength
   VirusSequence          ;; Sequence of the original virus
   VirusSequenceLength 

   VirusCount             ;; Keeps track of number of alive viruses
   TotalVirusCount        ;; Keeps track of the total number of viruses
   ContainerVirusCounts   ;; Keeps track of the number of alive viruses in respective containers
]

;; For debugging purposes
patches-own [
  container
]



to setup
  clear-all
  initVirusGenotypes
  set WorldLength 8
  set VirusSequenceLength 10
  set VirusSequence (n-values VirusSequenceLength [0])
  
  set MutationLength 10
  
  set DrugSequence [ 0 0 0 0 ]
  set DrugContainers [ ]
  
  set AdjacentContainers [ ]
  set GridCount WorldLength * WorldLength                                ;; Number of grids
  resize-world (- WorldLength) WorldLength (- WorldLength) WorldLength   ;; resize-world 
  set ContainerVirusCounts array:from-list n-values GridCount [0]
  set ContainerSequence array:from-list n-values GridCount [n-values MutationLength [-1]]
  
  let i 0  
  repeat GridCount [    
      set AdjacentContainers lput getAdjacentContainers i AdjacentContainers
      set i i + 1
  ]
    
  setup-patches 
  create-viruses 1
  graphics:initialize  min-pxcor max-pycor patch-size
  graphics:set-font "MonoSpaced" "Bold" 13
  setup-env
  
  ;; Fix this repeat and one above, later
    set i 0  
  repeat GridCount [    
      ;; Partition the sequences to the same size
      let partition partitionSequence (array:item ContainerSequence i ) (length DrugSequence)
      
      ;; Check for a match with our drug sequence, filter if bits are equivilanet 
      if not (empty? filter [? = DrugSequence] partition ) [ set DrugContainers lput i DrugContainers ]
      set i i + 1
  ]
  if DebugDraw [ drawVirusCounts ] ;foreach DrugContainers [ ask patches with [container = ?] [ set pcolor green ]] ]
  reset-ticks
end

to setup-env 
   while [not (withinN)] [    
      env
   ]
end




to env
    let i 0
    ;; Create an array for the container sequences
    set ContainerSequence array:from-list n-values GridCount [n-values MutationLength [-1]]
    ;; Randomly generate the first one
    array:set ContainerSequence 0 (n-values MutationLength [0])
    
    ;; Goes through each row, unable to call it completely recursively with current implementation
    repeat WorldLength [ 
        setSequences i filter [ ? > i ] (getAdjacentContainers i)    
        set i i + WorldLength
    ]
    ;; Tries to match bits 
    fixme
end

to fixme
      let i 0
      repeat GridCount [
             foreach (item i AdjacentContainers) [
                   if not (hammingDistance array:item ContainerSequence i array:item ContainerSequence ? = 2) [
                       fix i
                    ]
             ]
             set i i + 1
       ]
end

;; Checks if the entire grid is within a hamming distance of 1 or 2 of each adjacent cell
to-report withinN
   let i 0
   repeat GridCount [
          foreach (item i AdjacentContainers) [
                if (hammingDistance array:item ContainerSequence i array:item ContainerSequence ? = 0 or hammingDistance array:item ContainerSequence i array:item ContainerSequence ? > 2) [
                    report false
                 ]
          ]
          set i i + 1
    ]
    report true
end

;; Try to match the bits from container x 
to fix [ i ]
repeat GridCount [
       foreach (item i AdjacentContainers) [
           let hd hammingDistance array:item ContainerSequence i array:item ContainerSequence ? 
           if not (hd = 2) [
               ifelse (hd = 0) [ ;; Hamming distance = 0, just shuffle the bits
                    array:set ContainerSequence i shuffle (array:item ContainerSequence i)
               ][            
                   ;; Get list of matches between the two sequence
                   let diff (map [?1 = ?2] array:item ContainerSequence i array:item ContainerSequence ?)
                   let temp array:item ContainerSequence i

                   let x 0
                   ;; Get the amount of positions in sequence, shuffle them
                   foreach shuffle (n-of (MutationLength - 1) (n-values MutationLength [?])) [
                     ;; flip only two bits
                     ifelse x <= 2 [ 
                          if item ? diff = false [ ;; check if we have a disagreement, then flip the bit
                              set temp replace-item ? temp ifelse-value (item ? temp = 1) [ 0 ] [ 1 ]
                              set x x + 1
                          ]
                       ][
                           array:set ContainerSequence i temp
                       ]
                   ]
               ]
            ]
       ]
    ]
end

;; set container sequences
to setSequences [ node nodeList ]
    ;; Flip two bits in the nodeList
    foreach (nodeList) [ flipBits node ? ]
    
    ;; check adjacent containers and check if they have a common container
    let common [ ]      
    foreach (getAdjacentContainers item 0 nodeList) [
        let temp ?
        if length nodeList > 1 [
           foreach (getAdjacentContainers item 1 nodeList) [
               if temp = ? [ ;; common node
                   set common ? ;; should only be one item I think
               ]
           ]
        ]
     ]
    if (is-number? common) [
        ;; set common node, based on the two adjacent nodes
        ;; with two bit switches from a common parent, shuffle the third one till it is the right hamming distance
        let temp shuffle (array:item ContainerSequence (item random 1 nodeList))
        while [ (hammingdistance temp array:item ContainerSequence (item 0 nodeList)) > 2 and (hammingdistance temp array:item ContainerSequence (item 1 nodeList)) > 2 ] [
            set temp shuffle (array:item ContainerSequence (item random 1 nodeList))
        ]
        array:set ContainerSequence common temp
        ;; do the next container
        setSequences item 0 nodeList filter [ ? > (item 0 nodeList) and ? > (item 0 nodeList)] (getAdjacentContainers item 0 nodeList)
    ]
end

;; Flips two bits in container sequence,
;; Inputs: parent index, child index
to flipBits [ main secondary ]
    if main < (GridCount - 1) and secondary < (Gridcount - 1) [
                   
    let n 2
    let temp array:item ContainerSequence main
    let pos n-of n (n-values (MutationLength - 1) [?]) ;; get two random positions in the sequence list
    let i 0
    repeat n [
        set temp replace-item (item i pos) temp ifelse-value (item (item i pos) temp = 1) [ 0 ] [ 1 ]
        set i i + 1
    ]
   array:set ContainerSequence secondary temp
   ]
end


to check
   let i 0
   let results [ ]
   repeat GridCount [
          foreach (item i AdjacentContainers) [
              if  (hammingDistance array:item ContainerSequence i array:item ContainerSequence ? > 2) [
                set results lput (list i ? hammingDistance array:item ContainerSequence i array:item ContainerSequence ?) results

              ]
          ]
          set i i + 1
    ]

    let out results
    foreach results [
        let j item 0 ?
        let k item 1 ?
        foreach results [
            set i 0
            if (j = item 1 ? and k = item 0 ?) [
                set results remove-item i results                
            ]
            set i i + 1
        ]
    ]
    
    foreach out [ print (word "Container " item 0 ? " - " item 1 ? "  ==>  " item 2 ?) ]
    print "\n\n"
    foreach results [print (word "Container " item 0 ? " - " item 1 ? "  ==>  " item 2 ?) ]
end

to draw-hd
  let i 0
  let DrawSequenceColor rgb 255 255 255
  let DrawVirusCountColor rgb 0 20 148
  clear-drawing  
  repeat GridCount  [
      let xy [ ]
      ask patches with [container = i] [ set xy (list pxcor pycor) ]

      graphics:set-text-color rgb 255 0 0
      if (sum array:item ContainerSequence i) > 0 [
          graphics:draw-text item 0 xy (item 1 xy + 0.7) "C"  reduce word (array:item ContainerSequence i) 
      ]
      graphics:set-text-color DrawSequenceColor
      ; left, right, up, down
      foreach getAdjacentContainers i [
      if (sum array:item ContainerSequence ?) >= 0 and not ((hammingdistance array:item ContainerSequence i array:item ContainerSequence ?) = 2) [
           ifelse ? > i [ ; to the right or bottom
             ifelse (i + 1) = ? [ ; right
                     graphics:draw-text (item 0 xy + 1) (item 1 xy) "C"  (word "" hammingdistance array:item ContainerSequence i array:item ContainerSequence ?) 
             ][ ; bottom
                  graphics:draw-text (item 0 xy) (item 1 xy - 1) "C"  (word "" hammingdistance array:item ContainerSequence i array:item ContainerSequence ?) 
             ]
           ][
             ifelse (i - 1) = ? [ ; left
                 graphics:draw-text (item 0 xy - 1) (item 1 xy) "C"  (word "" hammingdistance array:item ContainerSequence i array:item ContainerSequence ?) 
             ][ ; up
                 graphics:draw-text (item 0 xy) (item 1 xy + 1) "C"  (word "" hammingdistance array:item ContainerSequence i array:item ContainerSequence ?) 
             ] 
           ]
        ]
      ]
      set i i + 1
  ]
  
  ;  foreach array:to-list containersequence [ if (sum ?) > 0 [ print ? ] ]
end


to go
  if VirusCount = 0 [ output-print "\n--[[ No Viruses Left ]]--" if DebugDraw [ drawVirusCounts ] stop ] 
  if getInfectedCount = GridCount [ output-print (word "\n--[[ All Containers Infected ]]--\n" date-and-time) stop ]
  if ticks = 40 [output-print (word "\n--[[ 40 Generations ]]--\n" date-and-time) stop ] 
  ;;this needs to go foreach
;  kill-virus
;  ;; All containers infected?
;  replicate
  drug
  if DebugDraw [ drawVirusCounts ]
  output-print (word date-and-time ":   Virus: " VirusCount"  Infected: " getInfectedCount)

  tick 
end

;; Clean this up later
to replicate
   let temp table:make 
   foreach table:to-list VirusGenotypes [     
         let containerNumber item 0 ?
         foreach table:to-list (item 1 ?) [
                 repeat (item 1 ?) [
                    if random-float 100.0 < ReplicationProbability [
                          let sequence mutateSequence (item 0 ?)
                          let mutation [ ]
                          let partition partitionSequence sequence MutationLength        ;; Partition sequence to the size of mutation
                          let adjacent shuffle (item containerNumber AdjacentContainers)                    ;; Mix up the container numbers to get a random 
                          let localContainerNumber containerNumber
                          foreach adjacent [ set mutation lput array:item ContainerSequence ? mutation ]          ;; Get mutation sequence from each container number
                          let i 0
                          ;; Check for matches, move them in the container if found
                          while [ i < length mutation][
                              if not (empty? filter [? = (item i mutation)] partition ) [
                                  set MutationCount MutationCount + 1
                                  set localContainerNumber item i adjacent
                                  set i i + (length mutation)
                              ]
                              set i i + 1
                          ]  
                          array:set ContainerVirusCounts localContainerNumber ((array:item ContainerVirusCounts localContainerNumber) + 1)
                          set VirusCount VirusCount + 1
                          set TotalVirusCount TotalVirusCount + 1
                          incrementDict temp  localContainerNumber  sequence                          
                    ]
                 ]
         ]
   ]
   
   ;; merge temp dict and regular
   foreach table:to-list temp [
       let localContainerNumber item 0 ?
       foreach table:to-list (item 1 ?) [
           repeat item 1 ? [
               addGenotype localContainerNumber item 0 ? 
           ]
       ]
   ]
end


to kill-virus 
    foreach table:to-list VirusGenotypes [
        let contKey item 0 ?
        foreach (table:to-list item 1 ?) [
           repeat (item 1 ?) [
              if random-float 100.0 < DeathProbability [ 
                   let seqKey item 0 ?                        
                   removeGenotype contKey seqKey
                   array:set ContainerVirusCounts contKey ((array:item ContainerVirusCounts contKey) - 1)
                   set VirusCount VirusCount - 1
              ]
           ]
       ]   
    ]
end

;; double check this implementation when spawning more than 1 virus, for Virusgenotypes and totalvirusgenotypes
to create-viruses [ n ]
  repeat n [
     let sequence n-values VirusSequenceLength [one-of VirusSequence]      ;; Create a random virus seq
     let c (random (GridCount - 1))
     addGenotype c  sequence                          
     array:set ContainerVirusCounts c ((array:item ContainerVirusCounts c) + 1)
     set VirusCount VirusCount + 1
     set TotalVirusCount TotalVirusCount + 1
  ]
end


to incrementDict [ dict cont seq ]
  if not (table:has-key? dict cont) [ table:put dict cont table:make ]
  ifelse table:has-key? (table:get dict cont) seq [
      table:put (table:get dict cont) seq (table:get (table:get dict cont) seq) + 1
  ][
      table:put (table:get dict cont) seq 1
  ]
end


to drawVirusCounts
  let DrawSequenceColor rgb 255 255 255
  let DrawVirusCountColor rgb 0 20 148
  clear-drawing  
  let i 0
  repeat GridCount  [
      let xy [ ]
      ask patches with [container = i] [ set xy (list pxcor pycor) ]
      graphics:set-text-color DrawSequenceColor
      graphics:draw-text item 0 xy (item 1 xy + 0.7) "C"  reduce word (array:item ContainerSequence i) 
      let c array:item ContainerVirusCounts i
      ifelse c > 0 [ 
          graphics:set-text-color rgb 200 3 3
      ][ graphics:set-text-color DrawVirusCountColor ]
      graphics:draw-text (item 0 xy )  (item 1 xy + 1.15) "C" (word array:item ContainerVirusCounts i)
      set i i + 1
  ]
end


to setup-patches
  let BackgroundColor rgb 84 84 84
  let x (- WorldLength)
  let y WorldLength
  let gridSize 2                                                         ;; x + 1 => x by x size for each grid
  let halfGridSize round ( gridSize / 2 )
  let containerX (- WorldLength) + halfGridSize
  let containerY WorldLength - halfGridSize
  let c 0
  
  ; Iterate over patches, top to bottom, right to left
  while [ y >= (- WorldLength) ] [
      while [ x <= WorldLength ] [
         ; Color border of grids
         ask patch x y [ set pcolor BackgroundColor set container -1 ]
         ask patch y x [ set pcolor BackgroundColor set container -1 ] 
         
         ; To setup/color inside the grids, slightly different parameters
         if (containerY >= (- WorldLength) and containerX <= WorldLength ) [
             ask patch containerX containerY [  
                 set container c
             ]
             set c c + 1 
             set containerX containerX + gridSize
         ]
         set x x + gridSize
     ]
     ; containerX/Y are separate because they mark the inside of grids and x y mark the outside
     set containerY containerY - gridSize      
     set containerX (- WorldLength) + halfGridSize
     set y y - 1 
     set x (- WorldLength)
  ]
  
  foreach DrugContainers [ ask patches with [container = ?] [ set pcolor green ]]
end



;;  Creates a list from the sequence of mSize
;;  eg [ 0 1 0 1] 2 returns [[0 1] [ 1 0] [ 0 1]] 
to-report partitionSequence [ seq mSize ]
  let i 0
  let res [ ]
  while [ (i + mSize) <= length seq ] [
      set res lput sublist seq i (i + mSize) res
      set i i + 1
  ]
  report res
end



;; Input: sequence list of 0s and/or 1s
;; Returns: the mutated sequence, randomly
to-report mutateSequence [ s ]
    report map [ifelse-value (random-float 100.0 < MutationProbability) [one-of [0 1]] [?]] s
end


;; Input: Container Number
;; Returns: A list of container numbers that are immediately adjacent to the cell
to-report getAdjacentContainers [ current ]
  let containerNumbers [ ]
  let result [ ]
  
  let edge (current mod WorldLength) ; left edge = 0 and right edge = (n - 1), where n = WorldLength
  let row floor (current / WorldLength) ; Gets row # 0 - (n - 1), n = WorldLength
  
  ;; Check Left
  if edge != 0 and current > 0 [ set containerNumbers lput (current - 1) containerNumbers ]     
  
  ;;Check Right
  if edge != (WorldLength - 1) and current < GridCount [ set containerNumbers lput (current + 1) containerNumbers ]
 
  ;; Check Above
  if row != 0 [ set containerNumbers lput (current - WorldLength) containerNumbers ]
  
  ;;Check below
  if row != (WorldLength - 1) [ set containerNumbers lput (current + WorldLength) containerNumbers ]
  
  report containerNumbers
end

;; Uri Wilensky
to-report hammingDistance [sequence1 sequence2]
  if length sequence1 = length sequence2 [ ;; 
      report (length remove true (map [?1 = ?2] sequence1 sequence2))
  ]
  report false
end


to-report convertBinaryLength [ num len ]
  if num = 0 [ report [0] ]
  
  let k 2 ; change k to convert to different bases
  let digit [ ]
  while [ num != 0 ] [
    let rem floor ( num mod k )
    set num floor ( num / k )
    set digit lput rem digit
  ]
  let diff len - (length digit)
  repeat diff [ set digit lput 0 digit ]
  report digit
end


;; Input: number
;; Returns: a list the number equivalent in binary 
to-report convertBinary [ num ]
  if num = 0 [ report [0] ]
  
  let k 2 ; change k to convert to different bases
  let digit [ ]
  while [ num != 0 ] [
    let rem floor ( num mod k )
    set num floor ( num / k )
    set digit lput rem digit
  ]
  report digit
end

;; Input: list of binary
;; Returns: the converted number in base 10
to-report convertDecimal [ num ]
  let i 0
  let total 0
  while [ i < length num ] [
      if item i num = 1 [
          set total total +  2 ^ i
      ]
      set i i + 1
  ]
  report total
end
@#$#@#$#@
GRAPHICS-WINDOW
225
10
685
491
7
7
30.0
1
10
1
1
1
0
1
1
1
-7
7
-7
7
0
0
1
ticks
30.0

BUTTON
25
10
91
43
Setup
setup\n\n
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
120
10
183
43
Go
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
5
135
205
168
MutationProbability
MutationProbability
0
100
20
1
1
%
HORIZONTAL

SLIDER
5
95
205
128
DeathProbability
DeathProbability
0
100
5
1
1
%
HORIZONTAL

OUTPUT
792
396
1251
555
12

SLIDER
5
55
205
88
ReplicationProbability
ReplicationProbability
1
100
50
1
1
%
HORIZONTAL

MONITOR
5
305
120
350
Infected Containers
getInfectedCount
0
1
11

MONITOR
5
185
97
230
Virus Count
VirusCount
0
1
11

BUTTON
1065
255
1135
288
Go * 5
repeat 5 [ go ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1065
200
1183
233
DebugDraw
DebugDraw
0
1
-1000

MONITOR
110
185
205
230
NIL
MutationCount
0
1
11

MONITOR
110
245
205
290
Mutation Rate %
MutationCount / VirusCount * 100
4
1
11

MONITOR
5
245
95
290
Death rate%
(TotalVirusCount - VirusCount) / TotalVirusCount * 100
4
1
11

PLOT
811
13
1038
167
Diversity HD
Hamming Distance
Virus Population
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram TotalVirusGenotypes"

BUTTON
1063
304
1213
337
Draw HammingDistances
draw-hd
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
735
190
1045
350
Diversity Genotype
NIL
NIL
0.0
1024.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram Diversity"

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
<experiments>
  <experiment name="Drugless" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="35"/>
    <metric>VirusCount</metric>
    <metric>TotalVirusCount</metric>
    <metric>MutationCount</metric>
    <metric>length filter [ ? = 0 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 1 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 2 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 3 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 4 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 5 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 6 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 7 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 8 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 9 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 10 ] TotalVirusGenotypes</metric>
    <enumeratedValueSet variable="DebugDraw">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReplicationProbability">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="DeathProbability" first="5" step="1" last="10"/>
    <steppedValueSet variable="MutationProbability" first="10" step="1" last="15"/>
  </experiment>
  <experiment name="aws" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="35"/>
    <metric>VirusCount</metric>
    <metric>TotalVirusCount</metric>
    <metric>MutationCount</metric>
    <metric>length filter [ ? = 0 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 1 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 2 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 3 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 4 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 5 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 6 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 7 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 8 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 9 ] TotalVirusGenotypes</metric>
    <metric>length filter [ ? = 10 ] TotalVirusGenotypes</metric>
    <enumeratedValueSet variable="DebugDraw">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ReplicationProbability">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="DeathProbability" first="5" step="1" last="7"/>
    <steppedValueSet variable="MutationProbability" first="10" step="1" last="12"/>
  </experiment>
</experiments>
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
1
@#$#@#$#@
