//garrett's simple medic....

//Includes:
#include <sourcemod>
#include <sdktools>

//well... semicolon is good
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.1"

static bool:PrethinkBuffer[MAXPLAYERS + 1];
static Float:clientposition[MAXPLAYERS + 1][3];
static Float:targetposition[MAXPLAYERS + 1][3];
static targetent[MAXPLAYERS + 1];
static targethp[MAXPLAYERS + 1];
static bool:isinhealing[MAXPLAYERS + 1];

new MaxPlayers;

//Effects
new g_BeamSprite;
new g_HaloSprite;
new greenColor[4] = {0, 200, 0, 255};
new blueColor[4] = {0, 0, 255, 255};

public Plugin:myinfo = 
{
	name = "Garrett's medic plugin",
	author = "javalia",
	description = "Initiates healing when a player presses his use key on another",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=829970"
};

public OnPluginStart()
{
	CreateConVar("sm_medic_version", PLUGIN_VERSION, "Version of the Medic plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnMapStart()
{
	MaxPlayers = GetMaxClients();
	
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt", true); 
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt", true);
	
	for (new i = 1; i <= MaxPlayers; i++)
	{
		targetent[i] = -1;
	}
}

public OnGameFrame()
{
	//Loop:
	for (new Client = 1; Client <= MaxPlayers; Client++)
	{
		//Connected and alive:
		if (IsClientInGame(Client) && IsPlayerAlive(Client))
		{
			//Use Key:
			if (GetClientButtons(Client) & IN_USE)
			{
				//Overflow:
				if (!PrethinkBuffer[Client])
				{
					//Action:
					CommandUse(Client);
					
					//UnHook:
					PrethinkBuffer[Client] = true;
				}
			}
			else
				PrethinkBuffer[Client] = false;
		}
	}
}

CommandUse(Client)
{
	//Initialize:
	new target = GetClientAimTarget(Client);
	
	if (target < 1)
		return;
	
	//Spamming the use key causes this to show up if the target is out of range  =/
	if (targetent[Client] > 0)
	{
		if (target != targetent[Client])
			PrintToChat(Client, "[Garrett] You can only heal one person at a time.");
		else
			PrintToChat(Client, "[Garrett] You are already healing %N.", target);
		
		return;
	}
	
	if (GetClientTeam(Client) == GetClientTeam(target))
	{
		targetent[Client] = target;
		CreateTimer(0.5, Commandmedic, Client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Commandmedic(Handle:Timer, any:Client)
{
	if (!IsClientInGame(Client) || !IsClientInGame(targetent[Client]) || !IsPlayerAlive(Client) || !IsPlayerAlive(targetent[Client]))
	{
		isinhealing[Client] = false;
		targetent[Client] = -1;
		return Plugin_Handled;
	}
	
	GetClientAbsOrigin(Client, clientposition[Client]);
	GetClientAbsOrigin(targetent[Client], targetposition[targetent[Client]]);
	new Float:distance = GetVectorDistance(clientposition[Client], targetposition[targetent[Client]]);
	
	//Initial
	if (!isinhealing[Client])
	{
		if (distance < 200.0)
		{
			targethp[targetent[Client]] = GetClientHealth(targetent[Client]);
			
			if (targethp[targetent[Client]] < 100)
			{
				PrintToChat(Client, "[Garrett] You are now healing %N. Healing will occur as long as %N is within range", targetent[Client], targetent[Client]);
				SetEntityHealth(targetent[Client], targethp[targetent[Client]] + 2);
				clientposition[Client][2] += 10.0;
				TE_SetupBeamRingPoint(clientposition[Client], 10.0, 400.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greenColor, 10, 0);
				TE_SendToAll();
				targetposition[targetent[Client]][2] += 10.0;
	  			TE_SetupBeamRingPoint(targetposition[targetent[Client]], 400.0, 10.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.5, 10.0, 0.5, blueColor, 10, 0);
				TE_SendToAll();
				PrintToChat(Client, "[Garrett] %N's health: %d", targetent[Client], targethp[targetent[Client]]);
				isinhealing[Client] = true;
				CreateTimer(0.5, Commandmedic, Client, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				if (targethp[targetent[Client]] > 100)
					SetEntityHealth(targetent[Client], 100);
				
				isinhealing[Client] = false;
				PrintToChat(Client, "[Garrett] %N has full health.", targetent[Client]);
				targetent[Client] = -1;
			}
		}
		else
			targetent[Client] = -1;
	}
	else	//Subsequent
	{
		if (distance < 200.0)
		{
			targethp[targetent[Client]] = GetClientHealth(targetent[Client]);
			
			if (targethp[targetent[Client]] < 100)
			{
				SetEntityHealth(targetent[Client], targethp[targetent[Client]] + 2);
				clientposition[Client][2] += 10.0;
				TE_SetupBeamRingPoint(clientposition[Client], 10.0, 400.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greenColor, 10, 0);
				TE_SendToAll();
				targetposition[targetent[Client]][2] += 10.0;
	  			TE_SetupBeamRingPoint(targetposition[targetent[Client]], 400.0, 10.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.5, 10.0, 0.5, blueColor, 10, 0);
				TE_SendToAll();
				PrintToChat(Client, "[Garrett] %N's health: %d", targetent[Client], targethp[targetent[Client]]);
				CreateTimer(0.5, Commandmedic, Client, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				if (targethp[targetent[Client]] > 100)
					SetEntityHealth(targetent[Client], 100);
				
				isinhealing[Client] = false;
				PrintToChat(Client, "[Garrett] %N has full health.", targetent[Client]);
				targetent[Client] = -1;
			}
		}
		else
		{
			isinhealing[Client] = false;
			PrintToChat(Client, "[Garrett] %N is out of range, healing stopped.", targetent[Client]);
			targetent[Client] = -1;
		}
	}
	return Plugin_Handled;
}
