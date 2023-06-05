;*****************************************
;* This is file macro.cnc version changed at V4.03.20
;* It is automatically loaded
;* Customize this file yourself if you like
;* It contains:
;* - subroutine change_tool this is called on M6T..
;* - subroutine home_x .. home_z, called when home functions in GUI are activated
;* - subroutine home_all, called when home all button in GUI are activated
;* - subroutine user_1 .. user_11, called when user functions are activated
;*   user_1: zeroing Z using a moveable tool setter
;*   user_2: measuring the tool length using a fixed tool setter
;*   user_3: move z-, x- and y-axis to safe loading coordinates
;*
;* You may also add frequently used macro's in this file.
;****************************************

;Standard variables
;#4995 (Variable tool setter height for zeroing Z, used in zero_z)
;#4996 (Tool measurement safe hight, used inside m_tool)
;#4997 (X position of tool length measurement)
;#4998 (Y position of tool length measurement)
;#4999 (Chuck height, or zero - tool length height)

;User defined variables
;#3010 (X position of tool change, used in change_tool)
;#3011 (Y position of tool change, used in change_tool)

;User defined variables used for logic
;#3001 (Temporary toolnumber for measuring length, used in user_2, change_tool_and_measure and m_tool)
;#5015 (Indicate of succesfull toolchange, used in change_tool_and_measure)


;*****************************************
;* Defaults
;*****************************************

sub set_defaults

	msg "sub set_defaults, set default for variables used in this macro file"
	
	;Movable toolsetter height
	#4995 =    40.375
	
	;Safe z-axis height
	#4996 =    -5.000
	
	;Fixed toolsetter coordinates
	#4997 =    59.500
	#4998 = -2539.000
	#4999 =  -300.000
	
	;Safe loading coordinates
	#3010 =   400.000
	#3011 = -2250.000	
endsub


;*****************************************
;* Machine coordinates
;***************************************** 

sub goto_loading

	msg "sub goto_loading, move to tool loading coordinates"

	;Defaults
	gosub set_defaults
	
	;Switch off spindle
	m5
		
	;Move z-axis up to a safe height, x- and y to safe loading coordinates
	g90 
	g53 g0 z#4996
	g53 g0 x#3010 y#3011 	
endsub


;*****************************************
;* User functions, F1..F11 in user menu
;*****************************************

sub user_1

	msg "sub user_1, zero-z using movable tool setter"

	gosub zero_z
endsub

sub user_2

	msg "sub user_2, measure tool using static tool setter"

	;Set tool to current tool
	#3001 = #5008

	;Measure
	gosub m_tool
endsub

sub user_3

	msg "sub user_3, move to safe loading point"
	
	;Loading
	gosub goto_loading
endsub


;*****************************************
;* Home
;*****************************************

sub home_z

	msg "sub home_z, home z-axis"

	home z 
	g90
	g53 g1 z0 f1000
endsub

sub home_y

	msg "sub home_y, home y-axis"

	home y
	g90	
	g53 g1 y0 f1000
endsub

sub home_x

	msg "sub home_x, home x-axis"

	home x
	g90
	g53 g1 x0 f1000
endsub

sub home_all

	msg "sub home_all, home z-, y- and x-axis"

	gosub home_z
	gosub home_y
	gosub home_x
endsub


;*****************************************
;* Tool change
;*****************************************  

sub change_tool

	;Defaults
	gosub set_defaults
	
	;Check if not simulating or rendering
	if [[#5380 == 0] and [#5397 == 0]]

		msg "sub change_tool, change tool"				

		;Switch off spindle
		m5
		
		;Move z-axis up to a safe height
		g90 
		g53 g0 z#4996		
		
		;Check if tool change is needed
		if [#5008 <> #5011]
		
			;Tool change mandatory
			gosub change_tool_and_measure
		else
		
			;Tool change optional
			dlgmsg "Click 'OK' to confirm that tool change is needed." "Current tool" 5008 "Requested tool" 5011

			;Check user pressed OK
			if [#5398 == 1]	
			
				gosub change_tool_and_measure
			endif
		endif
	endif
endsub    

sub change_tool_and_measure

	;Defaults
	gosub set_defaults

	;Loading
	gosub goto_loading
	
	;Use #5015 to indicate succesfull tool change
	#5015 = 0 	

	while[ #5015 == 0 ]
	
		;Confirm tool is changed
		dlgmsg "Click 'OK' if the tool is changed." "New tool" 5011
					
		;Check user pressed OK
		if [#5398 == 1]
				
			;Toolchange confirmed
			#5015 = 1
			
			msg "tool " #5008 " changed to tool " #5011
			m6t[#5011]

			;Check tool
			if[#5011 <> 0]

				;Set tool to changed tool
				#3001 = #5011

				;Measure tool
				gosub m_tool

				;Tool length compensation on
				g43
			else

				;Tool length compensation off for tool 0
				g49			  
			endif
		endif
	endwhile
endsub


;*****************************************
;* Tool measure
;***************************************** 
	
sub m_tool

	;Defaults
	gosub set_defaults
	
	;Do this only when not simulating and not rendering
	if [[#5380 == 0] and [#5397 == 0]]

		msg "sub m_tool, measure tool length with toolsetter"

		;Check tool
		if [[#3001 < 1] or [#3001 > 99]]

			errmsg "tool must be in range of 1 .. 99 current tool is: "#3001
		endif

		msg "the tool to measure is: "#3001 

		;Move z-axis up to a safe height, x- and y to toolsetter coordinates
		g90 
		g53 g0 z#4996
		g53 g0 x#4997 y#4998 

		;Measure tool
		g91 
		g38.2 z-400 f400
		g1 z3 f1000
		g38.2 z-5 f30

		;Move z-axis up to a safe height
		g90 
		g53 g0 z#4996

		;Store tool length, diameter in tool table but only if actually measured
		;Leave tool table as is while rendering 
		if [#5397 == 0]

			;5401..5499 is for tool length setting
			#[5400 + #3001] = [#5053 - #4999]

			;5501..5599 is for tool diameter (not used)
			#[5500 + #3001] = 1

			;5601..5699 is for tool x offset (not used)
			#[5600 + #3001] = 0 

			msg "tool length measured="#[5400 + #3001]" stored at tool "#3001
		endif 	
	endif

	;Reset
	#3001 = -1
endsub


;*****************************************
;* Tool zero
;*****************************************  

sub zero_z

	;Defaults
	gosub set_defaults

	;Do this only when not simulating and not rendering
	if [[#5380==0] and [#5397==0]]

		msg "sub zero_z, zero z-axis using movable tool setter"

		;Zero tool
		g91 
		g38.2 z-400 f400
		g1 z3 f1000
		g38.2 z-5 f30
		
		;Set offset for z-axis
		g92 z#4995
		
		;Move z-axis up to a safe height
		g90 
		g53 g0 z#4996	
	endif
endsub
