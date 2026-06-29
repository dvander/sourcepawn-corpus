/*
Notes:

ThingsToRemember:
public Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= GetMaxClients(); i++) 
	if (IsClientInGame(i))
	{	
	new Handle:menu = CreateMenu(MenuAbility);
	SetMenuTitle(menu, "l4d2 ability menu!!!");
	AddMenuItem(menu, "option0", "SelfReviveClass");
	AddMenuItem(menu, "option1", "SharpShooterClass");
	AddMenuItem(menu, "option2", "MedicClass");
	AddMenuItem(menu, "option3", "DomonactionClass");
	AddMenuItem(menu, "option4", "CrouchClass");
	AddMenuItem(menu, "option5", "SniperClass");
	AddMenuItem(menu, "option6", "HeavyClass");
	AddMenuItem(menu, "option7", "ScoutClass");
	AddMenuItem(menu, "option8", "DemoClass");
	AddMenuItem(menu, "option9", "SoldierClass");
	AddMenuItem(menu, "option10", "RacerClass");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, i, MENU_TIMER_FOREVER);
	}
}

more notes:
*	name =	"abilities"
*	author =	"gamemann"
*	description =	""
*	version =	"1.0.0"
*	url =		""
Version History:
*	2/5/2010:
*	- release
*	- working on it
Bugs:
**	- NONE!


*/










#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_NAME "abilities"
#define PLUGIN_TAG "AB"

#define DEBUG 0
#define KNIFE_TEXT "press FIREBUTTON to get released off of this special infected"

//handles
new Handle:SelfReviveClass = INVALID_HANDLE;
new Handle:SharpShooter = INVALID_HANDLE;
new Handle:Medic = INVALID_HANDLE;
new Handle:Domonation = INVALID_HANDLE;
new Handle:CrouchClass = INVALID_HANDLE;
new Handle:SniperClass = INVALID_HANDLE;
new Handle:HeavyClass = INVALID_HANDLE;
new Handle:ScoutClass = INVALID_HANDLE;
new Handle:DemoClass = INVALID_HANDLE;
new Handle:SoldierClass = INVALID_HANDLE;
new Handle:g_hConVar_Crawling;
new Handle:g_hConVar_Smoker;
new Handle:Racer = INVALID_HANDLE;
new bool:bHasClientClass[MAXPLAYERS+1];
new Float:RandomEverything;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "gamemann",
	description = "hidden ablilites that you can use and class you can get!!!",
	version = PLUGIN_VERSION,
	url = "sourcemod.net"
};

public OnPluginStart()
{
	g_hConVar_Crawling = FindConVar("survivor_allow_crawling");
	g_hConVar_Smoker = FindConVar("tongue_allow_voluntary_release");	
	//hooking events
	HookEvent("round_start", Event_Round_Start);
	HookEvent("round_end", Event_Round_End);
	HookEvent("tank_killed", Event_Tank_Killed);
	HookEvent("tank_spawn", Event_Tank_Spawned);
	HookEvent("witch_killed", Event_Witch_Killed);
	HookEvent("witch_spawn", Event_Witch_Spawn);
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("infected_death", Event_Infected_Death);
	HookEvent("player_death", Event_Player_Death);

	AllowCrawl();
	AllowSmokerRelease();
	HookConVarChange(g_hConVar_Crawling, ConVarChange_Crawl);
	HookConVarChange(g_hConVar_SmokerRelease, ConVarChange_SmokerRelease);
	

	//convars
	SelfReviveClass = CreateConVar("self_revive", "1", "the self revive class, if its enabled or not", FCVAR_PLUGIN);
	SharpShooter = CreateConVar("sharp_shooter_class", "1", "the sharpshooter class if its enabled or not", FCVAR_PLUGIN);
	Medic = CreateConVar("medic_class", "1", "the medic class if its enabled or not", FCVAR_PLUGIN);
	Domonation = CreateConVar("domonaction_class", "1", "the domonaction class if its enabled or not", FCVAR_PLUGIN);
	CrouchClass = CreateConVar("crouch_class", "1", "the crouch class if its enabled or not", FCVAR_PLUGIN);
	SniperClass = CreateConVar("sniper_class", "1", "the sniper class if its enabled or not", FCVAR_PLUGIN);
	HeavyClass = CreateConVar("heavy_class", "1", "the heavy class if its enabled or not", FCVAR_PLUGIN);
	ScoutClass = CreateConVar("scout_class", "1", "the scout class if its enabled or not", FCVAR_PLUGIN);
	DemoClass = CreateConVar("demo_class", "1", "the demo class if its enabled or not", FCVAR_PLUGIN);
	SoldierClass = CreateConVar("soldier_class", "1", "the soldier class if its enabled or not", FCVAR_PLUGIN);
	Racer = CreateConVar("racer_class", "1", "the racer class if its enabled or not", FCVAR_PLUGIN);

	AutoExecConfig(true, "l4d2_abilites_gamemann");
}

public Event_Witch_Killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:name[190]
	new Killer = GetConVarInt(event, "attacker");
	GetClientName(Killer, name, sizeof(name));
	PrintToChatAll(""Killer"%s has just killed the witch so he gets different abilities!!!");
	if(Killer !=0)
	{
		RandomEveything = GetRandomInt(0, 1)
		SetConVarInt(SelfReviveClass, RandomEverything);
		SetConVarInt(SharpShooterClass, RandomEverything);
		SetConVarInt(Medic, RandomEverything);
		SetConVarInt(Domonaction, RandomEverything);
		SetConVarInt(CrouchClass, RandomEverything);
		SetConVarInt(SniperClass, RandomEverything);
		SetConVarInt(HeavyClass, RandomEverything);
		SetConVarInt(ScoutClass, RandomEverything);
		SetConVarInt(DemoClass, RandomEverything);
		SetConVarInt(SoldierClass, RandomEverything);
		SetConVarInt(Racer, RandomEverything);
		if(RandomEverything == 0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(SelfReviveClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(SharpShooterClass)==0)
		{
			return Plugin-Handled;
		}
		if(GetConVarInt(Medic)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(Domonaction)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(CrouchClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(SniperClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(HeavyClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(ScoutClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVar(DemoClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(SoldierClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(Racer)==0)
		{
			return Plugin_Handled;
		}
		//now we are going to make the actions avalible with timers!


		if(GetConVarInt(SelfReviveClass)==1)
		{
			CreateTimer(1.0, SelfReviveClassTimer);
		}
		if(GetConVarInt(SharpShooterClass)==1)
		{
			CreateTimer(1.0, SharpShooterClassTimer);
		}
		if(GetConVarInt(Medic)==1)
		{
			CreateTimer(1.0, MedicTimer);
		}
		if(GetConVarInt(Domonaction)==1)
		{
			CreateTimer(1.0, DomonactionTimer);
		}
		if(GetConVarInt(CrouchClass)==1)
		{
			CreateTimer(1.0, CrouchClassTimer);
		}
		if(GetConVarInt(SniperClass)==1)
		{
			CreateTimer(1.0, SniperClass);
		}
		if(GetConVarInt(HeavyClass)==1)
		{
			CreateTimer(1.0, HeavyClass);
		}
		if(GetConVarInt(ScoutClass)==1)
		{
			CreateTimer(1.0, ScoutClassTimer);
		}
		if(GetConVar(DemoClass)==1)
		{
			CreateTimer(1.0, DemoClassTimer);
		}
		if(GetConVarInt(SoldierClass)==1)
		{
			CreateTimer(1.0, SoldierClassTimer);
		}
		if(GetConVarInt(Racer)==1)
		{
			CreateTimer(1.0, RacerTimer);
		}
	}
	return Plugin_Continue;
}

//ALL TIMERS THAT DO STUFF
public Action:SelfReviveClassTimer(Handle:htimer, any:client)
{
	if(GetConVarInt(SelfReviveClass)==1)
	{
		HookEvent("player_incapacitated", Event_Player_Incap);
		public Event_Player_Incap(Handle:event, const String:name[], bool:dontBroadcast)
		{
			CreateTimer(0.1, PlayerIncapTime);
		}
		
		public Action:PlayerIncapTime(Handle:timer, any:client)
		{
			HookEvent("revive_begin", Event_Revive_Begin);
			HookEvent("revive_end", Event_Revive_End);
		}
		public Event_Revive_Begin(Handle:event, const String:name[], bool:dontBroadcast)
		{
			CreateTimer(5.0, ReviveBeginTimerThenEnd);
		}
		public Action:ReviveBeginTimerThenEnd(Handle:htimer, any:client)
		{
			GetConVarInt(event, "Event_Revive-End");
			if(GetConVarInt(Event_Revive-End)==1)
			{
				PrintToChat(client, "you have been revived by yourself from using the ability SelfReviveClass!");
			}
		}
	}
	if(GetConVarInt(SelfReviveClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:SharpShooterClass(Handle:htimer, any:client)
{
	if(GetConVarInt(SharpShooterClass)==1)
	{
		CreateTimer(0.1, SharpShooterClassAbilities);
	}
	public Action:SharpShooterClassAbilities(Handle:htimer, any:client)
	{
		FakeClientCommand(client, "survivor_accuracy_upgrade_factor 3.0");
		PrintToChat(client, "you have the sharpshooter ability which lets you have better accurcy with your guns and you spawn with a hunting rifle every round!!!!");
	}
	if(GetConVarInt(SharpShooterClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:MedicTimer(Handle:event, any:client)
{
	if(GetConVarInt(Medic)==1)
	{
		CreateTimer(0.1, MedicTimerZ);
	}
	public Action:MedicTimerZ(Handle:htimer, any:client)
	{
		FakeClientCommand(client, "give first_aid_kit");
		FakeClientCommand(client, "first_aid_kit_use_duration 2");
		FakeClientCommand(client, "first_aid_kit_max_heal 150");
		FakeClientCommand(client, "first_aid_heal_percent 1.5");
		PrintToChat(client, "you got the ability Medic which lets you heal 2.5 faster than normal and you can have higher healths such as 100 is max health but now you can have up to 150!");
	}
	if(GetConvarInt(Medic)==0)
	{
		return Plugin_Handled;
	}
}

	
						


			


