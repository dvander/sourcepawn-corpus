#pragma semicolon 1

#include <sdkhooks>
#include <sdktools_functions>

#define PLUGIN_VERSION "3.41_fix"

#define EF_NODRAW 32

//=============HERE ADD Your Weapon===========
static const String:WEAPONS[][][] =
{	//	classname				model path
	{"weapon_goldenak47",	"models/zerogamer_v2/weapons/v_goldak47.mdl"},
	{"weapon_X",	"models/X.mdl"}
};

new	bool:bLate,
	Handle:hWeapons,
	bool:SpawnCheck[MAXPLAYERS+1],
	iVM[MAXPLAYERS+1][2],
	bool:IsCustom[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "[ZR] Extra Items ViewModel Fixer",
	author = "Grey83",
	description = "Fixes the Prediction of the Viewmodel on Custom Weapons",
	version = PLUGIN_VERSION,
	url = ".::T.Me/MahdiKhebre::."
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	bLate = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	hWeapons = CreateTrie();
}

public OnMapStart()
{
	ClearTrie(hWeapons);
	new i, j;
	for(; i < sizeof(WEAPONS); i++)
	{
		if((j = PrecacheModel(WEAPONS[i][1])) > 0) SetTrieValue(hWeapons, WEAPONS[i][0], j);
	}

	static bool:hooked;
	if(hooked == !GetTrieSize(hWeapons))
	{
		if((hooked ^= true))
		{
			HookEvent("player_death", Event_Player);
			HookEvent("player_spawn", Event_Player);
		}
		else
		{
			UnhookEvent("player_death", Event_Player);
			UnhookEvent("player_spawn", Event_Player);
		}
	}

	if(!bLate || !GetTrieSize(hWeapons))
		return;

	bLate = false;
	for (i = 0; ++i <= MaxClients;) if (IsClientInGame(i)) 
	{
		SDKHook(i, SDKHook_PostThinkPost, OnPostThinkPost);

		//find both of the clients viewmodels
		iVM[i][0] = GetEntPropEnt(i, Prop_Send, "m_hViewModel");

		j = -1;
		while ((j = FindEntityByClassname(j, "predicted_viewmodel")) != -1)
		{
			if (GetEntPropEnt(j, Prop_Send, "m_hOwner") == i && GetEntProp(j, Prop_Send, "m_nViewModelIndex") == 1)
			{
				iVM[i][1] = j;
				break;
			}
		}
	}
}

public OnClientPutInServer(client)
{
	if(GetTrieSize(hWeapons)) SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public OnPostThinkPost(client)
{
	//handle spectators
	if (!IsPlayerAlive(client))
	{
		return;
	}

	static OldWeapon[MAXPLAYERS + 1], OldSequence[MAXPLAYERS + 1], Float:OldCycle[MAXPLAYERS + 1];

	new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new Sequence = GetEntProp(iVM[client][0], Prop_Send, "m_nSequence");
	new Float:Cycle = GetEntPropFloat(iVM[client][0], Prop_Data, "m_flCycle");

	if (!IsValidEdict(WeaponIndex))
	{
		HideViewModel(iVM[client][1]);

		IsCustom[client] = false;

		OldWeapon[client] = WeaponIndex;
		OldSequence[client] = Sequence;
		OldCycle[client] = Cycle;

		return;
	}

	static String:classname[30];
	//just stuck the weapon switching in here as well instead of a separate hook
	if (WeaponIndex != OldWeapon[client])
	{
		GetEdictClassname(WeaponIndex, classname, sizeof(classname));
		new mdl_id;
		if (GetTrieValue(hWeapons, classname, mdl_id))
		{
			//hide viewmodel
			HideViewModel(iVM[client][0]);
			//unhide unused viewmodel
			ShowViewModel(iVM[client][1]);
			//set model and copy over props from viewmodel to used viewmodel
			SetEntProp(iVM[client][1], Prop_Send, "m_nModelIndex", mdl_id);

			SetEntPropEnt(iVM[client][1], Prop_Send, "m_hWeapon", GetEntPropEnt(iVM[client][0], Prop_Send, "m_hWeapon"));

			SetEntProp(iVM[client][1], Prop_Send, "m_nSequence", GetEntProp(iVM[client][0], Prop_Send, "m_nSequence"));
			SetEntPropFloat(iVM[client][1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(iVM[client][0], Prop_Send, "m_flPlaybackRate"));

			IsCustom[client] = true;
		}
		else
		{
			//hide unused viewmodel if the current weapon isn't using it
			HideViewModel(iVM[client][1]);

			IsCustom[client] = false;
		}
	}
	else if (IsCustom[client])
	{
		//copy the animation stuff from the viewmodel to the used one every frame
		SetEntProp(iVM[client][1], Prop_Send, "m_nSequence", GetEntProp(iVM[client][0], Prop_Send, "m_nSequence"));
		SetEntPropFloat(iVM[client][1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(iVM[client][0], Prop_Send, "m_flPlaybackRate"));

		if (Cycle < OldCycle[client] && Sequence == OldSequence[client])
		{
			SetEntProp(iVM[client][1], Prop_Send, "m_nSequence", 0);
		}
	}

	//hide viewmodel a frame after spawning
	if (SpawnCheck[client])
	{
		SpawnCheck[client] = false;
		if (IsCustom[client]) HideViewModel(iVM[client][0]);
	}

	OldWeapon[client] = WeaponIndex;
	OldSequence[client] = Sequence;
	OldCycle[client] = Cycle;
}

public Event_Player(Handle:event, const String:name[], bool:dontBroadcast)
{
	//use to delay hiding viewmodel a frame or it won't work
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client)
		return;

	//hide viewmodel on death
	if(name[7] == 'd')
		HideViewModel(iVM[client][1]);
	//when a player repsawns at round start after surviving previous round the viewmodel is unhidden
	else SpawnCheck[client] = true;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (GetTrieSize(hWeapons) && !strcmp(classname, "predicted_viewmodel", false))
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
}

//find both of the clients viewmodels
public OnEntitySpawned(entity)
{
	new Owner = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
	if (0 < Owner <= MaxClients)
	{
		int id = GetEntProp(entity, Prop_Send, "m_nViewModelIndex");
		switch(id)
		{
			case 0: iVM[Owner][0] = entity;
			case 1: iVM[Owner][1] = entity;
		}
	}
}

HideViewModel(entity)
{
	SetEntProp(entity, Prop_Send, "m_fEffects", GetEntProp(entity, Prop_Send, "m_fEffects")|EF_NODRAW);
}

ShowViewModel(entity)
{
	SetEntProp(entity, Prop_Send, "m_fEffects", GetEntProp(entity, Prop_Send, "m_fEffects")&~EF_NODRAW);
}