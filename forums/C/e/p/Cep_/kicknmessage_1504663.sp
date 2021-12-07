#pragma semicolon 1

#include <sourcemod>
#define PLUGIN_VERSION "1.0"
public Plugin:myinfo =
{
	name = "KicknMessage",
	author = "Cep>|<",
	description = "Kick connected players with a message",
	version = PLUGIN_VERSION,
	url = "http://www.fire-games.ru/"
};

new Handle:c_Enabled = INVALID_HANDLE;
new Handle:c_Mode = INVALID_HANDLE;
new Handle:c_AdminImmunity = INVALID_HANDLE;
new Handle:c_Message = INVALID_HANDLE;
new String:message[128];

public OnPluginStart( )
{
   	c_Enabled = CreateConVar("sm_kicknmessage", "1", "Enables this plugin");
   	c_Mode = CreateConVar("sm_kicknmessage_mode", "0", "Kick after: 0 - Connected, 1 - Join team");
   	c_AdminImmunity = CreateConVar("sm_kicknmessage_im", "1", "Admins immune. 1 - On, 0 - Off");
	c_Message = CreateConVar("sm_kicknmessage_text", "Message to kick", "Message for player");
   	CreateConVar("sm_kicknmessage_version", PLUGIN_VERSION, "Kick-Message version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "sm_kicknmessage");
        AddCommandListener(Command_JoinTeam, "jointeam");
}
public OnConfigsExecuted()
{
	GetConVarString(c_Message, message, 128);
}
public OnClientPostAdminCheck(client)
{
    if(GetConVarInt(c_Enabled) == 0 || GetConVarInt(c_Mode))
    return 1;
    if(IsClientConnected(client) && !IsFakeClient(client) && IsAdmin(client))
            return 1;
    KickClient(client, "%s",message);
    return 1;
}
public Action:Command_JoinTeam(client, const String:command[], argc)
{
    if(IsClientConnected(client) && !IsFakeClient(client) && IsAdmin(client))
        return Plugin_Continue;
    KickClient(client, "%s",message);
    return Plugin_Continue;
}
bool:IsAdmin(client)
{
    if(GetConVarInt(c_AdminImmunity) == 0) 
	return false;
    if (GetUserFlagBits(client) & ADMFLAG_RESERVATION) 
	return true;
    return false;
}