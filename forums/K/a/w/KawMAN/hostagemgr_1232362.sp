#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#undef REQUIRE_PLUGIN 
#include <autoupdate>

#define PLUGIN_VERSION "1.0.0"

#define DEBUG 0
#define CVARMAX 256
#define MAXSOUNDS 64 //Max sounds per host event sound group
#define MAXGROUPS 10 //Max host groups
#define MAXSKINS 32 //Max skins
#define HOSTVOLUME SNDLEVEL_DISHWASHER //from sdktools_sound, rest on the bottom of this file
#define HOSTENTNAME "hostage_entity"
#define MDLDIR "models/"
#define SNDDIR "sound/"

new Handle:hHostMgr = INVALID_HANDLE;
new Handle:hHostMgrSkins = INVALID_HANDLE;
new Handle:hHostMgrSounds = INVALID_HANDLE;
new Handle:hHostMgrAutoUpdate = INVALID_HANDLE;
new bool:IsON=false, bool:HostMgr = false,bool:HostMgrSkins=false,bool:HostMgrSounds=false;

new String:SoundsPain[MAXSOUNDS][PLATFORM_MAX_PATH], String:SoundsUnUse[MAXSOUNDS][PLATFORM_MAX_PATH], String:SoundsUse[MAXSOUNDS][PLATFORM_MAX_PATH];
new SoundsPainGroup[MAXSOUNDS] = { 0, ...}, SoundsUnUseGroup[MAXSOUNDS] = { 0, ...}, SoundsUseGroup[MAXSOUNDS] = { 0, ...} ;
new SoundsPainCount[MAXGROUPS] = { 0, ...}, SoundsUnUseCount[MAXGROUPS] = { 0, ...}, SoundsUseCount[MAXGROUPS] = { 0, ...};
new String:HostModels[MAXSKINS][PLATFORM_MAX_PATH] , HostModelsGroup[MAXSKINS] = { 0, ...},HostModelsCount[MAXGROUPS]  = { 0, ...};
new HostModelsCount2 = 0,HostModelsIndex[MAXSKINS] = { 0, ...};

static const String:DefHostSounds[][] = {
"hostage/hpain/hpain1.wav",
"hostage/hpain/hpain2.wav",
"hostage/hpain/hpain3.wav",
"hostage/hpain/hpain4.wav",
"hostage/hpain/hpain5.wav",
"hostage/hpain/hpain6.wav",
"hostage/hunuse/comeback.wav",
"hostage/hunuse/dontleaveme.wav",
"hostage/hunuse/illstayhere.wav",
"hostage/hunuse/notleaveme.wav",
"hostage/hunuse/yeahillstay.wav",
"hostage/huse/getouttahere.wav",
"hostage/huse/illfollow.wav",
"hostage/huse/letsdoit.wav",
"hostage/huse/letsgo.wav",
"hostage//huse/letshurry.wav", //!! - Buggy, double backslash
"hostage/huse/letsmove.wav",
"hostage/huse/okletsgo.wav",
"hostage/huse/youlead.wav"
};

public Plugin:myinfo = 
{
	name = "Hostage Manager",
	author = "KawMAN",
	description = "Hostage modification",
	version = PLUGIN_VERSION,
	url = "http://KawMAN.tk/SourceMOD"
};

public OnPluginStart()
{
	new String:game_description[64];
	GetGameDescription(game_description, sizeof(game_description), true);
	if (StrContains(game_description, "Counter-Strike", false) == -1) {
		SetFailState("Plugin for CS:S only");
	}

	#if DEBUG > 0
	new String:plguin_ver[128]= "";
	FormatTime(plguin_ver, sizeof(plguin_ver), NULL_STRING);
	Format(plguin_ver,sizeof(plguin_ver), "%s-%s",PLUGIN_VERSION,plguin_ver);
	CreateConVar("sm_hostagemgr_version", plguin_ver, "Hostage Manager Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);	
	#else
	CreateConVar("sm_hostagemgr_version", PLUGIN_VERSION, "Hostage Manager Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);	
	#endif
	
	hHostMgr = CreateConVar("sm_hostmgr", "0", "Set Hostage Mgr state, 0 = Off, 1 = On", FCVAR_PLUGIN,true,0.0,true,1.0); HookConVarChange(hHostMgr, MyCVARChange);
	hHostMgrAutoUpdate = CreateConVar("sm_hostmgr_autoupdate", "0", "Autoupdate plugin (Require Plugin Autoupdater & Sockets)", FCVAR_PLUGIN,true,0.0,true,1.0); HookConVarChange(hHostMgrAutoUpdate, MyCVARChange);
	hHostMgrSkins = CreateConVar("sm_hostmgr_models", "0", "Use custom hostage skins", FCVAR_PLUGIN,true,0.0,true,1.0); HookConVarChange(hHostMgrSkins, MyCVARChange);
	hHostMgrSounds = CreateConVar("sm_hostmgr_sounds", "0", "Use custom hostage sounds (will block defaults)", FCVAR_PLUGIN,true,0.0,true,1.0); HookConVarChange(hHostMgrSounds, MyCVARChange);
	
	AutoExecConfig(false, "hmgr/hostagemgr");
	RegServerCmd("sm_hmgr_print", CmdPrint, "Prints current config(arrays content)");
	RegServerCmd("sm_hmgr_addmodel", CmdAddModel, "Adds model,syntax: <path> [group=0]");
	RegServerCmd("sm_hmgr_addsound", CmdAddSound, "Adds sound,syntax: <path> [group=0]");
	RegServerCmd("sm_hmgr_clear", CmdFlush, "Flush config");
	RegServerCmd("sm_hmgr_adddownloadlist", CmdAddDownloadList, "Read files from file and adds them to download table, syntax <path_to_file_with_filelist>");
	RegServerCmd("sm_hmgr_adddownload", CmdAddDownload, "Adds file to download table, syntax <path_to_file>");
}
public OnMapStart()
{
	AddAllToDownload();
	PrecacheAll();
	SetupState();
	
}
public OnAllPluginsLoaded() { 
    if(GetConVarBool(hHostMgrAutoUpdate)&&LibraryExists("pluginautoupdate")) { 
        AutoUpdate_AddPlugin("kawman.tk", "/SourceMOD/hostagemgr.xml", PLUGIN_VERSION); 
    } 
} 
public OnPluginEnd() { 
    if(GetConVarBool(hHostMgrAutoUpdate)&&LibraryExists("pluginautoupdate")) { 

        AutoUpdate_RemovePlugin(); 
    } 
}
// ------------------------------------ Commands  ---------------------------------- //
public Action:CmdFlush(args) {
	HostModelsCount2 = 0;
	for(new i = 0; i<MAXSKINS;i++) {
		HostModels[i] = "";
		HostModelsGroup[i] = 0;
		
	}
	for(new i = 0; i<MAXGROUPS;i++) {
		HostModelsCount[i] = 0;
		SoundsPainCount[i] = 0;
		SoundsUseCount[i] = 0;
		SoundsUnUseCount[i] = 0;
	}
	for(new i = 0; i<MAXSOUNDS;i++) {
		SoundsPain[i] = "";
		SoundsUse[i] = "";
		SoundsUnUse[i] = "";
		SoundsPainGroup[i] = 0;
		SoundsUseGroup[i] = 0;
		SoundsUnUseGroup[i] = 0;
	}
	PrintToServer("Config clear!!!");
}
public Action:CmdPrint(args)
{
	PrintToServer("------- HOST SKIN LIST : NR - Group - Name/path");
	for(new i = 0; i<MAXSKINS;i++) {
		if(!StrEqual(HostModels[i],"")) {
			PrintToServer("%d - %d - %s",i,HostModelsGroup[i],HostModels[i]);
		}
		
	}
	PrintToServer("------- HOST GROUPS : Group - Skins - SPain - SUse - SUnUes");
	for(new i = 0; i<MAXGROUPS;i++) {
		if(HostModelsCount[i]!=0) {
			PrintToServer("%d - %d - %d - %d - %d",i,HostModelsCount[i],SoundsPainCount[i],SoundsUseCount[i],SoundsUnUseCount[i]);
		}
		
	}
	PrintToServer("------- HOST Sounds : Type - Nr - Group - path");
	for(new i = 0; i<MAXSOUNDS;i++) {
		if(!StrEqual(SoundsPain[i],"")) {
			PrintToServer("0(Pain)\t- %d - %d - %s",i,SoundsPainGroup[i],SoundsPain[i]);
		}
	}
	for(new i = 0; i<MAXSOUNDS;i++) {
		if(!StrEqual(SoundsUse[i],"")) {
			PrintToServer("1(Use)\t- %d - %d - %s",i,SoundsUseGroup[i],SoundsUse[i]);
		}
	}
	for(new i = 0; i<MAXSOUNDS;i++) {
		if(!StrEqual(SoundsUnUse[i],"")) {
			PrintToServer("1(UnUse)\t- %d - %d - %s",i,SoundsUnUseGroup[i],SoundsUnUse[i]);
		}
	}
	#if DEBUG >0
	PrintToServer("------- Precache models Table ------");
	for(new i = 0; i<MAXSKINS;i++) {
		if(!StrEqual(HostModels[i],"")) {
			PrintToServer("%d - %d - %d",i,HostModelsGroup[i],HostModelsIndex[i]);
		}
		
	}
	#endif
}
public Action:CmdAddModel(args)
{
	#if DEBUG > 1
	new String:Parms[CVARMAX]="";
	GetCmdArgString(Parms, sizeof(Parms));
	PrintToServer("[HM:DEBUG] AddModel Cmd, %s",Parms);
	#endif
	if(args <= 0) {
		PrintToServer("Add Hostage model, syntax: <path> [group=0]");
		return Plugin_Handled;
	}
	new String:Model[PLATFORM_MAX_PATH]="";
	GetCmdArg(1, Model, PLATFORM_MAX_PATH);

	new Group = 0;
	if(args >=2) {
		new String:SGroup[PLATFORM_MAX_PATH]="";
		GetCmdArg(2, SGroup, PLATFORM_MAX_PATH);
		Group = StringToInt(SGroup);
		if(Group >= MAXGROUPS) {
			PrintToServer("Only up to %d groups, if you want more change MAXGROUPS in source and compile",MAXGROUPS);
		}
	}
	new result = AddModel(Model,Group);
	if(result!=0) {
		if(result==-1) {
			PrintToServer("Error when adding file: %s, missing or DB full",Model);
		}
		else {
			PrintToServer("Model already added ");
		}
	}
	return Plugin_Handled;
}
public Action:CmdAddSound(args)
{
	#if DEBUG > 1
	new String:Parms[CVARMAX]="";
	GetCmdArgString(Parms, sizeof(Parms));
	PrintToServer("[HM:DEBUG] AddSound Cmd, %s",Parms);
	#endif
	if(args <= 1) {
		PrintToServer("Add Hostage sound, syntax: <path> <type: 0-Pain,1-Use,2-UnUse> [group=0]");
		return Plugin_Handled;
	}
	new String:Sound[PLATFORM_MAX_PATH]="";
	GetCmdArg(1, Sound, PLATFORM_MAX_PATH);
	new String:SType[PLATFORM_MAX_PATH]="";
	GetCmdArg(2, SType, PLATFORM_MAX_PATH);
	new Type = StringToInt(SType);
	
	new Group = 0;
	if(args >=3) {
		new String:SGroup[PLATFORM_MAX_PATH]="";
		GetCmdArg(3, SGroup, PLATFORM_MAX_PATH);
		Group = StringToInt(SGroup);
		if(Group >= MAXGROUPS) {
			PrintToServer("Only up to %d groups, if you want more change MAXGROUPS in source and compile",MAXGROUPS);
		}
	}
	new result = AddSound(Sound,Type,Group);
	if(result!=0) {
		if(result==-1) {
			PrintToServer("Error when adding file: %s, missing or DB full",Sound,Group);
		} else {
			PrintToServer("Sound already added gid:%d type:%d",Group,Type);
		}
	}
	return Plugin_Handled;
}
public Action:CmdAddDownloadList(args)
{
	if(args!=1) {
		PrintToServer("Wrong args");
		return Plugin_Handled;
	}
	new String:file[PLATFORM_MAX_PATH];
	GetCmdArg(1, file, PLATFORM_MAX_PATH);
	if(!FileExists(file)) {
		PrintToServer("No file: %s",file);
		return Plugin_Handled;
	}
	ReadDownloadsSimple(file);
	return Plugin_Handled;
}
public Action:CmdAddDownload(args)
{
	if(args!=1) {
		PrintToServer("Wrong args");
		return Plugin_Handled;
	}
	new String:file[PLATFORM_MAX_PATH];
	GetCmdArg(1, file, PLATFORM_MAX_PATH);
	if(!FileExists(file)) {
		PrintToServer("No file: %s",file);
		return Plugin_Handled;
	}
	AddFileToDownloadsTable(file);
	return Plugin_Handled;
}
// ------------------------------------ Hooks  ---------------------------------- //
public MyCVARChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar==hHostMgrAutoUpdate) {
		if(StringToInt(oldValue)==0&&StringToInt(newValue)==1) {
			AutoUpdate_AddPlugin("kawman.tk", "/SourceMOD/hostagemgr.xml", PLUGIN_VERSION);
		} else if(StringToInt(oldValue)==1&&StringToInt(newValue)==0) {
			AutoUpdate_RemovePlugin(); 
		}
	}
	SetupState();
}
// ------------------------------------ Events ---------------------------------- //
public eHostageHurt(Handle:event, const String:name[],bool:dontBroadcast)
{
	new HostID = GetEventInt(event, "hostage");
	if(HostMgrSounds) //Play pain sound
	{
		new HostGroup = GetHostGroup(HostID);
		if(HostGroup!=-1 && SoundsPainCount[HostGroup] > 0) {  //No sounds for this Host group check
			new Rand = GetRandomInt(1, SoundsPainCount[HostGroup]);
			new grpcount = 0;
			for(new i = 0; i<MAXSOUNDS; i++) {
				if(SoundsPainGroup[i]==HostGroup) {
					grpcount++;
				}
				if(grpcount==Rand) {
					EmitSoundToAll(SoundsPain[i], HostID, SNDCHAN_AUTO, HOSTVOLUME);
					break;
				}
				#if DEBUG > 1
				else {
					PrintToServer("[HM:DEBUG] Event %s HostID-Grp %d-%d grpcount:%d Rand:%d Sound:%s",name,HostID,HostGroup,grpcount,Rand,SoundsPain[i]);
				}
				#endif
			}
		}
		#if DEBUG > 1
		else {
			PrintToServer("[HM:DEBUG] Event %s HostID-Grp %d-%d",name,HostID,HostGroup);
		}
		#endif
	}
}
public eHostageFollows(Handle:event, const String:name[],bool:dontBroadcast)
{
	new HostID = GetEventInt(event, "hostage");
	if(HostMgrSounds) //Play pain sound
	{
		new HostGroup = GetHostGroup(HostID);
		if(HostGroup!=-1 && SoundsUseCount[HostGroup] > 0) {  //No sounds for this Host group check
			new Rand = GetRandomInt(1, SoundsUseCount[HostGroup]);
			new grpcount = 0;
			for(new i = 0; i<MAXSOUNDS; i++) {
				if(SoundsUseGroup[i]==HostGroup) {
					grpcount++;
				}
				if(grpcount==Rand) {
					EmitSoundToAll(SoundsUse[i], HostID, SNDCHAN_AUTO, HOSTVOLUME);
					break;
				}
			}
		}
		#if DEBUG > 1
		PrintToServer("[HM:DEBUG] Event %s HostID-Grp %d-%d",name,HostID,HostGroup);
		#endif
	}
}
public eHostageStopsFollowing(Handle:event, const String:name[],bool:dontBroadcast)
{
	new HostID = GetEventInt(event, "hostage");
	if(HostMgrSounds) //Play pain sound
	{
		new HostGroup = GetHostGroup(HostID);
		if(HostGroup!=-1 && SoundsUnUseCount[HostGroup] > 0) {  //No sounds for this Host group check
			new Rand = GetRandomInt(1, SoundsUnUseCount[HostGroup]);
			new grpcount = 0;
			for(new i = 0; i<MAXSOUNDS; i++) {
				if(SoundsUnUseGroup[i]==HostGroup) {
					grpcount++;
				}
				if(grpcount==Rand) {
					EmitSoundToAll(SoundsUnUse[i], HostID, SNDCHAN_AUTO, HOSTVOLUME);
					break;
				}
			}
		}
		#if DEBUG > 1
		PrintToServer("[HM:DEBUG] Event %s HostID-Grp %d-%d",name,HostID,HostGroup);
		#endif
	}
}
public eRoundStart(Handle:event, const String:name[],bool:dontBroadcast)
{
	if(HostMgrSkins) {
		new host = -1, rand = 0;
		while ((host = FindEntityByClassname2(host, HOSTENTNAME)) != -1) {
			if(HostModelsCount2 == 0) break;
			rand = GetRandomInt(0, HostModelsCount2 - 1);
			new String:tmp[PLATFORM_MAX_PATH];
			Format(tmp, sizeof(tmp), "%s%s", MDLDIR, HostModels[rand]);
			#if DEBUG > 0
			PrintToServer("[HM:DEBUG] HMC2: %d, R:%d tmp: %s",HostModelsCount2,rand,tmp);
			#endif
			SetEntityModel(host, tmp);
			//SetHostModel(host, HostModelsIndex[rand]);
		}
	}
}
public Action:eSoundPlayed(clients[64],&numClients,String:sample[PLATFORM_MAX_PATH],&entity,&channel,&Float:volume,&level,&pitch,&flags) 
{
	if(HostMgrSounds) {
		for(new i = 0; i<=18;i++) {
			if (StrEqual (sample,DefHostSounds[i]	)) {
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

/*
public OnConfigsExecuted() {
	SetupState();
}
*/
// -------------------------------------- Funcs ------------------------------------ //
#if DEBUG > 5
SetHostModel(host, mdlindex) {
	SetEntProp(host, Prop_Data, "m_nModelIndex", mdlindex);
}
#endif
AddAllToDownload() {
	new String:tmp[PLATFORM_MAX_PATH];
	for(new i = 0; i<MAXSKINS;i++) {
		if(!StrEqual(HostModels[i],"")) {
			Format(tmp, sizeof(tmp), "%s%s", MDLDIR, HostModels[i]);
			AddFileToDownloadsTable(tmp);
		}
		
	}
	for(new i = 0; i<MAXSOUNDS;i++) {
		if(!StrEqual(SoundsPain[i],"")) {
			Format(tmp, sizeof(tmp), "%s%s", SNDDIR, SoundsPain[i]);
			AddFileToDownloadsTable(tmp);
		}
	}
	for(new i = 0; i<MAXSOUNDS;i++) {
		if(!StrEqual(SoundsUse[i],"")) {
			Format(tmp, sizeof(tmp), "%s%s", SNDDIR, SoundsUse[i]);
			AddFileToDownloadsTable(tmp);
		}
	}
	for(new i = 0; i<MAXSOUNDS;i++) {
		if(!StrEqual(SoundsUnUse[i],"")) {
			Format(tmp, sizeof(tmp), "%s%s", SNDDIR, SoundsUnUse[i]);
			AddFileToDownloadsTable(tmp);
		}
	}
}
PrecacheAll() {
	new String:tmp[PLATFORM_MAX_PATH];
	for(new i = 0; i<MAXSKINS;i++) {
		if(!StrEqual(HostModels[i],"")) {
			Format(tmp, sizeof(tmp), "%s%s", MDLDIR, HostModels[i]);
			//HostModelsIndex[i] = PrecacheModel(HostModels[i]);
			HostModelsIndex[i] = PrecacheModel(tmp);
		}
		
	}
	for(new i = 0; i<MAXSOUNDS;i++) {
		if(!StrEqual(SoundsPain[i],"")) {
			PrecacheSound(SoundsPain[i]);
		}
	}
	for(new i = 0; i<MAXSOUNDS;i++) {
		if(!StrEqual(SoundsUse[i],"")) {
			PrecacheSound(SoundsUse[i]);
		}
	}
	for(new i = 0; i<MAXSOUNDS;i++) {
		if(!StrEqual(SoundsUnUse[i],"")) {
			PrecacheSound(SoundsUnUse[i]);
		}
	}
	#if DEBUG > 1
	PrintToServer("[HM:DEBUG] Precache End");
	#endif
}
AddModel(String:mdl[],grp=0) {
	new String:Pmdl[PLATFORM_MAX_PATH];
	Format(Pmdl,sizeof(Pmdl), "%s%s", MDLDIR, mdl);
	if(!FileExists(Pmdl)) {
		return -1;
	}
	
	for(new i = 0; i<MAXSKINS;i++) {
		if(StrEqual(HostModels[i],mdl)) {
			return 1;
		}
	}
	for(new i = 0; i<MAXSKINS;i++) {
		if(StrEqual(HostModels[i],"")) {
			strcopy(HostModels[i], PLATFORM_MAX_PATH, mdl);
			HostModelsGroup[i]=grp;
			HostModelsCount[grp]++;
			HostModelsCount2++;
			AddFileToDownloadsTable(Pmdl);
			//HostModelsIndex[i] = PrecacheModel(mdl);
			HostModelsIndex[i] = PrecacheModel(Pmdl);
			return 0;
		}
	}
	return -1;
}
//radio/blow.wav
//radio/clear.wav
AddSound(String:snd[],type=0,grp=0) {

	new String:Psnd[PLATFORM_MAX_PATH];
	Format(Psnd,sizeof(Psnd), "%s%s", SNDDIR, snd);
	#if DEBUG > 0
	PrintToServer("[HM:DEBUG] Checkint file: %s", Psnd);
	#endif
	if(!FileExists(Psnd)) {
		return -1;
	}
	if(type==0) {
		for(new i = 0; i<MAXSOUNDS;i++) {
			if(StrEqual(SoundsPain[i],snd)&&SoundsPainGroup[i] == grp) {
				#if DEBUG > 0
				PrintToServer("[HS:DEBUG] Same Sound %d",i);
				#endif
				return 1;
			}
		}
		for(new i = 0; i<MAXSOUNDS;i++) {
			if(StrEqual(SoundsPain[i],"")) {
				strcopy(SoundsPain[i], PLATFORM_MAX_PATH, snd);
				SoundsPainGroup[i]=grp;
				SoundsPainCount[grp]++;
				AddFileToDownloadsTable(Psnd);
				PrecacheSound(snd);
				return 0;
			}
		}
	} else if (type==1) {
		for(new i = 0; i<MAXSOUNDS;i++) {
			if(StrEqual(SoundsUse[i],snd)&&SoundsUseGroup[i] == grp) {
				return 1;
			}
		}
		for(new i = 0; i<MAXSOUNDS;i++) {
			if(StrEqual(SoundsUse[i],"")) {
				strcopy(SoundsUse[i], PLATFORM_MAX_PATH, snd);
				SoundsUseGroup[i]=grp;
				SoundsUseCount[grp]++;
				AddFileToDownloadsTable(Psnd);
				PrecacheSound(snd);
				return 0;
			}
		}
	} else if (type==2) {
		for(new i = 0; i<MAXSOUNDS;i++) {
			if(StrEqual(SoundsUnUse[i],snd)&&SoundsUnUseGroup[i] == grp) {
				return 1;
			}
		}
		for(new i = 0; i<MAXSOUNDS;i++) {
			if(StrEqual(SoundsUnUse[i],"")) {
				strcopy(SoundsUnUse[i], PLATFORM_MAX_PATH, snd);
				SoundsUnUseGroup[i]=grp;
				SoundsUnUseCount[grp]++;
				AddFileToDownloadsTable(Psnd);
				PrecacheSound(snd);
				return 0;
			}
		}
	}
	return -1;
}

SetupState() {
	#if DEBUG > 0
	PrintToServer("[HM:DEBUG] SetupState()");
	#endif
	HostMgr = GetConVarBool(hHostMgr);
	HostMgrSkins = GetConVarBool(hHostMgrSkins);
	HostMgrSounds = GetConVarBool(hHostMgrSounds);

	if(FindEntityByClassname(-1, HOSTENTNAME)==-1) {
		if(IsON) TurnOff();
	} else {
		if(IsON) {
			if (!HostMgr) TurnOff();
		} else {
			if (HostMgr) TurnOn();
		}
	}
}

TurnOn() {
	#if DEBUG > 0
	PrintToServer("[HM:DEBUG] TurnOn");
	#endif
	
	//Hook
	AddNormalSoundHook (NormalSHook:eSoundPlayed);
	HookEvent("hostage_hurt", eHostageHurt);
	HookEvent("hostage_follows", eHostageFollows);
	HookEvent("hostage_stops_following", eHostageStopsFollowing);
	HookEvent("round_start", eRoundStart);
	
	IsON = true;
}
TurnOff() {
	#if DEBUG > 0
	PrintToServer("[HM:DEBUG] TurnOff");
	#endif
	
	UnhookEvent("hostage_hurt", eHostageHurt);
	UnhookEvent("hostage_follows", eHostageFollows);
	UnhookEvent("hostage_stops_following", eHostageStopsFollowing);
	UnhookEvent("round_start", eRoundStart);
	RemoveNormalSoundHook(NormalSHook:eSoundPlayed);
	IsON = false;
}
public GetHostGroup(ent) { //Get Hostage Group based on Model, -1 = cant find matching model, wrong ent
	if(!IsHostage(ent)) return -1;
	new String:Modelname[PLATFORM_MAX_PATH];
	GetEntPropString(ent, Prop_Data, "m_ModelName", Modelname, sizeof(Modelname));
	#if DEBUG > 1
	PrintToServer("[HM:DEBUG] GetHostGroup(%d) - m_ModelName: %s",ent,Modelname);
	#endif
	new String:mdltmp[PLATFORM_MAX_PATH] = "";
	for(new i = 0; i<MAXSKINS; i++) {
		Format(mdltmp,sizeof(mdltmp), "%s%s",MDLDIR,HostModels[i]);
		#if DEBUG > 1
		PrintToServer("[HM:DEBUG] GetHostFroup Checking model:%s",mdltmp);
		#endif
		if(StrEqual(mdltmp, Modelname ,false)) return HostModelsGroup[i];
	}
	return -1;
}
public bool:IsHostage(ent) {
	if(!IsValidEntity(ent)) return false;
	new String:classname[128];
	GetEdictClassname(ent, classname, sizeof(classname));
	if(StrEqual(classname, HOSTENTNAME,false)) return true;
	return false;
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
public ReadDownloadsSimple(String:file[]){
	new Handle:fileh = OpenFile(file, "r");
	new String:buffer[256];
	new len;
	
	if(fileh == INVALID_HANDLE) return;
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
			buffer[--len] = '\0';
		if (buffer[len-1] == '\r')
			buffer[--len] = '\0';
		if (len >=2 && buffer[0]=='\\' && buffer[1]=='\\') continue;

		TrimString(buffer);

		if(!StrEqual(buffer,"",false)){
			ReadFileFolder(buffer);
		}
		
		if (IsEndOfFile(fileh))
			break;
	}
	if(fileh != INVALID_HANDLE){
		CloseHandle(fileh);
	}
}

public ReadFileFolder(String:path[]){
	new Handle:dirh = INVALID_HANDLE;
	new String:buffer[256];
	new String:tmp_path[256];
	new FileType:type = FileType_Unknown;
	new len;
	
	len = strlen(path);
	if (path[len-1] == '\n')
		path[--len] = '\0';

	TrimString(path);
	
	if(DirExists(path)){
		dirh = OpenDirectory(path);
		while(ReadDirEntry(dirh,buffer,sizeof(buffer),type)){
			len = strlen(buffer);
			if (buffer[len-1] == '\n')
				buffer[--len] = '\0';

			TrimString(buffer);

			if (!StrEqual(buffer,"",false) && !StrEqual(buffer,".",false) && !StrEqual(buffer,"..",false)){
				strcopy(tmp_path,255,path);
				StrCat(tmp_path,255,"/");
				StrCat(tmp_path,255,buffer);
				if(type == FileType_File){
					ReadItemSimple(tmp_path);
				}
				else{
					ReadFileFolder(tmp_path);
				}
			}
		}
	}
	else{
		ReadItemSimple(path);
	}
	if(dirh != INVALID_HANDLE){
		CloseHandle(dirh);
	}
}

public ReadItemSimple(String:buffer[]){
	new len = strlen(buffer);
	if (buffer[len-1] == '\n')
		buffer[--len] = '\0';
	
	TrimString(buffer);
	if(len >= 2 && buffer[0] == '/' && buffer[1] == '/'){
		//Comment
	}
	else if (!StrEqual(buffer,"",false) && FileExists(buffer))
	{
		AddFileToDownloadsTable(buffer);
	}
}
/*
	SNDLEVEL_NONE = 0,			< None
	SNDLEVEL_RUSTLE = 20,		< Rustling leaves
	SNDLEVEL_WHISPER = 25,		< Whispering
	SNDLEVEL_LIBRARY = 30,		< In a library
	SNDLEVEL_FRIDGE = 45,		< Refridgerator
	SNDLEVEL_HOME = 50,			< Average home (3.9 attn)
	SNDLEVEL_CONVO = 60,		< Normal conversation (2.0 attn)
	SNDLEVEL_DRYER = 60,		< Clothes dryer
	SNDLEVEL_DISHWASHER = 65,	< Dishwasher/washing machine (1.5 attn)
	SNDLEVEL_CAR = 70,			< Car or vacuum cleaner (1.0 attn)
	SNDLEVEL_NORMAL = 75,		< Normal sound level
	SNDLEVEL_TRAFFIC = 75,		< Busy traffic (0.8 attn)
	SNDLEVEL_MINIBIKE = 80,		< Mini-bike, alarm clock (0.7 attn)
	SNDLEVEL_SCREAMING = 90,	< Screaming child (0.5 attn)
	SNDLEVEL_TRAIN = 100,		< Subway train, pneumatic drill (0.4 attn)
	SNDLEVEL_HELICOPTER = 105,	< Helicopter
	SNDLEVEL_SNOWMOBILE = 110,	< Snow mobile
	SNDLEVEL_AIRCRAFT = 120,	< Auto horn, aircraft
	SNDLEVEL_RAIDSIREN = 130,	< Air raid siren
	SNDLEVEL_GUNFIRE = 140,		< Gunshot, jet engine (0.27 attn)
	SNDLEVEL_ROCKET = 180,		< Rocket launching (0.2 attn)
*/