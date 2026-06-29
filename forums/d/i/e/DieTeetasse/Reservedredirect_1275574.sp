#define PLUGIN_VERSION "1.02"
#define PLUGIN_NAME "L4D Reserved redirect "
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

#include <sourcemod>
#include <sdktools>

new Handle:h_TimeToShowQuestion = INVALID_HANDLE;
new Handle:h_PlayersBeforeKick = INVALID_HANDLE;
new Handle:h_ip = INVALID_HANDLE;
new Handle:h_b4kick_msg[5] = INVALID_HANDLE;
new Handle:h_panelek = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name = PLUGIN_NAME,
    author = "Olj, KrX, koles_pl, Die Teetasse",
    description = "[L4D] Reserves redirect spectator slots for admins only",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{    
    
    CreateConVar("l4d_reservedredirect_version", PLUGIN_VERSION, "Version of Reserved redirect plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    h_TimeToShowQuestion = CreateConVar("l4d_reservedredirect_timetoshowquestion", "30", "Specifies time before non-admin spectator will be kicked.", CVAR_FLAGS);
    h_PlayersBeforeKick = CreateConVar("l4d_reservedredirect_playersb4kick", "8", "Specifies how many players to have before adding timer to start kicking", CVAR_FLAGS);
    h_ip = CreateConVar("l4d_reservedredirect_ipserver", "78.46.59.68:27045", "Specifies ip of server to redirect to", CVAR_FLAGS);
    
    h_b4kick_msg[0]= CreateConVar("l4d_reservedredirect_msg1", "You joined reserved slot,", "Specifies message when showing redirect line1 (MAX 32 characters)", CVAR_FLAGS);
    h_b4kick_msg[1]= CreateConVar("l4d_reservedredirect_msg2", "You will be AUTO KICKED in 30s", "line2" ,CVAR_FLAGS);
    h_b4kick_msg[2]= CreateConVar("l4d_reservedredirect_msg3", "You still can connect to our ", "line3", CVAR_FLAGS);
    h_b4kick_msg[3]= CreateConVar("l4d_reservedredirect_msg4", "second server - JUST PRESS F3", "line4", CVAR_FLAGS);
    h_b4kick_msg[4]= CreateConVar("l4d_reservedredirect_msg5", "---", "line5", CVAR_FLAGS);

    AutoExecConfig(true, "L4D_Reservedredirect");
    CreateAskConnectPanel();
}

public OnMapStart()
{
    CreateAskConnectPanel();
}

CreateAskConnectPanel()
{
    decl String:msg[MAX_NAME_LENGTH];    
    h_panelek = CreatePanel();
    
    for (new i = 0; i < 5; i++)
    {
        GetConVarString(h_b4kick_msg[i], msg, sizeof(msg));
        DrawPanelText(h_panelek, msg);
    }
}

public OnClientPostAdminCheck(client)
{
    if (!IsValidPlayer(client))
        return;
        
    new totalClients = 0;
    for(new i = 1; i < MaxClients+1; i++)
        if(IsValidPlayer(i)) totalClients++;
    
    if(!IsClientMember(client) && totalClients > GetConVarInt(h_PlayersBeforeKick))
    {
        CreateTimer(25.0, ShowQuestionTimer, client);
        CreateTimer((GetConVarFloat(h_TimeToShowQuestion) + 25.0), KickTimer, client);
    }
}

public Action:ShowQuestionTimer(Handle:timer, any:client)
{
    if (GetClientTeam(client) == 1)
    {    
        decl String:ipServer[64];
        GetConVarString(h_ip, ipServer, sizeof(ipServer));
    
        new timeForQuestion = GetConVarInt(h_TimeToShowQuestion);
        
        DisplayAskConnectBox(client, float(timeForQuestion), ipServer);
        SendPanelToClient(h_panelek, client, MenuHandler, timeForQuestion);
    }
}

public Action:KickTimer(Handle:timer, any:client)
{
    if (GetClientTeam(client) == 1)
        KickClient(client, "Kicked! Too many spectators!");
}

public MenuHandler (Handle:menu, MenuAction:action, param1, param2)
{
    // nothing to do
}
    
bool:IsValidPlayer(client)
{
    if (!IsClientInGame(client))
        return false;
    
    if (IsFakeClient(client))
        return false;
    
    return true;
}

bool:IsClientMember(client)
{
    // Gets the admin id
    new AdminId:id = GetUserAdmin(client);
    
    // If player is not admin ...
    if (id == INVALID_ADMIN_ID)
        return false;
    
    // If player has at least reservation ...
    if (GetAdminFlag(id, Admin_Reservation) || GetAdminFlag(id, Admin_Root) || GetAdminFlag(id, Admin_Kick))
        return true;
    
    return false;
}  