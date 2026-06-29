#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION  "1.2"

public Plugin:myinfo = 
{
	name = "Bot Unlimited Ammo",
	author = "EfeDursun125",
	description = "Unlimited ammo for bots.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				if(GetAmmo(client) != -1)
				{
					SetEntData(client, GetAmmo(client) +4, 50);
					SetEntData(client, GetAmmo(client) +8, 50);
					if (GetEngineVersion() == Engine_TF2) 
					{
						SetVariantInt(1);
						AcceptEntityInput(client, "SetForcedTauntCam");
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

stock GetAmmo(client)
{
	if (GetEngineVersion() == Engine_TF2) 
	{
		return FindSendPropInfo("CTFPlayer", "m_iAmmo");
	}
	else if (GetEngineVersion() == Engine_CSS) 
	{
		return FindSendPropInfo("CCSPlayer", "m_iAmmo");
	}
	else if (GetEngineVersion() == Engine_CSGO) 
	{
		return FindSendPropInfo("CCSPlayer", "m_iAmmo");
	}
	else
	{
		return FindSendPropInfo("CPlayer", "m_iAmmo");
	}
}

bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}  