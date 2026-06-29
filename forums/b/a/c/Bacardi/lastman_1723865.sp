#include <sourcemod>
#include <sdktools>

new String:sm_path[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	BuildPath(Path_SM, sm_path, sizeof(sm_path), "configs/lastman.txt");
	HookEventEx("player_death", player_death);
}

public OnConfigsExecuted()
{
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

public player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team, T, CT;

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if((team = GetClientTeam(i)) == 2)
			{
				T++;
			}
			else if(team == 3)
			{
				CT++;
			}
		}
	}


	new Handle:kv = CreateKeyValues("data");
	if(!FileToKeyValues(kv, sm_path))
	{
		CloseHandle(kv);
		SetFailState("No file %s", sm_path);
		return;
	}

	new String:buffer[PLATFORM_MAX_PATH];
	Format(buffer, sizeof(buffer), "T%i:CT%i", T, CT);

	KvGetString(kv, buffer, buffer, sizeof(buffer), NULL_STRING);
	CloseHandle(kv);

	new pos = FindCharInString(buffer, '.', true);
	if(pos == -1 || !StrEqual(buffer[pos], ".mp3", false) && !StrEqual(buffer[pos], ".wav", false))
	{
		buffer[0] = '\0';
	}

	if(strlen(buffer) > 4)
	{
		EmitSoundToAll(buffer, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
	}
}