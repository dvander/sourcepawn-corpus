#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <multicolors>

public Plugin:myinfo = 
{
	name = "SSJ: Advanced (fix)",
	author = "AlkATraZ",
	description = "Jump stats plugin",
	version = "1.1",
	url = "https://github.com/dominovr/ssj/"
}

#define BHOP_TIME 15

new String:g_msg_start[64];
new String:g_msg_text[64];
new String:g_msg_var[64];

new Handle:hMsgStart, Handle:hMsgText, Handle:hMsgVar;

new Handle:g_hAirAccel;

new Handle:g_hCookieEnabled;
new Handle:g_hCookieEveryJump;
new Handle:g_hCookieCurrentSpeed;
new Handle:g_hCookieHeightDiff;
new Handle:g_hCookieSpeedDiff;
new Handle:g_hCookieGainStats;
new Handle:g_hCookieDefaultsSet;

new bool:g_bEnabled[129];
new bool:g_bEveryJump[129];
new bool:g_bCurrentSpeed[129] = {true, ...};
new bool:g_bSpeedDiff[129];
new bool:g_bHeightDiff[129];
new bool:g_bGainStats[129];
new bool:g_bTouchesWall[129];

new g_iTicksOnGround[129];
new g_strafeTick[129];
new g_iJump[129];

new Float:g_flInitialSpeed[129];
new Float:g_flInitialHeight[129];
new Float:g_flOldHeight[129];
new Float:g_flOldSpeed[129];
new Float:g_flRawGain[129];

public OnAllPluginsLoaded()
{
	hMsgStart = CreateConVar("ssj_msgstart", "{green}[SSJ] {darkblue}- ", "SSJ messages prefix.");
	hMsgText = CreateConVar("ssj_msgtext", "{lightblue}", "SSJ messages color.");
	hMsgVar = CreateConVar("ssj_msgvar", "{darkred}", "SSJ variables color.");
	AutoExecConfig(true, "chat_formats", "ssj");
	
	GetConVarString(hMsgStart, g_msg_start, sizeof(g_msg_start));
	GetConVarString(hMsgText, g_msg_text, sizeof(g_msg_text));
	GetConVarString(hMsgVar, g_msg_var, sizeof(g_msg_var));
	
	HookConVarChange(hMsgStart, OnFormatsChanged);
	HookConVarChange(hMsgText, OnFormatsChanged);
	HookConVarChange(hMsgVar, OnFormatsChanged);
	
	HookEvent("player_jump", OnPlayerJump);
}

public OnPluginStart()
{
	RegConsoleCmd("sm_ssj", Command_SSJ, "SSJ");
	
	g_hAirAccel = FindConVar("sv_airaccelerate");
	
	g_hCookieEnabled = RegClientCookie("ssj_enabled", "ssj_enabled", CookieAccess_Public);
	g_hCookieEveryJump = RegClientCookie("ssj_displaymode", "ssj_displaymode", CookieAccess_Public);
	g_hCookieCurrentSpeed = RegClientCookie("ssj_currentspeed", "ssj_currentspeed", CookieAccess_Public);
	g_hCookieSpeedDiff = RegClientCookie("ssj_speeddiff", "ssj_speeddiff", CookieAccess_Public);
	g_hCookieHeightDiff = RegClientCookie("ssj_heightdiff", "ssj_heightdiff", CookieAccess_Public);
	g_hCookieGainStats = RegClientCookie("ssj_gainstats", "ssj_gainstats", CookieAccess_Public);
	g_hCookieDefaultsSet = RegClientCookie("ssj_defaults", "ssj_defaults", CookieAccess_Public);
	
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
			OnClientCookiesCached(i);
		}
	}
}

public OnClientCookiesCached(client)
{
	decl String:strCookie[8];
	
	GetClientCookie(client, g_hCookieDefaultsSet, strCookie, sizeof(strCookie));
	
	if(StringToInt(strCookie) == 0)
	{
		SetCookie(client, g_hCookieEnabled, false);
		SetCookie(client, g_hCookieEveryJump, false);
		SetCookie(client, g_hCookieCurrentSpeed, true);
		SetCookie(client, g_hCookieSpeedDiff, true);
		SetCookie(client, g_hCookieHeightDiff, true);
		SetCookie(client, g_hCookieGainStats, true);
		
		SetCookie(client, g_hCookieDefaultsSet, true);
	}
	
	GetClientCookie(client, g_hCookieEnabled, strCookie, sizeof(strCookie));
	g_bEnabled[client] = bool:StringToInt(strCookie);
	
	GetClientCookie(client, g_hCookieEveryJump, strCookie, sizeof(strCookie));
	g_bEveryJump[client] = bool:StringToInt(strCookie);
	
	GetClientCookie(client, g_hCookieCurrentSpeed, strCookie, sizeof(strCookie));
	g_bCurrentSpeed[client] = bool:StringToInt(strCookie);
	
	GetClientCookie(client, g_hCookieSpeedDiff, strCookie, sizeof(strCookie));
	g_bSpeedDiff[client] = bool:StringToInt(strCookie);
	
	GetClientCookie(client, g_hCookieHeightDiff, strCookie, sizeof(strCookie));
	g_bHeightDiff[client] = bool:StringToInt(strCookie);
	
	GetClientCookie(client, g_hCookieGainStats, strCookie, sizeof(strCookie));
	g_bGainStats[client] = bool:StringToInt(strCookie);
}

public OnClientPutInServer(client)
{
	g_iJump[client] = 0;
	g_strafeTick[client] = 0;
	g_flRawGain[client] = 0.0;
	g_iTicksOnGround[client] = 0;
	SDKHook(client, SDKHook_Touch, onTouch);
}

public Action:onTouch(client, entity) if(entity == 0) g_bTouchesWall[client] = true;

public OnPlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid"); 

	new client = GetClientOfUserId(userid); 
	
	if(IsFakeClient(client)) return;
	
	g_iJump[client]++;
	new Float:velocity[3];
	new Float:origin[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
	GetClientAbsOrigin(client, origin);
	velocity[2] = 0.0;
	for(new i=1; i<MaxClients;i++)
	{
		if(IsClientInGame(i) && ((!IsPlayerAlive(i) && GetEntPropEnt(i, Prop_Data, "m_hObserverTarget") == client && GetEntProp(i, Prop_Data, "m_iObserverMode") != 7 && g_bEnabled[i]) || ((i == client && g_bEnabled[i] && ((g_iJump[i] == 6 && !g_bEveryJump[i]) || g_bEveryJump[i])))))
			PrintSSJStats(i, client);
	}
	if((g_iJump[client] == 6 && !g_bEveryJump[client]) || g_bEveryJump[client])
	{
		g_flRawGain[client] = 0.0;
		g_strafeTick[client] = 0;
		g_flOldSpeed[client] = GetVectorLength(velocity);
		g_flOldHeight[client] = origin[2];
	}
	if(g_iJump[client] == 1 && !g_bEveryJump[client])
	{
		g_flInitialHeight[client] = origin[2];
		g_flInitialSpeed[client] = GetVectorLength(velocity);
	}
}

public Action:Command_SSJ(client, args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "[SM] This command can only be used in-game.");
		return Plugin_Handled;
	}
	ShowSSJMenu(client);
	return Plugin_Handled;
}

public ShowSSJMenu(client)
{
	new Handle:menu = CreateMenu(SSJ_Select);
	SetMenuTitle(menu, "SSJ Menu\n \n");
	
	if(g_bEnabled[client])
		AddMenuItem(menu, "usage", "Usage: [ON]");
	else AddMenuItem(menu, "usage", "Usage: [OFF]");
	
	if(g_bEveryJump[client])
		AddMenuItem(menu, "mode", "Usage mode: [Every]");
	else AddMenuItem(menu, "mode", "Usage mode: [6th]");
	
	if(g_bCurrentSpeed[client])
		AddMenuItem(menu, "curspeed", "Current speed: [ON]");
	else AddMenuItem(menu, "curspeed", "Current speed: [OFF]");
	
	if(g_bSpeedDiff[client])
		AddMenuItem(menu, "speed", "Speed difference: [ON]");
	else AddMenuItem(menu, "speed", "Speed difference: [OFF]");
	
	if(g_bHeightDiff[client])
		AddMenuItem(menu, "height", "Height difference: [ON]");
	else AddMenuItem(menu, "height", "Height difference: [OFF]");
	
	if(g_bGainStats[client])
		AddMenuItem(menu, "gain", "Gain percentage: [ON]");
	else AddMenuItem(menu, "gain", "Gain percentage: [OFF]");
	
	DisplayMenu(menu, client, 0);
}

public SSJ_Select(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu, option, info, sizeof(info));
		if(StrEqual(info, "usage"))
		{
			g_bEnabled[client] = !g_bEnabled[client];
			SetCookie(client, g_hCookieEnabled, g_bEnabled[client]);
		}
		if(StrEqual(info, "mode"))
		{
			g_bEveryJump[client] = !g_bEveryJump[client];
			SetCookie(client, g_hCookieEveryJump, g_bEveryJump[client]);
		}
		if(StrEqual(info, "curspeed"))
		{
			g_bCurrentSpeed[client] = !g_bCurrentSpeed[client];
			SetCookie(client, g_hCookieCurrentSpeed, g_bCurrentSpeed[client]);
		}
		if(StrEqual(info, "speed"))
		{
			g_bSpeedDiff[client] = !g_bSpeedDiff[client];
			SetCookie(client, g_hCookieSpeedDiff, g_bSpeedDiff[client]);
		}
		if(StrEqual(info, "height"))
		{
			g_bHeightDiff[client] = !g_bHeightDiff[client];
			SetCookie(client, g_hCookieHeightDiff, g_bHeightDiff[client]);
		}
		if(StrEqual(info, "gain"))
		{
			g_bGainStats[client] = !g_bGainStats[client];
			SetCookie(client, g_hCookieGainStats, g_bGainStats[client]);
		}
		ShowSSJMenu(client);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

public OnFormatsChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if(cvar == hMsgStart)
	{
		GetConVarString(hMsgStart, g_msg_start, sizeof(g_msg_start));
	}
	if(cvar == hMsgText)
	{
		GetConVarString(hMsgText, g_msg_text, sizeof(g_msg_text));
	}
	if(cvar == hMsgVar)
	{
		GetConVarString(hMsgVar, g_msg_var, sizeof(g_msg_var));
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsFakeClient(client)) return Plugin_Continue;
	
	if(GetEntityFlags(client) & FL_ONGROUND)
	{
		if(g_iTicksOnGround[client] > BHOP_TIME)
		{
			g_iJump[client] = 0;
			g_strafeTick[client] = 0;
			g_flRawGain[client] = 0.0;
		}
		g_iTicksOnGround[client]++;
	}
	else
	{
		if(GetEntityMoveType(client) != MOVETYPE_NONE && GetEntityMoveType(client) != MOVETYPE_NOCLIP && GetEntityMoveType(client) != MOVETYPE_LADDER && GetEntProp(client, Prop_Data, "m_nWaterLevel") < 2)
		{
			new Float:gaincoeff;
			g_strafeTick[client]++;
			if(g_strafeTick[client] == 1000)
			{
				g_flRawGain[client] *= 998.0/999.0;
				g_strafeTick[client]--;
			}
			
			if(GetConVarFloat(g_hAirAccel) > 0.0)
			{
			
				new Float:velocity[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
				
				new Float:fore[3], Float:side[3], Float:wishvel[3], Float:wishdir[3];
				new Float:wishspeed, Float:wishspd, Float:currentgain;
				
				GetAngleVectors(angles, fore, side, NULL_VECTOR);
				
				fore[2] = 0.0;
				side[2] = 0.0;
				NormalizeVector(fore, fore);
				NormalizeVector(side, side);
				
				for(new i = 0; i < 2; i++)
					wishvel[i] = fore[i] * vel[0] + side[i] * vel[1];
				
				wishspeed = NormalizeVector(wishvel, wishdir);
				if(wishspeed > GetEntPropFloat(client, Prop_Send, "m_flMaxspeed")) wishspeed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
				
				if(wishspeed)
				{
					wishspd = (wishspeed > 30.0) ? 30.0 : wishspeed;
					
					currentgain = GetVectorDotProduct(velocity, wishdir);
					if(currentgain < 30.0)
						gaincoeff = (wishspd - FloatAbs(currentgain)) / wishspd;
					if(g_bTouchesWall[client] && gaincoeff > 0.5)
					{
						gaincoeff -= 1;
						gaincoeff = FloatAbs(gaincoeff);
					}
					g_flRawGain[client] += gaincoeff;
				}
			}
		}
		g_iTicksOnGround[client] = 0;
	}
	g_bTouchesWall[client] = false;
	return Plugin_Continue;
}

PrintSSJStats(client, target)
{
	new Float:velocity[3];
	new Float:origin[3];
	GetEntPropVector(target, Prop_Data, "m_vecAbsVelocity", velocity);
	GetClientAbsOrigin(target, origin);
	velocity[2] = 0.0;
	new Float:coeffsum = g_flRawGain[target];
	coeffsum /= g_strafeTick[target];
	coeffsum *= 100.0;
	coeffsum = RoundToFloor(coeffsum * 100.0 + 0.5) / 100.0;
	decl String:SSJText[255];
	Format(SSJText, sizeof(SSJText), "%s%sJump: %s%i", g_msg_start, g_msg_text, g_msg_var, g_iJump[target]);
	if(!g_bEveryJump[client] && g_iJump[target] == 6)
	{
		if(g_bCurrentSpeed[client])
			Format(SSJText, sizeof(SSJText), "%s %s| Speed: %s%i", SSJText, g_msg_text, g_msg_var, RoundToFloor(GetVectorLength(velocity)));
		if(g_bSpeedDiff[client])
			Format(SSJText, sizeof(SSJText), "%s %s| Speed Δ: %s%i", SSJText, g_msg_text, g_msg_var, RoundToFloor(GetVectorLength(velocity)) - RoundToFloor(g_flInitialSpeed[target]));
		if(g_bHeightDiff[client])
			Format(SSJText, sizeof(SSJText), "%s %s| Height Δ: %s%i", SSJText, g_msg_text, g_msg_var, RoundToFloor(origin[2]) - RoundToFloor(g_flInitialHeight[target]));
		if(g_bGainStats[client])
			Format(SSJText, sizeof(SSJText), "%s %s| Gain: %s%.2f%%", SSJText, g_msg_text, g_msg_var, coeffsum);
		CPrintToChat(client, SSJText);
	}
	else if(g_bEveryJump[client])
	{
		if(g_bCurrentSpeed[client])
			Format(SSJText, sizeof(SSJText), "%s %s| Speed: %s%i", SSJText, g_msg_text, g_msg_var, RoundToFloor(GetVectorLength(velocity)));
		if(g_iJump[target] > 1)
		{
			if(g_bSpeedDiff[client])
				Format(SSJText, sizeof(SSJText), "%s %s| Speed Δ: %s%i", SSJText, g_msg_text, g_msg_var, RoundToFloor(GetVectorLength(velocity)) - RoundToFloor(g_flOldSpeed[target]));
			if(g_bHeightDiff[client])
				Format(SSJText, sizeof(SSJText), "%s %s| Height Δ: %s%i", SSJText, g_msg_text, g_msg_var, RoundToFloor(origin[2]) - RoundToFloor(g_flOldHeight[target]));
			if(g_bGainStats[client])
				Format(SSJText, sizeof(SSJText), "%s %s| Gain: %s%.2f%%", SSJText, g_msg_text, g_msg_var, coeffsum);
		}
		CPrintToChat(client, SSJText);
	}
}

SetCookie(client, Handle:hCookie, n)
{
	decl String:strCookie[64];
	
	IntToString(n, strCookie, sizeof(strCookie));

	SetClientCookie(client, hCookie, strCookie);
}