#pragma semicolon 1

#include <sourcemod>
#include <tf2>

public Plugin:myinfo = {
	name		= "[TF2] Disable Waiting For Players",
	author		= "Dr. McKay",
	description	= "Disables TF2's waiting for players period",
	version		= "1.0.0",
	url		= "http://www.doctormckay.com"
};

new Handle:mp_waitingforplayers_cancel;

public APLRes:AskPluginLoad2(Handle:myself, bool:lateLoad, String:error[], err_max) {
	mp_waitingforplayers_cancel = FindConVar("mp_waitingforplayers_cancel");
	if(mp_waitingforplayers_cancel) {
		strcopy(error, err_max, "Couldn't find cvar mp_waitingforplayers_cancel");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public TF2_OnWaitingForPlayersStart() {
	CreateTimer(1.0, Timer_DisableWaiting);
}

public Action:Timer_DisableWaiting(Handle:timer) {
	SetConVarInt(mp_waitingforplayers_cancel, 1);
}