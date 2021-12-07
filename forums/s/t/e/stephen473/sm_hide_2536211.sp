#include <sourcemod> 
#include <sdktools> 
#include <sdkhooks> 

#define newdecls required

#define PLUGIN_VERSION "1.4" 

bool g_bHide[MAXPLAYERS+1] =  { false, ... };

ConVar g_cOnlyForAdmins;
ConVar g_cEnabled;
ConVar g_cOnlyTeammates;
ConVar g_cDisableSounds;

public Plugin myinfo = 
{
	name = "Hide Other Players",
	author = "stephen473(Hardy`)",
	description = "Players/admins can hide other players",
	version = PLUGIN_VERSION,
	url = "http://pluginsatis.com"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_hide", Command_Hide); 
	RegConsoleCmd("sm_hideplayers", Command_Hide);
	
	g_cEnabled = CreateConVar("sm_hideplayers_enable", "1", "Enable/Disable Plugin | 1 = Enable | 0 = Disable");
	g_cOnlyForAdmins = CreateConVar("sm_hideplayers_only_admin", "0", "Only admins can use sm_hide command? | 1 = Only Admins | 0 = All Players");
	g_cOnlyTeammates = CreateConVar("sm_hideplayers_only_teammates", "1", "Hide only teammates of client? | 1 = Yes | 0 = No");
	g_cDisableSounds = CreateConVar("sm_hideplayers_mutesounds", "1", "Mute other players weapons sound from client when hide activated? | 1 = Yes | 0 = No");
	
	HookConVarChange(g_cDisableSounds, OnConVarChanged);
	AutoExecConfig(true, "sm_hide");
	
	CheckBool();
}

public void OnConVarChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	CheckBool();	
}

public void CheckBool()
{
	if (g_cEnabled.BoolValue) { 
		if (g_cDisableSounds.BoolValue) {
			AddTempEntHook("Shotgun Shot", CSS_Hook_ShotgunShot);
			AddNormalSoundHook(OnNormalSoundPlayed);		
		}

		else {
			RemoveTempEntHook("Shotgun Shot", CSS_Hook_ShotgunShot);
			RemoveNormalSoundHook(OnNormalSoundPlayed);
		}
	}
}

public void OnClientPutInServer(int client)
{		
	if (g_cEnabled.BoolValue)
		SDKHook(client, SDKHook_SetTransmit, SetTransmit);
}

public Action SetTransmit(int entity, int client) 
{ 
    if (IsClientInGame(client))
    {
    	if (g_bHide[client] == true)
    	{
			if (client != entity && 0 < entity <= MaxClients)
			{
				if(!g_cOnlyTeammates.BoolValue)
				{		
					return Plugin_Handled;
				}
				
				else
				{
					if (GetClientTeam(client) == GetClientTeam(entity))
					{
						return Plugin_Handled;
					}
				}
			}
		}			
	}		
        
    return Plugin_Continue; 
}  

public Action Command_Hide(int client, int args) 
{
	if (IsClientInGame(client)) { 
		if (g_cEnabled.BoolValue) { 
			if (g_cOnlyForAdmins.BoolValue) { 
				AdminId bAdmin = GetUserAdmin(client);
				
				if (bAdmin != INVALID_ADMIN_ID) { 
					g_bHide[client] = !g_bHide[client];		
					PrintToChat(client, "[Pluginsatis.com] %s", g_bHide[client] ? "You're hided the players.":"You will see other players after this!");		
				}
				
				else { 
					PrintToChat(client, "[Pluginsatis.com] You must be admin to use this command.");
				}
			}				
				
			else { 
				g_bHide[client] = !g_bHide[client];		
				PrintToChat(client, "[Pluginsatis.com] %s", g_bHide[client] ? "You're hided other players.":"You will see other players after this!");			
			}			
		}	

		else { 
			PrintToChat(client, "[Pluginsatis.com] Plugin disabled.");
		}
	}
	
	else { 
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
} 

public Action OnNormalSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if ( 
	StrContains(sample, "weapons") != -1 
	|| StrContains(sample, "weapons") != -1 
	|| StrContains(sample, "player/kevlar") != -1 
	|| StrContains(sample, "physics/flesh") != -1 
	|| StrContains(sample, "player/headshot") != -1) {
		numClients = 0;

		for (int i = 1; i <= MaxClients; i++) { 
			if (IsClientInGame(i) && !IsFakeClient(i)) { 
				if (!g_bHide[i] || GetClientTeam(i) != GetClientTeam(entity))
					clients[numClients++] = i;				
						
				if (i == entity)
					clients[numClients++] = i;
			}
    	}
    
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action CSS_Hook_ShotgunShot(const char[] te_name, const Players[], numClients, float delay)
{
	int[] newClients = new int[MaxClients];
	int client;
	int i;
	int newTotal = 0;
	
	for (i = 0; i < numClients; i++) { 
		client = Players[i];
		
		if (!g_bHide[i] || GetClientTeam(i) != GetClientTeam(client)) { 
			newClients[newTotal++] = client;
		}
	}
	
	if (newTotal == numClients)
		return Plugin_Continue;
	
	else if (newTotal == 0)
		return Plugin_Stop;
	
	float vTemp[3];
	TE_Start("Shotgun Shot");
	TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_weapon", TE_ReadNum("m_weapon"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
	TE_WriteFloat("m_fInaccuracy", TE_ReadFloat("m_fInaccuracy"));
	TE_WriteFloat("m_fSpread", TE_ReadFloat("m_fSpread"));
	TE_Send(newClients, newTotal, delay);
	
	return Plugin_Stop;
}