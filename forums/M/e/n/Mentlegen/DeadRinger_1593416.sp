/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#define PLUGIN_NAME "DEAD RINGER"
#include <MLIB>
#define PLUGIN_VERSION "0.1"

#define SND "puppet/poof1.wav"

new bool:can[33];
new bool:trigger[33]

public Plugin:myinfo = 
{
	name = "Test",
	author = "Booster",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	new Handle:cvar = CreateConVar("sm_deadringer_version", PLUGIN_VERSION, "DeadRinger version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(cvar != INVALID_HANDLE)
		SetConVarString(cvar, PLUGIN_VERSION);

	HookEvent("player_hurt", Hurt, EventHookMode_Pre);
	RegConsoleCmd("sm_fd", Trigger)
	for (new i=1; i<=32; i++) {
		can[i] = true;
		trigger[i] = false;
	}
	Reclama()
}

public OnMapStart() {
	PrecacheSound(SND, true);
	AddFileToDownloadsTable("sound/puppet/poof1.wav")
}

public Action:Trigger(client, args) {
	if (can[client]) {
		trigger[client] = true
	}
	return Plugin_Handled
}

public Hurt(Handle:event, const String:name[], bool:lol) {
	new victimID = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(victimID);
	new aID = GetEventInt(event,"attacker")
	new a = GetClientOfUserId(aID);
	if (!can[a]) {
		SetEventInt(event, "damageamount", 0)
	}
	if (can[victim] && trigger[victim]) {
		new Handle:event1 = CreateEvent("player_death");
		
		if (event1 != INVALID_HANDLE)
		{
			SetEventInt(event1, "userid", victimID);
			SetEventInt(event1, "attacker", GetEventInt(event, "attacker"));
			SetEventInt(event1, "weaponid", GetEventInt(event, "weaponid"));
			SetEventInt(event1, "damagebits", TF_DEATHFLAG_DEADRINGER)
			FireEvent(event1);
		}
		
		if(IsValidEntity(victim))
		{
			SetEntityRenderMode(victim,RENDER_GLOW)
			SetEntityRenderColor(victim, 255, 255, 255, 0)
			CreateTimer(6.5, TimerUncloak, victim)
		}
		can[victim] = false;
		trigger[victim] = false;
		PrintToChatAll("Somebody Feigned his Death")
		PrintHintText(victim, "You feigned your death")
		EmitSoundToAll(SND, victim)
	}
	return Plugin_Changed
}

public Action:TimerUncloak(Handle:timer, any:cl) {
	if (IsPlayerAlive(cl)) {
		SetEntityRenderColor(cl, 255, 255, 255, 255)
	}
	CreateTimer(8.0, TimerCloak, cl)
	PrintHintText(cl, "You've uncloaked")
}

public Action:TimerCloak(Handle:timer, any:cl) {
	can[cl] = true;
	PrintHintText(cl, "You can now to feign death")
}
	