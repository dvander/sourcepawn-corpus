#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
    name = "Prevent IDLE glitch",
    author = "khan",
    description = "Stop players from using idle to cheat",
    version = "1.0"
};

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define ZC_HUNTER               3
#define ZC_CHARGER              6
#define ZC_TANK      		    8


enum ISSUE
{
    TankHit,
    Defib,
    Molotov,
	HunterHit,
	ChargerHit,
};

new iNextValidIDLE[MAXPLAYERS];                // Next game instant to allow player to go idle
new ISSUE:iReason[MAXPLAYERS];                // Reason for not allow idle

public OnPluginStart()
{
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
    HookEvent("defibrillator_used", Event_DefibUsed, EventHookMode_Pre);
    HookEvent("molotov_thrown", Event_Molotov, EventHookMode_Pre);
    
        
    AddCommandListener(GoAwayFromKeyboard, "go_away_from_keyboard");
}

public Action:GoAwayFromKeyboard(client, const String:command[], argc)
{
    if (!AllowIDLE(client))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action:Event_DefibUsed(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    new subject = GetClientOfUserId(GetEventInt(hEvent, "subject"));
    
    iNextValidIDLE[subject] = GetTime() + 10; // Disable IDLE for 5 seconds when defibbed
    iReason[subject] = ISSUE:Defib;
}

public Action:Event_Molotov(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    new subject = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    
    iNextValidIDLE[subject] = GetTime() + 15; // Disable IDLE for 15 seconds when Throw MOLOTOV
    iReason[subject] = ISSUE:Molotov;
}

public Action:Event_PlayerHurt(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    new player = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

    if (!IS_VALID_INFECTED(attacker)) return Plugin_Continue;
    
    new zClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");
    switch (zClass)
    {
        case ZC_TANK:
        {
            iNextValidIDLE[player] = GetTime() + 10;  // Disable idle for 3 seconds if hit by tank
            iReason[player] = ISSUE:TankHit;
        }
        case ZC_HUNTER:
        {
            iNextValidIDLE[player] = GetTime() + 10;  // Disable idle for 3 seconds if hit by tank
            iReason[player] = ISSUE:HunterHit;
        }
        case ZC_CHARGER:
        {
            iNextValidIDLE[player] = GetTime() + 10;  // Disable idle for 3 seconds if hit by tank
            iReason[player] = ISSUE:ChargerHit;
        }		
    }
    
    return Plugin_Continue;
}

bool:AllowIDLE(client)
{
    // Are they boomed? Don't allow player to go idle for 13 seconds after boomed - about the time when they can see clearly again
    new Float:vomitStart = GetEntPropFloat(client, Prop_Send, "m_vomitStart")
    if ( (vomitStart + 13) > GetGameTime()) 
    {
        //PrintToChat(client, "\x05Not allowed to go idle when boomed.");
        return false;
    }
    
    // Are they reloading?
    new weapon = GetPlayerWeaponSlot(client, 0);
    if (weapon != -1)
    {
        if( GetEntProp(weapon, Prop_Data, "m_bInReload") )
        {
            //PrintToChat(client, "\x05Not allowed to go idle when reloading.");
            return false;
        }
    }
    
    // Are they being charged?
    new m_pummelAttacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker"); //Charger
    if (m_pummelAttacker != -1)
    {
        //PrintToChat(client, "\x05Not allowed to go idle.");
        return false;
    }
	
	    // Are they being pounced?
    new m_pounceAttacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker"); //Hunter
    if (m_pounceAttacker != -1)
    {
        //PrintToChat(client, "\x05Not allowed to go idle.");
        return false;
    }
	
	    // Are they being pounced?
    new m_carryAttacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker"); //Jockey
    if (m_carryAttacker != -1)
    {
        //PrintToChat(client, "\x05Not allowed to go idle.");
        return false;
    }

	    // Are they being pounced?
    new m_jockeyAttacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker"); //Jockey
    if (m_jockeyAttacker != -1)
    {
        //PrintToChat(client, "\x05Not allowed to go idle.");
        return false;
    }

	    // Are they being pounced?
    new m_isHangingFromTongue = GetEntPropEnt(client, Prop_Send, "m_isHangingFromTongue"); //Smoker
    if (m_isHangingFromTongue != -1)
    {
        //PrintToChat(client, "\x05Not allowed to go idle.");
        return false;
    }

	    // Are they being pounced?
    new m_reachedTongueOwner = GetEntPropEnt(client, Prop_Send, "m_reachedTongueOwner"); //Smoker
    if (m_reachedTongueOwner != -1)
    {
        //PrintToChat(client, "\x05Not allowed to go idle.");
        return false;
    }
	
	    // Are they being pounced?
    new m_iCurrentUseAction = GetEntPropEnt(client, Prop_Send, "m_iCurrentUseAction"); //Use Action
    if (m_iCurrentUseAction != -1)
    {
        //PrintToChat(client, "\x05Not allowed to go idle.");
        return false;
    }	

	
	
	
    
    // Are they stumbling?
    new Float:vec[3];
    GetEntPropVector(client, Prop_Send, "m_staggerStart", vec);
    if (vec[0] != 0.000000 || vec[1] != 0.000000 || vec[2] != 0.000000)
    {
        //PrintToChat(client, "\x05Not allowed to go idle when stumbled");
        return false;
    }
    
    // Verify that they didn't just get hit by a tank or defibbed
    if (iNextValidIDLE[client] > GetTime())
    {
        if (iReason[client] == ISSUE:TankHit)
        {
            //PrintToChat(client, "\x05Not allowed to go idle after tank hit.");
        }
        else if (iReason[client] == ISSUE:Defib)
        {
            //PrintToChat(client, "\x05Not allowed to go idle after being defibbed.");
        }
        else if (iReason[client] == ISSUE:Molotov)
        {
            //PrintToChat(client, "\x05Not allowed to go idle.");
        }
        else
        {
            //PrintToChat(client, "\x05Not allowed to go idle.");
        }
        return false;
    }
    
    // Allow idle
    return true;
}