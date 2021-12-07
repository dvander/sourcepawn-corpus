/*
	[Chat Time Air] by meng (OG plug. by TechKnow)
	Plays a sound at chattime (end of map).
*/
#include <sourcemod>
#include <sdktools>

new Handle:g_CVarVolume;
new String:g_sCurrSound[192];
new UserMsg:g_umVGUIMenu;

public OnPluginStart()
{
	g_CVarVolume = CreateConVar("sm_chattimeair_volume", "0.7", "Volume of sound.", _, true, 0.0, true, 1.0);
	g_umVGUIMenu = GetUserMessageId("VGUIMenu");
	HookUserMessage(g_umVGUIMenu, VGUIMenuHook);
}

public OnMapStart()
{
	if (DirExists("sound/mapend"))
	{
		new Handle:soundsDir = OpenDirectory("sound/mapend");
		new Handle:soundsArray = CreateArray(192);
		new FileType:type;
		decl String:file[192];
		while (ReadDirEntry(soundsDir, file, sizeof(file), type))
			if (type == FileType_File)
				PushArrayString(soundsArray, file);
		CloseHandle(soundsDir);
		new arraySize = GetArraySize(soundsArray);
		if (arraySize > 0)
		{
			GetArrayString(soundsArray, (GetURandomInt() % arraySize), file, sizeof(file));
			Format(g_sCurrSound, sizeof(g_sCurrSound), "sound/mapend/%s", file);
			AddFileToDownloadsTable(g_sCurrSound);
			Format(g_sCurrSound, sizeof(g_sCurrSound), "mapend/%s", file);
			PrecacheSound(g_sCurrSound, true);
		}
		else
			LogError("No sound files found in sound/mapend.");
		CloseHandle(soundsArray);
	}
	else
		LogError("Directory sound/mapend does not exist.");
}

public Action:VGUIMenuHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:mess[16];
	BfReadString(bf, mess, sizeof(mess));
	if (StrEqual(mess, "scores") && (BfReadByte(bf) == 1) && (BfReadByte(bf) == 0))
		EmitSoundToAll(g_sCurrSound, _, _, _, _, GetConVarFloat(g_CVarVolume));

	return Plugin_Continue;
}  