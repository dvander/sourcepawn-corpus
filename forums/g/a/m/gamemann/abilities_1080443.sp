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









//includes
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

//defines
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_NAME "abilities"
#define PLUGIN_TAG "AB"

//debug == 0
#define DEBUG 0
#define KNIFE_TEXT "press FIREBUTTON to get released off of this special infected"

//spawns allowed
new Handle:TankSpawnAllowAbilites = INVALID_HANDLE;
new Handle:TankKilledAllowAbilites = INVALID_HANDLE;
new Handle:WitchKilledAllowAbilites = INVALID_HANDLE;
new Handle:WitchSpawnAllowAbilites = INVALID_HANDLE;
new Handle:RoundStartAllowAbilites = INVALID_HANDLE;


//handles
new Handle:SelfReviveClass = INVALID_HANDLE;
new Handle:SharpShooterClass = INVALID_HANDLE;
new Handle:Medic = INVALID_HANDLE;
new Handle:DomonationClass = INVALID_HANDLE;
new Handle:CrouchClass = INVALID_HANDLE;
new Handle:SniperClass = INVALID_HANDLE;
new Handle:HeavyClass = INVALID_HANDLE;
new Handle:ScoutClass = INVALID_HANDLE;
new Handle:DemoClass = INVALID_HANDLE;
new Handle:SoldierClass = INVALID_HANDLE;
new Handle:RacerClass = INVALID_HANDLE;
new bool:bHasClientClass[MAXPLAYERS+1];
new Float:RandomEverything;
new bool:Hooked = false;

//myinfo
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
	//convars
	SelfReviveClass = CreateConVar("self_revive", "1", "the self revive class, if its enabled or not", FCVAR_PLUGIN);
	SharpShooterClass = CreateConVar("sharp_shooter_class", "1", "the sharpshooter class if its enabled or not", FCVAR_PLUGIN);
	Medic = CreateConVar("medic_class", "1", "the medic class if its enabled or not", FCVAR_PLUGIN);
	DomonationClass = CreateConVar("domonaction_class", "1", "the domonaction class if its enabled or not", FCVAR_PLUGIN);
	CrouchClass = CreateConVar("crouch_class", "1", "the crouch class if its enabled or not", FCVAR_PLUGIN);
	SniperClass = CreateConVar("sniper_class", "1", "the sniper class if its enabled or not", FCVAR_PLUGIN);
	HeavyClass = CreateConVar("heavy_class", "1", "the heavy class if its enabled or not", FCVAR_PLUGIN);
	ScoutClass = CreateConVar("scout_class", "1", "the scout class if its enabled or not", FCVAR_PLUGIN);
	DemoClass = CreateConVar("demo_class", "1", "the demo class if its enabled or not", FCVAR_PLUGIN);
	SoldierClass = CreateConVar("soldier_class", "1", "the soldier class if its enabled or not", FCVAR_PLUGIN);
	RacerClass = CreateConVar("racer_class", "1", "the racer class if its enabled or not", FCVAR_PLUGIN);
	WitchKilledAllowAbilites = CreateConVar("witch_killed_allow_abilities", "1", "if set to 0 will make it so you cant get abilites after a witch gets killed for a killer!", FCVAR_PLUGIN);
	WitchSpawnAllowAbilites = CreateConVar("witch_spawn_allow_abilites", "1", "if set to 0 will make it so you dont get abilites when a witch is spawned", FCVAR_PLUGIN);
	TankSpawnAllowAbilites = CreateConVar("tank_spawn_allow_abilites", "1", "if set to 0 will make it so when a tank is spawned you cant get any abilites", FCVAR_PLUGIN);
	TankKilledAllowAbilites = CreateConVar("tank_killed_allow_abilites", "1", "if set to 0 will make it so when a tank is killed you cant get any abilities", FCVAR_PLUGIN);
	RoundStartAllowAbilites = CreateConVar("round_start_allow_abilites", "1", "if set to 0 will make it so at round start you will not be able to get abilites and a menu", FCVAR_PLUGIN);

	//reg console cmds
	
	AutoExecConfig(true, "l4d2_abilites_gamemann");
}
public ActiveEvents()
{
	if(!Hooked)
	{
	Hooked = true;
	HookEvent("round_start", Event_Round_Start);
	HookEvent("round_end", Event_Round_End);
	HookEvent("tank_killed", Event_Tank_Killed);
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("witch_killed", Event_Witch_Killed);
	HookEvent("witch_spawn", Event_Witch_Spawn);
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("player_incapacitated", Event_Player_Incap);
	HookEvent("revive_begin", Event_Revive_Begin);
	HookEvent("revive_end", Event_Revive_End);
	}
}


public Action:Event_Witch_Killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:name[190]
	new Killer = GetEventInt(event, "attacker");
	GetClientName(Killer, name, sizeof(name));
	PrintToChatAll("%s has just killed the witch so he gets different abilities!!!", name, Killer);
	if(Killer !=0)
	{
		RandomEverything = GetRandomInt(0, 1)
		SetConVarInt(SelfReviveClass, RandomEverything);
		SetConVarInt(SharpShooterClass, RandomEverything);
		SetConVarInt(Medic, RandomEverything);
		SetConVarInt(Domonation, RandomEverything);
		SetConVarInt(CrouchClass, RandomEverything);
		SetConVarInt(SniperClass, RandomEverything);
		SetConVarInt(HeavyClass, RandomEverything);
		SetConVarInt(ScoutClass, RandomEverything);
		SetConVarInt(DemoClass, RandomEverything);
		SetConVarInt(SoldierClass, RandomEverything);
		SetConVarInt(RacerClass, RandomEverything);
		if(RandomEverything == 0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(SelfReviveClass)==0)
		{
			return Plugin_Continue;
		}
		if(GetConVarInt(SharpShooterClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(Medic)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(Domonation)==0)
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
		if(GetConVarInt(DemoClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(SoldierClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(RacerClass)==0)
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
		if(GetConVarInt(Domonation)==1)
		{
			CreateTimer(1.0, DomonactionTimer);
		}
		if(GetConVarInt(CrouchClass)==1)
		{
			CreateTimer(1.0, CrouchClassTimer);
		}
		if(GetConVarInt(SniperClass)==1)
		{
			CreateTimer(1.0, SniperClassTimer);
		}
		if(GetConVarInt(HeavyClass)==1)
		{
			CreateTimer(1.0, HeavyClassTimer);
		}
		if(GetConVarInt(ScoutClass)==1)
		{
			CreateTimer(1.0, ScoutClassTimer);
		}
		if(GetConVarInt(DemoClass)==1)
		{
			CreateTimer(1.0, DemoClassTimer);
		}
		if(GetConVarInt(SoldierClass)==1)
		{
			CreateTimer(1.0, SoldierClassTimer);
		}
		if(GetConVarInt(RacerClass)==1)
		{
			CreateTimer(1.0, RacerTimer);
		}
		if(GetConVarInt(WitchKilledAllowAbilites)==0)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Event_Player_Incap(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, PlayerIncapTime);
	return Plugin_Continue;
}
public Event_Revive_Begin(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(5.0, ReviveBeginTimerThenEnd);
}
public Action:ReviveBeginTimerThenEnd(Handle:htimer, any:client)
{
	if(GetConVarInt(Event_Revive_End)==1)
	{
		PrintToChat(client, "you have been revived by yourself from using the ability SelfReviveClass!");
	}
}

//ALL TIMERS THAT DO STUFF
public Action:SelfReviveClassTimer(Handle:htimer, any:client)
{
	if(GetConVarInt(SelfReviveClass)==1)
	{
		CreateTimer(5.0, PlayerIncapTime);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:PlayerIncapTime(Handle:htimer, any:client)
{
	if(GetConVarInt(Event_Revive_End)==1)
	{
		PrintToChat(client, "you got revived by yourself!");
	}
	if(GetConVarInt(SelfReviveClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


public Action:SharpShooterClassTimer(Handle:htimer, any:client)
{
	if(GetConVarInt(SharpShooterClass)==1)
	{
		CreateTimer(0.1, SharpShooterClassAbilities);
	}
	return Plugin_Handled;
}

public Action:SharpShooterClassAbilities(Handle:htimer, any:client)
{
	FakeClientCommand(client, "survivor_accuracy_upgrade_factor 3.0");
	PrintToChat(client, "you have the sharpshooter ability which lets you have better accurcy with your guns and you spawn with a hunting rifle every round!!!!");
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
		return Plugin_Handled;
	}
}

public Action:MedicTimerZ(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "give first_aid_kit");
		FakeClientCommand(client, "first_aid_kit_use_duration 2");
		FakeClientCommand(client, "first_aid_kit_max_heal 150");
		FakeClientCommand(client, "first_aid_heal_percent 1.5");
		PrintToChat(client, "you got the ability Medic which lets you heal 2.5 faster than normal and you can have higher healths such as 100 is max health but now you can have up to 150!");
	}
	if(GetConVarInt(Medic)==0)
	{
		return Plugin_Handled;
	}
}
public Action:DomonactionTimer(Handle:htimer, any:client)
{
	if(GetConVarInt(DomonationClass)==1)
	{
		CreateTimer(0.1, DomonationTimer*);
	}
	return Plugin_Handled;
}

public Action:DomonationTimer*(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_damage_speed_factor 1.0f");
		PrintToChat(client, "you have the Domonaction ability which means you do more damage with explosives such as grenade launchers!");
	}
	if(GetConVarInt(DomonactionClass)==0)
	{
	return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:CrouchClassTimer(Handle:htimer, any:client)
{
	if(GetConVarInt(CrouchClass)==1)
	{
		FakeClientCommand(client, "survivor_crouch_speed 130");
		PrintToChat(client, "you have the Crouch ability which lets you move faster while crouching!");
	}
	if(GetConVarInt(CrouchClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:SniperClassTimer(Handle:htimer, any:client)
{
	if(GetConVarInt(SniperClass)==1)
	{
		CreateTimer(0.1, SniperClassTimerZZZ);
	}
}
public Action:SniperClassTimerZZZ(Handle:htimer, any:client)
{
	{
	FakeClientCommand(client, "survivor_speed 150");
	FakeClientCommand(client, "give military_sniper");
	FakeClientCommand(client, "survivor_damage_speed_factor 300f");
	}
	if(GetConVarInt(SniperClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:HeavyClassTimer(Handle:timer, any:client)
{
	if(GetConVarInt(HeavyClass)==1)
	{
		CreateTimer(0.1, HeavyClassTimer11);
	}
}
public Action:HeavyClassTimer11(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 50");
		FakeClientCommand(client, "survivor_damage_speed_factor 2.0f");
		FakeClientCommand(client, "survivor_accuracy_upgrade_factor 0.2");
		FakeClientCommand(client, "first_aid_kit_max_health 300");
		PrintToChat(client, "you have the heavy class which makes it so you run slower but do alot more damage with a gun!!!");
	}
	if(GetConVarInt(HeavyClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:ScoutClassTimer(Handle:htimer, any:client)
{
	if(GetConvarInt(ScoutClass)==1)
	{
		CreateTimer(0.1, ScoutClassTimerDD);
	}
}

public Action:ScoutClassTimerDD(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 350");
		FakeClientCommand(client, "survivor_damage_speed_factor 0.3f");
		PrintToChat(client, "you have the scout class which means you can run 2X faster than normal but also your damage for guns is below normal");
	}
	if(GetConVarInt(ScoutClass)==0)
	{
		return Plugin_Handled;
	}
}


public Action:DemoClassTimer(Handle:htimer, any:client)
{
	if(GetConVarInt(DemoClass)==1)
	{
		CreateTimer(0.1, DemoClassTimer0);
	}
}
public Action:DemoClassTimer0(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 170");
		FakeClientCommand(client, "survivor_damage_speed_factor 1.5f");
		PrintToChat(client, "you have the Demo ability so this means you can do more damage but walk a little slower!");
	}
	if(GetConVarInt(DemoClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:SoldierClassTimer(Handle:htimer, any:client)
{
	if(GetConVarInt(SoldierClass)==1)
	{
		CreateTimer(0.1, SoldierClassTimer1);
	}
}
public Action:SoldierClassTimer1(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 180");
		FakeClientCommand(client, "survivor_damage_speed_factor 3.0f");
		PrintToChat(client, "you have the Soldier ability which means you can do more damage to zombies but you walk slower by a little!");
	}
	if(GetConVarInt(SoldierClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:RacerTimer(Handle:htimer, any:client)
{
	if(GetConVarInt(RacerClass)==1)
	{
		CreateTimer(0.1, RacerTimerT);
	}
}
public Action:RacerTimerT(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 300");
		FakeClientCommand(client, "survivor_damage_speed_factor 0.1f");
	}
	if(GetConVarInt(RacerClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:name[190]
	new Killer = GetConVarInt(event, "attacker");
	GetClientName(Killer, name, sizeof(name));
	PrintToChatAll("Killer %s has just killed the witch so he gets different abilities!!!", name, Killer);
	if(Killer !=0)
	{
		RandomEverything = GetRandomInt(0, 1)
		SetConVarInt(SelfReviveClass, RandomEverything);
		SetConVarInt(SharpShooterClass, RandomEverything);
		SetConVarInt(Medic, RandomEverything);
		SetConVarInt(Domonation, RandomEverything);
		SetConVarInt(CrouchClass, RandomEverything);
		SetConVarInt(SniperClass, RandomEverything);
		SetConVarInt(HeavyClass, RandomEverything);
		SetConVarInt(ScoutClass, RandomEverything);
		SetConVarInt(DemoClass, RandomEverything);
		SetConVarInt(SoldierClass, RandomEverything);
		SetConVarInt(RacerClass, RandomEverything);
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
			return Plugin_Handled;
		}
		if(GetConVarInt(Medic)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(Domonation)==0)
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
		if(GetConVarInt(DemoClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(SoldierClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(RacerClass)==0)
		{
			return Plugin_Handled;
		}
		//now we are going to make the actions avalible with timers!


		if(GetConVarInt(SelfReviveClass)==1)
		{
			CreateTimer(1.0, SelfReviveClassTimerA);
		}
		if(GetConVarInt(SharpShooterClass)==1)
		{
			CreateTimer(1.0, SharpShooterClassTimerS);
		}
		if(GetConVarInt(Medic)==1)
		{
			CreateTimer(1.0, MedicTimerS);
		}
		if(GetConVarInt(Domonation)==1)
		{
			CreateTimer(1.0, DomonationTimerS);
		}
		if(GetConVarInt(CrouchClass)==1)
		{
			CreateTimer(1.0, CrouchClassTimerS);
		}
		if(GetConVarInt(SniperClass)==1)
		{
			CreateTimer(1.0, SniperClassTimerS);
		}
		if(GetConVarInt(HeavyClass)==1)
		{
			CreateTimer(1.0, HeavyClassTimerS);
		}
		if(GetConVarInt(ScoutClass)==1)
		{
			CreateTimer(1.0, ScoutClassTimerS);
		}
		if(GetConVarInt(DemoClass)==1)
		{
			CreateTimer(1.0, DemoClassTimerS);
		}
		if(GetConVarInt(SoldierClass)==1)
		{
			CreateTimer(1.0, SoldierClassTimerS);
		}
		if(GetConVarInt(RacerClass)==1)
		{
			CreateTimer(1.0, RacerTimer);
		}
		if(GetConVarInt(TankSpawnAllowAbilites)==0)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

//ALL TIMERS THAT DO STUFF

public Action:Event_Revive_Begin(Handle:event, const String:name[], bool:dontBroadcast)
{		
	CreateTimer(5.0, ReviveBeginTimerThenEnd);
	return Plugin_Handled;
}

public Action:SharpShooterClassTimerS(Handle:htimer, any:client)
{
	if(GetConVarInt(SharpShooterClass)==1)
	{
		CreateTimer(0.1, SharpShooterClassAbilitiesA);
	}
}
public Action:SharpShooterClassAbilitiesA(Handle:htimer, any:client)
{
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

public Action:MedicTimerS(Handle:event, any:client)
{
	if(GetConVarInt(Medic)==1)
	{
		CreateTimer(0.1, MedicTimerEE);
	}
}

public Action:MedicTimerEE(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "give first_aid_kit");
		FakeClientCommand(client, "first_aid_kit_use_duration 2");
		FakeClientCommand(client, "first_aid_kit_max_heal 150");
		FakeClientCommand(client, "first_aid_heal_percent 1.5");
		PrintToChat(client, "you got the ability Medic which lets you heal 2.5 faster than normal and you can have higher healths such as 100 is max health but now you can have up to 150!");
	}
	if(GetConVarInt(Medic)==0)
	{
		return Plugin_Handled;
	}
}
public Action:DomonationTimerS(Handle:htimer, any:client)
{
	if(GetConVarInt(DomonationClass)==1)
	{
		CreateTimer(0.1, DomonationTimerE);
	}
}
public Action:DomonationTimerE(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_damage_speed_factor 1.0f");
		PrintToChat(client, "you have the Domonaction ability which means you do more damage with explosives such as grenade launchers!");
	}
	if(GetConVarInt(DomonationClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:CrouchClassTimerS(Handle:htimer, any:client)
{
	if(GetConVarInt(CrouchClass)==1)
	{
		FakeClientCommand(client, "survivor_crouch_speed 130");
		PrintToChat(client, "you have the Crouch ability which lets you move faster while crouching!");
	}
	if(GetConVarInt(CrouchClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:SniperClassTimerS(Handle:htimer, any:client)
{
	if(GetConVarInt(SniperClass)==1)
	{
		CreateTimer(0.1, SniperClassTimerZZZ);
	}
}
public Action:SniperClassTimerZZZ(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 150");
		FakeClientCommand(client, "give military_sniper");
		FakeClientCommand(client, "survivor_damage_speed_factor 300f");
	}
	if(GetConVarInt(SniperClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:HeavyClassTimerS(Handle:timer, any:client)
{
	if(GetConVarInt(HeavyClass)==1)
	{
		CreateTimer(0.1, HeavyClassTimer111);
	}
	return Plugin_Continue;
}

public Action:HeavyClassTimer111(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 50");
		FakeClientCommand(client, "survivor_damage_speed_factor 2.0f");
		FakeClientCommand(client, "survivor_accuracy_upgrade_factor 0.2");
		FakeClientCommand(client, "first_aid_kit_max_health 300");
		PrintToChat(client, "you have the heavy class which makes it so you run slower but do alot more damage with a gun!!!");
	}
	if(GetConVarInt(HeavyClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:ScoutClassTimerS(Handle:htimer, any:client)
{
	if(GetConVarInt(ScoutClass)==1)
	{
		CreateTimer(0.1, ScoutClassTimerDD);
	}
}
public Action:ScoutClassTimerDD(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 350");
		FakeClientCommand(client, "survivor_damage_speed_factor 0.3f");
		PrintToChat(client, "you have the scout class which means you can run 2X faster than normal but also your damage for guns is below normal");
	}
	if(GetConVarInt(ScoutClass)==0)
	{
		return Plugin_Handled;
	}
}

public Action:DemoClassTimerS(Handle:htimer, any:client)
{
	if(GetConVarInt(DemoClass)==1)
	{
		CreateTimer(0.1, DemoClassTimer0);
	}
}
public Action:DemoClassTimer0(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 170");
		FakeClientCommand(client, "survivor_damage_speed_factor 1.5f");
		PrintToChat(client, "you have the Demo ability so this means you can do more damage but walk a little slower!");
	}
	if(GetConVarInt(DemoClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:SoldierClassTimerS(Handle:htimer, any:client)
{
	if(GetConVarInt(SoldierClass)==1)
	{
		CreateTimer(0.1, SoldierClassTimer1);
	}
}
public Action:SoldierClassTimer1(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 180");
		FakeClientCommand(client, "survivor_damage_speed_factor 3.0f");
		PrintToChat(client, "you have the Soldier ability which means you can do more damage to zombies but you walk slower by a little!");
	}
	if(GetConVarInt(SoldierClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:RacerTimerS(Handle:htimer, any:client)
{
	if(GetConVarInt(RacerClass)==1)
	{
		CreateTimer(0.1, RacerTimerT);
	}
}
public Action:RacerTimerT(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 300");
		FakeClientCommand(client, "survivor_damage_speed_factor 0.1f");
	}
	if(GetConVarInt(RacerClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Event_Tank_Killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:name[190]
	new Killer = GetEventInt(event, "attacker");
	GetClientName(Killer, name, sizeof(name));
	PrintToChatAll(" %s has just killed the witch so he gets different abilities!!!", Killer, name);
	if(Killer !=0)
	{
		RandomEverything = GetRandomInt(0, 1)
		SetConVarInt(SelfReviveClass, RandomEverything);
		SetConVarInt(SharpShooterClass, RandomEverything);
		SetConVarInt(Medic, RandomEverything);
		SetConVarInt(DomonationClass, RandomEverything);
		SetConVarInt(CrouchClass, RandomEverything);
		SetConVarInt(SniperClass, RandomEverything);
		SetConVarInt(HeavyClass, RandomEverything);
		SetConVarInt(ScoutClass, RandomEverything);
		SetConVarInt(DemoClass, RandomEverything);
		SetConVarInt(SoldierClass, RandomEverything);
		SetConVarInt(RacerClass, RandomEverything);
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
			return Plugin_Handled;
		}
		if(GetConVarInt(Medic)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(Domonation)==0)
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
		if(GetConVarInt(DemoClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(SoldierClass)==0)
		{
			return Plugin_Handled;
		}
		if(GetConVarInt(RacerClass)==0)
		{
			return Plugin_Handled;
		}
		//now we are going to make the actions avalible with timers!


		if(GetConVarInt(SelfReviveClass)==1)
		{
			CreateTimer(1.0, SelfReviveClassTimerD);
		}
		if(GetConVarInt(SharpShooterClass)==1)
		{
			CreateTimer(1.0, SharpShooterClassTimerD);
		}
		if(GetConVarInt(Medic)==1)
		{
			CreateTimer(1.0, MedicTimerD);
		}
		if(GetConVarInt(Domonation)==1)
		{
			CreateTimer(1.0, DomonactionTimerD);
		}
		if(GetConVarInt(CrouchClass)==1)
		{
			CreateTimer(1.0, CrouchClassTimerD);
		}
		if(GetConVarInt(SniperClass)==1)
		{
			CreateTimer(1.0, SniperClassTimerD);
		}
		if(GetConVarInt(HeavyClass)==1)
		{
			CreateTimer(1.0, HeavyClassTimerD);
		}
		if(GetConVarInt(ScoutClass)==1)
		{
			CreateTimer(1.0, ScoutClassTimerD);
		}
		if(GetConVarInt(DemoClass)==1)
		{
			CreateTimer(1.0, DemoClassTimerD);
		}
		if(GetConVarInt(SoldierClass)==1)
		{
			CreateTimer(1.0, SoldierClassTimerD);
		}
		if(GetConVarInt(RacerClass)==1)
		{
			CreateTimer(1.0, RacerTimer);
		}
		if(GetConVarInt(TankKilledAllowAbilites)==0)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Event_Revive_Begin(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(5.0, ReviveBeginTimerThenEnd);
}
public Action:ReviveBeginTimerThenEnd(Handle:htimer, any:client)
{
	GetConVarInt(event, "Event_Revive-End");
	if(GetConVarInt(Event_Revive_End)==1)
	{
		PrintToChat(client, "you have been revived by yourself from using the ability SelfReviveClass!");
	}
}
public Event_Player_Incap(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, PlayerIncapTime);
}
//ALL TIMERS THAT DO STUFF
public Action:SelfReviveClassTimerD(Handle:htimer, any:client)
{
	if(GetConVarInt(SelfReviveClass)==1)
	{
	new event = GetEventInt(event, "Event_Player_Incap");
	}
}
		
		
		public Action:PlayerIncapTime(Handle:timer, any:client)
		{
		new event2 = GetEventInt(event2, "Event_Revive_End");
		}
	}
	if(GetConVarInt(SelfReviveClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:SharpShooterClassTimerD(Handle:htimer, any:client)
{
	if(GetConVarInt(SharpShooterClass)==1)
	{
		CreateTimer(0.1, SharpShooterClassAbilities);
	}
}
public Action:SharpShooterClassAbilities(Handle:htimer, any:client)
{
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

public Action:MedicTimerD(Handle:event, any:client)
{
	if(GetConVarInt(Medic)==1)
	{
		CreateTimer(0.1, MedicTimerZ);
	}
}
public Action:MedicTimerZ(Handle:htimer, any:client)
{
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
public Action:DomonactionTimerD(Handle:htimer, any:client)
{
	if(GetConVarInt(DomonactionClass)==1)
	{
		CreateTimer(0.1, DomonationTimer*);
	}
}
public Action:DomonactionTimer*(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_damage_speed_factor 1.0f");
		PrintToChat(client, "you have the Domonaction ability which means you do more damage with explosives such as grenade launchers!");
	}
	if(GetConVarInt(DomonactionClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:CrouchClassTimerD(Handle:htimer, any:client)
{
	if(GetConVarInt(CrouchClass)==1)
	{
		FakeClientCommand(client, "survivor_crouch_speed 130");
		PrintToChat(client, "you have the Crouch ability which lets you move faster while crouching!");
	}
	if(GetConVarInt(CrouchClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:SniperClassTimerD(Handle:htimer, any:client)
{
	if(GetConVarInt(SniperClass)==1)
	{
		CreateTimer(0.1, SniperClassTimerZZZ);
	}
}
public Action:SniperClassTimerZZZ(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 150");
		FakeClientCommand(client, "give military_sniper");
		FakeClientCommand(client, "survivor_damage_speed_factor 300f");
	}
	if(GetConVarInt(SniperClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:HeavyClassTimerD(Handle:timer, any:client)
{
	if(GetConVarInt(HeavyClass)==1)
	{
		CreateTimer(0.1, HeavyClassTimer11);
	}
}
public Action:HeavyClassTimer11(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 50");
		FakeClientCommand(client, "survivor_damage_speed_factor 2.0f");
		FakeClientCommand(client, "survivor_accuracy_upgrade_factor 0.2");
		FakeClientCommand(client, "first_aid_kit_max_health 300");
		PrintToChat(client, "you have the heavy class which makes it so you run slower but do alot more damage with a gun!!!");
	}
	if(GetConVarInt(HeavyClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:ScoutClassTimerD(Handle:htimer, any:client)
{
	if(GetConvarInt(ScoutClass)==1)
	{
		CreateTimer(0.1, ScoutClassTimerDD);
	}
}
public Action:ScoutClassTimerDD(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 350");
		FakeClientCommand(client, "survivor_damage_speed_factor 0.3f");
		PrintToChat(client, "you have the scout class which means you can run 2X faster than normal but also your damage for guns is below normal");
	}
	if(GetConVarInt(ScoutClass)==0)
	{
		return Plugin_Handled;
	}
}

public Action:DemoClassTimerD(Handle:htimer, any:client)
{
	if(GetConVarInt(DemoClass)==1)
	{
		CreateTimer(0.1, DemoClassTimer0);
	}
}
public Action:DemoClassTimer0(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 170");
		FakeClientCommand(client, "survivor_damage_speed_factor 1.5f");
		PrintToChat(client, "you have the Demo ability so this means you can do more damage but walk a little slower!");
	}
	if(GetConVarInt(DemoClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:SoldierClassTimerD(Handle:htimer, any:client)
{
	if(GetConvarInt(SoldierClass)==1)
	{
		CreatTimer(0.1, SoldierClassTimer1);
	}
}
public Action:SoldierClassTimer1(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 180");
		FakeClientCommand(client, "survivor_damage_speed_factor 3.0f");
		PrintToChat(client, "you have the Soldier ability which means you can do more damage to zombies but you walk slower by a little!");
	}
	if(GetConVarInt(SoldierClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:RacerTimerD(Handle:htimer, any:client)
{
	if(GetConVarInt(Racer)==1)
	{
		CreateTimer(0.1, RacerTimerT);
	}
}
public Action:RacerTimerT(Handle:htimer, any:client)
{
	{
		FakeClientCommand(client, "survivor_speed 300");
		FakeClientCommand(client, "survivor_damage_speed_factor 0.1f");
	}
	if(GetConVarInt(RacerClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Event_Witch_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
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
			CreateTimer(1.0, SelfReviveClassTimerB);
		}
		if(GetConVarInt(SharpShooterClass)==1)
		{
			CreateTimer(1.0, SharpShooterClassTimerB);
		}
		if(GetConVarInt(Medic)==1)
		{
			CreateTimer(1.0, MedicTimerB);
		}
		if(GetConVarInt(Domonaction)==1)
		{
			CreateTimer(1.0, DomonactionTimerB);
		}
		if(GetConVarInt(CrouchClass)==1)
		{
			CreateTimer(1.0, CrouchClassTimerB);
		}
		if(GetConVarInt(SniperClass)==1)
		{
			CreateTimer(1.0, SniperClassTimerB);
		}
		if(GetConVarInt(HeavyClass)==1)
		{
			CreateTimer(1.0, HeavyClassTimerB);
		}
		if(GetConVarInt(ScoutClass)==1)
		{
			CreateTimer(1.0, ScoutClassTimerB);
		}
		if(GetConVar(DemoClass)==1)
		{
			CreateTimer(1.0, DemoClassTimerB);
		}
		if(GetConVarInt(SoldierClass)==1)
		{
			CreateTimer(1.0, SoldierClassTimerB);
		}
		if(GetConVarInt(Racer)==1)
		{
			CreateTimer(1.0, RacerTimer);
		}
		if(GetConVarInt(WitchSpawnAllowAbilites)==0)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public Event_Player_Incap(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, PlayerIncapTime);
}
//ALL TIMERS THAT DO STUFF
public Action:SelfReviveClassTimerB(Handle:htimer, any:client)
{
	if(GetConVarInt(SelfReviveClass)==1)
	{
		new event = GetEventInt(event, "Event_Player_Incap");
	}
}
		
		
public Action:PlayerIncapTime(Handle:timer, any:client)
{
	new event2 = GetEventInt(event2, "Event_Revive_End");
}

public Event_Revive_Begin(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(5.0, ReviveBeginTimerThenEnd);
}

public Action:ReviveBeginTimerThenEnd(Handle:htimer, any:client)
{
	GetConVarInt(event, "Event_Revive-End");
	if(GetConVarInt(Event_Revive_End)==1)
	{
		PrintToChat(client, "you have been revived by yourself from using the ability SelfReviveClass!");
	}
}
	
	if(GetConVarInt(SelfReviveClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:SharpShooterClassB(Handle:htimer, any:client)
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

public Action:MedicTimerB(Handle:event, any:client)
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
public Action:DomonactionTimerB(Handle:htimer, any:client)
{
	if(GetConVarInt(DomonactionClass)==1)
	{
		CreateTimer(0.1, DomonationTimer*);
	}
	public Action:DomonactionTimer*(Handle:htimer, any:client)
	{
		FakeClientCommand(client, "survivor_damage_speed_factor 1.0f");
		PrintToChat(client, "you have the Domonaction ability which means you do more damage with explosives such as grenade launchers!");
	}
	if(GetConVarInt(DomonactionClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:CrouchClassTimerB(Handle:htimer, any:client)
{
	if(GetConVarInt(CrouchClass)==1)
	{
		FakeClientCommand(client, "survivor_crouch_speed 130");
		PrintToChat(client, "you have the Crouch ability which lets you move faster while crouching!");
	}
	if(GetConVarInt(CrouchClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:SniperClassTimerB(Handle:htimer, any:client)
{
	if(GetConVarInt(SniperClass)==1)
	{
		CreateTimer(0.1, SniperClassTimerZZZ);
	}
	public Action:SniperClassTimerZZZ(Handle:htimer, any:client)
	{
		FakeClientCommand(client, "survivor_speed 150");
		FakeClientCommand(client, "give military_sniper");
		FakeClientCommand(client, "survivor_damage_speed_factor 300f");
	}
	if(GetConVarInt(SniperClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:HeavyClassTimerB(Handle:timer, any:client)
{
	if(GetConVarInt(HeavyClass)==1)
	{
		CreateTimer(0.1, HeavyClassTimer11);
	}
	public Action:HeavyClassTimer11(Handle:htimer, any:client)
	{
		FakeClientCommand(client, "survivor_speed 50");
		FakeClientCommand(client, "survivor_damage_speed_factor 2.0f");
		FakeClientCommand(client, "survivor_accuracy_upgrade_factor 0.2");
		FakeClientCommand(client, "first_aid_kit_max_health 300");
		PrintToChat(client, "you have the heavy class which makes it so you run slower but do alot more damage with a gun!!!");
	}
	if(GetConVarInt(HeavyClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:ScoutClassTimerB(Handle:htimer, any:client)
{
	if(GetConvarInt(ScoutClass)==1)
	{
		CreateTimer(0.1, ScoutClassTimerDD);
	}
	public Action:ScoutClassTimerDD(Handle:htimer, any:client)
	{
		FakeClientCommand(client, "survivor_speed 350");
		FakeClientCommand(client, "survivor_damage_speed_factor 0.3f");
		PrintToChat(client, "you have the scout class which means you can run 2X faster than normal but also your damage for guns is below normal");
	}
	if(GetConVarInt(ScoutClass)==0)
	{
		return Plugin_Handled;
	}
}

public Action:DemoClassTimerB(Handle:htimer, any:client)
{
	if(GetConVarInt(DemoClass)==1)
	{
		CreateTimer(0.1, DemoClassTimer0);
	}
	public Action:DemoClassTimer0(Handle:htimer, any:client)
	{
		FakeClientCommand(client, "survivor_speed 170");
		FakeClientCommand(client, "survivor_damage_speed_factor 1.5f");
		PrintToChat(client, "you have the Demo ability so this means you can do more damage but walk a little slower!");
	}
	if(GetConVarInt(DemoClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:SoldierClassTimerB(Handle:htimer, any:client)
{
	if(GetConvarInt(SoldierClass)==1)
	{
		CreatTimer(0.1, SoldierClassTimer1);
	}
	public Action:SoldierClassTimer1(Handle:htimer, any:client)
	{
		FakeClientCommand(client, "survivor_speed 180");
		FakeClientCommand(client, "survivor_damage_speed_factor 3.0f");
		PrintToChat(client, "you have the Soldier ability which means you can do more damage to zombies but you walk slower by a little!");
	}
	if(GetConVarInt(SoldierClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:RacerTimerB(Handle:htimer, any:client)
{
	if(GetConVarInt(Racer)==1)
	{
		CreateTimer(0.1, RacerTimerT);
	}
	public Action:RacerTimerT(Handle:htimer, any:client)
	{
		FakeClientCommand(client, "survivor_speed 300");
		FakeClientCommand(client, "survivor_damage_speed_factor 0.1f");
	}
	if(GetConVarInt(RacerClass)==0)
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
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
	AddMenuItem(menu, "option4", "SniperClass");
	AddMenuItem(menu, "option5", "CrouchClass");
	AddMenuItem(menu, "option6", "HeavyClass");
	AddMenuItem(menu, "option7", "ScoutClass");
	AddMenuItem(menu, "option8", "DemoClass");
	AddMenuItem(menu, "option9", "SoldierClass");
	AddMenuItem(menu, "option10", "RacerClass");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, i, MENU_TIMER_FOREVER);
	}
}

public Action:MenuAbility(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0: //self revive class
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
					if(GetConVarInt(Event_Revive_End)==1)
					{
						PrintToChat(client, "you have been revived by yourself from using the ability SelfReviveClass!");
					}
				}
				if(GetConVarInt(SelfReviveClass)==0)
				{
					PrintToChat(client, "the server admin has disabled this ability so you cant have it.");
					return Plugin_Handled;
				}
			}
			case 1: //sharpshooter
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
					PrintToChat(client, "the server admin has disabled this ability so you cant have it");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}
			case 2: //Medic Class
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
					PrintToChat(client, "the server admin has disabled this ability so you cant have it");
					return Plugin_Handled;
				}
			}
			case 3: //domonation class
			{
				if(GetConVarInt(DomonactionClass)==1)
				{
					CreateTimer(0.1, DomonationTimer*);
				}
				public Action:DomonactionTimer*(Handle:htimer, any:client)
				{
					FakeClientCommand(client, "survivor_damage_speed_factor 1.0f");
					PrintToChat(client, "you have the Domonaction ability which means you do more damage with explosives such as grenade launchers!");
				}
				if(GetConVarInt(DomonactionClass)==0)
				{
					PrintToChat(client, "the server admin has disabled this ability so you cant have it");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}
			case 4: //sniper class
			{
				if(GetConVarInt(SniperClass)==1)
				{
					CreateTimer(0.1, SniperClassTimerZZZ);
				}
				public Action:SniperClassTimerZZZ(Handle:htimer, any:client)
				{
					FakeClientCommand(client, "survivor_speed 150");
					FakeClientCommand(client, "give military_sniper");
					FakeClientCommand(client, "survivor_damage_speed_factor 300f");
				}
				if(GetConVarInt(SniperClass)==0)
				{
					PrintToChat(client, "the server admin has disabled this ability so you can have it");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}
			case 5: //crouch class
			{
				if(GetConVarInt(CrouchClass)==1)
				{
					FakeClientCommand(client, "survivor_crouch_speed 130");
					PrintToChat(client, "you have the Crouch ability which lets you move faster while crouching!");
				}
				if(GetConVarInt(CrouchClass)==0)
				{
					PrintToChat(client, "the server admin has disabled this ability so you cant have it");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}
			case 6: // heavy class
			{
				if(GetConVarInt(HeavyClass)==1)
				{
					CreateTimer(0.1, HeavyClassTimer11);
				}
				public Action:HeavyClassTimer11(Handle:htimer, any:client)
				{
					FakeClientCommand(client, "survivor_speed 50");
					FakeClientCommand(client, "survivor_damage_speed_factor 2.0f");
					FakeClientCommand(client, "survivor_accuracy_upgrade_factor 0.2");
					FakeClientCommand(client, "first_aid_kit_max_health 300");
					PrintToChat(client, "you have the heavy class which makes it so you run slower but do alot more damage with a gun!!!");
				}
				if(GetConVarInt(HeavyClass)==0)
				{
					PrintToChat(client, "the server admin has disabled this ability so you cant have it");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}
			case 7: //scout class
			{
				if(GetConvarInt(ScoutClass)==1)
				{
					CreateTimer(0.1, ScoutClassTimerDD);
				}
				public Action:ScoutClassTimerDD(Handle:htimer, any:client)
				{
					FakeClientCommand(client, "survivor_speed 350");
					FakeClientCommand(client, "survivor_damage_speed_factor 0.3f");
					PrintToChat(client, "you have the scout class which means you can run 2X faster than normal but also your damage for guns is below normal");
				}
				if(GetConVarInt(ScoutClass)==0)
				{
					PrintToChat(client, "the server admin has disabled this ability so you cant have it");
					return Plugin_Handled;
				}
			}
			case 8: //Demo Class
			{
				if(GetConVarInt(DemoClass)==1)
				{
					CreateTimer(0.1, DemoClassTimer0);
				}
				public Action:DemoClassTimer0(Handle:htimer, any:client)
				{
					FakeClientCommand(client, "survivor_speed 170");
					FakeClientCommand(client, "survivor_damage_speed_factor 1.5f");
					PrintToChat(client, "you have the Demo ability so this means you can do more damage but walk a little slower!");
				}
				if(GetConVarInt(DemoClass)==0)
				{
					PrintToChat(client, "the server admin has disabled this ability so you cant have it");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}
			case 9: //soldier class
			{
				if(GetConvarInt(SoldierClass)==1)
				{
					CreatTimer(0.1, SoldierClassTimer1);
				}
				public Action:SoldierClassTimer1(Handle:htimer, any:client)
				{
					FakeClientCommand(client, "survivor_speed 180");
					FakeClientCommand(client, "survivor_damage_speed_factor 3.0f");
					PrintToChat(client, "you have the Soldier ability which means you can do more damage to zombies but you walk slower by a little!");
				}
				if(GetConVarInt(SoldierClass)==0)
				{
					PrintToChat(client, "the server admin has disabled this ability so you cant have it");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}
			case 10: //racer class
			{
				if(GetConVarInt(Racer)==1)
				{
					CreateTimer(0.1, RacerTimerT);
				}
				public Action:RacerTimerT(Handle:htimer, any:client)
				{
					FakeClientCommand(client, "survivor_speed 300");
					FakeClientCommand(client, "survivor_damage_speed_factor 0.1f");
				}
				if(GetConVarInt(RacerClass)==0)
				{
					PrintToChat(client, "the server admin has disabled this abilty so you cant have it");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}
		}
	}
}

public Action:Event_Player_Spawn(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= GetMaxClients(); i++) 
		if (IsClientInGame(i))
		{
			PrintToChat(i, "this server runs ABILITIES so you may get random abilties anytime!!!");
		}
}

public Action:Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(3.0, ReloadPlugin);
	return Plugin-Handled;
}
			
			
			
			
			
			
			
			
			
			
				
			
			
		
			







			


