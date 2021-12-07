#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
//#include <setname>

#define PLUGIN_VERSION "b1.2"

new Handle:HideAttacker = INVALID_HANDLE;

new Handle:AttackerName = INVALID_HANDLE;

new Handle:names = INVALID_HANDLE;

new namesdefault;

public Plugin:myinfo =
{
	name = "SM Hide Attacker",
	author = "Franc1sco Steam: franug",
	description = "Hide Ts attackers",
	version = PLUGIN_VERSION,
	url = "www.servers-cfg.foroactivo.com"
};

public OnPluginStart()
{

	CreateConVar("sm_hideattacker_version", PLUGIN_VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HideAttacker = CreateConVar("sm_hideattacker", "1", "hide Ts attackers");

	AttackerName = CreateConVar("sm_hideattacker_name", "A terrorist", "the fake name");
	
	HookEvent("player_death", event_Death, EventHookMode_Pre);

	names = FindConVar("sv_namechange_cooldown_seconds");

	namesdefault = GetConVarInt(names);

}


public Action:event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetConVarInt(HideAttacker))
    {
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

        if (!attacker)
            return Plugin_Continue;

        if (GetClientTeam(attacker) != 2)  // only hide Ts attacker name
            return Plugin_Continue;

	SetConVarInt(names, 0, false, false);

	decl String:nombre[32];
	GetClientName(attacker, nombre, sizeof(nombre));


	decl String:nuevonombre[32];
	GetConVarString(AttackerName, nuevonombre, sizeof(nuevonombre));

	CS_SetClientName(attacker, nuevonombre);

	new Handle:pack;
        CreateDataTimer(0.2, Default, pack);
        WritePackCell(pack, attacker);
        WritePackString(pack, nombre);

    }

    return Plugin_Continue;
}


public Action:Default(Handle:timer, Handle:pack)
{

   new attacker;
   decl String:nombre2[32];



   ResetPack(pack);
   attacker = ReadPackCell(pack);
   ReadPackString(pack, nombre2, sizeof(nombre2));

   if (IsClientInGame(attacker))
   {
	CS_SetClientName(attacker, nombre2);
	SetConVarInt(names, namesdefault, false, false);
   }
}



stock CS_SetClientName(client, const String:name[], bool:silent=false)
{
    decl String:oldname[MAX_NAME_LENGTH];
    GetClientName(client, oldname, sizeof(oldname));

    SetClientInfo(client, "name", name);
    SetEntPropString(client, Prop_Data, "m_szNetname", name);

    new Handle:event = CreateEvent("player_changename");

    if (event != INVALID_HANDLE)
    {
        SetEventInt(event, "userid", GetClientUserId(client));
        SetEventString(event, "oldname", oldname);
        SetEventString(event, "newname", name);
        FireEvent(event);
    }

    if (silent)
        return;
    
    new Handle:msg = StartMessageAll("SayText2");

    if (msg != INVALID_HANDLE)
    {
        BfWriteByte(msg, client);
        BfWriteByte(msg, true);
        BfWriteString(msg, "Cstrike_Name_Change");
        BfWriteString(msg, oldname);
        BfWriteString(msg, name);
        EndMessage();
    }
}