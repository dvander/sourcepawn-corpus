#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.2"


public Plugin:myinfo = 
{
	name = "Set Spell",
	author = "Tylerst",
	
	description = "Set Spell and Spell Uses on target(s)",
	
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2055798"
}

new Handle:g_hRareSpellAdmin = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_setspell_version", PLUGIN_VERSION, "Set Spell", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_setspell", Command_SetSpell, ADMFLAG_SLAY, "Set Spell and Spell Uses on target(s), Usage: sm_setspell \"target\" \"spell number\" \"uses\"");
	RegAdminCmd("sm_setspelluses", Command_SetSpellUses, ADMFLAG_SLAY, "Set Spell Uses on target(s), Usage: sm_setspelluses \"target\" \"uses\"");
	RegConsoleCmd("sm_showspell", Command_ShowSpell, "Shows your current spell/uses on HUD(for use on non-event maps)");

	g_hRareSpellAdmin = CreateConVar("sm_setspell_rarespelladmin", "0", "If enabled, rare spells require a separate admin flag from common spells(Override with sm_setspell_rareadminflag)");
}

public Action:Command_SetSpell(client, args)
{
	switch(args)
	{
		case 2:
		{
			if(!IsClientInGame(client)) return Plugin_Handled;
			new String:buffer[32], spell, uses;
			GetCmdArg(1, buffer, sizeof(buffer));
			spell = StringToInt(buffer);
			GetCmdArg(2, buffer, sizeof(buffer));
			if(GetConVarBool(g_hRareSpellAdmin) && SpellIsRare(spell) && !CheckCommandAccess(client, "sm_setspell_rareadminflag", ADMFLAG_CHEATS))
			{
				ReplyToCommand(client, "[SM] You do not have access to rare spells");
				return Plugin_Handled;
			}
			uses = StringToInt(buffer);
			if(uses < 0) uses = 0;
			if(uses > 2147483647) uses = 2147483647;
			SetSpell(client, spell, uses);
		}
		case 3:
		{
			new String:buffer[32], String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
			GetCmdArg(1, buffer, sizeof(buffer));
			if((target_count = ProcessTargetString(buffer, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}

			new spell, uses;
			GetCmdArg(2, buffer, sizeof(buffer));
			spell = StringToInt(buffer);
			GetCmdArg(3, buffer, sizeof(buffer));
			uses = StringToInt(buffer);
			if(uses < 0) uses = 0;
			if(uses > 2147483647) uses = 2147483647;

			for(new i = 0; i < target_count; i++)
			{
				if(!IsClientInGame(target_list[i])) continue;
				SetSpell(target_list[i], spell, uses);
			}			
		}
		default:
		{
			ReplyToCommand(client, "[SM] Usage: sm_setspell \"target\" \"spell number\" \"uses\"");				
		}
	}
	return Plugin_Handled;
}

public Action:Command_SetSpellUses(client, args)
{
	switch(args)
	{
		case 1:
		{			
			if(!IsClientInGame(client)) return Plugin_Handled;
			new String:buffer[32], uses;
			GetCmdArg(1, buffer, sizeof(buffer));
			uses = StringToInt(buffer);
			if(uses < 0) uses = 0;
			if(uses > 2147483647) uses = 2147483647;
			SetSpellUses(client, uses);
		}
		case 2:
		{
			new String:buffer[32], String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
			GetCmdArg(1, buffer, sizeof(buffer));
			if((target_count = ProcessTargetString(buffer, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}

			new uses;
			GetCmdArg(2, buffer, sizeof(buffer));
			uses = StringToInt(buffer);
			if(uses < 0) uses = 0;
			if(uses > 2147483647) uses = 2147483647;

			for(new i = 0; i < target_count; i++)
			{
				SetSpellUses(target_list[i], uses);
			}
		}				
		default:
		{
			ReplyToCommand(client, "[SM] Usage: sm_setspelluses \"target\" \"uses\"");
		}
		
	}
	return Plugin_Handled;
}

public Action:Command_ShowSpell(client, args)
{
	if(!IsClientInGame(client)) return Plugin_Handled;
	new String:strMessage[128];	
	Format(strMessage, sizeof(strMessage), "Spell: %s\nUses: %i", GetSpellName(GetSpell(client)), GetSpellUses(client));
	new Handle:hBuffer = StartMessageOne("KeyHintText", client);
	BfWriteByte(hBuffer, 1);
	BfWriteString(hBuffer, strMessage);
	EndMessage();
	return Plugin_Handled;
}


SetSpell(client, spell, uses)
{
	new ent = GetSpellBook(client);
	if(!IsValidEntity(ent)) return;
	SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", spell);
	SetEntProp(ent, Prop_Send, "m_iSpellCharges", uses);
}



SetSpellUses(client, uses)
{
	new ent = GetSpellBook(client);
	if(!IsValidEntity(ent)) return;
	SetEntProp(ent, Prop_Send, "m_iSpellCharges", uses);
}

GetSpell(client)
{
	new ent = GetSpellBook(client);
	if(!IsValidEntity(ent)) return -1;
	return GetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex");
}

GetSpellUses(client)
{
	new ent = GetSpellBook(client);
	if(!IsValidEntity(ent)) return 0;
	return GetEntProp(ent, Prop_Send, "m_iSpellCharges");
}

GetSpellBook(client)
{
	new entity = -1;
	while((entity = FindEntityByClassname(entity, "tf_weapon_spellbook")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client) return entity;
	}
	return -1;
}

bool:SpellIsRare(spell)
{
	switch(spell)
	{
		case 7,8,9,10,11:
		{
			return true;
		}
	}
	return false;
}

String:GetSpellName(spell)
{
	new String:strSpellName[32];
	switch(spell)
	{
		case 0:
		{
			strSpellName = "Fireball";
		}
		case 1:
		{
			strSpellName = "Ball O' Bats";
		}
		case 2:
		{
			strSpellName = "Healing Aura";
		}
		case 3:
		{
			strSpellName = "Pumpkin MIRV";
		}
		case 4:
		{
			strSpellName = "Superjump";
		}
		case 5:
		{
			strSpellName = "Invisibility";
		}
		case 6:
		{
			strSpellName = "Teleport";
		}
		case 7:
		{
			strSpellName = "Tesla Bolt";
		}
		case 8:
		{
			strSpellName = "Minify";
		}
		case 9:
		{
			strSpellName = "Summon Monoculus";
		}
		case 10:
		{
			strSpellName = "Meteor Shower";
		}
		case 11:
		{
			strSpellName = "Summon Skeletons";
		}
		default:
		{
			strSpellName = "None";
		}
	}
	return strSpellName;
}

