#include <sourcemod>
#include <sdktools>
#include <warden>

new bool:Muted[MAXPLAYERS+1] = {false, ...};

Menu g_Menu = null;

public Plugin:myinfo =
{
	name = "Warden mute",
	author = "tommie113",
	description = "Allows wardens to mute terrorists.",
	version = "1.0",
	url = "https://www.sourcemod.net/"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_wmute", Wmute, "Allows a warden to mute all terrorists for a specified duration or untill the next round.");
	RegConsoleCmd("sm_wunmute", Wunmute, "Allows a warden to unmute the terrorists.");

	HookEvent("round_end", OnRoundEnd);
}

public void OnMapStart()
{
	g_Menu = BuildWMuteMenu();
}

public void OnMapEnd()
{
	if (g_Menu != INVALID_HANDLE)
	{
		delete(g_Menu);
		g_Menu = null;
	}
}

public Action:Wmute(int client, any args)
{
	if(!warden_iswarden(client))
	{
		ReplyToCommand(client, "You have to be warden in order to use this command.");
		return Plugin_Handled;
	}
	
	if(args < 1)
	{
		if(g_Menu == null)
		{
			LogMessage("Failed to create warden mute menu.");
			return Plugin_Handled;
		}
		
		g_Menu.Display(client, 20);
 
		return Plugin_Handled;
	} else if (args == 1) {
		new String:arg1[10];
		GetCmdArg(1, arg1, sizeof(arg1));
		new argument1;
		argument1 = StringToInt(arg1);
		Mute(argument1);
		return Plugin_Handled;
	} else {
		ReplyToCommand(client, "Usage: !wmute <duration>");
		return Plugin_Handled;
	}
}

public Action:Wunmute(int client, any args)
{
	if(!warden_iswarden(client))
	{
		ReplyToCommand(client, "You have to be warden in order to use this command.");
		return Plugin_Handled;
	}
	
	Unmute();
	return Plugin_Handled;
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	Unmute();
}

public Mute(a)
{
	for(new i = 1; i < MAXPLAYERS; i++)
	{
		if(IsClientConnected(i) && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			if(GetClientTeam(i) == 2)
			{
				if(GetClientListeningFlags(i) & VOICE_MUTED)
				{
					continue;
				}
				
				SetClientListeningFlags(i, VOICE_MUTED);
				Muted[i] = true;
			}
		}
	}
	
	if(a > 0)
	{
		new Float:b = float(a);
		CreateTimer(b, Timer);
	}
}

public Action:Timer(Handle timer)
{
	Unmute();
}

public Unmute()
{
	for(new i = 1; i < MAXPLAYERS; i++)
	{
		if(Muted[i])
		{
			SetClientListeningFlags(i, VOICE_NORMAL);
			Muted[i] = false;
		}
	}
}


Menu BuildWMuteMenu()
{
	Menu menu = new Menu(Menu_Mute);
	menu.SetTitle("Select the mute duration.");
	menu.AddItem("0", "Mute untill round end.");
	menu.AddItem("10", "Mute for 10 seconds.");
	menu.AddItem("20", "Mute for 20 seconds.");
	menu.AddItem("30", "Mute for 30 seconds.");
	menu.AddItem("40", "Mute for 40 seconds.");
	menu.AddItem("50", "Mute for 50 seconds.");
	menu.AddItem("60", "Mute for 60 seconds.");
	menu.ExitButton = true;
	
	return menu;
}

public int Menu_Mute(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[3];
		menu.GetItem(param2, info, sizeof(info));
		
		new duration;
		duration = StringToInt(info);
 
		Mute(duration);
	}
}