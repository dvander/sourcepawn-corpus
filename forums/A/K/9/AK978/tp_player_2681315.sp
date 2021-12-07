#include <sourcemod>
#include <sdktools> 

#define answer_NO "no"
#define answer_YES "yes"

new String:tpplayer[MAX_NAME_LENGTH];
new String:tpplayername[MAX_NAME_LENGTH];
new String:player_id[MAX_NAME_LENGTH];

new Handle:g_tp = INVALID_HANDLE;

public OnPluginStart()
{
	RegConsoleCmd("sm_tp2", Command_tp2, "");
}

public Action:Command_tp2(client, args)
{
	if(client!=0) CreatetpMenu(client);
	return Plugin_Handled;
}

CreatetpMenu(client)
{
	new Handle:menu = CreateMenu(Menu_tp);		
	new String:name[MAX_NAME_LENGTH];
	new String:playerid[32];
	SetMenuTitle(menu, "選擇傳送玩家");
	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==2)
		{
			Format(playerid,sizeof(playerid),"%i",GetClientUserId(i));
			if(GetClientName(i,name,sizeof(name)))
			{
				AddMenuItem(menu, playerid, name);						
			}
		}		
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);		
}

public Menu_tp(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32] , String:name[32];
		GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
		GetClientName(param1, player_id, sizeof(player_id));
		tpplayer = info;
		tpplayername = name;
		
		for(new i = 1;i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==2)
			{
				decl String:PlayerName[32];
				GetClientName(i, PlayerName, sizeof(PlayerName));
				
				if(StrContains(PlayerName, tpplayername, false) != -1)
				{
					DisplaytpMenu(i);
				}
			}
		}	
	}
}

public DisplaytpMenu(client)
{	
	g_tp = CreateMenu(Handler_Callback);
	SetMenuTitle(g_tp, "是否接受玩家的傳送");
	AddMenuItem(g_tp, answer_YES, "Yes");
	AddMenuItem(g_tp, answer_NO, "No");
	SetMenuExitButton(g_tp, false);
	DisplayMenu(g_tp, client, MENU_TIME_FOREVER);
}

public Handler_Callback(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				new Float:PlayerOrigin[3];
				new Float:TeleportOrigin[3];
				
				for(new i = 1;i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==2)
					{
						decl String:PlayerName[32];
						GetClientName(i, PlayerName, sizeof(PlayerName));
						
						if(StrContains(PlayerName, player_id, false) != -1)	
						{
							GetClientAbsOrigin(i, PlayerOrigin);
							
							TeleportOrigin[0] = PlayerOrigin[0];
							TeleportOrigin[1] = PlayerOrigin[1];
							TeleportOrigin[2] = (PlayerOrigin[2] + 73);

							TeleportEntity(param1, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
							PrintToChat(i ,"玩家 %N 傳送成功", param1);							
						}
					}
				}
			}
			case 1: 
			{
				for(new i = 1;i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==2)
					{
						decl String:PlayerName[32];
						GetClientName(i, PlayerName, sizeof(PlayerName));
						
						if(StrContains(PlayerName, player_id, false) != -1)
						{
							PrintToChat(i ,"玩家 %N 拒絕你的傳送要求", param1);
						}
					}
				}
			}
		}
	}
}