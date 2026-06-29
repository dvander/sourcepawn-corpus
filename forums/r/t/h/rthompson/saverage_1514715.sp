#include <sourcemod>
#define PLUGIN_VERSION "1.0.1"
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <events>
#include <clients> 


new Handle:Enabled;
new Handle:Range;
new Handle:Duration;

public Plugin:myinfo =
{
	name = "[TF2] Save Rage",
	author = "TommY",
	description = "If you die with your rage meter fully charged, you will get compensated",
	version = PLUGIN_VERSION,
	url = "tommy.or.kr"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	Enabled = CreateConVar("sm_saverage_enabled", "0.0", "Save Rage? 0 : off   1 : on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	Range = CreateConVar("sm_saverage_range", "450.0", "How far?", FCVAR_PLUGIN, false, 0.0, false, 0.0);
	Duration = CreateConVar("sm_saverage_duration", "5.0", "How long?(seconds)", FCVAR_PLUGIN, true, 0.0, true, 8.0);
	HookEvent("player_death", event_player_death, EventHookMode_Post);
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:clientname[64];
	GetClientName(client,clientname,sizeof(clientname));
	new RageOffset = FindSendPropInfo("CTFPlayer", "m_flRageMeter");
	new Float:rage = GetEntDataFloat(client, RageOffset);
	if (GetConVarBool(Enabled) && IsClientInGame(client) && client != -1 && rage == 100.0) {
		new weapon = GetPlayerWeaponSlot(client, 1);
		new weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 4);
		new team = GetClientTeam(client);
		new Float:clientpos[3], count;
		GetEntDataVector(client, FindSendPropOffs("CTFPlayer","m_vecOrigin"), clientpos);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && i != client) {
				new Float:teampos[3], Float:distance;
				GetEntDataVector(i, FindSendPropOffs("CTFPlayer","m_vecOrigin"), teampos);
				distance = SquareRoot(Pow((clientpos[0] - teampos[0]),2.0) + Pow((clientpos[1] - teampos[1]), 2.0) + Pow((clientpos[2] - teampos[2]), 2.0));
				if (GetClientTeam(i) == team && distance < GetConVarFloat(Range) && weaponindex == 129 && i != 0)
				{
					count++;
					TF2_AddCondition(i, TFCond_Buffed, GetConVarFloat(Duration)); 
					PrintToChat(i, "\x04[SM] \x01You have been given MiniCrit-Buff for %d seconds by %s.", GetConVarInt(Duration), clientname);
				}
			}

		}
		if (count > 0) {
			PrintToChat(client, "\x04[SM] \x01You had a fully charged MiniCrit-Buff before death.");
			PrintToChat(client, "\x04[SM] \x01%d Teammates have been given MiniCrit-Buff for %d seconds.", count, GetConVarInt(Duration));
		}
	}
}
