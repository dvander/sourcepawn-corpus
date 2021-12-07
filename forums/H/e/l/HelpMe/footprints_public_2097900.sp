#include <tf2attributes>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

new Float:FootprintID[MAXPLAYERS+1] = 0.0
new Handle:g_hCookieFoot;
new bool:b_random[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "[TF2] Halloween Footprints with clientprefs",
	author = "Oshizu + Dyl0n + Pelipoika + Benjamin",
	description = "Looks Fancy Ahhhh",
	version ="1.0",
	url = "www.otaku-gaming.net"
}

public OnPluginStart()
{
	RegAdminCmd("sm_footprints", FootSteps, ADMFLAG_RESERVATION)
	RegAdminCmd("sm_footsteps", FootSteps, ADMFLAG_RESERVATION)

	g_hCookieFoot = RegClientCookie("footprints", "", CookieAccess_Private);
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post)
	for(new i = 1; i <= MaxClients; i++)
	{
		b_random[i] = false;
	}
}

public OnClientDisconnect(client)
{
	if(FootprintID[client] > 0.0)
	{
		FootprintID[client] = 0.0
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(FootprintID[client] > 0.0)
	{
		TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", FootprintID[client]);
	}
}

public Action:FootSteps(client, args)
{
	new Handle:ws = CreateMenu(FootStepsCALLBACK);
	SetMenuTitle(ws, "Choose Your Footprints Effect");

	AddMenuItem(ws, "0", "No Effect");
	AddMenuItem(ws, "X", "----------", ITEMDRAW_DISABLED);
	AddMenuItem(ws, "1", "Team Based");
	AddMenuItem(ws, "7777", "Blue");
	AddMenuItem(ws, "933333", "Light Blue")
	AddMenuItem(ws, "8421376", "Yellow");
	AddMenuItem(ws, "4552221", "Corrupted Green");
	AddMenuItem(ws, "3100495", "Dark Green");
	AddMenuItem(ws, "51234123", "Lime");
	AddMenuItem(ws, "5322826", "Brown");
	AddMenuItem(ws, "8355220", "Oak Tree Brown");
	AddMenuItem(ws, "13595446", "Flames");
	AddMenuItem(ws, "8208497", "Cream");
	AddMenuItem(ws, "41234123", "Pink");
	AddMenuItem(ws, "300000", "Satan's Blue");
	AddMenuItem(ws, "2", "Purple");
	AddMenuItem(ws, "3", "4 8 15 16 23 42");
	AddMenuItem(ws, "83552", "Ghost In The Machine");
	AddMenuItem(ws, "9335510", "Holy Flame");
	AddMenuItem(ws, "1", "[Random]");

	DisplayMenu(ws, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public FootStepsCALLBACK(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) CloseHandle(menu);

	if(action == MenuAction_Select)
	{
		decl String:info[12];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new Float:weapon_glow = StringToFloat(info);
		FootprintID[client] = weapon_glow;
		if(weapon_glow == 0.0)
		{
			TF2Attrib_RemoveByName(client, "SPELL: set Halloween footstep type");
			SetClientCookie(client, g_hCookieFoot, info);
		}
		else
		{
			TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", weapon_glow);
			SetClientCookie(client, g_hCookieFoot, info);
		}
		if(param2 == 19)
		{
			b_random[client] = true;
		}
		else
		{
			b_random[client] = false;
		}
	}
}

public OnClientPutInServer(client)
{
	new iClient = client;
	CreateTimer(10.0, LoadCookies, iClient);
        //Ignore if it wasn't a valid client (rare).
        if(!IsClientInGame(client))
                return;
			
        SDKHook(client, SDKHook_PostThink, OnPostThink);
}

public OnPostThink(client)
{
	if(b_random[client])
	{
		switch(GetRandomInt(0,16))
		{
			case 0:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 1.0);
			case 1:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 7777.0);
			case 2:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 933333.0);
			case 3:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 8421376.0);
			case 4:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 4552221.0);
			case 5:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 3100495.0);
			case 6:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 51234123.0);
			case 7:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 5322826.0);
			case 8:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 8355220.0);
			case 9:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 13595446.0);
			case 10:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 8208497.0);
			case 11:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 41234123.0);
			case 12:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 300000.0);
			case 13:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 2.0);
			case 14:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 3.0);
			case 15:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 83552.0);
			case 16:
				TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 9335510.0);
		}
	}
}

public OnClientPostAdminCheck(iClient)
{
	if(IsValidClient(iClient) && AreClientCookiesCached(iClient))
		LoadClientCookies(iClient);
	else
		CreateTimer(1.0, Timer_LoadCookies, iClient, TIMER_REPEAT);
}

public Action:Timer_LoadCookies(Handle:hTimer, any:iClient)
{
	if(!IsValidClient(iClient) || !AreClientCookiesCached(iClient))
		return Plugin_Continue;

	LoadClientCookies(iClient);
	return Plugin_Stop;
}

public Action:LoadCookies(Handle:hTimer, any:iClient)
{
	LoadClientCookies(iClient);

	return Plugin_Stop;
}

stock LoadClientCookies(iClient)
{
	if(!IsUserDesignated(iClient))
		return;

	decl String:strCookie[32];
	GetClientCookie(iClient, g_hCookieFoot, strCookie, sizeof(strCookie));
	new Float:footprintValue = 0.0;
	footprintValue = StringToFloat(strCookie);
	FootprintID[iClient] = footprintValue;
}

stock bool:IsUserDesignated(iClient)
{
	if(!CheckCommandAccess(iClient, "sm_footprints", 0))
		return false;

	return true;
}

stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}