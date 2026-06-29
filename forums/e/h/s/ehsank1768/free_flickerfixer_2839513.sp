#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "3.41"








//=============HERE ADD Your Weapon===========
new ModelGoldenAK47 = -1;
new ModelName2 = -1;
new ModelName3 = -1;









#define EF_NODRAW 32

new bool:SpawnCheck[MAXPLAYERS+1];
new ClientVM[MAXPLAYERS+1][2];
new bool:IsCustom[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "[ZR] Extra Items ViewModel Fixer",
	author = "Khebre",
	description = "Fixes the Prediction of the Viewmodel on Custom Weapons",
	version = PLUGIN_VERSION,
	url = ".::T.Me/MahdiKhebre::."
};

public OnPluginStart()
{
//=============HERE ATTACH THE Name to Your Weapon.mdl file===========
ModelGoldenAK47 = PrecacheModel("models/zerogamer_v2/weapons/v_goldak47.mdl");
ModelName2 = PrecacheModel("models/zerogamer_v2/weapons/v_gunname2.mdl");
ModelName3 = PrecacheModel("models/zerogamer_v2/weapons/v_gunname3.mdl");

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);


    
	for (new client = 1; client <= MaxClients; client++) 
	{ 
		if (IsClientInGame(client)) 
        	{
            		SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
            
            		//find both of the clients viewmodels
            		ClientVM[client][0] = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
            
            		new PVM = -1;
            		while ((PVM = FindEntityByClassname(PVM, "predicted_viewmodel")) != -1)
            		{
                		if (GetEntPropEnt(PVM, Prop_Send, "m_hOwner") == client)
                		{
                    			if (GetEntProp(PVM, Prop_Send, "m_nViewModelIndex") == 1)
                    			{
                        			ClientVM[client][1] = PVM;
                        			break;
                    			}
                		}
            		}
        	} 
    	}
}

// ====================================================================================================================================================
// ====================================================================================================================================================
// ====================================================================================================================================================
// ====================================================================================================================================================

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

/// agregados


public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public OnEntityCreated(entity, const String:classname[])
{
    if (StrEqual(classname, "predicted_viewmodel", false))
    {
        SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
    }
}

//find both of the clients viewmodels
public OnEntitySpawned(entity)
{
    new Owner = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
    if ((Owner > 0) && (Owner <= MaxClients))
    {
        if (GetEntProp(entity, Prop_Send, "m_nViewModelIndex") == 0)
        {
            ClientVM[Owner][0] = entity;
        }
        else if (GetEntProp(entity, Prop_Send, "m_nViewModelIndex") == 1)
        {
            ClientVM[Owner][1] = entity;
        }
    }
}

public OnPostThinkPost(client)
{
    static OldWeapon[MAXPLAYERS + 1];
    static OldSequence[MAXPLAYERS + 1];
    static Float:OldCycle[MAXPLAYERS + 1];

    decl String:ClassName[30];
    new WeaponIndex;

    //handle spectators
    if (!IsPlayerAlive(client))
    {
        return;
    }

    WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    new Sequence = GetEntProp(ClientVM[client][0], Prop_Send, "m_nSequence");
    new Float:Cycle = GetEntPropFloat(ClientVM[client][0], Prop_Data, "m_flCycle");

    if (!IsValidEdict(WeaponIndex))
    {
        new EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
        EntEffects |= EF_NODRAW;
        SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);

        IsCustom[client] = false;

        OldWeapon[client] = WeaponIndex;
        OldSequence[client] = Sequence;
        OldCycle[client] = Cycle;

        return;
    }

    //just stuck the weapon switching in here as well instead of a separate hook
    if (WeaponIndex != OldWeapon[client])
    {
	// ================================================================Add the Weapon Class here first====================================================================================
        GetEdictClassname(WeaponIndex, ClassName, sizeof(ClassName));
        if (StrEqual("weapon_goldenak47", ClassName, false) || StrEqual("weapon_name2", ClassName, false) || StrEqual("weapon_name3", ClassName, false))
        {
            //hide viewmodel
            new EntEffects = GetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects");
            EntEffects |= EF_NODRAW;
            SetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects", EntEffects);
            //unhide unused viewmodel
            EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
            EntEffects &= ~EF_NODRAW;
            SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);

// ====================================================================================================================================================
// =============================================Now Down here Add a [else if] so the plugin assigns the model to the weapon_class======================
// ====================================================================================================================================================
            //set model and copy over props from viewmodel to used viewmodel
            if (StrEqual("weapon_goldenak47", ClassName, false))
            {
		        SetEntProp(ClientVM[client][1], Prop_Send, "m_nModelIndex", ModelGoldenAK47);
			}
			else if (StrEqual("weapon_gunname2", ClassName, false))
            {
                SetEntProp(ClientVM[client][1], Prop_Send, "m_nModelIndex", ModelName2);
            }
			else if (StrEqual("weapon_gunname3", ClassName, false))
            {
                SetEntProp(ClientVM[client][1], Prop_Send, "m_nModelIndex", ModelName3);
            }
// ====================================================================================================================================================
// ====================================================================================================================================================
            SetEntPropEnt(ClientVM[client][1], Prop_Send, "m_hWeapon", GetEntPropEnt(ClientVM[client][0], Prop_Send, "m_hWeapon"));

            SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", GetEntProp(ClientVM[client][0], Prop_Send, "m_nSequence"));
            SetEntPropFloat(ClientVM[client][1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(ClientVM[client][0], Prop_Send, "m_flPlaybackRate"));

            IsCustom[client] = true;
        }
        else
        {
            //hide unused viewmodel if the current weapon isn't using it
            new EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
            EntEffects |= EF_NODRAW;
            SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);

            IsCustom[client] = false;
        }
    }
    else
    {
        if (IsCustom[client])
        {
            //copy the animation stuff from the viewmodel to the used one every frame
            SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", GetEntProp(ClientVM[client][0], Prop_Send, "m_nSequence"));
            SetEntPropFloat(ClientVM[client][1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(ClientVM[client][0], Prop_Send, "m_flPlaybackRate"));

            if ((Cycle < OldCycle[client]) && (Sequence == OldSequence[client]))
            {
                SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", 0);
            }
        }
    }
    //hide viewmodel a frame after spawning
    if (SpawnCheck[client])
    {
        SpawnCheck[client] = false;
        if (IsCustom[client])
        {
            new EntEffects = GetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects");
            EntEffects |= EF_NODRAW;
            SetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects", EntEffects);
        }
    }
    
    OldWeapon[client] = WeaponIndex;
    OldSequence[client] = Sequence;
    OldCycle[client] = Cycle;
}


//hide viewmodel on death
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new UserId = GetEventInt(event, "userid");
    new client = GetClientOfUserId(UserId);
    
    new EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
    EntEffects |= EF_NODRAW;
    SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
}

//when a player repsawns at round start after surviving previous round the viewmodel is unhidden
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new UserId = GetEventInt(event, "userid");
    new client = GetClientOfUserId(UserId);
    
    //use to delay hiding viewmodel a frame or it won't work
    SpawnCheck[client] = true;
}   