#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION	 "1.02"
//#define DEBUG

#define PATH_MAX		 256
#define SOUNDNAME_MAX	 64
#define SOUNDS_MAX		 32

new bool:defaultSoundDone = false;
new String:defaultSound[PATH_MAX];
new String:precachedSounds[SOUNDS_MAX][PATH_MAX];
new String:precachedSoundNames[SOUNDS_MAX][SOUNDNAME_MAX];
new precachedSoundCount;

new Handle:sm_intro_repeat_on_roundstart = INVALID_HANDLE;
new bool:repeat_on_roundstart;
new bool:playerHeardSound[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Intro sound chooser",
	author = "dataviruset",
	description = "Plays a certain intro sound to a connecting player depending on his choise",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public bool:IsSoundAdded(String:path[])
{
	for(new i; i < sizeof(precachedSounds); i++)
		if (StrEqual(precachedSounds[i], path))
			return true;

	return false;
}

public OnPluginStart()
{
	RegConsoleCmd("sm_intro", Command_Intro);

	HookEvent("round_start", Event_RoundStart);

	sm_intro_repeat_on_roundstart = CreateConVar("sm_intro_repeat_on_roundstart", "1", "Enable/disable the possibility to repeat the intro on roundstart once (otherwise it will stop automatically when a new round starts); 0 - disable, 1 - enable");
	new Handle:sm_intro_version = CreateConVar("sm_intro_version", PLUGIN_VERSION, "Intro sound chooser version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetConVarString(sm_intro_version, PLUGIN_VERSION);
	HookConVarChange(sm_intro_version, VersionChange);
}

public VersionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, PLUGIN_VERSION);
}

stock String:kvFile()
{
	new String:file[PATH_MAX];
	BuildPath(Path_SM, file, PATH_MAX, "data/introchoises.txt");
	return file;
}

public OnConfigsExecuted()
{
	repeat_on_roundstart = (GetConVarInt(sm_intro_repeat_on_roundstart) == 1) ? true : false;

	for(new i = 0; i < precachedSoundCount; i++)
		precachedSounds[i] = "";
	for(new i = 0; i < precachedSoundCount; i++)
		precachedSoundNames[i] = "";

	precachedSoundCount = 0;
	defaultSoundDone = false;

	new Handle:cfgfile = CreateKeyValues("IntroSounds");
	decl String:file[PATH_MAX];
	BuildPath(Path_SM, file, PATH_MAX, "configs/introsounds.cfg");
	FileToKeyValues(cfgfile, file);
	KvGotoFirstSubKey(cfgfile);

	decl String:soundName[SOUNDNAME_MAX];
	decl String:path[PATH_MAX];
	decl String:path_full[PATH_MAX];

	do
	{
		KvGetString(cfgfile, "path", path, PATH_MAX);

		Format(path_full, sizeof(path_full), "sound/%s", path);
		if (FileExists(path_full))
		{
			PrecacheSound(path, true);
			AddFileToDownloadsTable(path_full);

			precachedSounds[precachedSoundCount] = path;

			KvGetSectionName(cfgfile, soundName, sizeof(soundName));
			precachedSoundNames[precachedSoundCount] = soundName;

			#if defined DEBUG
			PrintToServer("[INTROSOUND] Adding intro %s (%s)", soundName, path);
			#endif

			precachedSoundCount++;

			if (!defaultSoundDone)
			{
				defaultSoundDone = true;
				defaultSound = path;
				#if defined DEBUG
				PrintToServer("[INTROSOUND] DEFAULT SOUND %s", path);
				#endif
			}
		}
		else
			PrintToServer("[INTROSOUND] File does not exist! %s", path_full);
	} while(KvGotoNextKey(cfgfile));

	CloseHandle(cfgfile);
}

public OnMapEnd()
{
	defaultSoundDone = false;
}

public OnClientDisconnect(client)
{
	if (repeat_on_roundstart)
		playerHeardSound[client] = false;
}

public OnClientPostAdminCheck(client)
{
	EmitSoundToClient(client, GetClientIntro(client));
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (repeat_on_roundstart)
		for(new i = 1; i <= MaxClients; i++)
			if ( (IsClientInGame(i)) && (!playerHeardSound[i]) )
			{
				EmitSoundToClient(i, GetClientIntro(i));
				playerHeardSound[i] = true;
			}
}

String:GetClientIntro(any:client)
{
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	decl String:clientSound[PATH_MAX];

	new Handle:kv = CreateKeyValues("IntroChoises");
	FileToKeyValues(kv, kvFile());

	if (KvJumpToKey(kv, auth))
	{
		KvGetString(kv, "intro", clientSound, PATH_MAX);

		if (!StrEqual(clientSound, "none"))
		{
			if (!IsSoundAdded(clientSound))
			{
				#if defined DEBUG
				PrintToServer("Found Steam-ID in kv file, setting default sound to client (non existing intro found in records)", clientSound);
				#endif

				KvDeleteThis(kv);

				KvRewind(kv);
				KeyValuesToFile(kv, kvFile());

				clientSound = defaultSound;
			}

			#if defined DEBUG
			PrintToServer("Found Steam-ID in kv file, emitting %s to client", clientSound);
			#endif
			EmitSoundToClient(client, clientSound);
		}
		#if defined DEBUG
		else
			PrintToServer("Found Steam-ID in kv file, no sound chosen", clientSound);
		#endif
	
	}
	else
	{
		clientSound = defaultSound;
		#if defined DEBUG
		PrintToServer("Didn't find Steam-ID in kv file, emitting %s to client", clientSound);
		#endif
	}

	CloseHandle(kv);
	return clientSound;
}

public Action:Command_Intro(client, args)
{
	new Handle:menu = CreateMenu(MainHandler);
	SetMenuTitle(menu, "Choose your preferred intro sound:");
	AddMenuItem(menu, "soundNone", "None");

	for(new i = 0; i < precachedSoundCount; i++)
		AddMenuItem(menu, "sound", precachedSoundNames[i]);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);

	return Plugin_Handled;
}

public MainHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:auth[32];
		GetClientAuthString(param1, auth, sizeof(auth));

		new Handle:kv = CreateKeyValues("IntroChoises");
		FileToKeyValues(kv, kvFile());

		KvJumpToKey(kv, auth, true);
		if (param2 != 0)
			KvSetString(kv, "intro", precachedSounds[param2-1]);
		else
			KvSetString(kv, "intro", "none");

		KvRewind(kv);

		KeyValuesToFile(kv, kvFile());
		CloseHandle(kv);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}