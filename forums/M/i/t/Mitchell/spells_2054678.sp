#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>

#define PLUGIN_VERSION "2.0"

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

public Plugin:myinfo = 
{
	name = "[TF2] Spells",
	author = "Mitch",
	description = "Allows admins to shoot spells.",
	version = PLUGIN_VERSION,
	url = "http://www.mitch.dev/"
}

new Handle:cCheatOverride;
public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_spells_version", PLUGIN_VERSION, "Spells Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	//cCheatOverride = CreateConVar("sm_admin_spell_level", "a", "Level required to execute the spell commands",FCVAR_PLUGIN);
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
	//RegAdminCmd("sm_meteorshower", Command_Meteor, ADMFLAG_GENERIC, "Meteor Shower");
	
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