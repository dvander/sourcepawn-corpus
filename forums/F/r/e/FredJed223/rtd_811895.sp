/* ===========================================================================
* TF2: Roll the Dice
* 
* filename. rtd.sp
* author.   linux_lover (pheadxdll)
* version.  0.2
*
* =============================================================================*/
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define VERSION "0.2"

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
#define HEALTH      8
#define INVIS       9
#define GOODEND     9
// ..and bad
#define BADSTART    10
#define BEACON      10
#define SLAY        11
#define FREEZE      12
#define BURN        13
#define TIMEBOMB    14
#define BLIND       15
#define DRUG        16
#define RAINBOW     17
#define BADEND      17

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

#define COLNUM 6

new Handle:c_Enabled    = INVALID_HANDLE;
new Handle:c_Chance     = INVALID_HANDLE;
new Handle:c_Period     = INVALID_HANDLE;
new Handle:c_Wait       = INVALID_HANDLE;
new Handle:c_Radius     = INVALID_HANDLE;
new Handle:c_Gravity    = INVALID_HANDLE;
new Handle:c_Disabled   = INVALID_HANDLE;
new Handle:c_Sudden     = INVALID_HANDLE;
new Handle:c_Health     = INVALID_HANDLE;
new Handle:c_PlayerWait = INVALID_HANDLE;

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
new DisabledCommands[BADEND + 1];
new bypassGood;
new bypassBad;

new bool:gCanRun = false;
new bool:gWaitOver = false;
new Float:gMapStart;
new bool:gameStart = false;

new classHealth[10] = {0, 125, 125, 200, 175, 150, 300, 175, 125, 125};
new colors[COLNUM][4] = {{255, 0, 0, 192}, {255, 128, 0, 192}, {255, 255, 0, 192}, {0, 255, 0, 192}, {0, 0, 255, 192}, {128, 0, 255, 192}};
#define MAXTRIGGERS 4
static String:triggers[MAXTRIGGERS][] = { "rtd","rollthedice","diceroll","rolldice" }

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
        c_Enabled    = CreateConVar("sm_rtd_enabled","1","Enable/Disable rtd commands.");
        c_PlayerWait = CreateConVar("sm_rtd_playerwait","1","Whether the server has a 'waiting for players' period.");
        c_Chance     = CreateConVar("sm_rtd_chance","0.5","Percent chance of a GOOD command.");
        c_Period     = CreateConVar("sm_rtd_period","15.0","Period in seconds of the effect on a player.");
        c_Wait       = CreateConVar("sm_rtd_wait","120.0","Period in seconds the player must wait after rolling the dice once already.");
        c_Radius     = CreateConVar("sm_rtd_radius","275.0","Kill radius for players that are The Bomb.");
        c_Gravity    = CreateConVar("sm_rtd_gravity","0.1","Low gravity value.");
        c_Health     = CreateConVar("sm_rtd_health","1.5","Health multiplier.");
        c_Sudden     = CreateConVar("sm_rtd_suddendeath","0","Allow rtd commands during sudden death. Set to a 2 if using a death match melee plugin.")
        c_Disabled   = CreateConVar("sm_rtd_disabled","","Disabled commands, seperated by commas.");

        CreateConVar("sm_rtd_version", VERSION, "TF2: !rtd Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

        RegConsoleCmd("say", Command_Say);
        RegConsoleCmd("say_team", Command_Say);

        RegAdminCmd("sm_rtd", Command_admin, ADMFLAG_GENERIC);
        RegAdminCmd("sm_rtd_reset", Command_reset, ADMFLAG_GENERIC);

        HookEvent("player_hurt",  Event_PlayerHurt);
        HookEvent("player_death", Event_PlayerDeath);
        HookEvent("player_spawn",PlayerSpawn);

        // Round Start Events
	HookEvent("teamplay_round_start", MainEvents);
	HookEvent("teamplay_round_active", MainEvents);
	HookEvent("teamplay_restart_round", MainEvents);

        // Round End Events
	HookEvent("teamplay_round_stalemate", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_game_over", RoundEnd, EventHookMode_PostNoCopy);
        HookEvent("teamplay_suddendeath_begin", RoundEnd, EventHookMode_PostNoCopy);
        HookEvent("teamplay_suddendeath_end", RoundEnd, EventHookMode_PostNoCopy);

        g_cloakOffset = FindSendPropInfo("CTFPlayer", "m_flCloakMeter");

        pluginInUse = 0;
        PlayerCrits = 0;
        bypassGood  = 0;
        bypassBad   = 0;
        PlayerKills = 0;

        AutoExecConfig(false);
}

public OnMapStart()
{
        for(new i = 0; i <= GetMaxClients() + 1; i++)
                PlayerTimeStamp[i] = 0;

        gameStart = false;

	gCanRun = false;
	gWaitOver = false;
	gMapStart = GetEngineTime();
	MainEvents(INVALID_HANDLE, "map_start", true);       
}

public OnMapEnd()
{
        FinishIt();

        for(new i = 0; i <= GetMaxClients() + 1; i++)
                PlayerTimeStamp[i] = 0;
}

public Action:MainEvents(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(c_PlayerWait)==1)
	{
		if (StrEqual(name,"teamplay_restart_round", false))
		{
			gCanRun = true;
			gWaitOver = true;
		}
	}
	else
	{
		if (!StrEqual(name, "map_start"))
		{
			gCanRun = true;
			gWaitOver = true;
		}
	}
	
	if (gWaitOver)
	{
		if (StrEqual(name, "teamplay_round_start"))
		{
			gCanRun = false;
		}
		else if (StrEqual(name, "teamplay_round_active"))
		{
			gCanRun = true;
		}
	}
	
        //PrintToChatAll("Mainevent: %s gCanRun: %b", name, gCanRun);

	return Plugin_Continue;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
        gCanRun = false;

        if(StrEqual(name,"teamplay_round_stalemate", false) && GetConVarInt(c_Sudden)==2)
        {
                gCanRun = true;
        }else if(StrEqual(name,"teamplay_suddendeath_begin", false) && GetConVarInt(c_Sudden)==1)
        {
                gCanRun = true;
        }else if(StrEqual(name,"teamplay_suddendeath_end", false))
        {
                gCanRun = false;
        }	

        //PrintToChatAll("Mainevent: %s gCanRun: %b", name, gCanRun);

        return Plugin_Continue;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!gCanRun && !gameStart)
	{
		if (GetEngineTime() > (gMapStart + 60.0))
		{
			gCanRun = true;
                        gameStart = true;
		}
	}    

        return Plugin_Continue;
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
                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 disconnected during RTD session!", client);

                SayText2(client, nm);

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
                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 died during RTD!", PlayerUsing);

                SayText2(PlayerUsing, nm);

                if(CurrentAction == GRAVITY)
                        SetEntityGravity(PlayerUsing, 1.0);     

                if(CurrentAction == NOCLIP)
                        SetEntityMoveType(PlayerUsing, MOVETYPE_WALK);

                if(CurrentAction == GODMODE)
                        SetEntProp(PlayerUsing, Prop_Data, "m_takedamage", 2, 1);

                if(g_TimerHandle != INVALID_HANDLE)
                {
                        KillTimer(g_TimerHandle);
                        g_TimerHandle = INVALID_HANDLE;
                }

                PlayerTimeStamp[victim] = GetTime();
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

        for(new i = 0; i <= BADEND; i++)
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

        if(StrContains(strDisabled, "health", false) >= 0)
                DisabledCommands[HEALTH] = 1;

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

        if(StrContains(strDisabled, "rainbow", false) >= 0)
                DisabledCommands[RAINBOW] = 1;
                
        // idiot proofing / infinite loop protection
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

public Action:Command_Say(client, argc) 
{
        decl String:args[192],String:command[192];
        new success = 0;

	GetCmdArgString(args,192);
	GetLiteralString(args,command,192);

        for(new x=0; x<MAXTRIGGERS; x++)
        {
                if(StrEqual(command, triggers[x]))
                {
                        success = 1;
                        break;
                }
        }

        if(!success)
                return Plugin_Continue;

        // Is rtd enabled?
        if(!GetConVarBool(c_Enabled))
        {
                ReplyToCommand(client, "\x01\x04[RTD] \x03Sorry, rtd is disabled at this time.");
                return Plugin_Handled;
        }

        if(!gCanRun)
        {
                ReplyToCommand(client, "\x01\x04[RTD] \x03Wait for the round to start.");
                return Plugin_Handled;
        }

        if(PlayerUsing == client)
        {
                ReplyToCommand(client, "\x01\x04[RTD]\x03 Your already running RTD!");
                return Plugin_Handled;
        }

        if(!IsClientInGame(client) || !IsPlayerAlive(client))
        {
                ReplyToCommand(client, "\x01\x04[RTD]\x03 You need to be alive.");
                return Plugin_Handled;
        }

        // Player needs to wait longer than [sm_rtd_wait]?
        if((GetConVarInt(c_Wait)>0) && (GetConVarInt(c_Wait) > (GetTime() - PlayerTimeStamp[client])) && (PlayerTimeStamp[client] != 0))
        {
                new timeLeft = GetConVarInt(c_Wait) - (GetTime() - PlayerTimeStamp[client]);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD]\x01 You need to wait \x03%i\x01 seconds.", timeLeft);

                SayText2One(client, client, nm);

                return Plugin_Handled;
        }   

        // Already running an instance?
        if(pluginInUse)
        {
                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x01I'm busy with \x03%N\x01 right now!", PlayerUsing);

                SayText2One(client, PlayerUsing, nm);
                return Plugin_Handled;
        }      

        // Player can roll the dice
        pluginInUse = 1;
        PlayerCrits = 0;
        PlayerKills = 0;
        PlayerUsing = client;
        PlayerTimeStamp[client] = GetTime(); // Just in case user dies.

        RollTheDice(client);  

        return Plugin_Handled;
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
                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x01I'm busy with \x03%N\x01 right now!", PlayerUsing);

                SayText2One(client, PlayerUsing, nm);
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
                if(!IsClientInGame(target_list[0]) || !IsPlayerAlive(target_list[0]))
                {
                        ReplyToCommand(client, "\x01\x04[RTD]\x03 Player needs to be alive.");
                        return Plugin_Handled;
                }

                if(target_list[0] == PlayerUsing)
                {
                    ReplyToCommand(client, "\x01\x04[RTD]\x03 Player is already using RTD.");
                    return Plugin_Handled;
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

                //PrintToChatAll("%i", action);
                
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
                        case HEALTH:
                                DiceHealth(Player);
                        case INVIS:
                                DiceInvis(Player);
                }
        }else{
                new action = GetRandomInt(BADSTART, BADEND);

                //PrintToChatAll("%i", action);

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
                        case RAINBOW:
                                DiceRainbow(Player);
                }

                //PrintToChatAll("Bad: %i", action);

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
                        new m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond") ;

                        new cond = GetEntData(victim, m_nPlayerCond);

                        if(cond != 32)
                        {
                            ForcePlayerSuicide(victim);
                            //SendDeathEvent(attacker, victim);
                            PrintHintText(victim, "You were killed by %N's instant kills.", PlayerUsing); 
                        }
                }
        }

        return Plugin_Continue;
}

/*=================================================================
 Dice Event Routines
===================================================================*/
/* Needs to be worked on a bit for a future release.
public DiceSnail(client)
{
        PrintCenterTextAll("%N is a snail!", client)

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and is a snail.", client, CurrentAction);

        SayText2(client, nm);

        SetEntDataFloat(client,FindSendPropInfo("CTFPlayer", "m_flMaxspeed"), GetConVarFloat(c_Speed) * 400);

        CreateTimer(GetConVarFloat(c_Period), DiceSnailOff, client);    
}

public Action:DiceSnailOff(Handle:Timer, any:client)
{
        SetEntDataFloat(client,FindSendPropInfo("CTFPlayer", "m_flMaxspeed"), 400.0);

        if(pluginInUse && PlayerUsing == client)
        {       
                PrintHintTextToAll("%N is no a snail!", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 is no longer a snail.", client);

                SayText2(client, nm);

                FinishIt();
        }        
}
*/

public DiceRainbow(client)
{
        PrintCenterTextAll("%N is a rainbow!", client)

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and is a rainbow.", client, CurrentAction);

        SayText2(client, nm);

        TimerCount = 0;
        g_TimerHandle = CreateTimer(1.0, RainbowTimer, _, TIMER_REPEAT);


        CreateTimer(GetConVarFloat(c_Period), DiceRainbowOff, client);
}

public Action:DiceRainbowOff(Handle:Timer, any:client)
{
        DoColorize(client);

        if(pluginInUse && PlayerUsing == client)
        {       
                PrintHintTextToAll("%N is no longer a rainbow!", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 is no longer a rainbow.", client);

                SayText2(client, nm);

                FinishIt();
        }
}

public Action:RainbowTimer(Handle:Timer)
{
        if(pluginInUse)
        {
                RainbowRepeat(PlayerUsing, TimerCount);

                TimerCount++;

                if(TimerCount>COLNUM - 1)
                        TimerCount = 0;
        }
}

public DiceHealth(client)
{
        new maxClients = GetMaxClients();

        for(new i=1; i<=maxClients; i++)
        {
                if(!IsClientInGame(i) || !IsPlayerAlive(i))
                {
                        continue;
                }

                if(GetClientTeam(i) != GetClientTeam(client))
                {
                        continue;
                }

                SetEntityHealth(i, RoundToCeil(classHealth[GetEntProp(i, Prop_Send, "m_iClass")] * GetConVarFloat(c_Health))); // buff the health
        }

        new String:nm[255];
        switch(GetClientTeam(client))
        {
                case 2: // red
                        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and won the \x03red\x01 team health.", client, CurrentAction);

                case 3: // blu
                        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and won the \x03blu\x01 team health.", client, CurrentAction);
        }

        SayText2(client, nm);

        FinishIt();
}

public DiceInvis(client)
{
        PrintCenterTextAll("%N is invisible!", client);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and was given invisibility.", client, CurrentAction);

        SayText2(client, nm);

        CreateInvis(client);

        TimerCount = 0;
        g_TimerHandle = CreateTimer(1.0, NoclipRepeat, _, TIMER_REPEAT);

        CreateTimer(GetConVarFloat(c_Period), DiceInvisOff, client);
}

public Action:DiceInvisOff(Handle:Timer, any:client)
{
        DoColorize(client);

        if(pluginInUse && PlayerUsing == client)
        {       
                PrintHintTextToAll("%N is no longer invisible!", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 is no longer invisible.", client);

                SayText2(client, nm);

                FinishIt();
        }
}

public DiceDrug(client)
{
        PrintCenterTextAll("%N was drugged!", client);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and was drugged.", client, CurrentAction);

        SayText2(client, nm);  
        
        ServerCommand("sm_drug #%i", GetClientUserId(client));   
    
        CreateTimer(GetConVarFloat(c_Period), DiceDrugOff, client);         
}

public Action:DiceDrugOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                ServerCommand("sm_drug #%i", GetClientUserId(client));
        
                PrintHintTextToAll("%N is sober.", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 is no longer drugged.", client); 

                SayText2(client, nm);
        
                FinishIt();       
        } 
}

public DiceBlind(client)
{
        PrintCenterTextAll("%N was blinded!", client);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and was blinded.", client, CurrentAction);
        
        SayText2(client, nm);    
        
        ServerCommand("sm_blind #%i 255", GetClientUserId(client));   
    
        CreateTimer(GetConVarFloat(c_Period), DiceBlindOff, client);       
}

public Action:DiceBlindOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                ServerCommand("sm_blind #%i 0", GetClientUserId(client));
        
                PrintHintTextToAll("%N was unblinded.", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 is no longer blind.", client);
                
                SayText2(client, nm); 
        
                FinishIt();
        }
}

public DiceTimebomb(client)
{
        PrintCenterTextAll("%N is a timebomb!", client);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and won a timebomb.", client, CurrentAction);
        
        SayText2(client, nm);    
        
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
        PrintCenterTextAll("%N was burned!", client);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and was burned.", client, CurrentAction); 
        
        SayText2(client, nm);   
        
        ServerCommand("sm_burn #%i %f", GetClientUserId(client), GetConVarFloat(c_Period));
        
        CreateTimer(GetConVarFloat(c_Period), DiceBurnOff, client);    

        FinishIt();          
}

public Action:DiceBurnOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                PrintHintTextToAll("%N was extinguished!", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 was extinguished.", client);

                SayText2(client, nm);

                FinishIt();
        }
}

public DiceFreeze(client)
{
        PrintCenterTextAll("%N was frozen for %s!", client, TimeMessage);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and was frozen.", client, CurrentAction); 
        
        SayText2(client, nm);   
        
        ServerCommand("sm_freeze #%i %i", GetClientUserId(client), GetConVarInt(c_Period));  
        
        CreateTimer(GetConVarFloat(c_Period), DiceFreezeOff, client);    
}

public Action:DiceFreezeOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                PrintHintTextToAll("%N was unfrozen!", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 is no longer frozen.", client);

                SayText2(client, nm);

                FinishIt();
        }
}

public DiceSlay(client)
{
        PrintCenterTextAll("%N is a loser!", client);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and was slayed!", client, CurrentAction);  

        SayText2(client, nm);

        FinishIt();

        FakeClientCommand(client, "explode\n");
}

public DiceBeacon(client)
{
        PrintCenterTextAll("%N has beacon for %s!", client, TimeMessage);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and won beacon.", client, CurrentAction);
        
        SayText2(client, nm);  
        
        ServerCommand("sm_beacon #%i", GetClientUserId(client));
        
        CreateTimer(GetConVarFloat(c_Period), DiceBeaconOff, client);  
}

public Action:DiceBeaconOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                PrintHintTextToAll("%N was unbeaconed!", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 in no longer beaconed.", client);

                SayText2(client, nm);

                ServerCommand("sm_beacon #%i", GetClientUserId(client));
        
                FinishIt();
        }
}

public DiceInstantkill(client)
{
        PrintCenterTextAll("%N has instant kills for %s!", client, TimeMessage);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and has instant kills.", client, CurrentAction);

        SayText2(client, nm);

        PlayerKills = 1;

        CreateTimer(GetConVarFloat(c_Period), DiceInstantkillOff, client);
}

public Action:DiceInstantkillOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                PrintHintTextToAll("%N no longer has instant kills.", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 no longer has instant kills.", client);
                
                SayText2(client, nm);     
        
                FinishIt();
        }
}

public DiceToxic(client)
{
        PrintCenterTextAll("%N is toxic for %s!", client, TimeMessage);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and is toxic.", client, CurrentAction);
        
        SayText2(client, nm);   
        
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
                PrintHintTextToAll("%N is no longer toxic.", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 is no longer toxic.", client);     
                
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
                new maxClients = GetClientCount();
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

                        ForcePlayerSuicide(i);
                        SendDeathEvent(PlayerUsing, i);

                        PrintHintText(i, "You were killed by %N's toxicity.", PlayerUsing);
                }
        }
}

public DiceCloak(client)
{
        PrintCenterTextAll("%N has infinite cloak for %s!", client, TimeMessage);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and won infinite cloak.", client, CurrentAction); 
        
        SayText2(client, nm); 
        
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
                PrintHintTextToAll("%N's cloak wore off.", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N's\x01 cloak wore off.", client);  
                
                SayText2(client, nm);   
                
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
        PrintCenterTextAll("%N has godmode for %s!", client, TimeMessage);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and won godmode.", client, CurrentAction);  

        SayText2(client, nm);
        
        SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
        
        CreateTimer(GetConVarFloat(c_Period), DiceGodmodeOff, client);     
}

public Action:DiceGodmodeOff(Handle:Timer, any:client)
{
        SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);

        if(pluginInUse && PlayerUsing == client)
        {
                PrintHintTextToAll("%N's godmode wore off.", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N's\x01 godmode wore off.", client);
                
                SayText2(client, nm);     
        
                FinishIt();
        }

        
}

public DiceGravity(client)
{
        PrintCenterTextAll("%N has low gravity for %s!", client, TimeMessage);

        new String:nm[255];
        PrintToChatAll("\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and won low gravity.", client, CurrentAction);

        SayText2(client, nm);

        SetEntityGravity(client, GetConVarFloat(c_Gravity));

        CreateTimer(GetConVarFloat(c_Period), DiceGravityOff, client);
}

public Action:DiceGravityOff(Handle:Timer, any:client)
{
        SetEntityGravity(client, 1.0);

        if(pluginInUse && PlayerUsing == client)
        {
                PrintHintTextToAll("%N's gravity wore off.", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N's\x01 gravity wore off.", client); 

                SayText2(client, nm);

                FinishIt();
        }    
}

public DiceCrits(client)
{
        PrintCenterTextAll("%N has crits for %s!", client, TimeMessage);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and won crits.", client, CurrentAction);

        SayText2(client, nm);

        PlayerCrits = 1;

        CreateTimer(GetConVarFloat(c_Period), DiceCritsOff, client);
}

public Action:DiceCritsOff(Handle:Timer, any:client)
{
        if(pluginInUse && PlayerUsing == client)
        {
                PrintHintTextToAll("%N's crits wore off.", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N's\x01 crits wore off.", client);

                SayText2(client, nm);
        
                PlayerCrits = 0;
        
                FinishIt();
        }
}

public DiceUber(client)
{
        PrintCenterTextAll("%N has ÜberCharge for %s!", client, TimeMessage);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and won ÜberCharge.", client, CurrentAction);

        SayText2(client, nm);

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
                if(g_TimerHandle != INVALID_HANDLE)
                {
                        KillTimer(g_TimerHandle);
                        g_TimerHandle = INVALID_HANDLE;
                }
        
                PrintHintTextToAll("%N's ÜberCharge wore off!", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N's\x01 ÜberCharge wore off.", client);

                SayText2(client, nm);
        
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
        PrintCenterTextAll("%N has noclip for %s!", client, TimeMessage);

        new String:nm[255];
        Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N\x01 rolled a \x03%d\x01 and won noclip.", client, CurrentAction);

        SayText2(client, nm);

        SetEntityMoveType(client, MOVETYPE_NOCLIP);

        if(g_TimerHandle != INVALID_HANDLE)
        {
                KillTimer(g_TimerHandle);
                g_TimerHandle = INVALID_HANDLE;
        }

        TimerCount = 0;
        g_TimerHandle = CreateTimer(1.0, NoclipRepeat, _, TIMER_REPEAT);

        CreateTimer(GetConVarFloat(c_Period), DiceNoClipOff, client);
}

public Action:DiceNoClipOff(Handle:Timer, any:client)
{
        SetEntityMoveType(client, MOVETYPE_WALK);

        if(pluginInUse && PlayerUsing == client)
        {
                PrintHintTextToAll("%N's noclip wore off!", client);

                new String:nm[255];
                Format(nm, sizeof(nm), "\x01\x04[RTD] \x03%N's\x01 noclip wore off.", client);

                SayText2(client, nm);

                FinishIt();
        }
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

RainbowRepeat(client, index)
{
        SetWeaponsColor(client);
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, colors[index][0], colors[index][1], colors[index][2], colors[index][3]);
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

stock SayText2(author_index , const String:message[] ) {
    new Handle:buffer = StartMessageAll("SayText2");
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}  

stock SayText2One( client_index , author_index , const String:message[] ) {
    new Handle:buffer = StartMessageOne("SayText2", client_index);
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}  

stock GetLiteralString(const String:cmd[],String:buffer[],maxlength)
{
    strcopy(buffer,strlen(cmd)+1,cmd);
    ReplaceString(buffer,maxlength,"\"","");
    TrimString(buffer);
}
