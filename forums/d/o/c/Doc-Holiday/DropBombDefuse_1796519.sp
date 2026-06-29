#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0.6"

//Cvars
new Handle:g_Cvar_RoundEndDelay = INVALID_HANDLE;
new Handle:g_Cvar_DefuseTime = INVALID_HANDLE;
new Handle:g_Cvar_RequireDefuser = INVALID_HANDLE;
new Handle:g_Cvar_DefuserMultiplier = INVALID_HANDLE;
new Handle:g_Cvar_IgnoreDefuseKit = INVALID_HANDLE;
new Handle:g_Cvar_FragBonus = INVALID_HANDLE;
new Handle:g_Cvar_DefuseDistance = INVALID_HANDLE;
new Handle:g_Cvar_ForceRoundEnd = INVALID_HANDLE;
new Handle:g_Cvar_AnnouceDefuser = INVALID_HANDLE;
new Handle:g_Cvar_DefuseMoney = INVALID_HANDLE;
new Handle:g_Cvar_AnnouncementMode = INVALID_HANDLE;
new Handle:g_Cvar_PluginAnnounce = INVALID_HANDLE;
new Handle:g_Cvar_Prefix = INVALID_HANDLE;

//Timers
new Handle:g_Timer_BombDefused = INVALID_HANDLE;
new Handle:g_Timer_CheckCanDefuse = INVALID_HANDLE;
new Handle:g_Timer_PluginAnnounce = INVALID_HANDLE;

//Variables
new String:g_szPrefixName[32];
new bool:g_bPressedUse[MAXPLAYERS];
new g_iDefuser = -1; //Index of the person who defused the bomb
new g_iC4Ent = -1; //Entity Index of the dropped c4
new bool:g_bHasBombSite;

//Offsets

public Plugin:myinfo = 
{
	name = "Droped Bomb Defuse",
	author = "SavSin",
	description = "CT's can defuse the bomb left on the ground by T's",
	version = PLUGIN_VERSION,
	url = "www.norcalbots.com"
}

public OnPluginStart()
{
	//Public Var
	CreateConVar("dbd_version", PLUGIN_VERSION, "Version of dropped bomb defuse", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//Multi-Langual Support
	LoadTranslations("dropbombdefuse.phrases");
	
	//Cvars
	g_Cvar_RoundEndDelay = CreateConVar("sm_dbd_rndenddelay", "5.0", "Time before new round begins. <Default: 3.0>");
	g_Cvar_DefuseTime = CreateConVar("sm_dbd_defusetime", "10.0", "Time it takes to defuse the bomb. <Default: 10.0>");
	g_Cvar_RequireDefuser = CreateConVar("sm_dbd_requiredefuser", "1", "Require a defuse kit to defuse the dropped bomb. <Default: 1>");
	g_Cvar_DefuserMultiplier = CreateConVar("sm_dbd_defusermultiplier", "0.5", "Multiplier for defuse time if user has defuse kit. <Default: 0.5>");
	g_Cvar_IgnoreDefuseKit = CreateConVar("sm_dbd_ignoredefusekit", "1", "Ignore defuse kit multiplier <Default: 1>");
	g_Cvar_FragBonus = CreateConVar("sm_dbd_fragbonus", "2", "Ammount of frgas to give a player for defusing the dropped bomb. Set 0 to disable. <Default: 2>");
	g_Cvar_DefuseDistance = CreateConVar("sm_dbd_defusedist", "45", "Units away from the dropped bomb to defuse <Default: 45>");
	g_Cvar_ForceRoundEnd = CreateConVar("sm_dbd_forceroundend", "1", "Force round end? <Default: 1>");
	g_Cvar_AnnouceDefuser = CreateConVar("sm_dbd_announcedefuser", "1", "Toggle announcement of person defusing the bomb <Default:1>");
	g_Cvar_DefuseMoney = CreateConVar("sm_dbd_defusemoney", "200", "Amount of money to give to person who defused the bomb <Default:200>");
	g_Cvar_AnnouncementMode = CreateConVar("sm_dbd_announcementmode", "2", "Type of announcement. 1 = Hint, 2 = Chat, 3 = Center <Default: 2>");
	g_Cvar_PluginAnnounce = CreateConVar("sm_dbd_pluginannounce", "3", "Time in minuets announce to the players that this plugin is active. 0 to disable. <Default: 3.0>");
	g_Cvar_Prefix = CreateConVar("sm_prefix", "SM", "Prefix for the front of the chat messages <Default: SM>");
	
	GetConVarString(g_Cvar_Prefix, g_szPrefixName, sizeof(g_szPrefixName));
	
	HookConVarChange(g_Cvar_PluginAnnounce, ConVar_PluginAnnounceChanged);
	HookConVarChange(g_Cvar_Prefix, ConVar_PrefixChanged);
	
	//Events
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart()
{
	if(GameRules_GetProp("m_bMapHasBombTarget"))
	{
		g_bHasBombSite = true;
	}
	
	if(GetConVarInt(g_Cvar_PluginAnnounce) && g_bHasBombSite)
	{
		new Float:flAnnounceTime = (GetConVarFloat(g_Cvar_PluginAnnounce) * 60);
		g_Timer_PluginAnnounce = CreateTimer(flAnnounceTime, PluginAnnouncement, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public ConVar_PluginAnnounceChanged(Handle:hConVar, const String:szOldValue[], const String:szNewValue[])
{
	if(hConVar == g_Cvar_PluginAnnounce && g_bHasBombSite)
	{
		new iNewValue;
		StringToInt(szNewValue, iNewValue);
		
		if(iNewValue)
		{
			if(g_Timer_PluginAnnounce == INVALID_HANDLE)
			{
				new Float:flAnnounceTime = (GetConVarFloat(g_Cvar_PluginAnnounce) * 60);
				g_Timer_PluginAnnounce = CreateTimer(flAnnounceTime, PluginAnnouncement, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else
		{
			if(g_Timer_PluginAnnounce != INVALID_HANDLE)
			{
				KillTimer(g_Timer_PluginAnnounce);
				g_Timer_PluginAnnounce = INVALID_HANDLE;
			}
		}
	}
}

public ConVar_PrefixChanged(Handle:hConVar, const String:szOldValue[], const String:szNewValue[])
{
	if(hConVar == g_Cvar_Prefix)
	{
		strcopy(g_szPrefixName, sizeof(g_szPrefixName), szNewValue);
	}
}

public Action:PluginAnnouncement(Handle:hTimer, any:iData)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			Announcement(i, "%t", "Plugin Announcement");
		}
	}
}

public Action:Event_RoundEnd(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	g_iDefuser = -1;
	DisableTimers();
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient == g_iDefuser)
	{
		DisableTimers();
		CreateBarTime(iClient, 0);
		g_bPressedUse[iClient] = false;
	}
}

public Action:CS_OnCSWeaponDrop(iClient, iWeaponIndex)
{
	decl String:szClassName[32];
	GetEdictClassname(iWeaponIndex, szClassName, sizeof(szClassName));
	
	if(StrEqual(szClassName, "weapon_c4", false))
	{
		g_iC4Ent = iWeaponIndex;
	}
}

public Action:OnPlayerRunCmd(iClient, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) == CS_TEAM_CT)
	{
		if(!g_bPressedUse[iClient] && (buttons & IN_USE))
		{
			g_bPressedUse[iClient] = true;
			
			if(g_iDefuser == -1)
			{
				if(IsTargetInSightRange(iClient, g_iC4Ent))
				{
					new String:szPlayerName[32];
					GetClientName(iClient, szPlayerName, sizeof(szPlayerName));
					g_iDefuser = iClient;
					
					new iDefuseKit = GetEntProp(iClient, Prop_Send, "m_bHasDefuser");
					new Float:flDefuseTime = GetConVarFloat(g_Cvar_DefuseTime);
						
					if(GetConVarInt(g_Cvar_RequireDefuser) && iDefuseKit)
					{
						if(GetConVarInt(g_Cvar_IgnoreDefuseKit))
						{
							if(GetConVarInt(g_Cvar_AnnouceDefuser))
							{
								AnnouncementToAll("%s %t", szPlayerName, "Defuse Announcement");
							}								
							g_Timer_BombDefused = CreateTimer(flDefuseTime, BombDefused, iClient);
							g_Timer_CheckCanDefuse = CreateTimer(0.1, CheckCanDefuse, iClient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							CreateBarTime(iClient, GetConVarInt(g_Cvar_DefuseTime));
						}
						else
						{
							if(GetConVarInt(g_Cvar_AnnouceDefuser))
							{
								AnnouncementToAll("%s %t", szPlayerName, "Defuse Announcement");
							}									
							g_Timer_BombDefused = CreateTimer((flDefuseTime*GetConVarFloat(g_Cvar_DefuserMultiplier)), BombDefused, iClient);
							g_Timer_CheckCanDefuse = CreateTimer(0.1, CheckCanDefuse, iClient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							CreateBarTime(iClient, RoundToNearest(GetConVarInt(g_Cvar_DefuseTime)*GetConVarFloat(g_Cvar_DefuserMultiplier)));
						}
					}
					else if(GetConVarInt(g_Cvar_RequireDefuser) && !iDefuseKit)
					{
						Announcement(iClient, "%t", "Defusekit Required");
					}
					else if(!GetConVarInt(g_Cvar_RequireDefuser))
					{
						if(!iDefuseKit || GetConVarInt(g_Cvar_IgnoreDefuseKit))
						{
							if(GetConVarInt(g_Cvar_AnnouceDefuser))
							{
								AnnouncementToAll("%s %t", szPlayerName, "Defuse Announcement");
							}
							g_Timer_BombDefused = CreateTimer(flDefuseTime, BombDefused, iClient);
							g_Timer_CheckCanDefuse = CreateTimer(0.1, CheckCanDefuse, iClient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							CreateBarTime(iClient, GetConVarInt(g_Cvar_DefuseTime));
						}
						else if(iDefuseKit && !GetConVarInt(g_Cvar_IgnoreDefuseKit))
						{
							if(GetConVarInt(g_Cvar_AnnouceDefuser))
							{
								AnnouncementToAll("%s %t", szPlayerName, "Defuse Announcement");
							}
							g_Timer_BombDefused = CreateTimer((flDefuseTime*GetConVarFloat(g_Cvar_DefuserMultiplier)), BombDefused, iClient);
							g_Timer_CheckCanDefuse = CreateTimer(0.1, CheckCanDefuse, iClient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							CreateBarTime(iClient, RoundToNearest(GetConVarInt(g_Cvar_DefuseTime)*GetConVarFloat(g_Cvar_DefuserMultiplier)));
						}
					}
				}
			}
			else
			{
				decl String:szPlayerName[32];
				GetClientName(g_iDefuser, szPlayerName, sizeof(szPlayerName));
				Announcement(iClient, "%s %t", szPlayerName, "Already Defusing");
			}
		}
	}
		
	if(g_bPressedUse[iClient] && !(buttons & IN_USE))
	{
		if(g_Timer_BombDefused != INVALID_HANDLE)
		{
			DisableTimers();
			CreateBarTime(iClient, 0);
		}
		
		g_bPressedUse[iClient] = false;
	}
}

public Action:BombDefused(Handle:hTimer, any:iClient)
{
	RemoveEdict(g_iC4Ent);
	SetEntProp(iClient, Prop_Data, "m_iFrags", (GetClientFrags(g_iDefuser) + GetConVarInt(g_Cvar_FragBonus)));
	g_Timer_BombDefused = INVALID_HANDLE;
	SetEntProp(iClient, Prop_Send, "m_bIsDefusing", 0);
	
	new iMoney = (GetEntProp(iClient, Prop_Send, "m_iAccount")+GetConVarInt(g_Cvar_DefuseMoney));
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && GetClientTeam(iClient) == CS_TEAM_CT)
		{
			SetEntProp(i, Prop_Send, "m_iAccount", iMoney);
		}
	}
	
	new String:szPlayerName[32];
	GetClientName(iClient, szPlayerName, sizeof(szPlayerName));
	AnnouncementToAll("%s %t", szPlayerName, "Bomb Defused");
	
	if(GetConVarInt(g_Cvar_ForceRoundEnd))
	{
		new iTeamScore = (CS_GetTeamScore(CS_TEAM_CT) + 1);
		CS_SetTeamScore(CS_TEAM_CT, iTeamScore);
		SetTeamScore(CS_TEAM_CT, iTeamScore);
		CS_TerminateRound(GetConVarFloat(g_Cvar_RoundEndDelay), CSRoundEnd_BombDefused, false);
	}
	else
	{
		EmitSoundToAll("radio/bombdef.wav", _, _, SNDLEVEL_HOME, _, SNDVOL_NORMAL, _, _, _, _, _, _);
	}
}

public Action:CheckCanDefuse(Handle:hTimer, any:iClient)
{
	if(IsClientInGame(iClient))
	{
		if(!IsTargetInSightRange(iClient, g_iC4Ent))
		{
			DisableTimers();
			CreateBarTime(iClient, 0);
			g_bPressedUse[iClient] = false;
		}
	}
}

public DisableTimers()
{
	g_iDefuser = -1;
	
	if(g_Timer_BombDefused != INVALID_HANDLE)
	{
		KillTimer(g_Timer_BombDefused);
		g_Timer_BombDefused = INVALID_HANDLE;
	}
	
	if(g_Timer_CheckCanDefuse != INVALID_HANDLE)
	{
		KillTimer(g_Timer_CheckCanDefuse);
		g_Timer_CheckCanDefuse = INVALID_HANDLE;
	}
}

public CreateBarTime(iClient, iDuration)
{
	if(IsClientInGame(iClient))
	{
		if(iDuration)
		{
			g_iDefuser = iClient;
			SetEntProp(iClient, Prop_Send, "m_bIsDefusing", 1);
			SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		}
		else
		{
			g_iDefuser = -1;
			SetEntProp(iClient, Prop_Send, "m_bIsDefusing", 0);
		}
		SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", iDuration);
	}
}

stock AnnouncementToAll(const String:szAnnouncement[], any:...)
{
	decl String:szAnnouncementBuffer[192];
	switch(GetConVarInt(g_Cvar_AnnouncementMode))
	{
		case 1:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(!IsClientInGame(i))
					continue;
					
				VFormat(szAnnouncementBuffer, sizeof(szAnnouncementBuffer), szAnnouncement, 2);
				PrintHintText(i, szAnnouncementBuffer);
			}
		}
		case 2:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(!IsClientInGame(i))
					continue;
					
				VFormat(szAnnouncementBuffer, sizeof(szAnnouncementBuffer), szAnnouncement, 2);
				PrintToChat(i, "%s %s", g_szPrefixName, szAnnouncementBuffer);
			}
		}
		case 3:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(!IsClientInGame(i))
					continue;
					
				VFormat(szAnnouncementBuffer, sizeof(szAnnouncementBuffer), szAnnouncement, 2);
				PrintCenterText(i, szAnnouncementBuffer);
			}
		}
	}
}

stock Announcement(iClient, const String:szAnnouncement[], any:...)
{
	decl String:szAnnouncementBuffer[192];
	switch(GetConVarInt(g_Cvar_AnnouncementMode))
	{
		case 1:
		{
			VFormat(szAnnouncementBuffer, sizeof(szAnnouncementBuffer), szAnnouncement, 3);
			PrintHintText(iClient, szAnnouncementBuffer);
		}
		case 2:
		{
			VFormat(szAnnouncementBuffer, sizeof(szAnnouncementBuffer), szAnnouncement, 3);
			PrintToChat(iClient, "%s %s", g_szPrefixName, szAnnouncementBuffer);
		}
		case 3:
		{
			VFormat(szAnnouncementBuffer, sizeof(szAnnouncementBuffer), szAnnouncement, 3);
			PrintCenterText(iClient, szAnnouncementBuffer);
		}
	}
}

stock bool:IsTargetInSightRange(client, target, Float:angle=90.0, Float:distance=0.0, bool:heightcheck=true, bool:negativeangle=false)
{
	if(angle > 360.0 || angle < 0.0)
		return false;
		
	if(!IsClientConnected(client) && !(client))
		return false;
		
	if(!IsValidEdict(target))
		return false;
		
	decl Float:clientpos[3], Float:targetpos[3], Float:anglevector[3], Float:targetvector[3], Float:resultangle, Float:resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if(negativeangle)
		NegateVector(anglevector);

	GetClientAbsOrigin(client, clientpos);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetpos);
	if(heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	/* Check if player is close enough to target bomb */
	new Float:flDistance;
	flDistance = GetVectorDistance(clientpos, targetpos, false);
	
	if(flDistance > GetConVarFloat(g_Cvar_DefuseDistance))
		return false;
	
	if(resultangle <= angle/2)	
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
			if(distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}