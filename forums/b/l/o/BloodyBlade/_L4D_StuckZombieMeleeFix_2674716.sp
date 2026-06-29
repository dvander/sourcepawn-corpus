#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#define DEBUG 0

bool MeleeDelay[MAXPLAYERS + 1] = {false, ...};
float clientpos[3], entpos[3], Pos[3], oldpos[3], newpos[3], mins[3], maxs[3];
int entid = 0, zombieid = 0, zombiehealth = 0, zombiehealthmax = 0;
char entclass[96];

public Plugin myinfo = 
{
	name = "Stuck Zombie Melee Fix",
	author = "AtomicStryker",
	description = "Smash nonstaggering Zombies",
	version = "1.0.4",
	url = "http://forums.alliedmods.net/showthread.php?p=932416"
}

public void OnPluginStart()
{
	HookEvent("entity_shoved", Event_EntShoved);
	AddNormalSoundHook(view_as<NormalSHook>(HookSound_Callback));
}

public Action HookSound_Callback(int clients[64], int &numClients, char StrSample[PLATFORM_MAX_PATH], int &Entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if (StrContains(StrSample, "Swish", false) != -1 && Entity <= MAXPLAYERS && !MeleeDelay[Entity])
	{
    	MeleeDelay[Entity] = true;
    	CreateTimer(1.0, ResetMeleeDelay, Entity);

        #if DEBUG
    	PrintToChatAll("Melee detected via soundhook.");
        #endif

    	entid = GetClientAimTarget(Entity, false);
    	if (entid > 0)
    	{
        	GetEntityNetClass(entid, entclass, sizeof(entclass));
        	if (StrEqual(entclass, "Infected"))
        	{
            	GetEntityAbsOrigin(entid, entpos);
            	GetClientEyePosition(Entity, clientpos);
            	if (GetVectorDistance(clientpos, entpos) > 50)
            	{
                    #if DEBUG
                	PrintToChatAll("Youre meleeing and looking at Zombie id #%i", entid);
                    #endif

                	Event newEvent = CreateEvent("entity_shoved");
                	if(newEvent != null)
                	{
                		newEvent.SetInt("attacker", Entity);
                		newEvent.SetInt("entityid", entid);
                		newEvent.Fire(true);
                	}
            	}
        	}
    	}
	}
	return Plugin_Continue;
}

Action ResetMeleeDelay(Handle timer, any client)
{
	MeleeDelay[client] = false;
	return Plugin_Stop;
}

void Event_EntShoved(Event event, const char[] name, bool dontBroadcast)
{
	entid = event.GetInt("entityid");
	GetEntityNetClass(entid, entclass, sizeof(entclass));
	if (StrEqual(entclass, "Infected"))
	{
    	DataPack hPack;
    	CreateDataTimer(0.5, CheckForMovement, hPack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
    	hPack.WriteCell(entid);
    	GetEntityAbsOrigin(entid, Pos);
    	hPack.WriteFloat(Pos[0]);
    	hPack.WriteFloat(Pos[1]);
    	hPack.WriteFloat(Pos[2]);

        #if DEBUG
    	PrintToChatAll("Meleed Zombie detected.");
        #endif
	}
}

Action CheckForMovement(Handle timer, DataPack hDataPack)
{
	hDataPack.Reset();

	zombieid = hDataPack.ReadCell();
	if (IsValidEntity(zombieid))
	{
    	GetEntityNetClass(zombieid, entclass, sizeof(entclass));
    	if (StrEqual(entclass, "Infected"))
    	{
        	oldpos[0] = hDataPack.ReadFloat();
        	oldpos[1] = hDataPack.ReadFloat();
        	oldpos[2] = hDataPack.ReadFloat();

        	GetEntityAbsOrigin(zombieid, newpos);
        	if (GetVectorDistance(oldpos, newpos) < 5)
        	{
                #if DEBUG
            	PrintToChatAll("Stuck meleed Zombie detected.");
                #endif

            	zombiehealth = GetEntProp(zombieid, Prop_Data, "m_iHealth");
            	zombiehealthmax = FindConVar("z_health").IntValue;

            	if (zombiehealth - (zombiehealthmax / 2) <= 0)
            	{
            		AcceptEntityInput(zombieid, "BecomeRagdoll");
            	    #if DEBUG
            		PrintToChatAll("Slayed Stuck Zombie.");
            	    #endif
            	}
            	else
            	{
            		SetEntProp(zombieid, Prop_Data, "m_iHealth", zombiehealth - (zombiehealthmax / 2));
            	}
        	}
    	}
	}
	return Plugin_Stop;
}

void GetEntityAbsOrigin(int entity, float origin[3])
{
	GetEntPropVector(entity,Prop_Send,"m_vecOrigin", origin);
	GetEntPropVector(entity,Prop_Send,"m_vecMins", mins);
	GetEntPropVector(entity,Prop_Send,"m_vecMaxs", maxs);
	origin[0] += (mins[0] + maxs[0]) * 0.5;
	origin[1] += (mins[1] + maxs[1]) * 0.5;
	origin[2] += (mins[2] + maxs[2]) * 0.5;
}
