#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#define PLUGIN_VERSION "0.1.0.2"

public Plugin:myinfo =
{
	name = "KK Random Intro",
	author = "Camaron",
	description = "KK Random Intro",
	version = PLUGIN_VERSION,
	url = "http://kolokonklan.es/"
};

#define MAX_FILE_LEN 255
new String:g_soundName[MAX_FILE_LEN]
new String:intros[255][MAX_FILE_LEN]
new Handle:g_dirPrefix = INVALID_HANDLE;
new iFilecount=0;

public OnPluginStart()
{
  CreateConVar("kk_intro_version", PLUGIN_VERSION, "KK Random Welcome Sound Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  g_dirPrefix = CreateConVar("kk_intro_prefix", "intros/", "Prefix to intro dir");
  new Handle:hIntrodir = INVALID_HANDLE;
  new String:sAbsIntroDir[MAX_FILE_LEN] = "sound/";
  new String:sIntroDir[MAX_FILE_LEN];
  GetConVarString(g_dirPrefix, sIntroDir, MAX_FILE_LEN);
  StrCat(sAbsIntroDir, MAX_FILE_LEN, sIntroDir)
  if (DirExists(sAbsIntroDir)) {
    hIntrodir = OpenDirectory(sAbsIntroDir)
    if (hIntrodir != INVALID_HANDLE) {
      new String:sCurrfile[MAX_FILE_LEN];
      
      while (ReadDirEntry(hIntrodir, sCurrfile, MAX_FILE_LEN)) {
        new String:sCurrFileWithPath[MAX_FILE_LEN];
        GetConVarString(g_dirPrefix, sCurrFileWithPath, MAX_FILE_LEN);
        if (StrContains(sCurrfile, ".mp3", false) != -1) {
          StrCat(sCurrFileWithPath, MAX_FILE_LEN, sCurrfile)
          strcopy(intros[iFilecount], MAX_FILE_LEN, sCurrFileWithPath);
          iFilecount++;
        }
      }
    }
  }
}

public OnMapStart() 
{
  strcopy(g_soundName, MAX_FILE_LEN, intros[GetRandomInt(0, iFilecount)]);
	decl String:buffer[MAX_FILE_LEN];
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	if (FileExists(buffer)) {
	  AddFileToDownloadsTable(buffer);
	  PrecacheSound(g_soundName, true);
	}
}

public OnClientPostAdminCheck(client)
{
  EmitSoundToClient(client,g_soundName);
  PrintToChat(client, "[KK Intro] intro: \"%s\"", g_soundName);
}