#define PLUGIN_VERSION "1.01"
#define PLUGIN_NAME "L4D Reserved redirect "
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

#include <sourcemod>
#include <sdktools>
new Handle:h_TimeBeforeKick = INVALID_HANDLE;
new Handle:h_PlayersBeforeKick = INVALID_HANDLE;
new Handle:h_ip = INVALID_HANDLE;
new Handle:h_b4kick_msg1 = INVALID_HANDLE;
new Handle:h_b4kick_msg2 = INVALID_HANDLE;
new Handle:h_b4kick_msg3 = INVALID_HANDLE;
new Handle:h_b4kick_msg4 = INVALID_HANDLE;
new Handle:h_b4kick_msg5 = INVALID_HANDLE;
new Handle:h_panelek = INVALID_HANDLE;

new Float:TimeBeforeKick, PlayersBeforeKick;
new String:ipserver[MAX_NAME_LENGTH];
new String:b4kick_msg1[MAX_NAME_LENGTH];
new String:b4kick_msg2[MAX_NAME_LENGTH];
new String:b4kick_msg3[MAX_NAME_LENGTH];
new String:b4kick_msg4[MAX_NAME_LENGTH];
new String:b4kick_msg5[MAX_NAME_LENGTH];

public Plugin:myinfo = 
{
    name = PLUGIN_NAME,
    author = "Olj, KrX, koles_pl",
    description = "[L4D] Reserves redirect spectator slots for admins only",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net/"
}

public OnPluginStart()
	{	
		h_b4kick_msg1= CreateConVar("sm_b4kick_msg1", "You joined reserved slot,", "Specifies message when showing redirect line1 (MAX 32 characters)", CVAR_FLAGS);
		h_b4kick_msg2= CreateConVar("sm_b4kick_msg2", "You will be AUTO KICKED in 30s", "line2" ,CVAR_FLAGS);
		h_b4kick_msg3= CreateConVar("sm_b4kick_msg3", "You still can connect to our ", "line3", CVAR_FLAGS);
		h_b4kick_msg4= CreateConVar("sm_b4kick_msg4", "second server - JUST PRESS F3", "line4", CVAR_FLAGS);
		h_b4kick_msg5= CreateConVar("sm_b4kick_msg5", "---","line5", CVAR_FLAGS);

		GetConVarString(h_b4kick_msg1,b4kick_msg1,sizeof(b4kick_msg1)); 
		GetConVarString(h_b4kick_msg2,b4kick_msg2,sizeof(b4kick_msg2)); 
		GetConVarString(h_b4kick_msg3,b4kick_msg3,sizeof(b4kick_msg3)); 
		GetConVarString(h_b4kick_msg4,b4kick_msg4,sizeof(b4kick_msg4)); 
		GetConVarString(h_b4kick_msg5,b4kick_msg5,sizeof(b4kick_msg5)); 

		h_panelek = CreatePanel();
		h_ip = CreateConVar("sm_ipserver", "78.46.59.68:27045", "Specifies ip of server to redirect to", CVAR_FLAGS);
		GetConVarString(h_ip,ipserver,sizeof(ipserver)); 
		CreateConVar("l4d_rs_version", PLUGIN_VERSION, "Version of Reserved redirect plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

		//LoadTranslations("reserved_redirect.phrases");
		h_TimeBeforeKick = CreateConVar("l4d_reservedredirect_timetokick", "10.00", "Specifies time before non-admin spectator will be kicked.", CVAR_FLAGS);
		h_PlayersBeforeKick = CreateConVar("l4d_Reservedredirect_playersb4kick", "8", "Specifies how many players to have before adding timer to start kicking", CVAR_FLAGS);
		DrawPanelText(h_panelek ,b4kick_msg1);
		DrawPanelText(h_panelek ,b4kick_msg2);
		DrawPanelText(h_panelek ,b4kick_msg3);
		DrawPanelText(h_panelek ,b4kick_msg4);
		DrawPanelText(h_panelek ,b4kick_msg5);
		DrawPanelItem(h_panelek, "Yes", ITEMDRAW_DEFAULT);
		DrawPanelItem(h_panelek, "No", ITEMDRAW_DEFAULT);
		DrawPanelItem(h_panelek, "close", ITEMDRAW_DEFAULT);

		TimeBeforeKick = GetConVarFloat(h_TimeBeforeKick);
		PlayersBeforeKick = GetConVarInt(h_PlayersBeforeKick);
		HookConVarChange(h_TimeBeforeKick, KickTimeChanged);
		AutoExecConfig(true, "L4D_Reservedredirect");



	}


public OnClientPostAdminCheck(client)
    {
		if (!IsValidPlayer(client)) return;
		new i = 0, totalClients = 0;
		for(i = 0; i < MaxClients; i++) {
			if(IsValidPlayer(i))
				totalClients++;
		}
		if(!IsClientMember(client) && totalClients > PlayersBeforeKick)
        {
            CreateTimer(TimeBeforeKick, KickTimer, client);
        }
    }
    
public KickTimeChanged(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
	{
		TimeBeforeKick = GetConVarFloat(h_TimeBeforeKick);
	}


public Action:KickTimer(Handle:timer, any:client)
    {
        if ((IsValidPlayer(client))&&(!IsClientMember(client))&&(GetClientTeam(client)==1))
            {	
                decl String:name[MAX_NAME_LENGTH];
                GetClientName(client, name, MAX_NAME_LENGTH);
		DisplayAskConnectBox(client, TimeBeforeKick, ipserver);
		SendPanelToClient(h_panelek, client, MenuHandler, 30);

         
            }
    }

public MenuHandler (Handle:menu, MenuAction:action, param1, param2)
{
if (action == MenuAction_Select)
	{
		if (param2 == 1)
		{

   			
		}
		if (param2 == 2)
		{

		}
	}
}

	
public IsValidPlayer (client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	return true;
}

bool:IsClientMember (client)
{
	// Checks valid player
	//if (!IsValidPlayer (client))
		//return false;
	
	// Gets the admin id
	new AdminId:id = GetUserAdmin(client);
	
	// If player is not admin ...
	if (id == INVALID_ADMIN_ID)
		return false;
	
	// If player has at least reservation ...
	if (GetAdminFlag(id, Admin_Reservation)||GetAdminFlag(id, Admin_Root)||GetAdminFlag(id, Admin_Kick))
		return true;
	else
	return false;
}
