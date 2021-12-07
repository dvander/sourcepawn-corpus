#pragma semicolon 1
#include <sourcemod>
#include <dhooks>

#define VERSION 		"0.0.1"

new Handle:hShootPosition;
new Handle:hFwd;

public Plugin:myinfo = {
	name 		= "tWeaponShootPosition",
	author 		= "Thrawn",
	description = "Hooks all players Weapon_ShootPosition and provides a global forward for other plugins",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tweaponshootposition_version", VERSION, "tWeaponShootPosition", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	new Handle:temp = LoadGameConfigFile("tweaponshootposition.tf");
	if(temp == INVALID_HANDLE) {
		SetFailState("Gamedata not found");
	}

	new offset = GameConfGetOffset(temp, "CBasePlayer::Weapon_ShootPosition()");
	hShootPosition = DHookCreate(offset, HookType_Entity, ReturnType_Vector, ThisPointer_CBaseEntity, Weapon_ShootPosition);

	CloseHandle(temp);

	hFwd = CreateGlobalForward("OnClientWeaponShootPosition", ET_Ignore, Param_Cell, Param_Array);

	/* Account for late loading */
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			HookPlayer(i);
		}
	}
}

public OnClientPutInServer(client) {
	HookPlayer(client);
}

HookPlayer(client) {
    DHookEntity(hShootPosition, true, client, RemovalCB);
}

//bool CBasePlayer::Weapon_ShootPosition()
public MRESReturn:Weapon_ShootPosition(this, Handle:hReturn) {
	new Float:fShootPos[3];
	DHookGetReturnVector(hReturn, fShootPos);

	Call_StartForward(hFwd);
	Call_PushCell(this);
	Call_PushArray(fShootPos, 3);
	Call_Finish();

	return MRES_Ignored;
}


public RemovalCB(hookid) {}