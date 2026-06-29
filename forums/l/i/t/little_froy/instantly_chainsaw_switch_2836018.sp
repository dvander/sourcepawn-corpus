#define PLUGIN_VERSION	"1.2"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "Instantly Chainsaw Switch",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=350859"
};

enum CHAINSAW_STATE
{
    CHAINSAW_STATE_INACTIVE = 0,
    CHAINSAW_STATE_STARTUP = 1,
    CHAINSAW_STATE_IDLE	= 2,
    CHAINSAW_STATE_ACTIVE =	3
};

int Offset_m_iState;

public void OnGameFrame()
{
    for(int client = 1; client <= MaxClients; client++)
    {
		if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(active == -1)
			{
				continue;
			}
			char class_name[64];
			GetEntityClassname(active, class_name, sizeof(class_name));
			if(strcmp(class_name, "weapon_chainsaw") != 0)
			{
				continue;
			}
			if(view_as<CHAINSAW_STATE>(GetEntData(active, Offset_m_iState)) == CHAINSAW_STATE_STARTUP)
			{
				SetEntData(active, Offset_m_iState, CHAINSAW_STATE_IDLE);
				int viewmodel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
				if(viewmodel != -1)
				{
					SetEntProp(viewmodel, Prop_Send, "m_nLayerSequence", 3);
				}
			}
		}
	}
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
	Offset_m_iState = FindSendPropInfo("CChainsaw", "m_bHitting") - 4;
    
	CreateConVar("instantly_chainsaw_switch_version", PLUGIN_VERSION, "version of Instantly Chainsaw Switch", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}
