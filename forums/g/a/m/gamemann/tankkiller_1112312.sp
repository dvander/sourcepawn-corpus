#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "tankkiller",
	author = "gamemann",
	description = "When a tank dies something happens to him goodly though",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	HookEvent("tank_killed", Event_TankKilled);
	HookEvent("witch_killed", WitchKilled);
	HookEvent("witch_spawn", WitchSpawned);
	HookEvent("tank_spawn", TankSpawn);
	HookEvent("player_left_start_area", Horde);
}

public Event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Userid = GetEventInt(event, "userid");
	new User = GetClientOfUserId(Userid);
	if(User)
	{
		for (new i = 1; i <= GetMaxClients(); i++)
		if(IsClientInGame(i))
		{
			PrintHintText(i, "You are the tank killer! You get three things if you except this notice press yes if you dont like it press no...");
			new Handle:menu = CreateMenu(TankKillerMenu);
			SetMenuTitle(menu, "tank killer menu");
			AddMenuItem(menu, "option0", "Yes");
			AddMenuItem(menu, "option1", "No");
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, i, MENU_TIME_FOREVER);
		}
	}
}

public TankKillerMenu(Handle:menu, MenuAction:action, client, itemNum)
{
new Flags = GetCommandFlags("give");
SetCommandFlags("give", Flags & ~FCVAR_CHEAT);
new Flags1 = GetCommandFlags("director_force_panic_event");
SetCommandFlags("director_force_panic_event", Flags1 & ~FCVAR_CHEAT);
if(action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0: //Yes now for the weapons
			{
				FakeClientCommand(client, "give molotov");
				FakeClientCommand(client, "give health");
				FakeClientCommand(client, "give pain_pills");
			}
			case 1: //now for the no answer! TRICK				
			{
				PrintToChatAll("whoever killed the tank said no to get three more items. So this time something bad happens. hahahahahhaha");
				FakeClientCommand(client, "director_force_panic_event");
			}
		}
	}
}

public WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= GetMaxClients(); i++)
	if (IsClientInGame(i))
	{
		new Flags3 = GetCommandFlags("director_force_panic_event");
		SetCommandFlags("director_force_panic_event", Flags3 & ~FCVAR_CHEAT);
		PrintHintText(i, "HORDE PANIC EVENT!!!");
		FakeClientCommand(i, "director_force_panic_event");
	}
}

public WitchSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= GetMaxClients(); i++)
	if (IsClientInGame(i))
	{
		new Flags4 = GetCommandFlags("director_force_panic_event");
		SetCommandFlags("director_force_panic_event", Flags4 & ~FCVAR_CHEAT);
		PrintHintText(i, "HORDE PANIC EVENT!!!");
		FakeClientCommand(i, "director_force_panic_event");
	}
}

public TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= GetMaxClients(); i++)
	if (IsClientInGame(i))
	{
		new Flags5 = GetCommandFlags("director_force_panic_event");
		SetCommandFlags("director_force_panic_event", Flags5 & ~FCVAR_CHEAT);
		new Flags19 = GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", Flags19 & ~FCVAR_CHEAT);
		PrintHintText(i, "HORDE PANIC EVENT!!!");
		FakeClientCommand(i, "director_force_panic_event");
	}
}

public Horde(Handle:event, const String:name[], bool:dontBoradcast)
{
	for (new i = 1; i <= GetMaxClients(); i++)
	if (IsClientInGame(i))
	{
		new Flags5 = GetCommandFlags("director_force_panic_event");
		SetCommandFlags("director_force_panic_event", Flags5 & ~FCVAR_CHEAT);
		new Flags19 = GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", Flags19 & ~FCVAR_CHEAT);
		PrintHintText(i, "HORDE PANIC EVENT!!! + WITCH!!!!!!");
		FakeClientCommand(i, "director_force_panic_event");
	}
}



					
 