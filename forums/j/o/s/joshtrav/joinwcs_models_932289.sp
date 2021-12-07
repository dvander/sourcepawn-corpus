#include <clientprefs>
#include <sourcemod>
#include <sdktools>


#define PLUGIN_VERSION "1.02"

#define cookie_skin_ct      0
#define cookie_skin_t       1
#define cookie_num_cookies  2

public Plugin:myinfo = 
{
	name = "joinWCS model",
	author = "JT",
	description = "Model Management",
	version = PLUGIN_VERSION,
	url = "http://www.joinwcs.com/"
}

new Handle:g_TmodelsTrie
new Handle:g_CTmodelsTrie
new Handle:g_steamsTrie
new Handle:g_cookies[cookie_num_cookies]
new String:modelName[17][2][20][100]
new String:g_gametype[32]
new String:g_teamname[2][32]
public OnPluginStart()
{
    RegServerCmd("sm_reloadmodels", rehash_models)
    
    RegConsoleCmd("sm_models", command_grabber)
    
    g_cookies[cookie_skin_ct] = RegClientCookie("joinwcs_skin_ct", "Team2 Model Selection", CookieAccess_Protected);
    g_cookies[cookie_skin_t] = RegClientCookie("joinwcs_skin_t", "Team1 Selection", CookieAccess_Protected);
    
    SetCookieMenuItem(model_status, 0, "Models");
        
    new g_gamefolder = GetGame()
    if (g_gamefolder == 1)
    {
        g_gametype = "css"
        g_teamname[0] = "Terrorist"
        g_teamname[1] = "Counter Terrorist"
        HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post)
    }
    else if (g_gamefolder == 2)
    {
        g_gametype = "dods"
        g_teamname[0] = "U.S. Army"
        g_teamname[1] = "Wehrmacht"
        HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post)
    }
    else
    {
        LogError("Game not supported")
    }
    
    Build_Configs()
    //Build_Downloads()
    Build_Steams_Trie()
    Build_Models_Trie()
    Build_ModelNames()
}

public OnClientCookiesCached(client) 
{
    //testing
}

public OnMapStart()
{
    Build_Downloads()
    //Build_ModelNames()
}

public model_team1(Handle:model_team1_menu, MenuAction:selection, param1, param2)
{
    new client = param1
    if (selection == MenuAction_Select) 
    {
        new String:choice[24]
        GetMenuItem(model_team1_menu, param2, choice, sizeof(choice))
        SetClientCookie(client, g_cookies[cookie_skin_t], choice)
        PrintToChat(client, "\x04[joinWCS] \x01- \x03%s \x01model set.", g_teamname[0])
    }
    else if (selection == MenuAction_Cancel) 
    {
        if (param2 == MenuCancel_ExitBack)
        {
            ShowCookieMenu(client)
        }
    }
    else if (selection == MenuAction_End)
    {
        CloseHandle(model_team1_menu)
    }
}

public model_team2(Handle:model_team2_menu, MenuAction:selection, param1, param2)
{
    new client = param1
    if (selection == MenuAction_Select) 
    {
        new String:choice[24]
        GetMenuItem(model_team2_menu, param2, choice, sizeof(choice))
        SetClientCookie(client, g_cookies[cookie_skin_ct], choice)
        PrintToChat(client, "\x04[joinWCS] \x01- \x03%s \x01model set.", g_teamname[1])
    }
    else if (selection == MenuAction_Cancel) 
    {
        if (param2 == MenuCancel_ExitBack)
        {
            ShowCookieMenu(client)
        }
    }
    else if (selection == MenuAction_End)
    {
        CloseHandle(model_team2_menu)
    } 
}

public model_teamselect(Handle:modelone, MenuAction:selection, param1, param2)
{
    new client = param1;
    if (selection == MenuAction_Select) 
    {
        new String:choice[24];
        GetMenuItem(modelone, param2, choice, sizeof(choice))
        
        new String:steamid[64], status
        GetClientAuthString(client, steamid, 64)
        GetTrieValue(g_steamsTrie, steamid, status)
        
        if (StrEqual(choice, "team1", false))
        {
            new Handle:model_team1_menu = CreateMenu(model_team1);
            SetMenuTitle(model_team1_menu, "Select Model");
            
            for (new i = 16; i > 0; (i = i / 2))
            {
                if (i == 1)
                {
                    i = 0
                }
                if (HasStatus(i, status))
                {
                    for (new k = 0; k < 20; k++)
                    {
                        if (!StrEqual(modelName[i][0][k], "", false))
                        {
                            new String:menulink[32]
                            TrimString(modelName[i][0][k])
                            Format(menulink, sizeof(menulink), "%d 0 %d", i, k)
                            AddMenuItem(model_team1_menu, menulink, modelName[i][0][k])
                        }
                        else
                        {
                            break
                        }
                    }
                }
            }
            AddMenuItem(model_team1_menu, "None", "None");
            SetMenuExitBackButton(model_team1_menu, true);
            DisplayMenu(model_team1_menu, client, MENU_TIME_FOREVER);
        }
        else if (StrEqual(choice, "team2", false))
        {
            new Handle:model_team2_menu = CreateMenu(model_team2);
            SetMenuTitle(model_team2_menu, "Select Model");
            
            for (new i = 16; i > 0; (i = i / 2))
            {
                if (i == 1)
                {
                    i = 0
                }
                if (HasStatus(i, status))
                {
                    for (new k = 0; k < 20; k++)
                    {
                        if (!StrEqual(modelName[i][1][k], "", false))
                        {
                            new String:menulink[32]
                            TrimString(modelName[i][1][k])
                            Format(menulink, sizeof(menulink), "%d 1 %d", i, k)
                            AddMenuItem(model_team2_menu, menulink, modelName[i][1][k])
                        }
                        else
                        {
                            break
                        }
                    }
                }
            }
            AddMenuItem(model_team2_menu, "None", "None");
            SetMenuExitBackButton(model_team2_menu, true);
            DisplayMenu(model_team2_menu, client, MENU_TIME_FOREVER);
        }
    }
    else if (selection == MenuAction_Cancel) 
    {
        if (param2 == MenuCancel_ExitBack)
        {
            ShowCookieMenu(client);
        }
    }
    else if (selection == MenuAction_End)
    {
        CloseHandle(modelone);
    } 
}

public model_status(client, CookieMenuAction:selection, any:info, String:buffer[], maxlen)
{
    if (selection == CookieMenuAction_DisplayOption)
    {
        //don't think we need to do anything
    }
    else
    {
        new Handle:modelone = CreateMenu(model_teamselect)
        SetMenuTitle(modelone, "Select Team")

        AddMenuItem(modelone, "team1", g_teamname[0])
        AddMenuItem(modelone, "team2", g_teamname[1])
        
        SetMenuExitBackButton(modelone, true)
        DisplayMenu(modelone, client, MENU_TIME_FOREVER)
    }
}

public Action:command_grabber(client,args)
{
    ShowCookieMenu(client)
}

stock Build_Models_Trie()
{
    g_TmodelsTrie = CreateTrie()
    g_CTmodelsTrie = CreateTrie()
    ClearTrie(g_TmodelsTrie)
    ClearTrie(g_CTmodelsTrie)
    for (new i = 0; i < 2; i++)
    {
        new String: longname[128]
        Format(longname, sizeof(longname), "/configs/models/model_team%d.txt", (i + 1))
        new String: filename[128]
        BuildPath(Path_SM, filename, sizeof(filename), longname)
        if (FileExists(filename))
        {
            new Handle:fileopen = OpenFile(filename, "r")
            new String:buffer[256]
            while (!IsEndOfFile(fileopen) && ReadFileLine(fileopen, buffer, sizeof(buffer)))
            {
                if(HasComment(buffer))
                {
                    new String:buffer2[256]
                    SplitString(buffer, "//", buffer2, 256)
                    if (!strlen(buffer2))
                    {
                        continue
                    }
                    buffer = buffer2
                }
                new len = strlen(buffer)
                if (buffer[len-1] == '\n')
                {
                    buffer[--len] = '\0'
                }    
                new test = StrContains(buffer, "$")
                if (test != -1)
                {
                    new String:buffers[2][256]
                    ExplodeString(buffer, "$", buffers, 2, 256)
                    for (new j = 0; j < 2; j++)
                    {
                        TrimString(buffers[j])
                    }
                    if (i == 0)
                    {
                        SetTrieString(g_TmodelsTrie, buffers[0], buffers[1])
                    }
                    else if (i == 1)
                    {
                        SetTrieString(g_CTmodelsTrie, buffers[0], buffers[1])
                    }
                    if (FileExists(buffers[1]))
                    {
                        PrecacheModel(buffers[1],true)
                    }
                    else
                    {
                        LogError("$$%s$$ does not exist", buffers[1])
                    }
                }
            }
            CloseHandle(fileopen)
        }
        else
        {
            LogError("model_team%d does not exist", (i + 1))
        }
    }
}

Build_Downloads()
{
    for (new i = 0; i < 3; i++)
    {
        new String: shortname[128], String: longname[128]
        if (i == 0)
        {
            shortname = "model_team1.txt"
        }
        else if (i == 1)
        {
            shortname = "model_team2.txt"
        }
        else if (i == 2)
        {
            shortname = "model_downloads.txt"
        }

        Format(longname, sizeof(longname), "/configs/models/%s", shortname)
        new String: filename[128]
        BuildPath(Path_SM, filename, sizeof(filename), longname)
        if (FileExists(filename))
        {
            new Handle:fileopen = OpenFile(filename, "r")
            new String:buffer[256]
    
            while (!IsEndOfFile(fileopen) && ReadFileLine(fileopen, buffer, sizeof(buffer)))
            {
                if(HasComment(buffer))
                {
                    new String:buffer2[256]
                    SplitString(buffer, "//", buffer2, 256)
                    if (!strlen(buffer2))
                    {
                        continue
                    }
                    buffer = buffer2
                }
            
                new len = strlen(buffer)
                if (buffer[len-1] == '\n')
                    buffer[--len] = '\0'
               
                if (i < 2)
                {
                    new String:buffers[2][256]
                    ExplodeString(buffer, "$", buffers, 2, 256)
                    for (new j = 0; j < 2; j++)
                    {
                        TrimString(buffers[j])
                    }
                    if (FileExists(buffers[1]))
                    {
                        PrecacheModel(buffers[1],true)
                    }
                    buffer = buffers[1]
                }
                else
                {
                    TrimString(buffer)
                }
                if (FileExists(buffer))
                {
                    AddFileToDownloadsTable(buffer)
                }
                else
                {
                    LogError("%s does not exist", buffer)
                }
            }
            CloseHandle(fileopen);
        }
        else
        {
            LogError("%s does not exist", shortname)
        }
    }
}
    
public Action:rehash_models(args)
{
    Build_Models_Trie()
    Build_Steams_Trie()
    Clear_ModelNames()
    Build_ModelNames()
    Build_Downloads()
    LogMessage("Models Reloaded")
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(event, "userid")
    new client = GetClientOfUserId(userid)
    
    new String:steamid[64], String:path[128], status
    new team = GetClientTeam(client)
    GetClientAuthString(client, steamid, 64); 
    GetTrieValue(g_steamsTrie, steamid, status)
    
    decl String:value[100];
    
    if (team == 2)
    {    
        GetClientCookie(client, g_cookies[cookie_skin_t], value, sizeof(value))
    }
    else if (team == 3)
    {
        GetClientCookie(client, g_cookies[cookie_skin_ct], value, sizeof(value))
    }
    else
    {
        return
    }
    if (StrEqual(value,"0") || StrEqual(value,"") || StrEqual(value,"None"))
    {
        return
    }
    
    new String:buffers[3][3], String:model[100]
    ExplodeString(value, " ", buffers, 3, 3)
    new arg1 = StringToInt(buffers[0])
    new arg2 = StringToInt(buffers[1])
    new arg3 = StringToInt(buffers[2])
    new bool:status_check
    if (arg1 > 0)
    {
        status_check = HasStatus(arg1, status)
    }
    else
    {
        status_check = true
    }
    
    model = modelName[arg1][arg2][arg3]

    if (status_check == false)
    {
        PrintToChat(client, "\x04[joinWCS] \x01- Access to model:\x03 %s \x01has been removed.", model)
        if (team == 2)
        {
            SetClientCookie(client, g_cookies[cookie_skin_t], "None")
        }
        else if (team == 3)
        {
            SetClientCookie(client, g_cookies[cookie_skin_ct], "None")
        }
        return
    }
    
    if (team == 2)
    {
        if (!GetTrieString(g_TmodelsTrie, model, path, 128))
        {    
            return
        }
    }
    else if (team == 3)
    {
        if (!GetTrieString(g_CTmodelsTrie, model, path, 128))
        {    
            return
        }
    }
    else
    {
        return
    }
    if (!FileExists(path))
    {
        LogError("File: %s, does not exist", path)
        PrintToChat(client, "[joinWCS] - Model file:%s does not exist.  Report to admin please.", model)
        return
    }
    if (!IsModelPrecached(path))
    {
        PrecacheModel(path)
    }
    SetEntityModel(client, path)
    return
}

stock Clear_ModelNames()
{
    for (new i = 0; i < 17; i++)
    {
        for (new j = 0; j < 2; j++)
        {
            for (new k = 0; k < 20; k++)
            {
                for (new l = 0; l < 100; l++)
                {
                    modelName[i][j][k][l] = 0
                }
            }
        }
    }
}

stock Build_ModelNames()
{
    for (new i = 0; i < 2; i++)
    {
        new String: shortname[128], String: longname[128]
        if (i == 0)
        {
            shortname = "tier_team1.txt"
        }
        else if (i == 1)
        {
            shortname = "tier_team2.txt"
        }

        Format(longname, sizeof(longname), "/configs/models/%s", shortname)
        new String: filename[128]
        BuildPath(Path_SM, filename, sizeof(filename), longname)
        if (FileExists(filename))
        {
            new Handle:fileopen = OpenFile(filename, "r")
            new String:buffer[256]
    
            while (!IsEndOfFile(fileopen) && ReadFileLine(fileopen, buffer, sizeof(buffer)))
            {
                if(HasComment(buffer))
                {
                    new String:buffer2[256]
                    SplitString(buffer, "//", buffer2, 256)
                    if (!strlen(buffer2))
                    {
                        continue
                    }
                    buffer = buffer2
                }
            
                new len = strlen(buffer)
                if (buffer[len-1] == '\n')
                {
                    buffer[--len] = '\0'
                } 
                
                new String:buffers[2][100]
                ExplodeString(buffer, "$", buffers, 2, 100)
                for (new j = 0; j < 2; j++)
                {
                    TrimString(buffers[j])
                }
                new value = StringToInt(buffers[1])
                for (new k = 0; k < 20; k++)
                {
                    if (StrEqual(modelName[value][i][k], "", false) || StrEqual(modelName[value][i][k], "0", false))
                    {
                        modelName[value][i][k] = buffers[0]
                        LogMessage("tier: %d, team: %d, slot: %d", value, i, k)
                        break
                    }
                }
            }
            CloseHandle(fileopen)
        }
        else
        {
            LogError("%s does not exist", shortname)
        }
    }
}



stock Build_Steams_Trie()
{
    g_steamsTrie = CreateTrie()
    ClearTrie(g_steamsTrie)
    
    new String: filename[128]
    BuildPath(Path_SM, filename, sizeof(filename), "/configs/models/user_access.txt")
    if (FileExists(filename))
    {
        new Handle:fileopen = OpenFile(filename, "r")
        new String:buffer[256]
        while (!IsEndOfFile(fileopen) && ReadFileLine(fileopen, buffer, sizeof(buffer)))
        {
            if(HasComment(buffer))
            {
                new String:buffer2[256]
                SplitString(buffer, "//", buffer2, 256)
                if (!strlen(buffer2))
                {
                    continue
                }
                buffer = buffer2
            }
            new len = strlen(buffer)
            if (buffer[len-1] == '\n')
            {
                buffer[--len] = '\0'
            }       
            new test = StrContains(buffer, "$")
            if (test == -1)
            {
                continue
            }
            new String:buffers[2][256]
            ExplodeString(buffer, "$", buffers, 2, 256)
            for (new j = 0; j < 2; j++)
            {
                TrimString(buffers[j])
            }
            new value
            value = StringToInt(buffers[1])
            SetTrieValue(g_steamsTrie, buffers[0], value)
        }
        CloseHandle(fileopen)
    }
    else
    {
        LogError("User_access.txt does not exist")
    }
}

bool:HasComment(const String:buffer[256])
{
    new test = StrContains(buffer, "//")
    if (test == -1)
    {
        return false
    }
    return true
}

bool:HasStatus(const value, const status)
{
    switch(value)
    {
        case 16:
        {
            if (status == 16 || status == 24 || status == 20 || status == 18 || status == 26 || status == 22 || status == 30)
            {
                return true
            }
            else
            {
                return false
            }
        }
        case 8:
        {
            if (status == 8 || status == 12 || status == 10 || status == 24 || status == 28 || status == 26 || status == 14 || status == 30)
            {
                return true
            }   
            else
            {
                return false
            }
        }
        case 4:
        {
            if (status == 4 || status == 6 || status == 12 || status == 20 || status == 28 || status == 14 || status == 22 || status == 30)
            {
                return true
            }
            else
            {
                return false
            }
        }
        case 2:
        {
            if (status == 2 || status == 6 || status == 10 || status == 18 || status == 14 || status == 22 || status == 26 || status == 30)
            {
                return true
            }
            else
            {
                return false
            }
        }
        case 0:
        {
            return true
        }
    }
    return false
}

stock GetGame()
{
    new String:gfolder[128]
    GetGameFolderName(gfolder, sizeof(gfolder))

    if (StrEqual(gfolder, "cstrike", false))
    {
        return 1
    }
    else if (StrEqual(gfolder, "dod", false))
    {
        return 2
    }
    else
    {
        return 0
    }
}

stock Build_Configs()
{
    new String: file_tier_team1[128], String: file_tier_team2[128]
    new String: file_model_team1[128], String: file_model_team2[128]
    new String: file_new_model_team1[128], String: file_new_model_team2[128]
    BuildPath(Path_SM, file_model_team1, sizeof(file_model_team1), "/configs/models/model_list_t.txt")
    BuildPath(Path_SM, file_model_team2, sizeof(file_model_team2), "/configs/models/model_list_ct.txt")
    BuildPath(Path_SM, file_new_model_team1, sizeof(file_new_model_team1), "/configs/models/model_team1.txt")
    BuildPath(Path_SM, file_new_model_team2, sizeof(file_new_model_team2), "/configs/models/model_team2.txt")
    BuildPath(Path_SM, file_tier_team1, sizeof(file_tier_team1), "/configs/models/tier_team1.txt")
    BuildPath(Path_SM, file_tier_team2, sizeof(file_tier_team2), "/configs/models/tier_team2.txt")
    
    if (!FileExists(file_tier_team1))
    {
        new Handle:fileopen = OpenFile(file_tier_team1, "w")
        CloseHandle(fileopen)
        
        fileopen = OpenFile(file_tier_team1, "a")
        WriteFileLine(fileopen,"//All team1 models and tier levels go in this file.")
        WriteFileLine(fileopen,"//This is Terrorist/U.S. Army selections.")
        WriteFileLine(fileopen,"//This file has been created automatically for you and old configs have been added to it.")
        WriteFileLine(fileopen,"//Include the tier of a specific model in the line seperated by a $.")
        WriteFileLine(fileopen,"//Model1 Name Here$16")
        WriteFileLine(fileopen,"//Model2 Name Here$8")
        WriteFileLine(fileopen,"//Model3 Name Here$4")
        WriteFileLine(fileopen,"//Model4 Name Here$2")
        WriteFileLine(fileopen,"//Model5 Name Here$0")
        
        for (new i = 16; i > 0; (i = i / 2))
        {
            if (i == 1)
            {
                i = 0
            }
            new String: longname[128], String: path[128]
            Format(longname, sizeof(longname), "/configs/models/tier_%d_t.txt", i)
            BuildPath(Path_SM, path, sizeof(path), longname)
            if (FileExists(path))
            {
                LogMessage("%s exists", path)
                new Handle:oldfileopen = OpenFile(path, "r")
                new String:buffer[256]
                while (!IsEndOfFile(oldfileopen) && ReadFileLine(oldfileopen, buffer, sizeof(buffer)))
                {
                    if(HasComment(buffer))
                    {
                        new String:buffer2[256]
                        SplitString(buffer, "//", buffer2, 256)
                        if (!strlen(buffer2))
                        {
                            continue
                        }
                        buffer = buffer2
                    }
            
                    new len = strlen(buffer)
                    if (buffer[len-1] == '\n')
                    {
                        buffer[--len] = '\0'
                    }
                    TrimString(buffer)
                    new String: buffer2[256]
                    Format(buffer2, sizeof(buffer2), "%s$%d", buffer,i)
                    WriteFileLine(fileopen, buffer2)
                }
                CloseHandle(oldfileopen)
                DeleteFile(path)
            }
        }
        CloseHandle(fileopen)
    }
    
    if (!FileExists(file_tier_team2))
    {
        new Handle:fileopen = OpenFile(file_tier_team2, "w")
        CloseHandle(fileopen)
        
        fileopen = OpenFile(file_tier_team2, "a")
        WriteFileLine(fileopen,"//All team2 models and tier levels go in this file.")
        WriteFileLine(fileopen,"//This is Counter Terrorist/Wehrmacht selections.")
        WriteFileLine(fileopen,"//This file has been created automatically for you and old configs have been added to it.")
        WriteFileLine(fileopen,"//Include the tier of a specific model in the line seperated by a $.")
        WriteFileLine(fileopen,"//Model1 Name Here$16")
        WriteFileLine(fileopen,"//Model2 Name Here$8")
        WriteFileLine(fileopen,"//Model3 Name Here$4")
        WriteFileLine(fileopen,"//Model4 Name Here$2")
        WriteFileLine(fileopen,"//Model5 Name Here$0")
        
        for (new i = 16; i > 0; (i = i / 2))
        {
            if (i == 1)
            {
                i = 0
            }
            new String: longname[128], String: path[128]
            Format(longname, sizeof(longname), "/configs/models/tier_%d_ct.txt", i)
            BuildPath(Path_SM, path, sizeof(path), longname)
            if (FileExists(path))
            {
                new Handle:oldfileopen = OpenFile(path, "r")
                new String:buffer[256]
                while (!IsEndOfFile(oldfileopen) && ReadFileLine(oldfileopen, buffer, sizeof(buffer)))
                {
                    if(HasComment(buffer))
                    {
                        new String:buffer2[256]
                        SplitString(buffer, "//", buffer2, 256)
                        if (!strlen(buffer2))
                        {
                            continue
                        }
                        buffer = buffer2
                    }
            
                    new len = strlen(buffer)
                    if (buffer[len-1] == '\n')
                    {
                        buffer[--len] = '\0'
                    }
                    TrimString(buffer)
                    new String: buffer2[256]
                    Format(buffer2, sizeof(buffer2), "%s$%d", buffer,i)
                    WriteFileLine(fileopen, buffer2)
                }
                CloseHandle(oldfileopen)
                DeleteFile(path)
            }
        }
        CloseHandle(fileopen)
    }
    if (FileExists(file_model_team1))
    {
        RenameFile(file_new_model_team1, file_model_team1)
    }
    if (FileExists(file_model_team2))
    {
        RenameFile(file_new_model_team2, file_model_team2)
    }
}
                    
