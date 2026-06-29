#include <sourcemod>
#include <sdktools>

public bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}
public bool IsPlayerFallen(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0;
}
public bool IsPlayerAlright(int client)
{
	return !(IsPlayerFalling(client) || IsPlayerFallen(client));
}

public void OnGameFrame()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsValidEntity(client))
        {
            if(IsClientInGame(client) && GetClientTeam(client) == 2)
            {
                int buttons = GetClientButtons(client)
                if(buttons & IN_SPEED && IsPlayerAlright(client))
                {
                    if(GetEntProp(client, Prop_Send, "m_iHideHUD") != 0)
                    {
                        SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
                    }
                }
                else
                {
                    if(GetEntProp(client, Prop_Send, "m_iHideHUD") != 321)
                    {
                        SetEntProp(client, Prop_Send, "m_iHideHUD", 321);
                    }
                }
            }       
        }
    }
}