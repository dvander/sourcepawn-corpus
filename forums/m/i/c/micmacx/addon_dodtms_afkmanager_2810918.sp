//////////////////////////////////////////////
//
// SourceMod Script
//
// [DoD TMS] Addon - AFK Manager
//
// Developed by FeuerSturm
//
//////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <dodtms_base>

public Plugin:myinfo = 
{
	name = "[DoD TMS] Addon - AFK Manager",
	author = "FeuerSturm, modif Micmacx",
	description = "AFK Manager for [DoD TMS]",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

new Handle:AFKON = INVALID_HANDLE
new Handle:AFKKickTime = INVALID_HANDLE
new Handle:AFKCount = INVALID_HANDLE
new Handle:AFKKickMinPl = INVALID_HANDLE
new Handle:AFKSpawnDist = INVALID_HANDLE
new Handle:ClientImmunity = INVALID_HANDLE
new Handle:AFKIncludeAdmins = INVALID_HANDLE
new Handle:DoDTMSSpecLock = INVALID_HANDLE
new Handle:ScreenFade = INVALID_HANDLE
new Handle:JoinTeamMenu = INVALID_HANDLE
new Handle:AFKCheckMenu = INVALID_HANDLE
new Handle:AFKTimer[MAXPLAYERS+1]
new g_Checking[MAXPLAYERS+1], g_AFKCount[MAXPLAYERS+1], g_AFK[MAXPLAYERS+1], g_AFKKickCount[MAXPLAYERS+1], g_SentSpecByPlug[MAXPLAYERS+1]
new String:WLFeature[] = { "afkmanager" }
new bool:IsWhiteListed[MAXPLAYERS+1]
new bool:IsBlackListed[MAXPLAYERS+1]
new bool:g_Warned[MAXPLAYERS+1]

public OnPluginStart()
{
	AFKON = CreateConVar("dod_tms_afkmanager", "1", "<1/0> = enable/disable AFK Manager",_, true, 0.0, true, 1.0)
	AFKCount = CreateConVar("dod_tms_afktime", "60", "<#> = Time in seconds after that a client is considered AFK",_, true, 30.0, true, 120.0)
	AFKKickTime = CreateConVar("dod_tms_afkkicktime", "120", "<#> = Time in seconds after that an AFK client is kicked",_, true, 30.0, true, 300.0)
	AFKKickMinPl = CreateConVar("dod_tms_afkkickminpl", "5", "<#> = minimum number of active players on the server to start kicking  -  0 = never kick!",_, true, 0.0)
	AFKSpawnDist = CreateConVar("dod_tms_afkspawnradius", "600", "<#> = radius around players spawn position that counts as spawn area",_, true, 0.0, true, 1000.0)
	ClientImmunity = CreateConVar("dod_tms_afkimmunity", "1", "<1/0> = enable/disable Admins being immune from almost all actions",_, true, 0.0, true, 1.0)
	AFKIncludeAdmins = CreateConVar("dod_tms_afkincludeadmins", "1", "<1/0> = enable/disable Admins being moved to spec when AFK",_, true, 0.0, true, 1.0)
	HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)
	HookEventEx("player_team", OnChangeTeam, EventHookMode_Post)
	AutoExecConfig(true,"addon_dodtms_afkmanager", "dod_teammanager_source")
	LoadTranslations("dodtms_afkmanager.txt")
}

public OnAllPluginsLoaded()
{
	CreateTimer(0.2, DoDTMSRunning)
}

public Action:DoDTMSRunning(Handle:timer)
{
	if(!LibraryExists("DoDTeamManagerSource"))
	{
		SetFailState("[DoD TMS] Base Plugin not found!")
		return Plugin_Handled
	}
	DoDTMSSpecLock = FindConVar("dod_tms_speclock")
	TMSRegAddon("B")
	return Plugin_Handled
}

public OnDoDTMSDeleteCfg()
{
	decl String:configfile[256]
	Format(configfile, sizeof(configfile), "cfg/dod_teammanager_source/addon_dodtms_afkmanager.cfg")
	if(FileExists(configfile))
	{
		DeleteFile(configfile)
	}
}

public OnClientDisconnect(client)
{	
	ResetAFKTimers(client)
	g_Warned[client] = false
	g_AFK[client] = 0
	g_AFKCount[client] = 0
	g_AFKKickCount[client] = 0
	g_Checking[client] = 0
	g_SentSpecByPlug[client] = 0
	if(GetClientMenu(client))
	{
		CancelClientMenu(client)
	}
}

public OnClientPutInServer(client)
{	
	ResetAFKTimers(client)
	g_Warned[client] = false
	g_AFK[client] = 0
	g_AFKCount[client] = 0
	g_AFKKickCount[client] = 0
	g_Checking[client] = 0
	g_SentSpecByPlug[client] = 0
}

public Action:OnChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if(client < 1)
	{
		return Plugin_Continue
	}
	if(IsClientInGame(client) && GetConVarInt(AFKON) == 1 && !IsClientImmune(client))
	{
		if(g_SentSpecByPlug[client] == 1)
		{
			g_SentSpecByPlug[client] = 0
			return Plugin_Continue
		}
		ResetAFKTimers(client)
		g_Warned[client] = false
		g_Checking[client] = 0
		g_AFKCount[client] = 0
		g_AFKKickCount[client] = 0
		g_AFK[client] = 0
	}
	return Plugin_Continue
}

public OnClientPostAdminCheck(client)
{
	if(TMSIsWhiteListed(client, WLFeature))
	{
		IsWhiteListed[client] = true
	}
	else
	{
		IsWhiteListed[client] = false
	}
	if(TMSIsBlackListed(client, WLFeature))
	{
		IsBlackListed[client] = true
	}
	else
	{
		IsBlackListed[client] = false
	}
	if(IsClientInGame(client) && GetConVarInt(AFKON) == 1 && !IsClientImmune(client))
	{
		if(GetClientTeam(client) == UNASSIGNED && !IsFakeClient(client))
		{
			ResetAFKTimers(client)
			AFKTimer[client] = CreateTimer(float(GetConVarInt(AFKKickTime)), KickUnassigned, client, TIMER_FLAG_NO_MAPCHANGE)
		}
	}
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if(GetConVarInt(AFKON) == 1 && (!IsClientImmune(client) || GetConVarInt(AFKIncludeAdmins) == 1))
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1)
		{
			ResetAFKTimers(client)
			g_Warned[client] = false
			g_Checking[client] = 1
			g_AFKCount[client] = 0
			g_AFKKickCount[client] = 0
			g_AFK[client] = 0
			g_SentSpecByPlug[client] = 0
			AFKTimer[client] = CreateTimer(0.0, CheckAFK, client, TIMER_FLAG_NO_MAPCHANGE)
			return Plugin_Continue
		}
	}
	return Plugin_Continue
}

public OnDoDTMSRoundActive()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(AFKTimer[i] != INVALID_HANDLE)
			{
				if(CloseHandle(AFKTimer[i]))
				{
					AFKTimer[i] = INVALID_HANDLE
					g_AFKCount[i] = 0
					g_AFK[i] = 0
					g_AFKKickCount[i] = 0
					g_Warned[i] = false
					AFKTimer[i] = CreateTimer(0.0, CheckAFK, i, TIMER_FLAG_NO_MAPCHANGE)
				}
			}
		}
	}
}

public Action:ResetAFKTimers(client)
{
	if(IsClientInGame(client))
	{
		if(AFKTimer[client] != INVALID_HANDLE)
		{
			if(CloseHandle(AFKTimer[client]))
			{
				AFKTimer[client] = INVALID_HANDLE
				g_AFKCount[client] = 0
				g_AFK[client] = 0
				g_AFKKickCount[client] = 0
				g_Warned[client] = false
			}
		}
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:ReJoinTeamMenu(client)
{
	if(client > 0 && IsClientInGame(client))
	{
		JoinTeamMenu = CreateMenu(JoinTeamMenuAction)
		decl String:menutitle[256]
		Format(menutitle, sizeof(menutitle), "%T", "PlayerJoinTeamTitle", client)
		SetMenuTitle(JoinTeamMenu, menutitle)
		AddMenuItem(JoinTeamMenu, "Allies", "U.S. Army")
		AddMenuItem(JoinTeamMenu, "Axis", "Wehrmacht")
		if(GetConVarInt(DoDTMSSpecLock) != 1 || IsClientImmune(client))
		{
			AddMenuItem(JoinTeamMenu, "Spec", "Spectators")
		}
		SetMenuExitButton(JoinTeamMenu, false)
		DisplayMenu(JoinTeamMenu, client, MENU_TIME_FOREVER)
	}
	return Plugin_Handled
}

public JoinTeamMenuAction(Handle:menu, MenuAction:action, client, itemNum)
{
	if(client > 0 && IsClientInGame(client) && g_AFK[client] != 0)
	{
		if(action == MenuAction_Select)
		{
			decl String:Button[7]
			GetMenuItem(JoinTeamMenu, itemNum, Button, sizeof(Button))
			if (strcmp(Button,"Allies") == 0)
			{
				FakeClientCommandEx(client, "jointeam %i", ALLIES)
			}
			else if (strcmp(Button,"Axis") == 0)
			{
				FakeClientCommandEx(client, "jointeam %i", AXIS)
			}
			else if (strcmp(Button,"Spec") == 0)
			{
				ResetAFKTimers(client)
			}
		}
	}
}

public Action:CheckAFK(Handle:timer, any:client)
{
	AFKTimer[client] = INVALID_HANDLE
	if(GetConVarInt(AFKON) == 0)
	{
		return Plugin_Handled
	}
	if(g_Checking[client] == 1)
	{
		if(g_AFKCount[client]*5 >= GetConVarInt(AFKCount))
		{
			if(g_AFK[client] == 0)
			{
				g_Warned[client] = false
				g_AFK[client] = 1
				g_SentSpecByPlug[client] = 1
				TMSChangeToTeam(client, SPEC)
				decl String:message[256]
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						Format(message, sizeof(message), "%T", "Player AFKtoSpec", i, client)
						TMSMessage(i, message)
					}
				}
				AFKTimer[client] = CreateTimer(0.0, CheckAFK, client)
				ReJoinTeamMenu(client)
				return Plugin_Handled
			}
			else if(g_AFK[client] == 1)
			{
				decl String:hintmessage[256]
				new MaxKickCount = GetConVarInt(AFKKickTime)
				if((g_AFKKickCount[client]*10) >= MaxKickCount && GetConVarInt(AFKKickMinPl) != 0)
				{
					if((GetTeamClientCount(ALLIES) + GetTeamClientCount(AXIS)) >= GetConVarInt(AFKKickMinPl))
					{
						g_AFK[client] = 2
						Format(hintmessage, sizeof(hintmessage), "%T", "Player AFKKickNOW", client)
						TMSHintMessage(client,hintmessage)
						if(GetConVarInt(DoDTMSSpecLock) == 1)
						{
							BlindAFKPlayer(client)
						}
						AFKTimer[client] = CreateTimer(5.0, KickAFKClient, client, TIMER_FLAG_NO_MAPCHANGE)
						return Plugin_Handled
					}
				}
				g_AFKKickCount[client]++
				if(IsClientImmune(client))
				{
					g_AFKKickCount[client] = 0
				}
				if(((GetTeamClientCount(ALLIES) + GetTeamClientCount(AXIS)) < GetConVarInt(AFKKickMinPl)) || GetConVarInt(AFKKickMinPl) == 0 || IsClientImmune(client))
				{
					Format(hintmessage, sizeof(hintmessage), "%T", "Player AFKComeBack", client)
				}
				else
				{
					Format(hintmessage, sizeof(hintmessage), "%T", "Player AFKKickTimer", client, ((MaxKickCount+10-(g_AFKKickCount[client]*10))))
				}
				TMSHintMessage(client,hintmessage)
				if(GetConVarInt(DoDTMSSpecLock) == 1 && !IsClientImmune(client))
				{
					BlindAFKPlayer(client)
				}
				AFKTimer[client] = CreateTimer(10.0, CheckAFK, client, TIMER_FLAG_NO_MAPCHANGE)
				return Plugin_Handled
			}
			return Plugin_Handled
		}
		else if(g_AFKCount[client]*5 < GetConVarInt(AFKCount))
		{
			new SpawnRadius = GetConVarInt(AFKSpawnDist)
			if(TMSGetClientSpawnArea(client, SpawnRadius))
			{
				g_AFKCount[client]++
				g_AFK[client] = 0
				g_AFKKickCount[client] = 0
				AFKTimer[client] = CreateTimer(5.0, CheckAFK, client, TIMER_FLAG_NO_MAPCHANGE)
				if((g_AFKCount[client]*5)+15 >= GetConVarInt(AFKCount) && !g_Warned[client])
				{
					g_Warned[client] = true
					PlayerAFKCheckMenu(client)
				}
				return Plugin_Handled
			}
			else
			{
				g_Checking[client] = 0
				g_AFK[client] = 0
				g_AFKCount[client] = 0
				g_AFKKickCount[client] = 0
				return Plugin_Handled
			}
		}
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:PlayerAFKCheckMenu(client)
{
	if(client > 0 && IsClientInGame(client))
	{
		AFKCheckMenu = CreateMenu(PlayerAFKCheckMenuAction)
		decl String:menutitle[256], String:menuanswer[256]
		Format(menutitle, sizeof(menutitle), "%T", "PlayerAFKCheckTitle", client)
		Format(menuanswer, sizeof(menuanswer), "%T", "NotAFKChoice", client)
		SetMenuTitle(AFKCheckMenu, menutitle)
		AddMenuItem(AFKCheckMenu, "notafk", menuanswer)
		SetMenuExitButton(AFKCheckMenu, false)
		DisplayMenu(AFKCheckMenu, client, 10)
	}
	return Plugin_Handled
}

public PlayerAFKCheckMenuAction(Handle:menu, MenuAction:action, client, itemNum)
{
	if(client > 0 && IsClientInGame(client))
	{
		if(action == MenuAction_Select)
		{
			g_AFKCount[client] = 0
			g_Warned[client] = false
		}
	}
}

public Action:BlindAFKPlayer(client)
{
	ScreenFade = StartMessageOne("Fade", client)
	BfWriteShort(ScreenFade, 500)
	BfWriteShort(ScreenFade, 7000)
	BfWriteShort(ScreenFade, 0x0002)
	BfWriteByte(ScreenFade, 32)
	BfWriteByte(ScreenFade, 32)
	BfWriteByte(ScreenFade, 32)	
	BfWriteByte(ScreenFade, 255)
	EndMessage()
	return Plugin_Handled
}

public Action:KickAFKClient(Handle:timer, any:client)
{
	AFKTimer[client] = INVALID_HANDLE
	if(GetConVarInt(AFKON) == 0)
	{
		return Plugin_Handled
	}
	if(g_AFK[client] == 2 && IsClientInGame(client))
	{
		decl String:message[256]
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				Format(message,sizeof(message),"%T", "Player KickedAFK", i, client)
				TMSMessage(i, message)
			}
		}
		decl String:kickmessage[256]
		Format(kickmessage,sizeof(kickmessage),"%T", "Player AFKKickReason", client)
		TMSKick(client, kickmessage)
		g_AFK[client] = 0
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:KickUnassigned(Handle:timer, any:client)
{
	AFKTimer[client] = INVALID_HANDLE
	if(GetConVarInt(AFKON) == 0)
	{
		return Plugin_Handled
	}
	if(IsClientInGame(client) && GetClientTeam(client) == UNASSIGNED)
	{
		decl String:message[256]
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				Format(message,sizeof(message),"%T", "Player KickedIdle", i, client)
				TMSMessage(i, message)
			}
		}
		decl String:kickmessage[256]
		Format(kickmessage,sizeof(kickmessage),"%T", "Player IdleKickReason", client)
		TMSKick(client, kickmessage)
		return Plugin_Handled
	}
	return Plugin_Handled
}

stock bool:IsClientImmune(client)
{
	if((GetUserAdmin(client) != INVALID_ADMIN_ID || IsWhiteListed[client]) && !IsBlackListed[client] && GetConVarInt(ClientImmunity) == 1)
	{
		return true
	}
	else
	{
		return false
	}
}