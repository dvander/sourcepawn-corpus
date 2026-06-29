#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
 
public Plugin:myinfo = {
	name = "TF2 Achievement Farming Buddy",
	author = "twistedeuphoria",
	description = "Get a buddy to help you farm achievements!",
	version = "0.2",
	url = "http://forums.alliedmods.net/showthread.php?t=95579"
};

#define BUDDYSTATE_NORMAL (1<<0)
#define BUDDYSTATE_EASYKILL (1<<1)
#define BUDDYSTATE_EASYHEAL (1<<2)
#define BUDDYSTATE_AUTORESPAWN (1<<3)


new buddyid[128];
new buddystate[128];

public OnPluginStart()
{		
	RegAdminCmd("sm_af_menu", af_menu, ADMFLAG_KICK, "Open the achievement farming buddy menu.", "", 0);
}

public OnClientDisconnect(client)
{
	buddyid[client] = 0;
}

public Action:af_menu(client, args)
{
	make_and_show_main_af_menu(client);
	return Plugin_Handled
}

public make_and_show_main_af_menu(client)
{
	new Handle:menu = CreateMenu(AFMenuHandler_main);
	AddMenuItem(menu, "makebuddy", "Spawn Buddy");
	AddMenuItem(menu, "killbuddy", "Remove Buddy");
	AddMenuItem(menu, "buddyteam", "Swap Buddy's Team");
	AddMenuItem(menu, "telebuddy", "Teleport Buddy Here");
	AddMenuItem(menu, "easykill", "Make Buddy Easy To Kill");
	AddMenuItem(menu, "easyheal", "Make Buddy Easy To Heal");
	AddMenuItem(menu, "normalbuddy", "Make Your Buddy Normal Again");
	AddMenuItem(menu, "respawnbuddy", "Respawn Your Buddy");
	AddMenuItem(menu, "autorespawn", "Make Your Buddy Automatically Respawn");
	
	SetMenuTitle(menu, "Achievement Farming Menu");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public AFMenuHandler_main(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
 
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if(strcmp(info, "makebuddy", false) == 0)
		{
			if(buddyid[param1] != 0)
			{
				PrintToChat(param1, "\x04Hey!  You already have a buddy!");
				make_and_show_main_af_menu(param1);
			}
			else
			{
				PrintToChat(param1, "\x04So you want a buddy...?");
				make_and_show_class_make_menu(param1);
			}
		}
		else if(strcmp(info, "killbuddy", false) == 0)
		{
			if(buddyid[param1] == 0)
			{
				PrintToChat(param1, "\x04You don't have a buddy to get rid of!");
				make_and_show_main_af_menu(param1);
			}
			else
			{
				PrintToChat(param1, "\x04Your buddy misses you already!");
				KickClient(buddyid[param1], "Done");
				buddyid[param1] = 0;
				make_and_show_main_af_menu(param1);
			}
		}
		else if(strcmp(info, "buddyteam", false) == 0)
		{
			if(buddyid[param1] == 0)
			{
				PrintToChat(param1, "\x04You don't have a buddy!");
				make_and_show_main_af_menu(param1);
			}
			else
			{
					new starteam = GetClientTeam(buddyid[param1]);
					new newteam = -1;
	
					if(starteam == 2) newteam = 3;
					else if(starteam == 3) newteam = 2;

					ChangeClientTeam(buddyid[param1], newteam);
					TF2_RespawnPlayer(buddyid[param1]);
					PrintToChat(param1, "\x04Your buddy is on the other team now!");
					make_and_show_main_af_menu(param1);
			}
		}
		else if(strcmp(info, "telebuddy", false) == 0)
		{
			if(buddyid[param1] == 0)
			{
				PrintToChat(param1, "\x04You focus and attempt to teleport your buddy to your location...then you realize you don't have a buddy!");
				make_and_show_main_af_menu(param1);
			}
			else
			{
				new Float:eyepos[3];
				new Float:blank[3];
				GetClientEyePosition(param1, eyepos);
				eyepos[2] += 20.0;
				TeleportEntity(buddyid[param1], eyepos, blank, blank);
				PrintToChat(param1, "\x04Using your powers you teleport your buddy to your location!  But where is he?  Check above!");
				make_and_show_main_af_menu(param1);
			}
		}
		else if(strcmp(info, "easykill", false) == 0)
		{
			if(buddyid[param1] == 0)
			{
				PrintToChat(param1, "\x04You don't have a buddy!");
				make_and_show_main_af_menu(param1);
			}
			else
			{
				buddystate[param1] &= ~BUDDYSTATE_EASYHEAL;
				buddystate[param1] |= BUDDYSTATE_EASYKILL;
				PrintToChat(param1, "\x04Your buddy is really easy to kill now!  You might want to make him automatically respawn!");
				make_and_show_main_af_menu(param1);
			}
		}
		else if(strcmp(info, "easyheal", false) == 0)
		{
			if(buddyid[param1] == 0)
			{
				PrintToChat(param1, "\x04You don't have a buddy!");
				make_and_show_main_af_menu(param1);
			}
			else
			{
				buddystate[param1] &= ~BUDDYSTATE_EASYKILL;
				buddystate[param1] |= BUDDYSTATE_EASYHEAL;
				PrintToChat(param1, "\x04Your buddy is really easy to heal now!");
				make_and_show_main_af_menu(param1);
			}
		}
		else if(strcmp(info, "normalbuddy", false) == 0)
		{
			if(buddyid[param1] == 0)
			{
				PrintToChat(param1, "\x04You don't have a buddy!");
				make_and_show_main_af_menu(param1);
			}
			else
			{
				buddystate[param1] = BUDDYSTATE_NORMAL;
				PrintToChat(param1, "\x04Your buddy is back to normal now!");
				make_and_show_main_af_menu(param1);
			}
		}
		else if(strcmp(info, "respawnbuddy", false) == 0)
		{
			if(buddyid[param1] == 0)
			{
				PrintToChat(param1, "\x04You don't have a buddy!");
				make_and_show_main_af_menu(param1);
			}
			else
			{
				TF2_RespawnPlayer(buddyid[param1]);
				PrintToChat(param1, "\x04Your buddy is alive again!");
				make_and_show_main_af_menu(param1);
			}
		}
		else if(strcmp(info, "autorespawn", false) == 0)
		{
			if(buddyid[param1] == 0)
			{
				PrintToChat(param1, "\x04You don't have a buddy!");
				make_and_show_main_af_menu(param1);
			}
			else
			{
				buddystate[param1] |= BUDDYSTATE_AUTORESPAWN;
				PrintToChat(param1, "\x04Your buddy is automatically respawning now!");
				make_and_show_main_af_menu(param1);
			}
		}
		else
		{
			make_and_show_main_af_menu(param1);
		}
	}
}

public make_and_show_class_make_menu(client)
{
	new Handle:menu = CreateMenu(AFMenuHandler_buddyclass);
	AddMenuItem(menu, "scout", "Scout");
	AddMenuItem(menu, "soldier", "Soldier");
	AddMenuItem(menu, "pyro", "Pyro");
	AddMenuItem(menu, "demo", "Demoman");
	AddMenuItem(menu, "heavy", "Heavy");
	AddMenuItem(menu, "engi", "Engineer");
	AddMenuItem(menu, "medic", "Medic");
	AddMenuItem(menu, "sniper", "Sniper");
	AddMenuItem(menu, "spy", "Spy");
	
	SetMenuTitle(menu, "Choose a class for your new buddy:");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public AFMenuHandler_buddyclass(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
 
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if(strcmp(info, "scout", false) == 0)
		{
			makeBuddy(param1, TFClass_Scout);
		}
		else if(strcmp(info, "soldier", false) == 0)
		{
			makeBuddy(param1, TFClass_Soldier);
		}
		else if(strcmp(info, "pyro", false) == 0)
		{
			makeBuddy(param1, TFClass_Pyro);
		}
		else if(strcmp(info, "demo", false) == 0)
		{
			makeBuddy(param1, TFClass_DemoMan);
		}
		else if(strcmp(info, "heavy", false) == 0)
		{
			makeBuddy(param1, TFClass_Heavy);
		}
		else if(strcmp(info, "engi", false) == 0)
		{
			makeBuddy(param1, TFClass_Engineer);
		}
		else if(strcmp(info, "medic", false) == 0)
		{
			makeBuddy(param1, TFClass_Medic);
		}
		else if(strcmp(info, "sniper", false) == 0)
		{
			makeBuddy(param1, TFClass_Sniper);
		}
		else if(strcmp(info, "spy", false) == 0)
		{
			makeBuddy(param1, TFClass_Spy);
		}
		else
		{
			PrintToChat(param1, "\x04You broke something!");
		}
		
		make_and_show_main_af_menu(param1);
	}
}

public makeBuddy(client, TFClassType:class)
{
	new String:cname[50];
	GetClientName(client, cname, 50);
	new String:bname[75];
	Format(bname, 75, "%s-buddy", cname);
	
	new botindex = CreateFakeClient(bname);
	
	if(botindex == 0)
	{
		PrintToChat(client, "\x04Could not create buddy - is the game full?");
		return;
	}
	
	new clientteam = GetClientTeam(client);
	new botteam = -1;
	
	if(clientteam == 2) botteam = 3;
	else if(clientteam == 3) botteam = 2;
	
	if(botteam == -1)
	{
		PrintToChat(client, "\x04Join a team, then you can have a buddy!");
		return;
	}
	
	ChangeClientTeam(botindex, botteam);
	TF2_SetPlayerClass(botindex, class);
	TF2_RespawnPlayer(botindex);
	
	
	buddyid[client] = botindex;
	
	new Float:eyepos[3];
	new Float:blank[3];
	GetClientEyePosition(client, eyepos);
	eyepos[2] += 20.0;
	TeleportEntity(botindex, eyepos, blank, blank);
	
	PrintToChat(client, "\x04Your new buddy should be here!  Look up!");
	
	return;
}

public OnGameFrame()
{
	for(new i=0;i<128;i++)
	{
		if((buddyid[i] != 0) && IsClientConnected(buddyid[i]))
		{
			if(!IsPlayerAlive(buddyid[i]) && (buddystate[i] & BUDDYSTATE_AUTORESPAWN))
			{
				TF2_RespawnPlayer(buddyid[i]);
				
				if(!(buddystate[i] & BUDDYSTATE_NORMAL)) SetEntityHealth(buddyid[i], 1);
				new Float:eyepos[3];
				new Float:blank[3];
				GetClientEyePosition(i, eyepos);
				eyepos[2] += 20.0;
				TeleportEntity(buddyid[i], eyepos, blank, blank);
			}
			else if(IsPlayerAlive(buddyid[i]) && (buddystate[i] & BUDDYSTATE_EASYHEAL))
			{
				SetEntityHealth(buddyid[i], 1);
			}
		}
	}
}