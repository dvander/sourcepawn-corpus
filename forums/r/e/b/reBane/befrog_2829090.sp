#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <tf2>
#include <tf2utils>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "24w41a"

public Plugin myinfo = {
	name = "[TF2] BeFrog",
	author = "reBane",
	description = "Turn players into frogs",
	version = PLUGIN_VERSION,
	url = "N/A"
};
void SetupVersionConVar(const char[] cvar_name, const char[] cvar_desc)
{
	ConVar version = CreateConVar(cvar_name, PLUGIN_VERSION, cvar_desc, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	version.AddChangeHook(LockVersionConVar);
	version.SetString(PLUGIN_VERSION);
}
void LockVersionConVar(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!StrEqual(newValue, PLUGIN_VERSION)) {
		convar.SetString(PLUGIN_VERSION);
	}
}

bool bIsFrog[MAXPLAYERS+1];
bool bWasOnGround[MAXPLAYERS+1];
float flJumpTimer[MAXPLAYERS+1];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_befrog", Command_Frog, ADMFLAG_KICK, "Usage: /befrog <target> [0/1] - Reject humanity, become frog");
	RegAdminCmd("sm_frogme", Command_FrogMe, ADMFLAG_KICK, "Reject humanity, become frog");
	HookEvent("post_inventory_application", OnClientInventoryRegenerate);
	SetupVersionConVar("sm_befrog_version", "BeFrog Plugin Version");
}

public void OnClientConnected(int client)
{
	bIsFrog[client] = false;
	bWasOnGround[client] = false;
	flJumpTimer[client] = 0.0;
}

public void OnMapStart()
{
	for (int client = 0; client <= MaxClients; client ++) {
		OnClientConnected(client);
	}
	PrecacheModel("models/props_2fort/frog.mdl");
}

Action Command_FrogMe(int client, int args)
{
	if (IsClientInGame(client) && GetClientTeam(client)>=2) {
		bool turnFrog = !bIsFrog[client];
		if (!turnFrog) {
			BeFrog(client, false);
			ReplyToCommand(client, "[SM] Return to monkeh!");
		} else if (IsPlayerAlive(client)) {
			BeFrog(client, true);
			ReplyToCommand(client, "[SM] Return to froge!");
		}
	}
	return Plugin_Handled;
}

Action Command_Frog(int client, int args)
{
	char buffer[64];
	char on = 0;
	if (GetCmdArgs()==0) {
		ReplyToCommand(client, "Usage: /befrog <Target> [0/1]");
		return Plugin_Handled;
	} else if (GetCmdArgs()>=2) {
		GetCmdArg(2, buffer, sizeof(buffer));
		on = buffer[0];
		if (on != '1' && on != '0') {
			ReplyToCommand(client, "Force has to be 1 or 0");
			return Plugin_Handled;
		}
	}

	GetCmdArg(1, buffer, sizeof(buffer));
	int targets[MAXPLAYERS];
	bool tn_is_ml;
	int result = ProcessTargetString(buffer, client, targets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, buffer, sizeof(buffer), tn_is_ml);
	if (result <= 0) {
		ReplyToTargetError(client, result);
		return Plugin_Handled;
	}

	for (int i; i<result; i++) {
		if (on == 0) {
			BeFrog(targets[i], !bIsFrog[targets[i]]);
		} else if (on == '1') {
			BeFrog(targets[i], true);
		} else {
			BeFrog(targets[i], false);
		}
	}
	if (client) {
		if (tn_is_ml) {
			ReplyToCommand(client, "[SM] You turned %t to frogs", buffer);
			ShowActivity(client, "%N turned %t to frogs", client, buffer);
		} else {
			ReplyToCommand(client, "[SM] You turned %s to frogs", buffer);
			ShowActivity(client, "%N turned %t to frogs", client, buffer);
		}
	} else {
		if (tn_is_ml)
			ShowActivity(client, "Console turned %t to frogs", buffer);
		else
			ShowActivity(client, "Console turned %s to frogs", buffer);
	}
	return Plugin_Handled;
}

void OnClientInventoryRegenerate(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid", 0);
	CreateTimer(1.0, FrogTimer, userid, TIMER_FLAG_NO_MAPCHANGE);
}

void FrogTimer(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client) && GetClientTeam(client)>1 && IsPlayerAlive(client) && bIsFrog[client]) {
		bIsFrog[client] = false;
		BeFrog(client, true);
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!IsValidEdict(client) || !IsClientInGame(client) || GetClientTeam(client) < 2 || !IsPlayerAlive(client))
		return Plugin_Continue;

	bool onGround = (GetEntityFlags(client)&FL_ONGROUND)!=0;
	if (bIsFrog[client]) {
		float aux[3], fwd[3];

		// get the planar movement speed
		aux = vel;
		aux[2] = 0.0;
		float velLen = GetVectorLength(aux);

		// "unstrafe", planar redirection to look direction
		if (buttons & (IN_MOVELEFT|IN_MOVERIGHT)) {
			GetClientEyeAngles(client, aux);
			aux[1] = aux[2] = 0.0;
			GetAngleVectors(aux, fwd, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(fwd, fwd);
			ScaleVector(fwd, velLen);
			fwd[2] = vel[2];
			vel = fwd;
		}

		// block buttons, only allow W+Space
		int newButtons = IN_FORWARD | (buttons & IN_JUMP);
		if (onGround) {
			if (!bWasOnGround[client] || velLen<10.0) {
				flJumpTimer[client] = GetGameTime();
			} else {
				float groundTime = (GetGameTime() - flJumpTimer[client]);
				if ((groundTime > 0.3 && velLen > 150.0) || groundTime > 2.0)
					newButtons |= IN_JUMP;
			}
		}

		buttons = newButtons;
	}

	bWasOnGround[client] = onGround;
	return bIsFrog[client] ? Plugin_Changed : Plugin_Continue;
}

void BeFrog(int client, bool frog)
{
	if (bIsFrog[client] == frog) return;
	bIsFrog[client] = frog;

	if (frog) {
		SetVariantString("models/props_2fort/frog.mdl");
		AcceptEntityInput(client, "SetCustomModel");
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");

		//remove all weapons and wearables
		TF2_RemoveAllWeapons(client);
		int wearables = TF2Util_GetPlayerWearableCount(client);
		for (int i=wearables; i>0; i--) {
			TF2_RemoveWearable(client, TF2Util_GetPlayerWearable(client, 0));
		}
	} else {
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");

		TF2_RegeneratePlayer(client);
	}
}