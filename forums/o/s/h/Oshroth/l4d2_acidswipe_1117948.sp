#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

new hurtsLeft[MAXPLAYERS+1];
new attacker[MAXPLAYERS+1];

public Plugin:myinfo = {
	name = "Acid Swipe",
	author = "Oshroth",
	description = "Spitter claws cause acid damage.",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart() {
	decl String:game[12];
	new Handle:acid_version = INVALID_HANDLE;
	
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("Acid Swipe will only work with Left 4 Dead 2!");
	
	acid_version = CreateConVar("sm_acidswipe_version", PLUGIN_VERSION, "Acid Swipe plugin version.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	CreateConVar("sm_acidswipe_duration", "10", "Acid damage duration in seconds", FCVAR_NOTIFY);
	CreateConVar("sm_acidswipe_damage", "1", "Acid damage per second", FCVAR_NOTIFY);
	CreateConVar("sm_acidswipe_stack", "10", "Amount of time to add to timer on each additional swipe. -1 Each swipe resets timer, 0 Multiple swipes are ignored.", FCVAR_NOTIFY, true, -1.0);
	
	AutoExecConfig();
	
	SetConVarString(acid_version, PLUGIN_VERSION, true);
	
	HookEvent("player_hurt", Event_PlayerHurt);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new spitter = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	new duration = GetConVarInt(FindConVar("sm_acidswipe_duration"));
	new stack = GetConVarInt(FindConVar("sm_acidswipe_stack"));
	
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if((GetClientTeam(target) == 2) && (StrEqual(weapon, "spitter_claw"))) {
		PrintToChatAll("%N got acid all over %N", spitter, target);
		attacker[target] = spitter;
		if(hurtsLeft[target] <= 0) {
			hurtsLeft[target] = duration;
			CreateTimer(1.0, Acid_Damage, target);
		} else {
			if(stack == -1) {
				hurtsLeft[target] = duration;
			} else {
				if(stack >= 0) {
					hurtsLeft[target] += stack;
				} else {
					//sm_acidswipe_stack has invalid value so log error
					LogError("sm_acidswipe_stack has an invalid value. Accepted values are -1 and higher.");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Acid_Damage(Handle:timer, any:client) {
	if(hurtsLeft[client] <= 0) {
		attacker[client] = 0;
		return;
	} else {
		hurtsLeft[client] -= 1;
	}
	if(client == 0) {
		attacker[client] = 0;
		hurtsLeft[client] = 0;
		return;
	}
	if(!IsClientInGame(client)) {
		attacker[client] = 0;
		hurtsLeft[client] = 0;
		return;
	}
	if(!IsPlayerAlive(client)) {
		attacker[client] = 0;
		hurtsLeft[client] = 0;
		return;
	}
	if(GetClientTeam(client) != 2) {
		attacker[client] = 0;
		hurtsLeft[client] = 0;
		return;
	}
	#if defined DEBUG
	PrintToChatAll("%N is taking acid damage for %d more seconds.", client, hurtsLeft[client]);
	#endif
	
	DamageEffect(client);
	
	if(hurtsLeft[client] > 0) {
		CreateTimer(1.0, Acid_Damage, client);
	}
	return;
}

public Action:DamageEffect(target) {
	decl String:damage[10];
	decl String:type[10];
	IntToString((1 << 20), type, sizeof(type));
	GetConVarString(FindConVar("sm_acidswipe_damage"), damage, sizeof(damage));
	new pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(target, "targetname", "hurtme");
	DispatchKeyValue(pointHurt, "Damage", damage);
	DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
	DispatchKeyValue(pointHurt, "DamageType", type);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt", attacker[target]);
	AcceptEntityInput(pointHurt, "Kill");
	DispatchKeyValue(target, "targetname",	"blah");
}