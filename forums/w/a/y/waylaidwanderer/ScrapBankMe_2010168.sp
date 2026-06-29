#pragma semicolon 1

#include <sourcemod>
#include <steamtools>
#include <json>
#include <morecolors>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION  "1.5.0"
#define UPDATE_URL      "http://scrapbank.me/plugins/update.txt"

new Handle:adTimer = INVALID_HANDLE;
new Handle:checkQueueTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:cvar_enabled = INVALID_HANDLE;
new Handle:cvar_ad_timer = INVALID_HANDLE;
new Handle:cvar_private_key = INVALID_HANDLE;
new Handle:cvar_public_key = INVALID_HANDLE;
new Handle:cvar_additional_server_owners = INVALID_HANDLE;
new Handle:cvar_access_flag = INVALID_HANDLE;

new Handle:cvar_updater;
new Handle:cvar_tag;
new Handle:sv_tags;

new lastPosition[MAXPLAYERS+1] = 0;
new checkingQueue[MAXPLAYERS+1] = false;
new enabled = true;

public Plugin:myinfo = 
{
    name = "ScrapBank.Me - Automatic TF2 Banking Plugin",
    author = "waylaidwanderer",
    description = "Automated scrapbanking/hatbanking/keybanking/itembanking via ScrapBank.Me bots. Does not require HTML MOTD.",
    version = PLUGIN_VERSION,
    url = "http://scrapbank.me"
}

public OnPluginStart()
{
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }

    RegConsoleCmd("sm_bank", Command_Bank);
    RegConsoleCmd("sm_bank_remove", Command_Remove);
    RegConsoleCmd("sm_bank_get", Command_GetQueue);
    RegConsoleCmd("sm_bank_donate", Command_Donate);
    RegConsoleCmd("sm_bank_help", Command_BankHelp);

    cvar_enabled = CreateConVar("sbm_enabled", "1", "Enable (1) or disable (0) the plugin.", FCVAR_NOTIFY);
    cvar_updater = CreateConVar("sbm_auto_update", "1", "Enables automatic updating (has no effect if Updater is not installed)");
    cvar_ad_timer = CreateConVar("sbm_ad_time", "120", "Show ad notifying users of the plugin every X seconds. 0 to disable.", 0, true, 0.0, true, 300.0);    
    cvar_tag = CreateConVar("sbm_add_tag", "1", "If 1, Adds the scrapbank.me tag to your server's sv_tags, which is required to be listed on http://scrapbank.me/servers/", _, true, 0.0, true, 1.0);    
    cvar_public_key = CreateConVar("sbm_public_key", "", "Your public API key obtained from http://scrapbank.me/api/", FCVAR_PROTECTED);
    cvar_private_key = CreateConVar("sbm_private_key", "", "Your private API key obtained from http://scrapbank.me/api/", FCVAR_PROTECTED);
    cvar_additional_server_owners = CreateConVar("sbm_additional_server_owners", "", "SteamID64s of additional server owners, separated by a comma. Max of 2 SteamID64s.", FCVAR_PROTECTED);
    cvar_access_flag = CreateConVar("sbm_access_flag", "", "Specify which Admin Flag is required to use the plugin. Leave blank for everyone to use.");
    HookConVarChange(cvar_updater, Callback_VersionConVarChanged); // For purposes of removing the "A" if updater is disabled
    AutoExecConfig(true, "ScrapBankMe");

    sv_tags = FindConVar("sv_tags");
    
    new Float:adTime = GetConVarFloat(cvar_ad_timer);
    adTimer = CreateTimer(adTime, Ad, _, TIMER_REPEAT);
    
    HookConVarChange(cvar_access_flag, hook_access_flag);
    HookConVarChange(cvar_ad_timer, hook_ad);
    HookConVarChange(cvar_enabled, hook_enabled);
}

public OnAllPluginsLoaded() {
    new Handle:convar;
    if(LibraryExists("updater")) {
        Updater_AddPlugin(UPDATE_URL);
        decl String:newVersion[12];
        Format(newVersion, sizeof(newVersion), "%sA", PLUGIN_VERSION);
        convar = CreateConVar("scrapbankme_version", newVersion, "ScrapBank.Me plugin version.", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
    } else {
        convar = CreateConVar("scrapbankme_version", PLUGIN_VERSION, "ScrapBank.Me plugin version.", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);   
    }
    HookConVarChange(convar, Callback_VersionConVarChanged);
    Callback_VersionConVarChanged(convar, "", ""); // Check the cvar value
    CloseHandle(convar);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
        decl String:newVersion[12];
        Format(newVersion, sizeof(newVersion), "%sA", PLUGIN_VERSION);
        new Handle:convar;
        convar = CreateConVar("scrapbankme_version", newVersion, "ScrapBank.Me plugin version.", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
        Callback_VersionConVarChanged(convar, "", ""); // Check the cvar value
        CloseHandle(convar);
    }
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        new Handle:convar;
        convar = CreateConVar("scrapbankme_version", PLUGIN_VERSION, "ScrapBank.Me plugin version.", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
        Callback_VersionConVarChanged(convar, "", ""); // Check the cvar value
        CloseHandle(convar);
    }
}

public OnConfigsExecuted() {
    CreateTimer(2.0, Timer_AddTag); // Let everything load first
}

public Callback_VersionConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
    if(LibraryExists("updater") && GetConVarBool(cvar_updater)) {
        decl String:version[12];
        Format(version, sizeof(version), "%sA", PLUGIN_VERSION);
        SetConVarString(convar, version);
    } else {
        SetConVarString(convar, PLUGIN_VERSION);
    }
}

public hook_access_flag(Handle:convar, const String:oldValue[], const String:newValue[])
{
    SetConVarString(convar, newValue);
}

public hook_ad(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (adTimer != INVALID_HANDLE) {
        KillTimer(adTimer);
        adTimer = INVALID_HANDLE;
    }
    new Float:adTime = GetConVarFloat(convar);
    if (adTime > 0.0) {
        adTimer = CreateTimer(adTime, Ad, _, TIMER_REPEAT);
    } else if (adTimer != INVALID_HANDLE) {
        KillTimer(adTimer);
        adTimer = INVALID_HANDLE;
    }
}

public hook_enabled(Handle:cvar, const String:oldVal[], const String:newVal[]){
    enabled = GetConVarBool(cvar_enabled);
}

public Action:Ad(Handle:timer){
    if (enabled)
        SBMPrintToChatAll("{orange}[ScrapBank.Me] {default}Type {green}!bank {default} to sell your craftable weapons, hats, keys and items to ScrapBank.Me trading bots! Type {green}!bank_help {default} for help.");
    
    return Plugin_Continue;
}

public Action:GetQueue(Handle:timer, any:client)
{
    if(!enabled || !HasAccess(client)) {
        return Plugin_Handled;
    }
    
    if (!checkingQueue[client])
    {
        HandleQueue("get", client);
        checkingQueue[client] = true;
    }

    return Plugin_Continue;
}

public Action:Command_GetQueue(iClient, iArgs)
{
    if(!enabled || !HasAccess(iClient)) {
        return Plugin_Handled;
    }
    
    lastPosition[iClient] = 0;
    HandleQueue("get", iClient);
    
    return Plugin_Handled;
}

public Action:Command_BankHelp(iClient, iArgs)
{
    if(!enabled || !HasAccess(iClient) || iClient == 0) {
        return Plugin_Handled;
    }

    ShowWebPanel(iClient,"http://scrapbank.me/plugin.php");

    return Plugin_Handled;
}

public Action:Command_Bank(iClient, iArgs)
{
    if(!enabled || !HasAccess(iClient)) {
        return Plugin_Handled;
    }
    
    HandleQueue("add", iClient);
	
    return Plugin_Handled;
}

public Action:Command_Remove(iClient, iArgs)
{
    if(!enabled || !HasAccess(iClient)) {
        return Plugin_Handled;
    }

    HandleQueue("remove", iClient);
    
    return Plugin_Handled;
}

public Action:Command_Donate(iClient, iArgs)
{
    if(!enabled || !HasAccess(iClient)) {
        return Plugin_Handled;
    }

    HandleQueue("donate", iClient);
    
    return Plugin_Handled;
}

public Action:Timer_AddTag(Handle:timer) {
    if(!GetConVarBool(cvar_tag)) {
        return;
    }
    decl String:value[512];
    GetConVarString(sv_tags, value, sizeof(value));
    TrimString(value);
    if(strlen(value) == 0) {
        SetConVarString(sv_tags, "scrapbank.me");
        return;
    }
    decl String:tags[64][64];
    new total = ExplodeString(value, ",", tags, sizeof(tags), sizeof(tags[]));
    for(new i = 0; i < total; i++) {
        if(StrEqual(tags[i], "scrapbank.me")) {
            return; // Tag found, nothing to do here
        }
    }
    StrCat(value, sizeof(value), ",scrapbank.me");
    SetConVarString(sv_tags, value);
}

stock HandleQueue(String:type[], iClient) {
    if (iClient == 0)
    {
        PrintToServer("You have to be in-game to do that!");
        return;
    }
    decl String:steamID[64];
    if (GetClientAuthString(iClient, steamID, 64))
    {
        decl String:communityID[18];
        GetCommunityID(steamID, communityID, sizeof(communityID));

        decl String:privateKey[128], String:publicKey[128];
        decl String:toHash[128], String:hashedKey[128];
        
        GetConVarString(cvar_private_key, privateKey, sizeof(privateKey));
        GetConVarString(cvar_public_key, publicKey, sizeof(publicKey));
        
        decl String:otherOwners[38];
        GetConVarString(cvar_additional_server_owners, otherOwners, sizeof(otherOwners));

        if (!privateKey[0])
        {
            //Private key wasn't set
            CPrintToChat(iClient, "{orange}[ScrapBank.Me] {default}Unable to send request! The server owner has not set the private key. Please notify them about this.");
            PrintToServer("sbm_private_key is not set. You can find your private key at http://scrapbank.me/api/.");
            return;
        }
        
        if (!publicKey[0])
        {
            //Public key wasn't set
            CPrintToChat(iClient, "{orange}[ScrapBank.Me] {default}Unable to send request! The server owner has not set the public key. Please notify them about this.");
            PrintToServer("sbm_public_key is not set. You can find your public key at http://scrapbank.me/api/.");         
            return;
        }
        
        Format(toHash, sizeof(toHash), "%s%s", privateKey, communityID);        
        MD5String(toHash, hashedKey, sizeof(hashedKey));

        decl String:apiURL[40];
        Format(apiURL, sizeof(apiURL), "http://scrapbank.me/api/banking/%s/", type);

        new HTTPRequestHandle:request = Steam_CreateHTTPRequest(HTTPMethod_POST, apiURL);
        Steam_SetHTTPRequestGetOrPostParameter(request, "steamid", communityID);
        Steam_SetHTTPRequestGetOrPostParameter(request, "hash", hashedKey);
        Steam_SetHTTPRequestGetOrPostParameter(request, "otherowners", otherOwners);
        Steam_SetHTTPRequestGetOrPostParameter(request, "key", publicKey);
        Steam_SetHTTPRequestHeaderValue(request, "Pragma", "no-cache");
        Steam_SetHTTPRequestHeaderValue(request, "Cache-Control", "no-cache");
        if (StrEqual(type, "add") || StrEqual(type, "donate")) {
            CPrintToChat(iClient, "{orange}[ScrapBank.Me] {default}Sending the request to add you to the queue, please wait...");
            Steam_SendHTTPRequest(request, OnAddQueueComplete, iClient);
        } else if (StrEqual(type, "remove")) {
            CPrintToChat(iClient, "{orange}[ScrapBank.Me] {default}Sending the request to remove you from the queue, please wait...");
            Steam_SendHTTPRequest(request, OnRemoveQueueComplete, iClient);
        } else if (StrEqual(type, "get")) {
            Steam_SendHTTPRequest(request, OnGetQueueComplete, iClient);
        }
    }
    else
    {
        CPrintToChat(iClient, "{orange}[ScrapBank.Me] {red}Failed to get your SteamID :( {default}Please try again!");
    }
}

public OnAddQueueComplete(HTTPRequestHandle:request, bool:successful, HTTPStatusCode:status, any:client) {
    if (successful && status == HTTPStatusCode_OK)
    {
        decl String:response[1024];
        Steam_GetHTTPResponseBodyData(request, response, sizeof(response)); // Get the response from the server
        Steam_ReleaseHTTPRequest(request); // Close the handle
        if (StrEqual(response, ""))
        {
            response = "{orange}[ScrapBank.Me] {default}No response from the ScrapBank.Me server! Please try again later.";
        }
        else if (StrContains(response, "Failed") == -1)
        {
            // No match found, so successfully added to queue
            // Start timer for queue checking
            checkQueueTimer[client] = CreateTimer(1.5, GetQueue, client, TIMER_REPEAT);
        }
        CPrintToChat(client, "%s%s", response, " {default}Type {green}!bank_remove {default}to remove yourself from the queue.");
    }
    else
    {
        CPrintToChat(client, "{orange}[ScrapBank.Me] {default}Couldn't connect to the ScrapBank.Me server! Please try again later.");
    }
}

public OnRemoveQueueComplete(HTTPRequestHandle:request, bool:successful, HTTPStatusCode:status, any:client) {
    if (successful && status == HTTPStatusCode_OK)
    {
        decl String:response[1024];
        Steam_GetHTTPResponseBodyData(request, response, sizeof(response)); // Get the response from the server
        Steam_ReleaseHTTPRequest(request); // Close the handle
        if (StrEqual(response, ""))
        {
            response = "{orange}[ScrapBank.Me] {default}No response from the ScrapBank.Me server! Please try again later.";
        }
        CPrintToChat(client, response);
        CloseHandle(checkQueueTimer[client]);
        checkQueueTimer[client] = INVALID_HANDLE;
        lastPosition[client] = 0;
    }
    else
    {
        CPrintToChat(client, "{orange}[ScrapBank.Me] {default}Couldn't connect to the ScrapBank.Me server! Please try again later.");
        CloseHandle(checkQueueTimer[client]);
        checkQueueTimer[client] = INVALID_HANDLE;
        lastPosition[client] = 0;
    }
}

public OnGetQueueComplete(HTTPRequestHandle:request, bool:successful, HTTPStatusCode:status, any:client) {
    if (successful && status == HTTPStatusCode_OK)
    {
        decl String:response[1024];
        Steam_GetHTTPResponseBodyData(request, response, sizeof(response)); // Get the response from the server
        Steam_ReleaseHTTPRequest(request); // Close the handle
        if (StrEqual(response, "Error")) {
            CPrintToChat(client, "{orange}[ScrapBank.Me] {default}Failed to get your queue status (0)!");
            CloseHandle(checkQueueTimer[client]);
            checkQueueTimer[client] = INVALID_HANDLE;
            lastPosition[client] = 0;
        }
        else
        {
            // json response, so this needs to be parsed
            new JSON:resultJson = json_decode(response);
            if (resultJson == JSON_INVALID) {
                CPrintToChat(client, "{orange}[ScrapBank.Me] {default}Failed to get your queue status (1)!");
                KillTimer(checkQueueTimer[client]);
                checkQueueTimer[client] = INVALID_HANDLE;
                lastPosition[client] = 0;
            } else {
                new success = -1;
                json_get_cell(resultJson, "success", success);
                if (success == 1)
                {                    
                    decl String:botID[18];
                    json_get_string(resultJson, "bot_id", botID, sizeof(botID));
                    new position = -1;
                    json_get_cell(resultJson, "position", position);
                    if (position != lastPosition[client])
                    {
                        new totalPeople = -1;
                        json_get_cell(resultJson, "total_people", totalPeople);
                        decl String:refinedString[5];
                        json_get_string(resultJson, "refined", refinedString, sizeof(refinedString));
                        new Float:refined = StringToFloat(refinedString);
                        decl String:bot[32];
                        json_get_string(resultJson, "bot", bot, sizeof(bot));

                        decl String:output[1024];
                        Format(output, sizeof(output), "{orange}[ScrapBank.Me] {default}You are currently {olive}%d/%d {default}in queue for {green}%s{default}. {orange}%0.2f {default}refined currently in stock.", position, totalPeople, bot, refined);
                        CPrintToChat(client, output);
                        if (lastPosition[client] == 0 && position != 1)
                        {
                            CPrintToChat(client, "{orange}[ScrapBank.Me] {default}You will see this message again when your queue position changes, or you can type {green}!bank_get {default}to force this message to appear.");
                        }
                        if (position == 1)
                        {
                            CPrintToChat(client, "{orange}[ScrapBank.Me] {default}You are {green}#1 {default}in queue! Please make sure to accept the incoming friend request and/or trade request.");
                        }
                        lastPosition[client] = position;
                    }
                }
                else
                {                    
                    CPrintToChat(client, "{orange}[ScrapBank.Me] {default}You have been removed from the queue. If you like our service, please consider donating TF2 items to our bots by typing {green}!bank_donate{default}.");                    
                    CloseHandle(checkQueueTimer[client]);
                    checkQueueTimer[client] = INVALID_HANDLE;
                    lastPosition[client] = 0;
                }
            }
        }
    }
    else
    {        
        CPrintToChat(client, "{orange}[ScrapBank.Me] {default}Couldn't connect to the ScrapBank.Me server! Please try again later.");
        CloseHandle(checkQueueTimer[client]);
        checkQueueTimer[client] = INVALID_HANDLE;
        lastPosition[client] = 0;
    }
    checkingQueue[client] = false;
}

public OnClientDisconnect(client)
{
    if (checkQueueTimer[client] != INVALID_HANDLE)
    {        
        CloseHandle(checkQueueTimer[client]);
        checkQueueTimer[client] = INVALID_HANDLE;
    }
    lastPosition[client] = 0;
    checkingQueue[client] = false;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
    MarkNativeAsOptional("GetUserMessageType");
    return APLRes_Success;
}

stock ShowWebPanel(client, String:url[])
{
    new Handle:Kv = CreateKeyValues("data");
    KvSetString(Kv, "title", "");
    KvSetString(Kv, "type", "2");
    KvSetString(Kv, "msg", url);
    KvSetNum(Kv, "customsvr", 1);
    ShowVGUIPanel(client, "info", Kv);
    CloseHandle(Kv);
}

stock SBMPrintToChatAll(const String:message[])
{
    for (new i = 1; i <= MAXPLAYERS + 1; i++)
    {
        if (IsClientConnected(i) && IsClientInGame(i) && HasAccess(i))
        {
            CPrintToChat(i, message);
        }
    }
}

stock bool:GetCommunityID(String:AuthID[], String:FriendID[], size) 
{ 
    if(strlen(AuthID) < 11 || AuthID[0]!='S' || AuthID[6]=='I') 
    { 
        FriendID[0] = 0; 
        return false; 
    } 

    new iUpper = 765611979; 
    new iFriendID = StringToInt(AuthID[10])*2 + 60265728 + AuthID[8]-48; 

    new iDiv = iFriendID/100000000; 
    new iIdx = 9-(iDiv?iDiv/10+1:0); 
    iUpper += iDiv; 
     
    IntToString(iFriendID, FriendID[iIdx], size-iIdx); 
    iIdx = FriendID[9]; 
    IntToString(iUpper, FriendID, size); 
    FriendID[9] = iIdx; 

    return true; 
}

stock bool:HasAccess(client)
{
    decl String:flags[8];
    GetConVarString(cvar_access_flag, flags, sizeof(flags));
    
    if (!StrEqual(flags, "", false))
    {
        new AdminId:admin = GetUserAdmin(client);
        // Check if player is an admin.
        if(admin != INVALID_ADMIN_ID)
        {
            decl AdminFlag:flag;
            // Is the admin flag we are checking valid?
            if (FindFlagByChar(flags[0], flag))
            {
                // Check if the admin has the correct immunity flag.
                if (GetAdminFlag(admin, flag))
                {
                    return true;
                }
            }
        }
        else
        {
            return false;
        } 
    }
    
    return true;
}

stock MD5String(const String:str[], String:output[], maxlen)
{
    decl x[2];
    decl buf[4];
    decl input[64];
    new i, ii;
    
    new len = strlen(str);
    
    // MD5Init
    x[0] = x[1] = 0;
    buf[0] = 0x67452301;
    buf[1] = 0xefcdab89;
    buf[2] = 0x98badcfe;
    buf[3] = 0x10325476;
    
    // MD5Update
    new in[16];

    in[14] = x[0];
    in[15] = x[1];
    
    new mdi = (x[0] >>> 3) & 0x3F;
    
    if ((x[0] + (len << 3)) < x[0])
    {
        x[1] += 1;
    }
    
    x[0] += len << 3;
    x[1] += len >>> 29;
    
    new c = 0;
    while (len--)
    {
        input[mdi] = str[c];
        mdi += 1;
        c += 1;
        
        if (mdi == 0x40)
        {
            for (i = 0, ii = 0; i < 16; ++i, ii += 4)
            {
                in[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
            }
            // Transform
            MD5Transform(buf, in);
            
            mdi = 0;
        }
    }
    
    // MD5Final
    new padding[64] = {
        0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    };
    new inx[16];
    inx[14] = x[0];
    inx[15] = x[1];
    
    mdi = (x[0] >>> 3) & 0x3F;
    
    len = (mdi < 56) ? (56 - mdi) : (120 - mdi);
    in[14] = x[0];
    in[15] = x[1];
    
    mdi = (x[0] >>> 3) & 0x3F;
    
    if ((x[0] + (len << 3)) < x[0])
    {
        x[1] += 1;
    }
    
    x[0] += len << 3;
    x[1] += len >>> 29;
    
    c = 0;
    while (len--)
    {
        input[mdi] = padding[c];
        mdi += 1;
        c += 1;
        
        if (mdi == 0x40)
        {
            for (i = 0, ii = 0; i < 16; ++i, ii += 4)
            {
                in[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
            }
            // Transform
            MD5Transform(buf, in);
            
            mdi = 0;
        }
    }
    
    for (i = 0, ii = 0; i < 14; ++i, ii += 4)
    {
        inx[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
    }
    MD5Transform(buf, inx);
    
    new digest[16];
    for (i = 0, ii = 0; i < 4; ++i, ii += 4)
    {
        digest[ii] = (buf[i]) & 0xFF;
        digest[ii + 1] = (buf[i] >>> 8) & 0xFF;
        digest[ii + 2] = (buf[i] >>> 16) & 0xFF;
        digest[ii + 3] = (buf[i] >>> 24) & 0xFF;
    }
    
    FormatEx(output, maxlen, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
        digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7],
        digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]);
}

stock MD5Transform_FF(&a, &b, &c, &d, x, s, ac)
{
    a += (((b) & (c)) | ((~b) & (d))) + x + ac;
    a = (((a) << (s)) | ((a) >>> (32-(s))));
    a += b;
}

stock MD5Transform_GG(&a, &b, &c, &d, x, s, ac)
{
    a += (((b) & (d)) | ((c) & (~d))) + x + ac;
    a = (((a) << (s)) | ((a) >>> (32-(s))));
    a += b;
}

stock MD5Transform_HH(&a, &b, &c, &d, x, s, ac)
{
    a += ((b) ^ (c) ^ (d)) + x + ac;
    a = (((a) << (s)) | ((a) >>> (32-(s))));
    a += b;
}

stock MD5Transform_II(&a, &b, &c, &d, x, s, ac)
{
    a += ((c) ^ ((b) | (~d))) + x + ac;
    a = (((a) << (s)) | ((a) >>> (32-(s))));
    a += b;
}

stock MD5Transform(buf[], in[])
{
    new a = buf[0];
    new b = buf[1];
    new c = buf[2];
    new d = buf[3];
    
    MD5Transform_FF(a, b, c, d, in[0], 7, 0xd76aa478);
    MD5Transform_FF(d, a, b, c, in[1], 12, 0xe8c7b756);
    MD5Transform_FF(c, d, a, b, in[2], 17, 0x242070db);
    MD5Transform_FF(b, c, d, a, in[3], 22, 0xc1bdceee);
    MD5Transform_FF(a, b, c, d, in[4], 7, 0xf57c0faf);
    MD5Transform_FF(d, a, b, c, in[5], 12, 0x4787c62a);
    MD5Transform_FF(c, d, a, b, in[6], 17, 0xa8304613);
    MD5Transform_FF(b, c, d, a, in[7], 22, 0xfd469501);
    MD5Transform_FF(a, b, c, d, in[8], 7, 0x698098d8);
    MD5Transform_FF(d, a, b, c, in[9], 12, 0x8b44f7af);
    MD5Transform_FF(c, d, a, b, in[10], 17, 0xffff5bb1);
    MD5Transform_FF(b, c, d, a, in[11], 22, 0x895cd7be);
    MD5Transform_FF(a, b, c, d, in[12], 7, 0x6b901122);
    MD5Transform_FF(d, a, b, c, in[13], 12, 0xfd987193);
    MD5Transform_FF(c, d, a, b, in[14], 17, 0xa679438e);
    MD5Transform_FF(b, c, d, a, in[15], 22, 0x49b40821);
    
    MD5Transform_GG(a, b, c, d, in[1], 5, 0xf61e2562);
    MD5Transform_GG(d, a, b, c, in[6], 9, 0xc040b340);
    MD5Transform_GG(c, d, a, b, in[11], 14, 0x265e5a51);
    MD5Transform_GG(b, c, d, a, in[0], 20, 0xe9b6c7aa);
    MD5Transform_GG(a, b, c, d, in[5], 5, 0xd62f105d);
    MD5Transform_GG(d, a, b, c, in[10], 9, 0x02441453);
    MD5Transform_GG(c, d, a, b, in[15], 14, 0xd8a1e681);
    MD5Transform_GG(b, c, d, a, in[4], 20, 0xe7d3fbc8);
    MD5Transform_GG(a, b, c, d, in[9], 5, 0x21e1cde6);
    MD5Transform_GG(d, a, b, c, in[14], 9, 0xc33707d6);
    MD5Transform_GG(c, d, a, b, in[3], 14, 0xf4d50d87);
    MD5Transform_GG(b, c, d, a, in[8], 20, 0x455a14ed);
    MD5Transform_GG(a, b, c, d, in[13], 5, 0xa9e3e905);
    MD5Transform_GG(d, a, b, c, in[2], 9, 0xfcefa3f8);
    MD5Transform_GG(c, d, a, b, in[7], 14, 0x676f02d9);
    MD5Transform_GG(b, c, d, a, in[12], 20, 0x8d2a4c8a);
    
    MD5Transform_HH(a, b, c, d, in[5], 4, 0xfffa3942);
    MD5Transform_HH(d, a, b, c, in[8], 11, 0x8771f681);
    MD5Transform_HH(c, d, a, b, in[11], 16, 0x6d9d6122);
    MD5Transform_HH(b, c, d, a, in[14], 23, 0xfde5380c);
    MD5Transform_HH(a, b, c, d, in[1], 4, 0xa4beea44);
    MD5Transform_HH(d, a, b, c, in[4], 11, 0x4bdecfa9);
    MD5Transform_HH(c, d, a, b, in[7], 16, 0xf6bb4b60);
    MD5Transform_HH(b, c, d, a, in[10], 23, 0xbebfbc70);
    MD5Transform_HH(a, b, c, d, in[13], 4, 0x289b7ec6);
    MD5Transform_HH(d, a, b, c, in[0], 11, 0xeaa127fa);
    MD5Transform_HH(c, d, a, b, in[3], 16, 0xd4ef3085);
    MD5Transform_HH(b, c, d, a, in[6], 23, 0x04881d05);
    MD5Transform_HH(a, b, c, d, in[9], 4, 0xd9d4d039);
    MD5Transform_HH(d, a, b, c, in[12], 11, 0xe6db99e5);
    MD5Transform_HH(c, d, a, b, in[15], 16, 0x1fa27cf8);
    MD5Transform_HH(b, c, d, a, in[2], 23, 0xc4ac5665);

    MD5Transform_II(a, b, c, d, in[0], 6, 0xf4292244);
    MD5Transform_II(d, a, b, c, in[7], 10, 0x432aff97);
    MD5Transform_II(c, d, a, b, in[14], 15, 0xab9423a7);
    MD5Transform_II(b, c, d, a, in[5], 21, 0xfc93a039);
    MD5Transform_II(a, b, c, d, in[12], 6, 0x655b59c3);
    MD5Transform_II(d, a, b, c, in[3], 10, 0x8f0ccc92);
    MD5Transform_II(c, d, a, b, in[10], 15, 0xffeff47d);
    MD5Transform_II(b, c, d, a, in[1], 21, 0x85845dd1);
    MD5Transform_II(a, b, c, d, in[8], 6, 0x6fa87e4f);
    MD5Transform_II(d, a, b, c, in[15], 10, 0xfe2ce6e0);
    MD5Transform_II(c, d, a, b, in[6], 15, 0xa3014314);
    MD5Transform_II(b, c, d, a, in[13], 21, 0x4e0811a1);
    MD5Transform_II(a, b, c, d, in[4], 6, 0xf7537e82);
    MD5Transform_II(d, a, b, c, in[11], 10, 0xbd3af235);
    MD5Transform_II(c, d, a, b, in[2], 15, 0x2ad7d2bb);
    MD5Transform_II(b, c, d, a, in[9], 21, 0xeb86d391);
    
    buf[0] += a;
    buf[1] += b;
    buf[2] += c;
    buf[3] += d;
}  
