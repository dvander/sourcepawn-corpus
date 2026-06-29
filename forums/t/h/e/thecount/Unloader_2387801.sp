#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.0"

public Plugin:myinfo = {
	name = "Unloader",
	author = "The Count",
	description = "Unload plugins per map.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

new Handle:unloads = INVALID_HANDLE;
new String:cfgpath[PLATFORM_MAX_PATH];
new bool:checked = false;//Boolean to halt excessive surveying

public OnPluginStart(){
	CreateConVar("sm_unloader_version", PLUGIN_VERSION, "Unloader Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_unload", Cmd_Unload, ADMFLAG_ROOT, "Add a plugin to the unloading list.");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){//This forward used to catch plugins before execution
	BuildPath(Path_SM, cfgpath, sizeof(cfgpath), "configs/unloader.cfg");
	SurveyPlugins();
}

public OnMapStart(){
	if(!checked){
		SurveyPlugins();
	}
}

public OnMapEnd(){
	checked = false;
}

public Action:Cmd_Unload(client, args){
	if(args < 2){
		ReplyToCommand(client, "[Unloader] Usage: sm_unload \"PluginName\" \"Map\" \"Map2\"...");
		return Plugin_Handled;
	}
	new String:temp[256], String:arg[64];
	new Handle:file = OpenFile(cfgpath, "a");
	
	GetCmdArg(1, temp, sizeof(temp));
	GetCmdArg(2, arg, sizeof(arg));
	Format(temp, sizeof(temp), "%s: %s", temp, arg);
	for (new i = 3; i <= args;i++){
		GetCmdArg(i, arg, sizeof(arg));
		Format(temp, sizeof(temp), "%s, %s", temp, arg);
	}
	WriteFileLine(file, temp);
	CloseHandle(file);
	GetCmdArg(1, temp, sizeof(temp));
	GetCmdArg(2, arg, sizeof(arg));
	ReplyToCommand(client, "[Unloader] Plugin %s added to list for map%s %s%s.", temp, (args > 2 ? "s" : ""), arg, (args > 2 ? " etc.." : ""));
	
	unloads = INVALID_HANDLE;
	SurveyPlugins();
	return Plugin_Handled;
}

SurveyPlugins(){
	if (!LoadList()) { return; }
	
	new Handle:iter = GetPluginIterator(), Handle:plug, PluginStatus:stat;
	new String:name[64], String:name2[64], String:raw[512], String:maps[12][64];
	new String:curmap[64]; GetCurrentMap(curmap, sizeof(curmap));
	while((plug = ReadPlugin(iter)) != INVALID_HANDLE){//Loop through all plugins, check disabled maps
		stat = GetPluginStatus(plug);
		if(stat == Plugin_Loaded || stat == Plugin_Created || stat == Plugin_Running){
			GetPluginFilename(plug, name, sizeof(name));
			ReplaceString(name, sizeof(name), ".smx", "", false);
			strcopy(name2, sizeof(name2), name);
			StrLowerCase(name, sizeof(name));
			if(GetTrieString(unloads, name, raw, sizeof(raw))){
				ExplodeString(raw, ",", maps, 12, 64);
				for (new i = 0; i < 12;i++){
					if (StrEqual(maps[i], "")) { break; }//Nothing left in array
					if(StrEqual(curmap, maps[i], false)){
						ServerCommand("sm plugins unload %s", name2);
						PrintToServer("[Unloader] Attempted to unload: %s", name2);
						break;
					}
				}
			}
		}
	}
	CloseHandle(iter);
	checked = true;
}

bool:LoadList(){
	if(unloads != INVALID_HANDLE){
		return true;//Only load once per plugin lifetime
	}
	if(FileExists(cfgpath)){
		unloads = CreateTrie();
		new Handle:file = OpenFile(cfgpath, "r"), String:line[256], String:debris[2][256];
		while(ReadFileLine(file, line, sizeof(line))){
			ReplaceString(line, sizeof(line), "\n", "");
			ReplaceString(line, sizeof(line), " ", "");
			ExplodeString(line, ":", debris, 2, 256, true);
			
			StrLowerCase(debris[0], 256);
			StrLowerCase(debris[1], 256);
			SetTrieString(unloads, debris[0], debris[1]);//Set plugin key with map(s) string
		}
		CloseHandle(file);
	}else{
		PrintToServer("[Unloader] ERROR: Could not find sourcemod/configs/unloader.cfg!");
		return false;
	}
	return true;
}

StrLowerCase(String:targ[], maxlength){
	new String:temp[maxlength];
	strcopy(temp, maxlength, targ);
	
	new i = 0;
	while(temp[i] != '\0'){
		temp[i] = CharToLower(temp[i]);
		i++;
	}
	strcopy(targ, maxlength, temp);
}