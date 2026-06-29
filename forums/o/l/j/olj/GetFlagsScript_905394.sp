#define PLUGIN_VERSION "1.0"
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new const String:s_entMoveType[][] = { "example", "example2"}; //MOVE TYPES HERE, too lazy to write them, check entity_prop_stocks.inc

new const String:s_entFlags[][] = { 
"onGround",		// At rest / on the ground
"ducking",			//FL_DUCKING			(1 << 1)	// Player flag -- Player is fully crouched
"jumpingofwater",				//FL_WATERJUMP			(1 << 2)	// player jumping out of water
"ontrain",			//FL_ONTRAIN			(1 << 3)	// Player is _controlling_ a train, so movement commands should be ignored on client during prediction.
"intrain",				//FL_INRAIN			(1 << 4)	// Indicates the entity is standing in rain
"frozen",				//FL_FROZEN			(1 << 5)	// Player is frozen for 3rd person camera
"atcontrols",				//FL_ATCONTROLS			(1 << 6)	// Player can't move, but keeps key inputs for controlling another entity
"isPlayer",				//FL_CLIENT			(1 << 7)	// Is a player
"fakeClient",				//FL_FAKECLIENT			(1 << 8)	// Fake client, simulated server side; don't send network messages to them
"inWater",				//FL_INWATER			(1 << 9)	// In water
"fly",				//FL_FLY				(1 << 10)	// Changes the SV_Movestep() behavior to not need to be on ground
"swim",				//FL_SWIM				(1 << 11)	// Changes the SV_Movestep() behavior to not need to be on ground (but stay in water)
"wtf is that for?",				//FL_CONVEYOR			(1 << 12)
"isNPC",				//FL_NPC				(1 << 13)
"god",				//FL_GODMODE			(1 << 14)
"notarget",				//FL_NOTARGET			(1 << 15)
"aimtarget",				//FL_AIMTARGET			(1 << 16)	// set if the crosshair needs to aim onto the entity
"whatever",				//FL_PARTIALGROUND		(1 << 17)	// not all corners are valid
"static",				//FL_STATICPROP			(1 << 18)	// Eetsa static prop!		
"graphed",				//FL_GRAPHED			(1 << 19)	// worldgraph has this ent listed as something that blocks a connection
"grenade",				//FL_GRENADE			(1 << 20)
"step",				//FL_STEPMOVEMENT			(1 << 21)	// Changes the SV_Movestep() behavior to not do any processing
"notouch",				//FL_DONTTOUCH			(1 << 22)	// Doesn't generate touch functions, generates Untouch() for anything it was touching when this flag was set
"velocity",				//FL_BASEVELOCITY			(1 << 23)	// Base velocity has been applied this frame (used to convert base velocity into momentum)
"world",				//FL_WORLDBRUSH			(1 << 24)	// Not moveable/removeable brush entity (really part of the world, but represented as an entity for transparency or something)
"object",				//FL_OBJECT			(1 << 25)	// Terrible name. This is an object that NPCs should see. Missiles, for example.
"killme",				//FL_KILLME			(1 << 26)	// This entity is marked for death -- will be freed by game DLL
"burning",				//FL_ONFIRE			(1 << 27)	// You know...
"dissolving",				//FL_DISSOLVING			(1 << 28)	// We're dissolving!
"ragdoll",				//FL_TRANSRAGDOLL			(1 << 29)	// In the process of turning into a client side ragdoll.
"unblockable"				//FL_UNBLOCKABLE_BY_PLAYER	(1 << 30)	// pusher that can't be blocked by the player
}	;

public Plugin:myinfo = 
{
	name = "Getting some flags",
	author = "whatever",
	description = "whatever",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	HookEvent("tongue_grab", TongueGrab_Event, EventHookMode_Post);
}

public TongueGrab_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
PrintEntityFlags(attacker); //	This is for information purposes only, so we know what flags present
PrintMoveFlags(attacker);	//	This is for information purposes only, so we know what flags present
/* POSSIBLE DECISION */
	new flags = GetEntityFlags(attacker);
	//if has some flags (dont know how to check properly, not good at bitstrings), anyway its NOT NECESSARY if we just want to remove some flags
	SetEntProp(attacker, Prop_Send, "m_fFlags", flags & ~FL_FROZEN); //removing frozen flag
	SetEntityMoveType(attacker, MOVETYPE_CUSTOM); // we allow smoker to move as he will (in case he cant)
}
PrintEntityFlags(EntityIndex) { 
    decl String:buffer[256] ;
    new flags = GetEntityFlags(EntityIndex) ;
    if(flags == INVALID_FCVAR_FLAGS) {
        return ;       //no such command 
    } 
    else if(!flags) { 
        strcopy(buffer,sizeof buffer,"none") ;
    } 
    else { 
        new len ;
        for(new i = 0; i < sizeof s_entFlags; i++) { 
            if(flags & (1<<i)) { 
                len += FormatEx(buffer[len],sizeof buffer - len,"%s, ",s_entFlags[i]) ;
            } 
        } 
        if(len) { 
            buffer[len - 2] = 0 ;
        } 
        else { 
            strcopy(buffer,sizeof buffer,"none") ;
        } 
    } 
    PrintToChatAll("%s has following flags: %s", EntityIndex, buffer); 
}  

 
PrintMoveFlags(EntityIndex) {  // Wont work because tag mismatch on 95, anyway this function isnt that much needed, compared to entitys flags
    decl String:buffer[256] ;
    new flags = GetEntityMoveType(EntityIndex) ;
    if(flags == INVALID_FCVAR_FLAGS) { 
        return;    //no such command 
    }
    else if(!flags) { 
        strcopy(buffer,sizeof buffer,"none") ;
    } 
    else { 
        new len ;
        for(new i = 0; i < sizeof s_entMoveType; i++) { 
            if(flags & (1<<i)) { 
                len += FormatEx(buffer[len],sizeof buffer - len,"%s, ",s_entMoveType[i]) ;
            } 
        } 
        if(len) { 
            buffer[len - 2] = 0 ;
        } 
        else { 
            strcopy(buffer,sizeof buffer,"none") ;
        } 
    } 
    PrintToChatAll("%s has following move flags: %s", EntityIndex, buffer);
}



