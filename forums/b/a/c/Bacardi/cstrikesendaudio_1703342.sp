#include <sourcemod>
#include <sdktools>

new String:sm_path[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("SendAudio") , SendAudio, true); // Hook SendAudio

	BuildPath(Path_SM, sm_path, sizeof(sm_path), "configs/cstrike_sounds_radio.txt");
}

public OnConfigsExecuted()
{
	PrecacheSound("resource/warning.wav", true);
	new Handle:smc = SMC_CreateParser();
	SMC_SetReaders(smc, NewSection, KeyValue, EndSection);
	SMC_ParseFile(smc, sm_path);
	CloseHandle(smc);
}

public SMCResult:NewSection(Handle:smc, const String:name[], bool:opt_quotes){
}
public SMCResult:KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	new pos = FindCharInString(value, '.', true); // Thanks Chanz http://docs.sourcemod.net/api/index.php?fastload=show&id=867&
	if(pos != -1)
	{
		if(StrEqual(value[pos], ".mp3", false) || StrEqual(value[pos], ".wav", false))
		{
			decl String:buffer[PLATFORM_MAX_PATH];
			Format(buffer, sizeof(buffer), "sound/%s", value);
			AddFileToDownloadsTable(buffer);
			if(!PrecacheSound(value, true))
			{
				// When this really happen ?
				LogError("Failed precache file %s", value);
			}
		}
	}
}
public SMCResult:EndSection(Handle:smc){
}

public Action:SendAudio(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	// Message is original ?
	if(!reliable)
	{
		return Plugin_Continue;
	}

	// At least one player get this message
	if(playersNum > 0)
	{
		decl String:buffer[256];
		buffer[0] = '\0';

		new Handle:pack;
		CreateDataTimer(0.0, saudio, pack); // Start new message after this one

		WritePackCell(pack, playersNum); // need first collect player amount in datapack
		for(new i = 0; i < playersNum; i++) // List all players index in datapack
		{
			WritePackCell(pack, players[i]);
		}

		// audio title	...<mod>/scripts/game_sounds_radio.txt
		BfReadString(bf, buffer, sizeof(buffer));
		WritePackString(pack, buffer);
		ResetPack(pack); // Set position top of datapack;

		return Plugin_Handled; // Block this original msg
	}
	return Plugin_Continue;
}

// New fake SendAudio
public Action:saudio(Handle:timer, Handle:pack)
{
	// Copy players list from datapack
	new playersNum = ReadPackCell(pack);
	new players[playersNum];
	new count, client;

	for(new i = 0; i < playersNum; i++)
	{
		client = ReadPackCell(pack);
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			players[count] = client;
			count++;
		}
	}
	playersNum = count;

	if(playersNum < 1)
	{
		return Plugin_Stop;
	}

	// Start create new fake SendAudio.
	new Handle:kv = CreateKeyValues("data");
	if(!FileToKeyValues(kv, sm_path))
	{
		CloseHandle(kv);
		SetFailState("No file %s", sm_path);
		return Plugin_Stop;
	}

	new String:buffer[PLATFORM_MAX_PATH];
	ReadPackString(pack, buffer, sizeof(buffer)); // Get radio sound file from config

	KvGetString(kv, buffer, buffer, sizeof(buffer), "resource/warning.wav"); // Set warning sound when we fail get radio "key" from config
	CloseHandle(kv);

	new pos = FindCharInString(buffer, '.', true);
	if(pos == -1 || !StrEqual(buffer[pos], ".mp3", false) && !StrEqual(buffer[pos], ".wav", false))
	{
		Format(buffer, sizeof(buffer), "resource/warning.wav"); // Set warning sound when we fail get radio "sound file" from config
	}

	EmitSound(players, playersNum, buffer, SOUND_FROM_PLAYER, SNDCHAN_VOICE);

	return Plugin_Continue;
}