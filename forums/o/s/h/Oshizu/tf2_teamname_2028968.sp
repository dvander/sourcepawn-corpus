new Handle:teamname_enabled
new teamname_enabled_b = true

new Handle:CV

public Plugin:myinfo = 
{
    name = "[TF2] Customizable Team Names",
    author = "Oshizu™",
    description = "Allows you to change names of teams in TF",
    version = "1.0.3",
    url = "www.sourcemod.net"
}

public OnPluginStart()
{
    teamname_enabled = CreateConVar("sm_teamname_enabled", "1", "- Change following value")
    HookConVarChange(teamname_enabled, CvarChange_Enabled)
    
    CV = FindConVar("mp_tournament")
}

public OnPluginEnd()
{
    if(GetConVarInt(CV) == 1)
    {
        for (new i = 1; i <= MaxClients; i++)
        {
            EnableTeamName(i)
        }
    }
    else
    {
        for (new i = 1; i <= MaxClients; i++)
        {
            DisableTeamName(i)
        }
    }
}

public OnClientPutInServer(client)
{
    if(teamname_enabled_b)
    {
        EnableTeamName(client)
    }
}

public CvarChange_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if(StringToInt(newValue) == 1)
    {
        teamname_enabled_b = true
        for (new i = 1; i <= MaxClients; i++)
        {
            EnableTeamName(i)
        }
    }
    else if(StringToInt(newValue) == 0)
    {
        teamname_enabled_b = false
        for (new i = 1; i <= MaxClients; i++)
        {
            DisableTeamName(i)
        }
    }
}

// Stocks

stock EnableTeamName(userid)
{
	if(IsClientInGame(userid))
	{
		if(!IsFakeClient(userid))
		{
			SendConVarValue(userid, CV, "1");
		}
	}
}

stock DisableTeamName(userid)
{
	if(IsClientInGame(userid))
	{
		if(!IsFakeClient(userid))
		{
			SendConVarValue(userid, CV, "0");
		}
	}
}  