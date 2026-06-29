#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name        = "CIDR Block",
	author      = "Bottiger",
	description = "Block IPS with CIDR notation",
	version     = PLUGIN_VERSION,
	url         = "http://skial.com"
};

new bool:g_late;
new bool:g_loaded;
new Handle:g_path;

new Handle:g_min;
new Handle:g_max;

public OnPluginStart() {
    CreateConVar("cidr_version", PLUGIN_VERSION, "Block CIDR", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_path = CreateConVar("cidr_path", "configs/ipblocks.txt", "Path to block list.");
    
    RegAdminCmd("cidr_reload", Command_Reload, ADMFLAG_BAN, "Clear banlist and reload bans from file.");
    RegAdminCmd("cidr_clear", Command_Clear, ADMFLAG_BAN, "Clear banlist.");
    RegAdminCmd("cidr_add", Command_Add, ADMFLAG_BAN, "Add CIDR to banlist. Does not last between reboots and does not get added to file.");
    
    g_min = CreateArray();
    g_max = CreateArray();
}

public Action:Command_Reload(client, args) {
    ReplyToCommand(client, "Clearing banlist and reloading from file.");
    ClearArray(g_min);
    ClearArray(g_max);
    ParseFile();
}

public Action:Command_Clear(client, args) {
    ReplyToCommand(client, "Clearing banlist.");
    ClearArray(g_min);
    ClearArray(g_max);
}

public Action:Command_Add(client, args) {
    decl String:cmd[32];
    decl String:arg[32];
    
    if(args < 1) {
        GetCmdArg(0, cmd, sizeof(cmd));
        ReplyToCommand(client, "Usage: %s 1.2.3.4/30", cmd);
    }

    GetCmdArg(1, arg, sizeof(arg));
    TrimString(arg);
    
    ReplyToCommand(client, "Adding %s", arg);
    ParseCIDR(arg);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
    g_late = late;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen) {
    return !IsBlocked(client);
}

public OnConfigsExecuted() {
    if(!g_loaded) {
        g_loaded = true;
        ParseFile();
        if(g_late) {
            for(new i=1;i<=MaxClients;i++) {
                if(!IsClientInGame(i) || IsFakeClient(i))
                    continue;
                
                if(IsBlocked(i))
                    KickClient(i);
            }
        }
    }
}

bool:IsBlocked(client) {
    decl String:ip[17];
    GetClientIP(client, ip, sizeof(ip));
    new ipn = inet_aton(ip);
    
    new entries = GetArraySize(g_min);
    for(new i=0;i<entries;i++) {
        new min = GetArrayCell(g_min, i);
        new max = GetArrayCell(g_max, i);
        if(ipn >= min && ipn <= max)
            return true;
    }
    
    return false;
}

ParseFile() {
    decl String:target[PLATFORM_MAX_PATH];
    decl String:path[PLATFORM_MAX_PATH];
    decl String:line[32];
    new Handle:file;
    
    GetConVarString(g_path, target, sizeof(target));
    
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, target);
    file = OpenFile(path, "r");
    if(file == INVALID_HANDLE) {
        LogError("Block list not found %s", target);
        return;
    }
    
    while (!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line))) {
        TrimString(line);
        if(line[0] == '#' || line[0] == '\x00')
            continue;
        
        ParseCIDR(line);
    }
    CloseHandle(file);
}

stock ParseCIDR(const String:cidr_string[]) {
    decl String:cidr[2][17];
    
    ExplodeString(cidr_string, "/", cidr, 2, 17);
    new baseip = inet_aton(cidr[0]);
    new prefix = StringToInt(cidr[1]);
    
    if(prefix == 0) {
        LogError("CIDR prefix 0, clamping to 32. %s", cidr_string);
        prefix = 32;
    }
    
    new shift = 32 - prefix;
    new mask  = (1 << shift) - 1;
    new start = baseip >> shift << shift;
    new end   = start | mask;
    
    PushArrayCell(g_min, start);
    PushArrayCell(g_max, end);
}

stock inet_aton(const String:ip[]) {
    decl String:pieces[4][16];
    new nums[4];

    if (ExplodeString(ip, ".", pieces, 4, 16) != 4) {
        return 0;
    }

    nums[0] = StringToInt(pieces[0]);
    nums[1] = StringToInt(pieces[1]);
    nums[2] = StringToInt(pieces[2]);
    nums[3] = StringToInt(pieces[3]);

    return ((nums[0] << 24) | (nums[1] << 16) | (nums[2] << 8) | nums[3]);
}