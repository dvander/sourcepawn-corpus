#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "CommandReact",
	author = "theY4Kman",
	description = "Execute server commands when other commands are run.",
	version = PLUGIN_VERSION,
	url = "http://y4kstudios.com/unhinged/commandreact/"
};

new Handle:cmds;

public OnPluginStart(){
  ParseConfig();
  
  CreateConVar("cmdreact_version", PLUGIN_VERSION, "The version of CommandReact, a SourceMod plugin by theY4Kman", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
  
  RegAdminCmd("cmdreact_reload", ReloadEvent, Admin_Chat, "Realods the BotChat configuration file", "", FCVAR_PLUGIN);
}

public OnPluginEnd(){
  CloseHandle(cmds);
}

public Action:OnClientCommand(client, args){
  decl String:cmd[48];
  GetCmdArg(0, cmd, sizeof(cmd));
  
  decl String:args[256];
  GetCmdArgString(args, sizeof(args));
  
  decl String:cmdstring[305];
  Format(cmdstring, sizeof(cmdstring), "%s%s%s", cmd, strlen(args) ? " " : "", strlen(args) ? args : "");
  
  CommandReact(cmdstring, client);
}

public CommandReact(const String:cmd[], client){
  KvRewind(cmds);
  decl String:react[512];
  KvGetString(cmds, cmd, react, sizeof(react));
  
  if(strlen(react)){
    ServerCommand(react);
  }
}

public Action:ReloadEvent(client, args){
  ParseConfig();
}

public ParseConfig(){
  decl String:path[PLATFORM_MAX_PATH];
  BuildPath(Path_SM, path, sizeof(path), "configs/commandreact.cfg");
  
  if(!FileExists(path))
    ThrowError("The CommandReact config file could not be found at \"%s\"", path);
  
  cmds = CreateKeyValues("CommandReact", "Commands");
  KvGotoFirstSubKey(cmds);
  
  new Handle:cfg = OpenFile(path, "r");
  decl String:line[818];
  decl String:cmd[305];
  decl String:react[512];
  decl split;
  new Bool:quotes = false;
  
  while(ReadFileLine(cfg, line, sizeof(line))){
    if(line[0] == '"'){
      split = StrContains(line[1], "\" ") + 2;
      quotes = true;
    } else{
      split = StrContains(line, " ");
      quotes = false;
    }
    
    if(split == -1 || (line[0] == '/' && line[1] == '/'))
      continue;
    
    strcopy(cmd, split + (quotes ? -1 : 1), line[(line[0] == '"')]);
    strcopy(react, sizeof(react), line[split+1]);
    
    KvSetString(cmds, cmd, react);
  }
}
