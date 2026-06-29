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
 
new g_Lightning;
new g_ExplosionFire;
new g_Smoke1;
new g_Smoke2;
new g_FireBurst;

public OnMapStart(){
	g_Lightning = PrecacheModel("materials/sprites/tp_beam001.vmt", false);
	// Precache explosion
	g_ExplosionFire = PrecacheModel("materials/effects/fire_cloud1.vmt",false);
	// precache smoke
	g_Smoke1 = PrecacheModel("materials/effects/fire_cloud1.vmt",false);
	// precache another smoke
	g_Smoke2 = PrecacheModel("materials/effects/fire_cloud2.vmt",false);
	// precache a little fire
	g_FireBurst = PrecacheModel("materials/sprites/fireburst.vmt",false);
	// precache the explosion sound (used with slay)
	PrecacheSound("ambient/explosions/explode_8.wav",false);
	// Make sure everything loaded right
	if(g_Lightning == 0 || g_Smoke1 == 0 || g_Smoke2 == 0 || g_FireBurst == 0 || g_ExplosionFire == 0 || !IsSoundPrecached("ambient/explosions/explode_8.wav")){
		SetFailState("[Slay] Precache Failed");
	}
}

PerformSlay(client, target)
{
	LogAction(client, target, "\"%L\" slayed \"%L\"", client, target);
	SlayEffects(client);
	ForcePlayerSuicide(target);
}

DisplaySlayMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Slay);
	
	decl String:title[100];
	Format(title, sizeof(title), "%T:", "Slay player", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
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

public MenuHandler_Slay(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
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

// nifty pretties
stock SlayEffects(client)
{
	// get player position
	new Float:playerpos[3];
	GetClientAbsOrigin(client,playerpos);

	// set lightning settings
	// set the top coordinates of the lightning effect
	new Float:toppos[3];
	toppos[0] = playerpos[0];
	toppos[1] = playerpos[1];
	toppos[2] = playerpos[2]+1000;
	// set the color of the lightning
	new lightningcolor[4];
	lightningcolor[0] = 255;
	lightningcolor[1] = 255;
	lightningcolor[2] = 255;
	lightningcolor[3] = 255;
	// how long lightning lasts
	new Float:lightninglife = 2.0;
	// width of lightning at top
	new Float:lightningwidth = 5.0;
	// width of lightning at bottom
	new Float:lightningendwidth = 5.0;
	// lightning start frame
	new lightningstartframe = 0;
	// lightning frame rate
	new lightningframerate = 1;
	// how long it takes for lightning to fade
	new lightningfadelength = 1;
	// how bright lightning is
	new Float:lightningamplitude = 1.0;
	// how fast the effect is drawn
	new lightningspeed = 250;

	// set smoke settings
	// how wide a 360 degree radius of smoke should be used
	new Float:smokescale = 50.0;
	// frame rate for smoke
	new smokeframerate = 2;

	// coordinates for smoke effecet
	new Float:SmokePos[3];
	SmokePos[0] = playerpos[0];
	SmokePos[1] = playerpos[1];
	SmokePos[2] = playerpos[2] + 10;

	// coordinates for uppy body/head smoke efect
	new Float:PlayerHeadPos[3];
	PlayerHeadPos[0] = playerpos[0];
	PlayerHeadPos[1] = playerpos[1];
	PlayerHeadPos[2] = playerpos[2] + 100;

	// should the smoke be "blown" somewhere.
	new Float:direction[3];
	direction[0] = 0.0;
	direction[1] = 0.0;
	direction[2] = 0.0;

	new Float:sparkstart[3];
	sparkstart[0] = playerpos[0];
	sparkstart[1] = playerpos[1];
	sparkstart[2] = playerpos[2] + 13.0;

	new Float:sparkdir[3];
	sparkdir[0] = playerpos[0];
	sparkdir[1] = playerpos[1];
	sparkdir[2] = playerpos[2] + 23.0;

	// create lightning effects and sparks, and explosion
	TE_SetupBeamPoints(toppos, playerpos, g_Lightning, g_Lightning, lightningstartframe, lightningframerate, lightninglife, lightningwidth, lightningendwidth, lightningfadelength, lightningamplitude, lightningcolor, lightningspeed);
	TE_SetupExplosion(playerpos, g_ExplosionFire, 10.0, 10, TE_EXPLFLAG_NONE, 200, 255);
	TE_SetupSmoke(playerpos, g_Smoke1, smokescale, smokeframerate);
	TE_SetupSmoke(playerpos, g_Smoke2, smokescale, smokeframerate);
	TE_SetupMetalSparks(sparkstart,sparkdir);


	TE_SendToAll(0.0);
	EmitAmbientSound("ambient/explosions/explode_8.wav", playerpos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
}
