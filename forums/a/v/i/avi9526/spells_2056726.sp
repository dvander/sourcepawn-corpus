//──────────────────────────────────────────────────────────────────────────────
#pragma semicolon 1
//──────────────────────────────────────────────────────────────────────────────
#include <sourcemod>
#include <sdktools>
#include <tf2>
//──────────────────────────────────────────────────────────────────────────────
#define PLUGIN_VERSION "2.0.1"
//──────────────────────────────────────────────────────────────────────────────
#define FIREBALL	0 // Done
#define BATS 		1 // Done
#define PUMPKIN 	2 // Done
#define TELE 		3 // Done
#define LIGHTNING 	4 // Done
#define BOSS 		5 // Done
#define METEOR 		6 // Done
#define ZOMBIEH 	7 // Done
#define ZOMBIE 		8
#define PUMPKIN2 	9
//──────────────────────────────────────────────────────────────────────────────
#define LOG_PREFIX	"[Spells]"
#define CHAT_PREFIX	"\x01[\x07B262FFSpells\x01]"
//──────────────────────────────────────────────────────────────────────────────
public Plugin:myinfo = 
{
	name = "[TF2] Spells",
	author = "Mitch (base) & avi9526 (menu)",
	description = "Allows Players to shoot spells",
	version = PLUGIN_VERSION,
	url = "http://www.mitch.dev/"
}
//──────────────────────────────────────────────────────────────────────────────
// Global variables
//──────────────────────────────────────────────────────────────────────────────
new Handle:	cCheatOverride;
// Global Handle Console Variable - Delay
new Handle:	hDelay	= INVALID_HANDLE;
// Delay
new 		Delay	= 60;
// Store individual player data needed to plugin
enum PlayerData
{
	TimeUsed	// when player last time used menu
};
// Array
new Players[MAXPLAYERS+1][PlayerData];
//──────────────────────────────────────────────────────────────────────────────
// Hook functions
//──────────────────────────────────────────────────────────────────────────────
public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_spells_version", PLUGIN_VERSION, "Spells Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	//cCheatOverride = CreateConVar("sm_admin_spell_level", "a", "Level required to execute the spell commands",FCVAR_PLUGIN);
	
	hDelay = CreateConVar("sm_spelldelay", "60", "How much player must wait before use spell again", _, true, 20.0, false, 100.0);
	Delay = GetConVarInt(hDelay);
	HookConVarChange(hDelay, OnConVarChanged);
	
	// Spells menu
	RegConsoleCmd("sm_spells", Command_Menu, "Spells menu");
	
	//Fireball
	RegAdminCmd("sm_firebolt", Command_Firebolt, ADMFLAG_GENERIC, "Fires a fireball");
	RegAdminCmd("sm_fireball", Command_Firebolt, ADMFLAG_GENERIC, "Fires a fireball");
	
	//Lightning Orb
	RegAdminCmd("sm_lightning", 	Command_Lightning, ADMFLAG_GENERIC, "Fires a lightning orb");
	RegAdminCmd("sm_lightningorb", 	Command_Lightning, ADMFLAG_GENERIC, "Fires a lightning orb");
	
	//Transpose
	RegAdminCmd("sm_transpose", Command_Transpose, ADMFLAG_GENERIC, "Teleports");
	RegAdminCmd("sm_tele", 		Command_Transpose, ADMFLAG_GENERIC, "Teleports");
	
	//Bats
	RegAdminCmd("sm_bat", 	Command_Bats, ADMFLAG_GENERIC, "Bat Spell");
	RegAdminCmd("sm_bats", 	Command_Bats, ADMFLAG_GENERIC, "Bat Spell");
	
	//Meteor
	RegAdminCmd("sm_meteor", 		Command_Meteor, ADMFLAG_GENERIC, "Meteor Shower");
	RegAdminCmd("sm_meteorshower", 	Command_Meteor, ADMFLAG_GENERIC, "Meteor Shower");
	
	//Pumpkin Multiple/Single
	RegAdminCmd("sm_pumpkin", 	Command_Pumpkin, ADMFLAG_GENERIC, "Single Pumpkin");
	RegAdminCmd("sm_pumpkins", 	Command_Pumpkin2, ADMFLAG_GENERIC, "Multiple Pumpkins");
	
	//Monoculus
	RegAdminCmd("sm_boss", 		Command_Boss, ADMFLAG_GENERIC, "Spawns a Team Monoculus.");
	RegAdminCmd("sm_monoculus", Command_Boss, ADMFLAG_GENERIC, "Spawns a Team Monoculus.");
	
	//Zombies
	RegAdminCmd("sm_zombie", 		Command_Skeleton, ADMFLAG_GENERIC, "Spawns a skeleton.");
	RegAdminCmd("sm_skelespell", 	Command_Skeleton, ADMFLAG_GENERIC, "Spawns a skeleton."); // This may collide with Be The Skeleton....
	RegAdminCmd("sm_skele", 		Command_Skeleton, ADMFLAG_GENERIC, "Spawns a skeleton.");
	RegAdminCmd("sm_horde",		 	Command_SkeletonH, ADMFLAG_GENERIC, "Spawns 3 skeletons.");
	RegAdminCmd("sm_skeletonhorde", Command_SkeletonH, ADMFLAG_GENERIC, "Spawns 3 skeletons.");
	RegAdminCmd("sm_zombiehorde", 	Command_SkeletonH, ADMFLAG_GENERIC, "Spawns 3 skeletons.");
	
	
	
	
	//RegConsoleCmd("tf_test_spellindex",SpellCommand);
	//SetCommandFlags("tf_test_spellindex",GetCommandFlags("tf_test_spellindex")^FCVAR_CHEAT);
}
//──────────────────────────────────────────────────────────────────────────────
// If console variable changed - need change corresponding internal variables
public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == hDelay)
	{
		Delay = StringToInt(newValue);
		LogAction(-1, -1, "%s Delay now is %d", LOG_PREFIX, Delay);
	}
}
//──────────────────────────────────────────────────────────────────────────────
public OnPluginEnd()
{
	ResetAllData();
}
//──────────────────────────────────────────────────────────────────────────────
public OnMapStart()
{
	ResetAllData();
}
//──────────────────────────────────────────────────────────────────────────────
public OnClientDisconnect(client)
{
	ResetPlayerData(client);
}
//──────────────────────────────────────────────────────────────────────────────
// Stocks
//──────────────────────────────────────────────────────────────────────────────
// Ckeck if client is normal player (human) that already in game, not bot or etc
stock IsValidClient(Client)
{
	if ((Client <= 0) || (Client > MaxClients) || (!IsClientInGame(Client)))
	{
		return false;
	}
	if (IsClientSourceTV(Client) || IsClientReplay(Client))
	{
		return false;
	}
	// Skip bots
	new String:Auth[32];
	GetClientAuthString(Client, Auth, sizeof(Auth));
	if (StrEqual(Auth, "BOT", false) || StrEqual(Auth, "STEAM_ID_PENDING", false) || StrEqual(Auth, "STEAM_ID_LAN", false))
	{
		return false;
	}
	return true;
}
//──────────────────────────────────────────────────────────────────────────────
// Variables support
//──────────────────────────────────────────────────────────────────────────────
ResetPlayerData(client)
{
	Players[client][TimeUsed] = 0;
}
//──────────────────────────────────────────────────────────────────────────────
ResetAllData()
{
	for(new cli=0; cli<MAXPLAYERS+1; cli++)
		{
			ResetPlayerData(cli);
		}
}
//──────────────────────────────────────────────────────────────────────────────
// Menu
//──────────────────────────────────────────────────────────────────────────────
// Console command to call menu
public Action:Command_Menu(client, args)
{
	ShowMenu(client);
	return Plugin_Handled;
}
//──────────────────────────────────────────────────────────────────────────────
// Function to show menu
public ShowMenu(client)
{
	if (!IsValidClient(client))
	{
		LogAction(-1, -1, "%s Wrong client '%L' triggered this function", LOG_PREFIX, client);
		return;
	}
	
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s You must be alive", CHAT_PREFIX);
		return;
	}
	
	
	// How much time passed since last use of spell menu
	new TimePass = GetTime() - Players[client][TimeUsed];
	if(Players[client][TimeUsed] && TimePass < Delay)
	{
		// If less than delay - tell player to wait more
		PrintToChat(client, "%s You must wait %d seconds before use spells again", CHAT_PREFIX, Delay - TimePass);
		return;
	}

	new Handle:Menu = CreateMenu(MenuHandler, MenuAction_Start|MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	SetMenuTitle(Menu, "Spells");
	
	AddMenuItem(Menu, "Fireball", "Fireball");
	AddMenuItem(Menu, "Lightning", "Lightning Orb");
	AddMenuItem(Menu, "Transpose", "Transpose");
	//AddMenuItem(Menu, "Bats", "Bats");
	AddMenuItem(Menu, "MeteorShower", "Meteor Shower");
	//AddMenuItem(Menu, "Pumpkin", "Pumpkin");
	AddMenuItem(Menu, "Pumpkins", "Pumpkin ring");
	AddMenuItem(Menu, "Monoculus", "Monoculus");
	//AddMenuItem(Menu, "Skeleton", "Skeleton");
	AddMenuItem(Menu, "Skeletons", "Skeletons Horde");
	
	SetMenuExitButton(Menu, true);
	DisplayMenu(Menu, client, 20);

	return;
}
//──────────────────────────────────────────────────────────────────────────────
// Menu action handling
public MenuHandler(Handle:Menu, MenuAction:action, param1, param2)
{
	if(action==MenuAction_Select)
		{
			decl String:Info[32];
			GetMenuItem(Menu, param2, Info, sizeof(Info));
			
			// Selector
			if(StrEqual(Info, "Fireball"))
			{
				ShootProjectile(param1, FIREBALL);
			}
			else if(StrEqual(Info, "Lightning"))
			{
				ShootProjectile(param1, LIGHTNING);
			}
			else if(StrEqual(Info, "Transpose"))
			{
				ShootProjectile(param1, TELE);
			}
			else if(StrEqual(Info, "Bats"))
			{
				ShootProjectile(param1, BATS);
			}
			else if(StrEqual(Info, "MeteorShower"))
			{
				ShootProjectile(param1, METEOR);
			}
			else if(StrEqual(Info, "Pumpkin"))
			{
				ShootProjectile(param1, PUMPKIN);
			}
			else if(StrEqual(Info, "Pumpkins"))
			{
				ShootProjectile(param1, PUMPKIN);
			}
			else if(StrEqual(Info, "Monoculus"))
			{
				ShootProjectile(param1, BOSS);
			}
			else if(StrEqual(Info, "Skeleton"))
			{
				ShootProjectile(param1, ZOMBIE);
			}
			else if(StrEqual(Info, "Skeletons"))
			{
				ShootProjectile(param1, ZOMBIEH);
			}
			
			// Save time when player used spell
			Players[param1][TimeUsed] = GetTime();
		}

	if(action==MenuAction_End)
	{
		CloseHandle(Menu);
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Internal routines
//──────────────────────────────────────────────────────────────────────────────
ShootProjectile(client, spell)
{
	new Float:vAngles[3]; // original
	new Float:vPosition[3]; // original
	GetClientEyeAngles(client, vAngles);
	GetClientEyePosition(client, vPosition);
	new String:strEntname[45] = "";
	switch(spell)
	{
		case FIREBALL: 		strEntname = "tf_projectile_spellfireball";
		case LIGHTNING: 	strEntname = "tf_projectile_lightningorb";
		case PUMPKIN: 		strEntname = "tf_projectile_spellmirv";
		case PUMPKIN2: 		strEntname = "tf_projectile_spellpumpkin";
		case BATS: 			strEntname = "tf_projectile_spellbats";
		case METEOR: 		strEntname = "tf_projectile_spellmeteorshower";
		case TELE: 			strEntname = "tf_projectile_spelltransposeteleport";
		case BOSS:			strEntname = "tf_projectile_spellspawnboss";
		case ZOMBIEH:		strEntname = "tf_projectile_spellspawnhorde";
		case ZOMBIE:		strEntname = "tf_projectile_spellspawnzombie";
	}
	new iTeam = GetClientTeam(client);
	new iSpell = CreateEntityByName(strEntname);
	
	if(!IsValidEntity(iSpell))
		return -1;
	
	decl Float:vVelocity[3];
	decl Float:vBuffer[3];
	
	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	
	vVelocity[0] = vBuffer[0]*1100.0; //Speed of a tf2 rocket.
	vVelocity[1] = vBuffer[1]*1100.0;
	vVelocity[2] = vBuffer[2]*1100.0;
	
	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iSpell,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iSpell,    Prop_Send, "m_iTeamNum",     iTeam, 1);
	SetEntProp(iSpell,    Prop_Send, "m_nSkin", (iTeam-2));
	
	TeleportEntity(iSpell, vPosition, vAngles, NULL_VECTOR);
	/*switch(spell)
	{
		case FIREBALL, LIGHTNING:
		{
			TeleportEntity(iSpell, vPosition, vAngles, vVelocity);
		}
		case BATS, METEOR, TELE:
		{
			//TeleportEntity(iSpell, vPosition, vAngles, vVelocity);
			//SetEntPropVector(iSpell, Prop_Send, "m_vecForce", vVelocity);
			
		}
	}*/
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iSpell);
	/*
	switch(spell)
	{
		//These spells have arcs.
		case BATS, METEOR, TELE:
		{
			vVelocity[2] += 32.0;
		}
	}*/
	TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, vVelocity);
	
	return iSpell;
}
//──────────────────────────────────────────────────────────────────────────────
// Other console commands
//──────────────────────────────────────────────────────────────────────────────
public Action:SpellCommand(client, args)
{
	new String:access[8];
	GetConVarString(cCheatOverride,access,8);
	if (client == 0)
	{
		return Plugin_Handled;
	}
	if (GetUserFlagBits(client)&ReadFlagString(access) > 0 || GetUserFlagBits(client)&ADMFLAG_ROOT > 0)
	{
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action:Command_Firebolt(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Command is in-game only.");
		return Plugin_Handled;
	}
	ShootProjectile(client, FIREBALL);
	return Plugin_Handled;
}
public Action:Command_Lightning(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Command is in-game only.");
		return Plugin_Handled;
	}
	ShootProjectile(client, LIGHTNING);
	return Plugin_Handled;
}
public Action:Command_Transpose(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Command is in-game only.");
		return Plugin_Handled;
	}
	ShootProjectile(client, TELE);
	//ClientCommand(client, "tf_test_spellindex %i", TELE);
	
	return Plugin_Handled;
}
public Action:Command_Bats(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Command is in-game only.");
		return Plugin_Handled;
	}
	ShootProjectile(client, BATS);
	return Plugin_Handled;
}
public Action:Command_Meteor(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Command is in-game only.");
		return Plugin_Handled;
	}
	ShootProjectile(client, METEOR);
	return Plugin_Handled;
}

public Action:Command_Pumpkin(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Command is in-game only.");
		return Plugin_Handled;
	}
	ShootProjectile(client, PUMPKIN2);
	return Plugin_Handled;
}
public Action:Command_Pumpkin2(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Command is in-game only.");
		return Plugin_Handled;
	}
	ShootProjectile(client, PUMPKIN);
	return Plugin_Handled;
}
public Action:Command_Boss(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Command is in-game only.");
		return Plugin_Handled;
	}
	ShootProjectile(client, BOSS);
	return Plugin_Handled;
}
public Action:Command_Skeleton(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Command is in-game only.");
		return Plugin_Handled;
	}
	ShootProjectile(client, ZOMBIE);
	return Plugin_Handled;
}
public Action:Command_SkeletonH(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Command is in-game only.");
		return Plugin_Handled;
	}
	ShootProjectile(client, ZOMBIEH);
	return Plugin_Handled;
}
//tf_projectile_spelltransposeteleport
//tf_projectile_spellfireball
//tf_projectile_spellmirv - tf_projectile_spellpumpkin
//tf_projectile_spellbats
//tf_projectile_lightningorb
//tf_projectile_spellspawnboss
//tf_projectile_spellmeteorshower
//tf_projectile_spellspawnhorde - tf_projectile_spellspawnzombie
//──────────────────────────────────────────────────────────────────────────────
