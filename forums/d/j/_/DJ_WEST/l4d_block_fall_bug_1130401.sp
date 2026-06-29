#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#define DMG_CLUB (1 << 7)
#define TEAM_SURVIVOR 2

public Plugin:myinfo = 
{
	name = "Block Fall Bug",
	author = "DJ_WEST",
	description = "Block the survivor bug with falling on the infected zombies",
	version = PLUGIN_VERSION,
	url = "http://amx-x.ru"
}

new g_Warnings[MAXPLAYERS+1], Handle:g_ResetTimer[MAXPLAYERS+1], Handle:h_CvarWarnings, Handle:h_CvarTime

public OnPluginStart()
{
	decl String:s_Game[12], Handle:h_Version
	
	GetGameFolderName(s_Game, sizeof(s_Game))
	if (!StrEqual(s_Game, "left4dead") && !StrEqual(s_Game, "left4dead2"))
		SetFailState("Block Fall Bug supports Left 4 Dead and Left 4 Dead 2 only!")
	
	LoadTranslations("block_fall_bug.phrases")
		
	HookEvent("infected_hurt", EventInfectedHurt)
	
	h_Version = CreateConVar("block_fallbug_version", PLUGIN_VERSION, "Block Fall Bug version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	h_CvarWarnings = CreateConVar("l4d_fall_bug_warnings", "3", "Quantity of the player warnings for bug detection", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 10.0)
	h_CvarTime = CreateConVar("l4d_fall_bug_time", "2.0", "Time for checks warnings of the player", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 10.0)
	
	SetConVarString(h_Version, PLUGIN_VERSION)
}

public Action:EventInfectedHurt(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	if (!(GetEventInt(h_Event, "type") & DMG_CLUB))
		return Plugin_Handled
		
	decl i_UserID, i_Client, i_Ent
		
	i_UserID = GetEventInt(h_Event, "attacker")
	i_Client = GetClientOfUserId(i_UserID)
		
	if (i_Client && IsClientInGame(i_Client) && GetClientTeam(i_Client) == TEAM_SURVIVOR)
	{
		i_Ent = GetEventInt(h_Event, "entityid")
		
		if (GetEntPropEnt(i_Client, Prop_Data, "m_hGroundEntity") == i_Ent)
		{
			g_Warnings[i_Client]++
			
			if (g_ResetTimer[i_Client] == INVALID_HANDLE)
				g_ResetTimer[i_Client] = CreateTimer(GetConVarFloat(h_CvarTime), ResetWarnings, i_Client)
			
			if (g_Warnings[i_Client] > GetConVarInt(h_CvarWarnings))
			{
				decl String:s_PlayerName[MAX_NAME_LENGTH]
				
				GetClientName(i_Client, s_PlayerName, sizeof(s_PlayerName))
				PrintToChatAll("\x03[%t]\x01 %t.", "Information", "Detected", s_PlayerName)
				ForcePlayerSuicide(i_Client)
				
				g_Warnings[i_Client] = 0
				
				if (g_ResetTimer[i_Client] != INVALID_HANDLE)
				{
					KillTimer(g_ResetTimer[i_Client])
					g_ResetTimer[i_Client] = INVALID_HANDLE
				}	
			}
		}
	}
	
	return Plugin_Handled
}

public Action:ResetWarnings(Handle:h_Timer, any:i_Client)
{
	g_Warnings[i_Client] = 0
	g_ResetTimer[i_Client] = INVALID_HANDLE
}

public OnClientPutInServer(i_Client)
{
	if (IsFakeClient(i_Client))
		return
		
	if (g_ResetTimer[i_Client] != INVALID_HANDLE)
	{
		KillTimer(g_ResetTimer[i_Client])
		g_ResetTimer[i_Client] = INVALID_HANDLE
	}	
		
	g_Warnings[i_Client] = 0
}