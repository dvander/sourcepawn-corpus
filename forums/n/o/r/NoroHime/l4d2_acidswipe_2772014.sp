#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1.1"


int hurtsLeft[MAXPLAYERS+1];
int attackers[MAXPLAYERS+1];

ConVar Duration;
ConVar Damage;
ConVar Stack;
ConVar SoundPath;

public Plugin myinfo = 
{
	name = "Acid Swipe",
	author = "Oshroth & NoroHime",
	description = "Spitter claws cause acid damage.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1117948"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));

	if (!StrEqual(game_name, "left4dead2", false)) {
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	return APLRes_Success; 
}

public void OnPluginStart()  {
	CreateConVar("sm_acidswipe_version", PLUGIN_VERSION, "Acid Swipe plugin version.", FCVAR_NOTIFY);

	Duration = CreateConVar("sm_acidswipe_duration", "10", "Acid damage duration in seconds", FCVAR_NOTIFY|FCVAR_REPLICATED);
	Damage = CreateConVar("sm_acidswipe_damage", "1", "Acid damage per second", FCVAR_NOTIFY|FCVAR_REPLICATED);
	Stack = CreateConVar("sm_acidswipe_stack", "10", "Amount of time to add to timer on each additional swipe. -1 Each swipe resets timer, 0 Multiple swipes are ignored.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	SoundPath = CreateConVar("sm_acidswipe_sound", "player/spitter/swarm/spitter_acid_fadeout.wav", "Path to the Soundfile to be played on each damage point.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	AutoExecConfig(true, "sm_acidswipe");
	
	HookEvent("player_hurt", Event_PlayerHurt);
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {

	int attacker = GetClientOfUserId(event.GetInt("attacker")),
		victim = GetClientOfUserId(event.GetInt("userid")),
		duration = Duration.IntValue,
		stack = Stack.IntValue;
	
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));

	if(isAliveSurvivor(victim) && (strcmp(weapon, "spitter_claw") == 0)) {
		attackers[victim] = attacker;

		if(hurtsLeft[victim] <= 0)  {
			hurtsLeft[victim] = duration;
			CreateTimer(1.0, Acid_Damage, victim, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		} else if(stack >= 0)
			hurtsLeft[victim] += stack;
		else
			hurtsLeft[victim] = duration;
	}
	return Plugin_Continue;
}

public Action Acid_Damage(Handle timer, int victim)  {

	if(hurtsLeft[victim] <= 0)  {

		attackers[victim] = 0;
		return Plugin_Stop;

	} else  
		hurtsLeft[victim] -= 1;

	if(!isAliveSurvivor(victim))  {
		attackers[victim] = 0;
		hurtsLeft[victim] = 0;
		return Plugin_Stop;
	}
	
	DamageEffect(victim);
	
	return Plugin_Continue;
}

public void DamageEffect(int victim)  {

	if(isAliveSurvivor(victim)) {

		static char soundFilePath[255];
		SoundPath.GetString(soundFilePath, sizeof(soundFilePath));

		EmitSoundToClient(victim, soundFilePath);
		SDKHooks_TakeDamage(victim, 0, attackers[victim], Damage.FloatValue, DMG_ACID);
	}
}

stock bool isAliveSurvivor(int client) {
	return isClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

stock bool isClient(int client) {
	return isClientIndex(client) && IsValidEntity(client) && IsClientInGame(client);
}

stock bool isClientIndex(int client) {
	return (1 <= client <= MaxClients);
}