#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_NAME		"[TF2] Spellbook Commands"
#define PLUGIN_AUTHOR		"FlaminSarge"
#define PLUGIN_VERSION		"1.0"
#define PLUGIN_CONTACT		"http://forums.alliedmods.net/showthread.php?t=229177"
#define PLUGIN_DESCRIPTION	"A set of commands for messing with Spellbooks"

new Handle:hCvarLimit;
public String:spellnames[12][32] =
{
	"Fireball",
	"Swarm of Bats",
	"Overheal",
	"Pumpkin MIRV",
	"Blast Jump",
	"Stealth",
	"Shadow Leap (Instantarium)",
	"Ball o' Lightning",
	"Tiny and Athletic",
	"MONOCULUS!",
	"Meteor Shower",
	"Skeleton Horde"
};
public Plugin:myinfo = {
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description		= PLUGIN_DESCRIPTION,
	version			= PLUGIN_VERSION,
	url				= PLUGIN_CONTACT
};
public OnPluginStart()
{
	CreateConVar("tf_spellbookcmds_version", PLUGIN_VERSION, "[TF2] Spellbook Commands version", FCVAR_NOTIFY|FCVAR_PLUGIN);
	RegAdminCmd("sm_setspell", Cmd_SetSpell, ADMFLAG_CHEATS, "Sets the number of spells on a player's spellbook. Will also change their spell if 2nd param given. Target is 3rd param.");
	RegAdminCmd("sm_spelllist", Cmd_SpellList, 0, "Lists the name and index of each spell");
	hCvarLimit = CreateConVar("tf_spellbookcmds_limit", "-1", "Limits the number of spells those without access to sm_setspell_unlimit can set themselves to. -1 to disable.", FCVAR_PLUGIN);
	LoadTranslations("common.phrases");
}
public Action:Cmd_SpellList(client, args)
{
	ReplyToCommand(client, "[SM] List of Halloween spells for use with /setspell:");
	for (new i = 0; i < sizeof(spellnames); i++)
	{
		ReplyToCommand(client, "%d - %s", i, spellnames[i]);
	}
	return Plugin_Handled;
}
public Action:Cmd_SetSpell(client, args)
{
	if (client <= 0 && args < 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setspell <charges> [spell] [target]");
		return Plugin_Handled;
	}
	new bool:target_access = CheckCommandAccess(client, "sm_setspell_target", ADMFLAG_CHEATS, true);
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setspell <charges> [spell]%s", target_access ? " [target]" : "");
		return Plugin_Handled;
	}
	decl String:arg1[32];
	decl String:arg2[32];
	decl String:arg3[32];
	strcopy(arg3, sizeof(arg3), "@me");
	new spell = -1;
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		spell = StringToInt(arg2);
		if (spell < -1 || spell > 11)
		{
			ReplyToCommand(client, "[SM] Invalid spell number. Use /spelllist to see spell numbers, or use -1 to preserve spell.");
			return Plugin_Handled;
		}
		if (args > 2)
		{
			if (!target_access)
			{
				ReplyToCommand(client, "%t", "No Access");
				ReplyToCommand(client, "[SM] You do not have the access required to target other players with this command.");
				ReplyToCommand(client, "[SM] Usage: sm_setspell <charges> [spell]");
				return Plugin_Handled;
			}
			GetCmdArg(3, arg3, sizeof(arg3));
		}
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	new charges = StringToInt(arg1);
	if (charges < 0) charges = 0;
	new limit = GetConVarInt(hCvarLimit);
	if (limit >= 0 && charges > limit && !CheckCommandAccess(client, "sm_setspell_unlimit", ADMFLAG_ROOT, true))
	{
		ReplyToCommand(client, "[SM] Exceeded your spellbook charge limit (%d).", limit);
		charges = limit;
	}
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg3,
			client,
			target_list,
			MAXPLAYERS,
			(args <= 2 ? COMMAND_FILTER_NO_IMMUNITY : 0),
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		// This function replies to the admin with a failure message
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		new spellbook = FindSpellbook(target_list[i]);
		if (spellbook != -1)	//Should probably have a message if no spellbook, but eh.
		{
			SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", charges);
			if (spell >= 0)
			{
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", spell);
			}
//			else if (GetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex") < 0)	//if they don't have a spell... give them one? Nah.
//			{
//				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 0);
//			}
		}
		LogAction(client, target_list[i], "\"%L\" set spellbook charges on \"%L\" to %d%s%s", client, target_list[i], charges, spell >= 0 ? ", with spell " : "", spell >= 0 ? spellnames[spell] : "");
	}
	if (!target_access || args <= 2)
	{
		ReplyToCommand(client, "[SM] Set spellbook charges to %d%s%s", charges, spell >= 0 ? ", with spell " : "", spell >= 0 ? spellnames[spell] : "");
		return Plugin_Handled;
	}
	if (tn_is_ml)
		ShowActivity2(client, "[SM] ", "set spellbook charges on %t to %d%s%s", target_name, charges, spell >= 0 ? ", with spell " : "", spell >= 0 ? spellnames[spell] : "");
	else
		ShowActivity2(client, "[SM] ", "set spellbook charges on %s to %d%s%s", target_name, charges, spell >= 0 ? ", with spell " : "", spell >= 0 ? spellnames[spell] : "");
	return Plugin_Handled;
}

stock FindSpellbook(client)	//GetPlayerWeaponSlot was giving me some issues
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWeapon"))
		{
			return i;
		}
	}
	return -1;
}