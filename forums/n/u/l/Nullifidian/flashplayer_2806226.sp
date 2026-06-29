#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define SND_BLINDSEC "player/voice/botsurvival/subordinate/flashbanged25.ogg"
#define SND_BLINDINS "player/voice/bot/blinded9.ogg"
#define SND_DETONATE "weapons/m84/m84_detonate.wav"

public Plugin myinfo = {
	name = "flashplayer",
	author = "Nullifidian",
	description = "nade flash a player",
	version = "1.5",
	url = ""
};

public void OnPluginStart() {
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_flash", cmd_flash, ADMFLAG_BAN, "nade flash player: <#userid|name> <duration>");
}

public void OnMapStart() {
	PrecacheSound(SND_BLINDSEC, true);
	PrecacheSound(SND_BLINDINS, true);
	PrecacheSound(SND_DETONATE, true);
}

void BlindTarget(int client, float fDuration = 14.0) {
	//m_flFlashDuration must be set back to 0.0 for the next flashB effect to work
	if (GetEntPropFloat(client, Prop_Send, "m_flFlashDuration") != 0.0) {
		SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0);

		DataPack dPack;
		CreateDataTimer(0.01, Timer_BlindTarget, dPack, TIMER_FLAG_NO_MAPCHANGE);
		dPack.WriteCell(client);
		dPack.WriteFloat(fDuration);
		return;
	}

	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 255.0);
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", fDuration);
	
	EmitSoundToAll(SND_DETONATE, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.75, 100);
	EmitSoundToAll(GetClientTeam(client) == 2 ? SND_BLINDSEC : SND_BLINDINS, client, SNDCHAN_VOICE, _, _, 1.0);
}

Action Timer_BlindTarget(Handle timer, DataPack dPack) {
	dPack.Reset();
	int client = dPack.ReadCell();

	if (IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client)) {
		BlindTarget(client, dPack.ReadFloat());
	}
	return Plugin_Stop;
}

public Action cmd_flash(int client, int args) {
	if (args < 2) {
		ReplyToCommand(client, "[SM] Usage: sm_flash <#userid|name> <duration>");
		return Plugin_Handled;
	}

	char	arg[65];

	GetCmdArg(1, arg, sizeof(arg));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, arg, sizeof(arg));

	float fDuration = StringToFloat(arg);
	for (int i = 0; i < target_count; i++) {
		BlindTarget(target_list[i], fDuration);
	}
	
	ReplyToCommand(client, "[SM] Flashed (%.0f seconds): %s", fDuration, target_name);

	return Plugin_Handled;
}