/* ===========================================================================
* TF2: Roll the Dice
* 
* filename. rtd.sp
* author.   linux_lover (pheadxdll)
* version.  0.1.8
*
* =============================================================================*/

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define VERSION "0.1.8"

// the good..
#define GOODSTART   0
#define NOCLIP      0
#define UBER        1
#define CRITS       2
#define GRAVITY     3
#define GODMODE     4
#define CLOAK       5
#define TOXIC       6
#define INSTANTKILL 7
#define INVIS       8
#define GOODEND     8
// ..and bad
#define BADSTART    9
#define BEACON      9
#define SLAY        10
#define FREEZE      11
#define BURN        12
#define TIMEBOMB    13
#define BLIND       14
#define DRUG        15
#define BADEND      15

// TF2 Classes
#define TF2_SCOUT 1
#define TF2_SNIPER 2
#define TF2_SOLDIER 3 
#define TF2_DEMOMAN 4
#define TF2_MEDIC 5
#define TF2_HEAVY 6
#define TF2_PYRO 7
#define TF2_SPY 8
#define TF2_ENG 9

new Handle:c_Enabled  = INVALID_HANDLE;
new Handle:c_Chance   = INVALID_HANDLE;
new Handle:c_Period   = INVALID_HANDLE;
new Handle:c_Wait     = INVALID_HANDLE;
new Handle:c_Radius   = INVALID_HANDLE;
new Handle:c_Gravity  = INVALID_HANDLE;
new Handle:c_Disabled = INVALID_HANDLE;
new Handle:c_Sudden   = INVALID_HANDLE;

new Handle:g_TimerHandle = INVALID_HANDLE;

new pluginInUse;

new PlayerUsing;
new CurrentAction;
new PlayerTimeStamp[MAXPLAYERS + 1];
new String:TimeMessage[32];
new PlayerCrits;
new g_cloakOffset;
new PlayerKills;
new TimerCount;
new DisabledCommands[MAXPLAYERS + 1];
new bypassGood;
new bypassBad;
new mapStart;
new suddenDeath;

public Plugin:myinfo =
{
	name = "TF2: Roll the Dice",
	author = "linux_lover",
	description = "Let's a user roll the dice for certain incentives.",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
        c_Enabled  = CreateConVar("sm_rtd_enabled","1","Enable/Disable rtd commands.");
        c_Chance   = CreateConVar("sm_rtd_chance","0.5","Percent chance of a GOOD command.");
        c_Period   = CreateConVar("sm_rtd_period","15.0","Period in seconds of the effect on a player.");
        c_Wait     = CreateConVar("sm_rtd_wait","120.0","Period in seconds the player must wait after rolling the dice once already.");
        c_Radius   = CreateConVar("sm_rtd_radius","250.0","Kill radius for players that are The Bomb.");
        c_Gravity  = CreateConVar("sm_rtd_gravity","0.1","Low gravity value.");
        c_Sudden   = CreateConVar("sm_rtd_suddendeath","0","Allow rtd commands during sudden death.")
        c_Disabled = CreateConVar("sm_rtd_disabled","","Disabled commands, seperated by commas.");

        CreateConVar("sm_rtd_version", VERSION, "TF2: rtd version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

        RegConsoleCmd("rtd", Command_rtd);
        RegAdminCmd("sm_rtd", Command_admin, ADMFLAG_GENERIC);
        RegAdminCmd("sm_rtd_reset", Command_reset, ADMFLAG_GENERIC);

        HookEvent("player_hurt",  Event_PlayerHurt);
        HookEvent("player_death", Event_PlayerDeath);

        HookEvent("teamplay_round_start",  Event_RoundStart);
        HookEvent("teamplay_round_active",  Event_RoundActive);
        HookEvent("teamplay_restart_round", Event_RoundRestart);
        HookEvent("teamplay_suddendeath_begin", Event_SuddenBegin);
        HookEvent("teamplay_suddendeath_end", Event_SuddenEnd);
        HookEvent("teamplay_game_over", Event_GameOver);
        HookEvent("teamplay_round_win", Event_RoundWin);

        g_cloakOffset = FindSendPropInfo("CTFPlayer", "m_flCloakMeter");

        pluginInUse = 0;
        PlayerCrits = 0;
        bypassGood  = 0;
        bypassBad   = 0;
        PlayerKills = 0;
        suddenDeath = 0;
        mapStart = 1;

        AutoExecConfig(false);
}

public OnMapStart()
{
        mapStart = 0;

        for(new i = 0; i <= GetMaxClients() + 1; i++)
                PlayerTimeStamp[i] = 0;
}

public OnMapEnd()
{
        mapStart = 0;
        FinishIt();

        for(new i = 0; i <= GetMaxClients() + 1; i++)
                PlayerTimeStamp[i] = 0;
}

public Action:Event_RoundWin(Handle:event,  const String:name[], bool:dontBroadcast)
{
        mapStart = 0;
}

public Action:Event_GameOver(Handle:event,  const String:name[], bool:dontBroadcast)
{
        mapStart = 0;
}

public Action:Event_SuddenBegin(Handle:event,  const String:name[], bool:dontBroadcast)
{
        suddenDeath = 1;
}

public Action:Event_SuddenEnd(Handle:event,  const String:name[], bool:dontBroadcast)
{
        suddenDeath = 0;
}

public Action:Event_RoundRestart(Handle:event,  const String:name[], bool:dontBroadcast)
{
        mapStart = 0;
}

public Action:Event_RoundStart(Handle:event,  const String:name[], bool:dontBroadcast)
{
        mapStart = 0;
}

public Action:Event_RoundActive(Handle:event,  const String:name[], bool:dontBroadcast)
{
        mapStart = 1;
}

public OnConfigsExecuted()
{
        Format(TimeMessage, sizeof(TimeMessage), "%i second(s)", GetConVarInt(c_Period));  

        HookConVarChange(c_Disabled, ConVarChange_Disabled);   
        HookConVarChange(c_Enabled, ConVarChange_Enabled);
        HookConVarChange(c_Period, ConVarChange_Period);

        ParseList();
}

public ConVarChange_Period(Handle:convar, const String:oldValue[], const String:newValue[])
{
        Format(TimeMessage, sizeof(TimeMessage), "%i second(s)", StringToInt(newValue)); 
}

public ConVarChange_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
        if(!StringToInt(newValue))
        {
                if(g_TimerHandle != INVALID_HANDLE)
                {
                        KillTimer(g_TimerHandle);
                        g_TimerHandle = INVALID_HANDLE;
                }

                PlayerUsing = 0;
                pluginInUse = 0;
                PlayerKills = 0;
                PlayerCrits = 0;
                TimerCount = 0;
                
                for(new i=0;i<=MAXPLAYERS + 1;i++)
                        PlayerTimeStamp[i]=0;          
        }
}

public ConVarChange_Disabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
        ParseList();
}

public OnClientPutInServer(client)
{
        PlayerTimeStamp[client] = 0;
}

public OnClientDisconnect(client)
{
        if(pluginInUse && client == PlayerUsing)
        {
                new String:zname[32];
                GetClientName(client, zname, sizeof(zname));

                PrintToChatAll("\x01\x04[RTD] \x03%s disconnected during RTD session!", zname);

                if(g_TimerHandle != INVALID_HANDLE)
                {
                        KillTimer(g_TimerHandle);
                        g_TimerHandle = INVALID_HANDLE;
                }

                PlayerUsing = 0;
                pluginInUse = 0;
                PlayerKills = 0;
                PlayerCrits = 0;
                TimerCount = 0; 
        }

        // Blank out the timestamp
        PlayerTimeStamp[client] = 0;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid");
        new victim = GetClientOfUserId(victimId);

        if(pluginInUse && PlayerUsing == victim)
        {
                new String:zname[32];
                GetClientName(PlayerUsing, zname, sizeof(zname));

                PrintToChatAll("\x01\x04[RTD] \x03%s\x04 died during RTD!", zname);

                if(CurrentAction == GRAVITY)
                        SetEntityGravity(PlayerUsing, 1.0);     

                if(CurrentAction == INVIS)
                        DoColorize(PlayerUsing);

                if(CurrentAction == NOCLIP)
                        SetEntityMoveType(PlayerUsing, MOVETYPE_WALK);

                if(CurrentAction == GODMODE)
                        SetEntProp(PlayerUsing, Prop_Data, "m_takedamage", 2, 1);

                if(g_TimerHandle != INVALID_HANDLE)
                {
                        KillTimer(g_TimerHandle);
                        g_TimerHandle = INVALID_HANDLE;
                }

                PlayerUsing = 0;
                pluginInUse = 0;
                PlayerKills = 0;
                PlayerCrits = 0;
                TimerCount = 0;
        }

	return Plugin_Continue;
}

public ParseList()
{
        new String:strDisabled[200];
        bypassGood = 0;
        bypassBad  = 0;

        for(new i = 0; i <= 15; i++)
        {
                DisabledCommands[i] = 0;
        }

        GetConVarString(c_Disabled, strDisabled, sizeof(strDisabled));

        if(StrContains(strDisabled, "noclip", false) >= 0)
                DisabledCommands[NOCLIP] = 1;

        if(StrContains(strDisabled, "uber", false) >= 0)
                DisabledCommands[UBER] = 1;

        if(StrContains(strDisabled, "crits", false) >= 0)
                DisabledCommands[CRITS] = 1;

        if(StrContains(strDisabled, "gravity", false) >= 0)
                DisabledCommands[GRAVITY] = 1;

        if(StrContains(strDisabled, "godmode", false) >= 0)
                DisabledCommands[GODMODE] = 1;

        if(StrContains(strDisabled, "cloak", false) >= 0)
                DisabledCommands[CLOAK] = 1;

        if(StrContains(strDisabled, "toxic", false) >= 0)
                DisabledCommands[TOXIC] = 1;

        if(StrContains(strDisabled, "instantkill", false) >= 0)
                DisabledCommands[INSTANTKILL] = 1;

        if(StrContains(strDisabled, "invis", false) >= 0)
                DisabledCommands[INVIS] = 1;

        if(StrContains(strDisabled, "beacon", false) >= 0)
                DisabledCommands[BEACON] = 1;

        if(StrContains(strDisabled, "slay", false) >= 0)
                DisabledCommands[SLAY] = 1;

        if(StrContains(strDisabled, "freeze", false) >= 0)
                DisabledCommands[FREEZE] = 1;

        if(StrContains(strDisabled, "burn", false) >= 0)
                DisabledCommands[BURN] = 1;

        if(StrContains(strDisabled, "timebomb", false) >= 0)
                DisabledCommands[TIMEBOMB] = 1;

        if(StrContains(strDisabled, "blind", false) >= 0)
                DisabledCommands[BLIND] = 1;

        if(StrContains(strDisabled, "drug", false) >= 0)
                DisabledCommands[DRUG] = 1;
                
        // idiot proofing
        new temp = 0;
        for(new i=GOODSTART; i<=BADEND; i++)
        {
                if(DisabledCommands[i])
                        temp++;
        }

        if(temp == BADEND + 1)
        {
                bypassGood = 1;
                bypassBad  = 1;
        }

        new tempa = 0;
        for(new i=GOODSTART; i<=GOODEND; i++)
        {
                if(DisabledCommands[i])
                        tempa++;
        }

        if(tempa == GOODEND + 1)
                bypassGood = 1;

        if((tempa == 2) && (DisabledCommands[UBER]) && (DisabledCommands[CLOAK]))
                bypassGood = 1;

        new tempb = 0;

        for(new i=BADSTART; i<=BADEND; i++)
        {
                if(DisabledCommands[i])
                        tempb++;
        }

        if(tempb == BADEND - BADSTART + 1)
                bypassBad = 1;

        // whew, thats over with     
}

public Action:Command_rtd(client, args)
{
        // Is rtd enabled?
        if(!GetConVarBool(c_Enabled))
        {
                ReplyToCommand(client, "\x01\x04[RTD] \x03Sorry, rtd is disabled at this time.");
                return Plugin_Continue;
        }

        if(!GetConVarInt(c_Sudden) && suddenDeath)
        {
                ReplyToCommand(client, "\x01\x04[RTD] \x03Sorry, no rtd during sudden death.");
                return Plugin_Continue;
        }

        if(!mapStart)
        {
                ReplyToCommand(client, "\x01\x04[RTD] \x03Wait for the round to start.");
                return Plugin_Continue;
        }

        // Player needs to wait longer than [sm_rtd_wait]?
        if((GetConVarInt(c_Wait)>0) && (GetConVarInt(c_Wait) > (GetTime() - PlayerTimeStamp[client])) && (PlayerTimeStamp[client] != 0))
        {
                new timeLeft = GetConVarInt(c_Wait) - (GetTime() - PlayerTimeStamp[client]);
                ReplyToCommand(client, "\x01\x04[RTD] \x03You need to wait \x04%i\x03 seconds.", timeLeft);

                return Plugin_Continue;
        }   

        // Already running an instance?
        if(pluginInUse)
        {
                new String:name[32];
                GetClientName(PlayerUsing, name, sizeof(name));

                ReplyToCommand(client, "\x01\x04[RTD] \x03I'm busy with \x04%s\x03 right now!", name);
                return Plugin_Continue;
        }      
               
        // Player can roll the dice
        pluginInUse = 1;
        PlayerCrits = 0;
        PlayerKills = 0;
        PlayerUsing = client;
        PlayerTimeStamp[client] = GetTime(); // Just in case user dies.

        RollTheDice(client);  

        return Plugin_Continue;
}

public Action:Command_reset(client, args)
{
        if(args < 1)
        {
                ReplyToCommand(client, "[SM] Usage: sm_rtd_reset <#userid|name>");
                return Plugin_Handled;
        }

        decl String:Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));

	decl String:arg[65];
	new len = BreakString(Arguments, arg, sizeof(arg));
	
	if (len == -1)
	{
		/* Safely null terminate */
		len = 0;
		Arguments[0] = '\0';
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		if (tn_is_ml)
		{
			ShowActivity2(client, "[SM] ", "%t", "Cleared timestamp on target", target_name);
		}
		else
		{
			ShowActivity2(client, "[SM] ", "%t", "Cleared timestamp on target", "_s", target_name);
		}
		
                for(new i = 0; i < target_count; i++)
                {
                        PlayerTimeStamp[target_list[i]] = 0;
                }
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}

	return Plugin_Handled;
}

public Action:Command_admin(client, args)
{
        if(args < 1)
        {
                ReplyToCommand(client, "[SM] Usage: sm_rtd <#userid|name>");
                return Plugin_Handled;
        }

        if(pluginInUse)
        {
                new String:name[32];
                GetClientName(PlayerUsing, name, sizeof(name));

                ReplyToCommand(client, "\x01\x04[RTD] \x03I'm busy with \x04%s\x03 right now!", name);
                return Plugin_Handled;
        }          

        decl String:Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));

	decl String:arg[65];
	new len = BreakString(Arguments, arg, sizeof(arg));
	
	if (len == -1)
	{
		/* Safely null terminate */
		len = 0;
		Arguments[0] = '\0';
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		if (tn_is_ml)
		{
			ShowActivity2(client, "[SM] ", "%t", "Rolled dice on target", target_name);
		}
		else
		{
			ShowActivity2(client, "[SM] ", "%t", "Rolled dice on target", "_s", target_name);
		}
		
                pluginInUse = 1;
                PlayerCrits = 0;
                PlayerKills = 0
                PlayerUsing = target_list[0];

                RollTheDice(target_list[0]);

	}
	else
	{
		ReplyToTargetError(client, target_count);
	}

	return Plugin_Handled;
}

public RollTheDice(Player)
{
        if(!IsClientInGame(Player) || !IsPlayerAlive(Player))
        {
                ReplyToCommand(Player, "\x01\x04[RTD]\x03 Player needs to be alive.");
                return 1;
        }

        if(g_TimerHandle != INVALID_HANDLE)
        {
                KillTimer(g_TimerHandle);
                g_TimerHandle = INVALID_HANDLE;
        }

        new goodCommand = 0;

        // Calculate the chance of a GOOD command
        if(GetConVarFloat(c_Chance) > GetRandomFloat(0.0, 1.0))
        {
                goodCommand = 1;
        }

        if(goodCommand)
        {
                new action = GetRandomInt(GOODSTART, GOODEND);
                
                if(!bypassGood)
                {
                        while(DisabledCommands[action] || ((action == UBER) && GetEntProp(Player, Prop_Send, "m_iClass") != TF2_MEDIC && !DisabledCommands[UBER]) || ((action == CLOAK) && GetEntProp(Player, Prop_Send, "m_iClass") != TF2_SPY && !DisabledCommands[CLOAK])) // thats not long at all :3
                        {
                                action = GetRandomInt(GOODSTART, GOODEND);
                        }
                }else{
                        if((action == UBER) && (GetEntProp(Player, Prop_Send, "m_iClass") != TF2_MEDIC))
                                action++;
                
                        if((action == CLOAK) && (GetEntProp(Player, Prop_Send, "m_iClass") != TF2_SPY))
                                action++;
                }

                CurrentAction = action;

                switch(action)
                {
                        case NOCLIP:
                                DiceNoClip(Player);
                        case UBER:
                                DiceUber(Player)
                        case CRITS:
                                DiceCrits(Player);
                        case GRAVITY:
                                DiceGravity(Player);
                        case GODMODE:
                                DiceGodmode(Player);
                        case CLOAK:
                                DiceCloak(Player);
                        case TOXIC:
                                DiceToxic(Player);
                        case INSTANTKILL:
                                DiceInstantkill(Player);
                        case INVIS:
                                DiceInvis(Player);
                }
        }else{
                new action = GetRandomInt(BADSTART, BADEND);

                if(!bypassBad)
                {
                        while((DisabledCommands[action]))
                        {
                                action = GetRandomInt(BADSTART, BADEND);
                        }
                }
                
                CurrentAction = action;

                switch(action)
                {
                        case BEACON:
                                DiceBeacon(Player);
                        case SLAY:
                                DiceSlay(Player);
                        case FREEZE:
                                DiceFreeze(Player);
                        case BURN:
                                DiceBurn(Player);
                        case TIMEBOMB:
                                DiceTimebomb(Player);
                        case BLIND:
                                DiceBlind(Player);
                        case DRUG:
                                DiceDrug(Player);
                }
        }

        return 1;
}

public Action:Event_PlayerHurt(Handle:event,  const String:name[], bool:dontBroadcast)
{
        if(PlayerKills && pluginInUse)
        {
        	new victimId = GetEventInt(event, "userid");
        	new attackerId = GetEventInt(event, "attacker");
        	new victim = GetClientOfUserId(victimId);
        	new attacker = GetClientOfUserId(attackerId);

                if((attacker == PlayerUsing) && (victim != PlayerUsing))
                {
                        new String:playername[32];
                        GetClientName(PlayerUsing, playername, sizeof(playername));

                        ForcePlayerSuicide(victim);
                        SendDeathEvent(attacker, victim);
                        PrintHintText(victim, "You were killed by %s's instant kills.", playername); 
                }
        }
}

/*=================================================================
 Dice Event Routines
===================================================================*/
public DiceInvis(client)
{
        new String:name[32];

        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s is invisible!", name);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and was given invisibility.", name, CurrentAction);

        CreateInvis(client);

        TimerCount = 0;
        g_TimerHandle = CreateTimer(1.0, NoclipRepeat, _, TIMER_REPEAT);

        CreateTimer(GetConVarFloat(c_Period), DiceInvisOff, client);
}

public Action:DiceInvisOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                new String:name[32];
                GetClientName(client, name, sizeof(name));
        
                DoColorize(client);

                PrintHintTextToAll("%s is no longer invisible!", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04 is no longer invisible.", name);

                FinishIt();
        }
}

public DiceDrug(client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s was drugged!", name);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and was drugged.", name, CurrentAction);    
        
        ServerCommand("sm_drug #%i", GetClientUserId(client));   
    
        CreateTimer(GetConVarFloat(c_Period), DiceDrugOff, client);         
}

public Action:DiceDrugOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                new String:name[32];
                GetClientName(client, name, sizeof(name));

                ServerCommand("sm_drug #%i", GetClientUserId(client));
        
                PrintHintTextToAll("%s is sober.", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04 is no longer drugged.", name); 
        
                FinishIt();       
        } 
}

public DiceBlind(client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s was blinded!", name);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and was blinded.", name, CurrentAction);    
        
        ServerCommand("sm_blind #%i 255", GetClientUserId(client));   
    
        CreateTimer(GetConVarFloat(c_Period), DiceBlindOff, client);       
}

public Action:DiceBlindOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                new String:name[32];
                GetClientName(client, name, sizeof(name));

                ServerCommand("sm_blind #%i 0", GetClientUserId(client));
        
                PrintHintTextToAll("%s was unblinded.", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04 is no longer blind.", name); 
        
                FinishIt();
        }
}

public DiceTimebomb(client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s is a timebomb!", name);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and won a timebomb.", name, CurrentAction);    
        
        ServerCommand("sm_timebomb #%i 1", GetClientUserId(client));   
    
        CreateTimer(10.0, DiceTimebombOff, client);
}

public Action:DiceTimebombOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
                FinishIt();
}

public DiceBurn(client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s was burned!", name);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and was burned.", name, CurrentAction);    
        
        ServerCommand("sm_burn #%i %i", GetClientUserId(client), GetConVarInt(c_Period));   
        
        CreateTimer(GetConVarFloat(c_Period), DiceBurnOff, client);          
}

public Action:DiceBurnOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                new String:name[32];
                GetClientName(client, name, sizeof(name));

                PrintHintTextToAll("%s was unburned!", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04 is no longer burning.", name);

                FinishIt();
        }
}

public DiceFreeze(client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s was frozen for %s!", name, TimeMessage);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and was frozen.", name, CurrentAction);    
        
        ServerCommand("sm_freeze #%i %i", GetClientUserId(client), GetConVarInt(c_Period));  
        
        CreateTimer(GetConVarFloat(c_Period), DiceFreezeOff, client);    
}

public Action:DiceFreezeOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                new String:name[32];
                GetClientName(client, name, sizeof(name));

                PrintHintTextToAll("%s was unfrozen!", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04 is no longer frozen.", name);
                FinishIt();
        }
}

public DiceSlay(client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s is a loser!", name);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and was slayed!", name, CurrentAction);  

        ForcePlayerSuicide(client);

        FinishIt();
}

public DiceBeacon(client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s has beacon for %s!", name, TimeMessage);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and won beacon.", name, CurrentAction);  
        
        ServerCommand("sm_beacon #%i", GetClientUserId(client));
        
        CreateTimer(GetConVarFloat(c_Period), DiceBeaconOff, client);  
}

public Action:DiceBeaconOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                new String:name[32];
                GetClientName(client, name, sizeof(name));

                PrintHintTextToAll("%s was unbeaconed!", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04 in no longer beaconed.", name);

                ServerCommand("sm_beacon #%i", GetClientUserId(client));
        
                FinishIt();
        }
}

public DiceInstantkill(client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s has instant kills for %s!", name, TimeMessage);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and has instant kills.", name, CurrentAction);

        PlayerKills = 1;

        CreateTimer(GetConVarFloat(c_Period), DiceInstantkillOff, client);
}

public Action:DiceInstantkillOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                new String:name[32];
                GetClientName(client, name, sizeof(name));

                PrintHintTextToAll("%s no longer has instant kills.", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04 no longer has instant kills.", name);     
        
                FinishIt();
        }
}

public DiceToxic(client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s is toxic for %s!", name, TimeMessage);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and is toxic.", name, CurrentAction);   
        
        if(g_TimerHandle != INVALID_HANDLE)
        {
                KillTimer(g_TimerHandle);
                g_TimerHandle = INVALID_HANDLE;
        }
                
        g_TimerHandle = CreateTimer(1.0, ToxicRepeat, _, TIMER_REPEAT); 
        
        CreateTimer(GetConVarFloat(c_Period), DiceToxicOff, client);     
}

public Action:DiceToxicOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                new String:name[32];
                GetClientName(client, name, sizeof(name));

                PrintHintTextToAll("%s is no longer toxic.", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04 is no longer toxic.", name);     
                
                if(g_TimerHandle != INVALID_HANDLE)
                {
                        KillTimer(g_TimerHandle);   
                        g_TimerHandle = INVALID_HANDLE;
                }
        
                FinishIt();   
        }     
}

public Action:ToxicRepeat(Handle:Timer)
{
        if(pluginInUse)
        {
                new maxClients = GetMaxClients();
                new Float:vec[3];
                GetClientEyePosition(PlayerUsing, vec);
        
                for (new i = 1; i < maxClients; i++)
                {
                        if(!IsClientInGame(i) || !IsPlayerAlive(i) || i == PlayerUsing)
                        {
                            continue;
                        }
        
                        if(GetClientTeam(i) == GetClientTeam(PlayerUsing))
                        {
                            continue;
                        }
        
                        new Float:pos[3];
                        GetClientEyePosition(i, pos);
        
                        new Float:distance = GetVectorDistance(vec, pos);
        
                        if(distance > GetConVarFloat(c_Radius))
                        {
                            continue;
                        }
        
                        new String:name[32];
                        GetClientName(PlayerUsing, name, sizeof(name));

                        ForcePlayerSuicide(i);
                        SendDeathEvent(PlayerUsing, i);

                        PrintHintText(i, "You were killed by %s's toxicity. x_x", name);
                }
        }
}

public DiceCloak(client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s has infinite cloak for %s!", name, TimeMessage);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and won infinite cloak.", name, CurrentAction);  
        
        if(g_TimerHandle != INVALID_HANDLE)
        {
                KillTimer(g_TimerHandle);
                g_TimerHandle = INVALID_HANDLE;
        }

        g_TimerHandle = CreateTimer(1.0, CloakRepeat, _, TIMER_REPEAT);
        
        CreateTimer(GetConVarFloat(c_Period), DiceCloakOff, client);     
}

public Action:DiceCloakOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                new String:name[32];
                GetClientName(client, name, sizeof(name));

                PrintHintTextToAll("%s's cloak wore off.", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04's cloak wore off.", name);     
                
                if(g_TimerHandle != INVALID_HANDLE)
                {
                        KillTimer(g_TimerHandle);   
                        g_TimerHandle = INVALID_HANDLE;
                }        

                FinishIt();
        }
}

public Action:CloakRepeat(Handle:Timer)
{
        if(pluginInUse)
            SetEntDataFloat(PlayerUsing, g_cloakOffset, 100.0);
}

public DiceGodmode(client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s has godmode for %s!", name, TimeMessage);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and won godmode.", name, CurrentAction);  
        
        SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
        
        CreateTimer(GetConVarFloat(c_Period), DiceGodmodeOff, client);     
}

public Action:DiceGodmodeOff(Handle:Timer, any:client)
{
        SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);

        if(pluginInUse && PlayerUsing == client)
        {
                new String:name[32];
                GetClientName(client, name, sizeof(name));

                PrintHintTextToAll("%s's godmode wore off.", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04's godmode wore off.", name);     
        
                FinishIt();
        }

        
}

public DiceGravity(client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s has low gravity for %s!", name, TimeMessage);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and won low gravity.", name, CurrentAction);

        SetEntityGravity(client, GetConVarFloat(c_Gravity));

        CreateTimer(GetConVarFloat(c_Period), DiceGravityOff, client);
}

public Action:DiceGravityOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                new String:name[32];
                GetClientName(client, name, sizeof(name));

                SetEntityGravity(client, 1.0);
                PrintHintTextToAll("%s's gravity wore off.", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04's gravity wore off.", name); 

                FinishIt();
        }    
}

public DiceCrits(client)
{
        new String:name[32];
        GetClientName(PlayerUsing, name, sizeof(name));

        PrintCenterTextAll("%s has crits for %s!", name, TimeMessage);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and won crits.", name, CurrentAction);

        PlayerCrits = 1;

        CreateTimer(GetConVarFloat(c_Period), DiceCritsOff, client);
}

public Action:DiceCritsOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                new String:name[32];
                GetClientName(PlayerUsing, name, sizeof(name));

                PrintHintTextToAll("%s's crits wore off.", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04's crits wore off.", name);
        
                PlayerCrits = 0;
        
                FinishIt();
        }
}

public DiceUber(client)
{
        new String:name[32];
        GetClientName(PlayerUsing, name, sizeof(name));

        PrintCenterTextAll("%s has UberCharge for %s!", name, TimeMessage);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and won UberCharge.", name, CurrentAction);

        if(g_TimerHandle != INVALID_HANDLE)
        {
                KillTimer(g_TimerHandle);
                g_TimerHandle = INVALID_HANDLE;
        }

        g_TimerHandle = CreateTimer(1.0, UberRepeat, _, TIMER_REPEAT);

        CreateTimer(GetConVarFloat(c_Period), DiceUberOff, client)
}

public Action:DiceUberOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                new String:name[32];
                GetClientName(client, name, sizeof(name));

                if(g_TimerHandle != INVALID_HANDLE)
                {
                        KillTimer(g_TimerHandle);
                        g_TimerHandle = INVALID_HANDLE;
                }
        
                PrintHintTextToAll("%s's UberCharge wore off!", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04's UberCharge wore off.", name);
        
                FinishIt();
        }
}

public Action:UberRepeat(Handle:Timer)
{
        if(pluginInUse)
            TF_SetUberLevel(PlayerUsing, 100);
}

public DiceNoClip(client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        PrintCenterTextAll("%s has noclip for %s!", name, TimeMessage);
        PrintToChatAll("\x01\x04[RTD] \x03%s\x04 rolled a %d and won noclip.", name, CurrentAction);

        // Enable the noclip
        SetEntityMoveType(client, MOVETYPE_NOCLIP);

        if(g_TimerHandle != INVALID_HANDLE)
        {
                KillTimer(g_TimerHandle);
                g_TimerHandle = INVALID_HANDLE;
        }

        TimerCount = 0;
        g_TimerHandle = CreateTimer(1.0, NoclipRepeat, _, TIMER_REPEAT);

        // Make timer
        CreateTimer(GetConVarFloat(c_Period), DiceNoClipOff, client);
}

public Action:DiceNoClipOff(Handle:Timer, any:client)
{
        new String:name[32];
        GetClientName(client, name, sizeof(name));

        if(pluginInUse && PlayerUsing == client)
        {
                PrintHintTextToAll("%s's noclip wore off!", name);
                PrintToChatAll("\x01\x04[RTD] \x03%s\x04's noclip wore off.", name);

                FinishIt();
        }

        SetEntityMoveType(client, MOVETYPE_WALK);
}

public Action:NoclipRepeat(Handle:Timer)
{
        TimerCount++;
        if(pluginInUse)
        {
            PrintCenterText(PlayerUsing, "%i second(s) left!", GetConVarInt(c_Period) - TimerCount);
        }
}

public FinishIt()
{
        if(g_TimerHandle != INVALID_HANDLE)
        {
                KillTimer(g_TimerHandle);
                g_TimerHandle = INVALID_HANDLE;
        }

        PlayerTimeStamp[PlayerUsing] = GetTime();
        PlayerUsing = 0;
        pluginInUse = 0;
        PlayerKills = 0;
        PlayerCrits = 0;
        TimerCount = 0;

        return;
}

stock TF_SetUberLevel(client, uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
        if(pluginInUse && PlayerCrits && client == PlayerUsing)
        {
                result = true;
                return Plugin_Handled;
        }
	
	return Plugin_Continue;
}
public SendDeathEvent(attacker, victim)
{
	new Handle:event = CreateEvent("player_death");
	if (event == INVALID_HANDLE)
	{
		return;
	}
 
	SetEventInt(event, "userid", GetClientUserId(victim));
	SetEventInt(event, "attacker", GetClientUserId(attacker));
	//SetEventString(event, "weapon", weapon);
	//SetEventBool(event, "headshot", 0);
	FireEvent(event);
}

// Invisiablilty brought to you by Spazman0
CreateInvis(target)	
{
	SetAlpha(target,0);
}

SetAlpha(target, alpha)
{		
	SetWeaponsAlpha(target,alpha);
	SetEntityRenderMode(target, RENDER_TRANSCOLOR);
	SetEntityRenderColor(target, 255, 255, 255, alpha);	
}

SetWeaponsAlpha(target, alpha)
{
        if(IsPlayerAlive(target))
        {
        	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	
        
        	for(new i = 0, weapon; i < 47; i += 4)
        	{
        		weapon = GetEntDataEnt2(target, m_hMyWeapons + i);
        	
        		if(weapon > -1 )
        		{
        			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
        			SetEntityRenderColor(weapon, 255, 255, 255, alpha);
        		}
        	}
        }
}

DoColorize(client)
{
        SetWeaponsColor(client);
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	
	SetAlpha(client, 255);
}

SetWeaponsColor(client)
{
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	

	for(new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
	
		if(weapon > -1 )
		{
			SetEntityRenderMode(weapon, RENDER_NORMAL);
			SetEntityRenderColor(weapon, 255, 255, 255, 255);
		}
	}
}
