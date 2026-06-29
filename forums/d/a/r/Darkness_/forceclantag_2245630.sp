#include <sourcemod>
#include <cstrike>

new Handle:ClanTag;

public Plugin:myinfo =
{
    name        =    "Set server clan tag",
    author        =    "Arkarr",
    description    =    "Set server clan tag",
    version        =    "1.0",
    url            =    "http://www.sourcemod.net"
};

public OnPluginStart()
{
    ClanTag = CreateConVar("sm_default_clan", "[n00b]", "Default clan tag");
}

public OnGameFrame()
{
    for (new i = MaxClients; i > 0; --i)
    {
        if(IsValidClient(i) && !CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC))
        {
            decl String:tagz[40], String:tagzCvar[40];
            CS_GetClientClanTag(i, tagz, sizeof(tagz));
            GetConVarString(ClanTag, tagzCvar, sizeof(tagzCvar));
            if(!StrEqual(tagzCvar, tagz))
                CS_SetClientClanTag(i, tagzCvar);
        }
    }
}

stock bool:IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	return true;
}