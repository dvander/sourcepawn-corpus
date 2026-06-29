#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#pragma semicolon 1
#define MAX_FILE_LEN 80
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

#define PLUGIN_VERSION "0.0.1"
public Plugin:myinfo = 
{
	name = "Welcome Sound",
	author = "R-Hehl",
	description = "Plays Welcome Sound to connecting Players",
	version = PLUGIN_VERSION,
	url = "http://www.compactaim.de/"
};

public OnPluginStart()
{
  CreateConVar("sm_welcome_snd_version", PLUGIN_VERSION, "Welcome Sound Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  g_CvarSoundName = CreateConVar("sm_join_sound", "", "The sound to play (file goes in /sound/consnd/)");
  
  GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
  HookConVarChange(g_CvarSoundName, OnSettingChanged);  
}

public OnConfigsExecuted()
{
  if (strlen(g_soundName) > 3)
  {
    new String:soundfile[32];
    soundfile = "sound/consnd/";
    StrCat(soundfile, sizeof(soundfile), g_soundName);
    if (FileExists(soundfile))
    {
      decl String:buffer[MAX_FILE_LEN];
      soundfile = "consnd/";
      StrCat(soundfile, sizeof(soundfile), g_soundName);
      if (!PrecacheSound(soundfile, true))
      {
        SetFailState("[Welcome Sound: Could not pre-cache sound: %s", soundfile);
      }
      Format(buffer, sizeof(buffer), "sound/consnd/%s", g_soundName);
      AddFileToDownloadsTable(buffer);
    }
  }
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
  strcopy(g_soundName, sizeof(g_soundName), newValue);
}

public OnClientPostAdminCheck(client)
{
  new String:soundfile[32] = "consnd/";
  StrCat(soundfile, sizeof(soundfile), g_soundName);
  EmitSoundToClient(client, soundfile);
}