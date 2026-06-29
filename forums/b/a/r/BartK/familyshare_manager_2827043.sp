#include <SteamWorks>

ConVar g_hCvar_BanMessage;
ConVar g_hCvar_Whitelist;
ConVar g_hCvar_IgnoreAdmins;

char g_sWhitelist[PLATFORM_MAX_PATH];
StringMap g_hWhitelistTrie;

public Plugin myinfo = {name = "HL2DM Family Share Manager", author = "s (+bonbon, 11530) & Bart",
                 description = "Whitelist or ban family shared accounts",
                 version = "2.0", url = ""};

public void OnPluginStart() {

  g_hWhitelistTrie = CreateTrie();
  g_hCvar_BanMessage = CreateConVar("sm_familyshare_banmessage", "Family sharing is disabled.", "Message to display in sourcebans/on ban", FCVAR_NOTIFY);
  g_hCvar_Whitelist = CreateConVar("sm_familyshare_whitelist", "familyshare_whitelist.ini", "File to use for whitelist (addons/sourcemod/configs/file)");

  char file[PLATFORM_MAX_PATH];
  char filePath[PLATFORM_MAX_PATH];
  g_hCvar_Whitelist.GetString(file, sizeof(file));
  BuildPath(Path_SM, g_sWhitelist, sizeof(g_sWhitelist), "configs/%s", file);
  LogMessage("Built Filepath to: %s", g_sWhitelist);

  BuildPath(Path_SM, filePath, sizeof(filePath), "configs");
  CreateDirectory(filePath, 511);

  AutoExecConfig();
  parseList(false);
}

void parseList(bool rebuild, int client = 0) {
  char auth[32];
  File hFile = OpenFile(g_sWhitelist, "a+");
  LogMessage("Begin parseList()");

  while (!hFile.EndOfFile() && hFile.ReadLine(auth, sizeof(auth))) {
    TrimString(auth);
    StripQuotes(auth);

    if (strlen(auth) < 1)
      continue;

    if (StrContains(auth, "[U", false) != -1) {
      g_hWhitelistTrie.SetString(auth, auth, true); // key, value, replace
      LogMessage("Added %s to whitelist", auth);
    }
  }

  LogMessage("End parseList()");
  if (rebuild && client)
    PrintToChat(client, "[Family Share Manager] Rebuild complete!");
  delete hFile;
}

stock int GetClientOfAuthId(int authid)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i))
        {
            char steamid[32];
		        GetClientAuthId(i, AuthId_Steam3, steamid, sizeof(steamid));
			
            char split[3][32];
            ExplodeString(steamid, ":", split, sizeof(split), sizeof(split[]));
            ReplaceString(split[2], sizeof(split[]), "]", "");
            //Split 1: [U:
            //Split 2: 1:
            //Split 3: 12345]
            
            int auth = StringToInt(split[2]);
            if(auth == authid) return i;
        }
    }

    return -1;
}

bool checkUserWhithlisted(char[] userSteamId){  
    return g_hWhitelistTrie.ContainsKey(userSteamId);
}

public void SteamWorks_OnValidateClient(int ownerauthid, int authid) {
  int client = GetClientOfAuthId(authid);

  char userSteamID[64];
  GetClientAuthId(client, AuthId_Steam3, userSteamID, sizeof(userSteamID));

  if (ownerauthid != authid && !checkUserWhithlisted(userSteamID)) {
    char banMessage[PLATFORM_MAX_PATH];
    g_hCvar_BanMessage.GetString(banMessage, sizeof(banMessage));
    KickClient(client, banMessage);
  }


}