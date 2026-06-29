/*========================================
** Measure by DaFox
** Compatible with: Counter-Strike Source
** Thanks to SchlumPF & Exolent & Fatalis & petsku & #sourcemod
**======================================*/

#define VERSION	"1.0.0.1" //Dont forget to change the version number in the Menu

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "Measure",
	author = "DaFox",
	description = "Measure the distance between two points",
	version = VERSION,
	url = "http://www.google.com/"
}

//==============================================================================================

new g_iGlowSprite

new Float:g_vMeasurePos[MAXPLAYERS+1][2][3]
new bool:g_bMeasurePosSet[MAXPLAYERS+1][2]

new Handle:g_hMainMenu = INVALID_HANDLE
new Handle:g_hP2PRed[MAXPLAYERS+1] = { INVALID_HANDLE,... }
new Handle:g_hP2PGreen[MAXPLAYERS+1] = { INVALID_HANDLE,... }

public OnPluginStart() {
	CreateConVar("sm_measureversion",VERSION,"Measure Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY)
	RegConsoleCmd("sm_measure",Command_Menu)
		
	g_hMainMenu = CreateMenu(Handler_MainMenu)
	SetMenuTitle(g_hMainMenu,"Measure 1.0.0.1 by DaFox")
	AddMenuItem(g_hMainMenu,"","Point 1 (Red)")
	AddMenuItem(g_hMainMenu,"","Point 2 (Green)")
	AddMenuItem(g_hMainMenu,"","Find Distance")
	AddMenuItem(g_hMainMenu,"","Reset")
}

public OnMapStart() {
	g_iGlowSprite = PrecacheModel("materials/sprites/bluelaser1.vmt",true)
}

public OnClientDisconnect(client) {
	ResetPos(client)
}

//_________________
// Menu callbacks  \_____________________________
//==============================================================================================

public Handler_MainMenu(Handle:menu,MenuAction:action,param1,param2) {
	if(action == MenuAction_Select) {
		switch(param2) {
			case 0: {	//Point 1 (Red)
				GetPos(param1,0)
			}
			case 1: {	//Point 2 (Green)
				GetPos(param1,1)
			}
			case 2: {	//Find Distance
				if(g_bMeasurePosSet[param1][0] && g_bMeasurePosSet[param1][1]) {
					new Float:vDist = GetVectorDistance(g_vMeasurePos[param1][0],g_vMeasurePos[param1][1])
					new Float:vHightDist = (g_vMeasurePos[param1][0][2] - g_vMeasurePos[param1][1][2])
					PrintToChat(param1,"[Measure] Distance: %f (Height offset: %f)",vDist,vHightDist)
					
					Beam(param1,g_vMeasurePos[param1][0],g_vMeasurePos[param1][1],4.0,2.0,0,0,255)
				}
				else {
					PrintToChat(param1,"[Measure] You must set both points before finding a distance.")
				}
			}
			case 3: {	//Reset
				ResetPos(param1)
			}
		}
		DisplayMenu(g_hMainMenu,param1,MENU_TIME_FOREVER)
	}
	else if(action == MenuAction_Cancel) {
		ResetPos(param1)
	}
}

//__________________
// Other callbacks  \____________________________
//==============================================================================================

public Action:Command_Menu(client,args) {
	DisplayMenu(g_hMainMenu,client,MENU_TIME_FOREVER)
	return Plugin_Handled
}

GetPos(client,arg) {
	decl Float:origin[3],Float:angles[3]
	
	GetClientEyePosition(client,origin)
	GetClientEyeAngles(client,angles)
	
	new Handle:trace = TR_TraceRayFilterEx(origin,angles,MASK_SHOT,RayType_Infinite,TraceFilterPlayers,client)

	if(!TR_DidHit(trace)) {
		CloseHandle(trace)
		PrintToChat(client,"[Measure] You are not aiming at anything solid!")
		return
	}

	TR_GetEndPosition(origin,trace)
	CloseHandle(trace)

	g_vMeasurePos[client][arg][0] = origin[0]
	g_vMeasurePos[client][arg][1] = origin[1]
	g_vMeasurePos[client][arg][2] = origin[2]
	
	PrintToChat(client,"[Measure] Got Point %i at X:%.2f Y:%.2f Z:%.2f",arg+1,origin[0],origin[1],origin[2])
	
	if(arg == 0) {
		if(g_hP2PRed[client] != INVALID_HANDLE) {
			CloseHandle(g_hP2PRed[client])
			g_hP2PRed[client] = INVALID_HANDLE
		}
		g_bMeasurePosSet[client][0] = true
		g_hP2PRed[client] = CreateTimer(1.0,Timer_P2PRed,client,TIMER_REPEAT)
		P2PXBeam(client,0)
	}
	else {
		if(g_hP2PGreen[client] != INVALID_HANDLE) {
			CloseHandle(g_hP2PGreen[client])
			g_hP2PGreen[client] = INVALID_HANDLE
		}
		g_bMeasurePosSet[client][1] = true
		P2PXBeam(client,1)
		g_hP2PGreen[client] = CreateTimer(1.0,Timer_P2PGreen,client,TIMER_REPEAT)
	}
}

public Action:Timer_P2PRed(Handle:timer,any:client) {
	P2PXBeam(client,0)
}

public Action:Timer_P2PGreen(Handle:timer,any:client) {
	P2PXBeam(client,1)
}

P2PXBeam(client,arg) {
	decl Float:Origin0[3],Float:Origin1[3],Float:Origin2[3],Float:Origin3[3]
	
	Origin0[0] = (g_vMeasurePos[client][arg][0] + 8.0)
	Origin0[1] = (g_vMeasurePos[client][arg][1] + 8.0)
	Origin0[2] = g_vMeasurePos[client][arg][2]
	
	Origin1[0] = (g_vMeasurePos[client][arg][0] - 8.0)
	Origin1[1] = (g_vMeasurePos[client][arg][1] - 8.0)
	Origin1[2] = g_vMeasurePos[client][arg][2]
	
	Origin2[0] = (g_vMeasurePos[client][arg][0] + 8.0)
	Origin2[1] = (g_vMeasurePos[client][arg][1] - 8.0)
	Origin2[2] = g_vMeasurePos[client][arg][2]
	
	Origin3[0] = (g_vMeasurePos[client][arg][0] - 8.0)
	Origin3[1] = (g_vMeasurePos[client][arg][1] + 8.0)
	Origin3[2] = g_vMeasurePos[client][arg][2]
	
	if(arg == 0) {
		Beam(client,Origin0,Origin1,0.97,2.0,255,0,0)
		Beam(client,Origin2,Origin3,0.97,2.0,255,0,0)
	}
	else {
		Beam(client,Origin0,Origin1,0.97,2.0,0,255,0)
		Beam(client,Origin2,Origin3,0.97,2.0,0,255,0)
	}
}

Beam(client,Float:vecStart[3],Float:vecEnd[3],Float:life,Float:width,r,g,b) {
	TE_Start("BeamPoints")
	TE_WriteNum("m_nModelIndex",g_iGlowSprite)
	TE_WriteNum("m_nHaloIndex",0)
	TE_WriteNum("m_nStartFrame",0)
	TE_WriteNum("m_nFrameRate",0)
	TE_WriteFloat("m_fLife",life)
	TE_WriteFloat("m_fWidth",width)
	TE_WriteFloat("m_fEndWidth",width)
	TE_WriteNum("m_nFadeLength",0)
	TE_WriteFloat("m_fAmplitude",0.0)
	TE_WriteNum("m_nSpeed",0)
	TE_WriteNum("r",r)
	TE_WriteNum("g",g)
	TE_WriteNum("b",b)
	TE_WriteNum("a",255)
	TE_WriteNum("m_nFlags",0)
	TE_WriteVector("m_vecStartPoint",vecStart)
	TE_WriteVector("m_vecEndPoint",vecEnd)
	TE_SendToClient(client)
}

ResetPos(client) {
	if(g_hP2PRed[client] != INVALID_HANDLE) {
		CloseHandle(g_hP2PRed[client])
		g_hP2PRed[client] = INVALID_HANDLE
	}
	if(g_hP2PGreen[client] != INVALID_HANDLE) {
		CloseHandle(g_hP2PGreen[client])
		g_hP2PGreen[client] = INVALID_HANDLE
	}
	g_bMeasurePosSet[client][0] = false
	g_bMeasurePosSet[client][1] = false

	g_vMeasurePos[client][0][0] = 0.0 //This is stupid.
	g_vMeasurePos[client][0][1] = 0.0
	g_vMeasurePos[client][0][2] = 0.0
	g_vMeasurePos[client][1][0] = 0.0
	g_vMeasurePos[client][1][1] = 0.0
	g_vMeasurePos[client][1][2] = 0.0
}

//==============================================================================================

public bool:TraceFilterPlayers(entity,contentsMask) {
	return (entity > MaxClients) ? true : false
} //Thanks petsku