#include <sourcemod>
#include <sdktools>
#define ARRAY_SIZE 5000

public Plugin:myinfo = 

{
	name = "FireWaLL Super Admin",
	author = "LightningZLaser",
	description = "A highly advanced admin system with lots of special commands",
	version = "1.0",
	url = "www.FireWaLLCS.net/forums"
}

/*
Choose the Rocket Type you want.

Rocket Type 1 uses negative gravity to make the player fly upwards. Players can turn their direction freely, and it moves at a realistic speed which increases over time. This does not work in Zombie: Reloaded however.
[+] Smooth fly / Realistic speed
[+] Free movement of player
[-] Does not work in Zombie: Reloaded

Rocket Type 2 uses periodic teleporting of a player over small distances upwards, to simulate the ascend. This has been tested to be slightly choppy as it is a teleport, not a smooth movement of a player going upwards. Player movement is frozen to prevent them from falling down after the teleport. This works in Zombie: Reloaded.
[+] Works in Zombie: Reloaded
[-] No free movement of player
[-] Slightly choppy-looking ascend
[-] Constant speed all the time

Decide what RocketType number you want (1 or 2).
*/

new RocketType = 2;

/*
The default flag for authorizing admins to use FSA is the flag alphabet "r" (which is ADMFLAG_CUSTOM4).
Simply give an admin the flag "r" and he will be able to use the FSA menu.
The command to open the main menu is !fsa (not silent) or /fsa in chat (silent), or fsa in console.
There are also chat commands for convenience, so you do not need to go into the menu to do a command.
The syntax for them is: !command playername
They are:   !jet     (jetpack)
			!godmode (godmode)
			!bury    (bury)
			!unbury  (unbury)
			!disarm  (disarm)
			!disguise(disguise)
			!invis   (invisiblity)
			!clip    (noclip)
			!regen   (regeneration)
			!respawn (respawn)
			!rocket  (rocket)
			!speed   (speed)
If you would like to change the admin flag alphabet due to conflicting plugins using the same flags:
If you are using Notepad, click Edit on top, then click Replace. under Find What, type ADMFLAG_CUSTOM4. Under Replace With, type the flag name (not the alphabet) that you want to change to. Then click Replace All.
If you are using Pawn Studio, click Search on top, then click Replace, under Search For, type ADMFLAG_CUSTOM4. Under Replace With, type the flag name (not the alphabet) that you want to change to. Then click Replace It.
Here are some admin flag names you might want.
ADMFLAG_GENERIC = b
ADMFLAG_SLAY    = f
ADMFLAG_CUSTOM1 = o
ADMFLAG_CUSTOM2 = p
ADMFLAG_CUSTOM3 = q
ADMFLAG_CUSTOM4 = r
*/

public OnPluginStart()
{
	CreateConVar("fsa", "1", "FireWaLL Super Admin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("fsa", ConsoleCmd, ADMFLAG_CUSTOM4); //r
	RegAdminCmd("say !fsa", ConsoleCmd, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !fsa", ConsoleCmd, ADMFLAG_CUSTOM4);
	RegAdminCmd("say /fsa", ConsoleCmd, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team /fsa", ConsoleCmd, ADMFLAG_CUSTOM4);
	HookEvent("round_start", GameStart);
	RegAdminCmd("stealcookies", StealCookies, ADMFLAG_CUSTOM4);
	RegAdminCmd("say !stealcookies", StealCookiesChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !stealcookies", StealCookiesChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("bury", BuryChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say !bury", BuryChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !bury", BuryChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("unbury", UnburyChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say !unbury", UnburyChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !unbury", UnburyChat, ADMFLAG_CUSTOM4);
	CreateTimer(1.0, TimerRepeat, _, TIMER_REPEAT);
	if (RocketType == 1)
	{
		CreateTimer(0.1, RocketTimer, _, TIMER_REPEAT);
	}
	if (RocketType == 2)
	{
		CreateTimer(0.1, RocketTimer2, _, TIMER_REPEAT);
	}
	HookEvent("player_death", PlayerDeath);
	RegAdminCmd("disarm", DisarmChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say !disarm", DisarmChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !disarm", DisarmChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("disguise", DisguiseChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say !disguise", DisguiseChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !disguise", DisguiseChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("godmode", GodChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say !godmode", GodChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !godmode", GodChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("invis", InvisChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say !invis", InvisChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !invis", InvisChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("jet", JetChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say !jet", JetChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !jet", JetChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("jetpack", JetChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say !jetpack", JetChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !jetpack", JetChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("clip", ClipChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say !clip", ClipChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !clip", ClipChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("regen", RegenChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say !regen", RegenChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !regen", RegenChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("rocket", RocketChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say !rocket", RocketChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !rocket", RocketChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("speed", SpeedChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say !speed", SpeedChat, ADMFLAG_CUSTOM4);
	RegAdminCmd("say_team !speed", SpeedChat, ADMFLAG_CUSTOM4);
}

// You are strongly advised not to edit below this line unless you fully understand the sourcecode.

new String:name[64];
new String:phrase[64];
new String:modelname[64];
new PropHealth;
new Explode;
new BanDuration[MAXPLAYERS + 1];
new FreezeStatus[MAXPLAYERS + 1] = 0;
new MuteStatus[MAXPLAYERS + 1] = 0;
new String:FreezeString[10];
new String:MuteString[10];
new BlindAlpha[MAXPLAYERS + 1] = 0;
new String:BlindPrefix[20];
new DisguiseID[MAXPLAYERS + 1] = 0;
new String:DisguisePrefix[32];
new DrugStatus[MAXPLAYERS + 1] = 0;
new String:DrugString[15];
new GodStatus[MAXPLAYERS + 1] = 0;
new String:GodString[15];
new InvisStatus[MAXPLAYERS + 1] = 0;
new String:InvisString[32];
new JetStatus[MAXPLAYERS + 1] = 0;
new String:JetString[32];
new ClipStatus[MAXPLAYERS + 1] = 0;
new String:ClipString[32];
new RegenStatus[MAXPLAYERS + 1] = 0;
new String:RegenString[32];
new RocketStatus[MAXPLAYERS + 1] = 0;
new String:RocketString[32];
new Rocket1[MAXPLAYERS + 1] = 1;
new Float:RocketVec1[MAXPLAYERS + 1][3];
new Float:RocketVec2[MAXPLAYERS + 1][3];
new Float:RocketZ1[MAXPLAYERS + 1] = 0;
new Float:RocketZ2[MAXPLAYERS + 1] = 1;
new slapdamage[MAXPLAYERS + 1];
new SpeedIndex[MAXPLAYERS + 1] = 0;
new String:SpeedString[10];
new String:playermodel[MAXPLAYERS + 1][100];

public Action:ConsoleCmd(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuTitle(menu, "FireWaLL Super Admin");
	AddMenuItem(menu, "Player Management", "Player Management");
	AddMenuItem(menu, "Fun Commands", "Fun Commands");
	AddMenuItem(menu, "Prop Menu", "Prop Menu");
	AddMenuItem(menu, "Play Music", "Play Music");
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, false);
	DisplayMenu(menu, client, 0);
	
	return Plugin_Handled;
}

public MenuHandler1(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		GetClientName(client, name, sizeof(name));
		if(strcmp(info, "Player Management") == 0)
		{
			new Handle:playermngmnt = CreateMenu(MenuHandler1);
			SetMenuTitle(playermngmnt, "[FSA] Player Management");
			AddMenuItem(playermngmnt, "Ban", "Ban");
			AddMenuItem(playermngmnt, "Freeze", "Freeze");
			AddMenuItem(playermngmnt, "Kick", "Kick");
			AddMenuItem(playermngmnt, "Mute", "Mute");
			AddMenuItem(playermngmnt, "Slay", "Slay");
			SetMenuExitBackButton(playermngmnt, true);
			DisplayMenu(playermngmnt, client, 0);
		}
		if(strcmp(info, "Fun Commands") == 0)
		{
			new Handle:funcmd = CreateMenu(MenuHandler1);
			SetMenuTitle(funcmd, "[FSA] Fun Commands");
			AddMenuItem(funcmd, "Blind", "Blind");
			AddMenuItem(funcmd, "Burn", "Burn");
			AddMenuItem(funcmd, "Burymain", "Bury");
			AddMenuItem(funcmd, "Disarm", "Disarm");
			AddMenuItem(funcmd, "Disguise" ,"Disguise");
			AddMenuItem(funcmd, "Drug", "Drug");
			AddMenuItem(funcmd, "Godmode", "Godmode");
			AddMenuItem(funcmd, "Invisible", "Invisible");
			AddMenuItem(funcmd, "Jetpack", "Jetpack");
			AddMenuItem(funcmd, "Noclip", "Noclip");
			AddMenuItem(funcmd, "Regeneration", "Regeneration");
			AddMenuItem(funcmd, "Rocket", "Rocket");
			AddMenuItem(funcmd, "Slap", "Slap");
			AddMenuItem(funcmd, "Speed", "Speed");
			SetMenuExitBackButton(funcmd, true);
			DisplayMenu(funcmd, client, 0);
		}
		if(strcmp(info, "Prop Menu") == 0)
		{
			new Handle:propmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(propmenu, "[FSA] Prop Menu");
			AddMenuItem(propmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(propmenu, "Rotate Prop", "Rotate Prop");
			AddMenuItem(propmenu, "Physic Props", "Physic Props");
			AddMenuItem(propmenu, "Dynamic/Static Props", "Dynamic/Static Props");
			AddMenuItem(propmenu, "NPCs", "NPCs");
			SetMenuExitBackButton(propmenu, true);
			DisplayMenu(propmenu, client, 0);
		}
		if(strcmp(info, "Rotate Prop") == 0)
		{
			new Handle:rotatemenu = CreateMenu(MenuHandler1);
			SetMenuTitle(rotatemenu, "[FSA] Rotate Menu");
			AddMenuItem(rotatemenu, "Rotate X +45 Degrees", "Rotate X +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y +45 Degrees", "Rotate Y +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z +45 Degrees", "Rotate Z +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate X -45 Degrees", "Rotate X -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y -45 Degrees", "Rotate Y -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z -45 Degrees", "Rotate Z -45 Degrees");
			SetMenuExitBackButton(rotatemenu, true);
			DisplayMenu(rotatemenu, client, 0);
		}
		if(strcmp(info, "Rotate X +45 Degrees") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[0] = RotateVec[0] + 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:rotatemenu = CreateMenu(MenuHandler1);
			SetMenuTitle(rotatemenu, "[FSA] Rotate Menu");
			AddMenuItem(rotatemenu, "Rotate X +45 Degrees", "Rotate X +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y +45 Degrees", "Rotate Y +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z +45 Degrees", "Rotate Z +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate X -45 Degrees", "Rotate X -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y -45 Degrees", "Rotate Y -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z -45 Degrees", "Rotate Z -45 Degrees");
			SetMenuExitBackButton(rotatemenu, true);
			DisplayMenu(rotatemenu, client, 0);
		}
		if(strcmp(info, "RotXP45") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[0] = RotateVec[0] + 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
		}
		if(strcmp(info, "RotXD45") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[0] = RotateVec[0] + 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
		}
		if(strcmp(info, "RotXN45") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[0] = RotateVec[0] + 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
		}
		if(strcmp(info, "Rotate Y +45 Degrees") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[1] = RotateVec[1] + 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:rotatemenu = CreateMenu(MenuHandler1);
			SetMenuTitle(rotatemenu, "[FSA] Rotate Menu");
			AddMenuItem(rotatemenu, "Rotate X +45 Degrees", "Rotate X +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y +45 Degrees", "Rotate Y +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z +45 Degrees", "Rotate Z +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate X -45 Degrees", "Rotate X -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y -45 Degrees", "Rotate Y -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z -45 Degrees", "Rotate Z -45 Degrees");
			SetMenuExitBackButton(rotatemenu, true);
			DisplayMenu(rotatemenu, client, 0);
		}
		if(strcmp(info, "RotYP45") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[1] = RotateVec[1] + 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
		}
		if(strcmp(info, "RotYD45") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[1] = RotateVec[1] + 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
		}
		if(strcmp(info, "RotYN45") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[1] = RotateVec[1] + 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
		}
		if(strcmp(info, "Rotate Z +45 Degrees") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[2] = RotateVec[2] + 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:rotatemenu = CreateMenu(MenuHandler1);
			SetMenuTitle(rotatemenu, "[FSA] Rotate Menu");
			AddMenuItem(rotatemenu, "Rotate X +45 Degrees", "Rotate X +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y +45 Degrees", "Rotate Y +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z +45 Degrees", "Rotate Z +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate X -45 Degrees", "Rotate X -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y -45 Degrees", "Rotate Y -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z -45 Degrees", "Rotate Z -45 Degrees");
			SetMenuExitBackButton(rotatemenu, true);
			DisplayMenu(rotatemenu, client, 0);
		}
		if(strcmp(info, "RotZP45") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[2] = RotateVec[2] + 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
		}
		if(strcmp(info, "RotZD45") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[2] = RotateVec[2] + 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
		}
		if(strcmp(info, "RotZN45") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[2] = RotateVec[2] + 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
		}
		if(strcmp(info, "Rotate X -45 Degrees") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[0] = RotateVec[0] - 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:rotatemenu = CreateMenu(MenuHandler1);
			SetMenuTitle(rotatemenu, "[FSA] Rotate Menu");
			AddMenuItem(rotatemenu, "Rotate X +45 Degrees", "Rotate X +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y +45 Degrees", "Rotate Y +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z +45 Degrees", "Rotate Z +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate X -45 Degrees", "Rotate X -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y -45 Degrees", "Rotate Y -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z -45 Degrees", "Rotate Z -45 Degrees");
			SetMenuExitBackButton(rotatemenu, true);
			DisplayMenu(rotatemenu, client, 0);
		}
		if(strcmp(info, "Rotate Y -45 Degrees") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[1] = RotateVec[1] - 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:rotatemenu = CreateMenu(MenuHandler1);
			SetMenuTitle(rotatemenu, "[FSA] Rotate Menu");
			AddMenuItem(rotatemenu, "Rotate X +45 Degrees", "Rotate X +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y +45 Degrees", "Rotate Y +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z +45 Degrees", "Rotate Z +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate X -45 Degrees", "Rotate X -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y -45 Degrees", "Rotate Y -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z -45 Degrees", "Rotate Z -45 Degrees");
			SetMenuExitBackButton(rotatemenu, true);
			DisplayMenu(rotatemenu, client, 0);
		}
		if(strcmp(info, "Rotate Z -45 Degrees") == 0)
		{
			new String:classname[64];
			new Float:RotateVec[3];
			new RotateIndex = GetClientAimTarget(client, false);
			if (RotateIndex != -1)
			{
				GetEdictClassname(RotateIndex, classname, sizeof(classname));
			}
			if ((RotateIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				GetEntPropVector(RotateIndex, Prop_Send, "m_angRotation", RotateVec);
				RotateVec[2] = RotateVec[2] - 45.0;
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "Solid", "6"); 
				AcceptEntityInput(RotateIndex, "TurnOn", RotateIndex, RotateIndex, 0);
				AcceptEntityInput(RotateIndex, "EnableCollision"); 
				TeleportEntity(RotateIndex, NULL_VECTOR, RotateVec, NULL_VECTOR);
				SetEntProp(RotateIndex, Prop_Data, "m_CollisionGroup", 5);
				SetEntProp(RotateIndex, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(RotateIndex, Prop_Data, "m_nSolidType", 6);
				DispatchKeyValue(RotateIndex, "StartDisabled", "false");
				DispatchKeyValue(RotateIndex, "spawnflags", "8"); 
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s rotated a prop", name);
			}
			if ((RotateIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:rotatemenu = CreateMenu(MenuHandler1);
			SetMenuTitle(rotatemenu, "[FSA] Rotate Menu");
			AddMenuItem(rotatemenu, "Rotate X +45 Degrees", "Rotate X +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y +45 Degrees", "Rotate Y +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z +45 Degrees", "Rotate Z +45 Degrees");
			AddMenuItem(rotatemenu, "Rotate X -45 Degrees", "Rotate X -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Y -45 Degrees", "Rotate Y -45 Degrees");
			AddMenuItem(rotatemenu, "Rotate Z -45 Degrees", "Rotate Z -45 Degrees");
			SetMenuExitBackButton(rotatemenu, true);
			DisplayMenu(rotatemenu, client, 0);
		}
		if(strcmp(info, "Delete Prop") == 0)
		{
			new String:classname[64];
			new DeleteIndex = GetClientAimTarget(client, false);
			if (DeleteIndex != -1)
			{
				GetEdictClassname(DeleteIndex, classname, sizeof(classname));
			}
			if ((DeleteIndex != -1) && (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				AcceptEntityInput(DeleteIndex, "Kill", -1, -1, 0);
				PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s deleted a prop", name);
			}
			if ((DeleteIndex == -1) || !(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") || StrEqual(classname, "prop_dynamic") || StrEqual(classname, "prop_dynamic_override") || StrEqual(classname, "prop_physics_multiplayer") || StrEqual(classname, "prop_dynamic_ornament") || StrEqual(classname, "prop_static")))
			{
				PrintToChat(client, "\x03[\x04FSA\x03] \x01No entity found or invalid entity");
			}
			new Handle:propmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(propmenu, "[FSA] Prop Menu");
			AddMenuItem(propmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(propmenu, "Rotate Prop", "Rotate Prop");
			AddMenuItem(propmenu, "Physic Props", "Physic Props");
			AddMenuItem(propmenu, "Dynamic/Static Props", "Dynamic/Static Props");
			AddMenuItem(propmenu, "NPCs", "NPCs");
			SetMenuExitBackButton(propmenu, true);
			DisplayMenu(propmenu, client, 0);
		}
		if(strcmp(info, "Physic Props") == 0)
		{
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
		}
		if(strcmp(info, "Dynamic/Static Props") == 0)
		{
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
		}
		if(strcmp(info, "NPCs") == 0)
		{
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
		}
		if(strcmp(info, "Banana") == 0)
		{
			phrase = "Bananas";
			PrecacheModel("models/props/cs_italy/bananna_bunch.mdl",true);
			PrecacheModel("models/props/cs_italy/bananna.mdl", true);
			PrecacheModel("models/props/cs_italy/banannagib1.mdl", true);
			PrecacheModel("models/props/cs_italy/banannagib2.mdl", true);
			modelname = "models/props/cs_italy/bananna_bunch.mdl";
			PropHealth = 1;
			Explode = 0;
			prop_physics_create(client);
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
		}
		if(strcmp(info, "Barrel") == 0)
		{
			phrase = "a Barrel";
			PrecacheModel("models/props_c17/oildrum001.mdl",true);
			modelname = "models/props_c17/oildrum001.mdl";
			PropHealth = 0;
			Explode = 0;
			prop_physics_create(client);
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
		}
		if(strcmp(info, "Explosive Barrel") == 0)
		{
			phrase = "an Explosive Barrel";
			PrecacheModel("models/props_c17/oildrum001_explosive.mdl",true);
			PrecacheModel("models/props_c17/oildrumchunk01a.mdl",true);
			PrecacheModel("models/props_c17/oildrumchunk01b.mdl",true);
			PrecacheModel("models/props_c17/oildrumchunk01c.mdl",true);
			PrecacheModel("models/props_c17/oildrumchunk01d.mdl",true);
			PrecacheModel("models/props_c17/oildrumchunk01e.mdl",true);
			modelname = "models/props_c17/oildrum001_explosive.mdl";
			PropHealth = 1;
			Explode = 1;
			prop_physics_create(client);
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
		}
		if(strcmp(info, "File Cabinet") == 0)
		{
			phrase = "a File Cabinet";
			PrecacheModel("models/props/cs_office/file_cabinet3.mdl",true);
			modelname = "models/props/cs_office/file_cabinet3.mdl";
			PropHealth = 0;
			Explode = 0;
			prop_physics_create(client);
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Orange") == 0)
		{
			phrase = "an Orange";
			PrecacheModel("models/props/cs_italy/orange.mdl",true);
			PrecacheModel("models/props/cs_italy/orangegib1.mdl",true);
			PrecacheModel("models/props/cs_italy/orangegib2.mdl",true);
			PrecacheModel("models/props/cs_italy/orangegib3.mdl",true);
			modelname = "models/props/cs_italy/orange.mdl";
			PropHealth = 1;
			Explode = 0;
			prop_physics_create(client);
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Swampy Turtle") == 0)
		{
			phrase = "a Swampy Turtle";
			PrecacheModel("models/props/de_tides/vending_turtle.mdl",true);
			modelname = "models/props/de_tides/vending_turtle.mdl";
			PropHealth = 0;
			Explode = 0;
			prop_physics_create(client);
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Vending Machine") == 0)
		{
			phrase = "a Vending Machine";
			PrecacheModel("models/props/cs_office/vending_machine.mdl",true);
			modelname = "models/props/cs_office/vending_machine.mdl";
			decl Float:VecOrigin[3], Float:VecAngles[3];
			new prop = CreateEntityByName("prop_physics_override");
			DispatchKeyValue(prop, "model", modelname);
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
			TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
			TR_GetEndPosition(VecOrigin);
			VecAngles[0] = 0.0;
			VecAngles[2] = 0.0;
			VecOrigin[2] = VecOrigin[2] + 5;
			DispatchKeyValueVector(prop, "angles", VecAngles);
			DispatchSpawn(prop);
			TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
			PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s spawned %s", name, phrase);
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Heavy Vending Machine") == 0)
		{
			phrase = "a Heavy Vending Machine";
			PrecacheModel("models/props_interiors/vendingmachinesoda01a.mdl",true);
			modelname = "models/props_interiors/vendingmachinesoda01a.mdl";
			PropHealth = 0;
			Explode = 0;
			prop_physics_create(client);
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Watermelon") == 0)
		{
			phrase = "a Watermelon";
			PrecacheModel("models/props_junk/watermelon01.mdl",true);
			PrecacheModel("models/props_junk/watermelon01_chunk01a.mdl",true);
			PrecacheModel("models/props_junk/watermelon01_chunk01b.mdl",true);
			PrecacheModel("models/props_junk/watermelon01_chunk01c.mdl",true);
			PrecacheModel("models/props_junk/watermelon01_chunk02a.mdl",true);
			PrecacheModel("models/props_junk/watermelon01_chunk02b.mdl",true);
			PrecacheModel("models/props_junk/watermelon01_chunk02c.mdl",true);
			modelname = "models/props_junk/watermelon01.mdl";
			PropHealth = 1;
			Explode = 0;
			prop_physics_create(client);
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Wine Barrel") == 0)
		{
			phrase = "a Wine Barrel";
			PrecacheModel("models/props/de_inferno/wine_barrel.mdl",true);
			PrecacheModel("models/props/de_inferno/wine_barrel_p1.mdl",true);
			PrecacheModel("models/props/de_inferno/wine_barrel_p2.mdl",true);
			PrecacheModel("models/props/de_inferno/wine_barrel_p3.mdl",true);
			PrecacheModel("models/props/de_inferno/wine_barrel_p4.mdl",true);
			PrecacheModel("models/props/de_inferno/wine_barrel_p5.mdl",true);
			PrecacheModel("models/props/de_inferno/wine_barrel_p6.mdl",true);
			PrecacheModel("models/props/de_inferno/wine_barrel_p7.mdl",true);
			PrecacheModel("models/props/de_inferno/wine_barrel_p8.mdl",true);
			PrecacheModel("models/props/de_inferno/wine_barrel_p9.mdl",true);
			PrecacheModel("models/props/de_inferno/wine_barrel_p10.mdl",true);
			PrecacheModel("models/props/de_inferno/wine_barrel_p11.mdl",true);
			modelname = "models/props/de_inferno/wine_barrel.mdl";
			PropHealth = 0;
			Explode = 0;
			prop_physics_create(client);
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Leather Sofa") == 0)
		{
			phrase = "a Leather Sofa";
			PrecacheModel("models/props/cs_office/sofa.mdl",true);
			modelname = "models/props/cs_office/sofa.mdl";
			decl Float:VecOrigin[3], Float:VecAngles[3];
			new prop = CreateEntityByName("prop_physics_override");
			DispatchKeyValue(prop, "model", modelname);
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
			TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
			TR_GetEndPosition(VecOrigin);
			VecAngles[0] = 0.0;
			VecAngles[2] = 0.0;
			VecOrigin[2] = VecOrigin[2] + 10;
			DispatchKeyValueVector(prop, "angles", VecAngles);
			DispatchSpawn(prop);
			TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
			GetClientName(client, name, sizeof(name));
			PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s spawned %s", name, phrase);
			new Handle:physmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(physmenu, "[FSA] Physic Props");
			AddMenuItem(physmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(physmenu, "RotXP45", "Rotate X +45 Degrees");
			AddMenuItem(physmenu, "RotYP45", "Rotate Y +45 Degrees");
			AddMenuItem(physmenu, "RotZP45", "Rotate Z +45 Degrees");
			AddMenuItem(physmenu, "Banana", "Banana");
			AddMenuItem(physmenu, "Barrel", "Barrel");
			AddMenuItem(physmenu, "Explosive Barrel", "Explosive Barrel");
			AddMenuItem(physmenu, "File Cabinet", "File Cabinet");
			AddMenuItem(physmenu, "Orange", "Orange");
			AddMenuItem(physmenu, "Leather Sofa", "Leather Sofa");
			AddMenuItem(physmenu, "Swampy Turtle", "Swampy Turtle");
			AddMenuItem(physmenu, "Vending Machine", "Vending Machine");
			AddMenuItem(physmenu, "Heavy Vending Machine", "Heavy Vending Machine");
			AddMenuItem(physmenu, "Watermelon", "Watermelon");
			AddMenuItem(physmenu, "Wine Barrel", "Wine Barrel");
			SetMenuExitBackButton(physmenu, true);
			DisplayMenu(physmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Airboat") == 0)
		{
			phrase = "an Airboat";
			PrecacheModel("models/airboat.mdl",true);
			modelname = "models/airboat.mdl";
			prop_dynamic_create(client);
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
		}
		if(strcmp(info, "Fountain") == 0)
		{
			phrase = "a Fountain";
			PrecacheModel("models/props/de_inferno/fountain.mdl",true);
			modelname = "models/props/de_inferno/fountain.mdl";
			prop_dynamic_create(client);
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
		}
		if(strcmp(info, "Lamppost") == 0)
		{
			phrase = "a Lamppost";
			PrecacheModel("models/props_c17/lamppost03a_off.mdl",true);
			modelname = "models/props_c17/lamppost03a_off.mdl";
			prop_dynamic_create(client);
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Pipe") == 0)
		{
			phrase = "a Pipe";
			PrecacheModel("models/props_pipes/pipecluster32d_001a.mdl",true);
			modelname = "models/props_pipes/pipecluster32d_001a.mdl";
			prop_dynamic_create(client);
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Propane Machine") == 0)
		{
			phrase = "a Propane Machine";
			PrecacheModel("models/props/de_train/processor_nobase.mdl",true);
			modelname = "models/props/de_train/processor_nobase.mdl";
			prop_dynamic_create(client);
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Rock") == 0)
		{
			phrase = "a Rock";
			PrecacheModel("models/props/de_inferno/de_inferno_boulder_01.mdl",true);
			modelname = "models/props/de_inferno/de_inferno_boulder_01.mdl";
			prop_dynamic_create(client);
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Fabric Sofa") == 0)
		{
			phrase = "a Fabric Sofa";
			PrecacheModel("models/props/cs_militia/couch.mdl",true);
			modelname = "models/props/cs_militia/couch.mdl";
			prop_dynamic_create(client);
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Table") == 0)
		{
			phrase = "a Table";
			PrecacheModel("models/props/cs_militia/table_kitchen.mdl",true);
			modelname = "models/props/cs_militia/table_kitchen.mdl";
			prop_dynamic_create(client);
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Tank") == 0)
		{
			phrase = "a Tank";
			PrecacheModel("models/props_vehicles/apc001.mdl",true);
			modelname = "models/props_vehicles/apc001.mdl";
			prop_dynamic_create(client);
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Toilet") == 0)
		{
			phrase = "a Toilet";
			PrecacheModel("models/props/cs_militia/toilet.mdl",true);
			modelname = "models/props/cs_militia/toilet.mdl";
			prop_dynamic_create(client);
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Wooden Box") == 0)
		{
			phrase = "a Wooden Box";
			PrecacheModel("models/props/cs_militia/crate_extralargemill.mdl",true);
			modelname = "models/props/cs_militia/crate_extralargemill.mdl";
			prop_dynamic_create(client);
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Jeep") == 0)
		{
			phrase = "a Jeep";
			PrecacheModel("models/buggy.mdl",true);
			modelname = "models/buggy.mdl";
			prop_dynamic_create(client);
			new Handle:dynmcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(dynmcmenu, "[FSA] Dynamic Props");
			AddMenuItem(dynmcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(dynmcmenu, "RotXD45", "Rotate X +45 Degrees");
			AddMenuItem(dynmcmenu, "RotYD45", "Rotate Y +45 Degrees");
			AddMenuItem(dynmcmenu, "RotZD45", "Rotate Z +45 Degrees");
			AddMenuItem(dynmcmenu, "Airboat", "Airboat");
			AddMenuItem(dynmcmenu, "Fountain", "Fountain");
			AddMenuItem(dynmcmenu, "Jeep", "Jeep");
			AddMenuItem(dynmcmenu, "Lamppost", "Lamppost");
			AddMenuItem(dynmcmenu, "Pipe", "Pipe");
			AddMenuItem(dynmcmenu, "Propane Machine", "Propane Machine");
			AddMenuItem(dynmcmenu, "Rock", "Rock");
			AddMenuItem(dynmcmenu, "Fabric Sofa", "Fabric Sofa");
			AddMenuItem(dynmcmenu, "Table", "Table");
			AddMenuItem(dynmcmenu, "Tank", "Tank");
			AddMenuItem(dynmcmenu, "Toilet", "Toilet");
			AddMenuItem(dynmcmenu, "Wooden Box", "Wooden Box");
			SetMenuExitBackButton(dynmcmenu, true);
			DisplayMenu(dynmcmenu, client, 0);
		}
		if(strcmp(info, "Alyx") == 0)
		{
			phrase = "Alyx";
			PrecacheModel("models/alyx.mdl",true);
			modelname = "models/alyx.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
		}
		if(strcmp(info, "Antlion") == 0)
		{
			phrase = "an Antlion";
			PrecacheModel("models/antlion.mdl",true);
			modelname = "models/antlion.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
		}
		if(strcmp(info, "Antlion Guard") == 0)
		{
			phrase = "an Antlion Guard";
			PrecacheModel("models/antlion_guard.mdl",true);
			modelname = "models/antlion_guard.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
		}
		if(strcmp(info, "Barney") == 0)
		{
			phrase = "Barney";
			PrecacheModel("models/barney.mdl",true);
			modelname = "models/barney.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Breen") == 0)
		{
			phrase = "Breen";
			PrecacheModel("models/breen.mdl",true);
			modelname = "models/breen.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Counter-Terrorist") == 0)
		{
			phrase = "a Counter-Terrorist";
			PrecacheModel("models/player/ct_gign.mdl",true);
			modelname = "models/player/ct_gign.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Crow") == 0)
		{
			phrase = "a Crow";
			PrecacheModel("models/crow.mdl",true);
			modelname = "models/crow.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Dog") == 0)
		{
			phrase = "Dog";
			PrecacheModel("models/dog.mdl",true);
			modelname = "models/dog.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Eli") == 0)
		{
			phrase = "Eli";
			PrecacheModel("models/eli.mdl",true);
			modelname = "models/eli.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Fast Headcrab") == 0)
		{
			phrase = "a Fast Headcrab";
			PrecacheModel("models/headcrab.mdl",true);
			modelname = "models/headcrab.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Fast Zombie") == 0)
		{
			phrase = "a Fast Zombie";
			PrecacheModel("models/zombie/fast.mdl",true);
			modelname = "models/zombie/fast.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Headcrab") == 0)
		{
			phrase = "a Headcrab";
			PrecacheModel("models/headcrabclassic.mdl",true);
			modelname = "models/headcrabclassic.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Hostage") == 0)
		{
			phrase = "a Hostage";
			PrecacheModel("models/characters/hostage_02.mdl",true);
			modelname = "models/characters/hostage_02.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Kleiner") == 0)
		{
			phrase = "Kleiner";
			PrecacheModel("models/kleiner.mdl",true);
			modelname = "models/kleiner.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Poison Headcrab") == 0)
		{
			phrase = "a Poison Headcrab";
			PrecacheModel("models/headcrabblack.mdl",true);
			modelname = "models/headcrabblack.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Poison Zombie") == 0)
		{
			phrase = "a Poison Zombie";
			PrecacheModel("models/zombie/poison.mdl",true);
			modelname = "models/zombie/poison.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Terrorist") == 0)
		{
			phrase = "a Terrorist";
			PrecacheModel("models/player/t_guerilla.mdl",true);
			modelname = "models/player/t_guerilla.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Vortigaunt") == 0)
		{
			phrase = "a Vortigaunt";
			PrecacheModel("models/vortigaunt.mdl",true);
			modelname = "models/vortigaunt.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Zombie") == 0)
		{
			phrase = "a Zombie";
			PrecacheModel("models/zombie/classic.mdl",true);
			modelname = "models/zombie/classic.mdl";
			prop_npc_create(client);
			new Handle:npcmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(npcmenu, "[FSA] NPCs");
			AddMenuItem(npcmenu, "Delete Prop", "Delete Prop");
			AddMenuItem(npcmenu, "RotXN45", "Rotate X +45 Degrees");
			AddMenuItem(npcmenu, "RotYN45", "Rotate Y +45 Degrees");
			AddMenuItem(npcmenu, "RotZN45", "Rotate Z +45 Degrees");
			AddMenuItem(npcmenu, "Alyx", "Alyx");
			AddMenuItem(npcmenu, "Antlion", "Antlion");
			AddMenuItem(npcmenu, "Antlion Guard", "Antlion Guard");
			AddMenuItem(npcmenu, "Barney", "Barney");
			AddMenuItem(npcmenu, "Breen", "Breen");
			AddMenuItem(npcmenu, "Counter-Terrorist", "Counter-Terrorist");
			AddMenuItem(npcmenu, "Crow", "Crow");
			AddMenuItem(npcmenu, "Dog", "Dog");
			AddMenuItem(npcmenu, "Eli", "Eli");
			AddMenuItem(npcmenu, "Fast Headcrab", "Fast Headcrab");
			AddMenuItem(npcmenu, "Fast Zombie", "Fast Zombie");
			AddMenuItem(npcmenu, "Headcrab", "Headcrab");
			AddMenuItem(npcmenu, "Hostage", "Hostage");
			AddMenuItem(npcmenu, "Kleiner", "Kleiner");
			AddMenuItem(npcmenu, "Poison Headcrab", "Poison Headcrab");
			AddMenuItem(npcmenu, "Poison Zombie", "Poison Zombie");
			AddMenuItem(npcmenu, "Terrorist", "Terrorist");
			AddMenuItem(npcmenu, "Vortigaunt", "Vortigaunt");
			AddMenuItem(npcmenu, "Zombie", "Zombie");
			SetMenuExitBackButton(npcmenu, true);
			DisplayMenu(npcmenu, client, 0);
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
			FakeClientCommandEx(client, "menuselect 9");
		}
		if(strcmp(info, "Play Music") == 0)
		{			
			new Handle:musicmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(musicmenu, "[FSA] Music Menu");
			AddMenuItem(musicmenu, "HL2_song4", "Adrenaline");
			AddMenuItem(musicmenu, "HL2_song31", "Calm Battle");
			AddMenuItem(musicmenu, "HL1_song17", "Calm Travel");
			AddMenuItem(musicmenu, "HL2_song16", "Cautious Travel");
			AddMenuItem(musicmenu, "HL2_song12_long", "Easy Battle");
			AddMenuItem(musicmenu, "HL2_song7", "Entrance to Ravenholm");
			AddMenuItem(musicmenu, "HL2_song6", "Final Ascend");
			AddMenuItem(musicmenu, "HL1_song25_REMIX3", "Half-Life 1 Credits");
			AddMenuItem(musicmenu, "HL2_song3", "Half-Life 2 Credits");
			AddMenuItem(musicmenu, "HL2_song15", "Half-Life 2 Credits 2");
			AddMenuItem(musicmenu, "HL2_song10", "Heavens");
			AddMenuItem(musicmenu, "HL2_song17", "Horrific Discovery");
			AddMenuItem(musicmenu, "HL2_song28", "Horror");
			AddMenuItem(musicmenu, "HL2_song29", "Intense Escape");
			AddMenuItem(musicmenu, "HL2_song14", "Journey");
			AddMenuItem(musicmenu, "HL2_song25_Teleporter", "Majestical Horror");
			AddMenuItem(musicmenu, "HL2_song23_SuitSong3", "Memories");
			AddMenuItem(musicmenu, "HL2_song19", "Nova Prospekt");
			AddMenuItem(musicmenu, "Ravenholm_1", "Ravenholm Ending");
			AddMenuItem(musicmenu, "HL1_song10", "River Chase");
			AddMenuItem(musicmenu, "HL2_song20_submix0", "Slow Battle");
			AddMenuItem(musicmenu, "HL2_song20_submix4", "Slow Battle 2");
			AddMenuItem(musicmenu, "HL2_song32", "Sad End");
			AddMenuItem(musicmenu, "HL1_song11", "Source Engine");
			AddMenuItem(musicmenu, "HL2_song33", "Spooky Place");
			AddMenuItem(musicmenu, "HL1_song19", "Spooky Tunnel");
			AddMenuItem(musicmenu, "HL1_song15", "Strider Battle");
			SetMenuExitBackButton(musicmenu, true);
			DisplayMenu(musicmenu, client, 0);
		}
		if(strcmp(info, "HL2_song4") == 0)
		{
			PrecacheSound("music/HL2_song4.mp3", false);
			EmitSoundToAll("music/HL2_song4.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song31") == 0)
		{
			PrecacheSound("music/HL2_song31.mp3", false);
			EmitSoundToAll("music/HL2_song31.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL1_song17") == 0)
		{
			PrecacheSound("music/HL1_song17.mp3", false);
			EmitSoundToAll("music/HL1_song17.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song16") == 0)
		{
			PrecacheSound("music/HL2_song16.mp3", false);
			EmitSoundToAll("music/HL2_song16.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song12_long") == 0)
		{
			PrecacheSound("music/HL2_song12_long.mp3", false);
			EmitSoundToAll("music/HL2_song12_long.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song7") == 0)
		{
			PrecacheSound("music/HL2_song7.mp3", false);
			EmitSoundToAll("music/HL2_song7.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song6") == 0)
		{
			PrecacheSound("music/HL2_song6.mp3", false);
			EmitSoundToAll("music/HL2_song6.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL1_song25_REMIX3") == 0)
		{
			PrecacheSound("music/HL1_song25_REMIX3.mp3", false);
			EmitSoundToAll("music/HL1_song25_REMIX3.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song3") == 0)
		{
			PrecacheSound("music/HL2_song3.mp3", false);
			EmitSoundToAll("music/HL2_song3.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song15") == 0)
		{
			PrecacheSound("music/HL2_song15.mp3", false);
			EmitSoundToAll("music/HL2_song15.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song10") == 0)
		{
			PrecacheSound("music/HL2_song10.mp3", false);
			EmitSoundToAll("music/HL2_song10.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song17") == 0)
		{
			PrecacheSound("music/HL2_song17.mp3", false);
			EmitSoundToAll("music/HL2_song17.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song28") == 0)
		{
			PrecacheSound("music/HL2_song28.mp3", false);
			EmitSoundToAll("music/HL2_song28.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song29") == 0)
		{
			PrecacheSound("music/HL2_song29.mp3", false);
			EmitSoundToAll("music/HL2_song29.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song14") == 0)
		{
			PrecacheSound("music/HL2_song14.mp3", false);
			EmitSoundToAll("music/HL2_song14.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song25_Teleporter") == 0)
		{
			PrecacheSound("music/HL2_song25_Teleporter.mp3", false);
			EmitSoundToAll("music/HL2_song25_Teleporter.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song23_SuitSong3") == 0)
		{
			PrecacheSound("music/HL2_song23_SuitSong3.mp3", false);
			EmitSoundToAll("music/HL2_song23_SuitSong3.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song19") == 0)
		{
			PrecacheSound("music/HL2_song19.mp3", false);
			EmitSoundToAll("music/HL2_song19.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "Ravenholm_1") == 0)
		{
			PrecacheSound("music/Ravenholm_1.mp3", false);
			EmitSoundToAll("music/Ravenholm_1.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL1_song10") == 0)
		{
			PrecacheSound("music/HL1_song10.mp3", false);
			EmitSoundToAll("music/HL1_song10.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song20_submix0") == 0)
		{
			PrecacheSound("music/HL2_song20_submix0.mp3", false);
			EmitSoundToAll("music/HL2_song20_submix0.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song20_submix4") == 0)
		{
			PrecacheSound("music/HL2_song20_submix4.mp3", false);
			EmitSoundToAll("music/HL2_song20_submix4.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song32") == 0)
		{
			PrecacheSound("music/HL2_song32.mp3", false);
			EmitSoundToAll("music/HL2_song32.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL1_song11") == 0)
		{
			PrecacheSound("music/HL1_song11.mp3", false);
			EmitSoundToAll("music/HL1_song11.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL2_song33") == 0)
		{
			PrecacheSound("music/HL2_song33.mp3", false);
			EmitSoundToAll("music/HL2_song33.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL1_song19") == 0)
		{
			PrecacheSound("music/HL1_song19.mp3", false);
			EmitSoundToAll("music/HL1_song19.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "HL1_song15") == 0)
		{
			PrecacheSound("music/HL1_song15.mp3", false);
			EmitSoundToAll("music/HL1_song15.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(strcmp(info, "Ban") == 0)
		{
			new Handle:banmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(banmenu, "Select Ban Duration");
			AddMenuItem(banmenu, "Permanent", "Permanent");
			AddMenuItem(banmenu, "5 mins", "5 mins");
			AddMenuItem(banmenu, "30 mins", "30 mins");
			AddMenuItem(banmenu, "1 hour", "1 hour");
			AddMenuItem(banmenu, "2 hours", "2 hours");
			SetMenuExitBackButton(banmenu, true);
			DisplayMenu(banmenu, client, 0);
		}
		if(strcmp(info, "Permanent") == 0)
		{
			BanDuration[client] = 0;
			new Handle:banmenu = CreateMenu(BanHandle);
			SetMenuTitle(banmenu, "Select Player to Ban");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(banmenu, name, name);
				}
			}
			SetMenuExitBackButton(banmenu, true);
			DisplayMenu(banmenu, client, 0);
		}
		if(strcmp(info, "5 mins") == 0)
		{
			BanDuration[client] = 5;
			new Handle:banmenu = CreateMenu(BanHandle);
			SetMenuTitle(banmenu, "Select Player to Ban");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(banmenu, name, name);
				}
			}
			SetMenuExitBackButton(banmenu, true);
			DisplayMenu(banmenu, client, 0);
		}
		if(strcmp(info, "30 mins") == 0)
		{
			BanDuration[client] = 30;
			new Handle:banmenu = CreateMenu(BanHandle);
			SetMenuTitle(banmenu, "Select Player to Ban");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(banmenu, name, name);
				}
			}
			SetMenuExitBackButton(banmenu, true);
			DisplayMenu(banmenu, client, 0);
		}
		if(strcmp(info, "1 hour") == 0)
		{
			BanDuration[client] = 60;
			new Handle:banmenu = CreateMenu(BanHandle);
			SetMenuTitle(banmenu, "Select Player to Ban");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(banmenu, name, name);
				}
			}
			SetMenuExitBackButton(banmenu, true);
			DisplayMenu(banmenu, client, 0);
		}
		if(strcmp(info, "2 hours") == 0)
		{
			BanDuration[client] = 120;
			new Handle:banmenu = CreateMenu(BanHandle);
			SetMenuTitle(banmenu, "Select Player to Ban");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(banmenu, name, name);
				}
			}
			SetMenuExitBackButton(banmenu, true);
			DisplayMenu(banmenu, client, 0);
		}
		if(strcmp(info, "Freeze") == 0)
		{
			new Handle:freezemenu = CreateMenu(FreezeHandle);
			SetMenuTitle(freezemenu, "Select Player to Freeze/Unfreeze");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					if (FreezeStatus[i] == 0)
					{
						AddMenuItem(freezemenu, name, name);
					}
					if (FreezeStatus[i] == 1)
					{
						FreezeString = "[FROZEN] ";
						StrCat(FreezeString, 64, name);
						AddMenuItem(freezemenu, name, FreezeString);
					}
				}
			}
			SetMenuExitBackButton(freezemenu, true);
			DisplayMenu(freezemenu, client, 0);
		}
		if(strcmp(info, "Kick") == 0)
		{
			new Handle:kickmenu = CreateMenu(KickHandle);
			SetMenuTitle(kickmenu, "Select Player to Kick");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(kickmenu, name, name);
				}
			}
			SetMenuExitBackButton(kickmenu, true);
			DisplayMenu(kickmenu, client, 0);
		}
		if(strcmp(info, "Mute") == 0)
		{
			new Handle:mutemenu = CreateMenu(MuteHandle);
			SetMenuTitle(mutemenu, "Select Player to Mute/Unmute");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i))
				{
					GetClientName(i, name, sizeof(name));
					if (MuteStatus[i] == 0)
					{
						AddMenuItem(mutemenu, name, name);
					}
					if (MuteStatus[i] == 1)
					{
						MuteString = "[MUTED] ";
						StrCat(MuteString, 64, name);
						AddMenuItem(mutemenu, name, MuteString);
					}
				}
			}
			SetMenuExitBackButton(mutemenu, true);
			DisplayMenu(mutemenu, client, 0);
		}
		if(strcmp(info, "Slay") == 0)
		{
			new Handle:slaymenu = CreateMenu(SlayHandle);
			SetMenuTitle(slaymenu, "Select Player to Slay");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(slaymenu, name, name);
				}
			}
			SetMenuExitBackButton(slaymenu, true);
			DisplayMenu(slaymenu, client, 0);
		}
		if(strcmp(info, "Blind") == 0)
		{
			new Handle:blindmenu = CreateMenu(BlindHandle);
			SetMenuTitle(blindmenu, "Select Player to Blind/Unblind");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if (BlindAlpha[i] == 0)
					{
						GetClientName(i, name, sizeof(name));
						AddMenuItem(blindmenu, name, name);
					}
					if (BlindAlpha[i] == 200)
					{
						GetClientName(i, name, sizeof(name));
						BlindPrefix = "[Half-Blinded] ";
						StrCat(BlindPrefix, 64, name);
						AddMenuItem(blindmenu, name, BlindPrefix);
					}
					if (BlindAlpha[i] == 255)
					{
						GetClientName(i, name, sizeof(name));
						BlindPrefix = "[Blinded] ";
						StrCat(BlindPrefix, 64, name);
						AddMenuItem(blindmenu, name, BlindPrefix);
					}
				}
			}
			SetMenuExitBackButton(blindmenu, true);
			DisplayMenu(blindmenu, client, 0);
		}
		if(strcmp(info, "Burn") == 0)
		{
			new Handle:burnmenu = CreateMenu(BurnHandle);
			SetMenuTitle(burnmenu, "Select Player to Burn");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(burnmenu, name, name);
				}
			}
			SetMenuExitBackButton(burnmenu, true);
			DisplayMenu(burnmenu, client, 0);
		}
		if(strcmp(info, "Burymain") == 0)
		{
			new Handle:burymainmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(burymainmenu, "Select Bury/Unbury");
			AddMenuItem(burymainmenu, "Bury", "Bury");
			AddMenuItem(burymainmenu, "Unbury", "Unbury");
			SetMenuExitBackButton(burymainmenu, true);
			DisplayMenu(burymainmenu, client, 0);
		}
		if(strcmp(info, "Bury") == 0)
		{
			new Handle:burymenu = CreateMenu(BuryHandle);
			SetMenuTitle(burymenu, "Select Player to Bury");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(burymenu, name, name);
				}
			}
			SetMenuExitBackButton(burymenu, true);
			DisplayMenu(burymenu, client, 0);
		}
		if(strcmp(info, "Unbury") == 0)
		{
			new Handle:unburymenu = CreateMenu(UnburyHandle);
			SetMenuTitle(unburymenu, "Select Player to Unbury");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(unburymenu, name, name);
				}
			}
			SetMenuExitBackButton(unburymenu, true);
			DisplayMenu(unburymenu, client, 0);
		}
		if(strcmp(info, "Disarm") == 0)
		{
			new Handle:disarmmenu = CreateMenu(DisarmHandle);
			SetMenuTitle(disarmmenu, "Select Player to Disarm");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(disarmmenu, name, name);
				}
			}
			SetMenuExitBackButton(disarmmenu, true);
			DisplayMenu(disarmmenu, client, 0);
		}
		if(strcmp(info, "Disguise") == 0)
		{
			new Handle:disguisemenu = CreateMenu(DisguiseHandle);
			SetMenuTitle(disguisemenu, "Select Player to Disguise/Undisguise");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && (IsPlayerAlive(i)))
				{
					if (DisguiseID[i] == 0)
					{
						GetClientName(i, name, sizeof(name));
						AddMenuItem(disguisemenu, name, name);
					}
					else if (DisguiseID[i] == 1)
					{
						GetClientName(i, name, sizeof(name));
						DisguisePrefix = "[Barrel] ";
						StrCat(DisguisePrefix, 64, name);
						AddMenuItem(disguisemenu, name, DisguisePrefix);
					}
					else if (DisguiseID[i] == 2)
					{
						GetClientName(i, name, sizeof(name));
						DisguisePrefix = "[Zombie] ";
						StrCat(DisguisePrefix, 64, name);
						AddMenuItem(disguisemenu, name, DisguisePrefix);
					}
					else if (DisguiseID[i] == 3)
					{
						GetClientName(i, name, sizeof(name));
						DisguisePrefix = "[Bicycle] ";
						StrCat(DisguisePrefix, 64, name);
						AddMenuItem(disguisemenu, name, DisguisePrefix);
					}
					else if (DisguiseID[i] == 4)
					{
						GetClientName(i, name, sizeof(name));
						DisguisePrefix = "[Headcrab] ";
						StrCat(DisguisePrefix, 64, name);
						AddMenuItem(disguisemenu, name, DisguisePrefix);
					}
					else if (DisguiseID[i] == 5)
					{
						GetClientName(i, name, sizeof(name));
						DisguisePrefix = "[Pigeon] ";
						StrCat(DisguisePrefix, 64, name);
						AddMenuItem(disguisemenu, name, DisguisePrefix);
					}
				}
			}
			SetMenuExitBackButton(disguisemenu, true);
			DisplayMenu(disguisemenu, client, 0);
		}
		if(strcmp(info, "Drug") == 0)
		{
			new Handle:drugmenu = CreateMenu(DrugHandle);
			SetMenuTitle(drugmenu, "Select Player to Drug/Undrug");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && (IsPlayerAlive(i)))
				{
					GetClientName(i, name, sizeof(name));
					if (DrugStatus[i] == 0)
					{
						AddMenuItem(drugmenu, name, name);
					}
					if (DrugStatus[i] == 1)
					{
						DrugString = "[DRUGGED] ";
						StrCat(DrugString, 64, name);
						AddMenuItem(drugmenu, name, DrugString);
					}
				}
			}
			SetMenuExitBackButton(drugmenu, true);
			DisplayMenu(drugmenu, client, 0);
		}
		if(strcmp(info, "Godmode") == 0)
		{
			new Handle:godmenu = CreateMenu(GodHandle);
			SetMenuTitle(godmenu, "Select Player for Godmode");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					if (GodStatus[i] == 0)
					{
						AddMenuItem(godmenu, name, name);
					}
					if (GodStatus[i] == 1)
					{
						GodString = "[GODMODE] ";
						StrCat(GodString, 64, name);
						AddMenuItem(godmenu, name, GodString);
					}
				}
			}
			SetMenuExitBackButton(godmenu, true);
			DisplayMenu(godmenu, client, 0);
		}
		if(strcmp(info, "Invisible") == 0)
		{
			new Handle:invismenu = CreateMenu(InvisHandle);
			SetMenuTitle(invismenu, "Select Player for Invisibility");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && (IsPlayerAlive(i)))
				{
					GetClientName(i, name, sizeof(name));
					if (InvisStatus[i] == 0)
					{
						AddMenuItem(invismenu, name, name);
					}
					if (InvisStatus[i] == 1)
					{
						InvisString = "[INVISIBLE] ";
						StrCat(InvisString, 64, name);
						AddMenuItem(invismenu, name, InvisString);
					}
				}
			}
			SetMenuExitBackButton(invismenu, true);
			DisplayMenu(invismenu, client, 0);
		}
		if(strcmp(info, "Jetpack") == 0)
		{
			new Handle:jetmenu = CreateMenu(JetHandle);
			SetMenuTitle(jetmenu, "Select Player to Give/Remove Jetpack");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					if (JetStatus[i] == 0)
					{
						AddMenuItem(jetmenu, name, name);
					}
					if (JetStatus[i] == 1)
					{
						JetString = "[JETPACK] ";
						StrCat(JetString, 64, name);
						AddMenuItem(jetmenu, name, JetString);
					}
				}
			}
			SetMenuExitBackButton(jetmenu, true);
			DisplayMenu(jetmenu, client, 0);
		}
		if(strcmp(info, "Noclip") == 0)
		{
			new Handle:clipmenu = CreateMenu(ClipHandle);
			SetMenuTitle(clipmenu, "Select Player to Give/Remove Noclip");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					if (ClipStatus[i] == 0)
					{
						AddMenuItem(clipmenu, name, name);
					}
					if (ClipStatus[i] == 1)
					{
						ClipString = "[NOCLIP] ";
						StrCat(ClipString, 64, name);
						AddMenuItem(clipmenu, name, ClipString);
					}
				}
			}
			SetMenuExitBackButton(clipmenu, true);
			DisplayMenu(clipmenu, client, 0);
		}
		if(strcmp(info, "Regeneration") == 0)
		{
			new Handle:regenmenu = CreateMenu(RegenHandle);
			SetMenuTitle(regenmenu, "Select Player to Give/Remove Regeneration");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					if (RegenStatus[i] == 0)
					{
						AddMenuItem(regenmenu, name, name);
					}
					if (RegenStatus[i] == 1)
					{
						RegenString = "[REGEN] ";
						StrCat(RegenString, 64, name);
						AddMenuItem(regenmenu, name, RegenString);
					}
				}
			}
			SetMenuExitBackButton(regenmenu, true);
			DisplayMenu(regenmenu, client, 0);
		}
		if(strcmp(info, "Rocket") == 0)
		{
			new Handle:rocketmenu = CreateMenu(RocketHandle);
			SetMenuTitle(rocketmenu, "Select Player to turn into a Rocket");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					if (RocketStatus[i] == 0)
					{
						AddMenuItem(rocketmenu, name, name);
					}
					if (RocketStatus[i] == 1)
					{
						RocketString = "[ROCKET] ";
						StrCat(RocketString, 64, name);
						AddMenuItem(rocketmenu, name, RocketString);
					}
				}
			}
			SetMenuExitBackButton(rocketmenu, true);
			DisplayMenu(rocketmenu, client, 0);
		}
		if(strcmp(info, "Slap") == 0)
		{
			new Handle:slapmainmenu = CreateMenu(MenuHandler1);
			SetMenuTitle(slapmainmenu, "Select Slap Damage");
			AddMenuItem(slapmainmenu, "slap0", "0");
			AddMenuItem(slapmainmenu, "slap1", "1");
			AddMenuItem(slapmainmenu, "slap5", "5");
			AddMenuItem(slapmainmenu, "slap10", "10");
			AddMenuItem(slapmainmenu, "slap50", "50");
			AddMenuItem(slapmainmenu, "slap100", "100");
			AddMenuItem(slapmainmenu, "slap500", "500");
			SetMenuExitBackButton(slapmainmenu, true);
			DisplayMenu(slapmainmenu, client, 0);
		}
		if (strcmp(info, "slap0") == 0)
		{
			slapdamage[client] = 0;
			new Handle:slapmenu = CreateMenu(SlapMenu);
			SetMenuTitle(slapmenu, "Select Player to Slap");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(slapmenu, name, name);
				}
			}
			SetMenuExitBackButton(slapmenu, true);
			DisplayMenu(slapmenu, client, 0);
		}
		if (strcmp(info, "slap1") == 0)
		{
			slapdamage[client] = 1;
			new Handle:slapmenu = CreateMenu(SlapMenu);
			SetMenuTitle(slapmenu, "Select Player to Slap");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(slapmenu, name, name);
				}
			}
			SetMenuExitBackButton(slapmenu, true);
			DisplayMenu(slapmenu, client, 0);
		}
		if (strcmp(info, "slap5") == 0)
		{
			slapdamage[client] = 5;
			new Handle:slapmenu = CreateMenu(SlapMenu);
			SetMenuTitle(slapmenu, "Select Player to Slap");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(slapmenu, name, name);
				}
			}
			SetMenuExitBackButton(slapmenu, true);
			DisplayMenu(slapmenu, client, 0);
		}
		if (strcmp(info, "slap10") == 0)
		{
			slapdamage[client] = 10;
			new Handle:slapmenu = CreateMenu(SlapMenu);
			SetMenuTitle(slapmenu, "Select Player to Slap");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(slapmenu, name, name);
				}
			}
			SetMenuExitBackButton(slapmenu, true);
			DisplayMenu(slapmenu, client, 0);
		}
		if (strcmp(info, "slap50") == 0)
		{
			slapdamage[client] = 50;
			new Handle:slapmenu = CreateMenu(SlapMenu);
			SetMenuTitle(slapmenu, "Select Player to Slap");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(slapmenu, name, name);
				}
			}
			SetMenuExitBackButton(slapmenu, true);
			DisplayMenu(slapmenu, client, 0);
		}
		if (strcmp(info, "slap100") == 0)
		{
			slapdamage[client] = 100;
			new Handle:slapmenu = CreateMenu(SlapMenu);
			SetMenuTitle(slapmenu, "Select Player to Slap");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(slapmenu, name, name);
				}
			}
			SetMenuExitBackButton(slapmenu, true);
			DisplayMenu(slapmenu, client, 0);
		}
		if (strcmp(info, "slap500") == 0)
		{
			slapdamage[client] = 500;
			new Handle:slapmenu = CreateMenu(SlapMenu);
			SetMenuTitle(slapmenu, "Select Player to Slap");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(slapmenu, name, name);
				}
			}
			SetMenuExitBackButton(slapmenu, true);
			DisplayMenu(slapmenu, client, 0);
		}
		if(strcmp(info, "Speed") == 0)
		{
			new Handle:speedmenu = CreateMenu(SpeedHandle);
			SetMenuTitle(speedmenu, "Select Player to Change Speed");
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if ((IsClientInGame(i)) && IsPlayerAlive(i))
				{
					GetClientName(i, name, sizeof(name));
					if (SpeedIndex[i] == 0)
					{
						AddMenuItem(speedmenu, name, name);
					}
					if (SpeedIndex[i] == 1)
					{
						SpeedString = "[X2] ";
						StrCat(SpeedString, 64, name);
						AddMenuItem(speedmenu, name, SpeedString);
					}
					if (SpeedIndex[i] == 2)
					{
						SpeedString = "[X3] ";
						StrCat(SpeedString, 64, name);
						AddMenuItem(speedmenu, name, SpeedString);
					}
					if (SpeedIndex[i] == 3)
					{
						SpeedString = "[X4] ";
						StrCat(SpeedString, 64, name);
						AddMenuItem(speedmenu, name, SpeedString);
					}
					if (SpeedIndex[i] == 4)
					{
						SpeedString = "[X0.5] ";
						StrCat(SpeedString, 64, name);
						AddMenuItem(speedmenu, name, SpeedString);
					}
				}
			}
			SetMenuExitBackButton(speedmenu, true);
			DisplayMenu(speedmenu, client, 0);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			RemoveAllMenuItems(menu);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public BanHandle(Handle:banmenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		new String:authstring[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(banmenu, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					GetClientAuthString(i, authstring, sizeof(authstring));
					new String:bannedname[64];
					GetClientName(i, bannedname, sizeof(bannedname));
					BanIdentity(authstring, BanDuration[client], BANFLAG_AUTHID, "Banned by Admin");
					if (BanDuration[client] == 0)
					{
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s banned %s permanently", nameclient1, bannedname);
					}
					if (BanDuration[client] != 0)
					{
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s banned %s for %i minutes", nameclient1, bannedname, BanDuration[client]);
					}
					KickClient(i, "Banned by Admin");
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public FreezeHandle(Handle:freezemenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(freezemenu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					new tempstring = 0;
					if (FreezeStatus[i] == 0)
					{
						SetEntityMoveType(i, MOVETYPE_NONE);
						FreezeStatus[i] = 1;
						JetStatus[i] = 0;
						ClipStatus[i] = 0;
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s froze %s", nameclient1, nameclient2);
						tempstring = 1;
					}
					if (FreezeStatus[i] == 1)
					{
						if (tempstring == 0)
						{
							SetEntityMoveType(i, MOVETYPE_WALK);
							FreezeStatus[i] = 0;
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s unfroze %s", nameclient1, nameclient2);
						}
					}
				}
			}
		}
		RemoveAllMenuItems(freezemenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, name, sizeof(name));
				if (FreezeStatus[i] == 0)
				{
					AddMenuItem(freezemenu, name, name);
				}
				if (FreezeStatus[i] == 1)
				{
					FreezeString = "[FROZEN] ";
					StrCat(FreezeString, 64, name);
					AddMenuItem(freezemenu, name, FreezeString);
				}
			}
		}
		SetMenuExitBackButton(freezemenu, true);
		DisplayMenu(freezemenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public KickHandle(Handle:kickmenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(kickmenu, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					new String:kickname[64];
					GetClientName(i, kickname, sizeof(kickname));
					KickClient(i, "Kicked by Admin");
					PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s kicked %s", nameclient1, kickname);
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public MuteHandle(Handle:mutemenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(mutemenu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					new tempstring = 0;
					if (MuteStatus[i] == 0)
					{
						MuteStatus[i] = 1;
						ServerCommand("sm_mute %s", nameclient2);
						ServerCommand("sm_gag %s", nameclient2);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s muted %s", nameclient1, nameclient2);
						tempstring = 1;
					}
					if (MuteStatus[i] == 1)
					{
						if (tempstring == 0)
						{
							MuteStatus[i] = 0;
							ServerCommand("sm_unmute %s", nameclient2);
							ServerCommand("sm_ungag %s", nameclient2);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s unmuted %s", nameclient1, nameclient2);
						}
					}
				}
			}
		}
		RemoveAllMenuItems(mutemenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, name, sizeof(name));
				if (MuteStatus[i] == 0)
				{
					AddMenuItem(mutemenu, name, name);
				}
				if (MuteStatus[i] == 1)
				{
					MuteString = "[MUTED] ";
					StrCat(MuteString, 64, name);
					AddMenuItem(mutemenu, name, MuteString);
				}
			}
		}
		SetMenuExitBackButton(mutemenu, true);
		DisplayMenu(mutemenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public SlayHandle(Handle:slaymenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(slaymenu, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					new String:slayname[64];
					SlapPlayer(i, 64000, true);
					GetClientName(i, slayname, sizeof(slayname));
					PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s slayed %s", nameclient1, slayname);
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public BlindHandle(Handle:blindmenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(blindmenu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				new userid = GetClientUserId(i);
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					if (BlindAlpha[i] == 0)
					{
						BlindAlpha[i] = 200;
						ServerCommand("sm_blind #%i %i", userid, BlindAlpha[i]);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s half-blinded %s", nameclient1, nameclient2);
						break;
					}
					if (BlindAlpha[i] == 200)
					{
						BlindAlpha[i] = 255;
						ServerCommand("sm_blind #%i %i", userid, BlindAlpha[i]);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s blinded %s", nameclient1, nameclient2);
						break;
					}
					if (BlindAlpha[i] == 255)
					{
						BlindAlpha[i] = 0;
						ServerCommand("sm_blind #%i %i", userid, BlindAlpha[i]);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s unblinded %s", nameclient1, nameclient2);
						break;
					}
				}
			}
		}
		RemoveAllMenuItems(blindmenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				if (BlindAlpha[i] == 0)
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(blindmenu, name, name);
				}
				if (BlindAlpha[i] == 200)
				{
					GetClientName(i, name, sizeof(name));
					BlindPrefix = "[Half-Blinded] ";
					StrCat(BlindPrefix, 64, name);
					AddMenuItem(blindmenu, name, BlindPrefix);
				}
				if (BlindAlpha[i] == 255)
				{
					GetClientName(i, name, sizeof(name));
					BlindPrefix = "[Blinded] ";
					StrCat(BlindPrefix, 64, name);
					AddMenuItem(blindmenu, name, BlindPrefix);
				}
			}
		}
		SetMenuExitBackButton(blindmenu, true);
		DisplayMenu(blindmenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public BurnHandle(Handle:burnmenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(burnmenu, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					new String:burnname[64];
					GetClientName(i, burnname, sizeof(burnname));
					IgniteEntity(i, 15.0, false, 0.0, false);
					PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s burned %s", nameclient1, burnname);
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public BuryHandle(Handle:burymenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(burymenu, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					new Float:buryvec[3];
					GetClientAbsOrigin(i, buryvec);
					buryvec[2] = buryvec[2] - 50;
					TeleportEntity(i, buryvec, NULL_VECTOR, NULL_VECTOR);
					new String:buryname[64];
					GetClientName(i, buryname, sizeof(buryname));
					PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s buried %s", nameclient1, buryname);
				}
			}
		}
		RemoveAllMenuItems(burymenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, name, sizeof(name));
				AddMenuItem(burymenu, name, name);
			}
		}
		SetMenuExitBackButton(burymenu, true);
		DisplayMenu(burymenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public UnburyHandle(Handle:unburymenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(unburymenu, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					new Float:buryvec[3];
					GetClientAbsOrigin(i, buryvec);
					buryvec[2] = buryvec[2] + 50;
					TeleportEntity(i, buryvec, NULL_VECTOR, NULL_VECTOR);
					new String:buryname[64];
					GetClientName(i, buryname, sizeof(buryname));
					PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s unburied %s", nameclient1, buryname);
				}
			}
		}
		RemoveAllMenuItems(unburymenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, name, sizeof(name));
				AddMenuItem(unburymenu, name, name);
			}
		}
		SetMenuExitBackButton(unburymenu, true);
		DisplayMenu(unburymenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public DisarmHandle(Handle:disarmmenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(disarmmenu, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					new weaponid;
					weaponid = GetPlayerWeaponSlot(i, 0);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 1);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 2);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 3);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 4);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 5);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 6);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 7);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 8);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 9);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 10);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 11);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 0);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 1);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 2);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 3);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 4);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 5);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 6);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 7);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 8);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 9);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 10);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 11);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 0);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 1);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 2);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 3);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 4);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 5);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 6);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 7);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 8);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 9);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 10);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 11);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 0);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 1);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 2);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 3);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 4);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 5);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 6);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 7);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 8);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 9);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 10);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					weaponid = GetPlayerWeaponSlot(i, 11);
					if (weaponid != -1)
					{
						RemovePlayerItem(i, weaponid);
					}
					new String:disarmname[64];
					GetClientName(i, disarmname, sizeof(disarmname));
					PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s disarmed %s", nameclient1, disarmname);
				}
			}
		}
		RemoveAllMenuItems(disarmmenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, name, sizeof(name));
				AddMenuItem(disarmmenu, name, name);
			}
		}
		SetMenuExitBackButton(disarmmenu, true);
		DisplayMenu(disarmmenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public DisguiseHandle(Handle:disguisemenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(disguisemenu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && (IsPlayerAlive(i)))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					if (DisguiseID[i] == 0)
					{
						GetClientModel(i, playermodel[i], 100);
						PrecacheModel("models/props_c17/oildrum001.mdl", false);
						SetEntityModel(i, "models/props_c17/oildrum001.mdl");
						DisguiseID[i] = 1;
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s disguised %s as a Barrel", nameclient1, nameclient2);
						break;
					}
					if (DisguiseID[i] == 1)
					{
						PrecacheModel("models/zombie/classic.mdl", false);
						SetEntityModel(i, "models/zombie/classic.mdl");
						DisguiseID[i] = 2;
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s disguised %s as a Zombie", nameclient1, nameclient2);
						break;
					}
					if (DisguiseID[i] == 2)
					{
						PrecacheModel("models/props_junk/bicycle01a.mdl", false);
						SetEntityModel(i, "models/props_junk/bicycle01a.mdl");
						DisguiseID[i] = 3;
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s disguised %s as a Bicycle", nameclient1, nameclient2);
						break;
					}
					if (DisguiseID[i] == 3)
					{
						PrecacheModel("models/headcrabclassic.mdl", false);
						SetEntityModel(i, "models/headcrabclassic.mdl");
						DisguiseID[i] = 4;
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s disguised %s as a Headcrab", nameclient1, nameclient2);
						break;
					}
					if (DisguiseID[i] == 4)
					{
						PrecacheModel("models/pigeon.mdl", false);
						SetEntityModel(i, "models/pigeon.mdl");
						DisguiseID[i] = 5;
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s disguised %s as a Pigeon", nameclient1, nameclient2);
						break;
					}
					if (DisguiseID[i] == 5)
					{
						PrecacheModel(playermodel[i], false);
						SetEntityModel(i, playermodel[i]);
						DisguiseID[i] = 0;
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s undisguised %s", nameclient1, nameclient2);
						break;
					}
				}
			}
		}
		RemoveAllMenuItems(disguisemenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i) && (IsPlayerAlive(i)))
			{
				if (DisguiseID[i] == 0)
				{
					GetClientName(i, name, sizeof(name));
					AddMenuItem(disguisemenu, name, name);
				}
				else if (DisguiseID[i] == 1)
				{
					GetClientName(i, name, sizeof(name));
					DisguisePrefix = "[Barrel] ";
					StrCat(DisguisePrefix, 64, name);
					AddMenuItem(disguisemenu, name, DisguisePrefix);
				}
				else if (DisguiseID[i] == 2)
				{
					GetClientName(i, name, sizeof(name));
					DisguisePrefix = "[Zombie] ";
					StrCat(DisguisePrefix, 64, name);
					AddMenuItem(disguisemenu, name, DisguisePrefix);
				}
				else if (DisguiseID[i] == 3)
				{
					GetClientName(i, name, sizeof(name));
					DisguisePrefix = "[Bicycle] ";
					StrCat(DisguisePrefix, 64, name);
					AddMenuItem(disguisemenu, name, DisguisePrefix);
				}
				else if (DisguiseID[i] == 4)
				{
					GetClientName(i, name, sizeof(name));
					DisguisePrefix = "[Headcrab] ";
					StrCat(DisguisePrefix, 64, name);
					AddMenuItem(disguisemenu, name, DisguisePrefix);
				}
				else if (DisguiseID[i] == 5)
				{
					GetClientName(i, name, sizeof(name));
					DisguisePrefix = "[Pigeon] ";
					StrCat(DisguisePrefix, 64, name);
					AddMenuItem(disguisemenu, name, DisguisePrefix);
				}
			}
		}
		SetMenuExitBackButton(disguisemenu, true);
		DisplayMenu(disguisemenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public DrugHandle(Handle:drugmenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(drugmenu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					if (DrugStatus[i] == 0)
					{
						DrugStatus[i] = 1;
						new druguserid = GetClientUserId(i);
						ServerCommand("sm_drug #%i", druguserid);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s drugged %s", nameclient1, nameclient2);
						break;
					}
					if (DrugStatus[i] == 1)
					{
						DrugStatus[i] = 0;
						new druguserid = GetClientUserId(i);
						ServerCommand("sm_drug #%i", druguserid);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s undrugged %s", nameclient1, nameclient2);
						break;
					}
				}
			}
		}
		RemoveAllMenuItems(drugmenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, name, sizeof(name));
				if (DrugStatus[i] == 0)
				{
					AddMenuItem(drugmenu, name, name);
				}
				if (DrugStatus[i] == 1)
				{
					DrugString = "[DRUGGED] ";
					StrCat(DrugString, 64, name);
					AddMenuItem(drugmenu, name, DrugString);
				}
			}
		}
		SetMenuExitBackButton(drugmenu, true);
		DisplayMenu(drugmenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public GodHandle(Handle:godmenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(godmenu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					if (GodStatus[i] == 0)
					{
						GodStatus[i] = 1;
						SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s gave %s Godmode", nameclient1, nameclient2);
						break;
					}
					if (GodStatus[i] == 1)
					{
						GodStatus[i] = 0;
						SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s removed %s's Godmode", nameclient1, nameclient2);
						break;
					}
				}
			}
		}
		RemoveAllMenuItems(godmenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, name, sizeof(name));
				if (GodStatus[i] == 0)
				{
					AddMenuItem(godmenu, name, name);
				}
				if (GodStatus[i] == 1)
				{
					GodString = "[GODMODE] ";
					StrCat(GodString, 64, name);
					AddMenuItem(godmenu, name, GodString);
				}
			}
		}
		SetMenuExitBackButton(godmenu, true);
		DisplayMenu(godmenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public InvisHandle(Handle:invismenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(invismenu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					if (InvisStatus[i] == 0)
					{
						InvisStatus[i] = 1;
						SetEntityRenderMode(i, RENDER_NONE);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s made %s invisible", nameclient1, nameclient2);
						break;
					}
					if (InvisStatus[i] == 1)
					{
						InvisStatus[i] = 0;
						SetEntityRenderMode(i, RENDER_NORMAL);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s made %s visible", nameclient1, nameclient2);
						break;
					}
				}
			}
		}
		RemoveAllMenuItems(invismenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, name, sizeof(name));
				if (InvisStatus[i] == 0)
				{
					AddMenuItem(invismenu, name, name);
				}
				if (InvisStatus[i] == 1)
				{
					InvisString = "[INVISIBLE] ";
					StrCat(InvisString, 64, name);
					AddMenuItem(invismenu, name, InvisString);
				}
			}
		}
		SetMenuExitBackButton(invismenu, true);
		DisplayMenu(invismenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public JetHandle(Handle:jetmenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(jetmenu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					if (JetStatus[i] == 0)
					{
						JetStatus[i] = 1;
						FreezeStatus[i] = 0;
						ClipStatus[i] = 0;
						SetEntityMoveType(i, MOVETYPE_FLY);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s gave %s Jetpack", nameclient1, nameclient2);
						break;
					}
					if (JetStatus[i] == 1)
					{
						JetStatus[i] = 0;
						SetEntityMoveType(i, MOVETYPE_WALK);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s removed %s's Jetpack", nameclient1, nameclient2);
						break;
					}
				}
			}
		}
		RemoveAllMenuItems(jetmenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, name, sizeof(name));
				if (JetStatus[i] == 0)
				{
					AddMenuItem(jetmenu, name, name);
				}
				if (JetStatus[i] == 1)
				{
					JetString = "[JETPACK] ";
					StrCat(JetString, 64, name);
					AddMenuItem(jetmenu, name, JetString);
				}
			}
		}
		SetMenuExitBackButton(jetmenu, true);
		DisplayMenu(jetmenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public ClipHandle(Handle:clipmenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(clipmenu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					if (ClipStatus[i] == 0)
					{
						ClipStatus[i] = 1;
						FreezeStatus[i] = 0;
						JetStatus[i] = 0;
						SetEntityMoveType(i, MOVETYPE_NOCLIP);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s gave %s Noclip", nameclient1, nameclient2);
						break;
					}
					if (ClipStatus[i] == 1)
					{
						ClipStatus[i] = 0;
						SetEntityMoveType(i, MOVETYPE_WALK);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s removed %s's Noclip", nameclient1, nameclient2);
						break;
					}
				}
			}
		}
		RemoveAllMenuItems(clipmenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, name, sizeof(name));
				if (ClipStatus[i] == 0)
				{
					AddMenuItem(clipmenu, name, name);
				}
				if (ClipStatus[i] == 1)
				{
					ClipString = "[NOCLIP] ";
					StrCat(ClipString, 64, name);
					AddMenuItem(clipmenu, name, ClipString);
				}
			}
		}
		SetMenuExitBackButton(clipmenu, true);
		DisplayMenu(clipmenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public RegenHandle(Handle:regenmenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(regenmenu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					if (RegenStatus[i] == 0)
					{
						RegenStatus[i] = 1;
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s gave %s Regeneration", nameclient1, nameclient2);
						break;
					}
					if (RegenStatus[i] == 1)
					{
						RegenStatus[i] = 0;
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s removed %s's Regeneration", nameclient1, nameclient2);
						break;
					}
				}
			}
		}
		RemoveAllMenuItems(regenmenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, name, sizeof(name));
				if (RegenStatus[i] == 0)
				{
					AddMenuItem(regenmenu, name, name);
				}
				if (RegenStatus[i] == 1)
				{
					RegenString = "[REGEN] ";
					StrCat(RegenString, 64, name);
					AddMenuItem(regenmenu, name, RegenString);
				}
			}
		}
		SetMenuExitBackButton(regenmenu, true);
		DisplayMenu(regenmenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public RocketHandle(Handle:rocketmenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(rocketmenu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					if (RocketStatus[i] == 0)
					{
						RocketStatus[i] = 1;
						if (RocketType == 1)
						{
							SetEntityGravity(i, -0.1);
							new Float:ABSORIGIN[3];
							GetClientAbsOrigin(i, ABSORIGIN);
							ABSORIGIN[2] = ABSORIGIN[2] + 5;
							TeleportEntity(i, ABSORIGIN, NULL_VECTOR, NULL_VECTOR);
						}
						if (RocketType == 2)
						{
							SetEntityMoveType(i, MOVETYPE_NONE);
						}
						PrecacheSound("weapons/rpg/rocketfire1.wav", false);
						EmitSoundToAll("weapons/rpg/rocketfire1.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
						CreateTimer(0.25, RocketLaunchTimer);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s turned %s into a rocket", nameclient1, nameclient2);
						break;
					}
					if (RocketStatus[i] == 1)
					{
						RocketStatus[i] = 0;
						if (RocketType == 1)
						{
							SetEntityGravity(i, 1.0);
						}
						if (RocketType == 2)
						{
							SetEntityMoveType(i, MOVETYPE_WALK);
						}
						for (new k = 1; k <= (GetMaxClients()+1); k++)
						{
							StopSound(k, SNDCHAN_STATIC, "weapons/rpg/rocket1.wav");
						}
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s removed %s's rocket transformation", nameclient1, nameclient2);
						break;
					}
				}
			}
		}
		RemoveAllMenuItems(rocketmenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, name, sizeof(name));
				if (RocketStatus[i] == 0)
				{
					AddMenuItem(rocketmenu, name, name);
				}
				if (RocketStatus[i] == 1)
				{
					RocketString = "[ROCKET] ";
					StrCat(RocketString, 64, name);
					AddMenuItem(rocketmenu, name, RocketString);
				}
			}
		}
		SetMenuExitBackButton(rocketmenu, true);
		DisplayMenu(rocketmenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public SlapMenu(Handle:slapmenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(slapmenu, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					new String:slayname[64];
					SlapPlayer(i, slapdamage[client], true);
					GetClientName(i, slayname, sizeof(slayname));
					PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s slapped %s for %i damage", nameclient1, slayname, slapdamage[client]);
				}
			}
		}
		RemoveAllMenuItems(slapmenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, name, sizeof(name));
				AddMenuItem(slapmenu, name, name);
			}
		}
		SetMenuExitBackButton(slapmenu, true);
		DisplayMenu(slapmenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public SpeedHandle(Handle:speedmenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		GetClientName(client, nameclient1, sizeof(nameclient1));
		GetMenuItem(speedmenu, param2, nameclient2, sizeof(nameclient2));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					if (SpeedIndex[i] == 0)
					{
						SpeedIndex[i] = 1;
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 2.0); 
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s changed %s's speed to 2X", nameclient1, nameclient2);
						break;
					}
					if (SpeedIndex[i] == 1)
					{
						SpeedIndex[i] = 2;
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 3.0);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s changed %s's speed to 3X", nameclient1, nameclient2);
						break;
					}
					if (SpeedIndex[i] == 2)
					{
						SpeedIndex[i] = 3;
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 4.0);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s changed %s's speed to 4X", nameclient1, nameclient2);
						break;
					}
					if (SpeedIndex[i] == 3)
					{
						SpeedIndex[i] = 4;
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 0.5);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s changed %s's speed to 0.5X", nameclient1, nameclient2);
						break;
					}
					if (SpeedIndex[i] == 4)
					{
						SpeedIndex[i] = 0;
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s changed %s's speed to 1X", nameclient1, nameclient2);
						break;
					}
				}
			}
		}
		RemoveAllMenuItems(speedmenu);
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && IsPlayerAlive(i))
			{
				GetClientName(i, name, sizeof(name));
				if (SpeedIndex[i] == 0)
				{
					AddMenuItem(speedmenu, name, name);
				}
				if (SpeedIndex[i] == 1)
				{
					SpeedString = "[X2] ";
					StrCat(SpeedString, 64, name);
					AddMenuItem(speedmenu, name, SpeedString);
				}
				if (SpeedIndex[i] == 2)
				{
					SpeedString = "[X3] ";
					StrCat(SpeedString, 64, name);
					AddMenuItem(speedmenu, name, SpeedString);
				}
				if (SpeedIndex[i] == 3)
				{
					SpeedString = "[X4] ";
					StrCat(SpeedString, 64, name);
					AddMenuItem(speedmenu, name, SpeedString);
				}
				if (SpeedIndex[i] == 4)
				{
					SpeedString = "[X0.5] ";
					StrCat(SpeedString, 64, name);
					AddMenuItem(speedmenu, name, SpeedString);
				}
			}
		}
		SetMenuExitBackButton(speedmenu, true);
		DisplayMenu(speedmenu, client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			new Handle:menu = CreateMenu(MenuHandler1);
			SetMenuTitle(menu, "FireWaLL Super Admin");
			AddMenuItem(menu, "Player Management", "Player Management");
			AddMenuItem(menu, "Fun Commands", "Fun Commands");
			AddMenuItem(menu, "Prop Menu", "Prop Menu");
			AddMenuItem(menu, "Play Music", "Play Music");
			SetMenuExitButton(menu, true);
			SetMenuExitBackButton(menu, false);
			DisplayMenu(menu, client, 0);
		}
	}
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if (entity == data)
	{
		return false;
	}
	return true;
}

public prop_physics_create(client)
{
	new Float:VecOrigin[3];
	new Float:VecAngles[3];
	new prop = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(prop, "model", modelname);
	//DispatchSpawn(prop);
	if (PropHealth == 1)
	{
		DispatchKeyValue(prop, "health", "1");
	}
	if (Explode == 1)
	{
		DispatchKeyValue(prop, "exploderadius", "1000");
		DispatchKeyValue(prop, "explodedamage", "1");
	}
	GetClientEyePosition(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	TR_TraceRayFilter(VecOrigin, VecAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	TR_GetEndPosition(VecOrigin);
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	VecOrigin[2] = VecOrigin[2] + 10;
	DispatchKeyValue(prop, "StartDisabled", "false");
	DispatchKeyValue(prop, "Solid", "6"); 
	AcceptEntityInput(prop, "TurnOn", prop, prop, 0);
 	SetEntProp(prop, Prop_Data, "m_CollisionGroup", 5);
	SetEntProp(prop, Prop_Data, "m_nSolidType", 6);
	SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
	DispatchSpawn(prop);
	TeleportEntity(prop, VecOrigin, VecAngles, NULL_VECTOR);
	AcceptEntityInput(prop, "EnableCollision");
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s spawned %s", name, phrase);
	
	return 0;
}

public prop_dynamic_create(client)
{
	new Float:VecOrigin[3];
	new Float:VecAngles[3];
	new Float:normal[3];
	new prop = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(prop, "model", modelname);
	GetClientEyePosition(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	TR_TraceRayFilter(VecOrigin, VecAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	TR_GetEndPosition(VecOrigin);
	TR_GetPlaneNormal(INVALID_HANDLE, normal);
	GetVectorAngles(normal, normal);
	normal[0] += 90.0;
	DispatchKeyValue(prop, "StartDisabled", "false");
	DispatchKeyValue(prop, "Solid", "6");
	SetEntProp(prop, Prop_Data, "m_nSolidType", 6);
	DispatchKeyValue(prop, "spawnflags", "8"); 
	SetEntProp(prop, Prop_Data, "m_CollisionGroup", 5);
	TeleportEntity(prop, VecOrigin, normal, NULL_VECTOR);
	DispatchSpawn(prop);
	AcceptEntityInput(prop, "EnableCollision"); 
	AcceptEntityInput(prop, "TurnOn", prop, prop, 0);
	
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s spawned %s", name, phrase);
	
	return 0;
}

public prop_npc_create(client)
{
	new Float:VecOrigin[3];
	new Float:VecAngles[3];
	new Float:normal[3];
	new prop = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(prop, "model", modelname);
	GetClientEyePosition(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	TR_TraceRayFilter(VecOrigin, VecAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	TR_GetEndPosition(VecOrigin);
	TR_GetPlaneNormal(INVALID_HANDLE, normal);
	GetVectorAngles(normal, normal);
	normal[0] += 90.0;
	DispatchKeyValue(prop, "StartDisabled", "false");
	DispatchKeyValue(prop, "Solid", "6");
	SetEntProp(prop, Prop_Data, "m_nSolidType", 6);
	DispatchKeyValue(prop, "spawnflags", "8"); 
	SetEntProp(prop, Prop_Data, "m_CollisionGroup", 5);
	TeleportEntity(prop, VecOrigin, normal, NULL_VECTOR);
	DispatchSpawn(prop);
	AcceptEntityInput(prop, "EnableCollision"); 
	AcceptEntityInput(prop, "TurnOn", prop, prop, 0);
	
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s spawned %s", name, phrase);
	
	return 0;
}

public Action:GameStart(Handle:Event, const String:Name[], bool:Broadcast)
{
	for (new i = 1; i <= (GetMaxClients()+1); i++)
	{
		if (IsValidEntity(i))
		{
			FreezeStatus[i] = 0;
			DisguiseID[i] = 0;
			DrugStatus[i] = 0;
			GodStatus[i] = 0;
			InvisStatus[i] = 0;
			JetStatus[i] = 0;
			RocketStatus[i] = 0;
			RegenStatus[i] = 0;
			SetEntityGravity(i, 1.0);
			SpeedIndex[i] = 0;
		}
	}
}

public Action:StealCookies(client, args)
{
	new String:StolenCookies[64];
	new Target_List[MAXPLAYERS];
	new String:processed[64];
	new bool:thebool;
	GetClientName(client, name, sizeof(name));
	if (args < 1)
	{
		PrintToConsole(client, "Usage: stealcookies <name>");
	}
	if (args > 1)
	{
		PrintToConsole(client, "Usage: stealcookies <name>");
	}
	if (args == 1)
	{
		GetCmdArg(1, StolenCookies, sizeof(StolenCookies));
		if ((ProcessTargetString(StolenCookies, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) == 1)
		{
			ProcessTargetString(StolenCookies, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool);
			PrintToChatAll("\x04%s stole %s's cookies!", name, processed);
		}
		else if ((ProcessTargetString(StolenCookies, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) != 1)
		{
			PrintToChat(client, "[SM] More than 1 matching client found");
		}
	}
	
	return Plugin_Handled;
}

public Action:StealCookiesChat(client, args)
{
	new String:StolenCookies[64];
	new Target_List[MAXPLAYERS];
	new String:processed[64];
	new bool:thebool;
	GetClientName(client, name, sizeof(name));
	if (args < 2)
	{
		PrintToChat(client, "Usage: !stealcookies <name>");
	}
	if (args > 2)
	{
		PrintToChat(client, "Usage: !stealcookies <name>");
	}
	if (args == 2)
	{
		GetCmdArg(2, StolenCookies, sizeof(StolenCookies));
		if ((ProcessTargetString(StolenCookies, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) == 1)
		{
			ProcessTargetString(StolenCookies, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool);
			PrintToChatAll("\x04%s stole %s's cookies!", name, processed);
		}
		else if ((ProcessTargetString(StolenCookies, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) != 1)
		{
			PrintToChat(client, "[SM] More than 1 matching client found");
		}
	}
	
	return Plugin_Handled;
}

public Action:TimerRepeat(Handle:timer)
{
	for (new i = 1; i <= (GetMaxClients()+1); i++)
	{
		if (((RegenStatus[i] == 1) && (GetClientHealth(i) <= 10000) && (IsClientInGame(i)) && (IsPlayerAlive(i))))
		{
			new HealthHP = GetClientHealth(i);
			new ResultingHP = HealthHP + 500;
			SetEntityHealth(i, ResultingHP);
		}
	}
}

public Action:RocketTimer(Handle:timer)
{
	for (new i = 1; i <= (GetMaxClients()+1); i++)
	{
		if ((RocketStatus[i] == 1) && (IsClientInGame(i)) && (IsPlayerAlive(i)))
		{
			if (Rocket1[i] == 1)
			{
				GetClientAbsOrigin(i, RocketVec1[i]);
				RocketZ1[i] = RocketVec1[i][2];
				if (RocketZ1[i] == RocketZ2[i])
				{
					SlapPlayer(i, 64000, false);
					for (new k = 1; k <= (GetMaxClients()+1); k++)
					{
						StopSound(k, SNDCHAN_STATIC, "weapons/rpg/rocket1.wav");
					}
					PrecacheSound("weapons/explode3.wav", false);
					EmitSoundToAll("weapons/explode3.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				}
				Rocket1[i] = 0;
				break;
			}
			if (Rocket1[i] == 0)
			{
				GetClientAbsOrigin(i, RocketVec2[i]);
				RocketZ2[i] = RocketVec2[i][2];
				if (RocketZ2[i] == RocketZ1[i])
				{
					SlapPlayer(i, 64000, false);
					for (new k = 1; k <= (GetMaxClients()+1); k++)
					{
						StopSound(k, SNDCHAN_STATIC, "weapons/rpg/rocket1.wav");
					}
					PrecacheSound("weapons/explode3.wav", false);
					EmitSoundToAll("weapons/explode3.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				}
				Rocket1[i] = 1;
				break;
			}
		}
	}
}

public Action:RocketTimer2(Handle:timer)
{
	for (new i = 1; i <= (GetMaxClients()+1); i++)
	{
		if ((RocketStatus[i] == 1) && (IsClientInGame(i)) && (IsPlayerAlive(i)))
		{
			new Float:RocketAbsOrigin[3];
			new Float:RocketEndOrigin[3];
			GetClientEyePosition(i, RocketAbsOrigin);
			new Float:AbsAngle[3];
			AbsAngle[0] = -90.0;
			AbsAngle[1] = 0.0;
			AbsAngle[2] = 0.0;
			TR_TraceRayFilter(RocketAbsOrigin, AbsAngle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf);
			TR_GetEndPosition(RocketEndOrigin);
			new Float:DistanceBetween = RocketEndOrigin[2] - RocketAbsOrigin[2];
			if (DistanceBetween <= 9)
			{
				SlapPlayer(i, 64000, false);
				for (new k = 1; k <= (GetMaxClients()+1); k++)
				{
					StopSound(k, SNDCHAN_STATIC, "weapons/rpg/rocket1.wav");
				}
				PrecacheSound("weapons/explode3.wav", false);
				EmitSoundToAll("weapons/explode3.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				if (IsPlayerAlive(i))
				{
					RocketStatus[i] = 0;
					SetEntityMoveType(i, MOVETYPE_WALK);
				}
				break;
			}
			new Float:ClientOrigin[3];
			GetClientAbsOrigin(i, ClientOrigin);
			ClientOrigin[2] = ClientOrigin[2] + 8.0;
			TeleportEntity(i, ClientOrigin, NULL_VECTOR, NULL_VECTOR);
			break;
		}
	}
}

public Action:PlayerDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	new dieduserid = GetEventInt(Event, "userid");
	new diedindex = GetClientOfUserId(dieduserid);
	RocketStatus[diedindex] = 0;
	FreezeStatus[diedindex] = 0;
	ClipStatus[diedindex] = 0;
	JetStatus[diedindex] = 0;
	DrugStatus[diedindex] = 0;
	DisguiseID[diedindex] = 0;
	RegenStatus[diedindex] = 0;
	GodStatus[diedindex] = 0;
	InvisStatus[diedindex] = 0;
	SetEntityGravity(diedindex, 1.0);
	SpeedIndex[diedindex] = 0;
}

public OnClientPostAdminCheck(client)
{
	PrintToChat(client, "\x03[\x04FSA\x03] \x01This server runs the highly advanced admin menu \x03FireWaLL Super Admin \x01by \x04LightningZLaser");
}

public Action:BuryChat(client, args)
{
	new String:ChatString[64];
	new Target_List[MAXPLAYERS];
	new String:processed[64];
	new bool:thebool;
	GetClientName(client, name, sizeof(name));
	if (args < 1)
	{
		PrintToChat(client, "Usage: !bury <name>");
	}
	if (args > 1)
	{
		PrintToChat(client, "Usage: !bury <name>");
	}
	if (args == 1)
	{
		GetCmdArg(1, ChatString, sizeof(ChatString));
		if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) == 1)
		{
			ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool);
			new String:nameclient1[64];
			new String:nameclient2[64];
			GetClientName(client, nameclient1, sizeof(nameclient1));
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				GetClientName(i, nameclient2, sizeof(nameclient2));
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if ((StrEqual(processed, nameclient2, true)) && (IsClientInGame(i)))
					{
						new Float:buryvec[3];
						GetClientAbsOrigin(i, buryvec);
						buryvec[2] = buryvec[2] - 50;
						TeleportEntity(i, buryvec, NULL_VECTOR, NULL_VECTOR);
						new String:buryname[64];
						GetClientName(i, buryname, sizeof(buryname));
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s buried %s", nameclient1, nameclient2);
					}
				}
			}
		}
		else if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) != 1)
		{
			PrintToChat(client, "[SM] More than 1 matching client found");
		}
	}
	
	return Plugin_Handled;
}

public Action:UnburyChat(client, args)
{
	new String:ChatString[64];
	new Target_List[MAXPLAYERS];
	new String:processed[64];
	new bool:thebool;
	GetClientName(client, name, sizeof(name));
	if (args < 1)
	{
		PrintToChat(client, "Usage: !unbury <name>");
	}
	if (args > 1)
	{
		PrintToChat(client, "Usage: !unbury <name>");
	}
	if (args == 1)
	{
		GetCmdArg(1, ChatString, sizeof(ChatString));
		if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) == 1)
		{
			ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool);
			new String:nameclient1[64];
			new String:nameclient2[64];
			GetClientName(client, nameclient1, sizeof(nameclient1));
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				GetClientName(i, nameclient2, sizeof(nameclient2));
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if ((StrEqual(processed, nameclient2, true)) && (IsClientInGame(i)))
					{
						new Float:buryvec[3];
						GetClientAbsOrigin(i, buryvec);
						buryvec[2] = buryvec[2] + 50;
						TeleportEntity(i, buryvec, NULL_VECTOR, NULL_VECTOR);
						new String:buryname[64];
						GetClientName(i, buryname, sizeof(buryname));
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s unburied %s", nameclient1, nameclient2);
					}
				}
			}
		}
		else if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) != 1)
		{
			PrintToChat(client, "[SM] More than 1 matching client found");
		}
	}
	
	return Plugin_Handled;
}

public Action:DisarmChat(client, args)
{
	new String:ChatString[64];
	new Target_List[MAXPLAYERS];
	new String:processed[64];
	new bool:thebool;
	GetClientName(client, name, sizeof(name));
	if (args < 1)
	{
		PrintToChat(client, "Usage: !disarm <name>");
	}
	if (args > 1)
	{
		PrintToChat(client, "Usage: !disarm <name>");
	}
	if (args == 1)
	{
		GetCmdArg(1, ChatString, sizeof(ChatString));
		if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) == 1)
		{
			ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool);
			new String:nameclient1[64];
			new String:nameclient2[64];
			GetClientName(client, nameclient1, sizeof(nameclient1));
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				GetClientName(i, nameclient2, sizeof(nameclient2));
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if ((StrEqual(processed, nameclient2, true)) && (IsClientInGame(i)))
					{
						new weaponid;
						weaponid = GetPlayerWeaponSlot(i, 0);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 1);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 2);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 3);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 4);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 5);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 6);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 7);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 8);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 9);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 10);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 11);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 0);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 1);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 2);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 3);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 4);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 5);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 6);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 7);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 8);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 9);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 10);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 11);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 0);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 1);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 2);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 3);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 4);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 5);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 6);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 7);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 8);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 9);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 10);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 11);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 0);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 1);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 2);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 3);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 4);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 5);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 6);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 7);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 8);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 9);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 10);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						weaponid = GetPlayerWeaponSlot(i, 11);
						if (weaponid != -1)
						{
							RemovePlayerItem(i, weaponid);
						}
						new String:disarmname[64];
						GetClientName(i, disarmname, sizeof(disarmname));
						PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s disarmed %s", nameclient1, disarmname);
					}
				}
			}
		}
		else if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) != 1)
		{
			PrintToChat(client, "[SM] More than 1 matching client found");
		}
	}
	
	return Plugin_Handled;
}

public Action:DisguiseChat(client, args)
{
	new String:ChatString[64];
	new Target_List[MAXPLAYERS];
	new String:processed[64];
	new bool:thebool;
	GetClientName(client, name, sizeof(name));
	if (args < 1)
	{
		PrintToChat(client, "Usage: !disguise <name>");
	}
	if (args > 1)
	{
		PrintToChat(client, "Usage: !disguise <name>");
	}
	if (args == 1)
	{
		GetCmdArg(1, ChatString, sizeof(ChatString));
		if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) == 1)
		{
			ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool);
			new String:nameclient1[64];
			new String:nameclient2[64];
			GetClientName(client, nameclient1, sizeof(nameclient1));
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				GetClientName(i, nameclient2, sizeof(nameclient2));
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if ((StrEqual(processed, nameclient2, true)) && (IsClientInGame(i)))
					{
						if (DisguiseID[i] == 0)
						{
							GetClientModel(i, playermodel[i], 100);
							PrecacheModel("models/props_c17/oildrum001.mdl", false);
							SetEntityModel(i, "models/props_c17/oildrum001.mdl");
							DisguiseID[i] = 1;
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s disguised %s as a Barrel", nameclient1, nameclient2);
							break;
						}
						if (DisguiseID[i] == 1)
						{
							PrecacheModel("models/zombie/classic.mdl", false);
							SetEntityModel(i, "models/zombie/classic.mdl");
							DisguiseID[i] = 2;
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s disguised %s as a Zombie", nameclient1, nameclient2);
							break;
						}
						if (DisguiseID[i] == 2)
						{
							PrecacheModel("models/props_junk/bicycle01a.mdl", false);
							SetEntityModel(i, "models/props_junk/bicycle01a.mdl");
							DisguiseID[i] = 3;
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s disguised %s as a Bicycle", nameclient1, nameclient2);
							break;
						}
						if (DisguiseID[i] == 3)
						{
							PrecacheModel("models/headcrabclassic.mdl", false);
							SetEntityModel(i, "models/headcrabclassic.mdl");
							DisguiseID[i] = 4;
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s disguised %s as a Headcrab", nameclient1, nameclient2);
							break;
						}
						if (DisguiseID[i] == 4)
						{
							PrecacheModel("models/pigeon.mdl", false);
							SetEntityModel(i, "models/pigeon.mdl");
							DisguiseID[i] = 5;
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s disguised %s as a Pigeon", nameclient1, nameclient2);
							break;
						}
						if (DisguiseID[i] == 5)
						{
							PrecacheModel(playermodel[i], false);
							SetEntityModel(i, playermodel[i]);
							DisguiseID[i] = 0;
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s undisguised %s", nameclient1, nameclient2);
							break;
						}
					}
				}
			}
		}
		else if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) != 1)
		{
			PrintToChat(client, "[SM] More than 1 matching client found");
		}
	}
	
	return Plugin_Handled;
}

public Action:GodChat(client, args)
{
	new String:ChatString[64];
	new Target_List[MAXPLAYERS];
	new String:processed[64];
	new bool:thebool;
	GetClientName(client, name, sizeof(name));
	if (args < 1)
	{
		PrintToChat(client, "Usage: !god <name>");
	}
	if (args > 1)
	{
		PrintToChat(client, "Usage: !god <name>");
	}
	if (args == 1)
	{
		GetCmdArg(1, ChatString, sizeof(ChatString));
		if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) == 1)
		{
			ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool);
			new String:nameclient1[64];
			new String:nameclient2[64];
			GetClientName(client, nameclient1, sizeof(nameclient1));
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				GetClientName(i, nameclient2, sizeof(nameclient2));
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if ((StrEqual(processed, nameclient2, true)) && (IsClientInGame(i)))
					{
						if (GodStatus[i] == 0)
						{
							GodStatus[i] = 1;
							SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s gave %s Godmode", nameclient1, nameclient2);
							break;
						}
						if (GodStatus[i] == 1)
						{
							GodStatus[i] = 0;
							SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s removed %s's Godmode", nameclient1, nameclient2);
							break;
						}
					}
				}
			}
		}
		else if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) != 1)
		{
			PrintToChat(client, "[SM] More than 1 matching client found");
		}
	}
	
	return Plugin_Handled;
}

public Action:InvisChat(client, args)
{
	new String:ChatString[64];
	new Target_List[MAXPLAYERS];
	new String:processed[64];
	new bool:thebool;
	GetClientName(client, name, sizeof(name));
	if (args < 1)
	{
		PrintToChat(client, "Usage: !invis <name>");
	}
	if (args > 1)
	{
		PrintToChat(client, "Usage: !invis <name>");
	}
	if (args == 1)
	{
		GetCmdArg(1, ChatString, sizeof(ChatString));
		if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) == 1)
		{
			ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool);
			new String:nameclient1[64];
			new String:nameclient2[64];
			GetClientName(client, nameclient1, sizeof(nameclient1));
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				GetClientName(i, nameclient2, sizeof(nameclient2));
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if ((StrEqual(processed, nameclient2, true)) && (IsClientInGame(i)))
					{
						if (InvisStatus[i] == 0)
						{
							InvisStatus[i] = 1;
							SetEntityRenderMode(i, RENDER_NONE);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s made %s invisible", nameclient1, nameclient2);
							break;
						}
						if (InvisStatus[i] == 1)
						{
							InvisStatus[i] = 0;
							SetEntityRenderMode(i, RENDER_NORMAL);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s made %s visible", nameclient1, nameclient2);
							break;
						}
					}
				}
			}
		}
		else if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) != 1)
		{
			PrintToChat(client, "[SM] More than 1 matching client found");
		}
	}
	
	return Plugin_Handled;
}

public Action:JetChat(client, args)
{
	new String:ChatString[64];
	new Target_List[MAXPLAYERS];
	new String:processed[64];
	new bool:thebool;
	GetClientName(client, name, sizeof(name));
	if (args < 1)
	{
		PrintToChat(client, "Usage: !jet <name>");
	}
	if (args > 1)
	{
		PrintToChat(client, "Usage: !jet <name>");
	}
	if (args == 1)
	{
		GetCmdArg(1, ChatString, sizeof(ChatString));
		if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) == 1)
		{
			ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool);
			new String:nameclient1[64];
			new String:nameclient2[64];
			GetClientName(client, nameclient1, sizeof(nameclient1));
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				GetClientName(i, nameclient2, sizeof(nameclient2));
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if ((StrEqual(processed, nameclient2, true)) && (IsClientInGame(i)))
					{
						if (JetStatus[i] == 0)
						{
							JetStatus[i] = 1;
							FreezeStatus[i] = 0;
							ClipStatus[i] = 0;
							SetEntityMoveType(i, MOVETYPE_FLY);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s gave %s Jetpack", nameclient1, nameclient2);
							break;
						}
						if (JetStatus[i] == 1)
						{
							JetStatus[i] = 0;
							SetEntityMoveType(i, MOVETYPE_WALK);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s removed %s's Jetpack", nameclient1, nameclient2);
							break;
						}
					}
				}
			}
		}
		else if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) != 1)
		{
			PrintToChat(client, "[SM] More than 1 matching client found");
		}
	}
	
	return Plugin_Handled;
}

public Action:ClipChat(client, args)
{
	new String:ChatString[64];
	new Target_List[MAXPLAYERS];
	new String:processed[64];
	new bool:thebool;
	GetClientName(client, name, sizeof(name));
	if (args < 1)
	{
		PrintToChat(client, "Usage: !clip <name>");
	}
	if (args > 1)
	{
		PrintToChat(client, "Usage: !clip <name>");
	}
	if (args == 1)
	{
		GetCmdArg(1, ChatString, sizeof(ChatString));
		if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) == 1)
		{
			ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool);
			new String:nameclient1[64];
			new String:nameclient2[64];
			GetClientName(client, nameclient1, sizeof(nameclient1));
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				GetClientName(i, nameclient2, sizeof(nameclient2));
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if ((StrEqual(processed, nameclient2, true)) && (IsClientInGame(i)))
					{
						if (ClipStatus[i] == 0)
						{
							ClipStatus[i] = 1;
							FreezeStatus[i] = 0;
							JetStatus[i] = 0;
							SetEntityMoveType(i, MOVETYPE_NOCLIP);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s gave %s Noclip", nameclient1, nameclient2);
							break;
						}
						if (ClipStatus[i] == 1)
						{
							ClipStatus[i] = 0;
							SetEntityMoveType(i, MOVETYPE_WALK);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s removed %s's Noclip", nameclient1, nameclient2);
							break;
						}
					}
				}
			}
		}
		else if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) != 1)
		{
			PrintToChat(client, "[SM] More than 1 matching client found");
		}
	}
	
	return Plugin_Handled;
}

public Action:RegenChat(client, args)
{
	new String:ChatString[64];
	new Target_List[MAXPLAYERS];
	new String:processed[64];
	new bool:thebool;
	GetClientName(client, name, sizeof(name));
	if (args < 1)
	{
		PrintToChat(client, "Usage: !regen <name>");
	}
	if (args > 1)
	{
		PrintToChat(client, "Usage: !regen <name>");
	}
	if (args == 1)
	{
		GetCmdArg(1, ChatString, sizeof(ChatString));
		if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) == 1)
		{
			ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool);
			new String:nameclient1[64];
			new String:nameclient2[64];
			GetClientName(client, nameclient1, sizeof(nameclient1));
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				GetClientName(i, nameclient2, sizeof(nameclient2));
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if ((StrEqual(processed, nameclient2, true)) && (IsClientInGame(i)))
					{
						if (RegenStatus[i] == 0)
						{
							RegenStatus[i] = 1;
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s gave %s Regeneration", nameclient1, nameclient2);
							break;
						}
						if (RegenStatus[i] == 1)
						{
							RegenStatus[i] = 0;
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s removed %s's Regeneration", nameclient1, nameclient2);
							break;
						}
					}
				}
			}
		}
		else if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) != 1)
		{
			PrintToChat(client, "[SM] More than 1 matching client found");
		}
	}
	
	return Plugin_Handled;
}

public Action:RocketChat(client, args)
{
	new String:ChatString[64];
	new Target_List[MAXPLAYERS];
	new String:processed[64];
	new bool:thebool;
	GetClientName(client, name, sizeof(name));
	if (args < 1)
	{
		PrintToChat(client, "Usage: !rocket <name>");
	}
	if (args > 1)
	{
		PrintToChat(client, "Usage: !rocket <name>");
	}
	if (args == 1)
	{
		GetCmdArg(1, ChatString, sizeof(ChatString));
		if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) == 1)
		{
			ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool);
			new String:nameclient1[64];
			new String:nameclient2[64];
			GetClientName(client, nameclient1, sizeof(nameclient1));
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				GetClientName(i, nameclient2, sizeof(nameclient2));
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if ((StrEqual(processed, nameclient2, true)) && (IsClientInGame(i)))
					{
						if (RocketStatus[i] == 0)
						{
							RocketStatus[i] = 1;
							if (RocketType == 1)
							{
								SetEntityGravity(i, -0.1);
								new Float:ABSORIGIN[3];
								GetClientAbsOrigin(i, ABSORIGIN);
								ABSORIGIN[2] = ABSORIGIN[2] + 5;
								TeleportEntity(i, ABSORIGIN, NULL_VECTOR, NULL_VECTOR);
							}
							if (RocketType == 2)
							{
								SetEntityMoveType(i, MOVETYPE_NONE);
							}
							PrecacheSound("weapons/rpg/rocketfire1.wav", false);
							EmitSoundToAll("weapons/rpg/rocketfire1.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
							CreateTimer(0.25, RocketLaunchTimer);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s turned %s into a rocket", nameclient1, nameclient2);
							break;
						}
						if (RocketStatus[i] == 1)
						{
							RocketStatus[i] = 0;
							if (RocketType == 1)
							{
								SetEntityGravity(i, 1.0);
							}
							if (RocketType == 2)
							{
								SetEntityMoveType(i, MOVETYPE_WALK);
							}
							for (new k = 1; k <= (GetMaxClients()+1); k++)
							{
								StopSound(k, SNDCHAN_STATIC, "weapons/rpg/rocket1.wav");
							}
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s removed %s's rocket transformation", nameclient1, nameclient2);
							break;
						}
					}
				}
			}
		}
		else if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) != 1)
		{
			PrintToChat(client, "[SM] More than 1 matching client found");
		}
	}
	
	return Plugin_Handled;
}

public Action:SpeedChat(client, args)
{
	new String:ChatString[64];
	new Target_List[MAXPLAYERS];
	new String:processed[64];
	new bool:thebool;
	GetClientName(client, name, sizeof(name));
	if (args < 1)
	{
		PrintToChat(client, "Usage: !speed <name>");
	}
	if (args > 1)
	{
		PrintToChat(client, "Usage: !speed <name>");
	}
	if (args == 1)
	{
		GetCmdArg(1, ChatString, sizeof(ChatString));
		if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) == 1)
		{
			ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool);
			new String:nameclient1[64];
			new String:nameclient2[64];
			GetClientName(client, nameclient1, sizeof(nameclient1));
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				GetClientName(i, nameclient2, sizeof(nameclient2));
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if ((StrEqual(processed, nameclient2, true)) && (IsClientInGame(i)))
					{
						if (SpeedIndex[i] == 0)
						{
							SpeedIndex[i] = 1;
							SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 2.0); 
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s changed %s's speed to 2X", nameclient1, nameclient2);
							break;
						}
						if (SpeedIndex[i] == 1)
						{
							SpeedIndex[i] = 2;
							SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 3.0);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s changed %s's speed to 3X", nameclient1, nameclient2);
							break;
						}
						if (SpeedIndex[i] == 2)
						{
							SpeedIndex[i] = 3;
							SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 4.0);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s changed %s's speed to 4X", nameclient1, nameclient2);
							break;
						}
						if (SpeedIndex[i] == 3)
						{
							SpeedIndex[i] = 4;
							SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 0.5);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s changed %s's speed to 0.5X", nameclient1, nameclient2);
							break;
						}
						if (SpeedIndex[i] == 4)
						{
							SpeedIndex[i] = 0;
							SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
							PrintToChatAll("\x03[\x04FSA\x03] \x01(ADMIN) %s changed %s's speed to 1X", nameclient1, nameclient2);
							break;
						}
					}
				}
			}
		}
		else if ((ProcessTargetString(ChatString, client, Target_List, MAXPLAYERS, 0, processed, sizeof(processed), thebool)) != 1)
		{
			PrintToChat(client, "[SM] More than 1 matching client found");
		}
	}
	
	return Plugin_Handled;
}

public Action:RocketLaunchTimer(Handle:timer)
{
	PrecacheSound("weapons/rpg/rocket1.wav", false);
	EmitSoundToAll("weapons/rpg/rocket1.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}