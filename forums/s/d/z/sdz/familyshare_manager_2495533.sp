#include <SteamWorks>
#undef REQUIRE_PLUGIN
#include <updater>
#pragma newdecls required

#define UPDATE_URL "www.coldcommunity.com/dev/plugins/familyshare_manager/update.txt"
#define MAX_STEAMID_LENGTH 21
#define MAX_COMMUNITYID_LENGTH 18 

ConVar g_hCvar_BanMessage;
ConVar g_hCvar_Whitelist;
ConVar g_hCvar_IgnoreAdmins;


char g_sWhitelist[PLATFORM_MAX_PATH];
StringMap g_hWhitelistTrie;
bool g_bParsed;

public Plugin myinfo =
{
    name = "Family Share Manager",
    author = "s (+bonbon, 11530)",
    description = "Whitelist or ban family shared accounts",
    version = "1.5.5",
    url = "www.coldcommunity.com"
};

public void OnPluginStart()
{
    if(LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
        Updater_ForceUpdate();
    }

    g_bParsed = false;
    g_hWhitelistTrie = CreateTrie();
    g_hCvar_BanMessage = CreateConVar("sm_familyshare_banmessage", "Family sharing is disabled.", "Message to display in sourcebans/on ban", FCVAR_NOTIFY);
    g_hCvar_IgnoreAdmins = CreateConVar("sm_familyshare_ignoreadmins", "1", "Check and unblock admins?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvar_Whitelist = CreateConVar("sm_familyshare_whitelist", "familyshare_whitelist.ini", "File to use for whitelist (addons/sourcemod/configs/file)");

    char file[PLATFORM_MAX_PATH]; char filePath[PLATFORM_MAX_PATH];
    g_hCvar_Whitelist.GetString(file, sizeof(file));
    BuildPath(Path_SM, g_sWhitelist, sizeof(g_sWhitelist), "configs/%s", file);
    LogMessage("Built Filepath to: %s", g_sWhitelist);

    BuildPath(Path_SM, filePath, sizeof(filePath), "configs");
    CreateDirectory(filePath, 511);

    AutoExecConfig();
    parseList(false);

    RegAdminCmd("sm_reloadlist", command_reloadWhiteList, ADMFLAG_ROOT, "Reload the whitelist");
    RegAdminCmd("sm_addtolist", command_addToList, ADMFLAG_ROOT, "Add a player to the whitelist");
    RegAdminCmd("sm_removefromlist", command_removeFromList, ADMFLAG_ROOT, "Remove a player from the whitelist");
    RegAdminCmd("sm_displaylist", command_displayList, ADMFLAG_ROOT, "View current whitelist");
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
        Updater_ForceUpdate();
    }
}

public int Updater_OnPluginUpdated()
{
    PrintToServer("Family Share Manager has been updated!");
    ReloadPlugin();
}

public Action command_removeFromList(int client, int args)
{
    File hFile = OpenFile(g_sWhitelist, "a+");

    if(hFile == null)
    {
        LogError("[Family Share Manager] Critical Error: hFile is Invalid. --> command_removeFromList");
        PrintToChat(client, "[Family Share Manager] Plugin has encountered a critial error with the list file.");
        delete hFile;
        return Plugin_Handled;
    }

    if(args == 0)
    {
        PrintToChat(client, "[Family Share Manager] Invalid Syntax: sm_removefromlist <steam id>");
        return Plugin_Handled;
    }

    char steamid[32]; char playerSteam[32];
    GetCmdArgString(playerSteam, sizeof(playerSteam));

    StripQuotes(playerSteam);
    TrimString(playerSteam);
  
    bool found = false;
    ArrayList fileArray = CreateArray(32);

    while(!hFile.EndOfFile() && hFile.ReadLine(steamid, sizeof(steamid)))
    {
        if(strlen(steamid) < 1 || IsCharSpace(steamid[0])) continue;

        ReplaceString(steamid, sizeof(steamid), "\n", "", false);

        PrintToChat(client, "%s - %s", steamid, playerSteam);
        //Not found, add to next file.
        if(!StrEqual(steamid, playerSteam, false))
        {
            fileArray.PushString(steamid);
        }

        //Found, remove from file.
        else
        {
            found = true;
        }
    }

    delete hFile;

    //Delete and rewrite list if found..
    if(found)
    {
        DeleteFile(g_sWhitelist);
        File newFile = OpenFile(g_sWhitelist, "a+");

        if(newFile == null)
        {
            LogError("[Family Share Manager] Critical Error: newFile is Invalid. --> command_removeFromList");
            PrintToChat(client, "[Family Share Manager] Plugin has encountered a critial error with the list file.");
            return Plugin_Handled;
        }

        PrintToChat(client, "[Family Share Manager] Found Steam ID: %s, removing from list...", playerSteam);
        
        LogMessage("Begin rewrite of list..");

        for(int i = 0; i < GetArraySize(fileArray); i++)
        {
            char writeLine[32];
            fileArray.GetString(i, writeLine, sizeof(writeLine));
            newFile.WriteLine(writeLine);
            LogMessage("Wrote %s to list.", writeLine);
        }

        delete newFile;
        delete fileArray;
        parseList(false);
        return Plugin_Handled;
    }
    else PrintToChat(client, "[Family Share Manager] Steam ID: %s not found, no action taken.", playerSteam);
    return Plugin_Handled;
}

public Action command_addToList(int client, int args)
{
    File hFile = OpenFile(g_sWhitelist, "a+");
    
    //Argument Count:
    switch(args)
    {
        //Create Player List:
        case 0:
        {
            Menu playersMenu = new Menu(playerMenuHandle);
            for(int i = 1; i <= MaxClients; i++)
            {
                if(IsClientAuthorized(i) && i != client)
                {
                    playersMenu.SetTitle("Viewing all players...");

                    char formatItem[2][32];
                    Format(formatItem[0], sizeof(formatItem[]), "%i", GetClientUserId(i));
                    Format(formatItem[1], sizeof(formatItem[]), "%N", i);

                    //Adds menu item per player --> Client User ID, Display as Username.
                    playersMenu.AddItem(formatItem[0], formatItem[1]);
                }
            }

            playersMenu.ExitButton = true;
            playersMenu.Pagination = 7;
            playersMenu.Display(client, MENU_TIME_FOREVER);

            PrintToChat(client, "[Family Share Manager] Displaying players menu...");

            delete hFile;
            return Plugin_Handled;
        }

        //Directly write Steam ID:
        default:
        {
            char steamid[32];
            GetCmdArgString(steamid, sizeof(steamid));

            StripQuotes(steamid);
            TrimString(steamid);

            if(StrContains(steamid, "STEAM_", false) == -1)
            {
                PrintToChat(client, "[Family Share Manager] Invalid Input - Not a Steam 2 ID. (STEAM_0:X:XXXX)");
                delete hFile;
                return Plugin_Handled;
            }

            if(hFile == INVALID_HANDLE)
            {
                LogError("[Family Share Manager] Critical Error: hFile is Invalid. --> command_addToList");
                PrintToChat(client, "[Family Share Manager] Plugin has encountered a critial error with the list file.");
                delete hFile;
                return Plugin_Handled;
            }

            hFile.WriteLine(steamid);
            PrintToChat(client, "[Family Share Manager] Successfully added %s to the list.", steamid);
            delete hFile;
            parseList(false);
            return Plugin_Handled;
        }
    }
}

public int playerMenuHandle(Menu playerMenu, MenuAction action, int client, int menuItem)
{
    if(action == MenuAction_Select) 
    {   
        //Should be our Client's User ID.
        char menuItems[32]; 
        playerMenu.GetItem(menuItem, menuItems, sizeof(menuItems));

        int target = GetClientOfUserId(StringToInt(menuItems));
        
        //Invalid UserID/Client Index:
        if(!target)
        {
            LogError("[Family Share Manager] Critical Error: Invalid Client of User Id --> playerMenuHandle");
            delete playerMenu;
            return;
        }

        char steamid[32];
        GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));

        StripQuotes(steamid);
        TrimString(steamid);

        if(StrContains(steamid, "STEAM_", false) == -1)
        {
            PrintToChat(client, "[Family Share Manager] Invalid Input - Not a Steam 2 ID. (STEAM_0:X:XXXX)");
            return;
        }

        File hFile = OpenFile(g_sWhitelist, "a+");
        if(hFile == null)
        {
            LogError("[Family Share Manager] Critical Error: hFile is Invalid. --> playerMenuHandle");
            PrintToChat(client, "[Family Share Manager] Plugin has encountered a critial error with the list file.");
            delete hFile;
            return;
        }

        hFile.WriteLine(steamid);
        PrintToChat(client, "[Family Share Manager] Successfully added %s (%N) to the list.", steamid, target);
        delete hFile;
        parseList(false);
        return;
    }

    else if(action == MenuAction_End)
    {
        delete playerMenu;
    }
}

public Action command_displayList(int client, int args)
{
    char auth[32];
    File hFile = OpenFile(g_sWhitelist, "a+");

    while(!hFile.EndOfFile() && hFile.ReadLine(auth, sizeof(auth)))
    {
        TrimString(auth);
        StripQuotes(auth);

        if(strlen(auth) < 1) continue;
        ReplaceString(auth, sizeof(auth), "\n", "", false);

        if(StrContains(auth, "STEAM_", false) != -1)
        {
            if(!client) return Plugin_Handled;
            PrintToChat(client, "%s", auth); 
        }
    }

    delete hFile;
    return Plugin_Handled;
}

public Action command_reloadWhiteList(int client, int args)
{
    PrintToChat(client, "[Family Share Manager] Rebuilding whitelist...");
    parseList(true, client);
    return Plugin_Handled;
}

void parseList(bool rebuild, int client = 0)
{
    char auth[32];
    File hFile = OpenFile(g_sWhitelist, "a+");
    LogMessage("Begin parseList()");

    while(!hFile.EndOfFile() && hFile.ReadLine(auth, sizeof(auth)))
    {
        TrimString(auth);
        StripQuotes(auth);

        if(strlen(auth) < 1) continue;

        if(StrContains(auth, "STEAM_", false) != -1)
        {
            g_hWhitelistTrie.SetString(auth, auth, true);
            LogMessage("Added %s to whitelist", auth);
        }
    }

    LogMessage("End parseList()");
    if(rebuild && client) PrintToChat(client, "[Family Share Manager] Rebuild complete!");
    g_bParsed = true;
    delete hFile;
}

public void OnClientPostAdminCheck(int client)
{
    bool whiteListed = false;
    if(g_bParsed)
    {
        char auth[2][64];
        GetClientAuthId(client, AuthId_Steam2, auth[0], sizeof(auth[]));
        whiteListed = g_hWhitelistTrie.GetString(auth[0], auth[1], sizeof(auth[]));
        if(whiteListed)
        {
            LogMessage("Whitelist found player: %N", client);
            return;
        }
    }

    if(CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC) && g_hCvar_IgnoreAdmins.IntValue > 0)
    {
        return;
    }
}

stock int GetClientOfAuthId(int authid)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i))
        {
            char steamid[32]; GetClientAuthId(i, AuthId_Steam3, steamid, sizeof(steamid));
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

public int SteamWorks_OnValidateClient(int ownerauthid, int authid)
{
    int client = GetClientOfAuthId(authid);
    if(ownerauthid != authid)
    {
        char banMessage[PLATFORM_MAX_PATH]; g_hCvar_BanMessage.GetString(banMessage, sizeof(banMessage));
        KickClient(client, banMessage);
    }

    /*
    //Now using SteamWorks:
    EUserHasLicenseForAppResult result = SteamWorks_HasLicenseForApp(client, g_hCvar_AppId.IntValue);

    //Debug text: PrintToServer("Client %N License Value: %i", client, view_as<int>(result));

    //No License, kick em:
    if(result > k_EUserHasLicenseResultHasLicense)
    {
        char banMessage[PLATFORM_MAX_PATH]; g_hCvar_BanMessage.GetString(banMessage, sizeof(banMessage));
        KickClient(client, banMessage);
    }
    */
}