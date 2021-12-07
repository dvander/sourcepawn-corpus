/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <system2>

public Plugin:myinfo = 
{
	name = "Sourcepawn Editor",
	author = "necavi",
	description = "So pointless it makes me want to cry!",
	version = "0.1",
	url = "<- URL ->"
}
new Handle:FileHandles[MAXPLAYERS+1] = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_startpawn",StartPawn_Cmd,ADMFLAG_RCON,"Engage sourcepawn write mode");
	RegAdminCmd("sm_EndPawn",EndPawn_Cmd,ADMFLAG_RCON);
	RegAdminCmd("sm_NewFile",StartFile_Cmd,ADMFLAG_RCON);
	RegAdminCmd("sm_DeleteFile",DeleteFile_Cmd,ADMFLAG_RCON);
	RegAdminCmd("sm_Compile",Compile_Cmd,ADMFLAG_RCON);
	RegAdminCmd("sm_WriteLine",WriteLine_Cmd,ADMFLAG_RCON);
	RegAdminCmd("sm_InitFile",InitFile_Cmd,ADMFLAG_RCON);
	RegAdminCmd("sm_Include",Include_Cmd,ADMFLAG_RCON);
}
public Action:StartPawn_Cmd(client,args)
{
	
}
public Action:EndPawn_Cmd(client,args)
{
	
}
public Action:Include_Cmd(client,args)
{
	new position = FilePosition(FileHandles[client]);
	PrintToChatAll("Position: %s",position);
	FileSeek(FileHandles[client],0,SEEK_SET);
	new String:include[32];
	GetCmdArg(1,include,sizeof(include));
	WriteFileLine(FileHandles[client],"#include %s",include);
	FlushFile(FileHandles[client]);
	FileSeek(FileHandles[client],position,SEEK_SET);
}
public Action:StartFile_Cmd(client,args)
{
	new String:file[32];
	if(!GetCmdArg(1, file, sizeof(file)))
	{
		ReplyToCommand(client, "[PawnHerp] Please provide the name of a file to edit.")
		return;
	}
	new String:path[128];
	BuildPath(Path_SM, path,sizeof(path), "scripting/%s.sp",file);
	PrintToChatAll("Path: %s for file: %s",path,file);
	if(FileExists(path))
	{
		ReplyToCommand(client,"[PawnHerp] File already exists! Please use sm_DeleteFile on that file first!")
		return;
	}
	FileHandles[client] = OpenFile(path,"w+");
	WriteFileLine(FileHandles[client],"#include <sourcemod>");
	WriteFileLine(FileHandles[client],"public Plugin:myinfo =");
	WriteFileLine(FileHandles[client],"{");
	WriteFileLine(FileHandles[client],"    name = \"%s\",",file);
	new String:name[32];
	GetClientName(client,name,sizeof(name));
	WriteFileLine(FileHandles[client],"    author = \"%s\",",name);
	WriteFileLine(FileHandles[client],"    description = \"Made using Ingame Editor!\",");
	WriteFileLine(FileHandles[client],"    version = \"0.1\",");
	WriteFileLine(FileHandles[client],"    url = \"www.necavi.com\"");
	WriteFileLine(FileHandles[client],"}");
	FlushFile(FileHandles[client]);
}
public Action:WriteLine_Cmd(client,args)
{
	if(FileHandles[client] == INVALID_HANDLE)
	{
		ReplyToCommand(client,"[PawnHerp] Please open a file!");
		return;
	}
	if(GetCmdArgs()<1)
	{
		WriteFileLine(FileHandles[client],"");
	} else {
		decl String:Buffer[256];
		GetCmdArgString(Buffer,sizeof(Buffer));
		WriteFileLine(FileHandles[client],"%s",Buffer);
		ReplyToCommand(client, "[PawnHerp] Added line:");
		ReplyToCommand(client, "%s",Buffer);
	}
	FlushFile(FileHandles[client]);
}
public Action:InitFile_Cmd(client, args)
{
	
}
public Action:DeleteFile_Cmd(client, args)
{
	new String:file[32];
	if(!GetCmdArg(1, file, sizeof(file)))
	{
		ReplyToCommand(client, "[PawnHerp] Please provide the name of a file to delete.")
		return;
	}
	new String:path[128];
	BuildPath(Path_SM, path,sizeof(path), "scripting/%s.sp",file);
	if(!FileExists(path))
	{
		ReplyToCommand(client,"[PawnHerp] File does not exist!")
		return;
	}
	DeleteFile(path);
	PrintToChatAll("[PawnHerp] Deleted file: %s from path: %s",file,path);
}
public Action:Compile_Cmd(client,args)
{
	new String:file[32];
	if(!GetCmdArg(1, file, sizeof(file)))
	{
		ReplyToCommand(client, "[PawnHerp] Please provide the name of a file to compile.")
		return;
	}
	new String:path[128];
	BuildPath(Path_SM, path,sizeof(path), "scripting/");
	new String:filepath[128];
	Format(filepath,sizeof(filepath),"%s/%s.sp",path,file);
	PrintToChatAll("Path: %s for file: %s",filepath,file);
	if(!FileExists(filepath))
	{
		ReplyToCommand(client,"[PawnHerp] File does not exist!")
		return;
	}
	new String:SysPath[PLATFORM_MAX_PATH + 1];
	GetGameDir(SysPath,sizeof(SysPath));
	new String:EndPath[PLATFORM_MAX_PATH + 1];
	new String:AddonPath[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM,AddonPath,sizeof(AddonPath), "plugins/%s.smx",file);
	if(FileExists(AddonPath)) DeleteFile(AddonPath);
	Format(EndPath,sizeof(EndPath),"%s/%sspcomp %s/%s%s.sp -o=\"%s/%s\"",SysPath,path,SysPath,path,file,SysPath,AddonPath);
	PrintToChatAll("%s",EndPath);
	RunCommand(EndPath);
	PrintToChatAll("%s",AddonPath);
	if(FileExists(AddonPath))
	{
		PrintToChatAll("[Pawnherp] Compilation Successful!");
		ServerCommand("sm plugins reload %s",file);
	} else {
		PrintToChatAll("[PawnHerp] Compilation failed for some unknown reason...");
	}
	
}

