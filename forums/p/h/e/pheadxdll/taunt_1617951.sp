#include <sourcemod>
#include <sdktools>
#include <tf2>

#define SOUND "misc/tf_nemesis.wav"

new Handle:g_hCvarDuration;

public Plugin:myinfo = 
{
	name = "Taunt Crits",
	author = "linux_lover",
	description = "Gets crits for a taunt kill",
	version = "0.1",
	url = ""
}

public OnPluginStart()
{
	g_hCvarDuration = CreateConVar("tc_duration", "6.0", "Time (seconds) for crit effects after a taunt kill.");
	
	HookEvent("player_death", Event_Death);
}

public OnMapStart()
{
	PrecacheSound(SOUND);
}

public Event_Death(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(iVictim >= 1 && iVictim <= MaxClients && IsClientInGame(iVictim) && iAttacker >= 1 && iAttacker <= MaxClients && IsClientInGame(iAttacker) && IsPlayerAlive(iAttacker))
	{
		decl String:strLogWeapon[40];
		GetEventString(hEvent, "weapon", strLogWeapon, sizeof(strLogWeapon));
		if(strncmp(strLogWeapon, "taunt_", 6) == 0 && strcmp(strLogWeapon, "taunt_soldier") != 0)
		{
			decl String:strText[150];
			Format(strText, sizeof(strText), "\x03 %N\x01 just \x04taunt\x01 killed \x04%N\x01.", iAttacker, iVictim);	
			SayText2(iAttacker, strText);
			EmitSoundToClient(iVictim, SOUND);
			
			TF2_AddCondition(iAttacker, TFCond_CritOnFirstBlood, GetConVarFloat(g_hCvarDuration));
		}
	}
}

stock SayText2(author_index , const String:message[]) 
{
	new Handle:buffer = StartMessageAll("SayText2");
	if(buffer != INVALID_HANDLE) 
	{
		BfWriteByte(buffer, author_index);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, message);
		EndMessage();
	}
}