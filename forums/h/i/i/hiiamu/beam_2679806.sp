#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <sdkhooks>

#define PREFIX "\x01\x01[\x05JS\x01]"
#define MENUTITLE "SETTINGS - BEAM"

public Plugin myinfo = {
	name = "jump beam menu",
	author = "hiiamu, zwolof",
	description = "Beam menu for hns",
	version = "0.1.0",
	url = "/id/hiiamu & /id/zwolof"
}

float g_fLastPosition[MAXPLAYERS+1][3]
		, g_fJumpPosition[MAXPLAYERS+1][3]
		, g_fBeamZ[MAXPLAYERS+1]
		, g_fLastBeamZ[MAXPLAYERS+1];

bool g_bPlayerJumped[MAXPLAYERS+1]
	 , g_bPlayerDucked[MAXPLAYERS+1]
	 //, g_bSpeedBeam[MAXPLAYERS+1]
	 //, g_bTouchingTrigger[MAXPLAYERS+1]
	 , g_bPlayerOnGround[MAXPLAYERS+1]
	 , g_bWasOnLadder[MAXPLAYERS+1]
	 , g_bOnSurf[MAXPLAYERS+1]
	 //, g_bTouchingWall[MAXPLAYERS+1]
	 , g_bBeam[MAXPLAYERS+1]
	 , g_bGroundFollow[MAXPLAYERS+1]
	 , g_bAirFollow[MAXPLAYERS+1]
	 , g_bShowDucks[MAXPLAYERS+1];

int g_Beam[2]
	, g_iStandColor[MAXPLAYERS+1]
	, g_iDuckColor[MAXPLAYERS+1];

Handle g_hGroundFollowCookie = INVALID_HANDLE
		 , g_hAirFollowCookie = INVALID_HANDLE
		 , g_hStandColorCookie = INVALID_HANDLE
		 , g_hDuckColorCookie = INVALID_HANDLE
		 , g_hBeamCookie = INVALID_HANDLE
		 , g_hShowDucksCookie = INVALID_HANDLE;

int g_iRGBA[][] = {
	{24, 84, 249, 255}, 	//blue
	{244, 80, 80, 255},		//red
	{151, 15, 215, 255},	//purple
	{28, 215, 15, 255},		//green
	{215, 151, 15, 255},	//yellow
	{255, 255, 255, 255},	//white
	{0, 255, 0, 255},		//green
	{0, 255, 255, 255},		//light blue
	{0, 0, 255, 255},		//dark blue
	{127, 0, 255, 255},		//purple
	{255, 0, 127, 255},		//pink
	{255, 182, 193, 255}	//light pink
};

public void OnPluginStart() {
	RegConsoleCmd("sm_beam", Client_Beam, "Beam menu");

	HookEvent("player_jump", Event_OnPlayerJump);

	//HookEntityOutput("trigger_teleport", "OnStartTouch", StartTouchTrigger);
	//HookEntityOutput("trigger_teleport", "OnEndTouch", EndTouchTrigger);

	//COOKIES
	g_hAirFollowCookie = RegClientCookie("AirFollowToggle", "AirFollow Cookie", CookieAccess_Private);
	g_hGroundFollowCookie = RegClientCookie("GroudFollowToggle", "GroundFollow Cookie", CookieAccess_Private);
	g_hStandColorCookie = RegClientCookie("StandColor", "Standing Beam Color Cookie", CookieAccess_Private);
	g_hDuckColorCookie = RegClientCookie("DuckColor", "Ducking Beam Color Cookie", CookieAccess_Private);
	g_hBeamCookie = RegClientCookie("BeamToggle", "Beam Cookie", CookieAccess_Private);
	g_hShowDucksCookie = RegClientCookie("ShowDucksToggle", "ShowDucks Cookie", CookieAccess_Private);

	//COOKIE SHIT
	for(int i = MaxClients; i > 0; --i) {
		if(AreClientCookiesCached(i))
			OnClientPostAdminCheck(i);
	}
}

public void OnMapStart() {
	g_Beam[0] = PrecacheModel("materials/sprites/laser.vmt", true);
	g_Beam[1] = PrecacheModel("materials/sprites/laser.vmt", true);
/*	int ent = -1;
	SDKHook(0,SDKHook_Touch,Touch_Wall);
	while((ent = FindEntityByClassname(ent,"func_breakable")) != -1)
		SDKHook(ent,SDKHook_Touch,Touch_Wall);
	ent = -1;
	while((ent = FindEntityByClassname(ent,"func_illusionary")) != -1)
		SDKHook(ent,SDKHook_Touch,Touch_Wall);
	ent = -1;
	while((ent = FindEntityByClassname(ent,"func_wall")) != -1)
		SDKHook(ent,SDKHook_Touch,Touch_Wall);
	ent = -1;*/
}
/*
public OnMapEnd() {
	int ent = -1;
	SDKUnhook(0,SDKHook_Touch,Touch_Wall);
	while((ent = FindEntityByClassname(ent,"func_breakable")) != -1)
		SDKUnhook(ent,SDKHook_Touch,Touch_Wall);
	ent = -1;
	while((ent = FindEntityByClassname(ent,"func_illusionary")) != -1)
		SDKUnhook(ent,SDKHook_Touch,Touch_Wall);
	ent = -1;
	while((ent = FindEntityByClassname(ent,"func_wall")) != -1)
		SDKUnhook(ent,SDKHook_Touch,Touch_Wall);
	ent = -1;
}
*/
public Event_OnPlayerJump(Handle event, char[] error, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bPlayerJumped[client] = true;
}

public OnClientPostAdminCheck(int client) {
	char sCookie[2];

	GetClientCookie(client, g_hStandColorCookie, sCookie, sizeof(sCookie));
	g_iStandColor[client] = StringToInt(sCookie);

	GetClientCookie(client, g_hDuckColorCookie, sCookie, sizeof(sCookie));
	g_iDuckColor[client] = StringToInt(sCookie);

	GetClientCookie(client, g_hBeamCookie, sCookie, sizeof(sCookie));
	g_bBeam[client] = (sCookie[0] != '\0' && StringToInt(sCookie));

	GetClientCookie(client, g_hShowDucksCookie, sCookie, sizeof(sCookie));
	g_bShowDucks[client] = (sCookie[0] != '\0' && StringToInt(sCookie));

	GetClientCookie(client, g_hAirFollowCookie, sCookie, sizeof(sCookie));
	g_bAirFollow[client] = (sCookie[0] != '\0' && StringToInt(sCookie));

	GetClientCookie(client, g_hGroundFollowCookie, sCookie, sizeof(sCookie));
	g_bGroundFollow[client] = (sCookie[0] != '\0' && StringToInt(sCookie));
}

public Action Client_Beam(int client, int args) {
	Beam_Main(client);
	return Plugin_Handled;
}

public Action Beam_Main(int client) {
	Menu menu = new Menu(BeamMenuHandler);
	menu.SetTitle(MENUTITLE);

	char szBuffer[128];

	FormatEx(szBuffer, 128, "Beam %s", g_bBeam[client] ? "[ENABLED]" : "[DISABLED]");
	menu.AddItem("0", szBuffer, ITEMDRAW_DEFAULT);

	FormatEx(szBuffer, 128, "Show Ducks %s", g_bShowDucks[client] ? "[ENABLED]" : "[DISABLED]");
	menu.AddItem("1", szBuffer, g_bBeam[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	FormatEx(szBuffer, 128, "Air Follow %s", g_bAirFollow[client] ? "[ENABLED]" : "[DISABLED]");
	menu.AddItem("2", szBuffer, g_bBeam[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	FormatEx(szBuffer, 128, "Ground Follow %s", g_bGroundFollow[client] ? "[ENABLED]" : "[DISABLED]");
	menu.AddItem("3", szBuffer, g_bBeam[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	menu.AddItem("4", "Beam Color", g_bBeam[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	if(g_bBeam[client])
		menu.AddItem("5", "Crouch Color", g_bShowDucks[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int BeamMenuHandler(Menu menu, MenuAction action, int client, int select) {
	if(action == MenuAction_End)
		delete menu;
	else if(action == MenuAction_Select) {
		switch(select) {
			case 0: {
				g_bBeam[client] = !g_bBeam[client];

				PrintToChat(client, "%s Beam has been %s\x01.", PREFIX, g_bBeam[client] ? "\x04enabled" : "\x02disabled");

				char sCookie[2];
				IntToString(g_bBeam[client], sCookie, sizeof(sCookie));
				SetClientCookie(client, g_hBeamCookie, sCookie);
				Beam_Main(client);
			}
			case 1: {
				g_bShowDucks[client] = !g_bShowDucks[client];

				PrintToChat(client, "%s Show ducks has been %s\x01.", PREFIX, g_bShowDucks[client] ? "\x04enabled" : "\x02disabled");

				char sCookie[2];
				IntToString(g_bShowDucks[client], sCookie, sizeof(sCookie));
				SetClientCookie(client, g_hShowDucksCookie, sCookie);
				Beam_Main(client);
			}
			case 2: {
				g_bAirFollow[client] = !g_bAirFollow[client];

				PrintToChat(client, "%s Air follow has been %s\x01.", PREFIX, g_bAirFollow[client] ? "\x04enabled" : "\x02disabled");

				char sCookie[2];
				IntToString(g_bAirFollow[client], sCookie, sizeof(sCookie));
				SetClientCookie(client, g_hAirFollowCookie, sCookie);
				Beam_Main(client);
			}
			case 3: {
				g_bGroundFollow[client] = !g_bGroundFollow[client];

				PrintToChat(client, "%s Ground follow has been %s\x01.", PREFIX, g_bGroundFollow[client] ? "\x04enabled" : "\x02disabled");

				char sCookie[2];
				IntToString(g_bGroundFollow[client], sCookie, sizeof(sCookie));
				SetClientCookie(client, g_hGroundFollowCookie, sCookie);
				Beam_Main(client);
			}
			case 4:
				StandingColors(client);
			case 5:
				DuckingColors(client);
		}
	}
	else if(action == MenuAction_Cancel) {
		if(CommandExists("sm_js"))
			ClientCommand(client, "sm_js");
	}
}

stock void SetClientCookieBool(int client, Handle cookie, bool value) {
	char sValue[8];
	IntToString(value, sValue, sizeof(sValue));
	SetClientCookie(client, cookie, sValue);
}

public Action StandingColors(int client) {
	Menu menu = new Menu(StandColorHandle);
	menu.SetTitle(MENUTITLE);
	menu.AddItem("0", "Blue");
	menu.AddItem("1", "Light Red");
	menu.AddItem("2", "Purple");
	menu.AddItem("3", "Light Green");
	menu.AddItem("4", "Yellow");
	menu.AddItem("5", "White");
	menu.AddItem("6", "Dark Green");
	menu.AddItem("7", "Cyan");
	menu.AddItem("8", "Dark Blue");
	menu.AddItem("9", "Light Purple");
	menu.AddItem("10", "Pink");
	menu.AddItem("11", "Light Pink");
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int StandColorHandle(Menu menu, MenuAction action, int client, int select) {
	if(action == MenuAction_End)
		delete menu;
	else if(action == MenuAction_Select) {
		char choice[32];
		menu.GetItem(select, choice, sizeof(choice));
		g_iStandColor[client] = StringToInt(choice);
		StandingColors(client);
		SetClientCookie(client, g_hStandColorCookie, choice);
	}
	else if(action == MenuAction_Cancel)
		Beam_Main(client);
}

public Action DuckingColors(int client) {
	Menu menu = new Menu(ShowDucksColorsMenuHandle);
	menu.SetTitle(MENUTITLE);
	menu.AddItem("0", "Blue");
	menu.AddItem("1", "Light Red");
	menu.AddItem("2", "Purple");
	menu.AddItem("3", "Light Green");
	menu.AddItem("4", "Yellow");
	menu.AddItem("5", "White");
	menu.AddItem("6", "Dark Green");
	menu.AddItem("7", "Cyan");
	menu.AddItem("8", "Dark Blue");
	menu.AddItem("9", "Light Purple");
	menu.AddItem("10", "Pink");
	menu.AddItem("11", "Light Pink");
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int ShowDucksColorsMenuHandle(Menu menu, MenuAction action, int client, int select) {
	if(action == MenuAction_End)
		delete menu;
	else if(action == MenuAction_Select) {
		char choice[32];
		menu.GetItem(select, choice, sizeof(choice));
		g_iDuckColor[client] = StringToInt(choice);
		SetClientCookie(client, g_hDuckColorCookie, choice);
		DuckingColors(client);
	}
	else if(action == MenuAction_Cancel)
		Beam_Main(client);
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon) {
	if(!IsFakeClient(client) && IsClientInGame(client)) {
		float origin[3];
		GetClientAbsOrigin(client, origin);
		if(g_bShowDucks[client]) {
			if(buttons & IN_DUCK)
				g_bPlayerDucked[client] = true;
			else
				g_bPlayerDucked[client] = false;
		}
		if((GetEntityFlags(client) & FL_ONGROUND)) {
			g_bPlayerJumped[client] = false;
			g_bPlayerOnGround[client] = true;
			g_bWasOnLadder[client] = false;
			g_bOnSurf[client] = false;
		}
		else
			g_bPlayerOnGround[client] = false;

		if(g_bPlayerOnGround[client])
			g_fJumpPosition[client] = origin;

		if(GetEntityMoveType(client) == MOVETYPE_LADDER)
			g_bWasOnLadder[client] = true;

		if(origin[2] < g_fJumpPosition[client][2] || g_bWasOnLadder[client] || g_bOnSurf[client])
			g_fBeamZ[client] = origin[2];
		else
			g_fBeamZ[client] = g_fJumpPosition[client][2];
		if(g_bAirFollow[client])
			g_fBeamZ[client] = origin[2];
		if(g_bBeam[client])
			DrawBeam(client, origin);
		g_fLastPosition[client] = origin;
		g_fLastBeamZ[client] = g_fBeamZ[client];

	//surf check
		float vPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);
		float vMins[3];
		GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);
		float vMaxs[3];
		GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);
		float vEndPos[3];
		vEndPos[0] = vPos[0];
		vEndPos[1] = vPos[1];
		vEndPos[2] = vPos[2] - FindConVar("sv_maxvelocity").FloatValue;
		TR_TraceHullFilter(vPos, vEndPos, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, TraceRayDontHitSelf, client);
		if(TR_DidHit()) {
			float vPlane[3];
			TR_GetPlaneNormal(INVALID_HANDLE, vPlane);
			if(0.7 >= vPlane[2] && WallCheck(client))
				g_bOnSurf[client] = true;
		}
	}
}

public void DrawBeam(client, float origin[3]) {
	if(g_bPlayerOnGround[client] && !g_bGroundFollow[client])
		return;

	float v1[3];
	float v2[3];
	v1[0] = origin[0];
	v1[1] = origin[1];
	v1[2] = g_fBeamZ[client];
	v2[0] = g_fLastPosition[client][0];
	v2[1] = g_fLastPosition[client][1];
	v2[2] = g_fLastBeamZ[client];
	if(g_bPlayerDucked[client]) {
		//g_bSpeedBeam[client] = false;
		TE_SetupBeamPoints(v1, v2, g_Beam[0], 0, 0, 0, 2.5, 3.0, 3.0, 10, 0.0, g_iRGBA[g_iDuckColor[client]], 0);
		TE_SendToClient(client);
	}
	else {
		//g_bSpeedBeam[client] = false;
		TE_SetupBeamPoints(v1, v2, g_Beam[1], 0, 0, 0, 2.5, 2.5, 2.5, 10, 0.0, g_iRGBA[g_iStandColor[client]], 0);
		TE_SendToClient(client);
	}
}
/*
public int StartTouchTrigger(const char[] output, int entity, int client, float delay) {
	if(client < 1 || client > MaxClients)
		return;
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	g_bTouchingTrigger[client] = true;
}

public int EndTouchTrigger(const char[] output, int entity, int client, float delay) {
	if(client < 1 || client > MaxClients)
		return;
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	CreateTimer(0.1, BlockOffTrigger, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action BlockOffTrigger(Handle timer, any client) {
	gB_TouchingTrigger[client] = false;
	return Plugin_Stop;
}
*/
public bool TraceRayDontHitSelf(int entity, int mask, any data) {
	return entity != data && !(0 < entity <= MaxClients);
}

stock bool IsValidClient(client) {
	if(client >= 1 && client <= MaxClients && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client))
		return true;
	return false;
}

public bool WallCheck(client) {
	float pos[3];
	float endpos[3];
	float angs[3];
	float vecs[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angs);
	GetAngleVectors(angs, vecs, NULL_VECTOR, NULL_VECTOR);
	angs[1] = -180.0;
	while(angs[1] != 180.0) {
		Handle trace = TR_TraceRayFilterEx(pos, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
		if(TR_DidHit(trace)) {
			TR_GetEndPosition(endpos, trace);
			float fdist = GetVectorDistance(endpos, pos, false);
			if(fdist <= 25.0) {
				CloseHandle(trace);
				return true;
			}
		}
		CloseHandle(trace);
		angs[1]+=15.0;
	}
	return false;
}
/*
public Action Touch_Wall(ent,client) {
	if(IsValidClient(client)) {
		if(!(GetEntityFlags(client)&FL_ONGROUND) && g_bPlayerJumped[client]) {
			float origin[3];
			float temp[3];
			GetGroundOrigin(client, origin);
			GetClientAbsOrigin(client, temp);
			if(temp[2] - origin[2] <= 0.1)
				g_bTouchingWall[client] = true;
			else
				g_bTouchingWall[client] = false;
		}
	}
	return Plugin_Continue;
}
*/
stock GetGroundOrigin(client, float pos[3]) {
	float fOrigin[3];
	float result[3];
	GetClientAbsOrigin(client, fOrigin);
	TraceClientGroundOrigin(client, result, 100.0);
	pos = fOrigin;
	pos[2] = result[2];
}

stock TraceClientGroundOrigin(client, float result[3], float offset) {
	float temp[2][3];
	GetClientEyePosition(client, temp[0]);
	temp[1] = temp[0];
	temp[1][2] -= offset;
	float mins[]={-16.0, -16.0, 0.0};
	float maxs[]={16.0, 16.0, 60.0};
	Handle trace = TR_TraceHullFilterEx(temp[0], temp[1], mins, maxs, MASK_SHOT, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) {
		TR_GetEndPosition(result, trace);
		CloseHandle(trace);
		return 1;
	}
	CloseHandle(trace);
	return 0;
}

bool TraceEntityFilterPlayer(entity, contentsMask) {
	return entity > MaxClients;
}
