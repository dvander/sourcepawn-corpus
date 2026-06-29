#include <sdktools_sound>
#include <keyvalues>
#include <files>
#include <adt_array>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "Sound filter",
	author = "epi",
	description = "Filter all played sounds",
	version = "0.1",
	url = ""
};

ArrayList sounds = null;
ConVar enabled = null;
bool currentlyenabled = true;

void LoadKV() {
	if (sounds == null) {
		sounds = new ArrayList(PLATFORM_MAX_PATH);
	} else {
		sounds.Clear();
	}
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "configs/disabledsounds.cfg");
	KeyValues kv = new KeyValues("Sounds");
	if (!kv.ImportFromFile(path)) {
		delete kv;
		SetFailState("unable to load disabledsounds.cfg");
	}
	char sound[PLATFORM_MAX_PATH];
	kv.Rewind();
	kv.GotoFirstSubKey(false);
	do {
		kv.GetString(NULL_STRING, sound, PLATFORM_MAX_PATH);
		sounds.PushString(sound);
	} while (kv.GotoNextKey(false));
	delete kv;
}

public Action SoundHook(int c[MAXPLAYERS], int &nc, char sample[PLATFORM_MAX_PATH], int &e, int &ch, float &v, int &le, int &p, int &f, char se[PLATFORM_MAX_PATH], int &s) {
	char disabled[PLATFORM_MAX_PATH];
	for (int i = 0, l = sounds.Length; i < l; i++) {
		sounds.GetString(i, disabled, PLATFORM_MAX_PATH);
		if (StrContains(sample, disabled, false) != -1) {
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public void SetEnabled(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (convar.BoolValue && currentlyenabled) {
		currentlyenabled = false;
		RemoveNormalSoundHook(SoundHook);
	} else if (!convar.BoolValue && !currentlyenabled) {
		currentlyenabled = true;
		AddNormalSoundHook(SoundHook);
	}
}

public Action ReloadKV(int client, int args) {
	LoadKV();
	return Plugin_Handled;
}

public void OnPluginStart() {
	LoadKV();
	AddNormalSoundHook(SoundHook);
	enabled = CreateConVar("sm_soundfilter_enabled", "1", "Enable sound filter");
	enabled.AddChangeHook(SetEnabled);
	RegAdminCmd("sm_soundfilter_reload", ReloadKV, ADMFLAG_CHEATS, "Reload sound filter");
}