#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

char g_sFilePath[PLATFORM_MAX_PATH];

public void OnPluginStart() {
	RegAdminCmd("sm_getparticlelist", cmdGetParticleList, ADMFLAG_ROOT);
	BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), "configs/particles");
	if (!DirExists(g_sFilePath)) {
		CreateDirectory(g_sFilePath, 511);
	}
	BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), "/configs/particles/fullparticlelist.txt");
}

public Action cmdGetParticleList(int client, int args) {
	
	File file = OpenFile(g_sFilePath, "w");
	int tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx == INVALID_STRING_TABLE)  {
		LogError("Could not find string table: ParticleEffectNames");
		return Plugin_Handled;
	}
	
	// find particle index
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	for (int i = 0; i < count; i++) {
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		file.WriteLine(tmp);
	}

	ReplyToCommand(client, "Successfully wrote particles to file");
	delete file;

	return Plugin_Handled;
}