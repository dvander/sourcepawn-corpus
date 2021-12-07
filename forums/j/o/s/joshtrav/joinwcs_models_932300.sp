#include <clientprefs>
#include <sourcemod>
#include <sdktools>


#define PLUGIN_VERSION "0.1a"

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

new Handle:g_TmodelsTrie;
new Handle:g_CTmodelsTrie;
new Handle:g_steamsTrie;
new Handle:hGameConf;
new Handle:hSetModel;
new Handle:g_cookies[cookie_num_cookies];
new String:modelName[17][2][20][100]

public OnPluginStart()
{
    RegServerCmd("sm_reloadmodels", rehash_models)
    
    RegConsoleCmd("sm_models", command_grabber)
    
    g_cookies[cookie_skin_ct] = RegClientCookie("joinwcs_skin_ct", "Counter Terrorist Model Selection", CookieAccess_Protected);
    g_cookies[cookie_skin_t] = RegClientCookie("joinwcs_skin_t", "Terrorist Model Selection", CookieAccess_Protected);
    
    SetCookieMenuItem(model_status, 0, "Models");
    
    Build_Downloads()
    Build_Steams_Trie()
    Build_Models_Trie()
    Build_ModelNames()
    
    hGameConf = LoadGameConfigFile("clientmenu.gamedata")
    
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post)
    
    StartPrepSDKCall(SDKCall_Player)
    PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "SetModel")
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer)
    hSetModel = EndPrepSDKCall()
}

public OnClientCookiesCached(client) 
{
    //testing
}

public OnMapStart()
{
    Build_Downloads()
    Build_ModelNames()
}

public model_terrorist(Handle:modelt, MenuAction:selection, param1, param2)
{
    new client = param1
    if (selection == MenuAction_Select) 
    {
        new String:choice[24]
        GetMenuItem(modelt, param2, choice, sizeof(choice))
        SetClientCookie(client, g_cookies[cookie_skin_t], choice)
        PrintToChat(client, "[joinWCS] - Terrorist model set.")
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
        CloseHandle(modelt)
    }
}

public model_cterrorist(Handle:modelct, MenuAction:selection, param1, param2)
{
    new client = param1
    if (selection == MenuAction_Select) 
    {
        new String:choice[24]
        GetMenuItem(modelct, param2, choice, sizeof(choice))
        SetClientCookie(client, g_cookies[cookie_skin_ct], choice)
        PrintToChat(client, "[joinWCS] - Counter Terrorist model set.")
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
        CloseHandle(modelct)
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
        
        if (StrEqual(choice, "terrorist", false))
        {
            new Handle:modelt = CreateMenu(model_terrorist);
            SetMenuTitle(modelt, "Select Model");
            
            if (status == 16 || status == 24 || status == 20 || status == 18 || status == 26 || status == 22 || status == 30)
            {
                for (new k = 0; k < 20; k++)
                {
                    if (!StrEqual(modelName[16][0][k], "", false))
                    {
                        new String:menuLink[32]
                        Format(menuLink, sizeof(menuLink), "16 0 %d", k)
                        AddMenuItem(modelt, menuLink, modelName[16][0][k])
                    }
                    else
                    {
                        break
                    }
                }
            }
            if (status == 8 || status == 12 || status == 10 || status == 24 || status == 28 || status == 26 || status == 14 || status == 30)
            {
                for (new k = 0; k < 20; k++)
                {
                    if (!StrEqual(modelName[8][0][k], "", false))
                    {
                        new String:menuLink[32]
                        Format(menuLink, sizeof(menuLink), "8 0 %d", k)
                        AddMenuItem(modelt, menuLink, modelName[8][0][k])
                    }
                    else
                    {
                        break
                    }
                }
            }
            if (status == 4 || status == 6 || status == 12 || status == 20 || status == 28 || status == 14 || status == 22 || status == 30)
            {
                for (new k = 0; k < 20; k++)
                {
                    if (!StrEqual(modelName[4][0][k], "", false))
                    {
                        new String:menuLink[32]
                        Format(menuLink, sizeof(menuLink), "4 0 %d", k)
                        AddMenuItem(modelt, menuLink, modelName[4][0][k])
                    }
                    else
                    {
                        break
                    }
                }
            }
            if (status == 2 || status == 6 || status == 10 || status == 18 || status == 22 || status == 26 || status == 30)
            {
                for (new k = 0; k < 20; k++)
                {
                    if (!StrEqual(modelName[2][0][k], "", false))
                    {
                        new String:menuLink[32]
                        Format(menuLink, sizeof(menuLink), "2 0 %d", k)
                        AddMenuItem(modelt, menuLink, modelName[2][0][k])
                    }
                    else
                    {
                        break
                    }
                }
            }
            for (new k = 0; k < 20; k++)
            {
                if (!StrEqual(modelName[0][0][k], "", false))
                {
                    new String:menuLink[32]
                    Format(menuLink, sizeof(menuLink), "0 0 %d", k)
                    AddMenuItem(modelt, menuLink, modelName[0][0][k])
                }
                else
                {
                    break
                }
            }
            AddMenuItem(modelt, "None", "None");
            SetMenuExitBackButton(modelt, true);
            DisplayMenu(modelt, client, MENU_TIME_FOREVER);
        }
        else if (StrEqual(choice, "cterrorist", false))
        {
            new Handle:modelct = CreateMenu(model_cterrorist);
            SetMenuTitle(modelct, "Select Model");
            
            if (status == 16 || status == 24 || status == 20 || status == 18 || status == 26 || status == 22 || status == 30)
            {
                for (new k = 0; k < 20; k++)
                {
                    if (!StrEqual(modelName[16][1][k], "", false))
                    {
                        new String:menuLink[32]
                        Format(menuLink, sizeof(menuLink), "16 1 %d", k)
                        AddMenuItem(modelct, menuLink, modelName[16][1][k])
                    }
                    else
                    {
                        break
                    }
                }
            }
            if (status == 8 || status == 12 || status == 10 || status == 24 || status == 28 || status == 26 || status == 14 || status == 30)
            {
                for (new k = 0; k < 20; k++)
                {
                    if (!StrEqual(modelName[8][1][k], "", false))
                    {
                        new String:menuLink[32]
                        Format(menuLink, sizeof(menuLink), "8 1 %d", k)
                        AddMenuItem(modelct, menuLink, modelName[8][1][k])
                    }
                    else
                    {
                        break
                    }
                }
            }
            if (status == 4 || status == 6 || status == 12 || status == 20 || status == 28 || status == 14 || status == 22 || status == 30)
            {
                for (new k = 0; k < 20; k++)
                {
                    if (!StrEqual(modelName[4][1][k], "", false))
                    {
                        new String:menuLink[32]
                        Format(menuLink, sizeof(menuLink), "4 1 %d", k)
                        AddMenuItem(modelct, menuLink, modelName[4][1][k])
                    }
                    else
                    {
                        break
                    }
                }
            }
            if (status == 2 || status == 6 || status == 10 || status == 18 || status == 22 || status == 26 || status == 30)
            {
                for (new k = 0; k < 20; k++)
                {
                    if (!StrEqual(modelName[2][1][k], "", false))
                    {
                        new String:menuLink[32]
                        Format(menuLink, sizeof(menuLink), "2 1 %d", k)
                        AddMenuItem(modelct, menuLink, modelName[2][1][k])
                    }
                    else
                    {
                        break
                    }
                }
            }
            for (new k = 0; k < 20; k++)
            {
                if (!StrEqual(modelName[0][1][k], "", false))
                {
                    new String:menuLink[32]
                    Format(menuLink, sizeof(menuLink), "0 1 %d", k)
                    AddMenuItem(modelct, menuLink, modelName[0][1][k])
                }
                else
                {
                    break
                }
            }
            AddMenuItem(modelct, "None", "None");
            SetMenuExitBackButton(modelct, true);
            DisplayMenu(modelct, client, MENU_TIME_FOREVER);
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

        AddMenuItem(modelone, "terrorist", "Terrorist")
        AddMenuItem(modelone, "cterrorist", "Counter Terrorist")
        
        SetMenuExitBackButton(modelone, true)
        DisplayMenu(modelone, client, MENU_TIME_FOREVER)
    }
}

public Action:command_grabber(client,args)
{
    ShowCookieMenu(client);
}

Build_Models_Trie()
{
    
    g_TmodelsTrie = CreateTrie();
    ClearTrie(g_TmodelsTrie);
    
    new String: filename[128]
    
    BuildPath(Path_SM, filename, sizeof(filename), "/configs/models/model_list_t.txt")
    if (!FileExists(filename))
    {
        return
    }
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
            new String:name[32], String:path[256]
            strcopy(name, (test + 1), buffer);
            new i, j = 0
            
            for (i = test + 1; i < len; i++)
            {
                path[j] = buffer[i]
                j++
            }
            SetTrieString(g_TmodelsTrie, name, path)
            if (FileExists(path))
            {
                PrecacheModel(path,true)
            }
        }
    }
    CloseHandle(fileopen)
    
    g_CTmodelsTrie = CreateTrie();
    ClearTrie(g_CTmodelsTrie);
    
    BuildPath(Path_SM, filename, sizeof(filename), "/configs/models/model_list_ct.txt")
    if (!FileExists(filename))
    {
        return
    }
    
    fileopen = OpenFile(filename, "r")
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
            new String:name[32], String:path[256]
            strcopy(name, (test + 1), buffer);
            new i, j = 0
            
            for (i = test + 1; i < len; i++)
            {
                path[j] = buffer[i]
                j++
            }
            SetTrieString(g_CTmodelsTrie, name, path)
            if (FileExists(path))
            {
                PrecacheModel(path,true)
            }
        }
    }
    CloseHandle(fileopen)
}

Build_Downloads()
{
    new String: filename[128]
    
    BuildPath(Path_SM, filename, sizeof(filename), "/configs/models/model_downloads.txt")
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
               
            if (FileExists(buffer))
            {
                AddFileToDownloadsTable(buffer)
            }
        }
        CloseHandle(fileopen);
    }
    
    BuildPath(Path_SM, filename, sizeof(filename), "/configs/models/model_list_t.txt")
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
                new String:path[256]
                new i, j = 0
                for (i = test + 1; i < len; i++)
                {
                    path[j] = buffer[i]
                    j++
                }
                if (FileExists(path))
                {
                    PrecacheModel(path,true)
                    AddFileToDownloadsTable(path)
                }
            }
        }
        CloseHandle(fileopen);
    }
    
    BuildPath(Path_SM, filename, sizeof(filename), "/configs/models/model_list_ct.txt")
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
                new String:path[256]
                new i, j = 0
                for (i = test + 1; i < len; i++)
                {
                    path[j] = buffer[i]
                    j++
                }
                if (FileExists(path))
                {
                    PrecacheModel(path,true)
                    AddFileToDownloadsTable(path)
                }
            }
        }
        CloseHandle(fileopen);
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
    else if (team == 1)
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
    new bool:status_check = true
    if (arg1 == 16)
    {
        if (status == 16 || status == 24 || status == 20 || status == 18 || status == 26 || status == 22 || status == 30)
        {
            status_check = true
        }
        else
        {
            status_check = false
        }
    }
    if (arg1 == 8)
    {
        if (status == 8 || status == 12 || status == 10 || status == 24 || status == 28 || status == 26 || status == 14 || status == 30)
        {
            status_check = true
        }
        else
        {
            status_check = false
        }
    }
    if (arg1 == 4)
    {
        if (status == 4 || status == 6 || status == 12 || status == 20 || status == 28 || status == 14 || status == 22 || status == 30)
        {
            status_check = true
        }
        else
        {
            status_check = false
        }
    }
    if (arg1 == 2)
    {
        if (status == 2 || status == 6 || status == 10 || status == 18 || status == 22 || status == 26 || status == 30)
        {
            status_check = true
        }
        else
        {
            status_check = false
        }
    }
    model = modelName[arg1][arg2][arg3]
    if (status_check == false)
    {
        PrintToChat(client, "[joinWCS] - Your access to model file:%s has been removed.", model)
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
    SDKCall(hSetModel, client, path)
    return
}

Clear_ModelNames()
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

Build_ModelNames()
{
    new String: fileSname[128], String: filename[128]
    new Handle:fileopen
    for (new i = 2; i < 17; (i = i * 2))
    {
        Format(fileSname, sizeof(fileSname), "/configs/models/tier_%d_t.txt", i)
        BuildPath(Path_SM, filename, sizeof(filename), fileSname)
        if (!FileExists(filename))
        {
            continue;
        }
        fileopen = OpenFile(filename, "r")
        new String:buffer[256]
        new j = 0
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
                
            new String:name[32]
            strcopy(name, (len + 1), buffer)
            modelName[i][0][j] = name
            j++
        }
        CloseHandle(fileopen)
    }
    
    for (new i = 2; i < 17; (i = i * 2))
    {
        Format(fileSname, sizeof(fileSname), "/configs/models/tier_%d_ct.txt", i)
        BuildPath(Path_SM, filename, sizeof(filename), fileSname)
        if (!FileExists(filename))
        {
            continue;
        }
        fileopen = OpenFile(filename, "r")
        new String:buffer[256]
        new j = 0
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
                
            new String:name[32]
            strcopy(name, (len + 1), buffer)
            modelName[i][1][j] = name
            j++
        }
        CloseHandle(fileopen)
    }
    BuildPath(Path_SM, filename, sizeof(filename), "/configs/models/tier_0_t.txt")
    if (FileExists(filename))
    {
        fileopen = OpenFile(filename, "r")
        new String:buffer[256]
        new j = 0
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
                
            new String:name[32]
            strcopy(name, (len + 1), buffer)
            modelName[0][0][j] = name
            j++
        }
        CloseHandle(fileopen)
    }
    BuildPath(Path_SM, filename, sizeof(filename), "/configs/models/tier_0_ct.txt")
    if (FileExists(filename))
    {
        fileopen = OpenFile(filename, "r")
        new String:buffer[256]
        new j = 0
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
                
            new String:name[32]
            strcopy(name, (len + 1), buffer)
            modelName[0][1][j] = name
            j++
        }
        CloseHandle(fileopen)
    }
}

Build_Steams_Trie()
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
            
            new String:steamid[32], String:value[10]
            strcopy(steamid, (test + 1), buffer);
            
            new i, j = 0
            for (i = test + 1; i < len; i++)
            {
                value[j] = buffer[i]
                j++
            }
            SetTrieValue(g_steamsTrie, steamid, (StringToInt(value)))
        }
        CloseHandle(fileopen)
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