/**
* vim: set ts=4 :
* =============================================================================
* SourceMod Basefuncommands Plugin
* Provides slay functionality
*
* SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
* =============================================================================
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the GNU General Public License, version 3.0, as published by the
* Free Software Foundation.
* 
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
* details.
*
* You should have received a copy of the GNU General Public License along with
* this program.  If not, see <http://www.gnu.org/licenses/>.
*
* As a special exception, AlliedModders LLC gives you permission to link the
* code of this program (as well as its derivative works) to "Half-Life 2," the
* "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
* by the Valve Corporation.  You must obey the GNU General Public License in
* all respects for all other code used.  Additionally, AlliedModders LLC grants
* this exception to all derivative works.  AlliedModders LLC defines further
* exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
* or <http://www.sourcemod.net/license.php>.
*
* Version: $Id$
*/

#include <sdktools>

PerformSlay(client, target)
{
	LogAction(client, target, "\"%L\" slayed \"%L\"", client, target);
	SetEntProp(target, Prop_Send, "m_iHealth", 1);
	SetEntProp(target, Prop_Send, "m_currentReviveCount", 2);
	SetEntProp(target, Prop_Send, "m_bIsOnThirdStrike", 1);
	SetEntProp(target, Prop_Send, "m_isGoingToDie", 1);
	
	DealDamage(target, 100);
}

DisplaySlayMenu(client)
{
	Menu menu = CreateMenu(MenuHandler_Slay);
	
	char title[100];
	Format(title, sizeof(title), "%T:", "Slay player", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	AddTargetsToMenu(menu, client, true, true);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public AdminMenu_Slay(Handle:topmenu, 
TopMenuAction:action,
TopMenuObject:object_id,
param,
String:buffer[],
maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Slay player", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplaySlayMenu(param);
	}
}

public MenuHandler_Slay(Menu menu, MenuAction action, param1, param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != null)
		{
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;
		
		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);
		
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else if (!IsPlayerAlive(target))
		{
			ReplyToCommand(param1, "[SM] %t", "Player has since died");
		}
		else
		{
			decl String:name[32];
			GetClientName(target, name, sizeof(name));
			PerformSlay(param1, target);
			ShowActivity2(param1, "[SM] ", "%t", "Slayed target", "_s", name);
		}
		
		DisplaySlayMenu(param1);
	}
}

public Action:Command_Slay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_slay <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
	arg,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_FILTER_ALIVE,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		PerformSlay(client, target_list[i]);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Slayed target", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Slayed target", "_s", target_name);
	}
	
	return Plugin_Handled;
}

#define DMG_GENERIC			0
#define DMG_CRUSH			(1 << 0)
#define DMG_BULLET			(1 << 1)
#define DMG_SLASH			(1 << 2)
#define DMG_BURN			(1 << 3)
#define DMG_VEHICLE			(1 << 4)
#define DMG_FALL			(1 << 5)
#define DMG_BLAST			(1 << 6)
#define DMG_CLUB			(1 << 7)
#define DMG_SHOCK			(1 << 8)
#define DMG_SONIC			(1 << 9)
#define DMG_ENERGYBEAM			(1 << 10)
#define DMG_PREVENT_PHYSICS_FORCE	(1 << 11)
#define DMG_NEVERGIB			(1 << 12)
#define DMG_ALWAYSGIB			(1 << 13)
#define DMG_DROWN			(1 << 14)
#define DMG_TIMEBASED			(DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
#define DMG_PARALYZE			(1 << 15)
#define DMG_NERVEGAS			(1 << 16)
#define DMG_POISON			(1 << 17)
#define DMG_RADIATION			(1 << 18)
#define DMG_DROWNRECOVER		(1 << 19)
#define DMG_ACID			(1 << 20)
#define DMG_SLOWBURN			(1 << 21)
#define DMG_REMOVENORAGDOLL		(1 << 22)
#define DMG_PHYSGUN			(1 << 23)
#define DMG_PLASMA			(1 << 24)
#define DMG_AIRBOAT			(1 << 25)
#define DMG_DISSOLVE			(1 << 26)
#define DMG_BLAST_SURFACE		(1 << 27)
#define DMG_DIRECT			(1 << 28)
#define DMG_BUCKSHOT			(1 << 29)

DealDamage(victim,damage,attacker=0,dmg_type=DMG_GENERIC,String:weapon[]="")
{
	if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
	{
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(victim,"targetname","war3_hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(victim,"targetname","war3_donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}
