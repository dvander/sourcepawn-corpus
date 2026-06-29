/**
 * vim: set ts=4 :
 * =============================================================================
 * Weapon Restriction Plugin for SourceMod
 * Restricts weapons for Counter-Strike: Source.
 *
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
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
 */

/*
 * Code written by Liam on 4/8/2008.
 *
 * The purpose of this plugin was to create an easy to use system for handling
 * weapon restrictions in Counter-Strike: Source.
 *
 * My ability to write this code would not have been possible without the help,
 * direction, knowledge given to me by teame06, Bailopan, pred, Tsunami, and
 * many others in #sourcemod. I thank each and every one of them for their
 * time and help in getting this plugin planned and working.
 *
 * The usage of this plugin is meant to be very simple, though it is run from 
 * the command line at present.
 *
 * Usage: sm_restrict <weapon_name> <amount (default is 0)> <ct|t|all (default is all)>
 *        sm_unrestrict <weapon_name>
 *
 * If you have any questions, comments, or suggestions, please feel free to contact me
 * either by replying to this thread or finding me in #sourcemod on irc.gamesurge.net.
 *
 */

/* Version History */
/* 1.0 - Initial Release */

/* TODO List */
/*
 * Integrate into menu system
 * Allow the restricting of weapons via cfg file
 *
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <restrict>

new g_CT_RestrictList[_:Weapon_Max];
new g_T_RestrictList[_:Weapon_Max];
new g_iAccount = -1;
new g_SingleWeapon = -1;
new g_SingleWeaponNext = -1;
new g_SingleWeaponRound = 0;
new g_KnivesOnly = 0;
new g_PistolsOnly = 0;
new Handle:g_Cvar_Admins_Can_Buy = INVALID_HANDLE;
new Handle:g_Cvar_KnivesMinVote = INVALID_HANDLE;
// new g_KnifeVotesNeeded = 5;
new g_PlayersVoted[MAXPLAYERS+1] = 0;
new g_IsDMServer = 0;

/* Anti Nade Spam bit */
new smoke[MAXPLAYERS+1] = 0;
new frag[MAXPLAYERS+1] = 0;
new flash[MAXPLAYERS+1] = 0;
new secondary[MAXPLAYERS+1] = 0;
new primary[MAXPLAYERS+1] = 0;
// new buysec[MAXPLAYERS+1] = 0;
// new buypri[MAXPLAYERS+1] = 0;
new String:prevbuy[MAXPLAYERS+1][64];

#include "restrict\restrict_functions.sp"

public Plugin:myinfo =
{
    name = "Weapon Restrictions",
    author = "Liam, modified by Kigen",
    description = "Handles weapon restrictions.",
    version = "1.1",
    url = "http://www.wcugaming.org/"
};

/*
 * OnPluginStart( )
 * Initialize all commands, hooks, and variables needed.
 */
public OnPluginStart( )
{
    RegAdminCmd("sm_restrict", Command_Restrict, ADMFLAG_ROOT, "Usage: sm_restrict <weapon> <amount> <all=default|ct|t>");
    RegAdminCmd("sm_unrestrict", Command_Unrestrict, ADMFLAG_ROOT, "Usage: sm_unrestrict <all|weapon> <all=default|team>");
    RegAdminCmd("sm_allow", Command_Allow1, ADMFLAG_ROOT, "Usage: sm_allow <weapon> - Allows only the use of a single weapon and knife.");
    RegAdminCmd("sm_knives", Command_Knives, ADMFLAG_ROOT, "Usage: sm_knives - Makes it a knives only round.");
    RegAdminCmd("sm_pistols", Command_Pistols, ADMFLAG_ROOT, "Usage: sm_pistols - Makes it a pistols only round.");
    RegAdminCmd("sm_custom1", Command_Fake, ADMFLAG_CUSTOM1, "Custom 1.");
    RegAdminCmd("sm_custom2", Command_Fake, ADMFLAG_CUSTOM2, "Custom 2.");
    RegAdminCmd("sm_custom3", Command_Fake, ADMFLAG_CUSTOM3, "Custom 3.");
    RegAdminCmd("sm_custom4", Command_Fake, ADMFLAG_CUSTOM4, "Custom 4.");
    RegAdminCmd("sm_custom5", Command_Fake, ADMFLAG_CUSTOM5, "Custom 5.");
    RegAdminCmd("sm_custom6", Command_Fake, ADMFLAG_CUSTOM6, "Custom 6.");
    g_Cvar_Admins_Can_Buy = CreateConVar("sm_cvar_admins_can_buy_restricted", "0", "Whether or not an admin can buy restricted weapons.");
    g_Cvar_KnivesMinVote = CreateConVar("sm_knife_votesneeded", "0.60", "Percentage of players that need to for for a knife round.", 0, true, 0.05, true, 1.0);
    RegConsoleCmd("buy", Command_Buy);
    RegConsoleCmd("rebuy", Command_Rebuy);
    // RegConsoleCmd("autobuy", Command_Autobuy);
    RegConsoleCmd("sm_knife", Command_Voteknife);
    HookEvent("player_spawn", Event_PlayerSpawn);
    // HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("item_pickup", Event_ItemPickup, EventHookMode_Post);
    InitializePlugin( );
    AutoExecConfig(true, "restrict_weapons");
    if ( FindConVar("cssdm_respawn_command") != INVALID_HANDLE )
    	g_IsDMServer = 1;
}

/*
 * OnPluginEnd( )
 * Close all open handles to free memory.
 */
public OnPluginEnd( )
{
    ClearWeaponArrays( );
}

/*
 * InitializePlugin( )
 * Hook all offsets needed, setup arrays, and initialize SDK Hacks.
 */
InitializePlugin( )
{
    GameConf = LoadGameConfigFile("hacks.games");

    if((m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons")) == INVALID_OFFSET)
    {
        decl String:Error[255];
        FormatEx(Error, sizeof(Error), "FATAL ERROR m_hMyWeapons [%d]. Please contact the author.", m_hMyWeapons);
        PrintToServer("FATAL ERROR m_hMyWeapons [%d]. Please contact the author.", m_hMyWeapons);
        SetFailState(Error);
    }
    g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
    CreateGetSlotHack( );
    CreateRemoveHack( );
    CreateDropHack( );
    g_MaxClients = GetMaxClients( );
    ClearWeaponArrays( );
}

/*
 * ClearWeaponArrays( )
 * Clear the restricted weapon arrays.
 */
ClearWeaponArrays( )
{
    for(new i = 0; i < _:Weapon_Max; i++)
    {
        g_CT_RestrictList[i] = -1;
        g_T_RestrictList[i] = -1;
    }
}

/*
 * OnMapStart( )
 * Reload the config file since it has our restricted weapons.
 */
public OnMapStart( )
{
    AutoExecConfig(true, "restrict_weapons");
    for(new i=0; i < (MAXPLAYERS+1);i++)
	g_PlayersVoted[i] = 0;
}

/*
 * OnMapEnd( )
 * Clear the restricted weapons array so they don't carry over.
 */
public OnMapEnd( )
{
    ClearWeaponArrays( );
    g_SingleWeapon = -1;
    g_SingleWeaponNext = -1;
    g_SingleWeaponRound = 0;
    g_KnivesOnly = 0;
    g_PistolsOnly = 0;
}

public OnClientDisconnect(client)
{
	g_PlayersVoted[client] = 0;
}

public Action:Command_Fake(client, args)
{
	ReplyToCommand(client, "This is a fake command.");
	return Plugin_Handled;
}

/*
 * Action:Command_Restrict(client, args)
 * Handles the restricting of weapons by parsing inputted arguments.
 * Can accept full or limited input and will default to base values.
 */
public Action:Command_Restrict(client, args)
{
    if(args < 1)
    {
        ReplyToCommand(client, "Usage: sm_restrict <weapon> <amt(default 0)> <all(default)|ct|t>");
        return Plugin_Continue;
    }
    else
    {
        new f_Weapon = -1;
        new f_Amount = -1;
        new f_Team = TEAM_ALL;
        decl String:f_WeaponString[64],
             String:f_AmountString[10],
             String:f_TeamString[64];

        switch(args)
        {
            case 1: // One argument - Restrict the weapon to 0 for all teams.
            {
                GetCmdArg(1, f_WeaponString, sizeof(f_WeaponString));
                f_AmountString[0] = '\0';
                f_TeamString[0] = '\0';
            }

            case 2: // Two arguments - Restrict the weapon to the amount specified for all teams.
            {
                GetCmdArg(1, f_WeaponString, sizeof(f_WeaponString));
                GetCmdArg(2, f_AmountString, sizeof(f_AmountString));
                f_TeamString[0] = '\0';
            }

            case 3: // Three arguments - restrict the weapon to the amount specified for specific teams.
            {
                GetCmdArg(1, f_WeaponString, sizeof(f_WeaponString));
                GetCmdArg(2, f_AmountString, sizeof(f_AmountString));
                GetCmdArg(3, f_TeamString, sizeof(f_TeamString));
            }
        }
        // Lets parse our input and then restrict the weapons
        f_Weapon = LookupWeaponNumber(f_WeaponString);
        f_Amount = StringToInt(f_AmountString);
        f_Team = LookupTeam(f_TeamString);
        RestrictWeapon(client, f_Weapon, f_Amount, f_Team);
        PerformTimedRemove(-1); // remove all restricted weapons in-game

        // log the command
        if(f_Team == TEAM_ALL)
        {
            if(f_Amount == 0)
            {
                LogAction(client, -1, "sm_restrict - Restricted the %s.", 
                    g_ShortWeaponNames[f_Weapon]);
            }
            else
            {
                LogAction(client, -1, "sm_restrict - Restricted the %s to %d per team.", 
                g_ShortWeaponNames[f_Weapon], f_Amount);
            }
        }
        else
        {
            if(f_Amount == 0)
            {
                LogAction(client, -1, "sm_restrict - Restricted the %s for the %s team.", 
                    g_ShortWeaponNames[f_Weapon], f_Team == TEAM_T ? "Terrorist" : "Counter-Terrorist");
            }
            else
            {
                LogAction(client, -1, "sm_restrict - Restricted the %s to %d for the %s team.", 
                g_ShortWeaponNames[f_Weapon], f_Amount, f_Team == TEAM_T ? "Terrorist" : "Counter-Terrorist");
            }
        }
    }
    return Plugin_Handled;
}

/*
 * Action:Command_Unrestrict(client, args)
 * Handles the unrestricting of weapons by parsing the inputted arguments
 * then comparing them to the array.
 */
public Action:Command_Unrestrict(client, args)
{
    if(args < 1)
    {
        ReplyToCommand(client, "Usage: sm_unrestrict <all|weapon> <all=default|ct|t>");
        return Plugin_Continue;
    }
    else
    {
        decl String:f_WeaponString[64];
        decl String:f_TeamString[64];
        GetCmdArg(1, f_WeaponString, sizeof(f_WeaponString));
        GetCmdArg(2, f_TeamString, sizeof(f_TeamString));
        new f_Weapon = LookupWeaponNumber(f_WeaponString); // lookup the weapon
        new f_Team = LookupTeam(f_TeamString);
        if(!strcmp(f_WeaponString, "all"))
            f_Weapon = 999;
        UnrestrictWeapon(client, f_Team, f_Weapon); // unrestrict it
        LogAction(client, -1, "sm_unrestrict - Unrestricted the %s.", g_ShortWeaponNames[f_Weapon]); // log the action
    }
    return Plugin_Handled;
}

public Action:Command_Voteknife(client, args)
{
    if ( g_PistolsOnly == 1 || g_PistolsOnly == 3 || g_SingleWeaponRound == 1 || g_SingleWeaponRound == 3 || g_KnivesOnly == 1 || g_KnivesOnly == 3 )
    {
         ReplyToCommand(client, "The next round is already going to be a restricted round.");
	 return Plugin_Handled;
    }
    if ( g_IsDMServer && ( g_PistolsOnly > 1 || g_SingleWeaponRound > 1 || g_KnivesOnly > 1 ) )
    {
         ReplyToCommand(client, "The map is already restricted.");
	 return Plugin_Handled;
    }
    if ( g_PlayersVoted[client] == 1 )
    {
	ReplyToCommand(client, "You have already voted for a knife round.");
	return Plugin_Handled;
    }
    g_PlayersVoted[client] = 1;
    new t = 0, r = 0;
    r = RoundToFloor(GetClientCount(true) * GetConVarFloat(g_Cvar_KnivesMinVote));
    for (new i=0;i< (MAXPLAYERS+1);i++)
    	if ( g_PlayersVoted[i] == 1 )
		t++;
    if ( t >= r )
    {
	for ( new i=0;i<(MAXPLAYERS+1);i++ )
		g_PlayersVoted[i] = 0;
	if ( g_IsDMServer == 1 )
	{
		PrintToChatAll("The map will now be knives only.");
		g_KnivesOnly = 2;
		PerformTimedRemove(-1);
		return Plugin_Handled;
	}
    	PrintToChatAll("The next round will be knives only.");
    	g_KnivesOnly++;
    }
    else
    {
	new String:name[64];
	GetClientName(client, name, sizeof(name));
	t = r-t;
	if ( g_IsDMServer == 1 )
		PrintToChatAll("%s has voted for to make the map knives only, %d more votes needed.", name, t);
	else
		PrintToChatAll("%s has voted to make the next round knives only, %d more votes needed.", name, t);
    }
    return Plugin_Handled;
}

/*
 * Action:Command_Knives(client, args)
 * Restricts a single round to knives only.
 */
public Action:Command_Knives(client, args)
{
    if ( g_PistolsOnly == 1 || g_PistolsOnly == 3 || g_SingleWeaponRound == 1 || g_SingleWeaponRound == 3)
    {
         ReplyToCommand(client, "You may only restrict one thing for next round.");
	 return Plugin_Handled;
    }
    if ( g_KnivesOnly == 1 || g_KnivesOnly == 3 )
    {
	 if ( g_IsDMServer == 1 )
	 {
		PrintToChatAll("The map will no longer be knives only.");
		g_KnivesOnly = 0;
		return Plugin_Handled;
	 }
         PrintToChatAll("The next round will no longer be knives only.");
	 g_KnivesOnly--;
    }
    if ( g_IsDMServer == 1 )
    {
	PrintToChatAll("The map will now be knives only.");
	g_KnivesOnly = 2;
	PerformTimedRemove(-1);
	return Plugin_Handled;
    }
    PrintToChatAll("The next round will be knives only.");
    g_KnivesOnly++;
    return Plugin_Handled;
}

/*
 * Action:Command_Pistols(client, args)
 * Restricts a single round to pistols only.
 */
public Action:Command_Pistols(client, args)
{
    if ( g_KnivesOnly == 1 || g_KnivesOnly == 3 || g_SingleWeaponRound == 1 || g_SingleWeaponRound == 3)
    {
         ReplyToCommand(client, "You may only restrict one thing for next round.");
	 return Plugin_Handled;
    }
    if ( g_PistolsOnly == 2 && g_IsDMServer == 1 )
    {
	PrintToChatAll("The map will no longer be pistols only.");
	g_PistolsOnly = 0;
	return Plugin_Handled;
    }
    if ( g_PistolsOnly == 1 || g_PistolsOnly == 3 )
    {
         PrintToChatAll("The next round will no longer be pistols only.");
	 g_PistolsOnly--;
	 return Plugin_Handled;
    }
    if ( g_IsDMServer == 1 )
    {
	PrintToChatAll("The map will now be pistols only.");
	g_PistolsOnly = 2;
	PerformTimedRemove(-1);
	return Plugin_Handled;
    }
    PrintToChatAll("The next round will be pistols only.");
    g_PistolsOnly++;
    return Plugin_Handled;
}

/*
 * Action:Command_Allow(client, args)
 * Restricts a single round to pistols only.
 */
public Action:Command_Allow1(client, args)
{
    if ( g_PistolsOnly == 1 || g_PistolsOnly == 3 || g_KnivesOnly == 1 || g_KnivesOnly == 3)
    {
         ReplyToCommand(client, "You may only restrict one thing for next round.");
	 return Plugin_Handled;
    }
    if(args != 1)
    {
	if ( g_SingleWeaponRound == 2 && g_IsDMServer == 1 )
	{
		PrintToChatAll("This map is no longer restricted to only the %s.", g_ShortWeaponNames[g_SingleWeapon]);
		g_SingleWeapon = -1;
		g_SingleWeaponRound = 0;
		return Plugin_Handled;
	}
	if ( g_SingleWeaponRound == 1 || g_SingleWeaponRound == 3 )
	{
		PrintToChatAll("The next round will no longer be restricted to only the %s.", g_ShortWeaponNames[g_SingleWeaponNext]);
		g_SingleWeaponNext = -1;
		g_SingleWeaponRound--;
		return Plugin_Handled;
	}
        ReplyToCommand(client, "Usage: sm_allow <weapon> - This allows the use of a single weapon and the knife.");
        return Plugin_Handled;
    }
    
    decl String:f_WeaponString[128], weap;

    GetCmdArg(1, f_WeaponString, sizeof(f_WeaponString));
    weap = LookupWeaponNumber(f_WeaponString);
    
    if(weap == -1)
    {
        ReplyToCommand(client, "That is not a valid weapon.");
        return Plugin_Handled;
    }
    if ( g_IsDMServer == 1 )
    {
	PrintToChatAll("The map will now be restricted to just the %s.", g_ShortWeaponNames[weap]);
	g_SingleWeapon = weap;
	g_SingleWeaponRound = 2;
	PerformTimedRemove(-1);
        for(new i = 1; i <= g_MaxClients; i++)
            if(IsClientConnected(i) && IsClientInGame(i))
                CreateTimer(0.5, GiveSingleWeap, i);
	return Plugin_Handled;
    }
    if ( g_SingleWeaponRound != 3 )
	 g_SingleWeaponRound++;
    g_SingleWeaponNext = weap;
    PrintToChatAll("The next round will only allow the %s.", g_ShortWeaponNames[g_SingleWeaponNext]);
    return Plugin_Handled;
}

/*
 * Action:Command_Buy(client, args)
 * Handles the input from the hooked 'buy' function.
 * This checks if what they are buying is restricted and replies appropriately.
 */
public Action:Command_Buy(client, args)
{
    decl String:f_WeaponName[64];
    new f_Weapon;

    if(g_KnivesOnly > 1)
    {
        PrintToChat(client, "This is a knives only round. Please try again later.");
        return Plugin_Handled;
    }

    GetCmdArg(1, f_WeaponName, 64); 

    if((f_Weapon = LookupWeaponNumber(f_WeaponName)) != -1) // look the weapon up
    {
	new Slots:slot = g_WeaponSlot[f_Weapon];
	
        if(g_PistolsOnly > 1)
        {
            if(slot != Slot_Secondary)
            {
                PrintToChat(client, "You may only buy pistols this round.");
                return Plugin_Handled;
            }
        }

        if(g_SingleWeaponRound > 1)
        {
            if(g_SingleWeapon != f_Weapon)
            {
                PrintToChat(client, "You may only buy the %s this round.", g_ShortWeaponNames[g_SingleWeapon]);
                return Plugin_Handled;
            }
        }

	if ( f_Weapon == LookupWeaponNumber("hegrenade") )
	{
		if ( frag[client] == 1 )
		{
			PrintToChat(client, "You may not buy any more HE Grenades.");
			return Plugin_Handled;
		}
		frag[client]++;
	}

	if ( f_Weapon == LookupWeaponNumber("flashbang") )
	{
		if ( flash[client] == 2 )
		{
			PrintToChat(client, "You may not buy any more Flashbangs.");
			return Plugin_Handled;
		}
		flash[client]++;
	}
	if ( f_Weapon == LookupWeaponNumber("smokegrenade") )
	{
		if ( smoke[client] == 1 )
		{
			PrintToChat(client, "You may not buy any more Smokes.");
			PrintToChat(client, "They're bad for your health anyways....");
			return Plugin_Handled;
		}
		smoke[client]++;
	}

        new f_Team = GetClientTeam(client);

        if(IsRestricted(f_Weapon, f_Team)) // check if its restricted
        {
            PrintToChat(client, "The %s is restricted.", g_WeaponNames[f_Weapon]);
            return Plugin_Handled;
        }

	if ( slot == Slot_Primary || StrContains(f_WeaponName, "mp5") != -1 )
	{
		decl String:f_EntityName[64];
        	new f_Entity = GetPlayerWeaponSlot(client, _:Slot_Primary);
  		if (f_Entity != -1)
		{
			GetEdictClassname(f_Entity, f_EntityName, sizeof(f_EntityName));
			// PrintToChat(client, "You are already carrying a %s.", g_WeaponNames[f_Weapon]);
			if ( LookupWeaponNumber(f_EntityName) == f_Weapon )
				return Plugin_Handled;
		}
		if ( primary[client] > 1 )
		{
			PrintToChat(client, "You may not buy anymore primary weapons this round.");
			return Plugin_Handled;
		}
		primary[client]++;
		// CreateTimer(0.1, CheckBuyPri, client);
		// buypri[client] = f_Weapon;
	}
	else if ( slot == Slot_Secondary )
	{
    		decl String:f_EntityName[64];
		new f_Entity = GetPlayerWeaponSlot(client, _:Slot_Secondary);
  		if (f_Entity != -1)
		{
			GetEdictClassname(f_Entity, f_EntityName, sizeof(f_EntityName));
			// PrintToChat(client, "You are already carrying a %s.", g_WeaponNames[f_Weapon]);
			if ( LookupWeaponNumber(f_EntityName) == f_Weapon )
				return Plugin_Handled;
		}
		if ( secondary[client] > 1 )
		{
			PrintToChat(client, "You may not buy anymore secondary weapons this round.");
			return Plugin_Handled;
		}
		secondary[client]++;
		// CreateTimer(0.1, CheckBuySec, client);
		// buysec[client] = f_Weapon;
	}
    }
    strcopy(prevbuy[client], 64, f_WeaponName);
    return Plugin_Continue;
}

public Action:Command_Rebuy(client, args)
{
    decl String:f_WeaponName[64];
    new f_Weapon;
    strcopy(f_WeaponName, 64, prevbuy[client]);

    if(g_KnivesOnly > 1)
    {
        PrintToChat(client, "This is a knives only round. Please try again later.");
        return Plugin_Handled;
    }

    // GetCmdArg(1, f_WeaponName, 64);

    if((f_Weapon = LookupWeaponNumber(f_WeaponName)) != -1) // look the weapon up
    {
	new Slots:slot = g_WeaponSlot[f_Weapon];
	
        if(g_PistolsOnly > 1)
        {
            if(slot != Slot_Secondary)
            {
                PrintToChat(client, "You may only buy pistols this round.");
                return Plugin_Handled;
            }
        }

        if(g_SingleWeaponRound > 1)
        {
            if(g_SingleWeapon != f_Weapon)
            {
                PrintToChat(client, "You may only buy the %s this round.", g_ShortWeaponNames[g_SingleWeapon]);
                return Plugin_Handled;
            }
        }

	if ( f_Weapon == LookupWeaponNumber("hegrenade") )
	{
		if ( frag[client] == 1 )
		{
			PrintToChat(client, "You may not buy any more HE Grenades.");
			return Plugin_Handled;
		}
		frag[client]++;
	}

	if ( f_Weapon == LookupWeaponNumber("flashbang") )
	{
		if ( flash[client] == 2 )
		{
			PrintToChat(client, "You may not buy any more Flashbangs.");
			return Plugin_Handled;
		}
		flash[client]++;
	}
	if ( f_Weapon == LookupWeaponNumber("smokegrenade") )
	{
		if ( smoke[client] == 1 )
		{
			PrintToChat(client, "You may not buy any more Smokes.");
			PrintToChat(client, "They're bad for your health anyways....");
			return Plugin_Handled;
		}
		smoke[client]++;
	}

        new f_Team = GetClientTeam(client);

        if(IsRestricted(f_Weapon, f_Team)) // check if its restricted
        {
            PrintToChat(client, "The %s is restricted.", g_WeaponNames[f_Weapon]);
            return Plugin_Handled;
        }

	if ( slot == Slot_Primary )
	{
		decl String:f_EntityName[64];
        	new f_Entity = GetPlayerWeaponSlot(client, _:Slot_Primary);
  		if (f_Entity != -1)
		{
			GetEdictClassname(f_Entity, f_EntityName, sizeof(f_EntityName));
			// PrintToChat(client, "You are already carrying a %s.", g_WeaponNames[f_Weapon]);
			if ( LookupWeaponNumber(f_EntityName) == f_Weapon )
				return Plugin_Handled;
		}
		if ( primary[client] > 1 )
		{
			PrintToChat(client, "You may not buy anymore primary weapons this round.");
			return Plugin_Handled;
		}
		primary[client]++;
		// CreateTimer(0.1, CheckBuyPri, client);
		// buypri[client] = f_Weapon;
	}
	else if ( slot == Slot_Secondary )
	{
    		decl String:f_EntityName[64];
		new f_Entity = GetPlayerWeaponSlot(client, _:Slot_Secondary);
  		if (f_Entity != -1)
		{
			GetEdictClassname(f_Entity, f_EntityName, sizeof(f_EntityName));
			// PrintToChat(client, "You are already carrying a %s.", g_WeaponNames[f_Weapon]);
			if ( LookupWeaponNumber(f_EntityName) == f_Weapon )
				return Plugin_Handled;
		}
		if ( secondary[client] > 1 )
		{
			PrintToChat(client, "You may not buy anymore secondary weapons this round.");
			return Plugin_Handled;
		}
		secondary[client]++;
		// CreateTimer(0.1, CheckBuySec, client);
		// buysec[client] = f_Weapon;
	}
    }
    return Plugin_Continue;
}

public Action:Command_Autobuy(client, args)
{
	new String:autobuy[512], String:arg[20], i = 0, t =0;
	GetClientInfo(client, "cl_autobuy", autobuy, sizeof(autobuy));
	// PrintToChat(client, "retrun %s", autobuy);
	// return Plugin_Handled;
	t = BreakString(autobuy, arg, sizeof(arg));
	while ( t != -1 )
	{
		i = i+t;
		TrimString(arg);
		FakeClientCommandEx(client, "buy %s", arg);
		t = BreakString(autobuy[i], arg, sizeof(arg));
	}
	return Plugin_Handled;
}

/*
 * Action:Event_PlayerSpawn(event, name, dontBroadcast)
 * Check them for restricted weapons on spawn.
 * Load a timer to double-check a few seconds later just to make sure.
 */
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new f_Client = GetClientOfUserId(GetEventInt(event, "userid"));
    primary[f_Client] = 0;
    secondary[f_Client] = 0;
    CheckClientForRestrictedWeapons(f_Client);
    PerformTimedRemove(f_Client);
    CountGrenades(f_Client);
    if ( g_SingleWeaponRound > 1 )
	CreateTimer(0.5, GiveSingleWeap, f_Client);
    return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_SingleWeaponRound > 1 )
	{
		decl String:temp[20];
		strcopy(temp, sizeof(temp), g_WeaponNames[g_SingleWeapon]);
		CharToUpper(temp[0]);
		PrintCenterTextAll("%s only this round!", temp);
	}
	else if ( g_KnivesOnly > 1 )
	{
		PrintCenterTextAll("Knives only this round!");
	}
	else if ( g_PistolsOnly > 1 )
	{
		PrintCenterTextAll("Pistols only this round!");
	}

}

/*
 * Action:Event_RoundEnd(event, name, dontBroadcast)
 * Turns off the KnifeOnly flag.
 */
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	switch ( g_SingleWeaponRound )
	{
		case 2:
		{
			g_SingleWeapon = -1;
			g_SingleWeaponRound = 0;
			// break;
		}
		case 1:
		{
			g_SingleWeapon = g_SingleWeaponNext;
			g_SingleWeaponNext = -1;
			g_SingleWeaponRound = 2;
			// break;
		}
		case 3:
		{
			g_SingleWeapon = g_SingleWeaponNext;
			g_SingleWeaponNext = -1;
			g_SingleWeaponRound = 2;
			// break;
		}
	}
	switch ( g_KnivesOnly )
	{
		case 2:
		{
			g_KnivesOnly = 0;
			// break;
		}
		case 1:
		{
			g_KnivesOnly = 2;
			// break;
		}
		case 3:
		{
			g_KnivesOnly = 2;
			// break;
		}
	}
	switch ( g_PistolsOnly )
	{
		case 2:
		{
			g_PistolsOnly = 0;
			// break;
		}
		case 1:
		{
			g_PistolsOnly = 2;
			// break;
		}
		case 3:
		{
			g_PistolsOnly = 2;
			// break;
		}
	}
	return Plugin_Continue;
}

// We're using decl here because this is going to be a heavily called event.
public Action:Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	// CheckClientForRestrictedWeapons(client);
	// return Plugin_Continue;
	decl String:f_WeaponName[64], f_Weapon;

	GetEventString(event, "item", f_WeaponName, 64);

    	if( ( f_Weapon = LookupWeaponNumber(f_WeaponName) ) == -1 )
		return Plugin_Continue;

	decl Slots:slot, remove;
	remove = 0;

	slot = g_WeaponSlot[f_Weapon];

	if (g_KnivesOnly > 1 && f_Weapon != _:Weapon_Knife)
		remove = 1;
	
        if(g_PistolsOnly > 1 && slot != Slot_Secondary && f_Weapon != _:Weapon_Knife)
		remove = 1;

        if(g_SingleWeaponRound > 1 && g_SingleWeapon != f_Weapon && f_Weapon != _:Weapon_Knife)
		remove = 1;

        decl f_Team;
	f_Team = GetClientTeam(client);

        if(IsRestricted(f_Weapon, f_Team, TYPE_REMOVE)) 
		remove = 1;

	if ( remove )
		RemoveWeaponFromClient(client, f_Weapon, true);

        return Plugin_Continue;
}

/*
 * PerformTimedRemove(client)
 * Checks to make sure that all restricted weapons
 * have been removed from all clients in-game.
 */
PerformTimedRemove(client)
{
    if(client == -1)
    {
        for(new i = 1; i <= g_MaxClients; i++)
        {
            if(IsClientConnected(i) && IsClientInGame(i))
            {
                CreateTimer(0.1, Timer_TimedRemove, i);
            }
        }
    }
    else
    {
        CreateTimer(0.5, Timer_TimedRemove, client);
    }
}

/*
 * Action:Timer_TimedRemove(timer, client)
 * Check for restricted weapons on the client and remove them.
 */
public Action:Timer_TimedRemove(Handle:timer, any:client)
{
    if(IsClientConnected(client) && IsClientInGame(client))
        CheckClientForRestrictedWeapons(client);
    return Plugin_Stop;
}

public Action:GiveSingleWeap(Handle:timer, any:client)
{
    if(g_SingleWeaponRound > 1 && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && RemoveWeaponFromClient(client, g_SingleWeapon, false) == -1)
	GivePlayerItem(client, g_WeaponNames[g_SingleWeapon]);
    return Plugin_Stop;
}
/*
public Action:CheckBuyPri(Handle:timer, any:client)
{
    if(IsClientConnected(client) && IsClientInGame(client))
    {
    	decl String:f_EntityName[64];
	new f_Entity = GetPlayerWeaponSlot(client, _:Slot_Primary);
  	if (f_Entity != -1)
	{
		GetEdictClassname(f_Entity, f_EntityName, sizeof(f_EntityName));
		// PrintToChat(client, "You are already carrying a %s.", g_WeaponNames[f_Weapon]);
		if ( LookupWeaponNumber(f_EntityName) != buypri[client] )
			primary[client]--;
	}
	else
		primary[client]--;
    }
    return Plugin_Stop;
}

public Action:CheckBuySec(Handle:timer, any:client)
{
    if(IsClientConnected(client) && IsClientInGame(client))
    {
    	decl String:f_EntityName[64];
	new f_Entity = GetPlayerWeaponSlot(client, _:Slot_Secondary);
  	if (f_Entity != -1)
	{
		GetEdictClassname(f_Entity, f_EntityName, sizeof(f_EntityName));
		// PrintToChat(client, "You are already carrying a %s.", g_WeaponNames[f_Weapon]);
		if ( LookupWeaponNumber(f_EntityName) != buysec[client] )
			secondary[client]--;
	}
	else
		secondary[client]--;
    }
    return Plugin_Stop;
}
*/